`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:       Paul Wightmore
// 
// Create Date:    23:33:42 05/14/2018 
// Design Name:    LS174
// Module Name:    system86/ttl/ls174.v
// Project Name:   Namco System86 simulation
// Target Devices: 
// Tool versions: 
// Description:    LS174 - Hex D-Type Positive-Edge-Triggered Flip-Flops With Clear	
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
// License:        https://www.apache.org/licenses/LICENSE-2.0
//
//////////////////////////////////////////////////////////////////////////////////
module LS174(
        input wire CLK,
        input wire CLR,
        input wire [5:0] D,
        output reg [5:0] Q
    );

	always @(posedge CLK) begin
		if (CLR)
			Q = 6'b0;
		else
			Q = D;
	end
	
endmodule
