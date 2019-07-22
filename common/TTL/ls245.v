`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:       Paul Wightmore
// 
// Create Date:    19:33:12 05/01/2018 
// Design Name:    LS245
// Module Name:    system86\src\ttl\ls245.v
// Project Name:   Namco System86 simulation
// Target Devices: 
// Tool versions: 
// Description:    LS245 - Octal Bus Transceiver
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
// License:        https://www.apache.org/licenses/LICENSE-2.0
//
//////////////////////////////////////////////////////////////////////////////////
module LS245(
        input wire DIR,
        input wire OE,
        inout wire [7:0] A,
        inout wire [7:0] B
    );

	wire BToA = OE & ~DIR;
	wire AToB = OE & DIR;
	
	assign A = BToA ? B : 8'bZ;
	assign B = AToB ? A : 8'bZ;
	
endmodule
