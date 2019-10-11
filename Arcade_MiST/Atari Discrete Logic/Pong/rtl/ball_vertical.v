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
  Pong - Ball Vertical Circuit
  ----------------------------
*/
`default_nettype none

module ball_vertical
(
    input wire  _hsync, _vblank, vblank, _hit, d1, _h256, d2, h256, c1, c2, b2, b1, attract, hit,
    output wire vball16, vball32, vball240, _vvid, vvid
);

wire ab, bb, cb, db;
ball_vertical_move bal_vert_move(vvid, vblank, _hit, d1, _h256, d2, h256, c1, c2, b2, b1, attract, hit, ab, bb, cb, db);
ball_vertical_counter bal_vert(_hsync, _vblank, ab, bb, cb, db, vball16, vball32, vball240, _vvid, vvid);

endmodule
