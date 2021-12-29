//============================================================================
// 
//  SD card ROM loader and ROM selector for MISTer.
//  Copyright (C) 2019 Kitrinx (aka Rysha)
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

// Rom layout for Arkanoid:
// 0x0000 - 0x7FFF = eprom_1
// 0x8000 - 0xFFFF = eprom_2
// 0x10000 - 0x17FFF = eprom_3
// 0x18000 - 0x1FFFF = eprom_4
// 0x20000 - 0x27FFF = eprom_5
// 0x28000 - 0x281FF = color_prom_1
// 0x28200 - 0x283FF = color_prom_2
// 0x28400 - 0x285FF = color_prom_3

module selector
(
	input logic [24:0] ioctl_addr,
	output logic ep1_cs, ep2_cs, ep3_cs, ep4_cs, ep5_cs, cp1_cs, cp2_cs, cp3_cs
);

	always_comb begin
		{ep1_cs, ep2_cs, ep3_cs, ep4_cs, ep5_cs, cp1_cs, cp2_cs, cp3_cs} = 0;
		if(ioctl_addr < 'h8000)
			ep1_cs = 1; // 0x8000 15
		else if(ioctl_addr < 'h10000)
			ep2_cs = 1; // 0x8000 15
		else if(ioctl_addr < 'h18000)
			ep3_cs = 1; // 0x8000 15
		else if(ioctl_addr < 'h20000)
			ep4_cs = 1; // 0x8000 15
		else if(ioctl_addr < 'h28000)
			ep5_cs = 1; // 0x8000 15
		else if(ioctl_addr < 'h28200)
			cp1_cs = 1; // 0x200  9
		else if(ioctl_addr < 'h28400)
			cp2_cs = 1; // 0x200  9
		else
			cp3_cs = 1; // 0x200  9
	end
endmodule

////////////
// EPROMS //
////////////

module eprom_1
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [14:0] ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [7:0] DATA
);
	dpram_dc #(.widthad_a(15)) eprom_1
	(
		.clock_a(CLK),
		.address_a(ADDR[14:0]),
		.q_a(DATA[7:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[14:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule

module eprom_2
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [14:0] ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [7:0] DATA
);
	dpram_dc #(.widthad_a(15)) eprom_2
	(
		.clock_a(CLK),
		.address_a(ADDR[14:0]),
		.q_a(DATA[7:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[14:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule

module eprom_3
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [14:0] ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [7:0] DATA
);
	dpram_dc #(.widthad_a(15)) eprom_3
	(
		.clock_a(CLK),
		.address_a(ADDR[14:0]),
		.q_a(DATA[7:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[14:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule

module eprom_4
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [14:0] ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [7:0] DATA
);
	dpram_dc #(.widthad_a(15)) eprom_4
	(
		.clock_a(CLK),
		.address_a(ADDR[14:0]),
		.q_a(DATA[7:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[14:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule

module eprom_5
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [14:0] ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [7:0] DATA
);
	dpram_dc #(.widthad_a(15)) eprom_5
	(
		.clock_a(CLK),
		.address_a(ADDR[14:0]),
		.q_a(DATA[7:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[14:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule

///////////
// PROMS //
///////////

module color_prom_1
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [8:0]  ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [3:0] DATA
);
	dpram_dc #(.widthad_a(9)) cprom_1
	(
		.clock_a(CLK),
		.address_a(ADDR),
		.q_a(DATA[3:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[8:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule

module color_prom_2
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [8:0]  ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [3:0] DATA
);
	dpram_dc #(.widthad_a(9)) cprom_2
	(
		.clock_a(CLK),
		.address_a(ADDR),
		.q_a(DATA[3:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[8:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule

module color_prom_3
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [8:0]  ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [3:0] DATA
);
	dpram_dc #(.widthad_a(9)) cprom_3
	(
		.clock_a(CLK),
		.address_a(ADDR),
		.q_a(DATA[3:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[8:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule
