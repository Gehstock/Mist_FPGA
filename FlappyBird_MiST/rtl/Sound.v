`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:36:33 04/27/2014 
// Design Name: 
// Module Name:    Sound 
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
module Sound(
input clk,input [15:0] PipesPosition1,input [15:0] PipesPosition2,
output reg speaker
);
reg [25:0] clkdivider;

//parameter clkdivider = 25000000/440/2;
always @ (PipesPosition1 or PipesPosition2)
if (PipesPosition1 < 10 || PipesPosition2 < 10) clkdivider <= 25000000/440/2;
else clkdivider <= 2;

reg [14:0] counter;
always @(posedge clk) if(counter==0) counter <= clkdivider-1; else counter <= counter-1;


always @(posedge clk) if(counter==0) speaker <= ~speaker;
endmodule
