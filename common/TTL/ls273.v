`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:       Paul Wightmore
// 
// Create Date:    21:51:32 05/14/2018 
// Design Name:    LS273
// Module Name:    system86/ttl/ls273.v
// Project Name:   Namco System86 simulation
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
// License:        https://www.apache.org/licenses/LICENSE-2.0
//
//////////////////////////////////////////////////////////////////////////////////
module LS273(
        input wire CLK,
        input wire CLR,
        input wire [7:0] D,
        output reg [7:0] Q
    );

	always @(posedge CLK) begin
		if (CLR)
			Q = 8'b0;
		else
			Q = D;
	end
	
endmodule
