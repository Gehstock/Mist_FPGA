module rallyX_mist (
	output        LED,
	output  [5:0] VGA_R,
	output  [5:0] VGA_G,
	output  [5:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        AUDIO_L,
	output        AUDIO_R,
	input         SPI_SCK,
	output        SPI_DO,
	input         SPI_DI,
	input         SPI_SS2,
	input         SPI_SS3,
	input         CONF_DATA0,
	input         CLOCK_27
);

`include "rtl\build_id.v" 

localparam CONF_STR = {
	"RallyX;;",
	"O8A,Difficulty,M1,M2,M3,M4,M5,M6,M7,M8;",
	"OBC,Bonus Life,M1,M2,M3,Nothing;",
	"OF,Service Mode,Off,On;",
	"O34,Scanlines,None,CRT 25%,CRT 50%,CRT 75%;",
	"T6,Reset;",
	"V,v1.00.",`BUILD_DATE
};

assign 		LED = 1;
assign 		AUDIO_R = AUDIO_L;

wire clock_24, clock_12;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clock_24)
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [11:0] kbjoy;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire  [7:0] audio;
wire 			hs, vs;
wire 			hb, vb;
wire 			blankn = ~(hb | vb);
wire [2:0] 	r, g;
wire [1:0] 	b;
wire 			key_strobe;
wire 			key_pressed;
wire  [7:0] key_code;


wire  [7:0] iDSW  = ~{ 2'b00, status[10:8], status[12:11], status[15] };
wire  [7:0] iCTR1 = ~{ btn_coin, btn_one_player, m_up1, m_down1, m_right1, m_left1, m_fire1, 1'b0 };
wire  [7:0] iCTR2 = ~{ btn_coin, btn_two_players, m_up2, m_down2, m_right2, m_left2, m_fire2, 1'b0 };


fpga_nrx fpga_nrx(
	.RESET(status[0] | status[6] | buttons[1]),
	.CLK24M(clock_24),		// Clock 24.576MHz
	.hsync(hs),
	.vsync(vs),
	.hblank(hb),
	.vblank(vb),
	.r(r),
	.g(g),
	.b(b),
	.SND(audio),			// Sound (unsigned PCM)
	.DSW(iDSW),			// DipSW
	.CTR1(iCTR1),			// Controler (Negative logic)
	.CTR2(iCTR2),
	.LAMP()
);

	
mist_video #(.COLOR_DEPTH(3), .SD_HCNT_WIDTH(9)) mist_video(
	.clk_sys        ( clock_24         ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( blankn ? r : 0   ),
	.G              ( blankn ? g : 0   ),
	.B              ( blankn ? {b,1'b0} : 0   ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.scandoubler_disable( scandoublerD ),
	.scanlines      ( status[4:3]      ),
	.ypbpr          ( ypbpr            )
	);
	
user_io #(.STRLEN(($size(CONF_STR)>>3)))user_io(
	.clk_sys        (clock_24       ),
	.conf_str       (CONF_STR       ),
	.SPI_CLK        (SPI_SCK        ),
	.SPI_SS_IO      (CONF_DATA0     ),
	.SPI_MISO       (SPI_DO         ),
	.SPI_MOSI       (SPI_DI         ),
	.buttons        (buttons        ),
	.switches       (switches       ),
	.scandoubler_disable (scandoublerD	  ),
	.ypbpr          (ypbpr          ),
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_code       (key_code       ),
	.joystick_0     (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);

dac #(.C_bits(16))dac(
	.clk_i(clock_24),
	.res_n_i(1),
	.dac_i({audio,audio}),
	.dac_o(AUDIO_L)
	);
	
wire m_up1     = btn_up | joystick_0[3];
wire m_down1   = btn_down | joystick_0[2];
wire m_left1   = btn_left | joystick_0[1];
wire m_right1  = btn_right | joystick_0[0];
wire m_fire1   = btn_fire1 | joystick_0[4];

wire m_up2     = joystick_1[3];
wire m_down2   = joystick_1[2];
wire m_left2   = joystick_1[1];
wire m_right2  = joystick_1[0];
wire m_fire2   = joystick_1[4];


reg btn_one_player = 0;
reg btn_two_players = 0;
reg btn_left = 0;
reg btn_right = 0;
reg btn_down = 0;
reg btn_up = 0;
reg btn_fire1 = 0;
//reg btn_fire2 = 0;
//reg btn_fire3 = 0;
reg btn_coin  = 0;

always @(posedge clock_24) begin
	reg old_state;
	old_state <= key_strobe;
	if(old_state != key_strobe) begin
		case(key_code)
			'h75: btn_up         	<= key_pressed; // up
			'h72: btn_down        	<= key_pressed; // down
			'h6B: btn_left      		<= key_pressed; // left
			'h74: btn_right       	<= key_pressed; // right
			'h76: btn_coin				<= key_pressed; // ESC
			'h05: btn_one_player   	<= key_pressed; // F1
			'h06: btn_two_players  	<= key_pressed; // F2
	//		'h14: btn_fire3 			<= key_pressed; // ctrl
	//		'h11: btn_fire2 			<= key_pressed; // alt
			'h29: btn_fire1   		<= key_pressed; // Space
		endcase
	end
end


endmodule
