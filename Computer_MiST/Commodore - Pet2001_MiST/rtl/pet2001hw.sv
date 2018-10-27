`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////
//
// Engineer:         Thomas Skibo
// 
// Create Date:      Sep 23, 2011
//
// Module Name:      pet2001hw
//
// Description:      Encapsulate all Pet hardware except cpu.
//
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2011, Thomas Skibo.  All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// * Redistributions of source code must retain the above copyright
//   notice, this list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright
//   notice, this list of conditions and the following disclaimer in the
//   documentation and/or other materials provided with the distribution.
// * The names of contributors may not be used to endorse or promote products
//   derived from this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL Thomas Skibo OR CONTRIBUTORS BE LIABLE FOR
// ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
// LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
// OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
// SUCH DAMAGE.
//
//////////////////////////////////////////////////////////////////////////////

module pet2001hw
(
	input [15:0]     addr, // CPU Interface
	input [7:0]      data_in,
	output reg [7:0] data_out,
	input            we,
	output           irq,

	output           pix,
	output           HSync,
	output           VSync,

	output [3:0]     keyrow, // Keyboard
	input  [7:0]     keyin,

	output           cass_motor_n, // Cassette
	output           cass_write,
	input            cass_sense_n,
	input            cass_read,
	output           audio, // CB2 audio

	input  [13:0]    dma_addr,
	input   [7:0]    dma_din,
	output  [7:0]    dma_dout,
	input            dma_we,

	input            clk_speed,
	input            clk_stop,
	input            diag_l,
	input            clk,
	input            ce_7mp,
	input            ce_7mn,
	input            ce_1m,
	input            reset
);

/////////////////////////////////////////////////////////////
// Pet ROMS incuding character ROM.  Character data is read
// out second port.  This brings total ROM to 16K which is
// easy to arrange.
/////////////////////////////////////////////////////////////
wire [7:0]	rom_data;

wire [10:0] charaddr;
wire [7:0] 	chardata;

pet2001rom rom
(
	.q_a(rom_data),
	.q_b(chardata),
	.address_a(addr[13:0]),
	.address_b({3'b101,charaddr}),
	.clock(clk)
);

	
//////////////////////////////////////////////////////////////
// Pet RAM and video RAM.  Video RAM is dual ported.
//////////////////////////////////////////////////////////////
wire [7:0] 	ram_data;
wire [7:0] 	vram_data;
wire [7:0] 	video_data;
wire [10:0] video_addr;

wire	ram_we  = we && (addr[15:14] == 2'b00);
wire	vram_we = we && (addr[15:11] == 5'b1000_0);

pet2001ram ram
(
	.clock(clk),

	.q_a(ram_data),
	.data_a(data_in),
	.address_a(addr[13:0]),
	.wren_a(ram_we),

	.q_b(dma_dout),
	.data_b(dma_din),
	.address_b(dma_addr),
	.wren_b(dma_we)
);

pet2001vram vidram
(
	.clock(clk),

	.address_a(addr[10:0]),
	.data_a(data_in),
	.wren_a(vram_we),
	.q_a(vram_data),

	.address_b(video_addr),
	.data_b(0),
	.wren_b(0),
	.q_b(video_data)
);

//////////////////////////////////////
// Video hardware.
//////////////////////////////////////
wire	video_on;    // signal indicating VGA is scanning visible
				       // rows.  Used to generate tick interrupts.
wire 	video_blank; // blank screen during scrolling
wire	video_gfx;	 // display graphic characters vs. lower-case
 
pet2001video vid(.*);
 
////////////////////////////////////////////////////////
// I/O hardware
////////////////////////////////////////////////////////
wire [7:0] 	io_read_data;
wire 	io_we = we && (addr[15:11] == 5'b1110_1);

pet2001io io
(
	.*,
	.ce(ce_1m),
	.data_out(io_read_data),
	.data_in(data_in),
	.addr(addr[10:0]),
	.we(io_we),
	.video_sync(video_on)
);

/////////////////////////////////////
// Read data mux (to CPU)
/////////////////////////////////////
always @(*)
casex(addr[15:11])
	5'b1111_x:                 // F000-FFFF
		data_out = rom_data;
	5'b1110_1:                 // E800-EFFF
		data_out = io_read_data;
	5'b1110_0:                 // E000-E7FF
		data_out = rom_data;
	5'b110x_x:                 // C000-DFFF
		data_out = rom_data;
	5'b1000_0:                 // 8000-87FF
		data_out = vram_data;
	5'b00xx_x:                 // 0000-3FFF
		data_out = ram_data;
	default:
		data_out = 8'h55;
endcase

endmodule // pet2001hw
