`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:56:03 02/22/2008 
// Design Name: 
// Module Name:    cgrom 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module cgrom(	addr, dout, en);
	input [10:0] addr;
	output [7:0] dout;
	input en;
	
	reg [7:0] mem [0:2047];
	
	assign dout = en ? mem[addr] : 8'hzz;
	
	initial $readmemh( "roms/cg_jp_hex.hex", mem );

endmodule
