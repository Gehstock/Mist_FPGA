//============================================================================
// 
//  SystemVerilog implementation of the 74LS393 dual 4-bit binary counter
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
clk1  |_|1          14|_| VCC
       _|             |_                     
clr1  |_|2          13|_| clk2
       _|             |_
q1(0) |_|3          12|_| clr2
       _|             |_
q1(1) |_|4          11|_| q2(0)
       _|             |_
q1(2) |_|5          10|_| q2(1)
       _|             |_
q1(3) |_|6           9|_| q2(2)
       _|             |_
GND   |_|7           8|_| q2(3)
        |_____________|
*/

module ls393
(
	input        clk1, clk2,
	input        clr1, clr2,
	output [3:0] q1, q2
);

reg [3:0] count1;
reg [3:0] count2;

always_ff @(negedge clk1 or posedge clr1) begin
	if(clr1)
		count1 <= 4'b0000;
	else
		count1 <= count1 + 1'b1;
end

always_ff @(negedge clk2 or posedge clr2) begin
	if(clr2)
		count2 <= 4'b0000;
	else
		count2 <= count2 + 1'b1;
end

assign q1 = count1;
assign q2 = count2;

endmodule
