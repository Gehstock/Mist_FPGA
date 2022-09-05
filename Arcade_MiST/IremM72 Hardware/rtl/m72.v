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
    
    input z80_reset_n,

    output [7:0] R,
    output [7:0] G,
    output [7:0] B,

    output HSync,
    output VSync,
    output HBlank,
    output VBlank,

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
    input sdr_sprite_rdy,

    output [24:1] sdr_bg_addr,
    input [31:0] sdr_bg_dout,
    output sdr_bg_req,
    input sdr_bg_rdy,

    output [24:1] sdr_cpu_addr,
    input [15:0] sdr_cpu_dout,
    output [15:0] sdr_cpu_din,
    output sdr_cpu_req,
    input sdr_cpu_rdy,
    output [1:0] sdr_cpu_wr_sel,

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
    input video_50hz,

    output ddr_debug_data_t ddr_debug_data
);

// Divide 32Mhz clock by 4 for pixel clock
reg paused = 0;
reg [8:0] paused_v;
reg [9:0] paused_h;

always @(posedge CLK_32M) begin
    if (pause_rq & ~paused) begin
        if (~ls245_en & ~DBEN & ~mem_rq_active) begin
            paused <= 1;
            paused_v <= V;
            paused_h <= H;
        end
    end else if (~pause_rq & paused) begin
        paused <= ~(V == paused_v && H == paused_h);
    end
end

reg [1:0] ce_counter_cpu, ce_counter_mcu;
reg ce_cpu, ce_4x_cpu, ce_mcu;

always @(posedge CLK_32M) begin
    if (!reset_n) begin
        ce_cpu <= 0;
        ce_4x_cpu <= 0;
        ce_counter_cpu <= 0;
        ce_counter_mcu <= 0;
    end else begin
        ce_cpu <= 0;
        ce_4x_cpu <= 0;
        ce_mcu <= 0;

        if (~paused) begin
            if (~ls245_en && ~mem_rq_active) begin // stall main cpu while fetching from sdram
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

wire clock = CLK_32M;

/* Global signals from schematics */
wire IOWR = cpu_io_write; // IO Write
wire IORD = cpu_io_read; // IO Read
wire MWR = cpu_mem_write; // Mem Write
wire MRD = cpu_mem_read; // Mem Read
wire DBEN = cpu_io_write | cpu_io_read | cpu_mem_read | cpu_mem_write;

wire TNSL;

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


wire [15:0] cpu_word_out = cpu_mem_addr[0] ? { cpu_mem_out[7:0], 8'h00 } : cpu_mem_out;
wire [19:0] cpu_word_addr = { cpu_mem_addr[19:1], 1'b0 };
wire [1:0] cpu_word_byte_sel = cpu_mem_addr[0] ? { cpu_mem_sel[0], 1'b0 } : cpu_mem_sel;
reg [15:0] cpu_ram_rom_data;
wire [24:1] cpu_region_addr;
wire cpu_region_writable;

function [15:0] word_shuffle(input [19:0] addr, input [15:0] data);
    begin
        word_shuffle = addr[0] ? { 8'h00, data[15:8] } : data;
    end
endfunction

reg mem_rq_active = 0;
reg b_d_dout_valid_lat, obj_pal_dout_valid_lat, sound_dout_valid_lat, sprite_dout_valid_lat;

always @(posedge CLK_32M or negedge reset_n)
begin
    if (!reset_n) begin
        b_d_dout_valid_lat <= 0;
        obj_pal_dout_valid_lat <= 0;
        sound_dout_valid_lat <= 0;
        sprite_dout_valid_lat <= 0;
    end else begin
        cpu_mem_read_lat <= cpu_mem_read_w;
        cpu_mem_write_lat <= cpu_mem_write_w;

        b_d_dout_valid_lat <= b_d_dout_valid;
        obj_pal_dout_valid_lat <= obj_pal_dout_valid;
        sound_dout_valid_lat <= sound_dout_valid;
        sprite_dout_valid_lat <= sprite_dout_valid;
    end
end

reg sdr_cpu_rq, sdr_cpu_ack, sdr_cpu_rq2;

always_ff @(posedge CLK_96M) begin
    sdr_cpu_req <= 0;
    if (sdr_cpu_rdy) sdr_cpu_ack <= sdr_cpu_rq;
    if (sdr_cpu_rq != sdr_cpu_rq2) begin
        sdr_cpu_req <= 1;
        sdr_cpu_rq2 <= sdr_cpu_rq;
    end
end


always_ff @(posedge CLK_32M or negedge reset_n) begin
    if (!reset_n) begin
        mem_rq_active <= 0;
    end else begin
        if (!mem_rq_active) begin
            if (ls245_en && ((cpu_mem_read_w & ~cpu_mem_read_lat) || (cpu_mem_write_w & ~cpu_mem_write_lat))) begin // sdram request
                sdr_cpu_wr_sel <= 2'b00;
                sdr_cpu_addr <= cpu_region_addr;
                if (cpu_mem_write & cpu_region_writable ) begin
                    sdr_cpu_wr_sel <= cpu_word_byte_sel;
                    sdr_cpu_din <= cpu_word_out;
                end
                sdr_cpu_rq <= ~sdr_cpu_rq;
                mem_rq_active <= 1;
            end
        end else if (sdr_cpu_rq == sdr_cpu_ack) begin
            cpu_ram_rom_data <= sdr_cpu_dout;
            mem_rq_active <= 0;
        end
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
wire BRQ = ~sys_flags[4];
wire BANK = sys_flags[5];
wire NL = SOFT_NL ^ dip_sw[8];

// TODO BANK, CBLK, NL
always @(posedge CLK_32M) begin
    if (FSET & ~cpu_io_addr[0]) sys_flags <= cpu_io_out[7:0];
end

// mux io and memory reads
always_comb begin
    bit [15:0] d16;
    bit [15:0] io16;

    if (b_d_dout_valid_lat) d16 = b_d_dout;
    else if (obj_pal_dout_valid_lat) d16 = obj_pal_dout;
    else if (sound_dout_valid_lat) d16 = sound_dout;
    else if (sprite_dout_valid_lat) d16 = sprite_dout;
    else if (cpu_mem_addr[19:16] == 4'hb) d16 = cpu_shared_ram_dout;
    else d16 = cpu_ram_rom_data;
    cpu_mem_in = word_shuffle(cpu_mem_addr, d16);

    if (SW) io16 = switches;
    else if (FLAG) io16 = flags;
    else if (DSW) io16 = dip_sw;
    else io16 = 16'hffff;

    cpu_io_in = cpu_io_addr[0] ? io16[15:8] : io16[7:0];
end

cpu v30(
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
    .cpu_export_opcode(cpu_export_opcode),
    .cpu_export_reg_cs(cpu_export_reg_cs),
    .cpu_export_reg_ip(cpu_export_reg_ip),

    .RegBus_Din(cpu_io_out),
    .RegBus_Adr(cpu_io_addr),
    .RegBus_wren(cpu_io_write),
    .RegBus_rden(cpu_io_read),
    .RegBus_Dout(cpu_io_in),

    .sleep_savestate(paused)
);

wire [15:0] cpu_export_reg_cs;
wire [15:0] cpu_export_reg_ip;
wire [7:0] cpu_export_opcode;

assign ddr_debug_data.cpu_cs = cpu_export_reg_cs;
assign ddr_debug_data.cpu_ip = cpu_export_reg_ip;
assign ddr_debug_data.cpu_opcode = cpu_export_opcode;

pal_3a pal_3a(
    .A(cpu_mem_addr),
    .BANK(),
    .DBEN(DBEN),
    .M_IO(MRD | MWR),
    .COD(),
    .board_cfg(board_cfg),
    .ls245_en(ls245_en),
    .sdr_addr(cpu_region_addr),
    .writable(cpu_region_writable),
    .S()
);

wire SW, FLAG, DSW, SND, SND2, FSET, DMA_ON, ISET, INTCS;

pal_4d pal_4d(
    .IOWR(IOWR),
    .IORD(IORD),
    .A(cpu_io_addr),
    .SW(SW),
    .FLAG(FLAG),
    .DSW(DSW),
    .SND(SND),
    .SND2(SND2),
    .FSET(FSET),
    .DMA_ON(DMA_ON),
    .ISET(ISET),
    .INTCS(INTCS)
);

wire BUFDBEN, BUFCS, OBJ_P, CHARA_P, CHARA, SOUND, SDBEN;

pal_3d pal_3d(
    .A(cpu_mem_addr),
    .M_IO(MRD | MWR),
    .DBEN(~DBEN),
    .TNSL(1), // TODO
    .BRQ(BRQ), // TODO

    .BUFDBEN(BUFDBEN),
    .BUFCS(BUFCS),
    .OBJ_P(OBJ_P),
    .CHARA_P(CHARA_P),
    .CHARA(CHARA),
    .SOUND(SOUND),
    .SDBEN(SDBEN)
);

wire int_req, int_ack;
wire [8:0] int_vector;

m72_pic m72_pic(
    .clk(CLK_32M),
    .ce(ce_cpu),
    .reset(~reset_n),

    .cs(INTCS),
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

assign HSync = HS;
assign HBlank = HBLK;
assign VSync = VS;
assign VBlank = VBLK;

kna70h015 kna70h015(
    .CLK_32M(CLK_32M),

    .CE_PIX(ce_pix),
    .D(cpu_io_out),
    .A0(cpu_io_addr[0]),
    .ISET(ISET),
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
    .CLK_96M(CLK_96M),

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
    .CHARA(CHARA),
    .CHARA_P(CHARA_P),
    .NL(NL),

    .VE(VE),
    .HE({HE[9], HE[7:0]}),


    .RED(char_r),
    .GREEN(char_g),
    .BLUE(char_b),
    .P1L(P1L),

    .sdr_data(sdr_bg_dout),
    .sdr_addr(sdr_bg_addr),
    .sdr_req(sdr_bg_req),
    .sdr_rdy(sdr_bg_rdy),

    .paused(paused),

    .en_layer_a(en_layer_a),
    .en_layer_b(en_layer_b),
    .en_palette(en_layer_palette)
);


wire [15:0] sound_dout;
wire sound_dout_valid;

wire [7:0] snd_io_addr;
wire [7:0] snd_io_data;
wire snd_io_req;

wire [15:0] ym_audio;

sound sound(
    .CLK_32M(CLK_32M),
    .DIN(cpu_mem_out),
    .DOUT(sound_dout),
    .DOUT_VALID(sound_dout_valid),
    
    .A(cpu_mem_addr),
    .BYTE_SEL(cpu_mem_sel),

    .IO_A(cpu_io_addr),
    .IO_DIN(cpu_io_out),

    .SDBEN(SDBEN),
    .SOUND(SOUND),
    .SND(SND),
    .BRQ(BRQ),
    .MRD(MRD),
    .MWR(MWR),
    .SND2(SND2),

    .ym_audio_l(),
    .ym_audio_r(ym_audio),

    .snd_io_addr(snd_io_addr),
    .snd_io_data(snd_io_data),
    .snd_io_req(snd_io_req),

    .pause(paused)
);

// Temp A-C board palette
wire [15:0] obj_pal_dout;
wire obj_pal_dout_valid;


wire [4:0] obj_pal_r, obj_pal_g, obj_pal_b;
kna91h014 obj_pal(
    .CLK_32M(CLK_32M),

    .G(OBJ_P),
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

assign R = ~CBLK ? ( (P0L & P1L) ? {obj_r[4:0], obj_r[4:2]} : {char_r[4:0], char_r[4:2]} ) : 8'h00;
assign G = ~CBLK ? ( (P0L & P1L) ? {obj_g[4:0], obj_g[4:2]} : {char_g[4:0], char_g[4:2]} ) : 8'h00;
assign B = ~CBLK ? ( (P0L & P1L) ? {obj_b[4:0], obj_b[4:2]} : {char_b[4:0], char_b[4:2]} ) : 8'h00;

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

    .BUFDBEN(BUFDBEN),
    .MRD(MRD),
    .MWR(MWR),

    .VE(VE),
    .NL(NL),
    .HBLK(HBLK),
    .pix_test(obj_pix),

    .TNSL(TNSL),
    .DMA_ON(DMA_ON & ~sprite_freeze),

    .sdr_data(sdr_sprite_dout),
    .sdr_addr(sdr_sprite_addr),
    .sdr_req(sdr_sprite_req),
    .sdr_rdy(sdr_sprite_rdy)
);


wire [15:0] cpu_shared_ram_dout;
wire [11:0] mcu_ram_addr;
wire [7:0] mcu_ram_din;
wire [7:0] mcu_ram_dout;
wire mcu_ram_we;
wire mcu_ram_int;
wire mcu_ram_cs;
wire [7:0] mcu_sample_data;

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

    .sample_data(mcu_sample_data),

    .clk_bram(clk_bram),
    .bram_wr(bram_wr),
    .bram_data(bram_data),
    .bram_addr(bram_addr),
    .bram_prom_cs(bram_cs[0]),
    .bram_samples_cs(bram_cs[1]),

    .dbg_rom_addr(mcu_dbg_rom_addr)
);

wire [7:0] signed_mcu_sample = mcu_sample_data - 8'h80;
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
        audio_out <= {ym_audio[15], ym_audio[15:0]} + {{signed_mcu_sample[7:0], 9'd0}};
end

















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

endmodule
