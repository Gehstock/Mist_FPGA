/*============================================================================
	74LS42 - BCD to decimal decoder

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

module ls42
(
	input wire  a, b, c, d,
	output wire [9:0] o
);

assign o[0] = ~(~a && ~b && ~c && ~d);
assign o[1] = ~(a && ~b && ~c && ~d);
assign o[2] = ~(~a && b && ~c && ~d);
assign o[3] = ~(a && b && ~c && ~d);
assign o[4] = ~(~a && ~b && c && ~d);
assign o[5] = ~(a && ~b && c && ~d);
assign o[6] = ~(~a && b && c && ~d);
assign o[7] = ~(a && b && c && ~d);
assign o[8] = ~(~a && ~b && ~c && d);
assign o[9] = ~(a && ~b && ~c && d);

endmodule
