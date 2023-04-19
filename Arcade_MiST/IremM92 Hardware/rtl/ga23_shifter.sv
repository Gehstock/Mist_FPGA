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

module ga23_shifter(
    input clk,
    input ce_pix,

    input [2:0] offset,

    input load,
    input reverse,
    input [31:0] row,
    input [6:0] palette,
    input [1:0] prio,

    output [10:0] color_out,
    output [1:0] prio_out
);

reg [2:0] cnt;
reg [31:0] pix_next, pix_cur;
reg [6:0] pal_next, pal_cur;
reg [1:0] prio_next, prio_cur;
wire [2:0] flip_cnt = cnt + offset;

always_ff @(posedge clk) begin
    if (ce_pix) begin
        pix_cur[27:0] <= pix_cur[31:4];
        cnt <= cnt + 3'd1;

        if (&flip_cnt) begin
            pix_cur <= pix_next;
            prio_cur <= prio_next;
            pal_cur <= pal_next;
        end

        if (load) begin
            integer i;
            for( i = 0; i < 8; i = i + 1 ) begin
                pix_next[(i * 4) + 3] = reverse ? row[24 + i] : row[31 - i];
                pix_next[(i * 4) + 2] = reverse ? row[16 + i] : row[23 - i];
                pix_next[(i * 4) + 1] = reverse ? row[ 8 + i] : row[15 - i];
                pix_next[(i * 4) + 0] = reverse ? row[ 0 + i] : row[ 7 - i];
            end
            pal_next <= palette;
            prio_next <= prio;
            cnt <= 0;
        end
    end
end

assign prio_out = prio_cur;
assign color_out = { pal_cur, pix_cur[3:0] };

endmodule