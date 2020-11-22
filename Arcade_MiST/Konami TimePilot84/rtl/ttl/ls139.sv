//============================================================================
// 
//  SystemVerilog implementation of the 74LS139 dual 2-to-4 address decoder
//  Copyright (C) 2018, 2020 Ace
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
a0(0)  |_|2          15|_| n_e(1)
        _|             |_
a1(0)  |_|3          14|_| a0(1)
        _|             |_
o0(0)  |_|4          13|_| a1(1)
        _|             |_
o0(1)  |_|5          12|_| o1(0)
        _|             |_
o0(2)  |_|6          11|_| o1(1)
        _|             |_
o0(3)  |_|7          10|_| o1(2)
        _|             |_
GND    |_|8           9|_| o1(3)
         |_____________|
*/

module ls139
(
	input  [1:0] a0,
	input  [1:0] a1,
	input  [1:0] n_e,
	output [3:0] o0,
	output [3:0] o1
);

assign o0 = 
	(!n_e[0] && !a0[0] && !a1[0]) ? 4'b1110:
	(!n_e[0] && a0[0] && !a1[0])  ? 4'b1101:
	(!n_e[0] && !a0[0] && a1[0])  ? 4'b1011:
	(!n_e[0] && a0[0] && a1[0])   ? 4'b0111:
	4'b1111;
assign o1 =
	(!n_e[1] && !a0[1] && !a1[1]) ? 4'b1110:
	(!n_e[1] && a0[1] && !a1[1])  ? 4'b1101:
	(!n_e[1] && !a0[1] && a1[1])  ? 4'b1011:
	(!n_e[1] && a0[1] && a1[1])   ? 4'b0111:
	4'b1111;
		
endmodule
