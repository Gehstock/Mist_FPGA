
//============================================================================
//  Irem M72 for MiSTer FPGA - Dualport memory with mailbox functionality
//
//  Copyright (C) 2022 Martin Donlon
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

// Based on the MB8421

// Left port is 16-bit, right port in 8-bit
// 
module dualport_mailbox_2kx16(
    input reset,

    input clk_l,
    input cs_l,
    input [11:1] addr_l,
    input [15:0] din_l,
    output [15:0] dout_l,
    input [1:0] we_l,
    output int_l,

    input clk_r,
    input cs_r,
    input [11:0] addr_r,
    input [7:0] din_r,
    output [7:0] dout_r,
    input we_r,
    output int_r
);

wire [7:0] dout_0_l, dout_1_l;
wire [7:0] dout_0_r, dout_1_r;

assign dout_l = { dout_1_l, dout_0_l };
assign dout_r = addr_r[0] ? dout_1_r : dout_0_r;

assign int_l = int_l_rq != int_l_ack;
assign int_r = int_r_rq != int_r_ack;

reg int_l_rq = 0;
reg int_l_ack = 0;
reg int_r_rq = 0;
reg int_r_ack = 0;

always @(posedge clk_l) begin
    if (reset) begin
        int_l_ack <= 0;
        int_r_rq <= 0;
    end else if (cs_l) begin
        if (we_l != 2'b00 && addr_l[11:1] == 'h7ff) int_r_rq <= ~int_r_ack;
        if (we_l == 2'b00 && addr_l[11:1] == 'h7fe) int_l_ack <= int_l_rq;
    end
end

always @(posedge clk_r) begin
    if (reset) begin
        int_l_rq <= 0;
        int_r_ack <= 0;
    end else if (cs_r) begin
        if (we_r && addr_r[11:1] == 'h7fe) int_l_rq <= ~int_l_ack;
        if (~we_r && addr_r[11:1] == 'h7ff) int_r_ack <= int_r_rq;
    end
end


dpramv #(.widthad_a(11)) ram_0(
    .clock_a(clk_l),
    .address_a(addr_l[11:1]),
    .q_a(dout_0_l),
    .wren_a(we_l[0]),
    .data_a(din_l[7:0]),

    .clock_b(clk_r),
    .address_b(addr_r[11:1]),
    .q_b(dout_0_r),
    .wren_b(we_r & ~addr_r[0]),
    .data_b(din_r)
);

dpramv #(.widthad_a(11)) ram_1(
    .clock_a(clk_l),
    .address_a(addr_l[11:1]),
    .q_a(dout_1_l),
    .wren_a(we_l[1]),
    .data_a(din_l[15:8]),

    .clock_b(clk_r),
    .address_b(addr_r[11:1]),
    .q_b(dout_1_r),
    .wren_b(we_r & addr_r[0]),
    .data_b(din_r)
);

endmodule