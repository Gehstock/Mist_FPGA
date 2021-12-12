//
// sdram.v
//
// Static RAM controller implementation using SDRAM MT48LC16M16A2
//
// Copyright (c) 2015-2019 Sorgelig
//
// Some parts of SDRAM code used from project:
// http://hamsterworks.co.nz/mediawiki/index.php/Simple_SDRAM_Controller
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
// ------------------------------------------
//
// v2.1 - Add universal 8/16 bit mode.
//

module sdram
(
   input             init,        // reset to initialize RAM
   input             clk,         // clock ~100MHz
                                  //
                                  // SDRAM_* - signals to the MT48LC16M16 chip
   inout  reg [15:0] SDRAM_DQ,    // 16 bit bidirectional data bus
   output reg [12:0] SDRAM_A,     // 13 bit multiplexed address bus
   output reg        SDRAM_DQML,  // two byte masks
   output reg        SDRAM_DQMH,  // 
   output reg  [1:0] SDRAM_BA,    // two banks
   output            SDRAM_nCS,   // a single chip select
   output            SDRAM_nWE,   // write enable
   output            SDRAM_nRAS,  // row address select
   output            SDRAM_nCAS,  // columns address select
   output            SDRAM_CKE,   // clock enable
                                  //
   input      [24:0] addr,        // 25 bit address for 8bit mode. addr[0] = 0 for 16bit mode for correct operations.
   output     [15:0] dout,        // data output to cpu
   input       [7:0] din,         // data input from cpu
   input             we,          // cpu requests write
   input             rd,          // cpu requests read
   output reg        ready        // dout is valid. Ready to accept new read/write.
);

assign SDRAM_CKE  = 1;
assign SDRAM_nCS  = 0;
assign SDRAM_nRAS = command[2];
assign SDRAM_nCAS = command[1];
assign SDRAM_nWE  = command[0];
assign {SDRAM_DQMH,SDRAM_DQML} = SDRAM_A[12:11];


// no burst configured
localparam BURST_LENGTH        = 3'b000;   // 000=1, 001=2, 010=4, 011=8
localparam ACCESS_TYPE         = 1'b0;     // 0=sequential, 1=interleaved
localparam CAS_LATENCY         = 3'd2;     // 2 for < 100MHz, 3 for >100MHz
localparam OP_MODE             = 2'b00;    // only 00 (standard operation) allowed
localparam NO_WRITE_BURST      = 1'b1;     // 0= write burst enabled, 1=only single access write
localparam MODE                = {3'b000, NO_WRITE_BURST, OP_MODE, CAS_LATENCY, ACCESS_TYPE, BURST_LENGTH};

localparam sdram_startup_cycles= 14'd12100;// 100us, plus a little more, @ 100MHz
localparam cycles_per_refresh  = 14'd780;  // (64000*100)/8192-1 Calc'd as (64ms @ 100MHz)/8192 rose
localparam startup_refresh_max = 14'b11111111111111;

// SDRAM commands
wire [2:0] CMD_NOP             = 3'b111;
wire [2:0] CMD_ACTIVE          = 3'b011;
wire [2:0] CMD_READ            = 3'b101;
wire [2:0] CMD_WRITE           = 3'b100;
wire [2:0] CMD_PRECHARGE       = 3'b010;
wire [2:0] CMD_AUTO_REFRESH    = 3'b001;
wire [2:0] CMD_LOAD_MODE       = 3'b000;

reg [13:0] refresh_count = startup_refresh_max - sdram_startup_cycles;
reg  [2:0] command;
reg [24:0] save_addr;

reg [15:0] data;
assign dout = data;

typedef enum
{
	STATE_STARTUP,
	STATE_OPEN_1, STATE_OPEN_2,
	STATE_IDLE,	  STATE_IDLE_1, STATE_IDLE_2, STATE_IDLE_3,
	STATE_IDLE_4, STATE_IDLE_5, STATE_IDLE_6, STATE_IDLE_7
} state_t;

always @(posedge clk) begin
	reg old_we, old_rd;
	reg [CAS_LATENCY:0] data_ready_delay;

	reg  [7:0] new_data;
	reg        new_we;
	reg        new_rd;
	reg        save_we = 1;

	state_t state = STATE_STARTUP;

	SDRAM_DQ <= 16'bZ;
	command  <= CMD_NOP;
	refresh_count  <= refresh_count+1'b1;

	data_ready_delay <= {1'b0, data_ready_delay[CAS_LATENCY:1]};

	if(data_ready_delay[0]) {ready, data}  <= {1'b1, SDRAM_DQ};

	case(state)
		STATE_STARTUP: begin
			SDRAM_A    <= 0;
			SDRAM_BA   <= 0;

			if (refresh_count == startup_refresh_max-31) begin
				command     <= CMD_PRECHARGE;
				SDRAM_A[10] <= 1;  // all banks
				SDRAM_BA    <= 2'b00;
			end
			if (refresh_count == startup_refresh_max-23) begin
				command     <= CMD_AUTO_REFRESH;
			end
			if (refresh_count == startup_refresh_max-15) begin
				command     <= CMD_AUTO_REFRESH;
			end
			if (refresh_count == startup_refresh_max-7) begin
				command     <= CMD_LOAD_MODE;
				SDRAM_A     <= MODE;
			end

			if(!refresh_count) begin
				state   <= STATE_IDLE;
				ready   <= 1;
				refresh_count <= 0;
			end
		end

		STATE_IDLE_7: state <= STATE_IDLE_6;
		STATE_IDLE_6: state <= STATE_IDLE_5;
		STATE_IDLE_5: state <= STATE_IDLE_4;
		STATE_IDLE_4: state <= STATE_IDLE_3;
		STATE_IDLE_3: state <= STATE_IDLE_2;
		STATE_IDLE_2: state <= STATE_IDLE_1;
		STATE_IDLE_1: begin
			state      <= STATE_IDLE;
			// mask possible refresh to reduce colliding.
			if(refresh_count > cycles_per_refresh) begin
				state    <= STATE_IDLE_7;
				command  <= CMD_AUTO_REFRESH;
				refresh_count <= 0;
			end
		end

		STATE_IDLE: begin
			// Priority is to issue a refresh if one is outstanding
			if(refresh_count > (cycles_per_refresh<<1)) state <= STATE_IDLE_1;
			else if(new_rd | new_we) begin
				new_we   <= 0;
				new_rd   <= 0;
				save_addr<= addr;
				save_we  <= new_we;
				state    <= STATE_OPEN_1;
				command  <= CMD_ACTIVE;
				SDRAM_A  <= addr[13:1];
				SDRAM_BA <= addr[24:23];
			end
		end

		STATE_OPEN_1: state <= STATE_OPEN_2;

		STATE_OPEN_2: begin
			SDRAM_A     <= {save_we & ~save_addr[0], save_we & save_addr[0], 2'b10, save_addr[22:14]};
			if(save_we) begin
				command  <= CMD_WRITE;
				SDRAM_DQ <= {new_data[7:0], new_data[7:0]};
				ready    <= 1;
				state    <= STATE_IDLE_2;
			end
			else begin
				command  <= CMD_READ;
				data_ready_delay[CAS_LATENCY] <= 1;
				state    <= STATE_IDLE_5;
			end
		end
	endcase

	if(init) begin
		state <= STATE_STARTUP;
		refresh_count <= startup_refresh_max - sdram_startup_cycles;
	end

	old_we <= we;
	if(we & ~old_we) {ready, new_we, new_data} <= {1'b0, 1'b1, din};

	old_rd <= rd;
	if(rd & ~old_rd) begin
		if(ready & ~save_we & (save_addr[24:1] == addr[24:1])) save_addr <= addr;
			else {ready, new_rd} <= {1'b0, 1'b1};
	end
end

endmodule
