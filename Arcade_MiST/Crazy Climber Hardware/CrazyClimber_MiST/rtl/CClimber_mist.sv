module CClimber_mist (
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
	"CClimber;;",
	"O34,Scanlines,Off,25%,50%,75%;",
	"T6,Reset;",
	"V,v1.20.",`BUILD_DATE
};

assign LED = 1;
assign AUDIO_R = AUDIO_L;

wire clock_24, clock_12, clock_6;
pll pll(
	.inclk0(CLOCK_27),
	.c0(clock_24),//48.784
	.c1(clock_12),//12.196
	.c2(clock_6)
	);

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoublerD;
wire        ypbpr;
wire [10:0] ps2_key;
wire [15:0] audio;
wire hs, vs;
wire hb, vb;
wire blankn = ~(hb | vb);
wire [2:0] r, g;
wire [1:0] b;


crazy_climber crazy_climber (
	.clock_12(clock_12),
	.reset(status[0] | status[6] | buttons[1]),
	.video_r(r),
	.video_g(g),
	.video_b(b),
	.video_hblank(hb),
	.video_vblank(vb),
	.video_hs(hs),
	.video_vs(vs),
	.audio_out(audio),
	.start2(btn_two_players),
	.start1(btn_one_player),
	.coin1(btn_coin),

	.r_right1(m_right1),//right Arrow
	.r_left1(m_left1),//left Arrow
	.r_down1(m_down1),//down Arrow
	.r_up1(m_up1),//up Arrow
	.l_right1(m_right2),//D
	.l_left1(m_left2),//A
	.l_down1(m_down2),//S
	.l_up1(m_up2),////W
  
	.r_right2(m_right1),//right Arrow
	.r_left2(m_left1),//left Arrow
	.r_down2(m_down1),//down Arrow
	.r_up2(m_up1),//up Arrow
	.l_right2(m_right2),//D
	.l_left2(m_left2),//A
	.l_down2(m_down2),//S
	.l_up2(m_up2),////W
	);

video_mixer video_mixer(
	.clk_sys(clock_24),
	.ce_pix(clock_6),
	.ce_pix_actual(clock_6),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(blankn ? {r} : "000"),
	.G(blankn ? {g} : "000"),
	.B(blankn ? {b,1'b0} : "000"),
	.HSync(hs),
	.VSync(vs),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.scandoublerD(scandoublerD),
	.scanlines(scandoublerD ? 2'b00 : status[4:3]),
	.ypbpr(ypbpr),
	.ypbpr_full(1),
	.line_start(0),
	.mono(0)
	);

mist_io #(
	.STRLEN(($size(CONF_STR)>>3)))
mist_io(
	.clk_sys        (clock_24       ),
	.conf_str       (CONF_STR       ),
	.SPI_SCK        (SPI_SCK        ),
	.CONF_DATA0     (CONF_DATA0     ),
	.SPI_SS2			 (SPI_SS2        ),
	.SPI_DO         (SPI_DO         ),
	.SPI_DI         (SPI_DI         ),
	.buttons        (buttons        ),
	.switches   	 (switches       ),
	.scandoublerD	 (scandoublerD	  ),
	.ypbpr          (ypbpr          ),
	.ps2_key			 (ps2_key        ),
	.joystick_0   	 (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
	);

dac #(
	.MSBI(15),
	.INV(1'b1))
dac(
	.CLK(clock_24),
	.RESET(0),
	.DACin(audio),
	.DACout(AUDIO_L)
	);

wire m_up1     = btn_up1 | joystick_0[3];
wire m_down1   = btn_down1 | joystick_0[2];
wire m_left1   = btn_left1 | joystick_0[1];
wire m_right1  = btn_right1 | joystick_0[0];

wire m_up2     = btn_up2 | joystick_1[3];
wire m_down2   = btn_down2 | joystick_1[2];
wire m_left2   = btn_left2 | joystick_1[1];
wire m_right2  = btn_right2 | joystick_1[0];

wire m_fire   = btn_fire1 | joystick_0[4] | joystick_1[4];
//wire m_bomb   = btn_fire2 | joystick_0[5] | joystick_1[5];

reg btn_one_player = 0;
reg btn_two_players = 0;
reg btn_left1 = 0;
reg btn_right1 = 0;
reg btn_down1 = 0;
reg btn_up1 = 0;
reg btn_left2 = 0;
reg btn_right2 = 0;
reg btn_down2 = 0;
reg btn_up2 = 0;
reg btn_fire1 = 0;
reg btn_fire2 = 0;
reg btn_fire3 = 0;
reg btn_coin  = 0;
wire       pressed = ps2_key[9];
wire [7:0] code    = ps2_key[7:0];	

always @(posedge clock_24) begin
	reg old_state;
	old_state <= ps2_key[10];
	if(old_state != ps2_key[10]) begin
		case(code)
			'h75: btn_up1         	<= pressed; // up
			'h72: btn_down1        	<= pressed; // down
			'h6B: btn_left1      	<= pressed; // left
			'h74: btn_right1       	<= pressed; // right
			
			'h1D: btn_up2         	<= pressed; // W
			'h1B: btn_down2        	<= pressed; // S
			'h1C: btn_left2      	<= pressed; // A
			'h23: btn_right2       	<= pressed; // D
			
			
			'h76: btn_coin				<= pressed; // ESC
			'h05: btn_one_player   	<= pressed; // F1
			'h06: btn_two_players  	<= pressed; // F2
			'h14: btn_fire3 			<= pressed; // ctrl
			'h11: btn_fire2 			<= pressed; // alt
			'h29: btn_fire1   		<= pressed; // Space
		endcase
	end
end
 
endmodule
