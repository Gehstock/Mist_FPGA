`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:       Paul Wightmore
// 
// Create Date:    20:13:54 04/24/2018 
// Design Name:    LS153
// Module Name:    system86/ttl/ls153.v
// Project Name:   Namco System86 simulation
// Target Devices: 
// Tool versions: 
// Description:    LS153 - Dual 4-Line To 1-Line Data Selectors/Multiplexers
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
// License:        https://www.apache.org/licenses/LICENSE-2.0
//
//////////////////////////////////////////////////////////////////////////////////
module LS153(
        input wire S0,
        input wire S1,
        input wire Ea,
        input wire I0a,
        input wire I1a,
        input wire I2a,
        input wire I3a,
        input wire Eb,
        input wire I0b,
        input wire I1b,
        input wire I2b,
        input wire I3b,
        output wire Za,
        output wire Zb
    );

	assign Za = Ea & ((I0a & ~S1 & ~S0) | (I1a & ~S1 & S0) | (I2a & S1 & ~S0) | (I3a & S1 & S0));
	assign Zb = Eb & ((I0b & ~S1 & ~S0) | (I1b & ~S1 & S0) | (I2b & S1 & ~S0) | (I3b & S1 & S0));
endmodule
