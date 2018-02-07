//
//
// Copyright (c) 2017 Sorgelig
//
// This program is GPL Licensed. See COPYING for the full license.
//
//
////////////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module video_mixer
#(
	parameter LINE_LENGTH  = 768,
	parameter HALF_DEPTH   = 0,

	parameter OSD_COLOR    = 3'd4,
	parameter OSD_X_OFFSET = 10'd0,
	parameter OSD_Y_OFFSET = 10'd0
)
(
	// master clock
	// it should be multiple by (ce_pix*4).
	input        clk_sys,
	
	// Pixel clock or clock_enable (both are accepted).
	input        ce_pix,

	// Some systems have multiple resolutions.
	// ce_pix_actual should match ce_pix where every second or fourth pulse is enabled,
	// thus half or qurter resolutions can be used without brake video sync while switching resolutions.
	// For fixed single resolution (or when video sync stability isn't required) ce_pix_actual = ce_pix.
	input        ce_pix_actual,

	// OSD SPI interface
	input        SPI_SCK,
	input        SPI_SS3,
	input        SPI_DI,

	// color
	input [2:0] R,
	input [2:0] G,
	input [2:0] B,

	// interlace sync. Positive pulses.
	input        HSync,
	input        VSync,

	// Falling of this signal means start of informative part of line.
	// It can be horizontal blank signal.
	// This signal can be used to reduce amount of required FPGA RAM for HQ2x scan doubler
	// If FPGA RAM is not an issue, then simply set it to 0 for whole line processing.
	// Keep in mind: due to algo first and last pixels of line should be black to avoid side artefacts.
	// Thus, if blank signal is used to reduce the line, make sure to feed at least one black (or paper) pixel 
	// before first informative pixel.
	input        line_start,

	// MiST video output signals
	output [5:0] VGA_R,
	output [5:0] VGA_G,
	output [5:0] VGA_B,
	output       VGA_VS,
	output       VGA_HS
);

wire       hs = HSync;
wire       vs = VSync;


wire [5:0] red, green, blue;
osd #(OSD_X_OFFSET, OSD_Y_OFFSET, OSD_COLOR) osd
(
	.*,

	.R_in({R,R}),
	.G_in({G,G}),
	.B_in({B,B}),
	.HSync(hs),
	.VSync(vs),

	.R_out(red),
	.G_out(green),
	.B_out(blue)
);


assign VGA_R  = red;
assign VGA_G  = green;
assign VGA_B  = blue;
assign VGA_VS = 1'b1;
assign VGA_HS =  ~(HSync ^ VSync);

endmodule
