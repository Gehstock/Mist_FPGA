`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:       Paul Wightmore
// 
// Create Date:    21:34:16 05/04/2018 
// Design Name:    LS257
// Module Name:    system86\src\ttl\ls257.v
// Project Name:   Namco System86 simulation
// Target Devices: 
// Tool versions: 
// Description:    LS257 - Quad 2-Line To 1-Line Data Selectors/Multiplexers
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
// License:        https://www.apache.org/licenses/LICENSE-2.0
//
//////////////////////////////////////////////////////////////////////////////////
module LS257(
        input wire G,
        input wire SELA,
        input wire [3:0] A,
        input wire [3:0] B,
        output wire [3:0] Y
    );

	assign Y = G ? (SELA ? A : B) : 4'bZ;

endmodule
