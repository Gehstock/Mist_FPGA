//============================================================================
// 
//  SystemVerilog implementation of the Konami 503 custom chip, used by
//  several Konami arcade PCBs for handling sprite data
//  Copyright (C) 2020, 2021 Ace
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
OB(7) |_|1          40|_| VCC
       _|             |_
OB(6) |_|2          39|_| VCNT(7)
       _|             |_
OB(5) |_|3          38|_| VCNT(6)
       _|             |_
OB(4) |_|4          37|_| VCNT(5)
       _|             |_
OB(3) |_|5          36|_| VCNT(4)
       _|             |_
OB(2) |_|6          35|_| VCNT(3)
       _|             |_
OB(1) |_|7          34|_| VCNT(2)
       _|             |_
OB(0) |_|8          33|_| VCNT(1)
       _|             |_
R(5)  |_|9          32|_| VCNT(0)
       _|             |_
R(4)  |_|10         31|_| NC
       _|             |_
R(3)  |_|11         30|_| OFLP
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
	input        CLK,    //Extra clock input for use with MiSTer (define MISTER_K503 macro to use this)
	input  [7:0] OB,     //Sprite data input
	input  [7:0] VCNT,   //Vertical counter input
	input        H4, H8, //Horizontal counter bits 2 (H4) and 3 (H8)
	input        LD,     //LD input (pulses low when bits 0 and 1 of the horizontal counter are both 1)
	output       OCS,    //Sprite line buffer chip select output
	output       OFLP,   //Sprite flip output
	output       ODAT,   //Signal to latch upper bits of sprite address
	output       OCOL,   //Signal to load addresses for sprite line buffer
	output [5:0] R       //Lower 6 bits of sprite address
);

//Sum sprite bits with vertical counter
wire [7:0] sprite_sum = OB + VCNT;

//Sprite select signal
wire sprite_sel = ~(&sprite_sum[7:4]);

//Latch sprite flip attributes and sprite information on each edge of H4, flip attributes on the positive edge,
//sprite information on the falling edge
//If the macro MISTER_K503 is defined, use alternate logic with a dedicated clock input, otherwise latch directly
//off H4
reg [6:0] sprite;
reg hflip, vflip;
`ifdef MISTER_K503
reg old_h4;
always_ff @(posedge CLK) begin
	old_h4 <= H4;
	if(!old_h4 && H4) begin
		hflip <= OB[6];
		vflip <= OB[7];
	end
	else if(old_h4 && !H4)
		sprite <= {sprite_sel, hflip, vflip, sprite_sum[3:0]};
	else begin
		hflip <= hflip;
		vflip <= vflip;
		sprite <= sprite;
	end
end
`else
always_ff @(posedge H4) begin
	hflip <= OB[6];
	vflip <= OB[7];
end
always_ff @(negedge H4) begin
	sprite <= {sprite_sel, hflip, vflip, sprite_sum[3:0]};
end
`endif
wire sprite_vflip = sprite[4];
assign OFLP = sprite[5];
assign OCS = sprite[6];

//Assign OCOL (sprite color) and ODAT (sprite data) outputs
assign OCOL = ({H8, H4, LD} != 3'b100);
assign ODAT = ({H8, H4, LD} != 3'b010);

//XOR final output for R
assign R[5] = (sprite[3] ^ sprite_vflip);
assign R[4] = (OFLP ^ H8);
assign R[3] = (OFLP ^ ~H4);
assign R[2] = (sprite[2] ^ sprite_vflip);
assign R[1] = (sprite[1] ^ sprite_vflip);
assign R[0] = (sprite[0] ^ sprite_vflip);

endmodule
