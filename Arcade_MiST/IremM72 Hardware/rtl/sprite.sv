//============================================================================
//  Irem M72 for MiSTer FPGA - Sprites
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

import m72_pkg::*;

module sprite (
    input CLK_32M,
    input CE_PIX,

    input CLK_96M,

    input [15:0] DIN,
    output [15:0] DOUT,
    output DOUT_VALID,

    input [19:0] A,
    input [1:0] BYTE_SEL,

    input BUFDBEN,
    input MRD,
    input MWR,

    input HBLK,
    input [8:0] VE,
    input NL,

    input DMA_ON,
    output reg TNSL,

    output [7:0] pix_test,

    input [63:0] sdr_data,
    output [24:1] sdr_addr,
    output reg sdr_req,
    input sdr_ack
);

wire [7:0] dout_h, dout_l;

assign DOUT = { dout_h, dout_l };
assign DOUT_VALID = MRD & BUFDBEN;

dpramv #(.widthad_a(9)) ram_h
(
    .clock_a(CLK_32M),
    .address_a(A[9:1]),
    .q_a(dout_h),
    .wren_a(MWR & BUFDBEN & BYTE_SEL[1]),
    .data_a(DIN[15:8]),

    .clock_b(CLK_32M),
    .address_b(dma_rd_addr),
    .data_b(),
    .wren_b(0),
    .q_b(dma_h)
);

dpramv #(.widthad_a(9)) ram_l
(
    .clock_a(CLK_32M),
    .address_a(A[9:1]),
    .q_a(dout_l),
    .wren_a(MWR & BUFDBEN & BYTE_SEL[0]),
    .data_a(DIN[7:0]),

    .clock_b(CLK_32M),
    .address_b(dma_rd_addr),
    .data_b(),
    .wren_b(0),
    .q_b(dma_l)
);

reg [63:0] objram[128];

reg [7:0] dma_l, dma_h;
reg [10:0] dma_counter;
wire [9:0] dma_rd_addr = dma_counter[10:1];

always_ff @(posedge CLK_32M) begin
    reg [7:0] b[6];
    if (DMA_ON & TNSL) begin
        TNSL <= 0;
        dma_counter <= 11'd0;
    end

    if (~TNSL) begin
        case (dma_counter[2:0])
        3'b001: begin
            b[0] <= dma_l;
            b[1] <= dma_h;
        end
        3'b011: begin
            b[2] <= dma_l;
            b[3] <= dma_h;
        end
        3'b101: begin
            b[4] <= dma_l;
            b[5] <= dma_h;
        end
        3'b111: objram[dma_counter[10:3]] <= { dma_h, dma_l, b[5], b[4], b[3], b[2], b[1], b[0] };
        endcase

        dma_counter <= dma_counter + 11'd1;
        if (dma_counter == 11'h3ff) TNSL <= 1;
    end
end

reg line_buffer_ack, line_buffer_req;
reg [3:0] line_buffer_color;
reg [63:0] line_buffer_in;
reg [9:0] line_buffer_x;

line_buffer line_buffer(
    .CLK_32M(CLK_32M),
    .CLK_96M(CLK_96M),
    .CE_PIX(CE_PIX),

    .V0(VE[0]),
    .NL(NL),

    .wr_req(line_buffer_req),
    .wr_ack(line_buffer_ack),
    .data_in(line_buffer_in),
    .color_in(line_buffer_color),
    .position_in(line_buffer_x),

    .pixel_out(pix_test)
);

// d is 16 pixels stored as 2 sets of 4 bitplanes
// d[31:0] is 8 pixels, made up from planes d[7:0], d[15:8], etc
// d[63:32] is 8 pixels made up from planes d[39:32], d[47:40], etc
// Returns 16 pixels stored as 4 bit planes d[15:0], d[31:16], etc
function [63:0] deswizzle(input [63:0] d, input rev);
    begin
        integer i;
        bit [7:0] plane[8];
        bit [7:0] t;
        for( i = 0; i < 8; i = i + 1 ) begin
            t = d[(i*8) +: 8];
            plane[i] = rev ? { t[0], t[1], t[2], t[3], t[4], t[5], t[6], t[7] } : t;
        end

        deswizzle[15:0]  = rev ? { plane[4], plane[0] } : { plane[0], plane[4] };
        deswizzle[31:16] = rev ? { plane[5], plane[1] } : { plane[1], plane[5] };
        deswizzle[47:32] = rev ? { plane[6], plane[2] } : { plane[2], plane[6] };
        deswizzle[63:48] = rev ? { plane[7], plane[3] } : { plane[3], plane[7] };
    end
endfunction

reg [63:0] cur_obj;
wire [8:0] obj_org_y = cur_obj[8:0];
wire [15:0] obj_code = cur_obj[31:16];
wire [3:0] obj_color = cur_obj[35:32];
wire obj_flipx = cur_obj[43];
wire obj_flipy = cur_obj[42];
wire [1:0] obj_height = cur_obj[45:44];
wire [1:0] obj_width = cur_obj[47:46];
wire [9:0] obj_org_x = cur_obj[57:48];
reg [8:0] width_px, height_px;
reg [3:0] width, height;
reg [8:0] rel_y;

wire [8:0] row_y = obj_flipy ? (height_px - rel_y - 9'd1) : rel_y;

always_ff @(posedge CLK_96M) begin
    reg old_v0 = 0;

    reg [7:0] obj_ptr = 0;
    reg [3:0] st = 0;
    reg [3:0] span;
    reg [15:0] code;
    reg [8:0] V;

    old_v0 <= VE[0];

    if (old_v0 != VE[0]) begin
        // new line, reset
        obj_ptr <= 0;
        st <= 0;
        V <= NL ? ( VE - 9'd1 ) : ( VE + 9'd1 );
    end else if (obj_ptr == 10'h80) begin
        // done, wait
        obj_ptr <= obj_ptr;
    end else if (sdr_req != sdr_ack) begin
        // wait
    end else begin
        st <= st + 4'd1;
        case (st)
        0: cur_obj <= objram[obj_ptr];
        1: begin
            width_px <= 9'd16 << obj_width;
            height_px <= 9'd16 << obj_height;
            width <= 4'd1 << obj_width;
            height <= 4'd1 << obj_height;
            rel_y <= V + obj_org_y + ( 9'd16 << obj_height );
            span <= 0;
        end
        2: begin
            if (rel_y >= height_px) begin
                st <= 0;
                obj_ptr <= obj_ptr + width;
            end
            code <= obj_code + row_y[8:4] + ( ( obj_flipx ? ( width - span - 16'd1 ) : span ) * 16'd8 );
        end
        3: begin
            sdr_addr <= REGION_SPRITE.base_addr[24:1] + { code[12:0], row_y[3:0], 2'b00 };
            sdr_req <= ~sdr_req;
        end
        4: begin
            line_buffer_in <= deswizzle(sdr_data, obj_flipx);
            if (line_buffer_req != line_buffer_ack)
                st <= st; // wait
            else begin
                line_buffer_color <= obj_color;
                line_buffer_x <= obj_org_x + ( 10'd16 * span );
                line_buffer_req <= ~line_buffer_ack;
            end
        end
        5: begin
            if (span == (width - 1)) begin
                st <= 0;
                obj_ptr <= obj_ptr + width;
            end else begin
                st <= 2;
                span <= span + 4'd1;
            end
        end
        endcase
    end
end

endmodule

module line_buffer(
    input CLK_32M,
    input CLK_96M,
    input CE_PIX,
    
    input V0,
     
     input NL,
    

    input wr_req,
    output reg wr_ack,
    input [63:0] data_in,
    input [3:0] color_in,
    input [9:0] position_in,

    output reg [7:0] pixel_out
);

reg       scan_buffer;
reg [9:0] scan_pos = 0;
wire [9:0] scan_pos_nl = scan_pos ^ {10{NL}};
reg [7:0] line_pixel;
reg [9:0] line_position;
reg line_write = 0;

wire [7:0] scan_0, scan_1, scan_2;
dpramv #(.widthad_a(10)) buffer_0
(
    .clock_a(CLK_32M),
    .address_a(scan_pos_nl),
    .q_a(scan_0),
    .wren_a(!scan_buffer && CE_PIX),
    .data_a(8'd0),

    .clock_b(CLK_96M),
    .address_b(line_position),
    .data_b(line_pixel),
    .wren_b(scan_buffer && line_write),
    .q_b()
);

dpramv #(.widthad_a(10)) buffer_1
(
    .clock_a(CLK_32M),
    .address_a(scan_pos_nl),
    .q_a(scan_1),
    .wren_a(scan_buffer && CE_PIX),
    .data_a(8'd0),

    .clock_b(CLK_96M),
    .address_b(line_position),
    .data_b(line_pixel),
    .wren_b(!scan_buffer && line_write),
    .q_b()
);

always_ff @(posedge CLK_96M) begin
    reg [63:0] data;
    reg [3:0] color;
    reg [9:0] position;
    reg [4:0] count = 0;

    line_write <= 0;

    if (count != 0) begin
        line_pixel <= { color, data[63], data[47], data[31], data[15] };
        line_write <= data[63] | data[47] | data[31] | data[15];
        line_position <= position;
        position <= position + 10'd1;
        count <= count - 4'd1;
        data <= { data[62:0], 1'b0 };
    end else if (wr_req != wr_ack) begin
        data <= data_in;
        color <= color_in;
        position <= position_in;
        count <= 5'd16;
        wr_ack <= wr_req;
    end
end

always_ff @(posedge CLK_32M) begin
    reg old_v0 = 0;

    if (old_v0 != V0) begin
        scan_pos <= 249; // TODO why?
        old_v0 <= V0;
        scan_buffer <= ~scan_buffer;
    end else if (CE_PIX) begin
        pixel_out <= scan_buffer ? scan_1 : scan_0;
        scan_pos <= scan_pos + 10'd1;
    end
end

endmodule
