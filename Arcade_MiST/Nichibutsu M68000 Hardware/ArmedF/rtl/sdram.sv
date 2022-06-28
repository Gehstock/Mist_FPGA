//
// sdram.v
//
// sdram controller implementation for the MiST board
// https://github.com/mist-devel/mist-board
// 
// Copyright (c) 2013 Till Harbaum <till@harbaum.org> 
// Copyright (c) 2019-2022 Gyorgy Szombathelyi
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
	inout  reg [15:0] SDRAM_DQ,   // 16 bit bidirectional data bus
	output reg [12:0] SDRAM_A,    // 13 bit multiplexed address bus
	output reg        SDRAM_DQML, // two byte masks
	output reg        SDRAM_DQMH, // two byte masks
	output reg [1:0]  SDRAM_BA,   // two banks
	output            SDRAM_nCS,  // a single chip select
	output            SDRAM_nWE,  // write enable
	output            SDRAM_nRAS, // row address select
	output            SDRAM_nCAS, // columns address select

	// cpu/chipset interface
	input             init_n,     // init signal after FPGA config to initialize RAM
	input             clk,        // sdram clock

	// 1st bank
	input             port1_req,
	output reg        port1_ack,
	input             port1_we,
	input      [23:1] port1_a,
	input       [1:0] port1_ds,
	input      [15:0] port1_d,
	output reg [15:0] port1_q,

	// cpu1 rom/ram
	input      [20:1] cpu1_rom_addr,
	input             cpu1_rom_cs,
	output reg [15:0] cpu1_rom_q,
	output reg        cpu1_rom_valid,

	input             cpu1_ram_req,
	output reg        cpu1_ram_ack,
	input      [19:1] cpu1_ram_addr,
	input             cpu1_ram_we,
	input       [1:0] cpu1_ram_ds,
	input      [15:0] cpu1_ram_d,
	output reg [15:0] cpu1_ram_q,

	// cpu2 rom
	input      [20:1] cpu2_addr,
	input             cpu2_rom_cs,
	output reg [15:0] cpu2_q,
	output reg        cpu2_valid,
	// cpu3 rom
	input      [20:1] cpu3_addr,
	input             cpu3_rom_cs,
	output reg [15:0] cpu3_q,
	output reg        cpu3_valid,
	// cpu4 rom
	input      [20:1] cpu4_addr,
	output reg [15:0] cpu4_q,
	output reg        cpu4_valid,

	// 2nd bank
	input             port2_req,
	output reg        port2_ack,
	input             port2_we,
	input      [23:1] port2_a,
	input       [1:0] port2_ds,
	input      [15:0] port2_d,
	output reg [31:0] port2_q,
	
	input      [20:2] gfx1_addr,
	output reg [31:0] gfx1_q,
	input      [20:2] gfx2_addr,
	output reg [31:0] gfx2_q,
	input      [20:2] gfx3_addr,
	output reg [31:0] gfx3_q,

	input      [20:2] sp_addr,
	input             sp_req,
	output reg        sp_ack,
	output reg [31:0] sp_q
);

parameter  MHZ = 16'd80; // 80 MHz default clock, set it to proper value to calculate refresh rate

localparam RASCAS_DELAY   = 3'd2;   // tRCD=20ns -> 2 cycles@<100MHz
localparam BURST_LENGTH   = 3'b001; // 000=1, 001=2, 010=4, 011=8
localparam ACCESS_TYPE    = 1'b0;   // 0=sequential, 1=interleaved
localparam CAS_LATENCY    = 3'd2;   // 2/3 allowed
localparam OP_MODE        = 2'b00;  // only 00 (standard operation) allowed
localparam NO_WRITE_BURST = 1'b1;   // 0= write burst enabled, 1=only single access write

localparam MODE = { 3'b000, NO_WRITE_BURST, OP_MODE, CAS_LATENCY, ACCESS_TYPE, BURST_LENGTH}; 

// 64ms/8192 rows = 7.8us
localparam RFRSH_CYCLES = 16'd78*MHZ/4'd10;

// ---------------------------------------------------------------------
// ------------------------ cycle state machine ------------------------
// ---------------------------------------------------------------------

/*
 SDRAM state machine for 2 bank interleaved access
 2 words burst, CL2
cmd issued  registered
 0 RAS0     cas1 - data0 read burst terminated
 1          ras0
 2          data1 returned
 3 CAS0     data1 returned
 4 RAS1     cas0
 5          ras1
 6 CAS1     data0 returned
*/

localparam STATE_RAS0      = 3'd0;   // first state in cycle
localparam STATE_RAS1      = 3'd4;   // Second ACTIVE command after RAS0 + tRRD (15ns)
localparam STATE_CAS0      = STATE_RAS0 + RASCAS_DELAY + 1'd1; // CAS phase - 3
localparam STATE_CAS1      = STATE_RAS1 + RASCAS_DELAY; // CAS phase - 6
localparam STATE_READ0     = 3'd0;// STATE_CAS0 + CAS_LATENCY + 2'd2; // 7
localparam STATE_READ1     = 3'd3;
localparam STATE_DS1b      = 3'd0;
localparam STATE_READ1b    = 3'd4;
localparam STATE_LAST      = 3'd6;

reg [2:0] t;

always @(posedge clk) begin
	t <= t + 1'd1;
	if (t == STATE_LAST) t <= STATE_RAS0;
end

// ---------------------------------------------------------------------
// --------------------------- startup/reset ---------------------------
// ---------------------------------------------------------------------

// wait 1ms (32 8Mhz cycles) after FPGA config is done before going
// into normal operation. Initialize the ram in the last 16 reset cycles (cycles 15-0)
reg [4:0]  reset;
reg        init = 1'b1;
always @(posedge clk, negedge init_n) begin
	if(!init_n) begin
		reset <= 5'h1f;
		init <= 1'b1;
	end else begin
		if((t == STATE_LAST) && (reset != 0)) reset <= reset - 5'd1;
		init <= !(reset == 0);
	end
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

reg [3:0]  sd_cmd;   // current command sent to sd ram
reg [15:0] sd_din;
// drive control signals according to current command
assign SDRAM_nCS  = sd_cmd[3];
assign SDRAM_nRAS = sd_cmd[2];
assign SDRAM_nCAS = sd_cmd[1];
assign SDRAM_nWE  = sd_cmd[0];

reg [24:1] addr_latch[3];
reg [24:1] addr_latch_next[2];
reg [20:1] addr_last[1:5];
reg [20:2] addr_last2[5];
reg [15:0] din_next;
reg [15:0] din_latch[2];
reg        oe_next;
reg  [1:0] oe_latch;
reg        we_next;
reg  [1:0] we_latch;
reg  [1:0] ds_next;
reg  [1:0] ds[2];

reg        port1_state;
reg        port2_state;
reg        cpu1_ram_req_state;

localparam PORT_NONE     = 3'd0;
localparam PORT_CPU1_ROM = 3'd1;
localparam PORT_CPU1_RAM = 3'd2;
localparam PORT_CPU2     = 3'd3;
localparam PORT_CPU3     = 3'd4;
localparam PORT_CPU4     = 3'd5;
localparam PORT_GFX1     = 3'd1;
localparam PORT_GFX2     = 3'd2;
localparam PORT_GFX3     = 3'd3;
localparam PORT_SP       = 3'd4;
localparam PORT_REQ      = 3'd6;

reg  [2:0] next_port[2];
reg  [2:0] port[2];

reg        refresh;
reg [10:0] refresh_cnt;
wire       need_refresh = (refresh_cnt >= RFRSH_CYCLES);

// PORT1: bank 0,1
always @(*) begin
	next_port[0] = PORT_NONE;
	addr_latch_next[0] = addr_latch[0];
	ds_next = 2'b00;
	{ oe_next, we_next } = 2'b00;
	din_next = 0;

	if (refresh) begin
		// nothing
	end else if (port1_req ^ port1_state) begin
		next_port[0] = PORT_REQ;
		addr_latch_next[0] = { 1'b0, port1_a };
		ds_next = port1_ds;
		{ oe_next, we_next } = { ~port1_we, port1_we };
		din_next = port1_d;
	end else if (/*cpu1_rom_addr != addr_last[PORT_CPU1_ROM] &&*/ cpu1_rom_cs && !cpu1_rom_valid) begin
		next_port[0] = PORT_CPU1_ROM;
		addr_latch_next[0] = { 4'd0, cpu1_rom_addr };
		ds_next = 2'b11;
		{ oe_next, we_next } = 2'b10;
	end else if (cpu1_ram_req ^ cpu1_ram_req_state) begin
		next_port[0] = PORT_CPU1_RAM;
		addr_latch_next[0] = { 2'b00, 3'b100, cpu1_ram_addr };
		ds_next = cpu1_ram_ds;
		{ oe_next, we_next } = { ~cpu1_ram_we, cpu1_ram_we };
		din_next = cpu1_ram_d;
	end else if (cpu2_addr != addr_last[PORT_CPU2] && cpu2_rom_cs) begin
		next_port[0] = PORT_CPU2;
		addr_latch_next[0] = { 4'd0, cpu2_addr };
		ds_next = 2'b11;
		{ oe_next, we_next } = 2'b10;
	end else if (cpu3_addr != addr_last[PORT_CPU3] && cpu3_rom_cs) begin
		next_port[0] = PORT_CPU3;
		addr_latch_next[0] = { 4'd0, cpu3_addr };
		ds_next = 2'b11;
		{ oe_next, we_next } = 2'b10;
	end else if (cpu4_addr != addr_last[PORT_CPU4]) begin
		next_port[0] = PORT_CPU4;
		addr_latch_next[0] = { 4'd0, cpu4_addr };
		ds_next = 2'b11;
		{ oe_next, we_next } = 2'b10;
	end
end

// PORT1: bank 2,3
always @(*) begin
	if (port2_req ^ port2_state) begin
		next_port[1] = PORT_REQ;
		addr_latch_next[1] = { 1'b1, port2_a };
	end else if (gfx1_addr != addr_last2[PORT_GFX1]) begin
		next_port[1] = PORT_GFX1;
		addr_latch_next[1] = { 1'b1, 3'd0, gfx1_addr, 1'b0 };
	end else if (gfx2_addr != addr_last2[PORT_GFX2]) begin
		next_port[1] = PORT_GFX2;
		addr_latch_next[1] = { 1'b1, 3'd0, gfx2_addr, 1'b0 };
	end else if (gfx3_addr != addr_last2[PORT_GFX3]) begin
		next_port[1] = PORT_GFX3;
		addr_latch_next[1] = { 1'b1, 3'd0, gfx3_addr, 1'b0 };
	end else if (sp_req ^ sp_ack) begin
		next_port[1] = PORT_SP;
		addr_latch_next[1] = { 1'b1, 3'd0, sp_addr, 1'b0 };
	end else begin
		next_port[1] = PORT_NONE;
		addr_latch_next[1] = addr_latch[1];
	end
end

always @(posedge clk) begin

	// permanently latch ram data to reduce delays
	sd_din <= SDRAM_DQ;
	SDRAM_DQ <= 16'bZZZZZZZZZZZZZZZZ;
	{ SDRAM_DQMH, SDRAM_DQML } <= 2'b11;
	sd_cmd <= CMD_NOP;  // default: idle
	refresh_cnt <= refresh_cnt + 1'd1;

	if(init) begin
		{ cpu1_rom_valid, cpu2_valid, cpu3_valid, cpu4_valid } <= 0;
		// initialization takes place at the end of the reset phase
		if(t == STATE_RAS0) begin

			if(reset == 15) begin
				sd_cmd <= CMD_PRECHARGE;
				SDRAM_A[10] <= 1'b1;      // precharge all banks
			end

			if(reset == 10 || reset == 8) begin
				sd_cmd <= CMD_AUTO_REFRESH;
			end

			if(reset == 2) begin
				sd_cmd <= CMD_LOAD_MODE;
				SDRAM_A <= MODE;
				SDRAM_BA <= 2'b00;
			end
		end
	end else begin
		if (!cpu1_rom_cs) cpu1_rom_valid <= 0;
		if (cpu2_addr != addr_last[PORT_CPU2] && cpu2_rom_cs) cpu2_valid <= 0;
		if (cpu3_addr != addr_last[PORT_CPU3] && cpu3_rom_cs) cpu3_valid <= 0;
		if (cpu4_addr != addr_last[PORT_CPU4]) cpu4_valid <= 0;

		// RAS phase
		// bank 0,1
		if(t == STATE_RAS0) begin
			addr_latch[0] <= addr_latch_next[0];
			port[0] <= next_port[0];
			{ oe_latch[0], we_latch[0] } <= 2'b00;

			if (next_port[0] != PORT_NONE) begin
				sd_cmd <= CMD_ACTIVE;
				SDRAM_A <= addr_latch_next[0][22:10];
				SDRAM_BA <= addr_latch_next[0][24:23];
			end
			addr_last[next_port[0]] <= addr_latch_next[0][20:1];
			ds[0] <= ds_next;
			{ oe_latch[0], we_latch[0] } <= { oe_next, we_next };
			din_latch[0] <= din_next;

			if (next_port[0] == PORT_REQ) port1_state <= port1_req;
			if (next_port[0] == PORT_CPU1_RAM) cpu1_ram_req_state <= cpu1_ram_req;
		end

		// bank 2,3
		if(t == STATE_RAS1) begin
			refresh <= 1'b0;
			addr_latch[1] <= addr_latch_next[1];
			{ oe_latch[1], we_latch[1] } <= 2'b00;
			port[1] <= next_port[1];

			if (next_port[1] != PORT_NONE) begin
				sd_cmd <= CMD_ACTIVE;
				SDRAM_A <= addr_latch_next[1][22:10];
				SDRAM_BA <= addr_latch_next[1][24:23];
				addr_last2[next_port[1]] <= addr_latch_next[1][20:2];
				if (next_port[1] == PORT_REQ) begin
					{ oe_latch[1], we_latch[1] } <= { ~port1_we, port1_we };
					ds[1] <= port2_ds;
					din_latch[1] <= port2_d;
					port2_state <= port2_req;
				end else begin
					{ oe_latch[1], we_latch[1] } <= 2'b10;
					ds[1] <= 2'b11;
				end
			end

			if (next_port[1] == PORT_NONE && need_refresh && !we_latch[0] && !oe_latch[0]) begin
				refresh <= 1'b1;
				refresh_cnt <= 0;
				sd_cmd <= CMD_AUTO_REFRESH;
			end
		end

		// CAS phase
		if(t == STATE_CAS0 && (we_latch[0] || oe_latch[0])) begin
			sd_cmd <= we_latch[0]?CMD_WRITE:CMD_READ;
			{ SDRAM_DQMH, SDRAM_DQML } <= ~ds[0];
			if (we_latch[0]) begin
				SDRAM_DQ <= din_latch[0];
				case(port[0])
					PORT_REQ: port1_ack <= port1_req;
					PORT_CPU1_RAM: cpu1_ram_ack <= cpu1_ram_req;
					default: ;
				endcase;
			end
			SDRAM_A <= { 4'b0010, addr_latch[0][9:1] };  // auto precharge
			SDRAM_BA <= addr_latch[0][24:23];
		end

		if(t == STATE_CAS1 && (we_latch[1] || oe_latch[1])) begin
			sd_cmd <= we_latch[1]?CMD_WRITE:CMD_READ;
			{ SDRAM_DQMH, SDRAM_DQML } <= ~ds[1];
			if (we_latch[1]) begin
				SDRAM_DQ <= din_latch[1];
				port2_ack <= port2_req;
			end
			SDRAM_A <= { 4'b0010, addr_latch[1][9:1] };  // auto precharge
			SDRAM_BA <= addr_latch[1][24:23];
		end

		// Data returned
		if(t == STATE_READ0 && oe_latch[0]) begin
			case(port[0])
				PORT_REQ:  begin port1_q <= sd_din; port1_ack <= port1_req; end
				PORT_CPU1_ROM: begin cpu1_rom_q <= sd_din; cpu1_rom_valid <= 1; end
				PORT_CPU1_RAM: begin cpu1_ram_q <= sd_din; cpu1_ram_ack <= cpu1_ram_req; end
				PORT_CPU2: begin cpu2_q  <= sd_din; cpu2_valid <= 1; end
				PORT_CPU3: begin cpu3_q  <= sd_din; cpu3_valid <= 1; end
				PORT_CPU4: begin cpu4_q  <= sd_din; cpu4_valid <= 1; end
				default: ;
			endcase;
		end

		if(t == STATE_READ1 && oe_latch[1]) begin
			case(port[1])
				PORT_REQ  : port2_q[15:0] <= sd_din;
				PORT_GFX1 :  gfx1_q[15:0] <= sd_din;
				PORT_GFX2 :  gfx2_q[15:0] <= sd_din;
				PORT_GFX3 :  gfx3_q[15:0] <= sd_din;
				PORT_SP   :    sp_q[15:0] <= sd_din;
				default: ;
			endcase;
		end

		if(t == STATE_DS1b && oe_latch[1]) { SDRAM_DQMH, SDRAM_DQML } <= ~ds[1];

		if(t == STATE_READ1b && oe_latch[1]) begin
			case(port[1])
				PORT_REQ  : begin port2_q[31:16] <= sd_din; port2_ack <= port2_req; end
				PORT_GFX1 : begin  gfx1_q[31:16] <= sd_din; end
				PORT_GFX2 : begin  gfx2_q[31:16] <= sd_din; end
				PORT_GFX3 : begin  gfx3_q[31:16] <= sd_din; end
				PORT_SP   : begin    sp_q[31:16] <= sd_din; sp_ack <= sp_req; end
				default: ;
			endcase;
		end
	end
end

endmodule
