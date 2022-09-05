//============================================================================
//  Irem M72 for MiSTer FPGA - Z80-based sound system
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

module sound (
    input CLK_32M,
    input reset_n,

    input [7:0] IO_A,
    input [7:0] IO_DIN,

    output [7:0] snd_io_addr,
    output [7:0] snd_io_data,
    output snd_io_req,

    input SOUND,
    input SND,
    input SND2,
    input BRQ,

    input pause,

    output [15:0] ym_audio_l,
    output [15:0] ym_audio_r,

    output [24:0] ram_addr,
    output  [7:0] ram_data,
    input   [7:0] ram_dout,
    output        ram_we,
    output        ram_cs,
    input         ram_valid
);



wire CE_AUDIO, CE_AUDIO_P1;
jtframe_frac_cen #(2) jt51_cen
(
    .clk(CLK_32M),
    .n(10'd83),
    .m(10'd742),
    .cen({CE_AUDIO_P1, CE_AUDIO})
);

assign ram_cs = ~z80_MREQ_n & z80_IORQ_n & z80_RFSH_n;
assign ram_we = ~z80_WR_n;

wire [7:0] SD_IN = z80_dout;
wire [7:0] SD_OUT;

wire SA0 = z80_addr[0];
wire SCS = ~z80_IORQ_n && (z80_addr[2:1] == 2'b00);
wire SIRQ_N;
wire SRESET;
wire SWR_N = z80_WR_n;

wire M1_n;
wire [15:0] z80_addr;
wire z80_IORQ_n, z80_RD_n, z80_WR_n, z80_MREQ_n, z80_M1_n, z80_RFSH_n;

assign ram_addr = {REGION_CPU2_RAM.base_addr[24:16], z80_addr};
assign ram_data = z80_dout;
wire [7:0] z80_din = ( ~z80_M1_n & ~z80_IORQ_n ) ? {2'b11, ~snd_latch1_ready, SIRQ_N, 4'b1111} :
                     ( ~z80_RD_n & ~z80_IORQ_n & (z80_addr[2:1] == 2'b01)) ? snd_latch1 :
                     ( ~z80_RD_n & ~z80_IORQ_n & (z80_addr[2:1] == 2'b10)) ? snd_latch2 :
                     ( ~z80_RD_n & SCS ) ? SD_OUT :
                     ( ~z80_RD_n ) ? ram_dout : 8'hff;
wire [7:0] z80_dout;

assign snd_io_addr = z80_addr[7:0];
assign snd_io_req = ~z80_IORQ_n;
assign snd_io_data = z80_dout;

T80s z80(
    .RESET_n(~BRQ & reset_n),
    .CLK(CLK_32M),
    .CEN(CE_AUDIO & ~pause & ~(ram_cs & ~ram_valid)),
    .INT_n(~(~SIRQ_N | snd_latch1_ready)),
    .BUSRQ_n(~BRQ),
    .M1_n(z80_M1_n),
    .MREQ_n(z80_MREQ_n),
    .IORQ_n(z80_IORQ_n),
    .RFSH_n(z80_RFSH_n),
    .RD_n(z80_RD_n),
    .WR_n(z80_WR_n),
    .A(z80_addr),
    .DI(z80_din),
    .DO(z80_dout),
    .NMI_n(~snd_latch2_ready)
);

jt51 ym2151(
    .rst(BRQ | ~reset_n),
    .clk(CLK_32M),
    .cen(CE_AUDIO & ~pause),
    .cen_p1(CE_AUDIO_P1 & ~pause),
    .cs_n(~SCS),
    .wr_n(SWR_N),
    .a0(SA0),
    .din(SD_IN),
    .dout(SD_OUT),
    .irq_n(SIRQ_N),
    .xleft(ym_audio_l),
    .xright(ym_audio_r)
);

reg [7:0] snd_latch1;
reg snd_latch1_ready = 0;

reg [7:0] snd_latch2;
reg snd_latch2_ready = 0;

always @(posedge CLK_32M) begin
    if (~reset_n) begin
        snd_latch1_ready <= 0;
        snd_latch2_ready <= 0;
    end else begin
        if (SND & ~IO_A[0]) begin
            snd_latch1 <= IO_DIN[7:0];
            snd_latch1_ready <= 1;
        end

        if (SND2 & ~IO_A[0]) begin
            snd_latch2 <= IO_DIN[7:0];
            snd_latch2_ready <= 1;
        end

        if (~z80_IORQ_n & ~z80_WR_n & z80_addr[2:1] == 2'b11) snd_latch1_ready <= 0;
        if (~z80_IORQ_n & ~z80_RD_n & (z80_addr[2:1] == 2'b10)) snd_latch2_ready <= 0;
    end

end

endmodule
