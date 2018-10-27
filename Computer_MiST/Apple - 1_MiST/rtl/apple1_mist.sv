module apple1_mist(
	output        LED,
	output  [5:0] VGA_R,
	output  [5:0] VGA_G,
	output  [5:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
//	output        AUDIO_L,
//	output        AUDIO_R,	
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
	"APPLE 1;;",
	"O34,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"T6,Reset;",
	"V,v1.00.",`BUILD_DATE
};


wire clk6p25, clk25;
wire r, g, b;
wire hs, vs;
wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire        scandoubler_disable;
wire        ypbpr;
wire        ps2_kbd_clk, ps2_kbd_data;
assign LED = 1;

wire RESET;

pll pll (
	.inclk0(CLOCK_27),
	.c0(clk6p25),
	.c1(clk25),
	.locked(),
	.areset()
	);

apple1 apple1 (
	.clk25(clk25),
	.rst_n(~(status[0] | status[6] | buttons[1])),
	.uart_rx(),
	.uart_tx(),
	.uart_cts(),
	.ps2_clk(ps2_kbd_clk),
	.ps2_din(ps2_kbd_data),
	.ps2_select(1'b1),
	.vga_h_sync(hs),
   .vga_v_sync(vs),
	.vga_red(r),
	.vga_grn(g),
	.vga_blu(b),
	.vga_cls(),
   .pc_monitor()
);
video_mixer #(.LINE_LENGTH(640), .HALF_DEPTH(1)) video_mixer
(
	.clk_sys(clk25),
	.ce_pix(clk6p25),
	.ce_pix_actual(clk6p25),
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
	.mono(1)
);

mist_io #(.STRLEN(($size(CONF_STR)>>3))) mist_io
(
	.clk_sys        (clk25          ),
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
	.status         (status         )
);


	

endmodule 