module sprint2_mist(
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
	"Sprint2;;",
	"O1,Test Mode,Off,On;",
	"T2,Next Track;",
	"O34,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"T6,Reset;",
	"V,v1.00.",`BUILD_DATE
};

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [9:0] kbjoy;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoubler_disable;
wire        ypbpr;
wire        ps2_kbd_clk, ps2_kbd_data;
wire  [6:0] audio1, audio2;
wire			video;

wire clk_48, clk_12;
wire locked;
pll pll
(
	.inclk0(CLOCK_27),
	.c0(clk_48),
	.c1(clk_12),
	.locked(locked)
);

wire led1, led2;
assign LED = (led1 | led2);

sprint2 sprint2 (
	.clk_12(clk_12),
	.Reset_n(~(status[0] | status[6] | buttons[1])),
	.VideoW_O(),
	.VideoB_O(),
	.Sync_O(),					
	.Hs(hs),
	.Vs(vs),
	.Vb(vb),		
	.Hb(hb),
	.Video(video),			
	.Audio1_O(audio1),
	.Audio2_O(audio2),
	.Coin1_I(~kbjoy[7]),
	.Coin2_I(~kbjoy[7]),
	.Start1_I(~kbjoy[5]),
	.Start2_I(~kbjoy[6]),
	.Trak_Sel_I(~status[2]),
	.Gas1_I(~kbjoy[4]),
	.Gas2_I(),
//	.Gear1_1_I(),//                                                                                                                                                                                                                                                                                                           Gear shifters, 4th gear = no other gear selected
//	.Gear1_2_I(),
//	.Gear1_3_I(),
//	.Gear2_1_I(),
//	.Gear2_2_I(),
//	.Gear2_3_I(),
	.Test_I(~status[1]),
	.Steer_1A_I(~kbjoy[1]),// Steering wheel inputs, these are quadrature encoders
	.Steer_1B_I(~kbjoy[0]),
//	.Steer_2A_I(),
//	.Steer_2B_I(),
	.Lamp1_O(led1),
	.Lamp2_O(led2)
);

dac dac (
	.CLK(clk_48),
	.RESET(1'b0),
	.DACin({audio1, audio2}),
	.DACout(AUDIO_L)
	);

assign AUDIO_R = AUDIO_L;

wire hs, vs;
wire hb, vb;
wire blankn = ~(hb | vb);
video_mixer #(.LINE_LENGTH(480), .HALF_DEPTH(1)) video_mixer
(
	.clk_sys(clk_48),
	.ce_pix(clk_12),
	.ce_pix_actual(clk_12),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(blankn ? {video,video,video} : "000"),
	.G(blankn ? {video,video,video} : "000"),
	.B(blankn ? {video,video,video} : "000"),
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
	.clk_sys        (clk_48   	     ),
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
	.clk(clk_48),
	.reset(),
	.ps2_kbd_clk(ps2_kbd_clk),
	.ps2_kbd_data(ps2_kbd_data),
	.joystick(kbjoy)
	);


endmodule
