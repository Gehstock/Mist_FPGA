/*============================================================================
	Generic dual-port RAM module with single clock input

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

module dpram #(
	parameter address_width = 10,
	parameter data_width = 8
) (
	input	wire						clock,

	input	wire						enable_a,
	input	wire						wren_a,
	input	wire	[address_width-1:0]	address_a,
	input	wire	[data_width-1:0]	data_a,
	output	reg		[data_width-1:0]	q_a,

	input	wire						enable_b,
	input	wire						wren_b,
	input	wire	[address_width-1:0]	address_b,
	input	wire	[data_width-1:0]	data_b,
	output	reg		[data_width-1:0]	q_b
);

	localparam ramLength = (2**address_width);
	reg [data_width-1:0] mem [ramLength-1:0];

	always @(posedge clock) begin
		if(enable_a)
		begin
			q_a <= mem[address_a];
			if(wren_a) begin
				q_a <= data_a;
				mem[address_a] <= data_a;
			end
		end
		
		if(enable_b)
		begin
			q_b <= mem[address_b];
			if(wren_b) begin
				q_b <= data_b;
				mem[address_b] <= data_b;
			end
		end
	end

endmodule