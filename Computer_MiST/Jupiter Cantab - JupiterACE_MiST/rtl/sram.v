//
// sram.v
//
// Static RAM controller implementation using SDRAM MT48LC16M16A2
// 
// Copyright (c) 2015 Sorgelig
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

module sram (

	// interface to the MT48LC16M16 chip
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

	// cpu/chipset interface
	input             init,        // reset to initialize RAM
	input             clk_sdram,		
	
	input      [24:0] addr,        // 25 bit address

	output reg  [7:0] dout,	       // data output to cpu
	input       [7:0] din,         // data input from cpu
	input             we,          // cpu requests write
	input             rd,          // cpu requests read
	output reg        ready
);

assign SDRAM_nCS  = command[3];
assign SDRAM_nRAS = command[2];
assign SDRAM_nCAS = command[1];
assign SDRAM_nWE  = command[0];
assign SDRAM_CKE  = cke;


// no burst configured
localparam BURST_LENGTH   = 3'b000; // 000=1, 001=2, 010=4, 011=8
localparam ACCESS_TYPE    = 1'b0;   // 0=sequential, 1=interleaved
localparam CAS_LATENCY    = 3'd3;   // 2 for < 100MHz, 3 for >100MHz
localparam OP_MODE        = 2'b00;  // only 00 (standard operation) allowed
localparam NO_WRITE_BURST = 1'b1;   // 0= write burst enabled, 1=only single access write

localparam MODE = { 3'b000, NO_WRITE_BURST, OP_MODE, CAS_LATENCY, ACCESS_TYPE, BURST_LENGTH}; 

parameter sdram_startup_cycles    = 14'd10100; // -- 100us, plus a little more, @ 100MHz
parameter cycles_per_refresh      = 14'd1524;  // (64000*100)/4196-1 Calc'd as  (64ms @ 100MHz)/ 4196 rose
parameter startup_refresh_max     = 14'b11111111111111;

reg  [13:0] startup_refresh_count = startup_refresh_max-sdram_startup_cycles;
wire        pending_refresh       = |startup_refresh_count[13:11];
wire        forcing_refresh       = |startup_refresh_count[13:12];

localparam STATE_STARTUP  = 0;
localparam STATE_OPEN_1   = 1;
localparam STATE_OPEN_2   = 2;
localparam STATE_WRITE    = 3;
localparam STATE_READ     = 4;
localparam STATE_IDLE     = 5;
localparam STATE_IDLE_1   = 6;
localparam STATE_IDLE_2   = 7;
localparam STATE_IDLE_3   = 8;
localparam STATE_IDLE_4   = 9;
localparam STATE_IDLE_5   = 10;
localparam STATE_IDLE_6   = 11;
localparam STATE_IDLE_7   = 12;
localparam STATE_IDLE_8   = 13;

// SDRAM commands
localparam CMD_INHIBIT         = 4'b1111;
localparam CMD_NOP             = 4'b0111;
localparam CMD_ACTIVE          = 4'b0011;
localparam CMD_READ            = 4'b0101;
localparam CMD_WRITE           = 4'b0100;
localparam CMD_BURST_TERMINATE = 4'b0110;
localparam CMD_PRECHARGE       = 4'b0010;
localparam CMD_AUTO_REFRESH    = 4'b0001;
localparam CMD_LOAD_MODE       = 4'b0000;

reg [4:0] state = STATE_STARTUP;
reg [3:0] command = CMD_INHIBIT;
reg       cke = 0;

parameter data_ready_delay_high = CAS_LATENCY+1;
reg [data_ready_delay_high:0] data_ready_delay;

always @(posedge clk_sdram) begin
	reg old_we, old_rd, new_we, new_rd;

	reg  [7:0] new_data;
	reg [24:0] save_addr;
	reg        save_we;
	reg        save_addr0;
	reg        avail;

	command <= CMD_NOP;

	startup_refresh_count  <= startup_refresh_count+1'b1;

   if(data_ready_delay[0]) begin
		dout  <= save_addr0 ? SDRAM_DQ[15:8] : SDRAM_DQ[7:0];
		avail <= 1;
		ready <= 1;
   end

   data_ready_delay <= {1'b0, data_ready_delay[data_ready_delay_high:1]};

	case(state) 
		STATE_STARTUP: begin
			//------------------------------------------------------------------------
			//-- This is the initial startup state, where we wait for at least 100us
			//-- before starting the start sequence
			//-- 
			//-- The initialisation is sequence is 
			//--  * de-assert SDRAM_CKE
			//--  * 100us wait, 
			//--  * assert SDRAM_CKE
			//--  * wait at least one cycle, 
			//--  * PRECHARGE
			//--  * wait 2 cycles
			//--  * REFRESH, 
			//--  * tREF wait
			//--  * REFRESH, 
			//--  * tREF wait 
			//--  * LOAD_MODE_REG 
			//--  * 2 cycles wait
			//------------------------------------------------------------------------
			cke        <= 1;
			SDRAM_DQ   <= 16'bZZZZZZZZZZZZZZZZ;
			SDRAM_DQML <= 1;
			SDRAM_DQMH <= 1;
			SDRAM_A    <= 0;
			SDRAM_BA   <= 0;

			// All the commands during the startup are NOPS, except these
			if(startup_refresh_count == startup_refresh_max-31) begin
				// ensure all rows are closed
				command     <= CMD_PRECHARGE;
				SDRAM_A[10] <= 1;  // all banks
				SDRAM_BA    <= 2'b00;
			end else if (startup_refresh_count == startup_refresh_max-23) begin
				// these refreshes need to be at least tREF (66ns) apart
				command     <= CMD_AUTO_REFRESH;
			end else if (startup_refresh_count == startup_refresh_max-15) 
				command     <= CMD_AUTO_REFRESH;
			else if (startup_refresh_count == startup_refresh_max-7) begin
				// Now load the mode register
				command     <= CMD_LOAD_MODE;
				SDRAM_A     <= MODE;
			end

			//------------------------------------------------------
			//-- if startup is complete then go into idle mode,
			//-- get prepared to accept a new command, and schedule
			//-- the first refresh cycle
			//------------------------------------------------------
			if(!startup_refresh_count) begin
				state   <= STATE_IDLE;
				avail   <= 1;
				ready   <= 1;
				startup_refresh_count <= 14'd2048 - cycles_per_refresh + 1'd1;
			end
		end

		STATE_IDLE_8: state <= STATE_IDLE_7;
		STATE_IDLE_7: state <= STATE_IDLE_6;
		STATE_IDLE_6: state <= STATE_IDLE_5;
		STATE_IDLE_5: state <= STATE_IDLE_4;
		STATE_IDLE_4: state <= STATE_IDLE_3;
		STATE_IDLE_3: state <= STATE_IDLE_2;
		STATE_IDLE_2: state <= STATE_IDLE_1;
		STATE_IDLE_1: begin
			SDRAM_DQ   <= 16'bZZZZZZZZZZZZZZZZ;
			state      <= STATE_IDLE;
			if(pending_refresh) begin
            //------------------------------------------------------------------------
            //-- Start the refresh cycle. 
            //-- This tasks tRFC (66ns), so 6 idle cycles are needed @ 100MHz
            //------------------------------------------------------------------------
				state    <= STATE_IDLE_8;
				command  <= CMD_AUTO_REFRESH;
				startup_refresh_count <= startup_refresh_count - cycles_per_refresh + 1'd1;
			end
		end

		STATE_IDLE: begin
			// Priority is to issue a refresh if one is outstanding
			if(forcing_refresh) state <= STATE_IDLE_1;
			else if(avail & (new_rd | new_we)) begin
				save_addr<= addr;
				save_we  <= new_we;
				avail    <= 0;
				new_we   <= 0;
				new_rd   <= 0;
				state    <= STATE_OPEN_1;
				command  <= CMD_ACTIVE;
				SDRAM_A  <= addr[22:10];
				SDRAM_BA <= addr[24:23];
			end

			SDRAM_DQML  <= 1;
			SDRAM_DQMH  <= 1;
		end

		//--------------------------------------------
		//-- Opening the row ready for reads or writes
		//--------------------------------------------
		// ACTIVE-to-READ or WRITE delay >20ns (-75)
		STATE_OPEN_1: state <= STATE_OPEN_2;
		STATE_OPEN_2: begin
			SDRAM_A     <= {4'b0010, save_addr[9:1]}; 
			SDRAM_DQML  <= save_addr[0];
			SDRAM_DQMH  <= ~save_addr[0];
			state       <= (save_we) ? STATE_WRITE : STATE_READ;
		end

		//----------------------------------
		//-- Processing the read transaction
		//----------------------------------
		STATE_READ: begin
			state       <= STATE_IDLE_5;
			command     <= CMD_READ;
			SDRAM_DQ    <= 16'bZZZZZZZZZZZZZZZZ;

			// Schedule reading the data values off the bus
			data_ready_delay[data_ready_delay_high] <= 1;
			save_addr0  <= save_addr[0];
		end

		//------------------------------------------------------------------
		// -- Processing the write transaction
		//-------------------------------------------------------------------
		STATE_WRITE: begin
			state       <= STATE_IDLE_5;
			command     <= CMD_WRITE;
			SDRAM_DQ    <= {new_data, new_data};
			avail       <= 1;
			ready       <= 1;
		end

		//-------------------------------------------------------------------
		//-- We should never get here, but if we do then reset the memory
		//-------------------------------------------------------------------
		default: begin
			state       <= STATE_STARTUP;
			avail       <= 0;
			startup_refresh_count <= startup_refresh_max-sdram_startup_cycles;
		end
	endcase

	if(init) begin  // Sync reset
		state <= STATE_STARTUP;
		avail <= 0;
		startup_refresh_count <= startup_refresh_max-sdram_startup_cycles;
	end

	old_we <= we;
	if(we & ~old_we) {ready, new_we, new_data} <= {1'b0, 1'b1, din};

	old_rd <= rd;
	if(rd & ~old_rd) {ready, new_rd} <= {1'b0, 1'b1};
end

endmodule
