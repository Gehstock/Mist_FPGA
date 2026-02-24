//============================================================================
// 
//  SystemVerilog implementation of the Konami 528, an 82S153 PLA used for
//  controlling the vertical counter outputs on Time Pilot's Konami 082
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
/*         _____________
         _|             |_
HCNT[0] |_|1          20|_| VCC
         _|             |_
HCNT[1] |_|2          19|_| PEN
         _|             |_
HCNT[2] |_|3          18|_| NVEN
         _|             |_
HCNT[3] |_|4          17|_| K082EN
         _|             |_
HCNT[4] |_|5          16|_| CLKO
         _|             |_
HCNT[5] |_|6          15|_| CLR
         _|             |_
HCNT[6] |_|7          14|_| o14
         _|             |_
H256    |_|8          13|_| NC
         _|             |_
NC      |_|9          12|_| RESET1
         _|             |_
GND     |_|10         11|_| RESET0
          |_____________|
*/

module k528
(
	input  [6:0] HCNT,           //Horizontal counter bits [6:0]
	input        H256,           //Inverse of the most significant bit of the horizontal counter
	input        RESET0, RESET1, //Reset inputs (both active low)
	input        NVEN, PEN,      //Vertical counter and pixel enable inputs (NVEN active low, PEN active high)
	output       CLR,            //Clear output for vertical counter latch
	output       CLKO,           //Clock output for vertical counter latch
	output       K082EN,         //Enable output for Konami 082 vertical counter
	output       o14             //Unknown output, connects to pin 27 of the Konami 082
);

assign o14 = ~PEN | ~RESET0;
assign CLR = RESET1 & PEN;
assign CLKO = ~H256 & PEN;
assign K082EN = (~NVEN & PEN) | ((&HCNT) & H256 & PEN);

endmodule
