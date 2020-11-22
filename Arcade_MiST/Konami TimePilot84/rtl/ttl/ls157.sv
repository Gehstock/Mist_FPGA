//============================================================================
// 
//  SystemVerilog implementation of the 74LS157 dual 2-to-1 multiplexor
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
/*       _____________
       _|             |_
s     |_|1          16|_| VCC
       _|             |_                     
i0(0) |_|2          15|_| n_e
       _|             |_
i1(0) |_|3          14|_| i0(2)
       _|             |_
z(0)  |_|4          13|_| i1(2)
       _|             |_
i0(1) |_|5          12|_| z(2)
       _|             |_
i1(1) |_|6          11|_| i0(3)
       _|             |_
z(1)  |_|7          10|_| i1(3)
       _|             |_
GND   |_|8           9|_| z(3)
        |_____________|
*/

module ls157 
(
	input  [3:0] i0,
	input  [3:0] i1,
	input        n_e,
	input        s,
	output [3:0] z
);

assign z = (!n_e && !s) ? i0:
	(!n_e && s)     ? i1:
	4'b0000;	
	
endmodule
