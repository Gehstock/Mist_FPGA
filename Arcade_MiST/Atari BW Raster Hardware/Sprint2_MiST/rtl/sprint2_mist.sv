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
	"V,v1.10.",`BUILD_DATE
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


wire m_left1   = (kbjoy[1] | joystick_1[1]);
wire m_right1  = (kbjoy[0] | joystick_1[0]);

wire m_left2   = (joystick_0[1]);
wire m_right2  = (joystick_0[0]);

wire m_fire1 = ~(kbjoy[4] | joystick_1[4]);
wire m_fire2 = ~(joystick_0[4]);
wire m_start1 = ~(kbjoy[5]);
wire m_start2 = ~(kbjoy[6]);
wire m_coin = ~(kbjoy[7]);
wire m_gearup1 = (kbjoy[8] | joystick_1[5]);
wire m_geardown1 = (kbjoy[9] | joystick_1[6]);
wire m_gearup2 = (joystick_0[5]);
wire m_geardown2 = (joystick_0[6]);

wire [1:0] steer1;
joy2quad steerp1(
	.CLK(clk_24),
	.clkdiv('d22500),	
	.right(m_right1),
	.left(m_left1),	
	.steer(steer1)
	);

wire [1:0] steer2;
joy2quad steerp2(
	.CLK(clk_24),
	.clkdiv('d22500),	
	.right(m_right2),
	.left(m_left2),	
	.steer(steer2)
	);

wire gear11,gear12,gear13;
gearshift gearshiftp1(
	.CLK(clk_12),	
	.gearup(m_gearup1),
	.geardown(m_geardown1),	
	.gear1(gear11),
	.gear2(gear12),
	.gear3(gear13)
	);

wire gear21,gear22,gear23;
gearshift gearshiftp2(
	.CLK(clk_12),	
	.gearup(m_gearup2),
	.geardown(m_geardown2),	
	.gear1(gear21),
	.gear2(gear22),
	.gear3(gear23)
	);

sprint2 sprint2(
	.clk_12(clk_12),
	.Reset_n(~(status[0] | status[6] | buttons[1])),			
	.Hs(hs),
	.Vs(vs),
	.Vb(vb),		
	.Hb(hb),
	.RGB(RGB),			
	.Audio1_O(audio1),
	.Audio2_O(audio2),
	.Coin1_I(m_coin),
	.Coin2_I(1'b1),
	.Start1_I(m_start1),
	.Start2_I(m_start2),
	.Trak_Sel_I(~status[2]),
	.Gas1_I(m_fire1),
	.Gas2_I(m_fire2),
	.Gear1_1_I(~gear11),
	.Gear1_2_I(~gear21),	
	.Gear2_1_I(~gear12),
	.Gear2_2_I(~gear22),	
	.Gear3_1_I(~gear13),
	.Gear3_2_I(~gear23),
	.Test_I(~status[1]),
	.Steer_1A_I(steer1[1]),
	.Steer_1B_I(steer1[0]),
	.Steer_2A_I(steer2[1]),
	.Steer_2B_I(steer2[0]),
	.Lamp1_O(),
	.Lamp2_O()
	);

dac dac(
	.CLK(clk_24),
	.RESET(0),
	.DACin({audio1,audio2,2'b00}),
	.DACout(AUDIO_L)
	);
	
assign AUDIO_R = AUDIO_L;
wire hs, vs;
wire hb, vb;
//wire blankn = ~(hb | vb);
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
	.R({RGB[7:2]}),
	.G({RGB[7:2]}),
	.B({RGB[7:2]}),
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
