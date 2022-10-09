//
// cdda_fifo.v
//
// CDDA FIFO for the MiST board
// https://github.com/mist-devel
//
// Copyright (c) 2022 Gyorgy Szombathelyi
//
// This source file is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This source file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
///////////////////////////////////////////////////////////////////////

module cdda_fifo
(
	input         clk_sys,
	input         clk_en,    // set to 1 when using the stock data_io
	input         cen_44100, // 44100 HZ clock enable
	input         reset,

	// data_io interface
	output        hdd_cdda_req,
	input         hdd_cdda_wr,
	input  [15:0] hdd_data_out,

	// sample output
	output reg [15:0] cdda_l,
	output reg [15:0] cdda_r
);

// 4k x 16bit default FIFO size
parameter FIFO_DEPTH = 12;
reg [15:0] fifo[2**FIFO_DEPTH];
reg [FIFO_DEPTH-1:0] inptr;
reg [FIFO_DEPTH-1:0] outptr;
reg [15:0] fifo_out;

wire [FIFO_DEPTH:0] fifo_used = inptr >= outptr ?
                                inptr - outptr :
                                inptr - outptr + (2'd2**FIFO_DEPTH);

assign hdd_cdda_req = fifo_used < ((2'd2**FIFO_DEPTH) - 16'd2352);

always @(posedge clk_sys) begin
	if (reset)
		inptr <= 0;
	else if (clk_en && hdd_cdda_wr) begin
		fifo[inptr] <= {hdd_data_out[7:0], hdd_data_out[15:8]};
		inptr <= inptr + 1'd1;
	end
end

always @(posedge clk_sys) fifo_out <= fifo[outptr];

reg left = 0;
reg mute = 1;
reg fifo_active = 0;

always @(posedge clk_sys) begin
	if (reset) begin
		outptr <= 0;
		fifo_active <= 0;
		mute <= 1;
		left <= 0;
		cdda_l <= 0;
		cdda_r <= 0;
	end else begin
		if (cen_44100) begin
			if (fifo_used >= 2352)
				fifo_active <= 1;
			if (outptr + 2'd2 == inptr)
				fifo_active <= 0;
			if (fifo_active) begin
				outptr <= outptr + 1'd1;
				left <= 1;
				mute <= 0;
			end else
				mute <= 1;
		end
		if (left) begin
			outptr <= outptr + 1'd1;
			left <= 0;
		end

		if (mute) begin
			cdda_l <= 0;
			cdda_r <= 0;
		end else begin
			if (left)
				cdda_l <= fifo_out;
			else
				cdda_r <= fifo_out;
		end
	end
end

endmodule
