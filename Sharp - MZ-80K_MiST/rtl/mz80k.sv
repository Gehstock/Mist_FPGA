module mz80k
(
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
	"MZ80K;;",
	"O2,CPU CLOCK ,6MHZ,3MHZ;",
	"O34,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"T6,Reset;",
	"V,v1.00.",`BUILD_DATE
};


wire clk_sys;
wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [7:0] kbjoy;
wire  [7:0] joystick_0;
wire  [7:0] joystick_1;
wire        scandoubler_disable;
wire        ypbpr;
wire        ps2_kbd_clk, ps2_kbd_data;
wire [7:0] audio;
//assign LED = 1;

wire hblank, vblank;
wire ce_vid;
wire hs, vs;
wire r,g,b;


pll pll
(
	.inclk0(CLOCK_27),
	.c0(clk_sys)
	);
	
video_mixer #(.LINE_LENGTH(640), .HALF_DEPTH(1)) video_mixer
(
	.clk_sys(clk_sys),
	.ce_pix(ce_vid),
	.ce_pix_actual(ce_vid),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.R({r,r,r}),
	.G({g,g,g}),
	.B({b,b,b}),
	.HSync(hs),
	.VSync(vs),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.scandoubler_disable(1),//scandoubler_disable),
	.scanlines(scandoubler_disable ? 2'b00 : {status[4:3] == 3, status[4:3] == 2}),
	.hq2x(status[4:3]==1),
	.ypbpr_full(1),
	.line_start(0),
	.mono(0)
);
	
	
mist_io #(.STRLEN(($size(CONF_STR)>>3))) mist_io
(
	.clk_sys        (clk_sys        ),
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

mycom mycom
(
	.CLK_50MHZ(clk_sys), 
	.BTN_NORTH(),
	.BTN_EAST((status[0] | status[6] | buttons[1])),//reset
	.BTN_SOUTH(), 
	.BTN_WEST(),
	.VGA_RED(r), 
	.VGA_GREEN(g), 
	.VGA_BLUE(b), 
	.VGA_HSYNC(hs), 
	.VGA_VSYNC(vs),
	.Turbo(status[2]),
	.Pix_ce(ce_vid),
	.PS2_CLK(ps2_kbd_clk), 
	.PS2_DATA(ps2_kbd_data),
	.SW(),
	.LED(LED),
	.TP1(audio)
	);



dac dac
(
	.clk_i(clk_sys),
	.res_n_i(1),
	.dac_i(audio),
	.dac_o(AUDIO_L)
	);

assign AUDIO_R = AUDIO_L;

endmodule
