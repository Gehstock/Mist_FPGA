`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    04:51:28 04/23/2014 
// Design Name: 
// Module Name:    SlowClock 
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
module SlowClock(input Clk,Reset,output reg [24:0] Clks);
initial Clks = 0;
		
		always @ (posedge Clk)
		begin
			if (!Reset) Clks <= 0;
			if(Clks > 25000000) Clks <= 0;
			else Clks <= Clks + 1;
		end

endmodule
