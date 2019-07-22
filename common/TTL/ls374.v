`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:       Paul Wightmore
// 
// Create Date:    20:28:15 05/15/2018 
// Design Name:    LS374
// Module Name:    system86/ttl/ls374.v
// Project Name:   Namco System86 simulation
// Target Devices: 
// Tool versions: 
// Description:    LS374 - Octal D-Type Transparent Latches And Edge-Triggered Flip-Flops
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
// License:        https://www.apache.org/licenses/LICENSE-2.0
//
//////////////////////////////////////////////////////////////////////////////////
module LS374(
        input wire OC,
        input wire CLK,
        input wire [1:8] D,
        output reg [1:8] Q
    );

	always @(posedge CLK) begin
		if (OC)
			Q = D;
		else
			Q = 8'bZ;
	end

endmodule
