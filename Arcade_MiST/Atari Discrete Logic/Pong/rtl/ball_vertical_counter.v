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
  Pong - Ball Vertical Counter Circuit
  ------------------------------------
*/
`default_nettype none

module ball_vertical_counter
(
    input wire _hsync, _vblank, ab, bb, cb, db,
    output wire vball16, vball32, vball240, _vvid, vvid
);

wire b3_carry, /* verilator lint_off UNUSED */ b3qa, b3qb /* verilator lint_on UNUSED */, b3qc, b3qd;
dm9316 b3(_hsync, 1'b1, ab, bb, cb, db, b2b_out, 1'b1, _vblank, b3qa, b3qb, b3qc, b3qd, b3_carry);

wire a3_carry, a3qa, a3qb, /* verilator lint_off UNUSED */ a3qc, a3qd /* verilator lint_on UNUSED */;
dm9316 a3(_hsync, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, b2b_out, b3_carry, 1'b1, a3qa, a3qb, a3qc, a3qd, a3_carry);

wire b2b_out;
ls00 b2b(a3_carry, b3_carry, b2b_out);

wire e2b_out;
ls10 e2b(a3_carry, b3qd, b3qc, e2b_out);

ls02 d2d(e2b_out, e2b_out, vvid);

assign _vvid = e2b_out;
assign vball240 = a3_carry;
assign vball16 = a3qa;
assign vball32 = a3qb;

endmodule
