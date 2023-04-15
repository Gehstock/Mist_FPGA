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

module linebuf(
    input clk,

    input ce_pix,

    input [9:0] scan_pos,
    input scan_active,
    output [11:0] scan_out,

    input [11:0] color0,
    input [11:0] color1,
    input [9:0] draw_pos,
    input draw_we
);

wire [11:0] scan_odd, scan_even;
assign scan_out = scan_pos[0] ? scan_odd : scan_even;

wire [11:0] odd_color = draw_pos[0] ? color0 : color1;
wire [11:0] even_color = draw_pos[0] ? color1 : color0;
wire [8:0] odd_addr = draw_pos[9:1];
wire [8:0] even_addr = draw_pos[0] ? draw_pos[9:1] + 9'd1 : draw_pos[9:1];

dualport_ram #(.widthad(9), .width(12)) buffer_odd
(
    .clock_a(clk),
    .address_a(scan_pos[9:1]),
    .q_a(scan_odd),
    .wren_a(scan_active & ce_pix & scan_pos[0]),
    .data_a(12'd0),

    .clock_b(clk),
    .address_b(odd_addr),
    .data_b(odd_color),
    .wren_b((~scan_active) & draw_we & |odd_color[3:0]),
    .q_b()
);

dualport_ram #(.widthad(9), .width(12)) buffer_even
(
    .clock_a(clk),
    .address_a(scan_pos[9:1]),
    .q_a(scan_even),
    .wren_a(scan_active & ce_pix & ~scan_pos[0]),
    .data_a(12'd0),

    .clock_b(clk),
    .address_b(even_addr),
    .data_b(even_color),
    .wren_b((~scan_active) & draw_we & |even_color[3:0]),
    .q_b()
);

endmodule


module double_linebuf(
    input clk,

    input ce_pix,

    input [9:0] scan_pos,
    input scan_toggle,
    output [11:0] scan_out,

    input [63:0] bitplanes,
    input flip,
    input [6:0] color,
    input prio,
    input [9:0] pos,
    input we,

    output idle
);

wire [11:0] scan_out_0, scan_out_1;
assign scan_out = scan_toggle ? scan_out_0 : scan_out_1;

reg [11:0] color0;
reg [11:0] color1;
reg [9:0] draw_pos;
reg draw_we = 0;

linebuf buf_0(
    .clk(clk),
    .ce_pix(ce_pix),

    .scan_active(scan_toggle),
    .scan_out(scan_out_0),
    .scan_pos(scan_pos),

    .color0(color0),
    .color1(color1),
    .draw_pos(draw_pos),
    .draw_we(draw_we)
);

linebuf buf_1(
    .clk(clk),
    .ce_pix(ce_pix),
    
    .scan_active(~scan_toggle),
    .scan_out(scan_out_1),
    .scan_pos(scan_pos),
    
    .color0(color0),
    .color1(color1),
    .draw_pos(draw_pos),
    .draw_we(draw_we)
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

reg [3:0] count = 0;
assign idle = count == 4'd0;

always_ff @(posedge clk) begin
    reg [63:0] bits_r;
    bit [63:0] bits;
    reg [6:0] color_r;
    reg prio_r;

    draw_we <= 0;

    if (count != 4'd0) begin
        color0 <= { prio_r, color_r, bits_r[63], bits_r[47], bits_r[31], bits_r[15] };
        color1 <= { prio_r, color_r, bits_r[62], bits_r[46], bits_r[30], bits_r[14] };
        draw_pos <= draw_pos + 10'd2;
        draw_we <= 1;

        bits_r <= { bits_r[61:0], 2'b00 };

        count <= count - 4'd1;
    end
    
    if (we) begin
        bits = deswizzle(bitplanes, flip);
        
        color0 <= { prio, color, bits[63], bits[47], bits[31], bits[15] };
        color1 <= { prio, color, bits[62], bits[46], bits[30], bits[14] };
        draw_we <= 1;
        draw_pos <= pos;

        bits_r <= { bits[61:0], 2'b00 };
        color_r <= color;
        prio_r <= prio;

        count <= 4'd7;
    end
end

endmodule


