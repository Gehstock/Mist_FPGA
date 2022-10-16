/*============================================================================
	Dual-port RAM module with bit-level write enable and read-only second port

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

module dpvram #(
	parameter address_width = 10,
	parameter data_width = 8
) (
	input	wire						clock_a,
	input	wire	[data_width-1:0]	wren_a,
	input	wire	[address_width-1:0]	address_a,
	input	wire	[data_width-1:0]	data_a,
	output	reg		[data_width-1:0]	q_a,

	input	wire						clock_b,
	input	wire	[address_width-1:0]	address_b,
	output	reg		[data_width-1:0]	q_b
);

	localparam ramLength = (2**address_width);
	reg [data_width-1:0] mem [ramLength-1:0];
	
	integer i;
	always @(posedge clock_a)
	begin
		q_a <= mem[address_a];
		for(i=0;i<data_width;i=i+1)
		begin
			if(!wren_a[i]) mem[address_a][i] <= data_a[i];
		end
	end

	always @(negedge clock_b) begin
		q_b <= mem[address_b];
	end

endmodule