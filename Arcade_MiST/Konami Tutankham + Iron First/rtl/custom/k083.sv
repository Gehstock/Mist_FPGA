//============================================================================
// 
//  SystemVerilog implementation of the Konami 083 custom chip, a custom
//  shift register used on many early Konami arcade PCBs for handling graphics
//  ROMs
//  Copyright (C) 2020, 2021 Ace & ElectronAsh
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
CK      |_|1          28|_| VCC
         _|             |_
LOAD    |_|2          27|_| FLIP
         _|             |_
DB1i(4) |_|3          26|_| DB1i(6)
         _|             |_
DB1i(0) |_|4          25|_| DB1i(2)
         _|             |_
DB0i(4) |_|5          24|_| DB0i(6)
         _|             |_
DB0i(6) |_|6          23|_| DB0i(2)
         _|             |_
DB1i(5) |_|7          22|_| DB1i(7)
         _|             |_
DB1i(1) |_|8          21|_| DB1i(3)
         _|             |_
DB0i(5) |_|9          20|_| DB0i(7)
         _|             |_
DB0i(1) |_|10         19|_| DB0i(3)
         _|             |_
NC      |_|11         18|_| NC
         _|             |_
DSH1(1) |_|12         17|_| DSH1(0)
         _|             |_
DSH0(1) |_|13         16|_| DSH0(0)
         _|             |_
GND     |_|14         15|_| NC
          |_____________|
*/

module k083
(
	input        CK,
	input        CEN, //Set to 1 if using this code to replace a real 083
	input        FLIP,
	input        LOAD,
	input  [7:0] DB0i, DB1i,
	output [1:0] DSH0, DSH1
);

//Internal registers (shift right and shift left)
reg [7:0] pixel_D0_l, pixel_D0_r;
reg [7:0] pixel_D1_l, pixel_D1_r;

//Latch and shift pixel data
always_ff @(posedge CK) begin
	if(CEN) begin
		if(LOAD) begin
			pixel_D0_l <= DB0i;
			pixel_D1_l <= DB1i;
			pixel_D0_r <= DB0i;
			pixel_D1_r <= DB1i;
		end
		else begin
			pixel_D0_l[3:0] <= {pixel_D0_l[2:0], 1'b0};
			pixel_D0_l[7:4] <= {pixel_D0_l[6:4], 1'b0};
			pixel_D1_l[3:0] <= {pixel_D1_l[2:0], 1'b0};
			pixel_D1_l[7:4] <= {pixel_D1_l[6:4], 1'b0};
			pixel_D0_r[3:0] <= {1'b0, pixel_D0_r[3:1]};
			pixel_D0_r[7:4] <= {1'b0, pixel_D0_r[7:5]};
			pixel_D1_r[3:0] <= {1'b0, pixel_D1_r[3:1]};
			pixel_D1_r[7:4] <= {1'b0, pixel_D1_r[7:5]};
		end
	end
end

//Output shifted pixel data (reverse the bits if FLIP is low)
assign DSH0 = FLIP ? {pixel_D0_l[3], pixel_D0_l[7]} : {pixel_D0_r[0], pixel_D0_r[4]};
assign DSH1 = FLIP ? {pixel_D1_l[3], pixel_D1_l[7]} : {pixel_D1_r[0], pixel_D1_r[4]};

endmodule
