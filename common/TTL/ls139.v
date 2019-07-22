`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:       Paul Wightmore
// 
// Create Date:    21:02:26 04/24/2018 
// Design Name:    LS139
// Module Name:    system86\src\ttl\ls139.v
// Project Name:   Namco System86 simulation
// Target Devices: 
// Tool versions: 
// Description:    LS139 - Dual 2-Line To 4-Line Decoder/Demultiplexer
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
// License:        https://www.apache.org/licenses/LICENSE-2.0
//
//////////////////////////////////////////////////////////////////////////////////
module LS139(
        input wire Ea,
        input wire A0a,
        input wire A1a,
        input wire Eb,
        input wire A0b,
        input wire A1b,
        output wire O0a,
        output wire O1a,
        output wire O2a,
        output wire O3a,
        output wire O0b,
        output wire O1b,
        output wire O2b,
        output wire O3b
    );

	assign O0a = Ea & (~A0a & ~A1a);
	assign O1a = Ea & (A0a & ~A1a);
	assign O2a = Ea & (~A0a & A1a);
	assign O3a = Ea & (A0a & A1a);
	
	assign O0b = Eb & (~A0b & ~A1b);
	assign O1b = Eb & (A0b & ~A1b);
	assign O2b = Eb & (~A0b & A1b);
	assign O3b = Eb & (A0b & A1b);

endmodule
