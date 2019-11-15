//===============================================================================
// FPGA DONKEY KONG  used LOGIC IP 
//
// Version : 1.00
//
// Copyright(c) 2003 - 2004 Katsumi Degawa , All rights reserved
//
// Important !
//
// This program is freeware for non-commercial use. 
// An author does no guarantee about this program.
// You can use this under your own risk.
//
//================================================================================

//================================================
// 74xx109
// JK FLIP-FLOPS with PRESET & RST
//     PRESET NO USE
//================================================

module  logic_74xx109(

CLK,
RST,
I_J,
I_K,
O_Q

);

input  CLK,RST;
input  I_J,I_K;
output O_Q;

reg    Q;

assign O_Q   = Q;

always@(posedge CLK or negedge RST)
begin
   if(RST == 1'b0) Q <= 1'b0;
   else begin
      case({I_J,I_K})
         2'b00: Q <= 1'b0;
         2'b01: Q <= Q;
         2'b10: Q <= ~Q;
         2'b11: Q <= 1'b1;
      endcase
   end
end

endmodule

//================================================
// 74xx138
// 3-to-8 line decoder
//================================================

module  logic_74xx138(

I_G1,
I_G2a,
I_G2b,
I_Sel,
O_Q

);

input  I_G1,I_G2a,I_G2b;
input  [2:0]I_Sel;
output [7:0]O_Q;

reg    [7:0]O_Q;
wire   [2:0]I_G = {I_G1,I_G2a,I_G2b};
always@(I_G or I_Sel or O_Q)
begin
   if(I_G == 3'b100 )begin
      case(I_Sel)
         3'b000: O_Q = 8'b11111110;
         3'b001: O_Q = 8'b11111101;
         3'b010: O_Q = 8'b11111011;
         3'b011: O_Q = 8'b11110111;
         3'b100: O_Q = 8'b11101111;
         3'b101: O_Q = 8'b11011111;
         3'b110: O_Q = 8'b10111111;
         3'b111: O_Q = 8'b01111111;
	  endcase
   end
   else begin
      O_Q = 8'b11111111;
   end
end
endmodule

//================================================
// 74xx139
// 2-to-4 line decoder
//================================================

module  logic_74xx139(

I_G,
I_Sel,
O_Q

);

input  I_G;
input  [1:0]I_Sel;
output [3:0]O_Q;

reg    [3:0]O_Q;
always@(I_G or I_Sel or O_Q)
begin
   if(I_G == 1'b0 )begin
      case(I_Sel)
         2'b00: O_Q = 4'b1110;
         2'b01: O_Q = 4'b1101;
         2'b10: O_Q = 4'b1011;
         2'b11: O_Q = 4'b0111;
	  endcase
   end
   else begin
      O_Q = 4'b1111;
   end
end
endmodule