`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////
//
// Engineer:	Thomas Skibo 
// 
// Create Date:	Sep 24, 2011
//
// Module Name: pia6520
//
// Description:
//
//	A simple implementation of the 6520 Peripheral Interface Adapter (PIA).
//	Tri-state lines aren't used.  Instead,  All PIA I/O signals have
//	seperate "in" and "out" signals.  Wire or ignore appropriately.
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

module pia6520
(
	output reg [7:0] data_out,	// cpu interface
	input      [7:0] data_in,
	input      [1:0] addr,
	input            strobe,
	input            we,

	output           irq,
	 
	output reg [7:0] porta_out,
	input      [7:0] porta_in,
	output reg [7:0] portb_out,
	input      [7:0] portb_in,

	input            ca1_in,
	output reg       ca2_out,
	input            ca2_in,
	input            cb1_in,
	output reg       cb2_out,
	input            cb2_in,

	input            clk,
	input            reset
);

reg [7:0] ddra;
reg [5:0] cra;
reg       irqa1;
reg       irqa2;
 
reg [7:0] ddrb;
reg [5:0] crb;
reg       irqb1;
reg       irqb2;

// Register address offsets
parameter [1:0]
	ADDR_PORTA = 2'b00,
	ADDR_CRA   = 2'b01,
	ADDR_PORTB = 2'b10,
	ADDR_CRB   = 2'b11;

wire wr_strobe = strobe && we;
wire rd_strobe = strobe && !we;
wire porta_rd_strobe = rd_strobe && addr == ADDR_PORTA;
wire portb_rd_strobe = rd_strobe && addr == ADDR_PORTB;
wire portb_wr_strobe = wr_strobe && addr == ADDR_PORTB;

// Implement CRA[5:0]
always @(posedge clk) begin
	if (reset) cra <= 6'b00_0000;
	else if (wr_strobe && addr == ADDR_CRA) cra <= data_in[5:0];
end

// Implement CRB[5:0]
always @(posedge clk) begin
	if (reset) crb <= 6'b00_0000;
	else if (wr_strobe && addr == ADDR_CRB) crb <= data_in[5:0];
end

// Implement PORTA (out)
always @(posedge clk) begin
	if (reset) porta_out <= 8'h00;
	else if (wr_strobe && addr == ADDR_PORTA && cra[2]) porta_out <= data_in;
end

// Implement DDRA
always @(posedge clk) begin
	if (reset) ddra <= 8'h00;
	else if (wr_strobe && addr == ADDR_PORTA && !cra[2]) ddra <= data_in;
end

// Implement PORTB (out)
always @(posedge clk) begin
	if (reset) portb_out <= 8'h00;
	else if (wr_strobe && addr == ADDR_PORTB && crb[2]) portb_out <= data_in;
end

// Implement DDRB
always @(posedge clk) begin
	if (reset) ddrb <= 8'h00;
	else if (wr_strobe && addr == ADDR_PORTB && !crb[2]) ddrb <= data_in;
end

////////////////////////////////////////////////////////
// IRQA logic

// register ca1_in and ca2_in to detect transitions.
reg	ca1_in_1;
reg ca2_in_1;
always @(posedge clk) begin
	ca1_in_1 <= ca1_in;
	ca2_in_1 <= ca2_in;
end

// detect "active" transitions
wire ca1_act_trans = ((ca1_in && !ca1_in_1 && cra[1]) || (!ca1_in && ca1_in_1 && !cra[1]));
wire ca2_act_trans = ((ca2_in && !ca2_in_1 && cra[4]) || (!ca2_in && ca2_in_1 && !cra[4]));

// IRQA1
always @(posedge clk) begin
	if (reset || (porta_rd_strobe && !ca1_act_trans)) irqa1 <= 1'b0;
	else if (ca1_act_trans) irqa1 <= 1'b1;
end

// IRQA2
always @(posedge clk) begin
	if (reset || (porta_rd_strobe && !ca2_act_trans)) irqa2 <= 1'b0;
	else if (ca2_act_trans && !cra[5]) irqa2 <= 1'b1;
end

   
////////////////////////////////////////////////////////
// IRQB logic

// register cb1_in and cb2_in to detect transitions.
reg cb1_in_1;
reg cb2_in_1;
always @(posedge clk) begin
	cb1_in_1 <= cb1_in;
	cb2_in_1 <= cb2_in;
end

// detect "active" transitions
wire cb1_act_trans = ((cb1_in && !cb1_in_1 && crb[1]) || (!cb1_in && cb1_in_1 && !crb[1]));
wire cb2_act_trans = ((cb2_in && !cb2_in_1 && crb[4]) || (!cb2_in && cb2_in_1 && !crb[4]));

// IRQB1
always @(posedge clk) begin
	if (reset || (portb_rd_strobe && !cb1_act_trans)) irqb1 <= 1'b0;
	else if (cb1_act_trans) irqb1 <= 1'b1;
end

// IRQB2
always @(posedge clk) begin
	if (reset || (portb_rd_strobe && !cb2_act_trans)) irqb2 <= 1'b0;
	else if (cb2_act_trans && !crb[5]) irqb2 <= 1'b1;
end

 
// IRQ and enable logic.
assign irq = (irqa1 && cra[0]) || (irqa2 && cra[3]) ||
             (irqb1 && crb[0]) || (irqb2 && crb[3]);

///////////////////////////////////////////////////
// CA2 and CB2 output modes
always @(posedge clk) begin
	case (cra[5:3])
		3'b100:  ca2_out <= irqa1;
		3'b101:  ca2_out <= !ca1_act_trans;
		3'b111:  ca2_out <= 1'b1;
		default: ca2_out <= 1'b0;
	endcase
end

reg cb2_out_r;
always @(posedge clk) begin
	if (reset || (portb_wr_strobe && !cb1_act_trans)) cb2_out_r <= 1'b0;
	else if (cb1_act_trans) cb2_out_r <= 1'b1;
end

always @(posedge clk) begin
	case (crb[5:3])
		3'b100:  cb2_out <= cb2_out_r;
		3'b101:  cb2_out <= !portb_wr_strobe;
		3'b111:  cb2_out <= 1'b1;
		default: cb2_out <= 1'b0;
	endcase
end
   
///////////////////////////////////////////////////
// Read data mux
wire [7:0] porta = (porta_out & ddra) | (porta_in & ~ddra);
wire [7:0] portb = (portb_out & ddrb) | (portb_in & ~ddrb);

always @(*) begin
	case (addr)
		ADDR_PORTA: data_out = cra[2] ? porta : ddra;
		ADDR_CRA:   data_out = { irqa1, irqa2, cra };
		ADDR_PORTB: data_out = crb[2] ? portb : ddrb;
		ADDR_CRB:   data_out = { irqb1, irqb2, crb };
	endcase
end

endmodule // pia6520
