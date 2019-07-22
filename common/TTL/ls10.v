`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:       Paul Wightmore
// 
// Create Date:    19:27:14 05/10/2018 
// Design Name:    LS10
// Module Name:    system86/ttl/ls10 
// Project Name:   Namco System86 simulation
// Target Devices: 
// Tool versions: 
// Description:    LS10 - Triple 3-Input Positive-NAND Gates
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
// License:        https://www.apache.org/licenses/LICENSE-2.0
//
//////////////////////////////////////////////////////////////////////////////////
module LS10(
        input wire A1,
        input wire B1,
        input wire C1,
        input wire A2,
        input wire B2,
        input wire C2,
        input wire A3,
        input wire B3,
        input wire C3,
        output wire Y1,
        output wire Y2,
        output wire Y3
    );

	nand ls10[0:2] ( {Y3, Y2, Y1}, {A3, A2, A1}, {B3, B2, B1}, {C3, C2, C1} );
endmodule
