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
  74LS74
  ------
  Dual Positive-Edge-Triggered D Flip-Flops with
  Preset, Clear and Complementary Outputs

  Pinout
  ------
          _______
         |       |
  _clr1 -| 1  14 |- VCC
     d1 -| 2  13 |- _clr2
   clk1 -| 3  12 |- d2
   _pr1 -| 4  11 |- clk2
     q1 -| 5  10 |- _pr2
    _q1 -| 6   9 |- q2
    GND -| 7   8 |- _q2
         |_______|
*/
`default_nettype none

module ls74
(
    input wire  clk, d, _clr, _pr,
    output reg  q,
    output wire _q
);

initial begin
  q = 1'b0;
end

always @(posedge clk or negedge _clr or negedge _pr) begin
    if (_clr == 1'b0) begin
      q <= 1'b0;
    end else if (_pr == 1'b0) begin
      q <= 1'b1;
    end else begin
      q <= d;
    end
end

assign _q = ~q;

endmodule
