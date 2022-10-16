/*============================================================================
	Generic single-port RAM module

	Copyright (C) 2022 - Jim Gregory - https://github.com/JimmyStones/

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
`default_nettype none

module spram # (
	parameter address_width = 8,
	parameter data_width = 8
)
(
	input 							clock,
	input [(address_width-1):0]		address,
	input [(data_width-1):0]		data,
	output reg [(data_width-1):0]	q,
	input							wren
);

	localparam ramLength = (2**address_width);
	reg [(data_width-1):0] mem [ramLength-1:0];

	always @(posedge clock)
	begin
		if (wren)
		begin
			mem[address] <= data;
			q <= data;
		end
		else
		begin
			q <= mem[address];
		end
	end

endmodule
