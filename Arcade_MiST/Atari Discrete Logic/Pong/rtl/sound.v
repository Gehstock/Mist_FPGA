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
  Pong - Sound Circuit
  --------------------
*/
`default_nettype none

module sound
(
    input wire  clk7_159, _miss, v32, vball16, _hit, vball240, _serve, _vvid, vblank, vvid, vball32, _attract,
    output wire sc, hit_sound, sound_out
);

timer #(7_159_000, 240) g4(clk7_159, _miss, sc);

wire c3c_to_c4b;
ls00 c3c(v32, sc, c3c_to_c4b);

/* verilator lint_off UNUSED */  
wire c2a_q;
/* verilator lint_on UNUSED */  
wire c2a__q;
ls74 c2a(vball240, 1'b1, _hit, 1'b1, c2a_q, c2a__q);
assign hit_sound = c2a__q;

wire c3a_to_c4b;
ls00 c3a(c2a__q, vball16, c3a_to_c4b);

wire f3a_q;
/* verilator lint_off UNUSED */  
wire f3a__q;
/* verilator lint_on UNUSED */  
ls107 f3a(vblank, _serve, vvid, _vvid, f3a_q, f3a__q);

wire c3b_to_c4b;
ls00 c3b(vball32, f3a_q, c3b_to_c4b);

wire c4b_to_c1b;
ls10 c4b(c3b_to_c4b, c3a_to_c4b, c3c_to_c4b, c4b_to_c1b);

wire c1b_out;
ls00 c1b(_attract, c4b_to_c1b, c1b_out);
assign sound_out = c1b_out;

endmodule
