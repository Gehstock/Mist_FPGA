//============================================================================
//  Copyright (C) 2023 Martin Donlon
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

module eeprom_28C64 #(parameter WRITE_CYCLES=0) (
    // Hardware ports
    input clk,
	input reset,

    input ce,
    input wr,
    input rd,

    input  [12:0] addr,
    input  [7:0]  data,
    output [7:0]  q,

    output ready,


    // MiSTer support
    output reg modified,
    input ioctl_download,
	input ioctl_wr,
	input [12:0] ioctl_addr,
	input [7:0] ioctl_dout,
	
    input ioctl_upload,
	output [7:0] ioctl_din,
	input ioctl_rd
);

wire [7:0] q0;

dualport_ram #(8, 13) mem(
    .clock_a(clk),
    .wren_a(wr),
    .address_a(addr),
    .data_a(data),
    .q_a(q0),

    .clock_b(clk),
    .wren_b(ioctl_download & ioctl_wr),
    .address_b(ioctl_addr),
    .data_b(ioctl_dout),
    .q_b(ioctl_din)
);

wire busy;
reg [31:0] write_timer;
reg prev_upload;

assign ready = write_timer == 32'd0;
assign busy = ~ready;
assign q = ready ? q0 : ( ~q0 );

always_ff @(posedge clk) begin
    if (reset) begin
        write_timer <= 32'd0;
        modified <= 0;
    end else if (ce) begin
        if (ioctl_upload & ~prev_upload) modified <= 0;
        prev_upload <= ioctl_upload;

        if (wr) modified <= 1;
        if (busy) begin
            write_timer <= write_timer - 32'd1;
        end else if (wr) begin
            write_timer <= WRITE_CYCLES;
        end
    end
end

endmodule


// This is completely untested. I wrote it and then realized it was not the eeprom that the M92 uses.
// Keeping it here in case it comes in useful at some point. It is an Atmel 28 series eeprom with 64
// byte pages.
module eeprom_28xx_paged(
    input clk,

    input reset,

    input ce,
    input wr,
    input rd,

    input [13:0] addr,
    input [7:0] data,
    output reg [7:0] q
);

reg [7:0] mem[16384];

reg [7:0]  write_page;
reg [5:0]  write_addrs[64];
reg [7:0]  write_bytes[64];
reg [6:0]  write_index;
reg [6:0]  store_index;
reg        write_queuing;
reg        store_pending;
reg [31:0] write_timer;
reg [7:0]  last_byte;

always @(posedge clk) begin
    if (reset) begin
        store_pending <= 0;
        write_queuing <= 0;
        write_index <= 7'd0;
        store_index <= 7'd0;

    end else if (ce) begin
        if (store_pending) begin
            if (store_index == write_index) begin
                store_pending <= 0;
            end else begin
                mem[{write_page, write_addrs[store_index]}] <= write_bytes[store_index];
                store_index <= store_index + 7'd1;
            end
        end else if (wr) begin
            write_timer <= 32'd0;
            write_queuing <= 1;
            write_addrs[write_index] <= addr[5:0];
            write_bytes[write_index] <= data;
            write_index <= write_index + 7'd1;
            write_page <= addr[13:6];
            last_byte <= data;

            if (write_index == 7'd63) begin
                store_pending <= 1;
                store_index <= 7'd0;
                write_queuing <= 0;
            end
        end else if (write_queuing) begin
            write_timer <= write_timer + 32'd1;
            if (write_timer == 32'd100_000) begin
                store_pending <= 1;
                store_index <= 7'd0;
                write_queuing <= 0;
            end
        end

        if (rd) begin
            if (write_queuing | store_pending) begin
                q <= { ~last_byte[7], last_byte[6:0] };
                last_byte[6] <= ~last_byte[6];
            end else begin
                q <= mem[addr];
            end
        end
    end
end

endmodule
