/*============================================================================
	Linear-feedback shift register

	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 1.0
	Date: 2021-11-06

    Based on Project F: Ad Astra - Starfield
    (C)2021 Will Green, open source hardware released under the MIT License
    Learn more at https://projectf.io

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

`timescale 1ps / 1ps

module lfsr #(
    parameter LEN=8,                  // shift register length
    parameter TAPS=8'b10111000        // XOR taps
    ) (
    input  wire clk,            // clock
    input  wire rst,            // reset
    input  wire en,             // enable
    input  wire [LEN-1:0] seed,
    output reg  [LEN-1:0] sreg  // lfsr output
    );

    always @(posedge clk) begin
        if (en) sreg <= {1'b0, sreg[LEN-1:1]} ^ (sreg[0] ? TAPS : {LEN{1'b0}});
        if (rst) sreg <= seed;
    end
endmodule