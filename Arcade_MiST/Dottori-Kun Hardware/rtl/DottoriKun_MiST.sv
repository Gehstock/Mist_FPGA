module DottoriKun_MiST(
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
	"DottoriKun;;",
	"O12,ROM ,ORIG,ORIG,MINE,PACM;",
	"O34,Scandoubler Fx,None,CRT 25%,CRT 50%,CRT 75%;",
	"O5,Blend,Off,On;",
	"T6,Reset;",
	"V,v1.00.",`BUILD_DATE
};
assign LED = 1;

wire clk_32, clk_8, clk_4;
pll pll
(
	.inclk0(CLOCK_27),
	.c0(clk_32),
	.c1(clk_8),
	.c2(clk_4)
);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0, joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire			r, g, b;
wire 			hs, vs;

dottori dottori (
	.CLK_4M(clk_4),
	.RED(r),
	.GREEN(g),
	.BLUE(b),
	.GAME(status[2:1]),
	.vSYNC(vs),
	.hSYNC(hs),
	.nRESET(~(status[0] | status[6] | buttons[1])),
	.BUTTONS(~{btn_one_player, btn_coin, m_bomb, m_fire, m_right, m_left, m_down, m_up})
	);

mist_video #(.COLOR_DEPTH(1), .SD_HCNT_WIDTH(10)) mist_video(
	.clk_sys        ( clk_32           ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( r                ),
	.G              ( g                ),
	.B              ( b                ),
	.HSync          ( hs               ),
	.VSync          ( vs               ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.rotate         ( 2'b00            ),
	.ce_divider     ( 1'b1             ),
	.blend          ( status[5]        ),
	.scandoubler_disable(scandoublerD  ),
	.scanlines      ( status[4:3]      ),
	.ypbpr          ( ypbpr            )
	);
	
user_io #(
	.STRLEN(($size(CONF_STR)>>3)))
user_io(
	.clk_sys        (clk_32         ),
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
	.joystick_0   	 (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);

wire m_up     = btn_up | joystick_0[3] | joystick_1[3];
wire m_down   = btn_down | joystick_0[2] | joystick_1[2];
wire m_left   = btn_left | joystick_0[1] | joystick_1[1];
wire m_right  = btn_right | joystick_0[0] | joystick_1[0];
wire m_fire   = btn_fire1 | joystick_0[4] | joystick_1[4];
wire m_bomb   = btn_fire2 | joystick_0[5] | joystick_1[5];

reg btn_one_player = 0;
reg btn_two_players = 0;
reg btn_left = 0;
reg btn_right = 0;
reg btn_down = 0;
reg btn_up = 0;
reg btn_fire1 = 0;
reg btn_fire2 = 0;
reg btn_fire3 = 0;
reg btn_coin  = 0;
wire key_strobe;
wire key_pressed;
wire [7:0] key_code;	

always @(posedge clk_32) begin
	if(key_strobe) begin
		case(key_code)
			'h75: btn_up         	<= key_pressed; // up
			'h72: btn_down        	<= key_pressed; // down
			'h6B: btn_left      	<= key_pressed; // left
			'h74: btn_right       	<= key_pressed; // right
			'h76: btn_coin		<= key_pressed; // ESC
			'h05: btn_one_player   	<= key_pressed; // F1
			'h06: btn_two_players  	<= key_pressed; // F2
			'h14: btn_fire3 	<= key_pressed; // ctrl
			'h11: btn_fire2 	<= key_pressed; // alt
			'h29: btn_fire1   	<= key_pressed; // Space
		endcase
	end
end

endmodule 