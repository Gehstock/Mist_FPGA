module bagman_mist (
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
	"Bagman;;",
	"O2,Joystick Control,Upright,Normal;",
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

wire clock_48, clock_12;
pll pll
(
	.inclk0(CLOCK_27),
	.c0(clock_48),
	.c1(clock_12)
);

wire m_up     = status[2] ? kbjoy[7] | joystick_0[0] | joystick_1[0] : kbjoy[4] | joystick_0[3] | joystick_1[3];
wire m_down   = status[2] ? kbjoy[6] | joystick_0[1] | joystick_1[1] : kbjoy[5] | joystick_0[2] | joystick_1[2];
wire m_left   = status[2] ? kbjoy[4] | joystick_0[3] | joystick_1[3] : kbjoy[6] | joystick_0[1] | joystick_1[1];
wire m_right  = status[2] ? kbjoy[5] | joystick_0[2] | joystick_1[2] : kbjoy[7] | joystick_0[0] | joystick_1[0];

wire m_fire   = kbjoy[0] | joystick_0[4] | joystick_1[4];
wire m_start1 = kbjoy[1];
wire m_start2 = kbjoy[2];
wire m_coin   = kbjoy[3];

bagman bagman (
	.clock_12(clock_12),
	.reset(status[0] | status[6] | buttons[1]),
	.tv15Khz_mode(scandoubler_disable),
	.video_r(r),
	.video_g(g),
	.video_b(b),
	.video_hblank(hb),
	.video_vblank(vb),
	.video_hs(hs),
	.video_vs(vs),
	.audio_out(audio),
	.start2(m_start2),
	.start1(m_start1),
	.coin1(m_coin),
	
	.fire1(m_fire),
	.right1(m_right),
	.left1(m_left),
	.down1(m_down),
	.up1(m_up),

	.fire2(m_fire),
	.right2(m_right),
	.left2(m_left),
	.down2(m_down),
	.up2(m_up)
);
  
wire [12:0] audio;

dac dac (
	.CLK(clock_48),
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
	.clk_sys(clock_48),
	.ce_pix(clock_12),
	.ce_pix_actual(clock_12),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(r),
	.G(g),
	.B({b,b[0]}),
	.HSync(hs),
	.VSync(vs),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.scandoubler_disable(1'b1),
	.scanlines(scandoubler_disable ? 2'b00 : {status[4:3] == 3, status[4:3] == 2}),
	.hq2x(status[4:3]==1),
	.ypbpr_full(1),
	.line_start(0),
	.mono(0)
);

mist_io #(.STRLEN(($size(CONF_STR)>>3))) mist_io
(
	.clk_sys        (clock_48 	     ),
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
	.clk(clock_48),
	.reset(),
	.ps2_kbd_clk(ps2_kbd_clk),
	.ps2_kbd_data(ps2_kbd_data),
	.joystick(kbjoy)
	);


endmodule
