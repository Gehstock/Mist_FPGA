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
  74LS153
  ------
  Dual 1-of-4 Line Data Selectors/Multiplexers

  Pinout
  ------
          _______
         |       |
_stb_g1 -| 1  16 |- VCC
  sel_b -| 2  15 |- _stb_g2
   g1c3 -| 3  14 |- sel_a
   g1c2 -| 4  13 |- g2c3
   g1c1 -| 5  12 |- g2c2
   g1c0 -| 6  11 |- g2c1
     y1 -| 7  10 |- g2c0
    GND -| 8   9 |- y2    
         |_______|
*/
`default_nettype none

module ls153
(
    input wire _stb_g1, _stb_g2, sel_a, sel_b, g1c0, g1c1, g1c2, g1c3, g2c0, g2c1, g2c2, g2c3,
    output wire y1, y2
);

wire cc1, cc2, cc3, cc4, cc5, cc6, cc7, cc8;
and(cc1, ~_stb_g1, ~sel_b, ~sel_a, g1c0);
and(cc2, ~_stb_g1, ~sel_b, sel_a, g1c1);
and(cc3, ~_stb_g1, sel_b, ~sel_a, g1c2);
and(cc4, ~_stb_g1, sel_b, sel_a, g1c3);

and(cc5, ~_stb_g2, ~sel_b, ~sel_a, g2c0);
and(cc6, ~_stb_g2, ~sel_b, sel_a, g2c1);
and(cc7, ~_stb_g2, sel_b, ~sel_a, g2c2);
and(cc8, ~_stb_g2, sel_b, sel_a, g2c3);

or(y1, cc1, cc2, cc3, cc4);
or(y2, cc5, cc6, cc7, cc8);

endmodule
