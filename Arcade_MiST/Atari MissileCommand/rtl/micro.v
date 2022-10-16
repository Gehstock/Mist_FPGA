/*============================================================================
	Missile Command for MiSTer FPGA - Microprocessor circuit

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

module micro
(
	input				clk_10M,
	input wire			s_phi_x,
	input wire			s_phi_extend,
	input wire			reset/*verilator public_flat*/,
	input wire			pause,
	input wire			flip,
	input wire			s_INTACK_n,
	input wire [8:0]	hcnt,
	input wire [7:0]	vcnt,
	input wire [7:0]	s_db_in,
	output wire			s_phi_0/*verilator public_flat*/,
	output wire			s_phi_2,
	output reg			s_irq_n,
	output wire			s_READWRITE,
	output wire			s_WRITE_n,
	output wire			s_br_w_n,
	output wire			s_16FLIP,
	output wire	[15:0]	s_addr/*verilator public_flat*/,
	output wire	[7:0]	s_db_out,
	output wire			sync/*verilator public_flat*/
);

//// TODO - Watchdog

// L3 - 74S86 - XOR
assign s_16FLIP = ~vcnt_adjust[4];
// C4 - 74S32 - OR
assign s_phi_0 = (s_phi_x | s_phi_extend);

reg				irq_pending;
wire	[7:0]	vcnt_adjust = vcnt - 8'd10;
always @(posedge clk_10M)
begin
	reg s_INTACK_n_last;
	reg s_16FLIP_last;
	s_INTACK_n_last <= s_INTACK_n;
	s_16FLIP_last <= s_16FLIP;

	if(reset)
		irq_pending <= 1'b1;
	else if (!s_INTACK_n & s_INTACK_n_last)
		irq_pending <= 1'b1;
	else if(s_16FLIP && !s_16FLIP_last)
		irq_pending <= vcnt_adjust[5];
end

wire sync_phi0 = (sync && s_phi_0);

// F7, E7
always @(posedge clk_10M)
begin
	reg sync_phi0_last;
	sync_phi0_last <= sync_phi0;
	if(reset)
		s_irq_n <= 1'b1;
	else
		if(sync_phi0 && !sync_phi0_last) s_irq_n <= irq_pending;
end

// D3 - 7414 - NOT
wire s_D3_1 = ~s_phi_0;
wire s_D3_3 = s_READWRITE;

// C3 - 7432 - OR
wire s_C3 = s_D3_1 | s_D3_3;

// C4 - 7432 - OR
wire s_C4 = ~hcnt[0] | s_C3;

assign s_WRITE_n = s_C4;
assign s_br_w_n = s_D3_3;

bc6502 bc6502
(
	.reset(reset),
	.clk(s_phi_0),
	.nmi(1'b0),
	.irq(~s_irq_n),
	.rdy(~pause),
	.so(1'b0),
	.di(s_db_in),
	.dout(s_db_out),
	.rw(s_READWRITE), 
	.ma(s_addr),
	.rw_nxt(),
	.ma_nxt(),
	.sync(sync),
	.state(),
	.flags()
);
	
assign s_phi_2 = ~s_phi_0;


endmodule 