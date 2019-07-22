`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:	   Paul Wightmore
// 
// Create Date:	   22:06:05 05/14/2018 
// Design Name:	   LS85
// Module Name:	   system86/ttl/ls85.v
// Project Name:   Namco System86 simulation
// Target Devices: 
// Tool versions: 
// Description:	   LS85 - 4-Bit Magnitude Comparators
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
// License:		   https://www.apache.org/licenses/LICENSE-2.0
//
//////////////////////////////////////////////////////////////////////////////////
module LS85(
        input wire [3:0] A,
        input wire [3:0] B,
        output wire AgtBin,
        output wire AeqBin,
        output wire AltBin,
        output wire AgtBout,
        output wire AeqBout,
        output wire AltBout
	);

	assign AgtBout = (A > B) || (!AeqBin && AgtBin && (A == B));
	assign AeqBout = (A == B) && AeqBin;
	assign AltBout = (A < B) || (!AeqBin && AltBin && (A == B));

endmodule
