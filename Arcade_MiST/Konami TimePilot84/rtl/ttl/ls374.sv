//============================================================================
// 
//  SystemVerilog implementation of the 74LS374 octal D-flip flop
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
/*         _____________
         _|             |_
out_ctl |_|1          20|_| VCC
         _|             |_                     
q(0)    |_|2          19|_| q(7)
         _|             |_
d(0)    |_|3          18|_| d(7)
         _|             |_
d(1)    |_|4          17|_| d(6)
         _|             |_
q(1)    |_|5          16|_| q(6)
         _|             |_
q(2)    |_|6          15|_| q(5)
         _|             |_
d(2)    |_|7          14|_| d(5)
         _|             |_
d(3)    |_|8          13|_| d(4)
         _|             |_
q(3)    |_|9          12|_| q(4)
         _|             |_
GND     |_|10         11|_| clk
          |_____________|
*/

module ls374
(
	input  [7:0] d,
	input        clk,
	input        out_ctl,
	output [7:0] q
);

reg [7:0] q_internal;

always_ff @(posedge clk) begin
	q_internal <= d;
end

assign q = !out_ctl ? q_internal : 8'hFF; //Should be Z when out_ctl is high

endmodule
