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

module sdram_4w_cl3 (

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
	output reg        port1_ack = 0,
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
	output reg        cpu1_ram_ack = 0,
	input      [22:1] cpu1_ram_addr,
	input             cpu1_ram_we,
	input       [1:0] cpu1_ram_ds,
	input      [15:0] cpu1_ram_d,
	output reg [15:0] cpu1_ram_q,

	// cpu2 rom/ram
	input             cpu2_ram_req,
	output reg        cpu2_ram_ack = 0,
	input      [22:1] cpu2_ram_addr,
	input             cpu2_ram_we,
	input       [1:0] cpu2_ram_ds,
	input      [15:0] cpu2_ram_d,
	output reg [15:0] cpu2_ram_q,

	// cpu3 rom
	input             vram_req,
	output reg        vram_ack = 0,
	input      [22:1] vram_addr,
	output reg [31:0] vram_q,

	// 2nd bank
	input             port2_req,
	output reg        port2_ack = 0,
	input             port2_we,
	input      [23:1] port2_a,
	input       [1:0] port2_ds,
	input      [15:0] port2_d,
	output reg [31:0] port2_q,

	input             gfx1_req,
	output reg        gfx1_ack = 0,
	input      [23:1] gfx1_addr,
	output reg [31:0] gfx1_q,

	input             gfx2_req,
	output reg        gfx2_ack = 0,
	input      [23:1] gfx2_addr,
	output reg [31:0] gfx2_q,

	input             gfx3_req,
	output reg        gfx3_ack = 0,
	input      [23:1] gfx3_addr,
	output reg [31:0] gfx3_q,

	input             sample_req,
	output reg        sample_ack = 0,
	input      [23:1] sample_addr,
	output reg [63:0] sample_q,

	input             sp_req,
	output reg        sp_ack = 0,
	input      [23:1] sp_addr,
	output reg [63:0] sp_q
);

parameter  MHZ = 16'd80; // 80 MHz default clock, set it to proper value to calculate refresh rate

localparam RASCAS_DELAY   = 3'd3;   // tRCD=20ns -> 2 cycles@<100MHz
localparam BURST_LENGTH   = 3'b010; // 000=1, 001=2, 010=4, 011=8
localparam ACCESS_TYPE    = 1'b0;   // 0=sequential, 1=interleaved
localparam CAS_LATENCY    = 3'd3;   // 2/3 allowed
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
 4 words burst, CL3
cmd issued  registered
 0 RAS0     data1 returned
 1          ras0, data1 returned
 2          data1 returned
 3 CAS0
 4 RAS1     cas0
 5          ras1
 6
 7 CAS1     data0 returned
 8          cas1 - data0 masked if cas1 write
 9          data0 returned (but masked via DQM)
 10         data0 returned (but masked via DQM)
 11         data1 returned
*/

localparam STATE_RAS0      = 4'd0;   // first state in cycle
localparam STATE_CAS0      = 4'd3;
localparam STATE_READ0     = 4'd8;   // STATE_CAS0 + CAS_LATENCY + 2'd2;
localparam STATE_READ0b    = 4'd9;
localparam STATE_DS0       = 4'd4;
localparam STATE_DS0b      = 4'd5;
localparam STATE_RAS1      = 4'd4;   // Second ACTIVE command after RAS0 + tRRD (15ns)
localparam STATE_CAS1      = 4'd7;   // CAS phase
localparam STATE_READ1     = 4'd0;
localparam STATE_READ1b    = 4'd1;
localparam STATE_READ1c    = 4'd2;
localparam STATE_READ1d    = 4'd3;
localparam STATE_DS1a      = 4'd8;
localparam STATE_DS1b      = 4'd9;
localparam STATE_DS1c      = 4'd10;
localparam STATE_DS1d      = 4'd11;
localparam STATE_LAST      = 4'd11;

reg [3:0] t;

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
reg        cpu2_ram_req_state;
reg        vram_req_state;
reg        sp_req_state;
reg        sample_req_state;

localparam PORT_NONE     = 3'd0;
localparam PORT_CPU1_ROM = 3'd1;
localparam PORT_CPU1_RAM = 3'd2;
localparam PORT_CPU2_RAM = 3'd3;
localparam PORT_VRAM     = 3'd4;
localparam PORT_GFX1     = 3'd1;
localparam PORT_GFX2     = 3'd2;
localparam PORT_GFX3     = 3'd3;
localparam PORT_SAMPLE   = 3'd4;
localparam PORT_SP       = 3'd5;
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
	end else if (vram_req ^ vram_req_state) begin
		next_port[0] = PORT_VRAM;
		addr_latch_next[0] = { 2'b00, vram_addr };
		ds_next = 2'b11;
		{ oe_next, we_next } = 2'b10;
	end else if (/*cpu1_rom_addr != addr_last[PORT_CPU1_ROM] &&*/ cpu1_rom_cs && !cpu1_rom_valid) begin
		next_port[0] = PORT_CPU1_ROM;
		addr_latch_next[0] = { 4'd0, cpu1_rom_addr };
		ds_next = 2'b11;
		{ oe_next, we_next } = 2'b10;
	end else if (cpu1_ram_req ^ cpu1_ram_req_state) begin
		next_port[0] = PORT_CPU1_RAM;
		addr_latch_next[0] = { 2'b00, cpu1_ram_addr };
		ds_next = cpu1_ram_ds;
		{ oe_next, we_next } = { ~cpu1_ram_we, cpu1_ram_we };
		din_next = cpu1_ram_d;
	end else if (cpu2_ram_req ^ cpu2_ram_req_state) begin
		next_port[0] = PORT_CPU2_RAM;
		addr_latch_next[0] = { 2'b00, cpu2_ram_addr };
		ds_next = cpu2_ram_ds;
		{ oe_next, we_next } = { ~cpu2_ram_we, cpu2_ram_we };
		din_next = cpu2_ram_d;
	end
end

// PORT1: bank 2,3
always @(*) begin
	if (port2_req ^ port2_state) begin
		next_port[1] = PORT_REQ;
		addr_latch_next[1] = { 1'b1, port2_a };
	end else if (sp_req ^ sp_req_state) begin
		next_port[1] = PORT_SP;
		addr_latch_next[1] = { 1'b1, sp_addr };
	end else if (gfx1_req ^ gfx1_ack) begin
		next_port[1] = PORT_GFX1;
		addr_latch_next[1] = { 1'b1, gfx1_addr };
	end else if (gfx2_req ^ gfx2_ack) begin
		next_port[1] = PORT_GFX2;
		addr_latch_next[1] = { 1'b1, gfx2_addr };
	end else if (gfx3_req ^ gfx3_ack) begin
		next_port[1] = PORT_GFX3;
		addr_latch_next[1] = { 1'b1, gfx3_addr };
	end else if (sample_req ^ sample_req_state) begin
		next_port[1] = PORT_SAMPLE;
		addr_latch_next[1] = { 1'b1, sample_addr };
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
		cpu1_rom_valid <= 0;
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

		// RAS phase
		// bank 0,1
		if(t == STATE_RAS0) begin
			addr_latch[0] <= addr_latch_next[0];
			port[0] <= next_port[0];
			ds[0] <= ds_next;
			{ oe_latch[0], we_latch[0] } <= { oe_next, we_next };
			din_latch[0] <= din_next;

			if (next_port[0] != PORT_NONE) begin
				sd_cmd <= CMD_ACTIVE;
				SDRAM_A <= addr_latch_next[0][22:10];
				SDRAM_BA <= addr_latch_next[0][24:23];
			end

			if (next_port[0] == PORT_REQ) port1_state <= port1_req;
			if (next_port[0] == PORT_CPU1_RAM) cpu1_ram_req_state <= cpu1_ram_req;
			if (next_port[0] == PORT_CPU2_RAM) cpu2_ram_req_state <= cpu2_ram_req;
			if (next_port[0] == PORT_VRAM) vram_req_state <= vram_req;
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
			if (next_port[1] == PORT_SP) sp_req_state <= sp_req;
			if (next_port[1] == PORT_SAMPLE) sample_req_state <= sample_req;

			if (next_port[1] == PORT_NONE && need_refresh && !we_latch[0] && !oe_latch[0]) begin
				refresh <= 1'b1;
				refresh_cnt <= 0;
				sd_cmd <= CMD_AUTO_REFRESH;
			end
		end

		// CAS phase
		if(t == STATE_CAS0 && (we_latch[0] || oe_latch[0])) begin
			sd_cmd <= we_latch[0]?CMD_WRITE:CMD_READ;
			if (we_latch[0]) begin
				{ SDRAM_DQMH, SDRAM_DQML } <= ~ds[0];
				SDRAM_DQ <= din_latch[0];
				case(port[0])
					PORT_REQ: port1_ack <= port1_req;
					PORT_CPU1_RAM: cpu1_ram_ack <= cpu1_ram_req;
					PORT_CPU2_RAM: cpu2_ram_ack <= cpu2_ram_req;
					default: ;
				endcase;
			end
			SDRAM_A <= { 4'b0010, addr_latch[0][9:1] };  // auto precharge
			SDRAM_BA <= addr_latch[0][24:23];
		end

		if(t == STATE_CAS1 && (we_latch[1] || oe_latch[1])) begin
			sd_cmd <= we_latch[1]?CMD_WRITE:CMD_READ;
			if (we_latch[1]) begin
				{ SDRAM_DQMH, SDRAM_DQML } <= ~ds[1];
				SDRAM_DQ <= din_latch[1];
				port2_ack <= port2_req;
			end
			SDRAM_A <= { 4'b0010, addr_latch[1][9:1] };  // auto precharge
			SDRAM_BA <= addr_latch[1][24:23];
		end

		if(t == STATE_DS0 && oe_latch[0]) { SDRAM_DQMH, SDRAM_DQML } <= 0;
		if(t == STATE_DS0b && oe_latch[0] && !we_latch[1]) { SDRAM_DQMH, SDRAM_DQML } <= 0;

		// Data returned
		if(t == STATE_READ0 && oe_latch[0]) begin
			case(port[0])
				PORT_REQ:  begin port1_q <= sd_din; port1_ack <= port1_req; end
				PORT_CPU1_ROM: begin cpu1_rom_q <= sd_din; cpu1_rom_valid <= 1; end
				PORT_CPU1_RAM: begin cpu1_ram_q <= sd_din; cpu1_ram_ack <= cpu1_ram_req; end
				PORT_CPU2_RAM: begin cpu2_ram_q <= sd_din; cpu2_ram_ack <= cpu2_ram_req; end
				PORT_VRAM: vram_q[15:0] <= sd_din;
				default: ;
			endcase;
		end
		if(t == STATE_READ0b && oe_latch[0]) begin
			case(port[0])
				PORT_VRAM: begin vram_q[31:16] <= sd_din; vram_ack <= vram_req; end
				default: ;
			endcase;
		end

		if(t == STATE_DS1a && oe_latch[1]) { SDRAM_DQMH, SDRAM_DQML } <= 0;
		if(t == STATE_DS1b && oe_latch[1]) { SDRAM_DQMH, SDRAM_DQML } <= 0;
		if(t == STATE_DS1c && oe_latch[1]) { SDRAM_DQMH, SDRAM_DQML } <= 0;
		if(t == STATE_DS1d && oe_latch[1]) { SDRAM_DQMH, SDRAM_DQML } <= 0;

		if(t == STATE_READ1 && oe_latch[1]) begin
			case(port[1])
				PORT_REQ  : port2_q[15:0] <= sd_din;
				PORT_GFX1 :  gfx1_q[15:0] <= sd_din;
				PORT_GFX2 :  gfx2_q[15:0] <= sd_din;
				PORT_GFX3 :  gfx3_q[15:0] <= sd_din;
				PORT_SAMPLE: sample_q[15:0] <= sd_din;
				PORT_SP   :    sp_q[15:0] <= sd_din;
				default: ;
			endcase;
		end

		if(t == STATE_READ1b && oe_latch[1]) begin
			case(port[1])
				PORT_REQ  : begin port2_q[31:16] <= sd_din; port2_ack <= port2_req; end
				PORT_GFX1 : begin  gfx1_q[31:16] <= sd_din; gfx1_ack <= gfx1_req; end
				PORT_GFX2 : begin  gfx2_q[31:16] <= sd_din; gfx2_ack <= gfx2_req; end
				PORT_GFX3 : begin  gfx3_q[31:16] <= sd_din; gfx3_ack <= gfx3_req; end
				PORT_SAMPLE:     sample_q[31:16] <= sd_din;
				PORT_SP   :          sp_q[31:16] <= sd_din;
				default: ;
			endcase;
		end
		if(t == STATE_READ1c && oe_latch[1]) begin
			case(port[1])
				PORT_SAMPLE: sample_q[47:32] <= sd_din;
				PORT_SP:         sp_q[47:32] <= sd_din;
				default: ;
			endcase;
		end
		if(t == STATE_READ1d && oe_latch[1]) begin
			case(port[1])
				PORT_SAMPLE: begin sample_q[63:48] <= sd_din; sample_ack <= sample_req; end
				PORT_SP:     begin     sp_q[63:48] <= sd_din; sp_ack <= sp_req; end
				default: ;
			endcase;
		end
	end
end

endmodule
