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

// ROM layout for Tutankham (index 0 - main CPU board):
// 0x0000 - 0x0FFF = rom_m1 (m1.1h)
// 0x1000 - 0x1FFF = rom_m2 (m2.2h)
// 0x2000 - 0x2FFF = rom_m3 (3j.3h)
// 0x3000 - 0x3FFF = rom_m4 (m4.4h)
// 0x4000 - 0x4FFF = rom_m5 (m5.5h)
// 0x5000 - 0x5FFF = rom_m6 (j6.6h)
// 0x6000 - 0x6FFF = bank0  (c1.1i)
// 0x7000 - 0x7FFF = bank1  (c2.2i)
// 0x8000 - 0x8FFF = bank2  (c3.3i)
// 0x9000 - 0x9FFF = bank3  (c4.4i)
// 0xA000 - 0xAFFF = bank4  (c5.5i)
// 0xB000 - 0xBFFF = bank5  (c6.6i)
// 0xC000 - 0xCFFF = bank6  (c7.7i)
// 0xD000 - 0xDFFF = bank7  (c8.8i)
// 0xE000 - 0xEFFF = bank8  (c9.9i)
// Sound board ROMs loaded separately via index 1

module selector
(
	input logic [24:0] ioctl_addr,
	output logic rom_m1_cs, rom_m2_cs, rom_m3_cs, rom_m4_cs, rom_m5_cs, rom_m6_cs,
	output logic bank0_cs, bank1_cs, bank2_cs, bank3_cs, bank4_cs,
	             bank5_cs, bank6_cs, bank7_cs, bank8_cs
);

	always_comb begin
		{rom_m1_cs, rom_m2_cs, rom_m3_cs, rom_m4_cs, rom_m5_cs, rom_m6_cs,
		 bank0_cs, bank1_cs, bank2_cs, bank3_cs, bank4_cs, bank5_cs,
		 bank6_cs, bank7_cs, bank8_cs} = 0;

		if(ioctl_addr < 'h1000)
			rom_m1_cs = 1;
		else if(ioctl_addr < 'h2000)
			rom_m2_cs = 1;
		else if(ioctl_addr < 'h3000)
			rom_m3_cs = 1;
		else if(ioctl_addr < 'h4000)
			rom_m4_cs = 1;
		else if(ioctl_addr < 'h5000)
			rom_m5_cs = 1;
		else if(ioctl_addr < 'h6000)
			rom_m6_cs = 1;
		else if(ioctl_addr < 'h7000)
			bank0_cs = 1;
		else if(ioctl_addr < 'h8000)
			bank1_cs = 1;
		else if(ioctl_addr < 'h9000)
			bank2_cs = 1;
		else if(ioctl_addr < 'hA000)
			bank3_cs = 1;
		else if(ioctl_addr < 'hB000)
			bank4_cs = 1;
		else if(ioctl_addr < 'hC000)
			bank5_cs = 1;
		else if(ioctl_addr < 'hD000)
			bank6_cs = 1;
		else if(ioctl_addr < 'hE000)
			bank7_cs = 1;
		else if(ioctl_addr < 'hF000)
			bank8_cs = 1;
	end
endmodule

////////////
// EPROMS //
////////////

//Generic 4KB ROM module (12-bit address)
module eprom_4k
(
	input logic        CLK,
	input logic        CLK_DL,
	input logic [11:0] ADDR,
	input logic [24:0] ADDR_DL,
	input logic [7:0]  DATA_IN,
	input logic        CS_DL,
	input logic        WR,
	output logic [7:0] DATA
);
	dpram_dc #(.widthad_a(12)) rom
	(
		.clock_a(CLK),
		.address_a(ADDR[11:0]),
		.q_a(DATA[7:0]),

		.clock_b(CLK_DL),
		.address_b(ADDR_DL[11:0]),
		.data_b(DATA_IN),
		.wren_b(WR & CS_DL)
	);
endmodule

//Sound board ROM (8KB, 13-bit address) - used by sound board index 1
module eprom_7
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
	dpram_dc #(.widthad_a(13)) eprom_7
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
