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

module GA21(
    input clk,
    input ce,

    input reset,

    input [15:0] din,
    output [15:0] dout,

    input [10:0] addr,

    input reg_cs,
    input buf_cs,
    input wr,

    output busy,

    output [15:0] obj_dout,
    input [15:0] obj_din,
    output [10:0] obj_addr,
    output obj_we,

    output buffer_we,
    output [10:0] buffer_addr,
    output [15:0] buffer_dout,
    input [15:0] buffer_din,

    input [9:0] count,

    output [12:0] pal_addr,
    output [15:0] pal_dout,
    input [15:0] pal_din,
    output pal_we,
    output pal_cs
	 
    // TODO pal latching and OE signals?

);

reg [7:0] reg_direct_access;
reg [7:0] reg_obj_ptr;
reg [15:0] reg_copy_mode;

wire [2:0] pal_addr_high = reg_copy_mode[10:8];
wire layer_ordered_copy = reg_copy_mode[0];
wire full_copy          = reg_copy_mode[7] & ~reg_copy_mode[0];

reg obj_addr_high = 0;

enum {
    IDLE,
    IDLE_DELAY,
    INIT_COPY_PAL,
    COPY_PAL,
    INIT_CLEAR_OBJ,
    CLEAR_OBJ,
    INIT_COPY_OBJ,
    COPY_OBJ
} copy_state = IDLE;


reg [10:0] copy_counter;
reg [15:0] copy_dout;
reg [10:0] copy_obj_addr;
reg [9:0] copy_pal_addr;
reg [2:0] copy_obj_word;
reg [8:0] copy_obj_idx;
reg [10:0] buffer_src_addr;
reg [10:0] next_buffer_src_addr;
reg [2:0] copy_layer;
reg copy_this_obj;

reg copy_obj_we, copy_pal_we;

wire direct_access_pal = reg_direct_access[1];
wire direct_access_obj = reg_direct_access[0];

always_ff @(posedge clk or posedge reset) begin
    bit [8:0] obj_y;
    bit [1:0] obj_height;
    bit [1:0] obj_log2_cols;
    bit [2:0] obj_layer;
    bit [3:0] obj_cols;
    bit [8:0] next_obj_idx;

    if (reset) begin
        copy_state <= IDLE;
        reg_direct_access <= 0;
        reg_obj_ptr <= 0;
        reg_copy_mode <= 0;
        
        copy_obj_we <= 0;
        copy_pal_we <= 0;
    end else begin
        if (reg_cs & wr) begin
            if (addr == 11'h0) reg_obj_ptr <= din[7:0];
            if (addr == 11'h1) reg_direct_access <= din[7:0];
            if (addr == 11'h2) reg_copy_mode <= din[15:0];
            if (addr == 11'h4) begin
                copy_state <= INIT_COPY_PAL;
            end
        end

        if (ce) begin
            copy_obj_we <= 0;
            copy_pal_we <= 0;

            case(copy_state)
            IDLE_DELAY: copy_state <= IDLE;
            IDLE: begin
            end
            INIT_COPY_PAL: begin
                buffer_src_addr <= 11'h400;
                copy_pal_addr <= ~10'd0;
                copy_state <= COPY_PAL;
            end
            COPY_PAL: begin
                if (buffer_src_addr == 11'h000) begin
                    copy_state <= INIT_CLEAR_OBJ;
                end else begin
                    buffer_src_addr <= buffer_src_addr + 11'd1;
                    copy_pal_addr <= copy_pal_addr + 10'd1;
                    copy_dout <= buffer_din;
                    copy_pal_we <= 1;
                end
            end
            INIT_CLEAR_OBJ: begin
                copy_dout <= 16'd0;
                copy_obj_addr <= 11'd0;
                copy_obj_we <= 1;
                copy_state <= CLEAR_OBJ;
            end
            CLEAR_OBJ: begin
                copy_obj_addr <= copy_obj_addr + 11'd1;
                copy_obj_we <= 1;
                if (&copy_obj_addr) begin
                    copy_state <= INIT_COPY_OBJ;
                end
            end
            INIT_COPY_OBJ: begin
                copy_state <= COPY_OBJ;
                copy_this_obj <= 0;
                buffer_src_addr <= 11'd0;
                copy_obj_word <= 2'd0;
                copy_layer <= 3'd0;
                copy_obj_idx <= 9'h100 - {1'b0, reg_obj_ptr};
            end
            COPY_OBJ: begin
                copy_dout <= buffer_din;
                buffer_src_addr <= buffer_src_addr + 11'd1;
                copy_obj_word <= copy_obj_word + 2'd1;
                copy_obj_addr <= {1'b0, copy_obj_idx[7:0], copy_obj_word[1:0]}; 
                copy_obj_we <= copy_this_obj;

                if (buffer_src_addr[1:0] == 2'b00) begin
                    if (copy_obj_idx == 9'd0) begin
                        copy_state <= IDLE;
                        copy_obj_we <= 0;
                    end else begin
                        obj_y = buffer_din[8:0];
                        obj_height = buffer_din[10:9];
                        obj_log2_cols = buffer_din[12:11];
                        obj_layer = buffer_din[15:13];
                        obj_cols = 4'd1 << obj_log2_cols;

                        if (full_copy || (layer_ordered_copy == 0 && obj_layer != 3'd7) || (obj_layer == copy_layer)) begin
                            copy_this_obj <= 1;
                            copy_obj_we <= 1;

                            next_obj_idx = copy_obj_idx - obj_cols;
                            if (next_obj_idx[8]) begin // wrapped around
                                copy_state <= IDLE;
                                copy_obj_we <= 0;
                            end else begin
                                copy_obj_addr <= {1'b0, next_obj_idx, copy_obj_word[1:0]};
                                copy_obj_idx <= next_obj_idx;
                            end
                        end else begin
                            copy_this_obj <= 0;
                            copy_obj_we <= 0;
                        end

                        next_buffer_src_addr <= buffer_src_addr + { obj_cols, 2'b00 };
                    end
                end else if (buffer_src_addr[1:0] == 2'b11) begin
                    if (next_buffer_src_addr[10]) begin // end of input
                        if (layer_ordered_copy && (copy_layer != 3'd6)) begin
                            copy_layer <= copy_layer + 3'd1;
                            buffer_src_addr <= 11'd0;
                        end else begin
                            copy_state <= IDLE_DELAY; // delay for one cycle so final write can complete
                        end
                    end else begin
                        buffer_src_addr <= next_buffer_src_addr;
                    end
                end
            end
            endcase
        end
    end
end

assign dout = buf_cs ? (direct_access_obj ? obj_din : (direct_access_pal ? pal_din : buffer_din)) : 16'd0;
assign busy = copy_state != IDLE;

assign buffer_we = ~busy & buf_cs & wr;
assign buffer_addr = busy ? buffer_src_addr : addr;

assign buffer_dout = din;

assign obj_dout = direct_access_obj ? din : copy_dout;
assign obj_addr = direct_access_obj ? addr : (busy ? copy_obj_addr : {obj_addr_high, count});
assign obj_we = direct_access_obj ? (buf_cs & wr) : (busy ? copy_obj_we : 1'b0);

assign pal_dout = direct_access_pal ? din : copy_dout;
assign pal_addr = {pal_addr_high, direct_access_pal ? addr[9:0] : (busy ? copy_pal_addr : 10'd0)};
assign pal_we = direct_access_pal ? (buf_cs & wr) : (busy ? copy_pal_we : 1'b0);
assign pal_cs = direct_access_pal ? buf_cs : 1'b0;

endmodule