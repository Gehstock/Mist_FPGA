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
        input wire [7:0] Ai,
        input wire [7:0] Bi,
		  output wire [7:0] Ao,
        output wire [7:0] Bo
    );

	wire BToA = OE & ~DIR;
	wire AToB = OE & DIR;
	
	assign Ao = BToA ? Bi : 8'bZ;
	assign Bo = AToB ? Ai : 8'bZ;
	
	
//	assign A = BToA ? B : 8'bZ;
//	assign B = AToB ? A : 8'bZ;
	
endmodule
