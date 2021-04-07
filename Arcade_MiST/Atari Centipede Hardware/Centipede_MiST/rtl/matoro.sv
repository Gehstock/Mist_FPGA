`timescale 1ns / 1ps
module m_range_check
  #(parameter WIDTH = 6)
   (input logic [WIDTH-1:0] val, low, high,
    output logic is_between);

   logic 	 smallEnough, largeEnough;
  
   m_comparator #(WIDTH) lc(,,largeEnough, low, val);
   m_comparator #(WIDTH) hc(,,smallEnough, val, high);

   assign is_between = ~smallEnough & ~largeEnough;
   
endmodule: m_range_check

module m_offset_check
  #(parameter WIDTH = 6)
   (input logic [WIDTH-1:0] val, low, delta,
    output logic is_between);

   logic 	 [WIDTH-1:0] high;
   
   m_adder #(WIDTH) add(high,, low, delta, 1'b0);
   m_range_check #(WIDTH) rc(.*);

endmodule: m_offset_check

module m_comparator
  #(parameter WIDTH = 6)
  (output logic AltB, AeqB, AgtB,
   input logic [WIDTH-1:0] A, B);

   assign AltB = (A < B);
   assign AeqB = (A == B);
   assign AgtB = (A > B);

endmodule: m_comparator

module m_adder
  #(parameter WIDTH = 6)
   (output logic [WIDTH-1:0] Sum,
    output logic Cout,
    input logic [WIDTH-1:0] A, B,
    input logic Cin);
   
   assign {Cout, Sum} = A + B + Cin;

endmodule: m_adder

module m_mux
  #(parameter WIDTH = 6)
   (output logic Y,
    input logic [WIDTH-1:0] I,
    input logic [$clog2(WIDTH)-1:0] Sel);

   assign Y = I[Sel];

endmodule: m_mux

module m_mux2to1
  #(parameter WIDTH = 6)
   (output logic [WIDTH-1:0] Y,
    input logic [WIDTH-1:0] I0, I1,
    input logic Sel);

   assign Y = (Sel ? I1 : I0);

endmodule: m_mux2to1

module m_decoder
  #(parameter WIDTH = 6)
   (output logic [(1 << WIDTH)-1:0] D,
    input logic [WIDTH-1:0] I,
    input logic en);

   assign D = en << I;

endmodule: m_decoder

module m_register
  #(parameter WIDTH = 6)
   (output logic [WIDTH-1:0] Q,
    input logic [WIDTH-1:0] D,
    input logic clr, en, clk);

   always_ff @(posedge clk)
      if(clr)
	Q <= 0;
      else if(en)
	Q <= D;
   
endmodule: m_register

module m_counter
  #(parameter WIDTH = 6)
   (output logic [WIDTH-1:0] Q,
    input logic [WIDTH-1:0] D,
    input logic clk, clr, load, en, up);

   always_ff @(posedge clk) begin
      if(clr)
	Q <= 0;
      else if(load)
	Q <= D;
      else if(en)
	Q <= (up ? Q + 1 : Q - 1);
      end
endmodule: m_counter

module m_shift_register
  #(parameter WIDTH = 6)
   (output logic [WIDTH-1:0] Q,
    input logic clk, en, left, s_in, clr);

   always_ff @(posedge clk)
     if (clr) begin
	Q <= 'd0;
     end
     else if(en) begin
	if(left) begin
	   Q <= (Q << 1);
	   Q[0] <= s_in;
	end
	else begin
	   Q <= (Q >> 1);
	   Q[WIDTH-1] <= s_in;
	end
     end
endmodule: m_shift_register
