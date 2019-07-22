`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:       Paul Wightmore
// 
// Create Date:    21:46:13 05/04/2018 
// Design Name:    LS157
// Module Name:    system86\src\custom\ls157.v
// Project Name:   Namco System86 simulation
// Target Devices: 
// Tool versions: 
// Description:    LS157 - Quad 2-Input Multiplexer
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
// License:        https://www.apache.org/licenses/LICENSE-2.0
//
//////////////////////////////////////////////////////////////////////////////////
module LS157(
        input wire G,
        input wire SELA,
        input wire [3:0] A,
        input wire [3:0] B,
        output wire [3:0] Y
    );

	assign Y = G ? (SELA ? A : B) : 4'b0;

endmodule
