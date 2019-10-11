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
  Pong - Score Counters to Segments Circuit
  -----------------------------------------
*/
`default_nettype none

module score_counters_to_segments
(
    input wire s1a, s1b, s1c, s1d, /* verilator lint_off UNUSED */ s1e /* verilator lint_on UNUSED */, _s1e,
    input wire s2a, s2b, s2c, s2d, /* verilator lint_off UNUSED */ s2e /* verilator lint_on UNUSED */, _s2e,
    input wire h32, h64, h128, h256, v32, v64, v128,
    output wire a, b, c, d, e, f, g
);

wire c6_y1, c6_y2, d6_y1, d6_y2;
ls153 c6(1'b0, 1'b0, h32, h64, 1'b1, s1a, 1'b1, s2a, _s1e, s1b, _s2e, s2b, c6_y1, c6_y2);
ls153 d6(1'b0, 1'b0, h32, h64, _s1e, s1c, _s2e, s2c, _s1e, s1d, _s2e, s2d, d6_y1, d6_y2);

ls48 c5(1'b1, 1'b1, d6_y2, d6_y1, c6_y2, c6_y1, f2a_out, a, b, c, d, e, f, g);

wire e3a_out, e3b_out, e2c_out, e3c_out, d2c_out;
ls27 e3a(h128, h128, h128, e3a_out);
ls27 e3b(h256, h64, e3a_out, e3b_out);
ls10 e2c(e3a_out, h64, h256, e2c_out);
ls27 e3c(e2c_out, e2c_out, e2c_out, e3c_out);
ls02 d2c(e3b_out, e3c_out, d2c_out);

wire g1a_out;
ls02 g1a(v32, v32, g1a_out);

wire f2a_out;
ls25 f2a(g1a_out, v64, v128, d2c_out, 1'b1, f2a_out);

endmodule
