`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    04:44:19 04/23/2014 
// Design Name: 
// Module Name:    VGAOut 
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
module VGAOut(Clk, vga_h_sync, vga_v_sync, inDisplayArea, CounterX, CounterY);
input Clk;
output vga_h_sync, vga_v_sync;
output inDisplayArea;
output [9:0] CounterX;
output [8:0] CounterY;

//////////////////////////////////////////////////
reg [9:0] CounterX;
reg [8:0] CounterY;
wire CounterXmaxed = (CounterX==10'h2FF);

always @(posedge Clk)
if(CounterXmaxed)
	CounterX <= 0;
else
	CounterX <= CounterX + 1;

always @(posedge Clk)
if(CounterXmaxed) CounterY <= CounterY + 1;

reg	vga_HS, vga_VS;
always @(posedge Clk)
begin
	vga_HS <= (CounterX[9:4]==6'h2D); // change this value to move the display horizontally
	vga_VS <= (CounterY==500); // change this value to move the display vertically
end

reg inDisplayArea;
always @(posedge Clk)
if(inDisplayArea==0)
	inDisplayArea <= (CounterXmaxed) && (CounterY<480);
else
	inDisplayArea <= !(CounterX==639);
	
assign vga_h_sync = ~vga_HS;
assign vga_v_sync = ~vga_VS;

endmodule