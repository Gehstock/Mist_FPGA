//============================================================================
// 
//  SystemVerilog implementation of the 74LS293 4-bit binary counter
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
/*      _____________
      _|             |_
NC   |_|1          14|_| VCC
      _|             |_                     
NC   |_|2          13|_| clr2
      _|             |_
NC   |_|3          12|_| clr1
      _|             |_
q(1) |_|4          11|_| clk2
      _|             |_
q(2) |_|5          10|_| clk1
      _|             |_
NC   |_|6           9|_| q(0)
      _|             |_
GND  |_|7           8|_| q(3)
       |_____________|
*/

module ls293
(
	input        clk1, clk2,
	input        clr1, clr2,
	output [3:0] q
);

wire clear = clr1 & clr2;
reg q_int;
reg [2:0] count;

always_ff @(negedge clk1 or posedge clear) begin
	if(clear)
		q_int <= 0;
	else
		q_int <= ~q_int;
end

always_ff @(negedge clk2 or posedge clear) begin
	if(clear)
		count <= 3'b000;
	else
		count <= count + 1'b1;
end

assign q[3:1] = count;
assign q[0] = q_int;

endmodule
