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
  Pong - Ball Vertical Move Circuit
  ---------------------------------
*/
`default_nettype none

module ball_vertical_move
(
    input wire vvid, vblank, _hit, d1, _h256, d2, h256, c1, c2, b2, b1, attract, hit,
    output wire ab, bb, cb, db
);

wire b6b_out;
ls50 b6b(_h256, d1, d2, h256, b6b_out);

wire a6b_out;
ls50 a6b(_h256, c1, c2, h256, a6b_out);

wire a6a_out;
ls50 a6a(b2, _h256, h256, b1, a6a_out);

wire d1c_out;
ls04 d1c(attract, d1c_out);

wire b5a_q, b5a__q;
ls74 b5a(hit, b6b_out, d1c_out, 1'b1, b5a_q, b5a__q);

wire a5a_q, /* verilator lint_off UNUSED */ a5a__q /* verilator lint_on UNUSED */;
ls74 a5a(hit, a6b_out, d1c_out, 1'b1, a5a_q, a5a__q);

wire a5b_q, /* verilator lint_off UNUSED */ a5b__q /* verilator lint_on UNUSED */;
ls74 a5b(hit, a6a_out, d1c_out, 1'b1, a5b_q, a5b__q);

wire a2a_q, a2a__q;
ls107 a2a(vblank, _hit, vvid, vvid, a2a_q, a2a__q);

wire b6a_out;
ls50 b6a(a2a_q, b5a_q, a2a__q, b5a__q, b6a_out);

wire a4b_out;
ls86 a4b(a2a_q, a5a_q, a4b_out);

wire a4c_out;
ls86 a4c(a5b_q, a2a_q, a4c_out);

wire c4a_out;
ls10 c4a(b6a_out, b6a_out, b6a_out, c4a_out);

wire /* verilator lint_off UNUSED */ b4_c4 /* verilator lint_on UNUSED */;
ls83 b4(a4c_out, a4b_out, b6a_out, 1'b0, c4a_out, 1'b1, 1'b1, 1'b0, 1'b0, ab, bb, cb, db, b4_c4);

endmodule
