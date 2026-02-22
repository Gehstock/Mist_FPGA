//============================================================================
// 
//  SystemVerilog implementation of the Konami 502 custom chip, used for
//  generating sprites on a number of '80s Konami arcade PCBs
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
/*         _____________
         _|             |_
SPLB(0) |_|1          28|_| VCC
         _|             |_
SPLB(1) |_|2          27|_| RESET
         _|             |_
SPLB(2) |_|3          26|_| SPLB(4)
         _|             |_
SPLB(3) |_|4          25|_| SPLB(5)
         _|             |_
CK1     |_|5          24|_| SPLB(6)
         _|             |_
CK2     |_|6          23|_| SPLB(7)
         _|             |_
H2      |_|7          22|_| OLD
         _|             |_
LDO     |_|8          21|_| OCLR
         _|             |_
H256    |_|9          20|_| OSEL
         _|             |_
SPAL(3) |_|10         19|_| COL(4)
         _|             |_
SPAL(2) |_|11         18|_| COL(3)
         _|             |_
SPAL(1) |_|12         17|_| COL(2)
         _|             |_
SPAL(0) |_|13         16|_| COL(1)
         _|             |_
GND     |_|14         15|_| COL(0)
          |_____________|

Note: The SPLB pins are bidirectional - this model splits these pins into separate
      data I/O
*/

module k502
(
	input        RESET,
	input        CK1,
	input        CK2,
	input        CEN, //Set to 1 if using this code to replace a real 502
	input        LDO,
	input        H2,
	input        H256,
	input  [3:0] SPAL,
	input  [7:0] SPLBi,
	output       OSEL,
	output       OLD,
	output       OCLR,
	output [7:0] SPLBo,
	output [4:0] COL
);

//Latch H256 on rising edge of LD0 and delay by one cycle (set to 0 if 502 is held in reset)
reg h256_lat = 0;
reg old_ldo;
always_ff @(posedge CK1) begin
	old_ldo <= LDO;
	if(!RESET)
		h256_lat <= 0;
	else if(!old_ldo && LDO)
		h256_lat <= H256;
end
reg h256_dly = 0;
reg old_h256_lat;
always_ff @(posedge CK1) begin
	old_h256_lat <= h256_lat;
	if(!RESET)
		h256_dly <= 0;
	else if(!old_h256_lat && h256_lat)
		h256_dly <= ~h256_dly;
end

//As the Konami 502 doesn't have a dedicated input for bit 2 of the horizontal counter (H4), generate
//this signal internally by dividing H2 by 2
reg h4 = 0;
reg old_h2;
always_ff @(posedge CK1) begin
	old_h2 <= H2;
	if(!old_h2 && H2)
		h4 <= ~h4;
end

//Generate OSEL, OLD and OCLR
reg [1:0] osel_reg;
always_ff @(posedge CK1) begin
	if(!RESET)
		osel_reg <= 2'b00;
	else if(old_h2 && !H2) begin
		if(!h4)
			osel_reg[1] <= h256_dly;
		else
			osel_reg[0] <= osel_reg[1];
	end
end
assign OLD = ~osel_reg[1];
assign OSEL = osel_reg[0];
assign OCLR = ~osel_reg[0];

//Multiplex incoming line buffer RAM data
wire [3:0] lbuff_Dmux = OCLR ? SPLBi[3:0] : SPLBi[7:4];

//Latch incoming line buffer RAM data on the falling edge of CK1
reg [7:0] lbuff_lat;
always_ff @(negedge CK2) begin
	if(!RESET)
		lbuff_lat <= 8'd0;
	else if(CEN)
		lbuff_lat <= SPLBi;
end

//Latch multiplexed line buffer RAM data on the falling edge of CK2
reg [3:0] lbuff_mux_lat;
always_ff @(negedge CK2) begin
	if(!RESET)
		lbuff_mux_lat <= 4'd0;
	else if(CEN)
		lbuff_mux_lat <= lbuff_Dmux;
end

//Assign sprite data output
assign COL[4] = ~(|lbuff_mux_lat[3:0]);
assign COL[3:0] = lbuff_mux_lat[3:0];

//Select sprite or palette data based on a 4-way AND of the inverted latched line buffer data
//(upper 4 bits and lower 4 bits produce separate select signals)
wire sprite_pal_sel2 = (~lbuff_lat[7] & ~lbuff_lat[6] & ~lbuff_lat[5] & ~lbuff_lat[4]);
wire sprite_pal_sel1 = (~lbuff_lat[3] & ~lbuff_lat[2] & ~lbuff_lat[1] & ~lbuff_lat[0]);

//Multiplex sprite data from line buffer with palette data (lower 4 bits)
wire [7:0] sprite_pal_mux;
assign sprite_pal_mux[3:0] = osel_reg[0] ? (sprite_pal_sel1 ? SPAL : SPLBi[3:0]) : 4'h0;

//Multiplex sprite data from line buffer with palette data (upper 4 bits)
assign sprite_pal_mux[7:4] = ~osel_reg[0] ? (sprite_pal_sel2 ? SPAL : SPLBi[7:4]) : 4'h0;

//Output data to sprite line buffer
assign SPLBo = sprite_pal_mux;

endmodule

