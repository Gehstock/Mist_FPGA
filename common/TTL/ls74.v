`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:       Paul Wightmore
// 
// Create Date:    19:24:54 05/16/2018 
// Design Name:    LS47
// Module Name:    system86/ttl/ls74.v
// Project Name:   Namco System86 simulation
// Target Devices: 
// Tool versions: 
// Description:    LS74 - Dual D-Type Positive-Edge -Triggered Flip-Flops With Preset and Clear
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
// License:        https://www.apache.org/licenses/LICENSE-2.0
//
//////////////////////////////////////////////////////////////////////////////////
module LS74(
        input wire CLR1,
        input wire CLR2,
        input wire CLK1,
        input wire CLK2,
        input wire PRE1,
        input wire PRE2,
        input wire D1,
        input wire D2,
        output reg Q1,
        output reg Q2,
        output reg nQ1,
        output reg nQ2
    );

	reg Q1Next = 0;
	reg Q2Next = 0;
	
	always @(posedge CLK1) begin
		Q1Next <= D1;
	end
	
	always @(posedge CLK2) begin
		Q2Next <= D2;
	end
	
	always @(PRE1 or CLR1 or Q1Next) begin
		if (!PRE1 && !CLR1) begin
			Q1 <= Q1Next;
		end else begin
			Q1 <= PRE1;
			nQ1 <= PRE1 || !CLR1;
		end
	end
	
	always @(PRE2 or CLR2 or Q2Next) begin
		if (!PRE2 && !CLR2) begin
			Q2 <= Q2Next;
		end else begin
			Q2 <= PRE2;
			nQ2 <= PRE2 || !CLR2;
		end
	end
	
endmodule
