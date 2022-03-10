/*============================================================================
	Astable 555 generator - based on a version from Space Race by bellwood420

	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 1.0
	Date: 2022-02-13

	This program is free software; you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the Free
	Software Foundation; either version 3 of the License, or (at your option)
	any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License along
	with this program. If not, see <http://www.gnu.org/licenses/>.
===========================================================================*/

`timescale 1 ps / 1 ps

module astable_555 #(
	parameter HIGH_PERIOD = 1000,
	parameter LOW_PERIOD = 1000
)(
	input clk,
	input reset,
	output out
);

	localparam BIT_WIDTH_HIGH = $clog2(HIGH_PERIOD);
	localparam BIT_WIDTH_LOW = $clog2(LOW_PERIOD);

	// State constants
	localparam STATE_RESET = 0;
	localparam STATE_HIGH_COUNT = 1;
	localparam STATE_LOW_COUNT = 2;

	// State and timers
	reg [1:0] state;
	reg [BIT_WIDTH_HIGH-1:0] high_count;
	reg [BIT_WIDTH_LOW-1:0] low_count;

	assign out = (state == STATE_HIGH_COUNT) ? 1'b1 : 1'b0;

	always @(posedge clk) 
	begin
		if (reset) state <= STATE_RESET;
		// Increment relevant counters
		case(state)
		STATE_RESET:
		begin
			high_count <= {BIT_WIDTH_HIGH{1'b0}};
			low_count  <= {BIT_WIDTH_LOW{1'b0}};
			state <= STATE_HIGH_COUNT;
		end
		STATE_HIGH_COUNT:
		begin
			high_count <= high_count + 1'b1;
			if ((high_count == HIGH_PERIOD-1)) state <= STATE_LOW_COUNT;
		end
		STATE_LOW_COUNT:
		begin
			low_count  <= low_count  + 1'b1;
			if ((low_count == LOW_PERIOD-1)) state <= STATE_HIGH_COUNT;
		end
		endcase
	end
endmodule