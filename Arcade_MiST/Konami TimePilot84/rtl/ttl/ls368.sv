//============================================================================
// 
//  SystemVerilog implementation of the 74LS368 tri-state hex inverter
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
n_g1 |_|1          16|_| VCC
      _|             |_                     
a1   |_|2          15|_| n_g2
      _|             |_
y1   |_|3          14|_| a6
      _|             |_
a2   |_|4          13|_| y6
      _|             |_
y2   |_|5          12|_| a5
      _|             |_
a3   |_|6          11|_| y5
      _|             |_
y3   |_|7          10|_| a4
      _|             |_
GND  |_|8           9|_| y4
       |_____________|
*/

module ls368
(
	input  n_g1, n_g2,
	input  a1, a2, a3, a4, a5, a6,
	output y1, y2, y3, y4, y5, y6
);

assign y1 = !n_g1 ? ~a1 : 1'b1;
assign y2 = !n_g1 ? ~a2 : 1'b1;
assign y3 = !n_g1 ? ~a3 : 1'b1;
assign y4 = !n_g1 ? ~a4 : 1'b1;
assign y5 = !n_g2 ? ~a5 : 1'b1;
assign y6 = !n_g2 ? ~a6 : 1'b1;
	
endmodule
