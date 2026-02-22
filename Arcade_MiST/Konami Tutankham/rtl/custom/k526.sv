//============================================================================
// 
//  SystemVerilog implementation of the Konami 526, an 82S153 PLA used for
//  address decoding on Time Pilot
//  Converted from dump available at the PLD Archive
//  http://wiki.pldarchive.co.uk/index.php?title=Time_Pilot
//  Copyright (C) 2021 Ace
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
/*        _____________
        _|             |_
MREQ   |_|1          20|_| VCC
        _|             |_
RFSH   |_|2          19|_| ROM(0)
        _|             |_
A15    |_|3          18|_| ROM(1)
        _|             |_
A14    |_|4          17|_| ROM(2)
        _|             |_
A13    |_|5          16|_| ROM(3)
        _|             |_
A12    |_|6          15|_| K501
        _|             |_
A10    |_|7          14|_| WRAM
        _|             |_
ENABLE |_|8          13|_| SPRAM1
        _|             |_
NC     |_|9          12|_| SPRAM0
        _|             |_
GND    |_|10         11|_| NC
         |_____________|
*/

module k526
(
	input        MREQ,                    //MREQ input from Z80
	input        RFSH,                    //RFSH input from Z80
	input        A15, A14, A13, A12, A10, //Address line inputs A[15:10] excluding A[11]
	input        ENABLE,                  //Enable input from Konami 501
	output       SPRAM0,                  //Sprite RAM 0 enable (active low)
	output       SPRAM1,                  //Sprite RAM 1 enable (active low)
	output       WRAM,                    //Work RAM/VRAM enable (active low)
	output       K501,                    //Enable for Konami 501 (active low)
	output [3:0] ROM                      //Enable for Z80 ROMs (active low)
);

assign SPRAM0 = ~(~MREQ & RFSH & {A15, A14, A13, A12, A10} == 5'b10111 & ~ENABLE);

assign SPRAM1 = ~(~MREQ & RFSH & {A15, A14, A13, A12, A10} == 5'b10110 & ~ENABLE);

assign WRAM = ~(~MREQ & RFSH & {A15, A14, A13, A12} == 4'b1010 & ~ENABLE);

assign K501 = ~(~MREQ & RFSH & A15);

assign ROM[3] = ~(~MREQ & RFSH & {A15, A14, A13} == 3'b011);
assign ROM[2] = ~(~MREQ & RFSH & {A15, A14, A13} == 3'b010);
assign ROM[1] = ~(~MREQ & RFSH & {A15, A14, A13} == 3'b001);
assign ROM[0] = ~(~MREQ & RFSH & {A15, A14, A13} == 3'b000);

endmodule
