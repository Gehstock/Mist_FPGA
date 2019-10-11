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
  Pong - Ball Horizontal Video Circuit
  ------------------------------------
*/
`default_nettype none

module ball_horizontal_video
(
    input wire aa, ba, _hblank, clk7_159, _attract, serve,
    output wire _hvid
);

wire _clr;
ls00 e1b(_attract, serve, _clr);

wire /* verilator lint_off UNUSED */ qa, qb /* verilator lint_on UNUSED */, qc, qd, g7_carry, h7_carry;
dm9316 g7(clk7_159, _clr, aa, ba, 1'b0, 1'b1, _load, 1'b1, _hblank, qa, qb, qc, qd, g7_carry);
wire /* verilator lint_off UNUSED */ qa2, qb2, qc2, qd2 /* verilator lint_on UNUSED */;
dm9316 h7(clk7_159, _clr, 1'b0, 1'b0, 1'b0, 1'b1, _load, g7_carry, 1'b1, qa2, qb2, qc2, qd2, h7_carry);

wire unused, g6b_out;
ls107 g6b(h7_carry, _clr, 1'b1, 1'b1, g6b_out, unused);

wire _load;
ls10 g5c(h7_carry, g7_carry, g6b_out, _load);
ls20 h6b(qc, qd, h7_carry, g6b_out, _hvid);

endmodule
