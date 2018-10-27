`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    03:54:03 04/24/2014 
// Design Name: 
// Module Name:    StatusChecker 
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
module StatusChecker(input Reset,CounterX,input R_Pipes_off,input R_Pipes2_off,input R_Bird_off,output reg Status);
initial Status = 1;
always @ (posedge CounterX)
begin

if (!Reset) Status <= 1;
if ((R_Pipes_off && R_Bird_off) || (R_Pipes2_off && R_Bird_off)) Status <= 0;

end
endmodule
