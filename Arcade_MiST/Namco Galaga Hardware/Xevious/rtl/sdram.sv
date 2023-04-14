//
// sdram.v
//
// sdram controller implementation for the MiST board
// https://github.com/mist-devel/mist-board
// 
// Copyright (c) 2013 Till Harbaum <till@harbaum.org> 
// Copyright (c) 2019 Gyorgy Szombathelyi
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

	input      [15:1] cpu1_addr,
	output reg [15:0] cpu1_q,
	input      [15:1] cpu2_addr,
	output reg [15:0] cpu2_q,
	input      [15:1] cpu3_addr,
	output reg [15:0] cpu3_q,
	input      [16:1] fg_addr,
	output reg [15:0] fg_q,
	input      [16:1] bg0_addr,
	output reg [15:0] bg0_q,
	input      [16:1] bg1_addr,
	output reg [15:0] bg1_q,

	input             port1_req,
	output reg        port1_ack,
	input             port1_we,
	input      [23:1] port1_a,
	input       [1:0] port1_ds,
	input      [15:0] port1_d,
	output     [15:0] port1_q,

	input      [16:1] sp1_addr,
	output reg [15:0] sp1_q,
	input      [16:1] sp2_addr,
	output reg [15:0] sp2_q,

	input             port2_req,
	output reg        port2_ack,
	input             port2_we,
	input      [23:1] port2_a,
	input       [1:0] port2_ds,
	input      [15:0] port2_d,
	output     [15:0] port2_q
);

parameter MHZ = 80; // 80 MHz default clock, adjust to calculate the refresh rate correctly

localparam RASCAS_DELAY   = 3'd2;   // tRCD=20ns -> 2 cycles@<100MHz
localparam BURST_LENGTH   = 3'b000; // 000=1, 001=2, 010=4, 011=8
localparam ACCESS_TYPE    = 1'b0;   // 0=sequential, 1=interleaved
localparam CAS_LATENCY    = 3'd2;   // 2/3 allowed
localparam OP_MODE        = 2'b00;  // only 00 (standard operation) allowed
localparam NO_WRITE_BURST = 1'b1;   // 0= write burst enabled, 1=only single access write

localparam MODE = { 3'b000, NO_WRITE_BURST, OP_MODE, CAS_LATENCY, ACCESS_TYPE, BURST_LENGTH}; 

// 64ms/8192 rows = 7.8us
localparam RFRSH_CYCLES = 16'd78*MHZ/10;

// ---------------------------------------------------------------------
// ------------------------ cycle state machine ------------------------
// ---------------------------------------------------------------------

/*
 SDRAM state machine for 2 bank interleaved access
 1 word burst, CL2
cmd issued  registered
 0 RAS0     cas1
 1          ras0
 2 CAS0     data1 returned
 3 RAS1     cas0
 4          ras1
 5 CAS1     data0 returned
*/

localparam STATE_RAS0      = 3'd0;   // first state in cycle
localparam STATE_RAS1      = 3'd3;   // Second ACTIVE command after RAS0 + tRRD (15ns)
localparam STATE_CAS0      = STATE_RAS0 + RASCAS_DELAY; // CAS phase - 3
localparam STATE_CAS1      = STATE_RAS1 + RASCAS_DELAY; // CAS phase - 5
localparam STATE_READ0     = 3'd0; //STATE_CAS0 + CAS_LATENCY + 1'd1; // 7
localparam STATE_READ1     = 3'd3;
localparam STATE_LAST      = 3'd5;

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

reg  [3:0] sd_cmd;   // current command sent to sd ram
reg [15:0] sd_din;
// drive control signals according to current command
assign SDRAM_nCS  = sd_cmd[3];
assign SDRAM_nRAS = sd_cmd[2];
assign SDRAM_nCAS = sd_cmd[1];
assign SDRAM_nWE  = sd_cmd[0];

reg [24:1] addr_latch[2];
reg [24:1] addr_latch_next[2];
reg [16:1] addr_last[7];
reg [16:1] addr_last2[7];
reg [15:0] din_latch[2];
reg  [1:0] oe_latch;
reg  [1:0] we_latch;
reg  [1:0] ds[2];

localparam PORT_NONE  = 3'd0;
localparam PORT_CPU1  = 3'd1;
localparam PORT_CPU2  = 3'd2;
localparam PORT_CPU3  = 3'd3;
localparam PORT_FG    = 3'd4;
localparam PORT_BG0   = 3'd5;
localparam PORT_BG1   = 3'd6;
localparam PORT_REQ   = 3'd7;

localparam PORT_SP1   = 3'd1;
localparam PORT_SP2   = 3'd2;

reg  [2:0] next_port[2];
reg  [2:0] port[2];

reg        refresh;
reg [10:0] refresh_cnt;
wire       need_refresh = (refresh_cnt >= RFRSH_CYCLES);

// PORT1: bank 0,1
always @(*) begin
	if (refresh) begin
		next_port[0] = PORT_NONE;
		addr_latch_next[0] = addr_latch[0];
	end else if (port1_req ^ port1_ack) begin
		next_port[0] = PORT_REQ;
		addr_latch_next[0] = { 1'b0, port1_a };
	end else if ({1'b0, cpu1_addr} != addr_last[PORT_CPU1]) begin
		next_port[0] = PORT_CPU1;
		addr_latch_next[0] = { 9'd0, cpu1_addr };
	end else if ({1'b0, cpu2_addr} != addr_last[PORT_CPU2]) begin
		next_port[0] = PORT_CPU2;
		addr_latch_next[0] = { 9'd0, cpu2_addr };
	end else if ({1'b0, cpu3_addr} != addr_last[PORT_CPU3]) begin
		next_port[0] = PORT_CPU3;
		addr_latch_next[0] = { 9'd0, cpu3_addr };
	end else if (fg_addr != addr_last[PORT_FG]) begin
		next_port[0] = PORT_FG;
		addr_latch_next[0] = { 8'd0, fg_addr };
	end else if (bg0_addr != addr_last[PORT_BG0]) begin
		next_port[0] = PORT_BG0;
		addr_latch_next[0] = { 8'd0, bg0_addr };
	end else if (bg1_addr != addr_last[PORT_BG1]) begin
		next_port[0] = PORT_BG1;
		addr_latch_next[0] = { 8'd0, bg1_addr };
	end else begin
		next_port[0] = PORT_NONE;
		addr_latch_next[0] = addr_latch[0];
	end
end

// PORT2: bank 2,3
always @(*) begin
	if (port2_req ^ port2_ack) begin
		next_port[1] = PORT_REQ;
		addr_latch_next[1] = { 1'b1, port2_a };
	end else if (sp1_addr != addr_last2[PORT_SP1]) begin
		next_port[1] = PORT_SP1;
		addr_latch_next[1] = { 1'b1, 7'd0, sp1_addr };
	end else if (sp2_addr != addr_last2[PORT_SP2]) begin
		next_port[1] = PORT_SP2;
		addr_latch_next[1] = { 1'b1, 7'd0, sp2_addr };
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
				addr_last[next_port[0]] <= addr_latch_next[0][16:1];
				if (next_port[0] == PORT_REQ) begin
					{ oe_latch[0], we_latch[0] } <= { ~port1_we, port1_we };
					ds[0] <= port1_ds;
					din_latch[0] <= port1_d;
				end else begin
					{ oe_latch[0], we_latch[0] } <= 2'b10;
					ds[0] <= 2'b11;
				end
			end
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
				addr_last2[next_port[1]] <= addr_latch_next[1][16:1];
				if (next_port[1] == PORT_REQ) begin
					{ oe_latch[1], we_latch[1] } <= { ~port2_we, port2_we };
					ds[1] <= port2_ds;
					din_latch[1] <= port2_d;
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
				port1_ack <= port1_req;
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
				PORT_CPU1: begin cpu1_q  <= sd_din; end
				PORT_CPU2: begin cpu2_q  <= sd_din; end
				PORT_CPU3: begin cpu3_q  <= sd_din; end
				PORT_FG:   begin fg_q    <= sd_din; end
				PORT_BG0:  begin bg0_q   <= sd_din; end
				PORT_BG1:  begin bg1_q   <= sd_din; end
				default: ;
			endcase;
		end
		if(t == STATE_READ1 && oe_latch[1]) begin
			case(port[1])
				PORT_REQ:  begin port2_q <= sd_din; port2_ack <= port2_req; end
				PORT_SP1:  begin sp1_q   <= sd_din; end
				PORT_SP2:  begin sp2_q   <= sd_din; end
				default: ;
			endcase;
		end
	end
end

endmodule
