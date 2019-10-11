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

module score
(
    input wire [7:0] dip_sw,
    input wire _hvid, hblank, _attract, l, r, srst, _srst,
    input wire h4, h8, h16, h32, h64, h128, h256, v4, v8, v16, v32, v64, v128,    
    output wire _miss, stop_g, score
);

wire a, b, c, d, e, f, g;
wire s1a, s1b, s1c, s1d, s1e, _s1e;
wire s2a, s2b, s2c, s2d, s2e, _s2e;

score_counters sb1(dip_sw, _hvid, hblank, _attract, l, r, srst, _srst, _miss, stop_g, s1a, s1b, s1c, s1d, s1e, _s1e, s2a, s2b, s2c, s2d, s2e, _s2e);
score_counters_to_segments sb2(s1a, s1b, s1c, s1d, s1e, _s1e, s2a, s2b, s2c, s2d, s2e, _s2e, h32, h64, h128, h256, v32, v64, v128, a, b, c, d, e, f, g);
score_segments_to_video sb3(h4, h8, h16, v4, v8, v16, a, b, c, d, e, f, g, score);

endmodule
