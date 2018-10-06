`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:04:28 04/24/2014 
// Design Name: 
// Module Name:    Random 
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
/*module Random(input Clk,req,output reg [7:0] Num);
reg [7:0] Position;
initial Position = 8'b00000000;
always@(posedge Clk)
begin
	Position[0] <= Position[7] ^ Position[5];
end

always@(posedge req)
begin
	Num <= Position;
end
endmodule*/

module LFSR (
    input clock,
    input reset,
    output [12:0] rnd
    );

wire feedback = random[12] ^ random[3] ^ random[2] ^ random[0];
 
reg [12:0] random, random_next, random_done;
reg [3:0] count, count_next; //to keep track of the shifts
 
always @ (posedge clock or posedge reset)
begin
 if (reset)
 begin
  random <= 13'hF; //An LFSR cannot have an all 0 state, thus reset to FF
  count <= 0;
 end
  
 else
 begin
  random <= random_next;
  count <= count_next;
 end
end
 
always @ (*)
begin
 random_next = random; //default state stays the same
 count_next = count;
   
  random_next = {random[11:0], feedback}; //shift left the xor'd every posedge clock
  count_next = count + 1;
 
 if (count == 13)
 begin
  count = 0;
  random_done = random; //assign the random number to output after 13 shifts
 end
  
end
 
 
assign rnd = random_done;
 
endmodule