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

`timescale 1ns / 1ps

module dualport_ram #(
    parameter width = 8,
    parameter widthad = 10
) (
    // Port A
    input   wire                  clock_a,
    input   wire                  wren_a,
    input   wire    [widthad-1:0] address_a,
    input   wire    [width-1:0]   data_a,
    output  reg     [width-1:0]   q_a,

    // Port B
    input   wire                  clock_b,
    input   wire                  wren_b,
    input   wire    [widthad-1:0] address_b,
    input   wire    [width-1:0]   data_b,
    output  reg     [width-1:0]   q_b
);

// Shared ramory
reg [width-1:0] ram[(2**widthad)-1:0];

// Port A
always @(posedge clock_a) begin
    if (wren_a) begin
        ram[address_a] <= data_a;
        q_a <= data_a;
    end else begin
        q_a <= ram[address_a];
    end
end

// Port B
always @(posedge clock_b) begin
    if(wren_b) begin
        q_b      <= data_b;
        ram[address_b] <= data_b;
    end else begin
        q_b <= ram[address_b];
    end
end

endmodule

module singleport_ram #(
    parameter width = 8,
    parameter widthad = 10,
    parameter name = "NONE"
) (
    input   wire                   clock,
    input   wire                   wren,
    input   wire    [widthad-1:0]  address,
    input   wire    [width-1:0]    data,
    output  reg     [width-1:0]    q

);

altsyncram	altsyncram_component (
            .address_a (address),
            .clock0 (clock),
            .data_a (data),
            .wren_a (wren),
            .q_a (q),
            .aclr0 (1'b0),
            .aclr1 (1'b0),
            .address_b (1'b1),
            .addressstall_a (1'b0),
            .addressstall_b (1'b0),
            .byteena_a (1'b1),
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
    altsyncram_component.clock_enable_input_a = "BYPASS",
    altsyncram_component.clock_enable_output_a = "BYPASS",
    altsyncram_component.intended_device_family = "Cyclone V",
    altsyncram_component.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
    altsyncram_component.lpm_type = "altsyncram",
    altsyncram_component.numwords_a = 2**widthad,
    altsyncram_component.operation_mode = "SINGLE_PORT",
    altsyncram_component.outdata_aclr_a = "NONE",
    altsyncram_component.outdata_reg_a = "CLOCK0",
    altsyncram_component.power_up_uninitialized = "FALSE",
    altsyncram_component.ram_block_type = "M10K",
    altsyncram_component.read_during_write_mode_port_a = "DONT_CARE",
    altsyncram_component.widthad_a = widthad,
    altsyncram_component.width_a = width,
    altsyncram_component.width_byteena_a = 1;


endmodule

module singleport_unreg_ram #(
    parameter width = 8,
    parameter widthad = 10,
    parameter name = "NONE"
) (
    input   wire                   clock,
    input   wire                   wren,
    input   wire    [widthad-1:0]  address,
    input   wire    [width-1:0]    data,
    output  wire    [width-1:0]    q
);

altsyncram	altsyncram_component (
            .address_a (address),
            .clock0 (clock),
            .data_a (data),
            .wren_a (wren),
            .q_a (q),
            .aclr0 (1'b0),
            .aclr1 (1'b0),
            .address_b (1'b1),
            .addressstall_a (1'b0),
            .addressstall_b (1'b0),
            .byteena_a (1'b1),
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
    altsyncram_component.clock_enable_input_a = "BYPASS",
    altsyncram_component.clock_enable_output_a = "BYPASS",
    altsyncram_component.intended_device_family = "Cyclone V",
    altsyncram_component.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
    altsyncram_component.lpm_type = "altsyncram",
    altsyncram_component.numwords_a = 2**widthad,
    altsyncram_component.operation_mode = "SINGLE_PORT",
    altsyncram_component.outdata_aclr_a = "NONE",
    altsyncram_component.outdata_reg_a = "UNREGISTERED",
    altsyncram_component.power_up_uninitialized = "FALSE",
    altsyncram_component.ram_block_type = "M10K",
    altsyncram_component.read_during_write_mode_port_a = "DONT_CARE",
    altsyncram_component.widthad_a = widthad,
    altsyncram_component.width_a = width,
    altsyncram_component.width_byteena_a = 1;

endmodule