//============================================================================
//  Irem M92 for MiSTer FPGA - Common definitions
//
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

package m92_pkg;

    typedef struct packed {
        bit [27:0] base_addr;
        bit reorder_64;
        bit [4:0] bram_cs;
    } region_t;

    parameter region_t REGION_CPU_ROM = '{ 28'h000_0000, 0, 5'b00000 };
    parameter region_t REGION_CPU_RAM = '{ 28'h010_0000, 0, 5'b00000 };
    parameter region_t REGION_SOUND =   '{ 28'h020_0000, 0, 5'b00000 };
    parameter region_t REGION_GA20 =    '{ 28'h030_0000, 0, 5'b00000 };
    parameter region_t REGION_SPRITE =  '{ 28'h040_0000, 1, 5'b00000 };
    parameter region_t REGION_TILE =    '{ 28'h0c0_0000, 0, 5'b00000 };
    parameter region_t REGION_CRYPT =   '{ 28'h000_0000, 0, 5'b00001 };
    parameter region_t REGION_WIDE_SPRITE =  '{ 28'h040_0000, 0, 5'b00000 };
    parameter region_t REGION_EEPROM =  '{ 28'h000_0000, 0, 5'b00100 };

    parameter region_t REGION_VRAM = '{ 28'h070_0000, 0, 5'b00000 };
    parameter region_t REGION_SOUND_RAM = '{ 28'h078_0000, 0, 5'b00000 };

    parameter region_t LOAD_REGIONS[8] = '{
        REGION_CPU_ROM,
        REGION_TILE,
        REGION_SPRITE,
        REGION_SOUND,
        REGION_CRYPT,
        REGION_GA20,
        REGION_WIDE_SPRITE,
        REGION_EEPROM
    };

    
    typedef struct packed {
        bit       large_tileset;
        bit       kick_harness;
        bit       wide_sprites;
        bit       alt_map;
        bit [3:0] bank_mask;
    } board_cfg_t;
endpackage