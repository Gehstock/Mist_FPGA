//Dominos from james10952001 Port to Mist by Gehstock

module dominos_mist(
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
	"Dominos;;",
	"O1,Self_Test,Off,On;",
	"O34,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"T6,Reset;",
	"V,v1.10.",`BUILD_DATE
};

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [11:0] kbjoy;
wire  [7:0] joy0;
wire  [7:0] joy1;
wire        scandoubler_disable;
wire        ypbpr;
wire        ps2_kbd_clk, ps2_kbd_data;
wire  [6:0] audio;
wire	[7:0] RGB;

wire clk_24, clk_12, clk_6;
wire locked;
pll pll
(
	.inclk0(CLOCK_27),
	.c0(clk_24),//24.192
	.c1(clk_12),//12.096
	.c2(clk_6),//6.048
	.locked(locked)
);

assign LED = 1;
wire m_start1 = ~(kbjoy[5] | joy0[4]);
wire m_start2 = ~(kbjoy[6] | joy1[4]);
wire m_coin = ~kbjoy[7];

dominos dominos (
	.clk_12(clk_12),
	.Reset_I(~(status[0] | status[6] | buttons[1])),				
	.Hs(hs),
	.Vs(vs),
	.Vb(vb),		
	.Hb(hb),
	.RGB(RGB),			
	.Audio(audio),
	.Coin1_I(m_coin),
	.Coin2_I(m_coin),
	.Start1_I(m_start1),
	.Start2_I(m_start2),
	
	.Up1(~(kbjoy[3] | joy0[3])),
	.Down1(~(kbjoy[2] | joy0[2])),
	.Left1(~(kbjoy[1] | joy0[1])),
	.Right1(~(kbjoy[0] | joy0[0])),
	
	.Up2(~(kbjoy[11] | joy1[3])),
	.Down2(~(kbjoy[10] | joy1[2])),
	.Left2(~(kbjoy[9] | joy1[1])),
	.Right2(~(kbjoy[8] | joy1[0])),	
	.Test_I(~status[1]),
	.Lamp1_O(),
	.Lamp2_O()
	);

dac dac (
	.CLK(clk_24),
	.RESET(0),
	.DACin(audio),
	.DACout(AUDIO_L)
	);

assign AUDIO_R = AUDIO_L;

wire hs, vs;
wire hb, vb;
wire blankn = ~(hb | vb);
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
	.joystick_0   	 (joy0     		  ),
	.joystick_1     (joy1     		  ),
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
