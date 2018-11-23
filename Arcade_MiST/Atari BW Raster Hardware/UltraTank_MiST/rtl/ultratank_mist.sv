module ultratank_mist(
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
	"Ultra Tank;;",
	"O1,Test Mode,Off,On;",
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
wire  [6:0] audio1, audio2;
wire	[1:0] video;

wire clk_48, clk_12;
wire locked;
pll pll
(
	.inclk0(CLOCK_27),
	.c0(clk_24),//24.192
	.c1(clk_12),//12.096
	.c2(clk_6),//6.048
	.locked(locked)
);

ultra_tank ultra_tank (
	.clk_12(clk_12),
	.Reset_n(~(status[0] | status[6] | buttons[1])),
	.Video(video),
	.Sync_O(),
	.Blank_O(),
	.HS(hs),
	.VS(vs),
	.HB(vb),	
	.VB(hb),
	.CC3_n_O(),// Not sure what these are, color monitor? (not connected in real game)
	.CC2_O(),
	.CC1_O(),
	.CC0_O(),
	.White_O(),
	.Audio1_O(audio1),
	.Audio2_O(audio2),
	.Coin1_I(~kbjoy[7]),
	.Coin2_I(~kbjoy[7]),
	.Start1_I(~kbjoy[5]),
	.Start2_I(~kbjoy[6]),
	.Invisible_I(),// Invisible tanks switch
	.Rebound_I(),// Rebounding shells switch
	.Barrier_I(),// Barriers switch
	.JoyW_Fw_I(~kbjoy[3]),
	.JoyW_Bk_I(~kbjoy[2]),
	.JoyY_Fw_I(~kbjoy[1]),
	.JoyY_Bk_I(~kbjoy[0]),
	.JoyX_Fw_I(),
	.JoyX_Bk_I(),
	.JoyZ_Fw_I(),
	.JoyZ_Bk_I(),
	.FireA_I(~kbjoy[4]),
	.FireB_I(),
	.Test_I(~status[1]),
	.Slam_I(),
	.LED1_O(),
	.LED2_O(),
	.Lockout_O()
);

dac dac1 (
	.CLK(clk_24),
	.RESET(1'b0),
	.DACin(audio1),
	.DACout(AUDIO_L)
	);
	
dac dac2 (
	.CLK(clk_24),
	.RESET(1'b0),
	.DACin(audio2),
	.DACout(AUDIO_R)
	);

wire hs, vs;
wire hb, vb;
wire blankn = ~(hb | vb);
video_mixer #(.LINE_LENGTH(480), .HALF_DEPTH(0)) video_mixer
(
	.clk_sys(clk_24),
	.ce_pix(clk_6),
	.ce_pix_actual(clk_6),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R({video&video,video}),
	.G({video&video,video}),
	.B({video&video,video}),
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
	.clk_sys        (clk_24   	     ),
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
	.clk(clk_24),
	.reset(),
	.ps2_kbd_clk(ps2_kbd_clk),
	.ps2_kbd_data(ps2_kbd_data),
	.joystick(kbjoy)
	);


endmodule
