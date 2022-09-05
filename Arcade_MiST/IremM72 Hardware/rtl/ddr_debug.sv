//============================================================================
//  Irem M72 for MiSTer FPGA - DDR-based tracing system
//
//  Copyright (C) 2022 Martin Donlon
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================


typedef struct {
    bit [15:0] cpu_cs;
    bit [15:0] cpu_ip;
    bit [7:0] cpu_opcode;
    bit [1:0] cpu_ext_we;
    bit [11:0] cpu_ext_addr;
    bit [15:0] cpu_ext_data;

    bit mcu_ext_we;
    bit [11:0] mcu_ext_addr;
    bit [7:0] mcu_ext_data;

    bit [15:0] mcu_rom_addr; 
} ddr_debug_data_t;

module ddr_debug(
    input clk,
    input reset,

    // ddr interface
    output        DDRAM_CLK,
    input         DDRAM_BUSY,
    output  [7:0] DDRAM_BURSTCNT,
    output [28:0] DDRAM_ADDR,
    input  [63:0] DDRAM_DOUT,
    input         DDRAM_DOUT_READY,
    output        DDRAM_RD,
    output [63:0] DDRAM_DIN,
    output  [7:0] DDRAM_BE,
    output        DDRAM_WE,

    output reg    stall,

    input ddr_debug_data_t data
);


// extram cpu 00 - 2 bit r/w, 12 bit addr, 16 bit data = 30 bits
// extram mcu 10 - 1 bit r/w, 12 bit addr, 8 bit data = 21 bits
// cpu cs 11 - 16 bits
// cpu ip 111 - 16 bits
// mcu rom_addr 1111 - 16 bits



assign DDRAM_BE = 8'hff;
assign DDRAM_CLK = clk;


wire [31:0] base_addr = 32'h3000_0000;
wire [31:0] write_count_addr = 32'h3400_0000;
wire [31:0] read_count_addr = 32'h3400_0008;
wire [31:0] init_count_addr = 32'h3400_0010;

reg [63:0] write_count = 0;
reg [63:0] read_count = 0;


reg [31:0] block_00[128];
reg [31:0] block_01[128];
reg [31:0] block_10[128];
reg [31:0] block_11[128];


reg [1:0] ready_to_send;
enum { INIT, INIT2, IDLE, UPDATE_RQ, BLOCK0, BLOCK1 } state = INIT;
reg [6:0] send_cnt = 0;

reg [31:0] last_cmd[6];
reg [31:0] send_cmd;
reg send_cmd_valid;
reg [8:0] entry_count = 0;
reg [3:0] cmd_idx = 0;
reg [7:0] init_count = 0;
reg [7:0] idle_count = 0;

/* each block is 1024 bytes in size (128, 8 bytes bursts)
 * 64MB (0x4000000) of memory for blocks which is 64k blocks (0x10000)
 * Blocks are written to 0x3000000 - 0x34000000
 * 0x3400000 and 0x34000008 hold the block written and block read counts
 * If written - read > 0x8000, pause the game.
 */

always @(posedge clk) begin
    bit [31:0] cmd[6];

    send_cmd_valid <= 0;
    stall <= ( write_count - read_count ) > 'hc000;
    DDRAM_WE <= 0;
    DDRAM_RD <= 0;

    if (reset) begin
        write_count <= 0;
        read_count <= 0;
        state <= INIT;
        ready_to_send <= 2'b00;
        last_cmd[0] <= 0;
        last_cmd[1] <= 0;
        last_cmd[2] <= 0;
        last_cmd[3] <= 0;
        last_cmd[4] <= 0;
        entry_count <= 0;
    end else begin
        if (~DDRAM_BUSY) begin
            if (DDRAM_DOUT_READY) begin
                read_count <= DDRAM_DOUT;
            end

            case (state)
            INIT: begin
                DDRAM_WE <= 1;
                DDRAM_BURSTCNT <= 1;
                DDRAM_ADDR <= write_count_addr[31:3];
                DDRAM_DIN <= 64'd0;
                state <= INIT2;
                init_count <= init_count + 8'd1;
            end
            INIT2: begin
                DDRAM_WE <= 1;
                DDRAM_BURSTCNT <= 1;
                DDRAM_ADDR <= init_count_addr[31:3];
                DDRAM_DIN <= init_count;
                state <= IDLE;
            end
            BLOCK0: begin
                send_cnt <= send_cnt + 7'd1;
                DDRAM_WE <= 1;
                DDRAM_DIN <= {block_01[send_cnt], block_00[send_cnt]};
                if (send_cnt == 7'd127) state <= UPDATE_RQ;
            end
            BLOCK1: begin
                send_cnt <= send_cnt + 7'd1;
                DDRAM_WE <= 1;
                DDRAM_DIN <= {block_11[send_cnt], block_10[send_cnt]};
                if (send_cnt == 7'd127) state <= UPDATE_RQ;
            end
            UPDATE_RQ: begin
                DDRAM_WE <= 1;
                DDRAM_BURSTCNT <= 1;
                DDRAM_ADDR <= write_count_addr[31:3];
                DDRAM_DIN <= write_count;
                state <= IDLE;
            end
            IDLE: begin
                idle_count <= idle_count + 8'd1;
                if (ready_to_send != 2'd0) begin
                    bit [31:0] addr;
                    write_count <= write_count + 17'd1;
                    addr = base_addr | { write_count[15:0], 10'd0 };
                    DDRAM_ADDR <= addr[31:3];
                    DDRAM_BURSTCNT <= 8'h80;
                    send_cnt <= 7'd0;
                    if (ready_to_send[0]) begin
                        state <= BLOCK0;
                        ready_to_send[0] <= 0;
                    end else begin
                        state <= BLOCK1;
                        ready_to_send[1] <= 0;
                    end
                end else if (idle_count == 8'd0) begin
                    DDRAM_RD <= 1;
                    DDRAM_BURSTCNT <= 1;
                    DDRAM_ADDR <= read_count_addr[31:3];
                end
            end
            endcase
        end

        send_cmd_valid <= 0;

        cmd_idx <= cmd_idx + 4'd1;
        if (cmd_idx == 4'd4) cmd_idx <= 4'd0;

        cmd[0] = { 2'b01, data.cpu_ext_we, data.cpu_ext_addr, data.cpu_ext_data };
        cmd[1] = { 2'b10, 9'b0, data.mcu_ext_we, data.mcu_ext_addr, data.mcu_ext_data };
        cmd[2] = { 8'b11000000, 8'b0, data.cpu_cs };
        cmd[3] = { 8'b11000001, data.cpu_opcode, data.cpu_ip };
        cmd[4] = { 8'b11000010, 8'b0, data.mcu_rom_addr };

        if (cmd[cmd_idx] != last_cmd[cmd_idx]) begin
            last_cmd[cmd_idx] <= cmd[cmd_idx];
            send_cmd <= cmd[cmd_idx];
            send_cmd_valid <= 1;
        end

        if (send_cmd_valid) begin
            entry_count <= entry_count + 9'd1;
            case( {entry_count[8], entry_count[0]} )
            2'b00: block_00[entry_count[7:1]] <= send_cmd;
            2'b01: block_01[entry_count[7:1]] <= send_cmd;
            2'b10: block_10[entry_count[7:1]] <= send_cmd;
            2'b11: block_11[entry_count[7:1]] <= send_cmd;
            endcase
            if (entry_count[8:0] == 9'h0ff) ready_to_send[0] <= 1;
            if (entry_count[8:0] == 9'h1ff) ready_to_send[1] <= 1;
        end
    end
end

endmodule



