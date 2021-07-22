//============================================================================
// 
//  SystemVerilog implementation of the Konami 501 custom chip, used by some
//  Konami arcade PCBs for partial address decoding and obfuscation of data
//  I/O
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
D[7] |_|1          28|_| VCC
      _|             |_
D[6] |_|2          27|_| XD[7]
      _|             |_
D[5] |_|3          26|_| XD[6]
      _|             |_
D[4] |_|4          25|_| XD[5]
      _|             |_
D[3] |_|5          24|_| XD[4]
      _|             |_
D[2] |_|6          23|_| XD[3]
      _|             |_
D[1] |_|7          22|_| XD[2]
      _|             |_
D[0] |_|8          21|_| XD[1]
      _|             |_
H2   |_|9          20|_| XD[0]
      _|             |_
H1   |_|10         19|_| WAIT
      _|             |_
CLK  |_|11         18|_| ENABLE
      _|             |_
RAM  |_|12         17|_| WRITE
      _|             |_
RD   |_|13         16|_| NC
      _|             |_
GND  |_|14         15|_| NC
       |_____________|

Note: The data bus is bidirectional - this model splits these pins into separate data I/O
*/

module k501
(
	input        CLK,     //Clock input (add a PLL to multiply the 6.144MHz pixel clock if replacing a real 501)
	input        CEN,     //Clock enable at 12.288MHz
	input        H1, H2,  //Bits 0 and 1 of the horizontal counter
	input        RAM,     //Chip select (active low)
	input        RD,      //Z80 read input
	output       WAIT,    //Z80 wait output
	output       WRITE,   //Write output
	output       ENABLE,  //Enable output
	input  [7:0] Di, XDi, //Inputs from data busses
	output [7:0] Do, XDo  //Outputs to data busses
);

//Data bus passthrough
assign XDo = Di;
assign Do = XDi;

//Latch bit 0 of the horizontal counter on each edge of the clock and preset to 1 if bit 1 of the horizontal counter
//is high
reg [1:0] h1_reg = 2'd0;
always_ff @(posedge CLK) begin
	if(H2)
		h1_reg[0] <= 1;
	else if(CEN)
		h1_reg <= {h1_reg[0], H1};
end

//AND both latched instances of H1
wire h1_lat = &h1_reg;

//Generate WAIT output
assign WAIT = ~H2 | RAM;

//Generate WRITE and ENABLE outputs
assign WRITE = ~RD | ENABLE;
assign ENABLE = h1_lat | RAM;

endmodule
