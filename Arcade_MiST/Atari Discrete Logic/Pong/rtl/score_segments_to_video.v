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
  Pong - Score Segments to Video Circuit
  --------------------------------------
*/
`default_nettype none

module score_segments_to_video
(
    input wire h4, h8, h16, v4, v8, v16,
    input wire a, b, c, d, e, f, g,
    output wire score
);

wire c3d_out;
ls00 c3d(h4, h8, c3d_out);

wire e4b_out;
ls04 e4b(h16, e4b_out);

wire e2a_out;
ls10 e2a(v4, v8, h16, e2a_out);

wire e4a_out;
ls04 e4a(e2a_out, e4a_out);

wire e4c_out;
ls04 e4c(v16, e4c_out);

wire e5c_out;
ls27 e5c(e4b_out, h4, h8, e5c_out);

wire d2b_out;
ls02 d2b(c3d_out, e4b_out, d2b_out);

wire e5b_out;
ls27 e5b(v8, v4, e4b_out, e5b_out);

wire d4a_out;
ls10 d4a(e4c_out, f, e5c_out, d4a_out);

wire d5c_out;
ls10 d5c(e, v16, e5c_out, d5c_out);

wire c4c_out;
ls10 c4c(d2b_out, e4c_out, b, c4c_out);

wire d5a_out;
ls10 d5a(d2b_out, c, v16, d5a_out);

wire d4c_out;
ls10 d4c(a, e4c_out, e5b_out, d4c_out);

wire d4b_out;
ls10 d4b(g, e4a_out, e4c_out, d4b_out);

wire d5b_out;
ls10 d5b(e4a_out, v16, d, d5b_out);

ls30 d3(d4a_out, d5c_out, c4c_out, d5a_out, 1'b1, d4c_out, d4b_out, d5b_out, score);

endmodule
