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
  74LS107
  -------
  Dual Negative-Edge-Triggered J-K Flip-Flops with clear
  
  Pinout
  ------
          _______
         |       |
     j1 -| 1  14 |- VCC
    _q1 -| 2  13 |- _clr1
     q1 -| 3  12 |- _clk1
     k1 -| 4  11 |- k2
     q2 -| 5  10 |- _clr2
    _q2 -| 6   9 |- _clk2
    GND -| 7   8 |- j2
         |_______|
*/
`default_nettype none

module ls107
(
    input wire  _clk, _clr, j, k,
    output reg  q,
    output wire _q
);

initial q = 1'b0;

always @(negedge _clk or negedge _clr) begin
    if (_clr == 1'b0) begin
      q <= 1'b0;
    end else if (j == 1'b1 && k == 1'b0) begin
      q <= 1'b1;
    end else if (j == 1'b0 && k == 1'b1) begin
      q <= 1'b0;
    end else if (j == 1'b1 && k == 1'b1) begin
      q <= ~q;
    end
end

assign _q = ~q;

endmodule
