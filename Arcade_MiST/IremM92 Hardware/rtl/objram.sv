//============================================================================
//  Copyright (C) 2023 Martin Donlon
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

module objram(
    input clk,

    input [10:0] addr,
    input we,

    input [15:0] data,

    output [15:0] q,
    output [63:0] q64
);

wire [1:0] col = addr[1:0];
wire [63:0] data64 = { col == 2'd3 ? data  : 16'd0, col == 2'd2 ? data  : 16'd0, col == 2'd1 ? data  : 16'd0, col == 2'd0 ? data  : 16'd0 };
wire [7:0] byte_en = { col == 2'd3 ? 2'b11 : 2'b00, col == 2'd2 ? 2'b11 : 2'b00, col == 2'd1 ? 2'b11 : 2'b00, col == 2'd0 ? 2'b11 : 2'b00 };
assign q = col == 2'd0 ? q64[15:0] : col == 2'd1 ? q64[31:16] : col == 2'd2 ? q64[47:32] : q64[63:48];

altsyncram	altsyncram_component (
            .address_a (addr[10:2]),
            .byteena_a (byte_en),
            .clock0 (clk),
            .data_a (data64),
            .wren_a (we),
            .q_a (q64),
            .aclr0 (1'b0),
            .aclr1 (1'b0),
            .address_b (1'b1),
            .addressstall_a (1'b0),
            .addressstall_b (1'b0),
            .byteena_b (1'b1),
            .clock1 (1'b1),
            .clocken0 (1'b1),
            .clocken1 (1'b1),
            .clocken2 (1'b1),
            .clocken3 (1'b1),
            .data_b (1'b1),
            .eccstatus (),
            .q_b (),
            .rden_a (1'b1),
            .rden_b (1'b1),
            .wren_b (1'b0));
defparam
    altsyncram_component.byte_size = 8,
    altsyncram_component.clock_enable_input_a = "BYPASS",
    altsyncram_component.clock_enable_output_a = "BYPASS",
    altsyncram_component.intended_device_family = "Cyclone V",
    altsyncram_component.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
    altsyncram_component.lpm_type = "altsyncram",
    altsyncram_component.numwords_a = 512,
    altsyncram_component.operation_mode = "SINGLE_PORT",
    altsyncram_component.outdata_aclr_a = "NONE",
    altsyncram_component.outdata_reg_a = "UNREGISTERED",
    altsyncram_component.power_up_uninitialized = "FALSE",
    altsyncram_component.read_during_write_mode_port_a = "DONT_CARE",
    altsyncram_component.widthad_a = 9,
    altsyncram_component.width_a = 64,
    altsyncram_component.width_byteena_a = 8;

endmodule