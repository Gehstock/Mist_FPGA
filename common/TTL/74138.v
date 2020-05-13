//============================================================================
//  SNK Alpha68k for MiSTer
//
//  Copyright (C) 2020 Sean 'Furrtek' Gonsalves
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

module C74669 (
	input [2:0] IN,
	input E1, nE2, nE3,
	output reg [7:0] OUT
);

	always @(*)
	begin
		case ({E1, E2, E3, IN)
			6'b100000: OUT <= 8'b11111110;
			6'b100001: OUT <= 8'b11111101;
			6'b100010: OUT <= 8'b11111011;
			6'b100011: OUT <= 8'b11110111;
			6'b100100: OUT <= 8'b11101111;
			6'b100101: OUT <= 8'b11011111;
			6'b100110: OUT <= 8'b10111111;
			6'b100111: OUT <= 8'b01111111;
			default: OUT <= 8'b11111111;
		endcase
	end

endmodule
