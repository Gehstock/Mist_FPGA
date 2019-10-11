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
  DM9316
  ------
  Synchronous 4-Bit Counters
  
  Pinout
  ------
          _______
         |       |
   _clr -| 1  16 |- VCC
    clk -| 2  15 |- carry
      a -| 3  14 |- qa
      b -| 4  13 |- qb
      c -| 5  12 |- qc
      d -| 6  11 |- qd
   en_p -| 7  10 |- en_t
    GND -| 8   9 |- _load
         |_______|
*/
`default_nettype none

module dm9316
(
    input wire  clk, _clr, a, b, c, d, _load, en_p, en_t,
    output wire qa, qb, qc, qd, carry
);

wire _clk, load, _en_p, _en_t;

not(_clk, clk);
not(load, _load);
not(_en_p, en_p);
not(_en_t, en_t);

wire a1;
nor(a1, load, _en_p, _en_t);

wire b1, b2, bb3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14, b15, b16;
and(b1, qa, a1);
and(b2, load, c2);
and(bb3, a, load);
and(b4, a1, _qa);
and(b5, qb, qa, a1);
and(b6, load, c4);
and(b7, b, load);
and(b8, a1, qa, _qb);
and(b9, qc, qa, qb, a1);
and(b10, load, c6);
and(b11, c, load);
and(b12, a1, qa, qb, _qc);
and(b13, qd, qa, qb, qc, a1);
and(b14, load, c8);
and(b15, d, load);
and(b16, a1, qa, qb, qc, _qd);

wire c1, c2, c3, c4, c5, c6, c7, c8;
nor(c1, b1, b2);
nor(c2, bb3, b4);
nor(c3, b5, b6);
nor(c4, b7, b8);
nor(c5, b9, b10);
nor(c6, b11, b12);
nor(c7, b13, b14);
nor(c8, b15, b16);

nor(carry, _qd, _qc, _qb, _qa, _en_t);

wire _qa, _qb, _qc, _qd;
png_jkff ff1(_clk, ~c2, ~c1, 1'b1, _clr, qa, _qa);
png_jkff ff2(_clk, ~c4, ~c3, 1'b1, _clr, qb, _qb);
png_jkff ff3(_clk, ~c6, ~c5, 1'b1, _clr, qc, _qc);
png_jkff ff4(_clk, ~c8, ~c7, 1'b1, _clr, qd, _qd);

endmodule
