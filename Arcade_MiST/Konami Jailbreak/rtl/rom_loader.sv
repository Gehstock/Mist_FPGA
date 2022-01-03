//============================================================================
// 
//  SD card ROM loader and ROM selector for MISTer.
//  Copyright (C) 2019, 2020 Kitrinx (aka Rysha)
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

// Rom layout for Jailbreak:
// 0x0000 - 0x3FFF = eprom_1
// 0x4000 - 0x7FFF = eprom_2
// 0x8000 - 0xBFFF = eprom_3
// 0xC000 - 0xFFFF = eprom_4
// 0x10000 - 0x13FFF = eprom_5
// 0x14000 - 0x17FFF = eprom_6
// 0x18000 - 0x1BFFF = eprom_7
// 0x1C000 - 0x1FFFF = eprom_8
// 0x20000 - 0x23FFF = eprom_9
// 0x24000 - 0x240FF = sprite_lut_prom
// 0x24100 - 0x241FF = tile_lut_prom
// 0x24200 - 0x2421F = color_prom_1
// 0x24220 - 0x2423F = color_prom_2

module selector
(
	input logic [24:0] ioctl_addr,
	output logic ep1_cs, ep2_cs, ep3_cs, ep4_cs, ep5_cs, ep6_cs, ep7_cs, ep8_cs, ep9_cs,
	             cp1_cs, cp2_cs, tl_cs, sl_cs
);

	always_comb begin
		{ep1_cs, ep2_cs, ep3_cs, ep4_cs, ep5_cs, ep6_cs, ep7_cs, ep8_cs, ep9_cs, cp1_cs,
                cp2_cs, tl_cs, sl_cs} = 0;
		if(ioctl_addr < 'h4000)
			ep1_cs = 1; // 0x4000 14
		else if(ioctl_addr < 'h8000)
			ep2_cs = 1; // 0x4000 14
		else if(ioctl_addr < 'hC000)
			ep3_cs = 1; // 0x4000 14
		else if(ioctl_addr < 'h10000)
			ep4_cs = 1; // 0x4000 14
		else if(ioctl_addr < 'h14000)
			ep5_cs = 1; // 0x4000 14
		else if(ioctl_addr < 'h18000)
			ep6_cs = 1; // 0x4000 14
		else if(ioctl_addr < 'h1C000)
			ep7_cs = 1; // 0x4000 14
		else if(ioctl_addr < 'h20000)
			ep8_cs = 1; // 0x4000 14
		else if(ioctl_addr < 'h24000)
			ep9_cs = 1; // 0x4000 14
		else if(ioctl_addr < 'h24100)
			sl_cs = 1; // 0x100 8
		else if(ioctl_addr < 'h24200)
			tl_cs = 1; // 0x100 8
		else if(ioctl_addr < 'h24220)
			cp1_cs = 1; // 0x20 5
		else
			cp2_cs = 1; // 0x20 5
	end
endmodule

////////////
// EPROMS //
////////////

module eprom_1
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [13:0] ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [7:0] DATA
);
	dpram_dc #(.widthad_a(14)) eprom_1
	(
		.clock_a(CLK),
		.address_a(ADDR[13:0]),
		.q_a(DATA[7:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[13:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule

module eprom_2
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [13:0] ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [7:0] DATA
);
	dpram_dc #(.widthad_a(14)) eprom_2
	(
		.clock_a(CLK),
		.address_a(ADDR[13:0]),
		.q_a(DATA[7:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[13:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule

module eprom_3
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [13:0] ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [7:0] DATA
);
	dpram_dc #(.widthad_a(14)) eprom_3
	(
		.clock_a(CLK),
		.address_a(ADDR[13:0]),
		.q_a(DATA[7:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[13:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule

module eprom_4
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [13:0] ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [7:0] DATA
);
	dpram_dc #(.widthad_a(14)) eprom_4
	(
		.clock_a(CLK),
		.address_a(ADDR[13:0]),
		.q_a(DATA[7:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[13:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule

module eprom_5
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [13:0] ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [7:0] DATA
);
	dpram_dc #(.widthad_a(14)) eprom_5
	(
		.clock_a(CLK),
		.address_a(ADDR[13:0]),
		.q_a(DATA[7:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[13:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule

module eprom_6
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [13:0] ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [7:0] DATA
);
	dpram_dc #(.widthad_a(14)) eprom_6
	(
		.clock_a(CLK),
		.address_a(ADDR[13:0]),
		.q_a(DATA[7:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[13:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule

module eprom_7
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [13:0] ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [7:0] DATA
);
	dpram_dc #(.widthad_a(14)) eprom_7
	(
		.clock_a(CLK),
		.address_a(ADDR[13:0]),
		.q_a(DATA[7:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[13:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule

module eprom_8
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [13:0] ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [7:0] DATA
);
	dpram_dc #(.widthad_a(14)) eprom_8
	(
		.clock_a(CLK),
		.address_a(ADDR[13:0]),
		.q_a(DATA[7:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[13:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule

module eprom_9
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [12:0] ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [7:0] DATA
);
	dpram_dc #(.widthad_a(13)) eprom_9
	(
		.clock_a(CLK),
		.address_a(ADDR[12:0]),
		.q_a(DATA[7:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[12:0]),
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
	input logic [4:0]  ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [7:0] DATA
);
	dpram_dc #(.widthad_a(5)) color_prom_1
	(
		.clock_a(CLK),
		.address_a(ADDR[4:0]),
		.q_a(DATA[7:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[4:0]),
		.data_b(DATA_IN[7:0]),
		.wren_b(WR & CS_DL)
	);
endmodule

module color_prom_2
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [4:0]  ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [7:0] DATA
);
	dpram_dc #(.widthad_a(5)) color_prom_2
	(
		.clock_a(CLK),
		.address_a(ADDR[4:0]),
		.q_a(DATA[7:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[4:0]),
		.data_b(DATA_IN[7:0]),
		.wren_b(WR & CS_DL)
	);
endmodule

module tile_lut_prom
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [7:0]  ADDR,
	input logic [24:0] ADDR_DL,
	input logic [3:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [3:0] DATA
);
	dpram_dc #(.widthad_a(8)) tile_lut_prom
	(
		.clock_a(CLK),
		.address_a(ADDR[7:0]),
		.q_a(DATA[3:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[7:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule

module sprite_lut_prom
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [7:0]  ADDR,
	input logic [24:0] ADDR_DL,
	input logic [3:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [3:0] DATA
);
	dpram_dc #(.widthad_a(8)) sprite_lut_prom
	(
		.clock_a(CLK),
		.address_a(ADDR[7:0]),
		.q_a(DATA[3:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[7:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule
