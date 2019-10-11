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
  Pong - Ball Horizontal Move Circuit
  -----------------------------------
*/
`default_nettype none

module ball_horizontal_move
(
    input wire _h256, vreset, rst_speed, hit_sound,
    output wire move
);

wire e1d_to_f1;
ls00 e1d(e1c_out, hit_sound, e1d_to_f1);

wire unused2, unused3, qc, qd;
ls93 f1(e1d_to_f1, 1'b0, rst_speed, rst_speed, unused2, unused3, qc, qd);

wire e1c_out;
ls00 e1c(qc, qd, e1c_out);

wire g1d_to_h1a;
ls02 g1d(qc, qd, g1d_to_h1a);

wire h1a_out;
ls00 h1a(g1d_to_h1a, g1d_to_h1a, h1a_out);

wire h1d_to_h1c;
ls00 h1d(e1c_out, h1a_out, h1d_to_h1c);

wire h1c_to_h2b;
ls00 h1c(vreset, h1d_to_h1c, h1c_to_h2b);

wire h1b_to_h2a;
ls00 h1b(h1a_out, vreset, h1b_to_h2a);

wire g1c_out;
ls02 g1c(_h256, vreset, g1c_out);

wire unused4, h2b_out;
ls107 h2b(g1c_out, h1c_to_h2b, 1'b1, move, h2b_out, unused4);

wire unused5, h2a_to_h4a;
ls107 h2a(g1c_out, h1b_to_h2a, h2b_out, 1'b0, h2a_to_h4a, unused5);

ls00 h4a(h2b_out, h2a_to_h4a, move);

endmodule
