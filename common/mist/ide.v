// Copyright 2008, 2009 by Jakub Bednarski
//
// Extracted from Minimig gayle.v
//
// Minimig is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// (at your option) any later version.
//
// Minimig is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//
//
// -- JB --
//
// 2008-10-06	- initial version
// 2008-10-08	- interrupt controller implemented, kickstart boots
// 2008-10-09	- working identify device command implemented (hdtoolbox detects our drive)
//				- read command reads data from hardfile (fixed size and name, only one sector read size supported, workbench sees hardfile partition)
// 2008-10-10	- multiple sector transfer supported: works ok, sequential transfers with direct spi read and 28MHz CPU from 400 to 520 KB/s
//				- arm firmare seekfile function very slow: seeking from start to 20MB takes 144 ms (some software improvements required)
// 2008-10-30	- write support added
// 2008-12-31	- added hdd enable
// 2009-05-24	- clean-up & renaming
// 2009-08-11	- hdd_ena enables Master & Slave drives
// 2009-11-18	- changed sector buffer size
// 2010-04-13	- changed sector buffer size
// 2010-08-10	- improved BSY signal handling
// 2022-08-18	- added packet command handling

module ide
(
	input          clk,
	input          clk_en,
	input          reset,
	input    [2:0] address_in,
	input          sel_secondary,
	input   [15:0] data_in,
	output  [15:0] data_out,
	output         data_oe,
	input          rd,
	input          hwr,
	input          lwr,
	input          sel_ide,
	output reg [1:0] intreq,
	input    [1:0] intreq_ack,  // interrupt clear
	output         nrdy,				// fifo is not ready for reading 
	input    [1:0] hdd0_ena,		// enables Master & Slave drives on primary channel
	input    [1:0] hdd1_ena,		// enables Master & Slave drives on secondary channel
	output         fifo_rd,
	output         fifo_wr,

	// connection to the IO-Controller
	output         hdd_cmd_req,
	output         hdd_dat_req,
	input    [2:0] hdd_addr,
	input   [15:0] hdd_data_out,
	output  [15:0] hdd_data_in,
	input          hdd_wr,
	input          hdd_status_wr,
	input          hdd_data_wr,
	input          hdd_data_rd
);

localparam VCC = 1'b1;
localparam GND = 1'b0;

/*
0 Data
1 Error | Feature
2 SectorCount
3 SectorNumber
4 CylinderLow
5 CylinderHigh
6 Device/Head
7 Status | Command

command class:
PI (PIO In)
PO (PIO Out)
ND (No Data)

Status:
#6 - DRDY	- Drive Ready
#7 - BSY	- Busy
#3 - DRQ	- Data Request
#0 - ERR	- Error
INTRQ	- Interrupt Request

*/
 

// address decoding signals
wire 	sel_tfr;    // HDD task file registers select
wire 	sel_fifo;   // HDD data port select (FIFO buffer)
wire 	sel_status /* synthesis keep */; // HDD status register select
wire 	sel_command /* synthesis keep */;// HDD command register select

// internal registers
reg		block_mark; // IDE multiple block start flag
reg		busy;       // busy status (command processing state)
reg		pio_in;     // pio in command type is being processed
reg		pio_out;    // pio out command type is being processed
reg		error;      // error status (command processing failed)

reg   [1:0] dev;  // drive select (Primary/Secondary, Master/Slave)
wire 	bsy;        // busy
wire 	drdy;       // drive ready
wire 	drq;        // data request
reg  	drq_d;      // data request
wire 	err;        // error
wire 	[7:0] status;	// HDD status

// FIFO control
wire	fifo_reset;
wire	[15:0] fifo_data_in;
wire	[15:0] fifo_data_out;
wire 	fifo_full;
wire 	fifo_empty;
wire	fifo_last_out; // last word of a sector is being read
wire	fifo_last_in;  // last word of a sector is being written


// HDD status register
assign status = {bsy,drdy,2'b01,drq,2'b00,err};

// packet states
reg  [1:0] packet_state;
localparam PACKET_IDLE       = 0;
localparam PACKET_WAITCMD    = 1;
localparam PACKET_PROCESSCMD = 2;
wire       packet_state_change;
reg [12:0] packet_count;
wire       packet_in_last;
wire       packet_in;
wire       packet_out;

`ifdef IDE_DEBUG
// cmd/status debug
reg [7:0] status_dbg  /* synthesis noprune */;
reg [7:0] dbg_ide_cmd /* synthesis noprune */;
reg [2:0] dbg_addr /* synthesis noprune */;
reg       dbg_wr /* synthesis noprune */;
reg[15:0] dbg_data_in /* synthesis noprune */;
reg[15:0] dbg_data_out /* synthesis noprune */;

always @(posedge clk) begin
	status_dbg <= status;
	if (clk_en) begin
		dbg_wr <= 0;
		if (sel_command) // set when the CPU writes command register
			dbg_ide_cmd <= data_in[15:8];
		if (sel_ide) begin
			dbg_addr <= address_in;
			dbg_wr <= hwr | lwr;
			if (rd) dbg_data_out <= data_out;
			if (hwr | lwr) dbg_data_in <= data_in;
		end
	end
end
`endif

// HDD status register bits
assign bsy = busy & ~drq;
assign drdy = ~(bsy|drq);
assign err = error;

// address decoding
assign sel_tfr = sel_ide;
assign sel_status = rd && sel_tfr && address_in==3'b111 ? VCC : GND;
assign sel_command = hwr && sel_tfr && address_in==3'b111 ? VCC : GND;
assign sel_fifo = sel_tfr && address_in==3'b000 ? VCC : GND;

//===============================================================================================//

// task file registers
reg   [7:0] tfr [7:0];
wire  [2:0] tfr_sel;
wire  [7:0] tfr_in;
wire  [7:0] tfr_out;
wire        tfr_we;

reg   [8:0] sector_count;         // sector counter
wire        sector_count_dec_in;  // decrease sector counter (reads)
wire        sector_count_dec_out; // decrease sector counter (writes)

always @(posedge clk)
	if (clk_en) begin
		if (hwr && sel_tfr && address_in == 3'b010) begin // sector count register loaded by the host
			sector_count <= {1'b0, data_in[15:8]};
			if (data_in[15:8] == 0) sector_count <= 9'd256;
		end else if (sector_count_dec_in || sector_count_dec_out)
			sector_count <= sector_count - 8'd1;
	end

reg rd_old;
reg wr_old;
reg sel_fifo_old;
always @(posedge clk)
	if (clk_en) begin
		rd_old <= rd;
		wr_old <= hwr & lwr;
		sel_fifo_old <= sel_fifo;
	end

assign sector_count_dec_in  = pio_in & fifo_last_out & sel_fifo_old & ~rd & rd_old & packet_state == PACKET_IDLE;
assign sector_count_dec_out = pio_out & fifo_last_in & sel_fifo_old & ~hwr & ~lwr & wr_old & packet_state == PACKET_IDLE;

// task file register control
assign tfr_we =  packet_in_last ? 1'b1 : bsy ? hdd_wr : sel_tfr & hwr;
assign tfr_sel = packet_in_last ? 3'd2 : bsy ? hdd_addr : address_in;
assign tfr_in =  packet_in_last ? 8'h03: bsy ? hdd_data_out[7:0] : data_in[15:8];

// input multiplexer for SPI host
assign hdd_data_in = tfr_sel==0 ? fifo_data_out : {7'h0, dev[1], tfr_out};

// task file registers
always @(posedge clk)
	if (clk_en) begin
		if (tfr_we)
			tfr[tfr_sel] <= tfr_in;
	end

assign tfr_out = tfr[tfr_sel];

// master/slave drive select
always @(posedge clk)
	if (clk_en) begin
		if (reset)
			dev <= 0;
		else if (sel_tfr && address_in==6 && hwr)
			dev <= {sel_secondary, data_in[12]};
	end

assign packet_state_change = busy && hdd_status_wr && hdd_data_out[5];

// bytes count in a packet
always @(posedge clk)
	if (clk_en) begin
		if (reset)
			packet_count <= 0;
		else if (hdd_wr && hdd_addr == 4)
			packet_count[6:0] <= hdd_data_out[7:1];
		else if (hdd_wr && hdd_addr == 5)
			packet_count[12:7] <= hdd_data_out[5:0];
		else if (packet_state_change && packet_state == PACKET_IDLE)
			packet_count <= 13'd6; // IDLE->WAITCMD transition, expect 6 words of packet command
	end

// status register (write only from SPI host)
// 7 - busy status (write zero to finish command processing: allow host access to task file registers)
// 6
// 5
// 4 - intreq (used for writes only)
// 3 - drq enable for pio in (PI) command type
// 2 - drq enable for pio out (PO) command type
// 1
// 0 - error flag (remember about setting error task file register)

// command busy status
always @(posedge clk)
	if (clk_en) begin
		if (reset)
			busy <= GND;
		else if (hdd_status_wr && hdd_data_out[7] || (sector_count_dec_in && sector_count == 9'h01))	// reset by SPI host (by clearing BSY status bit)
			busy <= GND;
		else if (sel_command) // set when the CPU writes command register
			busy <= VCC;
	end

// IDE interrupt request register
always @(posedge clk)
	if (clk_en) begin
		drq_d <= drq;

		if (reset) begin
			intreq[0] <= GND;
			intreq[1] <= GND;
			block_mark <= GND;
		end else begin
			if (busy && hdd_status_wr && hdd_data_out[3])
				block_mark <= VCC; // to handle IDENTIFY

			if (pio_in) begin // reads
				if (hdd_status_wr && hdd_data_out[4]) 
					block_mark <= VCC;
				if ((error | (!drq_d & drq)) & block_mark) begin
					intreq[dev[1]] <= VCC;
					block_mark <= GND;
				end
				if (packet_in_last) // read the last word from the packet command result
					intreq[dev[1]] <= VCC;
			end else if (pio_out) begin // writes
				if (hdd_status_wr && hdd_data_out[4])
					intreq[dev[1]] <= VCC;
			end else if (hdd_status_wr && hdd_data_out[7]) // other command types completed
				intreq[dev[1]] <= VCC;
			else if (packet_state_change && packet_state == PACKET_IDLE) // ready to accept command packet
				intreq[dev[1]] <= VCC;

			if (intreq_ack[0]) intreq[0] <= GND; // cleared by the CPU
			if (intreq_ack[1]) intreq[1] <= GND; // cleared by the CPU

		end
	end

// pio in command type
always @(posedge clk)
	if (clk_en) begin
		if (reset)
			pio_in <= GND;
		else if (drdy) // reset when processing of the current command ends
			pio_in <= GND;
		else if (busy && hdd_status_wr && hdd_data_out[3])	// set by SPI host 
			pio_in <= VCC;
  end

// pio out command type
always @(posedge clk)
	if (clk_en) begin
		if (reset)
			pio_out <= GND;
		else if (busy && hdd_status_wr && hdd_data_out[7]) 	// reset by SPI host when command processing completes
			pio_out <= GND;
		else if (busy && hdd_status_wr && hdd_data_out[3])	// pio_in set by SPI host (during PACKET processing)
			pio_out <= GND;
		else if (busy && hdd_status_wr && hdd_data_out[2])	// set by SPI host
			pio_out <= VCC;	
	end

// packet command state machine
always @(posedge clk)
	if (clk_en) begin
		if (reset)
			packet_state <= PACKET_IDLE;
		else if (drdy) 	// reset when processing of the current command ends
			packet_state <= PACKET_IDLE;
		else if (packet_state_change)	// set by SPI host
			packet_state <= packet_state == PACKET_IDLE ? PACKET_WAITCMD :
			                packet_state == PACKET_WAITCMD ? PACKET_PROCESSCMD : packet_state;
	end

assign drq = (fifo_full & pio_in) | (~fifo_full & pio_out & (sector_count != 0 || packet_out)); // HDD data request status bit

// error status
always @(posedge clk)
	if (clk_en) begin
		if (reset)
			error <= GND;
		else if (sel_command) // reset by the CPU when command register is written
			error <= GND;
		else if (busy && hdd_status_wr && hdd_data_out[0]) // set by SPI host
			error <= VCC;
	end

assign hdd_cmd_req = bsy; // bsy is set when command register is written, tells the SPI host about new command
assign hdd_dat_req = (fifo_full & pio_out); // the FIFO is full so SPI host may read it

// FIFO in/out multiplexer
assign fifo_reset = reset | sel_command | packet_state_change | packet_in_last;
assign fifo_data_in = pio_in ? hdd_data_out : data_in;
assign fifo_rd = pio_out ? hdd_data_rd : sel_fifo & rd;
assign fifo_wr = pio_in ? hdd_data_wr : sel_fifo & hwr & lwr;

assign packet_in = packet_state == PACKET_PROCESSCMD && pio_in;
assign packet_out = packet_state == PACKET_WAITCMD || (packet_state == PACKET_PROCESSCMD && pio_out);

//sector data buffer (FIFO)
ide_fifo SECBUF1
(
	.clk(clk),
	.clk_en(clk_en),
	.reset(fifo_reset),
	.data_in(fifo_data_in),
	.data_out(fifo_data_out),
	.rd(fifo_rd),
	.wr(fifo_wr),
	.packet_in(packet_in),
	.packet_out(packet_out),
	.packet_count(packet_count),
	.packet_in_last(packet_in_last),
	.full(fifo_full),
	.empty(fifo_empty),
	.last_out(fifo_last_out),
	.last_in(fifo_last_in)
);

// fifo is not ready for reading
assign nrdy = pio_in & sel_fifo & fifo_empty;

assign data_oe = (!dev[1] && hdd0_ena[dev[0]]) || (dev[1] && hdd1_ena[dev[0]]);
//data_out multiplexer
assign data_out = sel_fifo && rd ? fifo_data_out  :
                  sel_status ? data_oe ? {status,8'h00} : 16'h00_00 :
                  sel_tfr && rd ? {tfr_out,8'h00} : 16'h00_00;

//===============================================================================================//

endmodule
