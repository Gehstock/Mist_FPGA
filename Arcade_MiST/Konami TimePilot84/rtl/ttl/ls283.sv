//============================================================================
// 
//  SystemVerilog implementation of the 74LS283 4-bit full adder with fast
//  carry
//  Copyright (C) 2019 Ace
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
sum(1) |_|1          16|_| VCC
        _|             |_                     
b(1)   |_|2          15|_| b(2)
        _|             |_
a(1)   |_|3          14|_| a(2)
        _|             |_
sum(0) |_|4          13|_| sum(2)
        _|             |_
a(0)   |_|5          12|_| a(3)
        _|             |_
b(0)   |_|6          11|_| b(3)
        _|             |_
c_in   |_|7          10|_| sum(3)
        _|             |_
GND    |_|8           9|_| c_out
         |_____________|
*/

module ls283
(
	input  [3:0] a,
	input  [3:0] b,
	input        c_in,
	output [3:0] sum,
	output       c_out
);

wire [4:0] sum_int;

assign sum_int = a + b + c_in;
assign sum = sum_int[3:0];
assign c_out = sum_int[4];

endmodule
