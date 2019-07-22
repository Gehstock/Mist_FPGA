`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:       Paul Wightmore
// 
// Create Date:    20:44:36 04/25/2018 
// Design Name:    LS175
// Module Name:    system86\src\ttl\ls175.v
// Project Name:   Namco System86 simulation
// Target Devices: 
// Tool versions: 
// Description:    LS175 - Quad D-Type Flip-Flop
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
// License:        https://www.apache.org/licenses/LICENSE-2.0
//
//////////////////////////////////////////////////////////////////////////////////
module LS175(
        input wire CLK,
        input wire CLR,
        input wire D1,
        input wire D2,
        input wire D3,
        input wire D4,
        output reg Q1,
        output wire Q1_L,
        output reg Q2,
        output wire Q2_L,
        output reg Q3,
        output wire Q3_L,
        output reg Q4,
        output wire Q4_L
    );

	always @(posedge CLK) begin
		if (CLR) begin
			Q1 <= 0;
			Q2 <= 0;
			Q3 <= 0;
			Q4 <= 0;
		end else begin
			Q1 <= D1;
			Q2 <= D2;
			Q3 <= D3;
			Q4 <= D4;
		end
	end
	
	assign Q1_L = ~Q1;	
	assign Q2_L = ~Q2;
	assign Q3_L = ~Q3;
	assign Q4_L = ~Q4;
	
endmodule
