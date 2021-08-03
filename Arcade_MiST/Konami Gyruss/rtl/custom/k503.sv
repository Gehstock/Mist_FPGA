//============================================================================
// 
//  SystemVerilog implementation of the Konami 503 custom chip, used by
//  several Konami arcade PCBs for handling sprite data
//
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
OB(7) |_|1          40|_| VCC
       _|             |_
OB(6) |_|2          39|_| V128
       _|             |_
OB(5) |_|3          38|_| V64
       _|             |_
OB(4) |_|4          37|_| V32
       _|             |_
OB(3) |_|5          36|_| V16
       _|             |_
OB(2) |_|6          35|_| V8
       _|             |_
OB(1) |_|7          34|_| V4
       _|             |_
OB(0) |_|8          33|_| V2
       _|             |_
R(5)  |_|9          32|_| V1
       _|             |_
R(4)  |_|10         31|_| NC
       _|             |_
R(3)  |_|11         30|_| NE83
       _|             |_
R(2)  |_|12         29|_| OCS
       _|             |_
R(1)  |_|13         28|_| NC
       _|             |_
R(0)  |_|14         27|_| NC
       _|             |_
LD    |_|15         26|_| NC
       _|             |_
H4    |_|16         25|_| NC
       _|             |_
H8    |_|17         24|_| NC
       _|             |_
OCOL  |_|18         23|_| NC
       _|             |_
ODAT  |_|19         22|_| NC
       _|             |_
GND   |_|20         21|_| NC
        |_____________|
*/

module k503
(
	input        clk,
	input        clk_en,
	input  [7:0] OB,
	input  [7:0] VCNT,
	input        H4, H8,
	input        LD,
	output       OCS,
	output       NE83,
	output       ODAT, OCOL,
	output [5:0] R
);

//Sum object bits with vertical counter
wire [7:0] obj_sum = OB + VCNT;

//Control signal for object enable output
wire obj_ctl = ~(&obj_sum[7:4]);

//Sprite control
wire sprite_ctrl = ~(~LD & ~H4 & ~H8) /* synthesis keep */;
reg ob6_lat, ob7_lat;
always_ff @(posedge clk) begin
	if (clk_en & ~sprite_ctrl) begin
		ob6_lat <= OB[6];
		ob7_lat <= OB[7];
	end
end

//Latch object information
reg [6:0] obj;
always_ff @(posedge clk) begin
	if (clk_en & ~objdata)
		obj <= {obj_ctl, ob6_lat, ob7_lat, obj_sum[3:0]};
end
wire obj_dat = obj[4];
assign NE83 = obj[5];
assign OCS = obj[6];

//Assign OCOL and ODAT outputs
assign OCOL = ~(~LD & ~H4 & H8);
wire objdata = ~(~LD & H4 & ~H8) /* synthesis keep */;
assign ODAT = objdata;

//XOR final output for R
assign R[5] = (obj[3] ^ obj_dat);
assign R[4] = (NE83 ^ H8);
assign R[3] = (NE83 ^ ~H4);
assign R[2] = (obj[2] ^ obj_dat);
assign R[1] = (obj[1] ^ obj_dat);
assign R[0] = (obj[0] ^ obj_dat);

endmodule

