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
  74LS90
  ------
  Decade and Binary Counters
  
  Pinout
  ------
          _______
         |       |
   _ckb -| 1  14 |- _cka
   r0_1 -| 2  13 |- NC
   r0_2 -| 3  12 |- qa
     NC -| 4  11 |- qd
    VCC -| 5  10 |- GND
   r9_1 -| 6   9 |- qb
   r9_2 -| 7   8 |- qc
         |_______|
*/
`default_nettype none

module ls90
(
    input wire  _cka, /* verilator lint_off UNUSED */ _ckb /* verilator lint_on UNUSED */, r0_1, r0_2, r9_1, r9_2,
    output wire  qa, qb, qc, qd
);

wire r0, r9;
assign r0 = ~(r0_1 & r0_2);
assign r9 = ~(r9_1 & r9_2);

wire unused, unused2, unused3, _qd;
//             _clk        j       k  _set           _clr   q   _q
png_jkff jkff1(_cka,    1'b1,   1'b1,   r9,            r0, qa, unused);
png_jkff jkff2(qa,       _qd,   1'b1, 1'b1,  ~(~r0 | ~r9), qb, unused2);
png_jkff jkff3(qb,      1'b1,   1'b1, 1'b1,  ~(~r0 | ~r9), qc, unused3);
png_jkff jkff4(qa, (qc & qb),     qd,   r9,            r0, qd, _qd);

endmodule
