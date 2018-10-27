module FlappyBird_MiST(
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
	"FlappyBird;;",
	"V,v1.00.",`BUILD_DATE
};

wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire  [9:0] kbjoy;
wire  [7:0] joy0, joy1;
wire        scandoubler_disable;
wire        ypbpr;
wire        ps2_kbd_clk, ps2_kbd_data;
wire  [7:0] audio;
wire			r, g, b;
wire hs, vs;
assign AUDIO_R = AUDIO_L;
assign LED = 1'b1;

wire clk_sys, clk_pix;
pll pll
(
	.inclk0(CLOCK_27),
	.c0(clk_sys),
	.c1(clk_pix)
);

TopModule TopModule(
	.Clk(clk_sys),
	.Button(~(joy0[4] | joy1[4] | kbjoy[4])),
	.Reset(~(kbjoy[7] | joy0[5] | joy1[5])), 
	.vga_h_sync(hs),
	.vga_v_sync(vs),
	.vga_R(r), 
	.vga_G(g),
	.vga_B(b),
	.Speaker(AUDIO_L)
	);

video_mixer #(.LINE_LENGTH(480), .HALF_DEPTH(1)) video_mixer
(
	.clk_sys(clk_sys),
	.ce_pix(clk_pix),
	.ce_pix_actual(clk_pix),
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
	.scandoubler_disable(1'b1),//scandoubler_disable),
	.scanlines(scandoubler_disable ? 2'b00 : {status[4:3] == 3, status[4:3] == 2}),
	.hq2x(status[4:3]==1),
	.ypbpr_full(1),
	.line_start(0),
	.mono(1)
);

mist_io #(.STRLEN(($size(CONF_STR)>>3))) mist_io
(
	.clk_sys        (clk_sys   	     ),
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
	.joystick_0   	 (joy0     ),
	.joystick_1     (joy1     ),
	.status         (status         )
);

keyboard keyboard(
	.clk(clk_sys),
	.reset(),
	.ps2_kbd_clk(ps2_kbd_clk),
	.ps2_kbd_data(ps2_kbd_data),
	.joystick(kbjoy)
	);


endmodule
