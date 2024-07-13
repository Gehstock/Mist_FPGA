/*============================================================================
	VIC arcade hardware by Gremlin Industries for MiSTer - Main system

	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 1.0
	Date: 2022-02-20

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

module vic (
	input clk,
	input reset,

	input srl,	// 29
	input src,	// 23
	input msb,	// 30
	input m1,	// 14
	input m2,	// 13
	input m4,	// 12

	input [11:0] addr,	// 33,36,39, 3, 6,11,31,34,37,40, 4,10
	input [7:0] data,	// 27,26,25,24,22,21,19,18

	//output csync,		// 15
	//output cblank_n,	// 17

	output reg hsync,
	output reg vsync,
	output reg hblank,
	output reg vblank,

	output reg [8:0] hcnt,
	output reg [8:0] vcnt,

	output [5:0] ram_addr	// 32,35,38, 2, 5 ,7

);

	localparam VIC_HTOTAL = 9'd327;
	localparam VIC_HBSTART  = 9'd255;
	localparam VIC_HBEND = 9'd327;
	localparam VIC_HSSTART = 9'd272;
	localparam VIC_HSEND = 9'd304;

	localparam VIC_VTOTAL = 9'd262;
	localparam VIC_VBSTART = 9'd224;
	localparam VIC_VBEND = 9'd000;
	localparam VIC_VSSTART = 9'd236;
	localparam VIC_VSEND = 9'd240;

	localparam VIC_HCOUNT_START = 9'd1;

	wire s_1v = vcnt[0];
	wire s_2v = vcnt[1];
	wire s_4v = vcnt[2];
	wire s_8v = vcnt[3];
	wire s_16v = vcnt[4];
	wire s_32v = vcnt[5];
	wire s_64v = vcnt[6];
	wire s_128v = vcnt[7];
	wire s_8h = hcnt[3];
	wire s_16h = hcnt[4];
	wire s_32h = hcnt[5];
	wire s_64h = hcnt[6];
	wire s_128h = hcnt[7];

	reg hsync_last;
	reg src_last;
	wire src_falling = !src && src_last;

	always @(posedge clk)
	begin
		if(reset)
		begin
			hcnt <= VIC_HCOUNT_START;
			vcnt <= 9'd0;
		end
		else
		begin
			src_last <= src;
			if(src_falling)
			begin
				hcnt <= hcnt + 1'b1;
				if(hcnt == VIC_HBSTART) hblank <= 1'b1;
				if(hcnt == VIC_HBEND) hblank <= 1'b0;
				if(hcnt == VIC_HSSTART)
				begin
					hsync <= 1'b1;
					vcnt <= vcnt + 9'd1;
					if(vcnt == VIC_VBSTART) vblank <= 1'b1;
					if(vcnt == VIC_VBEND) vblank <= 1'b0;
					if(vcnt == VIC_VSSTART) vsync <= 1'b1;
					if(vcnt == VIC_VSEND) vsync <= 1'b0;
					if(vcnt == VIC_VTOTAL) vcnt <= 9'b0;
				end
				if(hcnt == VIC_HSEND) hsync <= 1'b0;
				if(hcnt == VIC_HTOTAL) hcnt <= 9'b0;
			end
		end
	end

	// Address decoding?
	reg [4:0] c;
	wire [2:0] m = {m4,m2,m1};

	// U18 flip-flop
	reg msb_last;
	always @(posedge clk)
	begin
		msb_last <= msb;
		if(msb && !msb_last) c <= data[7:3];
	end

	// U8 - Line selector
	ttl74151 u8 (
		.data({2'b0, 1'b1,data[2],1'b0,s_8v,addr[11],addr[5]}),
		.sel(m),
		.out(ram_addr[5])
	);
	// U9 - Line selector
	ttl74151 u9 (
		.data({2'b0, c[4],data[1],1'b0,s_128h,addr[10],addr[4]}),
		.sel(m),
		.out(ram_addr[4])
	);
	// U10 - Line selector
	ttl74151 u10 (
		.data({2'b0, c[3],data[0],s_128v,s_64h,addr[9],addr[3]}),
		.sel(m),
		.out(ram_addr[3])
	);
	// U11 - Line selector
	ttl74151 u11 (
		.data({2'b0, c[2],s_4v,s_64v,s_32h,addr[8],addr[2]}),
		.sel(m),
		.out(ram_addr[2])
	);
	// U7 - Line selector
	ttl74151 u7 (
		.data({2'b0, c[1],s_2v,s_32v,s_16h,addr[7],addr[1]}),
		.sel(),
		.out(ram_addr[1])
	);
	// U7 - Line selector
	ttl74151 u6 (
		.data({2'b0, c[0],s_1v,s_16v,s_8h,addr[6],addr[0]}),
		.sel(m),
		.out(ram_addr[0])
	);

endmodule

module ttl74151(
	input [7:0] data,
	input [2:0] sel,
	output out
);

    assign out =
	  ( sel[2] &  sel[1] &  sel[0] & data[7])
	| ( sel[2] &  sel[1] & !sel[0] & data[6])
	| ( sel[2] & !sel[1] &  sel[0] & data[5])
	| ( sel[2] & !sel[1] & !sel[0] & data[4])
	| (!sel[2] &  sel[1] &  sel[0] & data[3])
	| (!sel[2] &  sel[1] & !sel[0] & data[2])
	| (!sel[2] & !sel[1] &  sel[0] & data[1])
	| (!sel[2] & !sel[1] & !sel[0] & data[0]);
endmodule 