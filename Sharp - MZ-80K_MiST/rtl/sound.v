`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    08:54:34 02/19/2008 
// Design Name: 
// Module Name:    clock_gen 
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
module sound(CLK_50MHZ, SW, TP1);
	input CLK_50MHZ;
	input SW;
	output TP1;
	reg [14:0] count = 0;
	reg [14:0] count2 = 1;
	reg CLK = 0;
	wire TP1;

	always @(posedge CLK_50MHZ)
	begin
		count <= count + 1;
	end

	always @(posedge count[12])
	begin
		if ( count2 >= SW )
		begin
			CLK <= SW != 0 ? ~CLK: CLK;
			count2 <= 1;
		end else
		begin
			count2 <= count2 + 1;
		end
	end
	
	assign TP1 = CLK;

endmodule
