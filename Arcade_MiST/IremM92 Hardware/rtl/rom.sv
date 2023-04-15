//============================================================================
//  Irem M72 for MiSTer FPGA - ROM loading
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

import m92_pkg::*;

module rom_loader
(
    input sys_clk,

    input ioctl_downl,
    input ioctl_wr,
    input [7:0] ioctl_data,

    output ioctl_wait,

    output [24:0] sdr_addr,
    output [15:0] sdr_data,
    output [1:0] sdr_be,
    output reg sdr_req,
    input sdr_ack,

    output [19:0] bram_addr,
    output [7:0] bram_data,
    output reg [4:0] bram_cs,
    output bram_wr,

    output board_cfg_t board_cfg
);

reg [27:0] base_addr;
reg reorder_64;
reg [24:0] offset;
reg [23:0] size;

enum {
    BOARD_CFG,
    REGION_IDX,
    SIZE_0,
    SIZE_1,
    SIZE_2,
    SDR_DATA,
    BRAM_DATA
} stage = BOARD_CFG;

integer region = 0;

always @(posedge sys_clk) begin
    if (!ioctl_downl) begin
        stage <= BOARD_CFG;
        region <= 0;
        bram_cs <= 0;
    end
    if (sdr_ack == sdr_req) begin
        ioctl_wait <= 0;
    end
    bram_wr <= 0;

    if (ioctl_wr) begin
        case (stage)
        BOARD_CFG: begin board_cfg <= board_cfg_t'(ioctl_data); stage <= REGION_IDX; end
        REGION_IDX: begin
            if (ioctl_data == 8'hff) region <= region + 4'd1;
            else region <= ioctl_data[3:0];
            stage <= SIZE_0;
        end
        SIZE_0: begin size[23:16] <= ioctl_data; stage <= SIZE_1; end
        SIZE_1: begin size[15:8] <= ioctl_data; stage <= SIZE_2; end
        SIZE_2: begin
            size[7:0] <= ioctl_data;
            base_addr <= LOAD_REGIONS[region].base_addr;
            reorder_64 <= LOAD_REGIONS[region].reorder_64;
            bram_cs <= LOAD_REGIONS[region].bram_cs;
            offset <= 25'd0;

            if ({size[23:8], ioctl_data} == 24'd0)
                stage <= REGION_IDX;
            else if (LOAD_REGIONS[region].bram_cs != 0)
                stage <= BRAM_DATA;
            else
                stage <= SDR_DATA;
        end
        SDR_DATA: begin
            if (reorder_64)
                sdr_addr <= base_addr[24:0] + {offset[24:7], offset[5:2], offset[6], offset[1:0]};
            else
                sdr_addr <= base_addr[24:0] + offset[24:0];
            sdr_data = {ioctl_data, ioctl_data};
            sdr_be <= { offset[0], ~offset[0] };
            offset <= offset + 25'd1;
            sdr_req <= ~sdr_req;
            ioctl_wait <= 1;

            if (offset == ( size - 1)) stage <= REGION_IDX;
        end
        BRAM_DATA: begin
            bram_addr <= offset[19:0];
            bram_data <= ioctl_data;
            bram_wr <= 1;
            offset <= offset + 25'd1;

            if (offset == ( size - 1)) stage <= REGION_IDX;
        end
        endcase
    end
end

endmodule
