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
  74LS83
  ------
  4-Bit Binary Adder with Fast Carry
  
  Pinout
  ------
          _______
         |       |
     a4 -| 1  16 |- b4
     s3 -| 2  15 |- s4
     a3 -| 3  14 |- c4
     b3 -| 4  13 |- c0
    VCC -| 5  12 |- GND
     s2 -| 6  11 |- b1
     b2 -| 7  10 |- a1
     a2 -| 8   9 |- s1     
         |_______|
*/
`default_nettype none

module ls83
(
    input wire  a1, a2, a3, a4, bb1, bb2, bb3, bb4, c0,
    output wire s1, s2, s3, s4, c4
);

wire i1, i2, i3, i4, i5, i6, i7, i8, i9;
nand(i1, bb4, a4);
nor(i2, bb4, a4);
nand(i3, bb3, a3);
nor(i4, bb3, a3);
nand(i5, bb2, a2);
nor(i6, bb2, a2);
nand(i7, bb1, a1);
nor(i8, bb1, a1);
not(i9, c0);

wire j1, j2, j3, j4, j5, j6, j7, j8, j9, j10, j11, j12, j13, j14, j15, j16, j17, j18, j19;

assign j1 = i2;
and(j2, i4, i1);
and(j3, i6, i1, i3);
and(j4, i8, i1, i3, i5);
and(j5, i1, i3, i5, i7, i9);
and(j6, i1, ~i2);

assign j7 = i4;
and(j8, i6, i3);
and(j9, i8, i3, i5);
and(j10, i3, i5, i7, i9);
and(j11, i3, ~i4);

assign j12 = i6;
and(j13, i8, i5);
and(j14, i5, i7, i9);
and(j15, i5, ~i6);

assign j16 = i8;
and(j17, i7, i9);
and(j18, i7, ~i8);
not(j19, i9);

wire k1, k2, k3, k4;
nor(k1, j1, j2, j3, j4, j5);
nor(k2, j7, j8, j9, j10);
nor(k3, j12, j13, j14);
nor(k4, j16, j17);

wire l1, l2, l3, l4;
xor(l1, j6, k2);
xor(l2, j11, k3);
xor(l3, j15, k4);
xor(l4, j18, j19);

assign c4 = k1;
assign s4 = l1;
assign s3 = l2;
assign s2 = l3;
assign s1 = l4;

endmodule
