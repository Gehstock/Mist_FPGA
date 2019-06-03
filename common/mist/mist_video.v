// A video pipeline for MiST. Just insert between the core video output and the VGA pins
// Provides an optional scandoubler, a rotateable OSD and (optional) RGb->YPbPr conversion

module mist_video
(
	// master clock
	// it should be 4xpixel clock for the scandoubler
	input        clk_sys,

	// OSD SPI interface
	input        SPI_SCK,
	input        SPI_SS3,
	input        SPI_DI,

	// scanlines (00-none 01-25% 10-50% 11-75%)
	input  [1:0] scanlines,

	// 0 = HVSync 31KHz, 1 = CSync 15KHz
	input        scandoubler_disable,
	// YPbPr always uses composite sync
	input        ypbpr,
	// Rotate OSD [0] - rotate [1] - left or right
	input  [1:0] rotate,

	// video in
	input  [COLOR_DEPTH-1:0] R,
	input  [COLOR_DEPTH-1:0] G,
	input  [COLOR_DEPTH-1:0] B,

	input        HSync,
	input        VSync,

	// MiST video output signals
	output [5:0] VGA_R,
	output [5:0] VGA_G,
	output [5:0] VGA_B,
	output       VGA_VS,
	output       VGA_HS
);

parameter OSD_COLOR    = 3'd4;
parameter OSD_X_OFFSET = 10'd0;
parameter OSD_Y_OFFSET = 10'd0;
parameter SD_HCNT_WIDTH = 9;
parameter COLOR_DEPTH = 6; // 3-6

wire [5:0] SD_R_O;
wire [5:0] SD_G_O;
wire [5:0] SD_B_O;
wire       SD_HS_O;
wire       SD_VS_O;

scandoubler #(SD_HCNT_WIDTH, COLOR_DEPTH) scandoubler
(
	.clk_sys   ( clk_sys   ),
	.scanlines ( scanlines ),
	.hs_in     ( HSync     ),
	.vs_in     ( VSync     ),
	.r_in      ( R         ),
	.g_in      ( G         ),
	.b_in      ( B         ),
	.hs_out    ( SD_HS_O   ),
	.vs_out    ( SD_VS_O   ),
	.r_out     ( SD_R_O    ),
	.g_out     ( SD_G_O    ),
	.b_out     ( SD_B_O    )
);

wire [5:0] osd_r_o;
wire [5:0] osd_g_o;
wire [5:0] osd_b_o;

osd #(OSD_X_OFFSET, OSD_Y_OFFSET, OSD_COLOR) osd
(
	.clk_sys ( clk_sys ),
	.rotate  ( rotate  ),
	.SPI_DI  ( SPI_DI  ),
	.SPI_SCK ( SPI_SCK ),
	.SPI_SS3 ( SPI_SS3 ),
	.R_in    ( scandoubler_disable ? R : SD_R_O ),
	.G_in    ( scandoubler_disable ? G : SD_G_O ),
	.B_in    ( scandoubler_disable ? B : SD_B_O ),
	.HSync   ( scandoubler_disable ? HSync : SD_HS_O ),
	.VSync   ( scandoubler_disable ? VSync : SD_VS_O ),
	.R_out   ( osd_r_o ),
	.G_out   ( osd_g_o ),
	.B_out   ( osd_b_o )
);

wire [5:0] y, pb, pr;

rgb2ypbpr rgb2ypbpr
(
	.red   ( osd_r_o ),
	.green ( osd_g_o ),
	.blue  ( osd_b_o ),
	.y     ( y       ),
	.pb    ( pb      ),
	.pr    ( pr      )
);

assign VGA_R = ypbpr?pr:osd_r_o;
assign VGA_G = ypbpr? y:osd_g_o;
assign VGA_B = ypbpr?pb:osd_b_o;

wire   cs = scandoubler_disable ? ~(HSync ^ VSync) : ~(SD_HS_O ^ SD_VS_O);
wire   hs = scandoubler_disable ? HSync : SD_HS_O;
wire   vs = scandoubler_disable ? VSync : SD_VS_O;

// a minimig vga->scart cable expects a composite sync signal on the VGA_HS output.
// and VCC on VGA_VS (to switch into rgb mode)
assign VGA_HS = (scandoubler_disable || ypbpr)? cs : hs;
assign VGA_VS = (scandoubler_disable || ypbpr)? 1'b1 : vs;

endmodule
