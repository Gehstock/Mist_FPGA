//
// sdram.v
//
//	(Darfpga configuration for 1x8bits write / 8x16bits read - 01/12/2019)
//
// sdram controller implementation for the MiST board adaptation
// of Luddes NES core
// http://code.google.com/p/mist-board/
// 
// Copyright (c) 2013 Till Harbaum <till@harbaum.org> 
// 
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or 
// (at your option) any later version. 
// 
// This source file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License 
// along with this program.  If not, see <http://www.gnu.org/licenses/>. 
//

module sdram (

	// interface to the MT48LC16M16 chip
	inout  [15:0] 	  sd_data,    // 16 bit bidirectional data bus
	output [12:0]	  sd_addr,    // 13 bit multiplexed address bus
	output [1:0] 	  sd_dqm,     // two byte masks
	output [1:0] 	  sd_ba,      // two banks
	output 			  sd_cs,      // a single chip select
	output 			  sd_we,      // write enable
	output 			  sd_ras,     // row address select
	output 			  sd_cas,     // columns address select

	// cpu/chipset interface
	input 		 	   init, // init signal after FPGA config to initialize RAM
	input 		 	   clk,  // sdram is accessed at up to 128MHz
	
	input [24:0]      addr, // 25 bit byte address
	input 		 	   we,   // requests write
	input [7:0]  	   di,   // data input
	input 		 	   rd,   // requests data
	output[4:0]       sm_cycle // state machine cycle

);

// burst 8 data configured
localparam RASCAS_DELAY   = 3'd3;   // tRCD=20ns -> 3 cycles@130MHz
localparam BURST_LENGTH   = 3'b011; // 000=1, 001=2, 010=4, 011=8
localparam ACCESS_TYPE    = 1'b0;   // 0=sequential, 1=interleaved
localparam CAS_LATENCY    = 3'd2;   // 2/3 allowed
localparam OP_MODE        = 2'b00;  // only 00 (standard operation) allowed
localparam NO_WRITE_BURST = 1'b1;   // 0= write burst enabled, 1=only single access write

localparam MODE = { 3'b000, NO_WRITE_BURST, OP_MODE, CAS_LATENCY, ACCESS_TYPE, BURST_LENGTH}; 

// ---------------------------------------------------------------------
// ------------------------ cycle state machine ------------------------
// ---------------------------------------------------------------------

localparam STATE_FIRST     = 5'd0;   // first state in cycle
localparam STATE_CMD_START = 5'd1;   // state in which a new command can be started
localparam STATE_CMD_CONT  = STATE_CMD_START  + RASCAS_DELAY; // 4 command can be continued
localparam STATE_CMD_REF1  = 5'd17;  // last state in cycle
localparam STATE_CMD_REF2  = 5'd22;  // last state in cycle
localparam STATE_LAST      = 5'd31;  // last state in cycle

reg [4:0] q;
always @(posedge clk) begin
	// SDRAM (state machine)
	// wait for read or write to start cycle
	if       (q == STATE_LAST) q <= STATE_FIRST;
	else if ((q == STATE_FIRST) && (we || rd) || (q != STATE_FIRST)) q <= q + 5'd1;
end

assign sm_cycle = q;

// ---------------------------------------------------------------------
// --------------------------- startup/reset ---------------------------
// ---------------------------------------------------------------------

// wait 700us (85000 cycles) after FPGA config is done before going
// into normal operation. Initialize the ram in the last 16 reset cycles (cycles 15-0)
reg [16:0] reset;
always @(posedge clk) begin
	if(init)	reset <= 17'h14c08;
	else if((q == STATE_LAST) && (reset != 0))
		reset <= reset - 17'd1;
end

// ---------------------------------------------------------------------
// ------------------ generate ram control signals ---------------------
// ---------------------------------------------------------------------

// all possible commands
localparam CMD_INHIBIT         = 4'b1111;
localparam CMD_NOP             = 4'b0111;
localparam CMD_ACTIVE          = 4'b0011;
localparam CMD_READ            = 4'b0101;
localparam CMD_WRITE           = 4'b0100;
localparam CMD_BURST_TERMINATE = 4'b0110;
localparam CMD_PRECHARGE       = 4'b0010;
localparam CMD_AUTO_REFRESH    = 4'b0001;
localparam CMD_LOAD_MODE       = 4'b0000;

wire [3:0] sd_cmd;   // current command sent to sd ram

// drive control signals according to current command
assign sd_cs  = sd_cmd[3];
assign sd_ras = sd_cmd[2];
assign sd_cas = sd_cmd[1];
assign sd_we  = sd_cmd[0];

// drive ram data lines when writing, set them as inputs otherwise
// the eight bits are sent on both bytes ports. Which one's actually
// written depends on the state of dqm of which only one is active
// at a time when writing
assign sd_data = we?{di, di}:16'bZZZZZZZZZZZZZZZZ;

wire [3:0] reset_cmd = 
	((q == STATE_CMD_START) && (reset == 13))?CMD_PRECHARGE:
	((q == STATE_CMD_START) && (reset ==  2))?CMD_LOAD_MODE:
	CMD_INHIBIT;

wire [3:0] run_cmd =
	((we || rd) && (q == STATE_CMD_START))?CMD_ACTIVE:
	(we && 			(q == STATE_CMD_CONT ))?CMD_WRITE:
	(!we &&  rd &&	(q == STATE_CMD_CONT ))?CMD_READ:
//	(!we && !rd && (q == STATE_CMD_START))?CMD_AUTO_REFRESH:
	((q == STATE_CMD_REF1))?CMD_AUTO_REFRESH:
	((q == STATE_CMD_REF2))?CMD_AUTO_REFRESH:
	CMD_INHIBIT;
	
assign sd_cmd = (reset != 0)?reset_cmd:run_cmd;

wire [12:0] reset_addr = (reset == 13)?13'b0010000000000:MODE;
	
wire [12:0] run_addr = 
	(q == STATE_CMD_START)?addr[21:9]:{ 4'b0010, addr[24], addr[8:1]};

assign sd_addr = (reset != 0)?reset_addr:run_addr;

assign sd_ba = addr[23:22];

assign sd_dqm = we?{ addr[0], ~addr[0] }:2'b00;

endmodule
