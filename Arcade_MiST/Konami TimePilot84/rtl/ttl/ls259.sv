//============================================================================
// 
//  SystemVerilog implementation of the 74LS259 8-bit addressable latch
//  Copyright (C) 2020 Ace & ElectronAsh
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
s(0) |_|1          16|_| VCC
      _|             |_                     
s(1) |_|2          15|_| n_clr
      _|             |_
s(2) |_|3          14|_| n_g
      _|             |_
q(0) |_|4          13|_| d
      _|             |_
q(1) |_|5          12|_| q(7)
      _|             |_
q(2) |_|6          11|_| q(6)
      _|             |_
q(3) |_|7          10|_| q(5)
      _|             |_
GND  |_|8           9|_| q(4)
       |_____________|
*/

module ls259
(
	input            d, n_clr, n_g,
	input      [2:0] s,
	output reg [7:0] q
);

always @(*) begin
	if (!n_clr)
		q <= 8'h00;
	else
		if (!n_g) begin
			case (s)
				3'b000: q[0] <= d;
				3'b001: q[1] <= d;
				3'b010: q[2] <= d;
				3'b011: q[3] <= d;
				3'b100: q[4] <= d;
				3'b101: q[5] <= d;
				3'b110: q[6] <= d;
				3'b111: q[7] <= d;
				default:;
			endcase;
		end
end

endmodule
