`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////
//
// Engineer:	Thomas Skibo 
// 
// Create Date:	Sep 24, 2011
//
// Module Name: pet2001io
//
// Description:
//	I/O devices for Pet emulator.  Includes two PIAs and a VIA and a
//	module that converts a PS2 keyboard into a PET keyboard.
//
//	I/O is mapped into region 0xE800-0xEFFF.
//
//		0xE810-0xE813		PIA1
//		0xE820-0xE823		PIA2
//		0xE840-0xE84F		VIA
//
/////////////////////////////////////////////////////////////////////////////
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

module pet2001io
(
	output reg [7:0] data_out, 	// CPU interface
	input  [7:0] data_in,
	input [10:0] addr,
	input        we,

	output       irq,

	output [3:0] keyrow, 		// Keyboard
	input  [7:0] keyin,

	output       video_blank, 	// Video controls
	output       video_gfx,
	input        video_sync,

	output       cass_motor_n, 	// Cassette #1 interface
	output       cass_write,
	input        cass_sense_n,
	input        cass_read,
	output       audio, 		// CB2 audio

	input        diag_l, 	// diag jumper input

	input        ce,
	input        clk,
	input        reset
);

//delay ce for io for stability.
reg strobe_io;
always @(negedge clk) strobe_io <= ce;

/////////////////////////// 6520 PIA1 ////////////////////////////////////
//
wire       pia1_strobe = strobe_io && (addr[10:2] == 9'b000_0001_00);
wire [7:0] pia1_data_out;
wire       pia1_irq;
wire [7:0] pia1_porta_out;
wire [7:0] pia1_porta_in = {diag_l, 2'b00, cass_sense_n, 4'b0000};
wire       pia1_ca1_in = !cass_read;
wire       pia1_ca2_out;

pia6520 pia1
(
	.data_out(pia1_data_out),
	.data_in(data_in),
	.addr(addr[1:0]),
	.strobe(pia1_strobe),
	.we(we),

	.irq(pia1_irq),
	.porta_out(pia1_porta_out),
	.porta_in(pia1_porta_in),
	.portb_out(),
	.portb_in(keyin),

	.ca1_in(pia1_ca1_in),
	.ca2_out(pia1_ca2_out),
	.ca2_in(1'b0),

	.cb1_in(video_sync),
	.cb2_out(cass_motor_n),
	.cb2_in(1'b0),

	.clk(clk),
	.reset(reset)
);
 
assign video_blank = !pia1_ca2_out;
assign keyrow = pia1_porta_out[3:0];

 
////////////////////////// 6520 PIA2 ////////////////////////////////////
// (does nothing for now)
wire       pia2_strobe = strobe_io && (addr[10:2] == 9'b000_0010_00);
wire [7:0] pia2_data_out;
wire       pia2_irq;

pia6520 pia2
(
	.data_out(pia2_data_out),
	.data_in(data_in),
	.addr(addr[1:0]),
	.strobe(pia2_strobe),
	.we(we),

	.irq(pia2_irq),
	.porta_out(),
	.porta_in(8'h00),
	.portb_out(),
	.portb_in(8'h00),

	.ca1_in(1'b0),
	.ca2_out(),
	.ca2_in(1'b0),

	.cb1_in(1'b0),
	.cb2_out(),
	.cb2_in(1'b0),

	.clk(clk),
	.reset(reset)
);


/////////////////////////// 6522 VIA ////////////////////////////////////
//
wire	     via_strobe = strobe_io && (addr[10:4] == 7'b000_0100);
wire [7:0] via_data_out;
wire       via_irq;
wire [7:0] via_portb_out;
wire [7:0] via_portb_in = {2'b00, video_sync, 5'b0_0000};

via6522 via
(
	.data_out(via_data_out),
	.data_in(data_in),
	.addr(addr[3:0]),
	.strobe(via_strobe),
	.we(we),

	.irq(via_irq),
	.porta_out(),
	.porta_in(8'h00),
	.portb_out(via_portb_out),
	.portb_in(via_portb_in),

	.ca1_in(1'b0),
	.ca2_out(video_gfx),
	.ca2_in(1'b0),

	.cb1_out(),
	.cb1_in(1'b0),
	.cb2_out(audio),
	.cb2_in(1'b0),

	.ce(ce),

	.clk(clk),
	.reset(reset)
);

assign cass_write = via_portb_out[3];


/////////////// Read data mux /////////////////////////
// register I/O stuff, therefore RDY must be delayed a cycle!
//
always @(posedge clk)
casex (addr[10:2])
			9'b000_0001_00:	data_out <= pia1_data_out;
			9'b000_0010_00:	data_out <= pia2_data_out;
			9'b000_0100_xx:	data_out <= via_data_out;
			default: 		data_out <= 8'hXX;
endcase
 
assign irq = pia1_irq || pia2_irq || via_irq;

endmodule // pet2001io
