//============================================================================
//  Irem M72 for MiSTer FPGA - 8051 protection and sample playback MCU
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

module mcu(
    input CLK_32M,
    input ce_8m,
    input reset,

    // shared ram
    output reg [11:0] ext_ram_addr,
    input [7:0] ext_ram_din,
    output reg [7:0] ext_ram_dout,
    output reg ext_ram_cs,
    output reg ext_ram_we,
    input ext_ram_int,

    // z80 latch
    input [7:0] z80_din,
    input z80_latch_en,

    // sample output, 8-bit unsigned
    output reg [7:0] sample_data,

    output reg [24:0] sample_rom_addr,
    input  [63:0] sample_rom_data,
    output reg sample_rom_req = 0,
    input sample_rom_ack,

    // ioctl
    input clk_bram,
    input bram_wr,
    input [7:0] bram_data,
    input [19:0] bram_addr,
    input bram_prom_cs,
    input bram_samples_cs,

    output [15:0] dbg_rom_addr
);

reg   [6:0] ram_addr;
reg   [7:0] ram_din, ram_dout;
reg         ram_we, ram_cs;

wire  [7:0] sample_port;

reg   [3:0] delayed_ce_count = 0;
wire        delayed_ce = ce_8m & ~|delayed_ce_count & sample_rom_req == sample_rom_ack;

always @(posedge CLK_32M) begin
    if (reset)
        sample_data <= 8'h80;
    else
        sample_data <= sample_port;
end

dpramv #(.widthad_a(7)) internal_ram
(
    .clock_a(CLK_32M),
    .address_a(ram_addr),
    .q_a(ram_din),
    .wren_a(ram_we),
    .data_a(ram_dout),

    .clock_b(0),
    .address_b(0),
    .data_b(),
    .wren_b(1'd0),
    .q_b()
);

dpramv #(.widthad_a(13)) prom
(
    .clock_a(CLK_32M),
    .address_a(prom_addr[12:0]),
    .q_a(prom_data),
    .wren_a(1'b0),
    .data_a(),
    
    .clock_b(clk_bram),
    .address_b(bram_addr[12:0]),
    .data_b(bram_data),
    .wren_b(bram_prom_cs),
    .q_b()
);

wire  [7:0] sample_data_dout;
reg   [7:0] sample_data_latch;
reg  [17:0] sample_addr;

reg   [7:0] z80_latch;
reg         z80_latch_int = 0;

reg   [7:0] ext_dout;
reg  [15:0] ext_addr;
reg         ext_cs, ext_we;

enum { SAMPLE, Z80, RAM } ext_src = SAMPLE;

always @(posedge CLK_32M) begin

    if (reset) begin
        sample_rom_addr[17:0] <= 18'h3FFFF;
    end

    if (z80_latch_en) begin
        z80_latch <= z80_din;
        z80_latch_int <= 1;
    end

    if (ce_8m & |delayed_ce_count) delayed_ce_count <= delayed_ce_count - 3'd1;

    ext_ram_cs <= 0;
    ext_ram_we <= 0;

    if (delayed_ce) begin
        dbg_rom_addr <= prom_addr;

        if (ext_cs) begin
            casex (ext_addr)
            16'h0000: if (ext_we) begin
                sample_addr[12:0] <= { ext_dout, 5'd0 };
            end else begin
                ext_src <= SAMPLE;
                sample_addr <= sample_addr + 18'd1;
                sample_rom_addr <= {REGION_SAMPLES.base_addr[24:18], sample_addr[17:0]};
                if(sample_addr[17:3] != sample_rom_addr[17:3])
                    sample_rom_req <= ~sample_rom_req;
            end

            16'h0001: if (ext_we) begin
                sample_addr[17:13] <= ext_dout[4:0];
            end

            16'h0002: if (ext_we) begin
                z80_latch_int <= 0;
            end else begin
                ext_src <= Z80;
            end

            16'hcxxx: begin
                delayed_ce_count <= 7;
                ext_ram_addr <= ext_addr[11:0];
                ext_ram_dout <= ext_dout;
                ext_ram_cs <= ext_cs;
                ext_ram_we <= ext_cs & ext_we;
                if (~ext_we) ext_src <= RAM;
                end
            endcase
        end
    end
end

always @(*) begin
    case(sample_rom_addr[2:0])
        3'd0: sample_data_dout = sample_rom_data[ 7: 0];
        3'd1: sample_data_dout = sample_rom_data[15: 8];
        3'd2: sample_data_dout = sample_rom_data[23:16];
        3'd3: sample_data_dout = sample_rom_data[31:24];
        3'd4: sample_data_dout = sample_rom_data[39:32];
        3'd5: sample_data_dout = sample_rom_data[47:40];
        3'd6: sample_data_dout = sample_rom_data[55:48];
        default: sample_data_dout = sample_rom_data[63:56];
    endcase;
end

wire [7:0] ext_din = ext_src == SAMPLE ? sample_data_dout : ext_src == Z80 ? z80_latch : ext_ram_din;

reg  [12:0] prom_addr;
wire [12:0] pre_prom_addr;
wire  [7:0] prom_data;

wire  [6:0] pre_ram_addr;
wire  [7:0] pre_ram_dout;
wire        pre_ram_we, pre_ram_cs;

wire  [7:0] pre_ext_dout;
wire [15:0] pre_ext_addr;
wire        pre_ext_cs;
wire        pre_ext_we;

always @(posedge CLK_32M) begin
    ext_dout <= pre_ext_dout;
    ext_addr <= pre_ext_addr;
    ext_cs <= pre_ext_cs;
    ext_we <= pre_ext_we;

    if (delayed_ce) begin
        ram_dout <= pre_ram_dout;
        ram_addr <= pre_ram_addr;
        ram_we   <= pre_ram_we;
        ram_cs   <= pre_ram_cs;

        prom_addr <= pre_prom_addr;
    end
end

mc8051_core mc8051(
    .clk(CLK_32M),
    .cen(delayed_ce),
    .reset(reset),

    // prom
    .rom_data_i(prom_data),
    .rom_adr_o(pre_prom_addr),

    // internal ram
    .ram_data_i(ram_din),
    .ram_data_o(pre_ram_dout),
    .ram_adr_o(pre_ram_addr),
    .ram_wr_o(pre_ram_we),
    .ram_en_o(pre_ram_cs),

    // interrupt lines
    .int0_i(~ext_ram_int),
    .int1_i(~z80_latch_int),

    // sample dac
    .p1_o(sample_port),

    // external ram
    .datax_i(ext_din),
    .datax_o(pre_ext_dout),
    .adrx_o(pre_ext_addr),
    .memx_o(pre_ext_cs),
    .wrx_o(pre_ext_we)
);

endmodule