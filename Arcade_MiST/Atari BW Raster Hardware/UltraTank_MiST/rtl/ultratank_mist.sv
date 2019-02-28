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
	"O2,Invisible,Off,On;",
	"O5,Rebound,Off,On;",
	"O7,Barrier,Off,On;",
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
wire	[7:0] RGB;
assign LED = 1;
wire clk_24, clk_12, clk_6;
wire locked;

pll pll(
	.inclk0(CLOCK_27),
	.c0(clk_24),//24.192
	.c1(clk_12),//12.096
	.c2(clk_6),//6.048
	.locked(locked)
	);

wire m_up1     = ~(kbjoy[0] | joystick_1[0]);
wire m_down1   = ~(kbjoy[2] | joystick_1[2]);
wire m_left1   = ~(kbjoy[1] | joystick_1[1]);
wire m_right1  = ~(kbjoy[3] | joystick_1[3]);

wire m_up2     = (joystick_0[0]);
wire m_down2   = (joystick_0[2]);
wire m_left2   = (joystick_0[1]);
wire m_right2  = (joystick_0[3]);

wire m_fire1   = ~(kbjoy[4] | joystick_1[4]);
wire m_fire2   = ~(joystick_0[4]);
wire m_start1 = ~(kbjoy[5]);
wire m_start2 = ~(kbjoy[6]);
wire m_coin = ~(kbjoy[7]);



ultra_tank ultra_tank (
	.clk_12(clk_12),
	.Reset_n(~(status[0] | status[6] | buttons[1])),
	.RGB(RGB),
	.HS(hs),
	.VS(vs),
	.HB(vb),	
	.VB(hb),
	.Audio1_O(audio1),
	.Audio2_O(audio2),
	.Coin1_I(m_coin),
	.Coin2_I(1'b1),
	.Start1_I(m_start1),
	.Start2_I(1'b1),
	.Invisible_I(~status[2]),// Invisible tanks switch
	.Rebound_I(~status[5]),// Rebounding shells switch
	.Barrier_I(~status[7]),// Barriers switch
	.JoyW_Fw_I(m_up1),
	.JoyW_Bk_I(1'b1),
	.JoyY_Fw_I(m_down1),
	.JoyY_Bk_I(1'b1),
	.JoyX_Fw_I(m_left1),
	.JoyX_Bk_I(1'b1),
	.JoyZ_Fw_I(m_right1),
	.JoyZ_Bk_I(1'b1),
	.FireA_I(m_fire1),
	.FireB_I(m_fire2),
	.Test_I(~status[1]),
	.Slam_I(1'b1),
	.LED1_O(),
	.LED2_O(),
	.Lockout_O()
);

dac dac(
	.CLK(clk_24),
	.RESET(0),
	.DACin({audio1,"00",audio2}),
	.DACout(AUDIO_L)
	);
	
assign AUDIO_R = AUDIO_L;
wire hs, vs;
wire hb, vb;
wire blankn = 1'b1;//~(hb | vb);
video_mixer #(
	.LINE_LENGTH(480), 
	.HALF_DEPTH(0))
video_mixer(
	.clk_sys(clk_24),
	.ce_pix(clk_6),
	.ce_pix_actual(clk_6),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R(blankn ? RGB[7:2] : "000000"),
	.G(blankn ? RGB[7:2] : "000000"),
	.B(blankn ? RGB[7:2] : "000000"),
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

mist_io #(
	.STRLEN(($size(CONF_STR)>>3))) 
mist_io(
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
	.reset(0),
	.ps2_kbd_clk(ps2_kbd_clk),
	.ps2_kbd_data(ps2_kbd_data),
	.joystick(kbjoy)
	);


endmodule
