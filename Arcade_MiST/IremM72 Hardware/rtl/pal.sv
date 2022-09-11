//============================================================================
//  Irem M72 for MiSTer FPGA - PAL address decoders
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

// http://wiki.pldarchive.co.uk/index.php?title=M72-R-3A

import m72_pkg::*;

module address_translator
(
    input logic [19:0] A,
    input logic [15:0] data,
    input logic [1:0] bytesel,

    input logic rd,
    input logic wr,
    
    input board_cfg_t board_cfg,

    input logic DBEN,
    input logic M_IO,
    output logic ls245_en, // TODO this signal might be better named
    output [24:0] sdr_addr,
    output writable,

    output bg_a_memrq, // CHARA
    output bg_b_memrq, // CHARA
    output bg_palette_memrq, // CHARA_P
    
    output sprite_memrq, // 
    output sprite_palette_memrq, // OBJ_P
    output sound_memrq,

    output sprite_dma,
    output [1:0] iset,
    output [15:0] iset_data,

    output snd_latch1_wr,
    output snd_latch2_wr
);

    assign snd_latch1_wr = ~M_IO & wr & ( A[7:0] == 8'h00 );
    assign snd_latch2_wr = (board_cfg.m84) ? 1'b0 : ( ~M_IO & wr & ( A[7:0] == 8'hc0));
    
    always_comb begin
        case (board_cfg.memory_map)
        0: begin
            casex (A[19:16])
            4'b010x: begin ls245_en = DBEN & M_IO; writable = 1; sdr_addr = REGION_CPU_RAM.base_addr[24:0] | A[16:0]; end
            4'b00xx: begin ls245_en = DBEN & M_IO; writable = 0; sdr_addr = REGION_CPU_ROM.base_addr[24:0] | A[17:0]; end
            4'b1111: begin ls245_en = DBEN & M_IO; writable = 0; sdr_addr = REGION_CPU_ROM.base_addr[24:0] | A[17:0]; end
            default: begin ls245_en = 0; writable = 0; sdr_addr = 24'd0; end
            endcase
        end
        1: begin
            casex (A[19:16])
            4'b1010: begin ls245_en = DBEN & M_IO; writable = 1; sdr_addr = REGION_CPU_RAM.base_addr[24:0] | A[16:0]; end
            4'b0xxx: begin ls245_en = DBEN & M_IO; writable = 0; sdr_addr = REGION_CPU_ROM.base_addr[24:0] | A[18:0]; end
            4'b1111: begin ls245_en = DBEN & M_IO; writable = 0; sdr_addr = REGION_CPU_ROM.base_addr[24:0] | A[18:0]; end
            default: begin ls245_en = 0; writable = 0; sdr_addr = 24'd0; end
            endcase
        end
        2: begin
            casex (A[19:16])
            4'b100x: begin ls245_en = DBEN & M_IO; writable = 1; sdr_addr = REGION_CPU_RAM.base_addr[24:0] | A[16:0]; end
            4'b0xxx: begin ls245_en = DBEN & M_IO; writable = 0; sdr_addr = REGION_CPU_ROM.base_addr[24:0] | A[18:0]; end
            4'b1111: begin ls245_en = DBEN & M_IO; writable = 0; sdr_addr = REGION_CPU_ROM.base_addr[24:0] | A[18:0]; end
            default: begin ls245_en = 0; writable = 0; sdr_addr = 24'd0; end
            endcase
        end

        3,4: begin
            casex (A[19:16])
            4'b1110: begin ls245_en = DBEN & M_IO; writable = 1; sdr_addr = REGION_CPU_RAM.base_addr[24:0] | A[16:0]; end
            4'b0xxx: begin ls245_en = DBEN & M_IO; writable = 0; sdr_addr = REGION_CPU_ROM.base_addr[24:0] | A[18:0]; end
            4'b1111: begin ls245_en = DBEN & M_IO; writable = 0; sdr_addr = REGION_CPU_ROM.base_addr[24:0] | A[18:0]; end
            default: begin ls245_en = 0; writable = 0; sdr_addr = 24'd0; end
            endcase
        end

        default: begin
            ls245_en = 0;
            writable = 0;
            sdr_addr = 0;
        end
            
        endcase
    end

    always_comb begin
        bg_a_memrq = 0;
        bg_b_memrq = 0;
        bg_palette_memrq = 0;
        sprite_memrq = 0;
        sprite_palette_memrq = 0;
        sound_memrq = 0;

        case (board_cfg.memory_map)
        // M84 rtype2
        3: begin
            casex (A[19:12])
            // 0xc0xxx
            8'b1100_0000: sprite_memrq = 1;
            // 0xc8xxx
            8'b1100_1000: sprite_palette_memrq = 1;
            // 0xd8xxx
            8'b1101_1000: bg_palette_memrq = 1;
            // 0xd0000 - 0xd3fff
            8'b1101_00xx: bg_a_memrq = 1;
            // 0xd4000 - 0xd7fff
            8'b1101_01xx: bg_b_memrq = 1;
            default: begin end// nothing
            endcase
        end
        // M84 Hammerin' Harry
        4: begin
            casex (A[19:12])
            // 0xc0xxx
            8'b1100_0000: sprite_memrq = 1;
            // 0xa0xxx
            8'b1010_0000: sprite_palette_memrq = 1;
            // 0xa8xxx
            8'b1010_1000: bg_palette_memrq = 1;
            // 0xd0000 - 0xd3fff
            8'b1101_00xx: bg_a_memrq = 1;
            // 0xd4000 - 0xd7fff
            8'b1101_01xx: bg_b_memrq = 1;
            default: begin end// nothing
            endcase
        end

        // M72
        default: begin
            casex (A[19:12])
            // 0xc0xxx
            8'b1100_0000: sprite_memrq = 1;
            // 0xc8xxx
            8'b1100_1000: sprite_palette_memrq = 1;
            // 0xccxxx
            8'b1100_1100: bg_palette_memrq = 1;
            // 0xd0000 - 0xd3fff
            8'b1101_00xx: bg_a_memrq = 1;
            // 0xd8000 - 0xdbfff
            8'b1101_10xx: bg_b_memrq = 1;
            // 0xexxxx
            8'b1110_xxxx: sound_memrq = 1;
            default: begin end// nothing
            endcase
        end
        endcase
    end

    always_comb begin
        sprite_dma = 0;
        iset_data = 16'd0;
        iset = 2'b00;

        // M84
        if (board_cfg.m84) begin
            if (M_IO & wr) begin
                sprite_dma = A == 20'hbc000;
                if (A == 20'hb0000) begin
                    iset = bytesel;
                    iset_data = data;
                end else if (A == 20'hb0001) begin
                    iset = 2'b10;
                    iset_data = { data[7:0], 8'h00 };
                end
            end
        end else begin
            if (!M_IO & wr) begin
                sprite_dma = A == 8'h04;
                if (A == 8'h06) begin
                    iset = 2'b01;
                    iset_data = { 8'h00, data[7:0] };
                end else if (A == 8'h07) begin
                    iset = 2'b10;
                    iset_data = { data[7:0], 8'h00 };
                end
            end
        end
    end
endmodule
