`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//  Copyright 2013-2016 Istvan Hegedus
//
//  FPGATED is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  FPGATED is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>. 
//
// Create Date:    16:36:31 12/10/2014 
// Module Name:    mos8501 
// Project Name:	 FPGATED 
// Target Devices: Xilinx Spartan 3E
//
// Description: 
//
// Dependencies: 
//	This module contains an instance of Peter Wendrich's 6502 CPU core from FPGA64 project. 
//	The CPU core is used and included with Peter's permission and not developed by me.
// The mos8501 shell around the CPU core is written by me, but inspired by fpga64 6510 CPU
// shell. It might shows certain similarities.
//
// Revision history:
//	0.1	first release using incorrect 6502 core from fpga64 project
//	1.0	CPU core replaced to cpu65xx_fast.vhd from fpga64 project
//
//////////////////////////////////////////////////////////////////////////////////
module mos8501
(
	input         clk,
	input         reset,
	input         enable,
	input         irq_n,
	input   [7:0] data_in,
	output  [7:0] data_out,
	output [15:0] address,
	input         gate_in,
	output        rw,
	input   [7:0] port_in,
	output  [7:0] port_out,
	input         rdy,
	input         aec
);

wire        we;
wire [15:0] core_address;
wire  [7:0] core_data_out;
reg   [7:0] port_dir=8'b0;
reg   [7:0] port_data=8'b0;

// 6502 CPU core
cpu65xx #(.pipelineOpcode("\false"),.pipelineAluMux("\false"),.pipelineAluOut("\false")) cpu_core
(
	.clk(clk), 
	.reset(reset), 
	.enable((rdy | we) & enable), // When RDY is low and cpu would do a read, halt cpu
	.nmi_n(1'b1), 
	.irq_n(irq_n), 
	.di(!port_access ? data_in : address[0] ? (port_dir & port_data) | (~port_dir & port_in) : port_dir), 
	.do(core_data_out), 
	.addr(core_address), 
	.we(we),
	.so_n(1'b1),
	.debugOpcode(),
	.debugPc(),
	.debugA(),
	.debugX(),
	.debugY(),
	.debugS()
);

wire   port_access = ~|core_address[15:1];

assign address     = aec ? core_address : 16'hffff;  // address tri state emulated for easy bus signal combining
assign port_out    = port_data;
assign rw          = ~aec|~we|port_access;
assign data_out    = rw ? 8'hff : core_data_out; // when mux is low data out register is allowed to outside

// IO port part of cpu
// if direction bit is 0 then data is from chip's port
// if direction bit is 1 then data is from data port register filled earlier by CPU
	
always @(posedge clk) begin	//writing port registers
	if(reset) begin
		port_dir<=0;
		port_data<=0;
	end
	else if (enable) begin
		if(port_access & we) begin
			if(core_address[0]==0) port_dir<=core_data_out;
			else port_data<=core_data_out;
		end
	end
end

endmodule
