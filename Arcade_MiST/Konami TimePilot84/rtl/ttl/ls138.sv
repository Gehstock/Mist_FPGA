//============================================================================
// 
//  SystemVerilog implementation of the 74LS138 3-to-8 decoder
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
/*      _____________
      _|             |_
a(0) |_|1          16|_| VCC
      _|             |_                     
a(1) |_|2          15|_| o(0)
      _|             |_
a(2) |_|3          14|_| o(1)
      _|             |_
n_e1 |_|4          13|_| o(2)
      _|             |_
n_e2 |_|5          12|_| o(3)
      _|             |_
e3   |_|6          11|_| o(4)
      _|             |_
o(7) |_|7          10|_| o(5)
      _|             |_
GND  |_|8           9|_| o(6)
       |_____________|
*/

module ls138
(
	input        n_e1, n_e2, e3,  //e3 is active high
	input  [2:0] a,
	output [7:0] o
);

assign o =
	(!n_e1 && !n_e2 && e3 && a == 3'b000) ? 8'b11111110:
	(!n_e1 && !n_e2 && e3 && a == 3'b001) ? 8'b11111101:
	(!n_e1 && !n_e2 && e3 && a == 3'b010) ? 8'b11111011:
	(!n_e1 && !n_e2 && e3 && a == 3'b011) ? 8'b11110111:
	(!n_e1 && !n_e2 && e3 && a == 3'b100) ? 8'b11101111:
	(!n_e1 && !n_e2 && e3 && a == 3'b101) ? 8'b11011111:
	(!n_e1 && !n_e2 && e3 && a == 3'b110) ? 8'b10111111:
	(!n_e1 && !n_e2 && e3 && a == 3'b111) ? 8'b01111111:
	8'b11111111;
		
endmodule
