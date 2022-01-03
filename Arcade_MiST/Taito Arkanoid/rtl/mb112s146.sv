//============================================================================
// 
//  SystemVerilog mplementation of the Fujitsu MB112S146 custom IC
//  Contains two left/right shift registers and a multiplexer
//  Copyright (C) 2019 Ace
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//	 the rights to use, copy, modify, merge, publish, distribute, sublicense,
//	 and/or sell copies of the Software, and to permit persons to whom the 
//	 Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//	 all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//	 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//	 DEALINGS IN THE SOFTWARE.
//
//============================================================================

//Chip pinout:
/*          _____________
          _|             |_
shift_ld |_|1          28|_| VCC
          _|             |_                     
latch    |_|2          27|_| n_clr
          _|             |_
s_in(0)  |_|3          26|_| sel
          _|             |_
s_in(1)  |_|4          25|_| GND
          _|             |_
clk      |_|5          24|_| d2_in(0)
          _|             |_
d1_in(0) |_|6          23|_| d2_in(1)
          _|             |_
d1_in(1) |_|7          22|_| d2_in(2)
          _|             |_
d1_in(2) |_|8          21|_| d2_in(3)
          _|             |_
d1_in(3) |_|9          20|_| d2_in(4)
          _|             |_
d1_in(4) |_|10         19|_| d2_in(5)
          _|             |_
d1_in(5) |_|11         18|_| d2_in(6)
          _|             |_
d1_in(6) |_|12         17|_| d2_in(7)
          _|             |_
d1_in(7) |_|13         16|_| shift_out(0)
          _|             |_
GND      |_|14         15|_| shift_out(1)
           |_____________|
*/

module mb112s146
(
	input        clk, cen,
	input        n_clr, shift_ld,
	input        sel,
	input  [1:0] s_in,
	input  [7:0] d1_in, d2_in,
	output [1:0] shift_out
);

reg [7:0] shift_l_1, shift_l_2;
reg [7:0] shift_r_1, shift_r_2;

always_ff @(posedge clk or negedge n_clr) begin
	if(!n_clr) begin
		//Reset internal registers
		shift_l_1 <= 8'd0;
		shift_l_2 <= 8'd0;
		shift_r_1 <= 8'd0;
		shift_r_2 <= 8'd0;
	end
	else if(cen) begin
		//Left shift data 1 input
		shift_l_1[0] <= (s_in[0] & shift_ld) | (~shift_ld & d1_in[0]);
		shift_l_1[1] <= (shift_l_1[0] & shift_ld) | (~shift_ld & d1_in[1]);
		shift_l_1[2] <= (shift_l_1[1] & shift_ld) | (~shift_ld & d1_in[2]);
		shift_l_1[3] <= (shift_l_1[2] & shift_ld) | (~shift_ld & d1_in[3]);
		shift_l_1[4] <= (shift_l_1[3] & shift_ld) | (~shift_ld & d1_in[4]);
		shift_l_1[5] <= (shift_l_1[4] & shift_ld) | (~shift_ld & d1_in[5]);
		shift_l_1[6] <= (shift_l_1[5] & shift_ld) | (~shift_ld & d1_in[6]);
		shift_l_1[7] <= (shift_l_1[6] & shift_ld) | (~shift_ld & d1_in[7]);
		//Left shift data 2 input
		shift_l_2[0] <= (s_in[1] & shift_ld) | (~shift_ld & d2_in[0]);
		shift_l_2[1] <= (shift_l_2[0] & shift_ld) | (~shift_ld & d2_in[1]);
		shift_l_2[2] <= (shift_l_2[1] & shift_ld) | (~shift_ld & d2_in[2]);
		shift_l_2[3] <= (shift_l_2[2] & shift_ld) | (~shift_ld & d2_in[3]);
		shift_l_2[4] <= (shift_l_2[3] & shift_ld) | (~shift_ld & d2_in[4]);
		shift_l_2[5] <= (shift_l_2[4] & shift_ld) | (~shift_ld & d2_in[5]);
		shift_l_2[6] <= (shift_l_2[5] & shift_ld) | (~shift_ld & d2_in[6]);
		shift_l_2[7] <= (shift_l_2[6] & shift_ld) | (~shift_ld & d2_in[7]);
		//Right shift data 1 input
		shift_r_1[0] <= (s_in[0] & shift_ld) | (~shift_ld & d1_in[7]);
		shift_r_1[1] <= (shift_r_1[0] & shift_ld) | (~shift_ld & d1_in[6]);
		shift_r_1[2] <= (shift_r_1[1] & shift_ld) | (~shift_ld & d1_in[5]);
		shift_r_1[3] <= (shift_r_1[2] & shift_ld) | (~shift_ld & d1_in[4]);
		shift_r_1[4] <= (shift_r_1[3] & shift_ld) | (~shift_ld & d1_in[3]);
		shift_r_1[5] <= (shift_r_1[4] & shift_ld) | (~shift_ld & d1_in[2]);
		shift_r_1[6] <= (shift_r_1[5] & shift_ld) | (~shift_ld & d1_in[1]);
		shift_r_1[7] <= (shift_r_1[6] & shift_ld) | (~shift_ld & d1_in[0]);
		//Right shift data 2 input
		shift_r_2[0] <= (s_in[1] & shift_ld) | (~shift_ld & d2_in[7]);
		shift_r_2[1] <= (shift_r_2[0] & shift_ld) | (~shift_ld & d2_in[6]);
		shift_r_2[2] <= (shift_r_2[1] & shift_ld) | (~shift_ld & d2_in[5]);
		shift_r_2[3] <= (shift_r_2[2] & shift_ld) | (~shift_ld & d2_in[4]);
		shift_r_2[4] <= (shift_r_2[3] & shift_ld) | (~shift_ld & d2_in[3]);
		shift_r_2[5] <= (shift_r_2[4] & shift_ld) | (~shift_ld & d2_in[2]);
		shift_r_2[6] <= (shift_r_2[5] & shift_ld) | (~shift_ld & d2_in[1]);
		shift_r_2[7] <= (shift_r_2[6] & shift_ld) | (~shift_ld & d2_in[0]);
	end
end

assign shift_out = sel ? {shift_r_2[7], shift_r_1[7]}:
						{shift_l_2[7], shift_l_1[7]};

endmodule
