//============================================================================
//  Jupiter Ace video
//  Copyright (C) 2018 Sorgelig
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module video
(
	input         clk,
	input         ce_pix,

	output  [9:0] sram_addr,
	input   [7:0] sram_data,
	output  [9:0] cram_addr,
	input   [7:0] cram_data,

	output        video_out,
	output reg    hsync,
	output reg    vsync,
	output reg    hblank,
	output reg    vblank
);

assign sram_addr = {vcnt[7:3], hcnt[7:3]};
assign cram_addr = {sram_data[6:0], vcnt[2:0]};
assign video_out = pix[7] ^ inv;

reg [8:0] hcnt;
reg [8:0] vcnt;
reg [7:0] pix;
reg       inv;
always @(posedge clk) begin
	reg ven,hen;

	if(ce_pix) begin
		if (hcnt != 415) hcnt <= hcnt + 1'd1;
		else begin
			hcnt <= 0;
			if (vcnt != 311) vcnt <= vcnt + 1'd1;
			else vcnt <= 0;
		end

		if (hcnt == 308) hsync <= 0;
		if (hcnt == 340) hsync <= 1;
		if (hcnt == 000) hen = 1;
		if (hcnt == 256) hen = 0;

		if (vcnt == 248) vsync <= 0;
		if (vcnt == 256) vsync <= 1;
		if (vcnt == 000) ven = 1;
		if (vcnt == 192) ven = 0;

		hblank <= ~hen;
		vblank <= ~ven;

		pix <= {pix[6:0], 1'b0};
		if (!hcnt[2:0] && ven && hen) pix <= cram_data;
		if (!hcnt[2:0]) inv <= ven & hen & sram_data[7];
	end
end

endmodule 