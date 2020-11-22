//============================================================================
// 
//  SystemVerilog implementation of the 74LS253 tristate dual 4-to-1
//  multiplexor
//  Copyright (C) 2020 Ace
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the 
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
//
//============================================================================

//Chip pinout:
/*        _____________
        _|             |_
n_e(0) |_|1          16|_| VCC
        _|             |_                     
s(1)   |_|2          15|_| n_e(1)
        _|             |_
i_a(3) |_|3          14|_| s(0)
        _|             |_
i_a(2) |_|4          13|_| i_b(3)
        _|             |_
i_a(1) |_|5          12|_| i_b(2)
        _|             |_
i_a(0) |_|6          11|_| i_b(1)
        _|             |_
z(0)   |_|7          10|_| i_b(0)
        _|             |_
GND    |_|8           9|_| z(1)
         |_____________|
*/

module ls253
(
	input  [3:0] i_a, i_b,
	input  [1:0] n_e,
	input  [1:0] s,
	output [1:0] z
);

assign z[0] =
	(s == 2'b00 && !n_e[0]) ? i_a[0]:
	(s == 2'b01 && !n_e[0]) ? i_a[1]:
	(s == 2'b10 && !n_e[0]) ? i_a[2]:
	(s == 2'b11 && !n_e[0]) ? i_a[3]:
	1'b1; //Should be Z
assign z[1] =
	(s == 2'b00 && !n_e[1]) ? i_b[0]:
	(s == 2'b01 && !n_e[1]) ? i_b[1]:
	(s == 2'b10 && !n_e[1]) ? i_b[2]:
	(s == 2'b11 && !n_e[1]) ? i_b[3]:
	1'b1; //Should be Z

endmodule
