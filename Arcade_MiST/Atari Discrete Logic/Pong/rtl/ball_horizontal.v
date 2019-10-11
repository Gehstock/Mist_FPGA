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
  Pong - Ball Horizontal Circuit
  ------------------------------
*/
`default_nettype none

module ball_horizontal
(
    input wire _h256, vreset, rst_speed, hit_sound, _hit2, sc, attract, _hit1, _hblank, clk7_159, _attract, serve,
    output wire l, r, _hvid
);

wire move, aa, ba;
ball_horizontal_move        ball_hor_mov(_h256, vreset, rst_speed, hit_sound, move);
ball_horizontal_direction   ball_hor_dir(move, _hit2, sc, attract, _hit1, l, r, aa, ba);
ball_horizontal_video       ball_hor_video(aa, ba, _hblank, clk7_159, _attract, serve, _hvid);

endmodule
