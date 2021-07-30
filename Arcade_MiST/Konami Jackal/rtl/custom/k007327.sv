//============================================================================
// 
//  SystemVerilog implementation of the Konami 007327 custom palette RAM +
//  video DAC module
//  Copyright (C) 2021 Ace & SnakeGrunger
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

//Module pinout:
/*        _______________________
        _|                       |_
CCS    |_|1                    40|_| CLK
        _|                       |_                     
CWR    |_|2                    39|_| BLK
        _|                       |_
D[7]   |_|3                    38|_| RW
        _|                       |_
D[6]   |_|4                    37|_| A[0]
        _|                       |_
D[5]   |_|5                    36|_| NA0
        _|                       |_
D[4]   |_|6                    35|_| A[1]
        _|                       |_
D[3]   |_|7                    34|_| A[2]
        _|                       |_
D[2]   |_|8                    33|_| A[3]
        _|                       |_
D[1]   |_|9                    32|_| A[4]
        _|                       |_
D[0]   |_|10                   31|_| A[5]
        _|                       |_
GND    |_|11                   30|_| A[6]
        _|                       |_                     
VCC    |_|12                   29|_| A[7]
        _|                       |_
B      |_|13                   28|_| CB[0]
        _|                       |_
G      |_|14                   27|_| CB[1]
        _|                       |_
R      |_|15                   26|_| CB[2]
        _|                       |_
GND    |_|16                   25|_| CB[3]
        _|                       |_
RA[8]  |_|17                   24|_| CB[4]
        _|                       |_
RA[9]  |_|18                   23|_| CB[5]
        _|                       |_
RA[10] |_|19                   22|_| CB[6]
        _|                       |_
RA[11] |_|20                   21|_| SEL
         |_______________________|
*/

module k007327
(
	input         CLK,     //Clock input
	input         CEN,     //Clock enable input (set to 1 if replacing an actual 007327)
	input  [11:8] RA,      //External address inputs to palette RAM's upper 4 address bits
	input   [7:0] A,       //Address bus from CPU
	input         NA0,     //Inverse of address bit A0
	input   [6:0] CB,      //7-bit Color bus input
	input   [7:0] Di,      //CPU data input
	input         RW,      //Read/write input
	input         SEL,     //Color/CPU data select input
	input         CCS,     //Chip select input (active low)
	input         CWR,     //Color write enable (active low)
	input         BLK,     //Blank input
	output  [4:0] R, G, B, //15-bit RGB color output, 5 bits per color
	output  [7:0] Do       //CPU data output
);

//Multiplex address lines A[6:0] for palette RAM
wire [10:0] paletteram_A;
assign paletteram_A[10:7] = RA[11:8];
assign paletteram_A[6:0] = SEL ? CB : A[7:1];

//Generate read and write enable signals for palette RAM
wire n_paletteram0_cs = (CCS | NA0);
wire n_paletteram1_cs = (CCS | A[0]);
wire n_paletteram0_wr = (n_paletteram0_cs | CWR);
wire n_paletteram1_wr = (n_paletteram1_cs | CWR);

//Palette RAM
wire [15:0] paletteram_D;
spram #(8, 11) PALRAM_L
(
	.clk(CLK),
	.addr(paletteram_A),
	.data(Di),
	.q(paletteram_D[7:0]),
	.we(~n_paletteram0_wr & RW)
);
spram #(8, 11) PALRAM_H
(
	.clk(CLK),
	.addr(paletteram_A),
	.data(Di),
	.q(paletteram_D[15:8]),
	.we(~n_paletteram1_wr & RW)
);

//Output palette RAM data to CPU
assign Do = (~n_paletteram0_cs & ~RW) ? paletteram_D[7:0]:
            (~n_paletteram1_cs & ~RW) ? paletteram_D[15:8]:
            8'hFF;

//Latch blank input at every positive edge of the incoming clock
reg blank = 1;
always_ff @(posedge CLK) begin
	if(CEN)
		blank <= BLK;
end

//Latch pixel data
reg [4:0] pixel_red = 0;
reg [4:0] pixel_green = 0;
reg [4:0] pixel_blue = 0;
always_ff @(posedge CLK) begin
	if(CEN) begin
		pixel_red <= paletteram_D[12:8];
		pixel_green <= {paletteram_D[1:0], paletteram_D[15:13]};
		pixel_blue <= paletteram_D[6:2];
	end
end

//Generate final RGB output
assign R = blank ? pixel_red : 5'd0;
assign G = blank ? pixel_green : 5'd0;
assign B = blank ? pixel_blue : 5'd0;

endmodule
