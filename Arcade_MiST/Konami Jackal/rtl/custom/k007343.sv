//============================================================================
// 
//  SystemVerilog implementation of the Konami K007343, a PAL16L8 used as part
//  of the address decoding hardware on Jackal/Top Gunner arcade PCBs
//  Converted from dump available at the PLD Archive
//  http://wiki.pldarchive.co.uk/index.php?title=Jackal
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
/*      _____________
      _|             |_
A13  |_|1          20|_| VCC
      _|             |_                     
A12  |_|2          19|_| MGCS
      _|             |_
A11  |_|3          18|_| NC
      _|             |_
A10  |_|4          17|_| CRCS
      _|             |_
A8_9 |_|5          16|_| IOCS
      _|             |_
A7   |_|6          15|_| GATEB
      _|             |_
A6   |_|7          14|_| WR
      _|             |_
A5   |_|8          13|_| OBJB
      _|             |_
A4   |_|9          12|_| SGCS
      _|             |_
GND  |_|10         11|_| GATECS
       |_____________|
*/

module k007343
(
	input  A4,
	input  A5,
	input  A6,
	input  A7,
	input  A8_9,
	input  A10,
	input  A11,
	input  A12,
	input  A13,
	input  WR,
	input  OBJB,
	input  GATEB,
	input  GATECS,
	output MGCS,
	output SGCS,
	output IOCS,
	output CRCS
);

wire o18 = ~(A13 & A12 & ~A10 & ~GATECS |
           A13 & A12 & ~A8_9 & ~GATECS);

assign MGCS = ~(~GATECS & ~OBJB & ~GATEB & IOCS & CRCS |
              ~GATECS & ~GATEB & IOCS & CRCS & o18);
assign CRCS = ~(~A13 & A12 & ~GATECS |
              ~A13 & ~A12 & A11 & ~GATECS |
              ~A13 & ~A12 & A8_9 & ~GATECS |
              ~A13 & ~A12 & A7 & ~GATECS |
              ~A13 & ~A12 & A6 & A5 & ~GATECS |
              ~A13 & ~A12 & A10 & ~GATECS);
assign IOCS = ~(~A13 & ~A12 & ~A11 & ~A10 & ~A8_9 & ~A7 & ~A6 & ~A5 & A4 & ~GATECS);
assign SGCS = ~(~GATECS & GATEB & IOCS & CRCS |
              ~GATECS & OBJB & ~WR & IOCS & CRCS |
              ~GATECS & OBJB & IOCS & CRCS & ~o18 |
              ~GATECS & ~WR & IOCS & CRCS & o18);

endmodule
