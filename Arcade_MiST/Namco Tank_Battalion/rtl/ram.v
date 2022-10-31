module ram2114
(
	input [7:0] data,
	input [10:0] addr,
	input we,clk,
	output [7:0] q
);

	reg [7:0] ram[2047:0];

	reg [10:0] addr_reg;

//RAM initialization Option 1 - Fill
	initial 
	begin : INIT
		integer i;
		for(i = 0; i < 2048; i = i + 1)
			ram[i] = {8{1'b0}};
	end 

	always @ (posedge clk)
	begin
		// Write
		if (we)//!
			ram[addr] <= data;

		addr_reg <= addr;
	end

	assign q = ram[addr_reg];

endmodule

module ram2114_DP
(
	input [7:0] data_a, data_b,
	input [10:0] addr_a, addr_b,
	input we_a, we_b, clk,
	output reg [7:0] q_a, q_b
);

	// Declare the RAM variable
	reg [7:0] ram[2047:0];
	
	initial 
	begin : INIT
		integer i;
		for(i = 0; i < 2048; i = i + 1)
			ram[i] = {8{1'b0}};
	end 

	// Port A 
	always @ (posedge clk)
	begin
		if (we_a) //!
		begin
			ram[addr_a] <= data_a;
			q_a <= data_a;
		end
		else 
		begin
			q_a <= ram[addr_a];
		end 
	end 

	// Port B 
	always @ (posedge clk)
	begin
		if (we_b) //
		begin
			ram[addr_b] <= data_b;
			q_b <= data_b;
		end
		else 
		begin
			q_b <= ram[addr_b];
		end 
	end

endmodule
//New Modules
module ram8125
(
	input di,
	input [7:0] addr,
	input we,clk,cs,
	output q
);

	reg ram[0:1023];

	reg [7:0] addr_reg;

	initial 
	begin : INIT
		integer i;
		for(i = 0; i < 1024; i = i + 1)
			ram[i] = 1'b0;
	end 

	always @ (posedge clk)
	begin
		// Write
		if (we && cs)
			ram[addr] <= di;

		addr_reg <= addr;
	end

	assign q = ram[addr_reg];

endmodule
/*============================================================================
	Generic single-port RAM module

	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 1.0
	Date: 2022-01-28

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

module spram # (
	parameter address_width = 8,
	parameter data_width = 8,
	parameter init_file= ""
)
(
	input 							clk,
	input [(address_width-1):0]		address,
	input [(data_width-1):0]		data,
	output reg [(data_width-1):0]	q,
	input							wren
);

	localparam ramLength = (2**address_width);

	reg [(data_width-1):0] mem [ramLength-1:0];

	initial begin
		if (init_file>0) $readmemh(init_file, mem);
	end

	always @(posedge clk)
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