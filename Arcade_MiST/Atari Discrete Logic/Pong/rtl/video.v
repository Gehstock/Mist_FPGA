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
  Pong - Video Generator Circuit
  ------------------------------
*/
`default_nettype none

module video
(
    input wire  score, _hsync, _vsync, pad1, pad2, net, _hvid, _vvid,
    output wire score_1_2k, sync_2_2k, pads_net_1k, _hit, _hit2, hit, _hit1
);

wire a4d_to_e4e;
ls86 a4d(_hsync, _vsync, a4d_to_e4e);
ls04 e4e(a4d_to_e4e, sync_2_2k);

wire f2b_to_e4f;
ls25 f2b(pad1, net, pad2, g1b_out, 1'b1, f2b_to_e4f);
ls04 e4f(f2b_to_e4f, pads_net_1k);

wire g1b_out;
ls02 g1b(_hvid, _vvid, g1b_out);

ls00 g3a(pad2, g1b_out, _hit2);
ls00 g3d(pad1, g1b_out, _hit1);

ls00 b2c(_hit1, _hit2, hit);
ls00 b2d(hit, hit, _hit);

assign score_1_2k = score;

endmodule
