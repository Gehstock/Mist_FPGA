/*============================================================================
	VIC arcade hardware by Gremlin Industries for MiSTer - Sega 97269-P-B daughter board

	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 1.0
	Date: 2022-05-01

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

module sega_97269pb (
	input clk,
	input reset,

	input palbank_b2,
	input palbank_b3,
	input [8:0] hcnt,
	input [8:0] vcnt,
	input video,
	input [2:0] rgb,
	input hsync,
	input vsync,
	input vblank,

	input [15:0] dn_addr,
	input 		 dn_wr,
	input [7:0]  dn_data,

	output reg [7:0] r,
	output reg [7:0] g,
	output reg [7:0] b

);

reg hsync_last = 1'b0;
reg vsync_last = 1'b0;
reg h1_last = 1'b0;
reg [3:0] c5_q;
reg [3:0] a4_q;

reg [3:0] c2_cnt;
reg c2_co;
wire c2_13 = c2_cnt[2];
wire c2_14 = c2_cnt[3];

reg [3:0] c3_cnt;
reg c3_co;
wire c3_11 = c3_cnt[3];
wire c3_12 = c3_cnt[2];
wire c3_13 = c3_cnt[1];
wire c3_14 = c3_cnt[0];

reg [7:0] b4_cnt;
wire b4_6 = b4_cnt[3];
wire b4_11 = b4_cnt[4];

wire [3:0] b5_q = ~({ palbank_b3, palbank_b2, c2_co, b4_cnt[0]} & { palbank_b3, palbank_b2, c2_co, b4_cnt[1]});
wire [3:0] c4_q = !b5_q[0] ? { 1'b0, palbank_b3, b5_q[3], 1'b0 } : { 1'b0 , 1'b0, 1'b1, 1'b1 };

wire b3_12 = ~(pr57_a3_data_out[0] & rgb[0]); // vred
wire b3_6 = ~(pr57_a3_data_out[1] & rgb[1] & a4_q[1]);  // vgreen
wire b3_8 = ~(pr57_a3_data_out[2] & rgb[2] & a4_q[3]);  // vblue

reg [7:0] grad_r;
reg [7:0] grad_g;
reg [7:0] grad_b;

always @(posedge clk)
begin

	// if(vcnt == 9'd0) $display("%3d > %b", hcnt, pr02_a1_data_out );

	case(pr02_a1_data_out[7:4])
	4'b0100:
	begin
		grad_r = 8'b00000000;
		grad_g = 8'b00000000;
		grad_b = { pr02_a1_data_out[3:0], 4'b1111 };
	end
	4'b0001: // light blue to cyan
	begin
		grad_r = 8'b00000000;
		grad_g = { 1'b1, pr02_a1_data_out[3:0], 3'b111 };
		grad_b = 8'b11111111;
	end
	default:
	begin
		grad_r = {8{rgb[0]}};
		grad_g = {8{rgb[1]}};
		grad_b = {8{rgb[2]}};
	end
	endcase

	r <= video ? {8{rgb[0]}} : grad_r;
	g <= video ? {8{rgb[1]}} : grad_g;
	b <= video ? {8{rgb[2]}} : grad_b;

	//r <= 8'b0;
	//g <= 8'b0;
	//b <= 8'b0;
	 //r <= video ? {8{rgb[0]}} : {8{pr57_a3_data_out[0]}};
	// g <= video ? {8{rgb[1]}} : {8{pr57_a3_data_out[1]}};
	// b <= video ? {8{rgb[2]}} : {8{pr57_a3_data_out[2]}};
	// if(pr57_a3_data_out>4'b0)
	// begin
	// 	r <= 8'hFF;
	// end
	// if(reset) $display("%d", pr57_a3_data_out);

	// 74175 C5
	h1_last <= hcnt[0];
	if(hcnt[0] && !h1_last)
	begin
		c5_q <= pr02_a1_data_out[3:0];
		a4_q <= pr02_a1_data_out[7:4];
	end

	// 74393 B4
	vsync_last <= vsync;
	if(vsync && !vsync_last) b4_cnt <= b4_cnt + 1'b1;

	// 74161 C2 / C3
	hsync_last <= hsync;
	if(!hsync && hsync_last)
	begin
		// Load
		if(b5_q[1])
		begin
			c2_cnt = { 2'b0, c4_q[2], c4_q[1] };
			c3_cnt = { {3{c4_q[1]}}, c4_q[0] };
		end
		else
		begin
			if(c3_co)
			begin
				c2_cnt = c2_cnt + 1'b1;
				c2_co <= (c2_cnt == 4'b1111);
			end
			if(!vblank)
			begin
				c3_cnt = c3_cnt + 1'b1;
				c3_co <= (c3_cnt == 4'b1111);
			end
		end
	end	

end

// PROM download write enables
wire pr02_a1_wr = (dn_addr[15:7] >= 9'b100000010 && dn_addr[15:7] < 9'b100000100) && dn_wr;
wire pr56_b2_wr = (dn_addr[15:7] >= 9'b100000100 && dn_addr[15:7] < 9'b100001100) && dn_wr;
wire pr57_a3_wr = (dn_addr[15:7] >= 9'b100001100) && dn_wr;

wire [9:0] hcnt_offset = hcnt + 10'd5;

// PROM read addresses
wire [7:0] pr02_a1_addr = { palbank_b3, hcnt_offset[7:1] } ;
wire [9:0] pr56_b2_addr = { palbank_b3, b4_6, b4_11, c2_13, c2_14, c3_11, hcnt_offset[6:3] };
wire [9:0] pr57_a3_addr = { pr56_b2_data_out, c3_12, c3_13, c3_14, hcnt_offset[2:0] };

// PROM data out
wire [7:0] pr02_a1_data_out;
wire [3:0] pr56_b2_data_out;
wire [3:0] pr57_a3_data_out;

// PROM - PR-02-A1
dpram #(8,8) pr02_a1
(
	.clock_a(clk),
	.address_a(pr02_a1_addr),
	.enable_a(~b5_q[2]),
	.wren_a(1'b0),
	.data_a(),
	.q_a(pr02_a1_data_out),

	.clock_b(clk),
	.address_b(dn_addr[7:0]),
	.enable_b(pr02_a1_wr),
	.wren_b(pr02_a1_wr),
	.data_b(dn_data),
	.q_b()
);

// PROM - PR-56-B2
dpram #(10,4) pr56_b2
(
	.clock_a(clk),
	.address_a(pr56_b2_addr),
	.enable_a(!reset),
	.wren_a(1'b0),
	.data_a(),
	.q_a(pr56_b2_data_out),

	.clock_b(clk),
	.address_b(dn_addr[9:0]),
	.enable_b(pr56_b2_wr),
	.wren_b(pr56_b2_wr),
	.data_b(dn_data[3:0]),
	.q_b()
);

// PROM - PR-57-A3
dpram #(10,4) pr57_a3
(
	.clock_a(clk),
	.address_a(pr57_a3_addr),
	.enable_a(~(a4_q[1] && b5_q[2])),
	.wren_a(1'b0),
	.data_a(),
	.q_a(pr57_a3_data_out),

	.clock_b(clk),
	.address_b(dn_addr[9:0]),
	.enable_b(pr57_a3_wr),
	.wren_b(pr57_a3_wr),
	.data_b(dn_data[3:0]),
	.q_b()
);

endmodule