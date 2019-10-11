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
  74LS50
  ------
  Dual 2-Wide 2-Input And-Or-Invert Gates (One Gate Expandable)
  
  Pinout
  ------
          _______
         |       |
     a1 -| 1  14 |- VCC
     a2 -| 2  13 |- b1
     b2 -| 3  12 |- _x1
     c2 -| 4  11 |- x1
     d2 -| 5  10 |- d1
     y2 -| 6   9 |- c1
    GND -| 7   8 |- y1
         |_______|
*/
`default_nettype none

module ls50
(
    input wire  a, b, c, d,
    output wire y
);

wire a2, b2;
and(a2, a, b);
and(b2, c, d);
nor(y, a2, b2);

// TODO: What's the purpose with x1 and _x1?

endmodule
