//============================================================================
//
//  SD card ROM loader and ROM selector for MISTer.
//  Copyright (C) 2019, 2020 Kitrinx (aka Rysha)
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
//
//============================================================================

// ROM layout for Blue Print (index 0 - main CPU board + graphics):
// 0x0000 - 0x0FFF = main_rom1 (bp-1.1m)
// 0x1000 - 0x1FFF = main_rom2 (bp-2.1n)
// 0x2000 - 0x2FFF = main_rom3 (bp-3.1p)
// 0x3000 - 0x3FFF = main_rom4 (bp-4.1r)
// 0x4000 - 0x4FFF = main_rom5 (bp-5.1s)
// 0x5000 - 0x5FFF = tile_rom0 (bg-1.3c)
// 0x6000 - 0x6FFF = tile_rom1 (bg-2.3d)
// 0x7000 - 0x7FFF = spr_rom_r (red.17d)
// 0x8000 - 0x8FFF = spr_rom_b (blue.18d)
// 0x9000 - 0x9FFF = spr_rom_g (green.20d)
// Sound board ROMs loaded separately via index 1

module selector
(
    input logic [24:0] ioctl_addr,
    output logic main1_cs, main2_cs, main3_cs, main4_cs, main5_cs,
    output logic tile0_cs, tile1_cs,
    output logic spr_r_cs, spr_b_cs, spr_g_cs
);
    always_comb begin
        {main1_cs, main2_cs, main3_cs, main4_cs, main5_cs,
         tile0_cs, tile1_cs, spr_r_cs, spr_b_cs, spr_g_cs} = 0;

        if(ioctl_addr < 'h1000)      main1_cs = 1;
        else if(ioctl_addr < 'h2000) main2_cs = 1;
        else if(ioctl_addr < 'h3000) main3_cs = 1;
        else if(ioctl_addr < 'h4000) main4_cs = 1;
        else if(ioctl_addr < 'h5000) main5_cs = 1;
        else if(ioctl_addr < 'h6000) tile0_cs = 1;
        else if(ioctl_addr < 'h7000) tile1_cs = 1;
        else if(ioctl_addr < 'h8000) spr_r_cs = 1;
        else if(ioctl_addr < 'h9000) spr_b_cs = 1;
        else if(ioctl_addr < 'hA000) spr_g_cs = 1;
    end
endmodule

////////////
// EPROMS //
////////////

// Generic 4KB ROM module (12-bit address)
module eprom_4k
(
    input logic        CLK,
    input logic        CLK_DL,
    input logic [11:0] ADDR,
    input logic [24:0] ADDR_DL,
    input logic [7:0]  DATA_IN,
    input logic        CS_DL,
    input logic        WR,
    output logic [7:0] DATA
);
    dpram_dc #(.widthad_a(12)) rom
    (
        .clock_a(CLK),
        .address_a(ADDR[11:0]),
        .q_a(DATA[7:0]),
        .clock_b(CLK_DL),
        .address_b(ADDR_DL[11:0]),
        .data_b(DATA_IN),
        .wren_b(WR & CS_DL)
    );
endmodule

