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
  74LS48
  ------
  BCD to 7-Segment Decoder

  Pinout
  ------
          _______
         |       |
     a1 -| 1  14 |- VCC
     a2 -| 2  13 |- f
    _lt -| 3  12 |- g
_bi_rbo -| 4  11 |- a
   _rbi -| 5  10 |- b
     a3 -| 6   9 |- c
     a0 -| 7   8 |- d
    GND -| 8   9 |- e    
         |_______|
*/
`default_nettype none

module ls48
(
    input wire  _lt, _rbi, a3, a2, a1, a0, _bi_rbo,
    output wire a, b, c, d, e, f, g
);

wire _a3, _a2, _a1, _a0;
not(_a3, a3);
nand(_a2, a2, _lt);
nand(_a1, a1, _lt);
nand(_a0, a0, _lt);

wire d1, d2, a3_2, a2_2, a1_2, a0_2;
nand(d1, _lt, ~_rbi, _a3, _a2, a2_2, _a0);
assign d2 = _bi_rbo == 1'b1 ? d1 : 1'b0;
nand(a3_2, d2, _a3);
nand(a2_2, d2, _a2);
nand(a1_2, d2, _a1);
nand(a0_2, d2, _a0);

// segment a
wire aa1, aa2, aa3;
and(aa1, _a3, _a2, _a1, a0_2);
and(aa2, a2_2, _a0);
and(aa3, a3_2, a1_2);
and(a, ~aa1, ~aa2, ~aa3);

// segment b
wire bb1, bb2, bb3;
and(bb1, a2_2, a1_2, _a0);
and(bb2, a2_2, _a1, a0_2);
and(bb3, a3_2, a1_2);
and(b, ~bb1, ~bb2, ~bb3);

// segment c
wire cc1, cc2;
and(cc1, _a2, a1_2, _a0);
and(cc2, a3_2, a2_2);
and(c, ~cc1, ~cc2);

// segment d
wire dd1, dd2, dd3;
and(dd1, a2_2, a1_2, a0_2);
and(dd2, a2_2, _a1, _a0);
and(dd3, _a2, _a1, a0_2);
and(d, ~dd1, ~dd2, ~dd3);

// segment e
wire ee1;
and(ee1, a2_2, _a1);
and(e, ~ee1, ~a0_2);

// segment f
wire ff1, ff2, ff3;
and(ff1, _a3, _a2, a0_2);
and(ff2, _a2, a1_2);
and(ff3, a1_2, a0_2);
and(f, ~ff1, ~ff2, ~ff3);

// segment g
wire gg1, gg2;
and(gg1, _lt, _a3, _a2, _a1);
and(gg2, a2_2, a1_2, a0_2);
and(g, ~gg1, ~gg2);

endmodule
