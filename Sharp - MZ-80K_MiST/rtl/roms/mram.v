`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:04:18 02/22/2008 
// Design Name: 
// Module Name:    mram 
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
module mram(addr,din,dout,en,we);
	input [14:0] addr;
	input [7:0] din;
	output [7:0] dout;
	input en, we;
	
	reg [7:0] mem [0:32767];
	wire	WRITE, READ;
	
	always @( WRITE or din ) begin
		if ( WRITE )
			mem[ addr ] <= din;
	end
	
	assign READ	= ~we & en;
	assign WRITE = we & en;
	
	assign dout = READ ? mem[ addr ] : 8'hzz;
	
	initial $readmemh( "roms/mon_rom_jp.hex.hex", mem );

endmodule
