/*
  MIT License

  Copyright (c) 2019 Richard Eng

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
*/

/*
  Pong - Paddles Circuit
  ----------------------
*/
`default_nettype none

module paddles
(
    input wire [7:0] paddle1_vpos, input wire [7:0] paddle2_vpos, input wire _hsync, _v256, _attract, h4, h128, h256, _h256,
    output wire b1, c1, d1, pad1, b2, c2, d2, pad2 
);

wire _vpad1;
paddle p1(paddle1_vpos, _hsync, _v256, b1, c1, d1, _vpad1);

wire _vpad2;
paddle p2(paddle2_vpos, _hsync, _v256, b2, c2, d2, _vpad2);

/* verilator lint_off UNUSED */  
wire h3a_q;
/* verilator lint_on UNUSED */  
wire h3a__q;
ls74 h3a(h4, h128, 1'b1, _attract, h3a_q, h3a__q);

wire g3c_out;
ls00 g3c(h128, h3a__q, g3c_out);

wire g2c_out;
ls27 g2c(_vpad1, h256, g3c_out, g2c_out);
assign pad1 = g2c_out;

wire g2a_out;
ls27 g2a(_vpad2, _h256, g3c_out, g2a_out);
assign pad2 = g2a_out;

endmodule
