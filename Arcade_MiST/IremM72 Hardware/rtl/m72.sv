//============================================================================
//  Irem M72 for MiSTer FPGA - Main module
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

module m72 (
    input CLK_32M,
    input CLK_96M,

    input reset_n,
    output reg ce_pix,

    input board_cfg_t board_cfg,
    
    output reg [7:0] R,
    output reg [7:0] G,
    output reg [7:0] B,

    output reg HSync,
    output reg VSync,
    output reg HBlank,
    output reg VBlank,

    output [15:0] AUDIO_L,
    output [15:0] AUDIO_R,

    input [1:0] coin,
    input [1:0] start_buttons,
    input [3:0] p1_joystick,
    input [3:0] p2_joystick,
    input [3:0] p1_buttons,
    input [3:0] p2_buttons,
    input service_button,
    input [15:0] dip_sw,

    input pause_rq,

    output [24:1] sdr_sprite_addr,
    input [63:0] sdr_sprite_dout,
    output sdr_sprite_req,
    input sdr_sprite_ack,

    input [31:0] sdr_bg_data_a,
    output [24:0] sdr_bg_addr_a,
    output sdr_bg_req_a,
    input sdr_bg_ack_a,

    input [31:0] sdr_bg_data_b,
    output [24:0] sdr_bg_addr_b,
    output sdr_bg_req_b,
    input sdr_bg_ack_b,

    output [24:0] sdr_cpu_addr,
    input [15:0] sdr_cpu_dout,
    output [15:0] sdr_cpu_din,
    output reg sdr_cpu_req,
    input sdr_cpu_ack,
    output [1:0] sdr_cpu_wr_sel,

    output [24:0] sdr_z80_ram_addr,
    output  [7:0] sdr_z80_ram_data,
    input   [7:0] sdr_z80_ram_dout,
    output        sdr_z80_ram_we,
    output        sdr_z80_ram_cs,
    input         sdr_z80_ram_valid,

    output [24:0] sample_rom_addr,
    input  [63:0] sample_rom_dout,
    output        sample_rom_req,
    input         sample_rom_ack,

    input clk_bram,
    input bram_wr,
    input [7:0] bram_data,
    input [19:0] bram_addr,
    input [1:0] bram_cs,

    input en_layer_a,
    input en_layer_b,
    input en_sprites,
    input en_layer_palette,
    input en_sprite_palette,
    input en_audio_filters,

    input sprite_freeze,

    input video_60hz,
    input video_57hz,
    input video_50hz
);

// Divide 32Mhz clock by 4 for pixel clock
reg paused = 0;

always @(posedge CLK_32M) begin
    if (pause_rq & ~paused & VBlank) begin
        if (~ls245_en & ~DBEN & ~mem_rq_active) begin
            paused <= 1;
        end
    end else if (~pause_rq & paused & VBlank) begin
        paused <= 0;
    end
end

wire SDBEN = sound_memrq & BRQ;

reg [1:0] ce_counter_cpu;
reg [1:0] ce_counter_mcu;
reg ce_cpu, ce_4x_cpu, ce_mcu;

always @(posedge CLK_32M) begin
    if (!reset_n) begin
        ce_cpu <= 0;
        ce_4x_cpu <= 0;
        ce_counter_cpu <= 0;
        ce_counter_mcu <= 0;
        ce_mcu <= 0;
    end else begin
        ce_cpu <= 0;
        ce_4x_cpu <= 0;
        ce_mcu <= 0;

        if (~paused) begin
            if (~ls245_en && ~SDBEN && ~mem_rq_active) begin // stall main cpu while fetching from sdram
                ce_counter_cpu <= ce_counter_cpu + 2'd1;
                ce_4x_cpu <= 1;
                ce_cpu <= &ce_counter_cpu;
            end
            ce_counter_mcu <= ce_counter_mcu + 2'd1;
            ce_mcu <= &ce_counter_mcu;
        end
    end
end

wire ce_pix_half;
jtframe_frac_cen #(2) pixel_cen
(
    .clk(CLK_32M),
    .n(video_57hz ? 10'd115 : video_60hz ? 10'd207 : 10'd1),
    .m(video_57hz ? 10'd444 : video_60hz ? 10'd760 : 10'd4),
    .cen({ce_pix_half, ce_pix})
);

/* Global signals from schematics */
wire IOWR = cpu_io_write; // IO Write
wire IORD = cpu_io_read; // IO Read
wire MWR = cpu_mem_write; // Mem Write
wire MRD = cpu_mem_read; // Mem Read
wire DBEN = cpu_io_write | cpu_io_read | cpu_mem_read | cpu_mem_write;

wire TNSL;

wire m84 = board_cfg.m84;

wire [15:0] cpu_mem_out;
wire [19:0] cpu_mem_addr;
wire [1:0] cpu_mem_sel;
reg cpu_mem_read_lat, cpu_mem_write_lat;
wire cpu_mem_read_w, cpu_mem_write_w;
wire cpu_mem_read = cpu_mem_read_w | cpu_mem_read_lat;
wire cpu_mem_write = cpu_mem_write_w | cpu_mem_write_lat;

wire cpu_io_read, cpu_io_write;
wire [7:0] cpu_io_in;
wire [7:0] cpu_io_out;
wire [7:0] cpu_io_addr;

wire [15:0] cpu_mem_in;


wire [15:0] cpu_word_out = cpu_mem_addr[0] ? { cpu_mem_out[7:0], cpu_mem_out[15:8] } : cpu_mem_out;
wire [19:0] cpu_word_addr = { cpu_mem_addr[19:1], 1'b0 };
wire [1:0] cpu_word_byte_sel = cpu_mem_addr[0] ? { cpu_mem_sel[0], cpu_mem_sel[1] } : cpu_mem_sel;
reg [15:0] cpu_ram_rom_data;
wire [24:0] cpu_region_addr;
wire cpu_region_writable;

wire bg_a_memrq;
wire bg_b_memrq;
wire bg_palette_memrq;
wire sprite_memrq;
wire sprite_palette_memrq;
wire sound_memrq;

function [15:0] word_shuffle(input [19:0] addr, input [15:0] data);
    begin
        word_shuffle = addr[0] ? { 8'h00, data[15:8] } : data;
    end
endfunction

reg mem_rq_active = 0;
reg b_d_dout_valid_lat, obj_pal_dout_valid_lat, sprite_dout_valid_lat;

always @(posedge CLK_32M)
begin
    if (!reset_n) begin
        b_d_dout_valid_lat <= 0;
        obj_pal_dout_valid_lat <= 0;
        sprite_dout_valid_lat <= 0;
    end else begin
        cpu_mem_read_lat <= cpu_mem_read_w;
        cpu_mem_write_lat <= cpu_mem_write_w;

        b_d_dout_valid_lat <= b_d_dout_valid;
        obj_pal_dout_valid_lat <= obj_pal_dout_valid;
        sprite_dout_valid_lat <= sprite_dout_valid;
    end
end

always_ff @(posedge CLK_32M) begin
    if (!mem_rq_active) begin
        if ((ls245_en | SDBEN) && ((cpu_mem_read_w & ~cpu_mem_read_lat) || (cpu_mem_write_w & ~cpu_mem_write_lat))) begin // sdram request
            sdr_cpu_wr_sel <= 2'b00;
            sdr_cpu_addr <= SDBEN ? {REGION_SOUND.base_addr[24:16], cpu_word_addr[15:0]} : cpu_region_addr;
            if (cpu_mem_write & (cpu_region_writable | SDBEN)) begin
                sdr_cpu_wr_sel <= cpu_word_byte_sel;
                sdr_cpu_din <= cpu_word_out;
            end
            sdr_cpu_req <= ~sdr_cpu_req;
            mem_rq_active <= 1;
        end
    end else if (sdr_cpu_req == sdr_cpu_ack) begin
        cpu_ram_rom_data <= sdr_cpu_dout;
        mem_rq_active <= 0;
    end
end

wire ls245_en, rom0_ce, rom1_ce, ram_cs2;


wire [15:0] switches = { p2_buttons, p2_joystick, p1_buttons, p1_joystick };
wire [15:0] flags = { 8'hff, TNSL, 1'b1, 1'b1 /*TEST*/, 1'b1 /*R*/, coin, start_buttons };

reg [7:0] sys_flags = 0;
wire COIN0 = sys_flags[0];
wire COIN1 = sys_flags[1];
wire SOFT_NL = ~sys_flags[2];
wire CBLK = sys_flags[3];
wire BRQ = ~m84 & ~sys_flags[4];
wire BANK = sys_flags[5];
wire NL = SOFT_NL ^ dip_sw[8];

// TODO BANK, CBLK, NL
always @(posedge CLK_32M) begin
    if (IOWR && cpu_io_addr == 8'h02) sys_flags <= cpu_io_out[7:0];
end

// mux io and memory reads
always_comb begin
    bit [15:0] d16;
    bit [15:0] io16;

    if (b_d_dout_valid_lat) d16 = b_d_dout;
    else if (obj_pal_dout_valid_lat) d16 = obj_pal_dout;
    else if (sprite_dout_valid_lat) d16 = sprite_dout;
    else if (cpu_mem_addr[19:16] == 4'hb) d16 = cpu_shared_ram_dout;
    else d16 = cpu_ram_rom_data;
    cpu_mem_in = word_shuffle(cpu_mem_addr, d16);

    case ({cpu_io_addr[7:1], 1'b0})
    8'h00: io16 = switches;
    8'h02: io16 = flags;
    8'h04: io16 = dip_sw;
    default: io16 = 16'hffff;
    endcase

    cpu_io_in = cpu_io_addr[0] ? io16[15:8] : io16[7:0];
end

v30 v30(
    .clk(CLK_32M),
    .ce(ce_cpu), // TODO
    .ce_4x(ce_4x_cpu), // TODO
    .reset(~reset_n),
    .turbo(0),
    .SLOWTIMING(0),

    .cpu_idle(),
    .cpu_halt(),
    .cpu_irqrequest(),
    .cpu_prefix(),

    .dma_active(0),
    .sdma_request(0),
    .canSpeedup(),

    .bus_read(cpu_mem_read_w),
    .bus_write(cpu_mem_write_w),
    .bus_be(cpu_mem_sel),
    .bus_addr(cpu_mem_addr),
    .bus_datawrite(cpu_mem_out),
    .bus_dataread(cpu_mem_in),

    .irqrequest_in(int_req),
    .irqvector_in(int_vector),
    .irqrequest_ack(int_ack),

    .load_savestate(0),

    // TODO
    .cpu_done(),

    .RegBus_Din(cpu_io_out),
    .RegBus_Adr(cpu_io_addr),
    .RegBus_wren(cpu_io_write),
    .RegBus_rden(cpu_io_read),
    .RegBus_Dout(cpu_io_in),

    .sleep_savestate(paused)
);

wire m_io = MRD | MWR;
wire sprite_dma;
wire [1:0] iset;
wire [15:0] iset_data;
wire snd_latch1_wr, snd_latch2_wr;

address_translator address_translator(
    .A(m_io ? cpu_mem_addr : {8'h00, cpu_io_addr}),
    .data(m_io ? cpu_mem_out : {8'h00, cpu_io_out}),
    .bytesel(m_io ? cpu_mem_sel : 2'b01),
    .rd(m_io ? MRD : IORD),
    .wr(m_io ? MWR : IOWR),
    .M_IO(m_io),
    .DBEN(DBEN),
    .board_cfg(board_cfg),
    .ls245_en(ls245_en),
    .sdr_addr(cpu_region_addr),
    .writable(cpu_region_writable),
    .bg_a_memrq(bg_a_memrq),
    .bg_b_memrq(bg_b_memrq),
    .bg_palette_memrq(bg_palette_memrq),
    .sprite_memrq(sprite_memrq),
    .sprite_palette_memrq(sprite_palette_memrq),
    .sound_memrq(sound_memrq),

    .sprite_dma(sprite_dma),
    .iset(iset),
    .iset_data(iset_data),

    .snd_latch1_wr(snd_latch1_wr),
    .snd_latch2_wr(snd_latch2_wr)
);

wire int_req, int_ack;
wire [8:0] int_vector;

m72_pic m72_pic(
    .clk(CLK_32M),
    .ce(ce_cpu),
    .reset(~reset_n),

    .cs((IORD | IOWR) & ~cpu_io_addr[7] & cpu_io_addr[6]), // 0x40-0x43
    .wr(IOWR),
    .rd(0),
    .a0(cpu_io_addr[1]),
    
    .din(cpu_io_out),

    .int_req(int_req),
    .int_vector(int_vector),
    .int_ack(int_ack),

    .intp({5'd0, HINT, 1'b0, VBLK})
);

wire [8:0] VE, V;
wire [9:0] HE, H;
wire HBLK, VBLK, HS, VS;
wire HINT;

kna70h015 kna70h015(
    .CLK_32M(CLK_32M),

    .CE_PIX(ce_pix),
    .iset(iset),
    .iset_data(iset_data),
    .NL(NL),
    .S24H(0),

    .CLD(),
    .CPBLK(),

    .VE(VE),
    .V(V),
    .HE(HE),
    .H(H),

    .HBLK(HBLK),
    .VBLK(VBLK),
    .HINT(HINT),

    .HS(HS),
    .VS(VS),

    .video_50hz(video_50hz)
);

wire [15:0] b_d_dout;
wire b_d_dout_valid;

wire [4:0] char_r, char_g, char_b;
wire P1L;
        
board_b_d board_b_d(
    .CLK_32M(CLK_32M),

    .CE_PIX(ce_pix),

    .DOUT(b_d_dout),
    .DOUT_VALID(b_d_dout_valid),

    .DIN(cpu_word_out),
    .A(cpu_word_addr),
    .BYTE_SEL(cpu_word_byte_sel),

    .IO_DIN(cpu_io_out),
    .IO_A(cpu_io_addr),

    .MRD(MRD),
    .MWR(MWR),
    .IORD(IORD),
    .IOWR(IOWR),

    .a_memrq(bg_a_memrq),
    .b_memrq(bg_b_memrq),
    .palette_memrq(bg_palette_memrq),

    .NL(NL),

    .VE(VE),
    .HE({HE[9], HE[7:0]}),

    .RED(char_r),
    .GREEN(char_g),
    .BLUE(char_b),
    .P1L(P1L),

    .sdr_data_a(sdr_bg_data_a),
    .sdr_addr_a(sdr_bg_addr_a),
    .sdr_req_a(sdr_bg_req_a),
    .sdr_ack_a(sdr_bg_ack_a),

    .sdr_data_b(sdr_bg_data_b),
    .sdr_addr_b(sdr_bg_addr_b),
    .sdr_req_b(sdr_bg_req_b),
    .sdr_ack_b(sdr_bg_ack_b),

    .paused(paused),

    .en_layer_a(en_layer_a),
    .en_layer_b(en_layer_b),
    .en_palette(en_layer_palette),

    .m84(m84)
);


wire [7:0] snd_io_addr;
wire [7:0] snd_io_data;
wire snd_io_req;

wire [15:0] ym_audio;

sound sound(
    .CLK_32M(CLK_32M),
    .reset_n(reset_n),

    .IO_A(cpu_io_addr),
    .IO_DIN(cpu_io_out),

    .SND(snd_latch1_wr),
    .BRQ(BRQ),
    .SND2(snd_latch2_wr),

    .sample_inc(z80_sample_inc),
    .sample_addr(z80_sample_addr),
    .sample_addr_wr(z80_sample_addr_wr),
    .sample_out(z80_sample_out),
    .sample_in(sample_rom_data),
    .sample_ready(sample_rom_req == sample_rom_ack),

    .ym_audio_l(),
    .ym_audio_r(ym_audio),

    .snd_io_addr(snd_io_addr),
    .snd_io_data(snd_io_data),
    .snd_io_req(snd_io_req),

    .pause(paused),

    .m84(m84),

    .ram_addr(sdr_z80_ram_addr),
    .ram_data(sdr_z80_ram_data),
    .ram_dout(sdr_z80_ram_dout),
    .ram_we(sdr_z80_ram_we),
    .ram_cs(sdr_z80_ram_cs),
    .ram_valid(sdr_z80_ram_valid)
);

// Temp A-C board palette
wire [15:0] obj_pal_dout;
wire obj_pal_dout_valid;


wire [4:0] obj_pal_r, obj_pal_g, obj_pal_b;
kna91h014 obj_pal(
    .CLK_32M(CLK_32M),
    .CE_PIX(ce_pix),

    .G(sprite_palette_memrq),
    .SELECT(0),
    .CA(obj_pix),
    .CB(obj_pix),

    .E1_N(), // TODO
    .E2_N(), // TODO
    
    .MWR(MWR & cpu_word_byte_sel[0]),
    .MRD(MRD),

    .DIN(cpu_word_out),
    .DOUT(obj_pal_dout),
    .DOUT_VALID(obj_pal_dout_valid),
    .A(cpu_word_addr),

    .RED(obj_pal_r),
    .GRN(obj_pal_g),
    .BLU(obj_pal_b)
);

wire [4:0] obj_r = en_sprite_palette ? obj_pal_r : { obj_pix[3:0], 1'b0 };
wire [4:0] obj_g = en_sprite_palette ? obj_pal_g : { obj_pix[3:0], 1'b0 };
wire [4:0] obj_b = en_sprite_palette ? obj_pal_b : { obj_pix[3:0], 1'b0 };

wire P0L = (|obj_pix[3:0]) && en_sprites;
always @(posedge CLK_32M) begin
    if (ce_pix) begin
        R <= ~CBLK ? ( (P0L & P1L) ? {obj_r[4:0], obj_r[4:2]} : {char_r[4:0], char_r[4:2]} ) : 8'h00;
        G <= ~CBLK ? ( (P0L & P1L) ? {obj_g[4:0], obj_g[4:2]} : {char_g[4:0], char_g[4:2]} ) : 8'h00;
        B <= ~CBLK ? ( (P0L & P1L) ? {obj_b[4:0], obj_b[4:2]} : {char_b[4:0], char_b[4:2]} ) : 8'h00;
        HSync <= HS;
        HBlank <= HBLK;
        VSync <= VS;
        VBlank <= VBLK;
    end
end

wire [15:0] sprite_dout;
wire sprite_dout_valid;

wire [7:0] obj_pix;

sprite sprite(
    .CLK_32M(CLK_32M),
    .CLK_96M(CLK_96M),
    .CE_PIX(ce_pix),

    .DIN(cpu_word_out),
    .DOUT(sprite_dout),
    .DOUT_VALID(sprite_dout_valid),
    
    .A(cpu_word_addr),
    .BYTE_SEL(cpu_word_byte_sel),

    .BUFDBEN(sprite_memrq),
    .MRD(MRD),
    .MWR(MWR),

    .VE(VE),
    .NL(NL),
    .HBLK(HBLK),
    .pix_test(obj_pix),

    .TNSL(TNSL),
    .DMA_ON(sprite_dma & ~sprite_freeze),

    .sdr_data(sdr_sprite_dout),
    .sdr_addr(sdr_sprite_addr),
    .sdr_req(sdr_sprite_req),
    .sdr_ack(sdr_sprite_ack)
);


wire [15:0] cpu_shared_ram_dout;
wire [11:0] mcu_ram_addr;
wire [7:0] mcu_ram_din;
wire [7:0] mcu_ram_dout;
wire mcu_ram_we;
wire mcu_ram_int;
wire mcu_ram_cs;
wire [7:0] mcu_sample_out;

dualport_mailbox_2kx16 mcu_shared_ram(
    .reset(~reset_n),
    .clk_l(CLK_32M),
    .addr_l(cpu_word_addr[11:1]),
    .cs_l(1'b1),
    .din_l(cpu_word_out),
    .dout_l(cpu_shared_ram_dout),
    .we_l((cpu_word_addr[19:16] == 4'hb && MWR) ? cpu_word_byte_sel : 2'b00),
    .int_l(),

    .clk_r(CLK_32M),
    .cs_r(mcu_ram_cs),
    .addr_r(mcu_ram_addr[11:0]),
    .din_r(mcu_ram_dout),
    .dout_r(mcu_ram_din),
    .we_r(mcu_ram_we),
    .int_r(mcu_ram_int)
);

wire [7:0] mculatch_data = board_cfg.main_mculatch ? cpu_io_out : snd_io_data;
wire mculatch_en = board_cfg.main_mculatch ? ( IOWR && cpu_io_addr == 8'hc0 ) : ( snd_io_req && snd_io_addr == 8'h82 );

mcu mcu(
    .CLK_32M(CLK_32M),
    .ce_8m(ce_mcu),
    .reset(~reset_n),

    .ext_ram_addr(mcu_ram_addr),
    .ext_ram_din(mcu_ram_din),
    .ext_ram_dout(mcu_ram_dout),
    .ext_ram_cs(mcu_ram_cs),
    .ext_ram_we(mcu_ram_we),
    .ext_ram_int(mcu_ram_int),

    .z80_din(mculatch_data),
    .z80_latch_en(mculatch_en),

    .sample_out(mcu_sample_out),

    .sample_addr_wr(mcu_sample_addr_wr),
    .sample_addr(mcu_sample_addr),
    .sample_inc(mcu_sample_inc),
    .sample_rom_data(sample_rom_data),
    .sample_ready(sample_rom_req == sample_rom_ack),

    .clk_bram(clk_bram),
    .bram_wr(bram_wr),
    .bram_data(bram_data),
    .bram_addr(bram_addr),
    .bram_prom_cs(bram_cs[0]),
    .bram_samples_cs(bram_cs[1]),

    .dbg_rom_addr(mcu_dbg_rom_addr)
);

wire [1:0] z80_sample_addr_wr, mcu_sample_addr_wr;
wire [7:0] z80_sample_addr, mcu_sample_addr;
wire [7:0] sample_rom_data;
wire [7:0] z80_sample_out;
wire z80_sample_inc, mcu_sample_inc;

sample_rom sample_rom(
    .clk(CLK_32M),
    .reset(~reset_n),
    .sample_addr_in(m84 ? z80_sample_addr : mcu_sample_addr),
    .sample_addr_wr(m84 ? z80_sample_addr_wr : mcu_sample_addr_wr),

    .sample_data(sample_rom_data),
    .sample_inc(m84 ? z80_sample_inc : mcu_sample_inc),

    .sample_rom_addr(sample_rom_addr),
    .sample_rom_dout(sample_rom_dout),
    .sample_rom_req(sample_rom_req),
    .sample_rom_ack(sample_rom_ack)
);

wire [7:0] signed_mcu_sample = ( m84 ? z80_sample_out : mcu_sample_out ) - 8'h80;
reg [2:0] ce_filter_counter = 0;
wire ce_filter = &ce_filter_counter;
reg [15:0] filtered_mcu_sample;
reg [15:0] filtered_ym_audio;

// 3.5Khz 2nd order low pass filter with additional 10dB attenuation
IIR_filter #( .use_params(1), .stereo(0), .coeff_x(0.00004185087102461337 * 0.31622776601), .coeff_x0(2), .coeff_x1(1), .coeff_x2(0), .coeff_y0(-1.99222499379830120247), .coeff_y1(0.99225510233860669818), .coeff_y2(0)) samples_lpf (
	.clk(CLK_32M),
	.reset(~reset_n),

	.ce(ce_filter),
	.sample_ce(1),

	.cx(),
	.cx0(),
	.cx1(),
	.cx2(),
	.cy0(),
	.cy1(),
	.cy2(),

	.input_l({signed_mcu_sample[7:0], 8'd0}),
    .input_r(),
	.output_l(filtered_mcu_sample),
    .output_r()
);


// 9khz 1st order, 10khz 2nd order
IIR_filter #( .use_params(1), .stereo(0), .coeff_x(0.00000476166826258131), .coeff_x0(3), .coeff_x1(3), .coeff_x2(1), .coeff_y0(-2.96374831301152275032), .coeff_y1(2.92805248787211569450), .coeff_y2(-0.96430074919997255112)) music_lpf (
	.clk(CLK_32M),
	.reset(~reset_n),

	.ce(ce_filter),
	.sample_ce(1),

	.cx(),
	.cx0(),
	.cx1(),
	.cx2(),
	.cy0(),
	.cy1(),
	.cy2(),

	.input_l(ym_audio),
    .input_r(),
	.output_l(filtered_ym_audio),
    .output_r()
);

reg [16:0] audio_out;

assign AUDIO_L = audio_out[16:1];
assign AUDIO_R = audio_out[16:1];

always @(posedge CLK_32M) begin
    ce_filter_counter <= ce_filter_counter + 3'd1;
  
    if (en_audio_filters)
        audio_out <= {filtered_ym_audio[15], filtered_ym_audio[15:0]} + {filtered_mcu_sample[15], filtered_mcu_sample[15:0]};
    else
        audio_out <= {ym_audio[15], ym_audio[15:0]} + {{3{signed_mcu_sample[7]}}, signed_mcu_sample[6:0], 7'd0};
end
















/*
reg [11:0] dbg_cpu_ext_addr;
reg [15:0] dbg_cpu_ext_data;
reg [1:0]  dbg_cpu_ext_we;

assign ddr_debug_data.cpu_ext_addr = dbg_cpu_ext_addr;
assign ddr_debug_data.cpu_ext_data = dbg_cpu_ext_data;
assign ddr_debug_data.cpu_ext_we = dbg_cpu_ext_we;

// CPU debug
always @(posedge CLK_32M) begin
    reg cs;
    reg [11:0] addr;
    reg [15:0] data;
    reg [1:0] we;

    cs <= (cpu_word_addr[19:16] == 4'hb) && ( MWR || MRD );
    addr <= cpu_word_addr[11:0];
    data <= cpu_word_out;
    we <= MWR ? cpu_word_byte_sel : 2'b00;

    if (cs & ~((cpu_word_addr[19:16] == 4'hb) && ( MWR || MRD ))) begin
        dbg_cpu_ext_addr <= addr;
        dbg_cpu_ext_we <= we;
        if (we != 2'b00) dbg_cpu_ext_data <= data;
        else dbg_cpu_ext_data <= cpu_shared_ram_dout;
    end
end

reg [11:0] dbg_mcu_ext_addr;
reg [7:0] dbg_mcu_ext_data;
reg dbg_mcu_ext_we;

assign ddr_debug_data.mcu_ext_addr = dbg_mcu_ext_addr;
assign ddr_debug_data.mcu_ext_data = dbg_mcu_ext_data;
assign ddr_debug_data.mcu_ext_we = dbg_mcu_ext_we;

// MCU debug
always @(posedge CLK_32M) begin
    reg cs;
    reg [11:0] addr;
    reg [7:0] data;
    reg we;

    cs <= mcu_ram_cs;
    addr <= mcu_ram_addr;
    data <= mcu_ram_dout;
    we <= mcu_ram_we;

    if (cs & ~mcu_ram_cs) begin
        dbg_mcu_ext_addr <= addr;
        dbg_mcu_ext_we <= we;
        if (we) dbg_mcu_ext_data <= data;
        else dbg_mcu_ext_data <= mcu_ram_din;
    end
end


wire [15:0] mcu_dbg_rom_addr;
reg [15:0] latched_mcu_dbg_rom_addr;
assign ddr_debug_data.mcu_rom_addr = latched_mcu_dbg_rom_addr; 
always @(posedge CLK_32M) if (ce_cpu) latched_mcu_dbg_rom_addr <= mcu_dbg_rom_addr;
*/
endmodule
