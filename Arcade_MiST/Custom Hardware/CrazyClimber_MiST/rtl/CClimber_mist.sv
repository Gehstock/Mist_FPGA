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

`include "rtl\build_id.sv" 

localparam CONF_STR = {
	"CClimber;;",
	"O34,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"T6,Reset;",
	"V,v1.00.",`BUILD_DATE
};

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [11:0] kbjoy;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoubler_disable;
wire        ypbpr;
wire        ps2_kbd_clk, ps2_kbd_data;

assign LED = 1;

wire clock_24, clock_12, clock_6;
pll pll
(
	.inclk0(CLOCK_27),
	.c0(clock_24),//48.784
	.c1(clock_12),//12.196
	.c2(clock_6)
);

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
	.start2(kbjoy[6]),
	.start1(kbjoy[5]),
	.coin1(kbjoy[7]),

	.r_right1(kbjoy[0] | joystick_0[2]),//right Arrow
	.r_left1(kbjoy[1] | joystick_0[3]),//left Arrow
	.r_down1(kbjoy[2] | joystick_0[1]),//down Arrow
	.r_up1(kbjoy[3] | joystick_0[0]),//up Arrow
	.l_right1(kbjoy[11] | joystick_0[2]),//D
	.l_left1(kbjoy[10] | joystick_1[3]),//A
	.l_down1(kbjoy[9] | joystick_1[1]),//S
	.l_up1(kbjoy[8] | joystick_1[0]),////W
  
	.r_right2(kbjoy[0] | joystick_0[2]),//right Arrow
	.r_left2(kbjoy[1] | joystick_0[3]),//left Arrow
	.r_down2(kbjoy[2] | joystick_0[1]),//down Arrow
	.r_up2(kbjoy[3] | joystick_0[0]),//up Arrow
	.l_right2(kbjoy[11] | joystick_0[2]),//D
	.l_left2(kbjoy[10] | joystick_1[3]),//A
	.l_down2(kbjoy[9] | joystick_1[1]),//S
	.l_up2(kbjoy[8] | joystick_1[0]),////W
);

wire [15:0] audio;

dac dac (
	.CLK(clock_24),
	.RESET(1'b0),
	.DACin(audio),
	.DACout(AUDIO_L)
	);

assign AUDIO_R = AUDIO_L;

wire hs, vs;
wire hb, vb;
wire blankn = ~(hb | vb);
wire [2:0] r, g;
wire [1:0] b;
video_mixer #(.LINE_LENGTH(480), .HALF_DEPTH(1)) video_mixer
(
	.clk_sys(clock_24),
	.ce_pix(clock_6),
	.ce_pix_actual(clock_6),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(blankn ? r : "000"),
	.G(blankn ? g : "000"),
	.B(blankn ? {b,b[0]} : "000"),
	.HSync(hs),
	.VSync(vs),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.scandoubler_disable(scandoubler_disable),
	.scanlines(scandoubler_disable ? 2'b00 : {status[4:3] == 3, status[4:3] == 2}),
	.hq2x(status[4:3]==1),
	.ypbpr_full(1),
	.line_start(0),
	.mono(0)
);

mist_io #(.STRLEN(($size(CONF_STR)>>3))) mist_io
(
	.clk_sys        (clock_24 	     ),
	.conf_str       (CONF_STR       ),
	.SPI_SCK        (SPI_SCK        ),
	.CONF_DATA0     (CONF_DATA0     ),
	.SPI_SS2			 (SPI_SS2        ),
	.SPI_DO         (SPI_DO         ),
	.SPI_DI         (SPI_DI         ),
	.buttons        (buttons        ),
	.switches   	 (switches       ),
	.scandoubler_disable(scandoubler_disable),
	.ypbpr          (ypbpr          ),
	.ps2_kbd_clk    (ps2_kbd_clk    ),
	.ps2_kbd_data   (ps2_kbd_data   ),
	.joystick_0   	 (joystick_0     ),
	.joystick_1     (joystick_1     ),
	.status         (status         )
);

keyboard keyboard(
	.clk(clock_24),
	.reset(),
	.ps2_kbd_clk(ps2_kbd_clk),
	.ps2_kbd_data(ps2_kbd_data),
	.joystick(kbjoy)
	);


endmodule
