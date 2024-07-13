/*============================================================================
	VIC arcade hardware by Gremlin Industries for MiSTer - Carnival sound board

	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 1.0
	Date: 2022-05-16

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

module sound_carnival (
	input clk,
	input reset,
	input [7:0] control_1,
	input [7:0] control_2,
	output signed [15:0] out,

	input [23:0] dn_addr,
	input [7:0]  dn_index,
	input 		 dn_wr,
	input [7:0]  dn_data
);

	// Clock emulation
	// Main clock is 15.468480 Mhz
	// - 3.579545 Mhz clock for 8035 audio CPU
	// - 1.193181 Mhz clock for AY-3-8910
	localparam increment_width = 22;
	reg [increment_width:0] count_3_579M;
	reg [increment_width:0] count_1_193M;
	localparam [increment_width:0] increment_3_579M = 970599;
	localparam [increment_width:0] increment_1_193M = 323533;
	wire ce_3_579M = count_3_579M[increment_width];
	wire ce_1_193M = count_1_193M[increment_width];

	always @(posedge clk) 
	begin
		// Generate clock enables for sound CPUs and controllers 
		count_3_579M <= count_3_579M + increment_3_579M;
		count_1_193M <= count_1_193M + increment_1_193M;
		if(count_3_579M[increment_width]) count_3_579M[increment_width] <= 1'b0;
		if(count_1_193M[increment_width]) count_1_193M[increment_width] <= 1'b0;
		if(ce_3_579M && !reset)
		begin
			//if(ce_3_579M && clk_mstate_s == 0) $display("raddr=%x romdout=%x | t1=%b | opcode=%x acc=%x", t48_rom_addr, t48_rom_dout, ctl, opcode, acc);
		end
	end

	wire rom_t48_we = dn_index == 8'd0 && dn_addr >= 24'h8060 && dn_wr;
	wire [9:0] rom_t48_write_addr = dn_addr[9:0] - 10'h60;
	dpram #(10,8) rom_t48
	(
		.clock_a(clk),
		.enable_a(1'b1),
		.wren_a(rom_t48_we),
		.address_a(rom_t48_write_addr),
		.data_a(dn_data),
		.q_a(),
		.clock_b(clk),
		.enable_b(1'b1),
		.wren_b(1'b0),
		.address_b(t48_rom_addr),
		.data_b(),
		.q_b(t48_rom_dout)
	);

	wire [7:0] t48_dout;
	wire [7:0] t48_p1_out;
	wire [7:0] t48_p2_out;
	wire [7:0] t48_p2_in;
	reg [7:0] t48_addr_latch;
	wire [9:0] t48_rom_addr = { t48_p2_out[1:0], t48_addr_latch };
	wire [7:0] t48_rom_dout;
	wire [7:0] t48_din = !t48_psen_n ? t48_rom_dout : 
							//!t48_rd_n ? s_4M_q : 
							8'b0;
	wire t48_rd_n;
	wire t48_wr_n;
	wire t48_ale;
	wire t48_psen_n;
	wire t48_prog_n;
	wire t48_t0_o;			// Clock enable to AY

	wire ctl = ~control_2[3];

	always @(posedge clk)
	begin
		reg t48_ale_last;
		t48_ale_last <= t48_ale;
		if(!t48_ale && t48_ale_last) t48_addr_latch <= t48_dout; // Latch MCU address
	end

	wire reset_n = ~(reset | ~control_2[4]);

	i8035 i8035_cpu (
		.clk(clk),
		.ce(ce_3_579M),
		.I_RSTn(reset_n),
		.I_INTn(1'b1),
		.I_EA(1'b1),
		.O_PSENn(t48_psen_n),
		.O_RDn(t48_rd_n),
		.O_WRn(t48_wr_n),
		.O_ALE(t48_ale),
		.O_PROGn(t48_prog_n),
		.I_T0(),
		.O_T0(t48_t0_o),
		.I_T1(ctl),
		.I_DB(t48_din),
		.O_DB(t48_dout),
		.I_P1(),
		.O_P1(t48_p1_out),
		.I_P2(t48_p2_in),
		.O_P2(t48_p2_out)
	);


	wire ay_bdir = t48_p2_out[6];
	wire ay_bc1 = t48_p2_out[7];
	wire [9:0] ay1_sound;

	jt49_bus jt49_music(
		.clk(clk),
		.clk_en(ce_1_193M),
		.rst_n(reset_n),
		.bdir(ay_bdir),
		.bc1(ay_bc1),
		.din(t48_p1_out),
		.dout(),
		.sound(ay1_sound),
		.sample(),
		.A(),
		.B(),
		.C(),
		.sel(1'b1),
		.IOA_in(),
		.IOA_out(),
		.IOA_oe(),
		.IOB_in(),
		.IOB_out(),
		.IOB_oe()
	);

	assign out = { 2'b0, ay1_sound, 4'b0 };

endmodule
