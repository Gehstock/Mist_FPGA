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
  Pong - Score Counters Circuit
  -----------------------------
*/
`default_nettype none

module score_counters
(
    input wire [7:0]  /* verilator lint_off UNUSED */ dip_sw /* verilator lint_on UNUSED */,
    input wire  _hvid, hblank, _attract, l, r, srst, _srst,
    output wire _miss, stop_g, s1a, s1b, s1c, s1d, s1e, _s1e,
    output wire s2a, s2b, s2c, s2d, s2e, _s2e
);

wire h6a_to_e6c, d1f_to_e1a, _missed, f5b_to_c7, f5a_to_d7;

ls20 h6a(_hvid, _hvid, _hvid, _hvid, h6a_to_e6c);
ls00 e6c(h6a_to_e6c, hblank, _miss);
ls04 d1f(_miss, d1f_to_e1a);
ls00 e1a(d1f_to_e1a, _attract, _missed);
ls02 f5b(_missed, l, f5b_to_c7);
ls02 f5a(_missed, r, f5a_to_d7);

ls90 c7(f5b_to_c7, 1'b1, srst, srst, 1'b0, 1'b0, s1a, s1b, s1c, s1d);
ls107 c8a(s1d, _srst, 1'b1, 1'b1, s1e, _s1e);

ls90 d7(f5a_to_d7, 1'b1, srst, srst, 1'b0, 1'b0, s2a, s2b, s2c, s2d);
ls107 c8b(s2d, _srst, 1'b1, 1'b1, s2e, _s2e);

// stop_g signal handling
// dip_sw[0] = 0 - 11 points
// dip_sw[0] = 1 - 15 points
wire d8a_out;
ls10 d8a(s1a, dip_sw[0] ? s1c : 1'b1, s1e, d8a_out);
wire d8b_out;
ls10 d8b(s2a, dip_sw[0] ? s2c : 1'b1, s2e, d8b_out);
ls00 b2a(d8a_out, d8b_out, stop_g);

endmodule
