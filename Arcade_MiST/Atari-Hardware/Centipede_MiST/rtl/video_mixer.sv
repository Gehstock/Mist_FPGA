//
//
// Copyright (c) 2017 Sorgelig
//
// This program is GPL Licensed. See COPYING for the full license.
//
//
////////////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

//
// LINE_LENGTH: Length of  display line in pixels
//              Usually it's length from HSync to HSync.
//              May be less if line_start is used.
//
// HALF_DEPTH:  If =1 then color dept is 4 bits per component
//              For half depth 8 bits monochrome is available with
//              mono signal enabled and color = {G, R}

module video_mixer
#(
	parameter LINE_LENGTH  = 768,
	parameter HALF_DEPTH   = 0
)
(
	// master clock
	// it should be multiple by (ce_pix*4).
	input            clk_sys,
	
	// Pixel clock or clock_enable (both are accepted).
	input            ce_pix,
	output           ce_pix_out,

	input            scandoubler,

	// scanlines (00-none 01-25% 10-50% 11-75%)
	input      [1:0] scanlines,

	// High quality 2x scaling
	input            hq2x,

	// color
	input [DWIDTH:0] R,
	input [DWIDTH:0] G,
	input [DWIDTH:0] B,

	// Monochrome mode (for HALF_DEPTH only)
	input            mono,
	input            ypbpr,

	// Positive pulses.
	input            HSync,
	input            VSync,
	input            HBlank,
	input            VBlank,

	input            SPI_SCK,
	input            SPI_SS3,
	input            SPI_DI,

	// video output signals
	output     [5:0] VGA_R,
	output     [5:0] VGA_G,
	output     [5:0] VGA_B,
	output reg       VGA_VS,
	output reg       VGA_HS,
	output reg       VGA_DE
);

localparam DWIDTH = HALF_DEPTH ? 3 : 7;

wire [DWIDTH:0] R_sd;
wire [DWIDTH:0] G_sd;
wire [DWIDTH:0] B_sd;
wire hs_sd, vs_sd, hb_sd, vb_sd, ce_pix_sd;

scandoubler #(.LENGTH(LINE_LENGTH), .HALF_DEPTH(HALF_DEPTH)) sd
(
	.*,
	.hs_in(HSync),
	.vs_in(VSync),
	.hb_in(HBlank),
	.vb_in(VBlank),
	.r_in(R),
	.g_in(G),
	.b_in(B),

	.ce_pix_out(ce_pix_sd),
	.hs_out(hs_sd),
	.vs_out(vs_sd),
	.hb_out(hb_sd),
	.vb_out(vb_sd),
	.r_out(R_sd),
	.g_out(G_sd),
	.b_out(B_sd)
);

wire [DWIDTH:0] rt  = (scandoubler ? R_sd : R);
wire [DWIDTH:0] gt  = (scandoubler ? G_sd : G);
wire [DWIDTH:0] bt  = (scandoubler ? B_sd : B);

generate
	if(HALF_DEPTH) begin
		wire [7:0] r  = mono ? {gt,rt} : {rt,rt};
		wire [7:0] g  = mono ? {gt,rt} : {gt,gt};
		wire [7:0] b  = mono ? {gt,rt} : {bt,bt};
	end else begin
		wire [7:0] r  = rt;
		wire [7:0] g  = gt;
		wire [7:0] b  = bt;
	end
endgenerate

wire hs = (scandoubler ? hs_sd : HSync);
wire vs = (scandoubler ? vs_sd : VSync);

assign ce_pix_out = scandoubler ? ce_pix_sd : ce_pix;

reg scanline = 0;
always @(posedge clk_sys) begin
	reg old_hs, old_vs;
	
	old_hs <= hs;
	old_vs <= vs;
	
	if(old_hs && ~hs) scanline <= ~scanline;
	if(old_vs && ~vs) scanline <= 0;
end

wire hde = scandoubler ? ~hb_sd : ~HBlank;
wire vde = scandoubler ? ~vb_sd : ~VBlank;

reg hsync, vsync;

reg [7:0] R_in,G_in,B_in;
always @(posedge clk_sys) begin
	reg old_hde;

	case(scanlines & {scanline, scanline})
		1: begin // reduce 25% = 1/2 + 1/4
			R_in <= {1'b0, r[7:1]} + {2'b00, r[7:2]};
			G_in <= {1'b0, g[7:1]} + {2'b00, g[7:2]};
			B_in <= {1'b0, b[7:1]} + {2'b00, b[7:2]};
		end

		2: begin // reduce 50% = 1/2
			R_in <= {1'b0, r[7:1]};
			G_in <= {1'b0, g[7:1]};
			B_in <= {1'b0, b[7:1]};
		end

		3: begin // reduce 75% = 1/4
			R_in <= {2'b00, r[7:2]};
			G_in <= {2'b00, g[7:2]};
			B_in <= {2'b00, b[7:2]};
		end

		default: begin
			R_in <= r;
			G_in <= g;
			B_in <= b;
		end
	endcase

	vsync <= vs;
	hsync <= hs;

	old_hde <= hde;
	if(~old_hde && hde) VGA_DE <= vde;
	if(old_hde && ~hde) VGA_DE <= 0;
end

assign VGA_VS = (~scandoubler | ypbpr) ? 1'b1             : ~vsync;
assign VGA_HS = (~scandoubler | ypbpr) ? ~(vsync ^ hsync) : ~hsync;

wire [5:0] R_out,G_out,B_out;
osd osd
(
	.*,
	.R_in(VGA_DE ? R_in[7:2] : 6'd0),
	.G_in(VGA_DE ? G_in[7:2] : 6'd0),
	.B_in(VGA_DE ? B_in[7:2] : 6'd0),
//	.R_out(VGA_R),
//	.G_out(VGA_G),
//	.B_out(VGA_B),	
	.HSync(hsync),
	.VSync(vsync)
);

vga_space vga_space
(
	.*,
	.ypbpr_full(1),
	.ypbpr_en(ypbpr),
	.red(R_out),
	.green(G_out),
	.blue(B_out)
);


endmodule
