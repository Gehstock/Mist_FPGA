//============================================================================
//  Irem M92 for MiSTer FPGA - Main module
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

import m92_pkg::*;

module m92 (
    input clk_sys,

    input reset_n,
    output reg ce_pix,
    output flipped,

    input board_cfg_t board_cfg,

    output [7:0] R,
    output [7:0] G,
    output [7:0] B,

    output HSync,
    output VSync,
    output HBlank,
    output VBlank,

    output [15:0] AUDIO_L,
    output [15:0] AUDIO_R,

    input [3:0] coin,
    input [3:0] start_buttons,
    
    input [9:0] p1_input,
    input [9:0] p2_input,
    input [9:0] p3_input,
    input [9:0] p4_input,

    input [23:0] dip_sw,

    input pause_rq,
    output cpu_paused,

    output [24:0] sdr_vram_addr,
    input [31:0] sdr_vram_data,
    output sdr_vram_req,

    output [24:0] sdr_sprite_addr,
    input [63:0] sdr_sprite_dout,
    output sdr_sprite_req,
    input sdr_sprite_ack,
    output sdr_sprite_refresh,

    output [24:0] sdr_bg_addr_a,
    input [31:0] sdr_bg_data_a,
    output sdr_bg_req_a,
    input sdr_bg_ack_a,

    output [24:0] sdr_bg_addr_b,
    input [31:0] sdr_bg_data_b,
    output sdr_bg_req_b,
    input sdr_bg_ack_b,

    output [24:0] sdr_bg_addr_c,
    input [31:0] sdr_bg_data_c,
    output sdr_bg_req_c,
    input sdr_bg_ack_c,

    output reg [24:0] sdr_cpu_addr,
    input [15:0] sdr_cpu_dout,
    output reg [15:0] sdr_cpu_din,
    output reg sdr_cpu_req,
    input sdr_cpu_ack,
    output reg [1:0] sdr_cpu_wr_sel,

    output reg [24:0] sdr_audio_cpu_addr,
    input [15:0] sdr_audio_cpu_dout,
    output reg [15:0] sdr_audio_cpu_din,
    output reg sdr_audio_cpu_req,
    input sdr_audio_cpu_ack,
    output reg [1:0] sdr_audio_cpu_wr_sel,

    output [24:0] sdr_audio_addr,
    input [63:0] sdr_audio_dout,
    output sdr_audio_req,
    input sdr_audio_ack,

    input clk_bram,
    input bram_wr,
    input [7:0] bram_data,
    input [19:0] bram_addr,
    input [4:0] bram_cs,

    input ioctl_download,
    input ioctl_wr,
    input [26:0] ioctl_addr,
    input [7:0] ioctl_dout,

    input ioctl_upload,
    output [7:0] ioctl_upload_index,
    output [7:0] ioctl_din,
    input ioctl_rd,
    output ioctl_upload_req,

    input [2:0] dbg_en_layers,
    input dbg_solid_sprites,
    input en_audio_filters,
    input dbg_fm_en,

    input sprite_freeze,

    input dbg_io_write,
    input [7:0] dbg_io_data,
    output reg dbg_io_wait
);

assign ioctl_upload_index = 8'd1;
assign flipped = NL;

wire [15:0] rgb_color;
assign R = { rgb_color[4:0], rgb_color[4:2] };
assign G = { rgb_color[9:5], rgb_color[9:7] };
assign B = { rgb_color[14:10], rgb_color[14:12] };

reg paused = 0;
assign cpu_paused = paused;

always @(posedge clk_sys) begin
    if (pause_rq & ~paused) begin
        if (~cpu_mem_read & ~cpu_mem_write & ~mem_rq_active & vpulse) begin
            paused <= 1;
        end
    end else if (~pause_rq & paused) begin
        paused <= ~vpulse;
    end
end


wire ce_13m;
jtframe_frac_cen #(2) pixel_cen
(
    .clk(clk_sys),
    .cen_in(1),
    .n(10'd1),
    .m(10'd3),
    .cen({ce_pix, ce_13m})
);

wire ce_9m, ce_18m;
jtframe_frac_cen #(2) cpu_cen
(
    .clk(clk_sys),
    .cen_in(1),
    .n(10'd9),
    .m(10'd20),
    .cen({ce_9m, ce_18m})
);

wire dma_busy;

wire [15:0] cpu_mem_out;
wire [19:0] cpu_mem_addr;
wire [1:0] cpu_mem_sel;

// v30 bus read/write signals are only asserted for a single clock cycle, so latch them for an additional one
reg cpu_mem_read_lat, cpu_mem_write_lat;
wire cpu_mem_read_w, cpu_mem_write_w;
wire cpu_mem_read = cpu_mem_read_w | cpu_mem_read_lat;
wire cpu_mem_write = cpu_mem_write_w | cpu_mem_write_lat;

wire cpu_io_read, cpu_io_write;
wire [7:0] cpu_io_in;
wire [7:0] cpu_io_out;
wire [7:0] cpu_io_addr;

wire [15:0] cpu_mem_in;

/* Global signals from schematics */
wire IOWR = cpu_io_write; // IO Write
wire IORD = cpu_io_read; // IO Read
wire MWR = cpu_mem_write; // Mem Write
wire MRD = cpu_mem_read; // Mem Read


wire [15:0] cpu_word_out = cpu_mem_addr[0] ? { cpu_mem_out[7:0], 8'h00 } : cpu_mem_out;
wire [1:0] cpu_word_byte_sel = cpu_mem_addr[0] ? { cpu_mem_sel[0], 1'b0 } : cpu_mem_sel;
reg  [15:0] cpu_ram_rom_data;
wire [24:0] cpu_region_addr;
wire cpu_region_writable;

wire ram_rom_memrq;
wire buffer_memrq;
wire sprite_control_memrq;
wire video_control_memrq;
wire eeprom_memrq;
wire banked_memrq;

wire [7:0] snd_latch_dout;
wire snd_latch_rdy;

reg [1:0] ce_counter_cpu;
reg ce_cpu, ce_4x_cpu;
reg mem_rq_active = 0;

always @(posedge clk_sys, negedge reset_n) begin
    if (!reset_n) begin
        ce_cpu <= 0;
        ce_4x_cpu <= 0;
        ce_counter_cpu <= 0;
    end else begin
        ce_cpu <= 0;
        ce_4x_cpu <= 0;

        if (~paused) begin
            if (~((ram_rom_memrq) & (cpu_mem_read | cpu_mem_write)) & ~mem_rq_active) begin // stall main cpu while fetching from sdram
                ce_counter_cpu <= ce_counter_cpu + 2'd1;
                ce_4x_cpu <= 1;
                ce_cpu <= &ce_counter_cpu;
            end
        end
    end
end

function [15:0] word_shuffle(input [19:0] addr, input [15:0] data);
    begin
        word_shuffle = addr[0] ? { 8'h00, data[15:8] } : data;
    end
endfunction

always_ff @(posedge clk_sys or negedge reset_n) begin
    if (!reset_n) begin
        mem_rq_active <= 0;
    end else begin
        cpu_mem_read_lat <= cpu_mem_read_w;
        cpu_mem_write_lat <= cpu_mem_write_w;
        if (!mem_rq_active) begin
            if (ram_rom_memrq & ((cpu_mem_read_w & ~cpu_mem_read_lat) | (cpu_mem_write_w & ~cpu_mem_write_lat))) begin // sdram request
                sdr_cpu_wr_sel <= 2'b00;
                sdr_cpu_addr <= cpu_region_addr;
                if (cpu_mem_write & cpu_region_writable ) begin
                    sdr_cpu_wr_sel <= cpu_word_byte_sel;
                    sdr_cpu_din <= cpu_word_out;
                end
                sdr_cpu_req <= ~sdr_cpu_req;
                mem_rq_active <= 1;
            end
        end else if (sdr_cpu_req == sdr_cpu_ack) begin
            mem_rq_active <= 0;
            cpu_ram_rom_data <= sdr_cpu_dout;
        end
    end
end

wire rom0_ce, rom1_ce, ram_cs2;

reg [7:0] dbg_io_latch;

reg [3:0] bank_select = 4'd0;


wire [7:0] switches_p1 = board_cfg.kick_harness ? { p1_input[4], p1_input[5], p1_input[6], 1'b0,             p1_input[3], p1_input[2], p1_input[1], p1_input[0] }
                                                : { p1_input[4], p1_input[5], 1'b0,        1'b0,             p1_input[3], p1_input[2], p1_input[1], p1_input[0] };
wire [7:0] switches_p2 = board_cfg.kick_harness ? { p2_input[4], p2_input[5], p2_input[6], 1'b0,             p2_input[3], p2_input[2], p2_input[1], p2_input[0] }
                                                : { p2_input[4], p2_input[5], 1'b0,        1'b0,             p2_input[3], p2_input[2], p2_input[1], p2_input[0] };
wire [7:0] switches_p3 = board_cfg.kick_harness ? { 1'b0,        1'b0,        1'b0,        1'b0,             1'b0,        1'b0,        1'b0,        1'b0        }
                                                : { p3_input[4], p3_input[5], coin[2],     start_buttons[2], p3_input[3], p3_input[2], p3_input[1], p3_input[0] };
wire [7:0] switches_p4 = board_cfg.kick_harness ? { p2_input[9], p2_input[8], p2_input[7], 1'b0,             p1_input[9], p1_input[8], p1_input[7], 1'b0        }
                                                : { p4_input[4], p4_input[5], coin[3],     start_buttons[3], p4_input[3], p4_input[2], p4_input[1], p4_input[0] };

wire [15:0] switches_p1_p2 = { ~switches_p2, ~switches_p1 };

`ifdef M92_DEBUG_IO
wire [15:0] switches_p3_p4 = { dbg_io_latch, dbg_io_latch };
`else
wire [15:0] switches_p3_p4 = { ~switches_p4, ~switches_p3 };
`endif 

wire [15:0] flags = { ~dip_sw[23:16], ~dma_busy, 1'b1, 1'b1 /*TEST*/, 1'b1 /*R*/, ~coin[1:0], ~start_buttons[1:0] };

reg [7:0] sys_flags = 0;
wire COIN0 = sys_flags[0];
wire COIN1 = sys_flags[1];
wire SOFT_NL = ~sys_flags[2];
wire CBLK = sys_flags[3];
wire BRQ = ~sys_flags[4];
wire BANK = sys_flags[5];
wire NL = SOFT_NL ^ ~dip_sw[8];

// TODO BANK, CBLK, NL
always @(posedge clk_sys) begin
    if (IOWR && cpu_io_addr == 8'h02) sys_flags <= cpu_io_out[7:0];
    if (IOWR && cpu_io_addr == 8'h20) bank_select <= cpu_io_out[3:0];
end

reg [15:0] vid_ctrl;
always @(posedge clk_sys or negedge reset_n) begin
    if (~reset_n) begin
        vid_ctrl <= 0;
    end else if (video_control_memrq & MWR) begin
        vid_ctrl <= cpu_word_out;
    end
end

`ifdef M92_DEBUG_IO
always @(posedge clk_sys or negedge reset_n) begin
    if (~reset_n) begin
        dbg_io_wait <= 0;
        dbg_io_latch <= 8'hff;
    end else begin
        if (IORD && cpu_io_addr == 8'h06) begin
            dbg_io_wait <= 0;
        end

        if (dbg_io_write) begin
            dbg_io_wait <= 1;
            dbg_io_latch <= dbg_io_data;
        end
    end
end
`endif

wire [15:0] ga21_dout;
wire [7:0] eeprom_dout;

// mux io and memory reads
always_comb begin
    bit [15:0] d16;
    bit [15:0] io16;

    if (buffer_memrq) d16 = ga21_dout;
    else if(eeprom_memrq) d16 = { eeprom_dout, eeprom_dout };
    else d16 = cpu_ram_rom_data;
    cpu_mem_in = word_shuffle(cpu_mem_addr, d16);

    case ({cpu_io_addr[7:1], 1'b0})
    8'h00: io16 = switches_p1_p2;
    8'h02: io16 = flags;
    8'h04: io16 = ~dip_sw[15:0];
    8'h06: io16 = switches_p3_p4;
    8'h08: io16 = { snd_latch_dout, snd_latch_dout };
    default: io16 = 16'hffff;
    endcase

    cpu_io_in = cpu_io_addr[0] ? io16[15:8] : io16[7:0];
end

wire int_req, int_ack;
wire [8:0] int_vector;

v30 #(.INTACK_DELAY(0)) v30(
    .clk(clk_sys),
    .ce(ce_cpu),
    .ce_4x(ce_4x_cpu),
    .reset(~reset_n),
    .turbo(1),
    .SLOWTIMING(0),

    .cpu_idle(),
    .cpu_halt(),
    .cpu_irqrequest(),
    .cpu_prefix(),

    .bus_read(cpu_mem_read_w),
    .bus_write(cpu_mem_write_w),
    .bus_be(cpu_mem_sel),
    .bus_addr(cpu_mem_addr),
    .bus_datawrite(cpu_mem_out),
    .bus_dataread(cpu_mem_in),

    .irqrequest_in(int_req),
    .irqvector_in(int_vector),
    .irqrequest_ack(int_ack),

    // TODO
    .cpu_done(),

    .RegBus_Din(cpu_io_out),
    .RegBus_Adr(cpu_io_addr),
    .RegBus_wren(cpu_io_write),
    .RegBus_rden(cpu_io_read),
    .RegBus_Dout(cpu_io_in)
);

address_translator address_translator(
    .A(cpu_mem_addr),
    .board_cfg(board_cfg),
    .ram_rom_memrq(ram_rom_memrq),
    .sdr_addr(cpu_region_addr),
    .writable(cpu_region_writable),

    .buffer_memrq(buffer_memrq),
    .sprite_control_memrq(sprite_control_memrq),
    .video_control_memrq(video_control_memrq),
    .eeprom_memrq(eeprom_memrq),

    .bank_select(bank_select)
);

wire vblank, hblank, vsync, hsync, vpulse, hpulse, hint;

m92_pic m92_pic(
    .clk(clk_sys),
    .ce(ce_cpu),
    .reset(~reset_n),

    .cs((IORD | IOWR) & ~cpu_io_addr[7] & cpu_io_addr[6] & ~cpu_io_addr[0]), // 0x40-0x43
    .wr(IOWR),
    .rd(0),
    .a0(cpu_io_addr[1]),

    .din(cpu_io_out),

    .int_req(int_req),
    .int_vector(int_vector),
    .int_ack(int_ack),

    .intp({4'd0, snd_latch_rdy, hint, ~dma_busy, vblank})
);

assign HSync = hsync;
assign HBlank = hblank;
assign VSync = vsync;
assign VBlank = vblank;

wire objram_we;
wire [15:0] objram_data, objram_q;
wire [63:0] objram_q64;
wire [10:0] objram_addr;

wire [11:0] ga22_color, ga23_color;
wire ga23_prio;

objram objram(
    .clk(clk_sys),

    .addr(objram_addr),
    .we(objram_we),

    .data(objram_data),

    .q(objram_q),
    .q64(objram_q64)
);

wire bufram_we;
wire [15:0] bufram_data;
wire [15:0] bufram_q00, bufram_q01, bufram_q10, bufram_q11;
wire [10:0] bufram_addr;

wire [1:0] bufram_cs =  ( ~bufram_addr[10] & ~dma_busy ) ? { 1'b0,        vid_ctrl[0] } :
                        (  bufram_addr[10] & ~dma_busy ) ? { vid_ctrl[2], vid_ctrl[1] } :
                        ( ~bufram_addr[10] &  dma_busy ) ? { 1'b0,        vid_ctrl[3] } :
                        (  bufram_addr[10] &  dma_busy ) ? { vid_ctrl[5], vid_ctrl[4] } : 2'b00;

wire [15:0] bufram_q;

wire [12:0] ga21_palram_addr;
wire ga21_palram_we, ga21_palram_cs;
wire [15:0] ga21_palram_dout;
wire [15:0] palram_q;
wire [10:0] ga22_count;



singleport_unreg_ram #(.widthad(13), .width(16), .name("BUFRAM")) bufram(
    .clock(clk_sys),
    .address({bufram_cs, bufram_addr}),
    .q(bufram_q),
    .wren(bufram_we),
    .data(bufram_data)
);

palram palram(
    .clk(clk_sys),

    .ce_pix(ce_pix),

    .vid_ctrl(vid_ctrl),
    .dma_busy(dma_busy),

    .cpu_addr(cpu_mem_addr[10:1]),

    .ga21_addr(ga21_palram_addr),
    .ga21_we(ga21_palram_we),
    .ga21_req(ga21_palram_cs),
    
    .obj_color(ga22_color[10:0]),
    .obj_prio(ga22_color[11]),
    .obj_active(|ga22_color[3:0]),

    .pf_color(ga23_color),
    .pf_prio(~ga23_prio),

    .din(ga21_palram_dout),
    .dout(palram_q),

    .rgb_out(rgb_color)
);

GA21 ga21(
    .clk(clk_sys),
    .ce(ce_9m),

    .reset(),

    .din(cpu_word_out),
    .dout(ga21_dout),

    .addr(cpu_mem_addr[11:1]),

    .reg_cs(sprite_control_memrq),
    .buf_cs(buffer_memrq),
    .wr(MWR),

    .busy(dma_busy),

    .obj_dout(objram_data),
    .obj_din(objram_q),
    .obj_addr(objram_addr),
    .obj_we(objram_we),

    .buffer_dout(bufram_data),
    .buffer_din(bufram_q),
    .buffer_addr(bufram_addr),
    .buffer_we(bufram_we),

    .count(ga22_count),

    .pal_addr(ga21_palram_addr),
    .pal_dout(ga21_palram_dout),
    .pal_din(palram_q),
    .pal_we(ga21_palram_we),
    .pal_cs(ga21_palram_cs)
);

GA22 ga22(
    .clk(clk_sys),

    .ce(ce_13m), // 13.33Mhz

    .ce_pix(ce_pix), // 6.66Mhz

    .reset(~reset_n),

    .color(ga22_color),

    .NL(NL),
    .hpulse(hpulse),
    .vpulse(vpulse),

    .count(ga22_count),

    .obj_in(objram_q64),

    .sdr_data(sdr_sprite_dout),
    .sdr_addr(sdr_sprite_addr),
    .sdr_req(sdr_sprite_req),
    .sdr_ack(sdr_sprite_ack),
    .sdr_refresh(sdr_sprite_refresh),

    .dbg_solid_sprites(dbg_solid_sprites)
);

wire [14:0] vram_addr;
assign sdr_vram_addr = {REGION_VRAM.base_addr[24:16], vram_addr, 1'b0};

GA23 ga23(
    .clk(clk_sys),

    .ce(ce_pix),

    .reset(~reset_n),

    .paused(paused),

    .io_wr(IOWR),
    .addr(IOWR ? {8'd0, cpu_io_addr} : cpu_mem_addr),
    .cpu_din(IOWR ? {8'd0, cpu_io_out} : cpu_mem_out),

    .vram_addr(vram_addr),
    .vram_din(sdr_vram_data),
    .vram_req(sdr_vram_req),

    .NL(NL),
    .large_tileset(board_cfg.large_tileset),

    .sdr_data_a(sdr_bg_data_a),
    .sdr_addr_a(sdr_bg_addr_a),
    .sdr_req_a(sdr_bg_req_a),
    .sdr_ack_a(sdr_bg_ack_a),

    .sdr_data_b(sdr_bg_data_b),
    .sdr_addr_b(sdr_bg_addr_b),
    .sdr_req_b(sdr_bg_req_b),
    .sdr_ack_b(sdr_bg_ack_b),

    .sdr_data_c(sdr_bg_data_c),
    .sdr_addr_c(sdr_bg_addr_c),
    .sdr_req_c(sdr_bg_req_c),
    .sdr_ack_c(sdr_bg_ack_c),

    .vblank(vblank),
    .hblank(hblank),
    .vsync(vsync),
    .hsync(hsync),
    .hpulse(hpulse),
    .vpulse(vpulse),

    .hint(hint),

    .color_out(ga23_color),
    .prio_out(ga23_prio),

    .dbg_en_layers(dbg_en_layers)
);

/*
// Sound board test (select sound with P1 left/right)
reg [7:0] snd_id;
reg snd_wr;
reg left_last, right_last;
wire left = p1_input[1];
wire right = p1_input[0];

always @(posedge clk_sys) begin
	if (!reset_n) begin
		snd_wr <= 0;
		snd_id <= 0;
	end else begin
		snd_wr <= 0;
		left_last <= left;
		right_last <= right;
		if (!left_last & left) begin
			snd_id <= snd_id - 1'd1;
			snd_wr <= 1;
		end
		if (!right_last & right) begin
			snd_id <= snd_id + 1'd1;
			snd_wr <= 1;
		end
	end
	
end
*/
wire [15:0] sound_sample;

sound sound(
    .clk_sys(clk_sys),
    .reset(~reset_n),
    .filter_en(en_audio_filters),
    .dbg_fm_en(dbg_fm_en),
    .paused(paused),

    .latch_wr(IOWR & cpu_io_addr == 8'h00),
	//.latch_wr(snd_wr),
    .latch_rd(IORD & cpu_io_addr == 8'h08),
    .latch_din(cpu_io_out),
	//.latch_din(snd_id),
    .latch_dout(snd_latch_dout),
    .latch_rdy(snd_latch_rdy),
    
    .rom_addr(bram_addr),
    .rom_data(bram_data),
    .rom_wr(bram_wr & bram_cs[1]),

    .secure_addr(bram_addr[7:0]),
    .secure_data(bram_data),
    .secure_wr(bram_wr & bram_cs[0]),

    .sample(sound_sample),

    .sdr_cpu_addr(sdr_audio_cpu_addr),
    .sdr_cpu_dout(sdr_audio_cpu_dout),
    .sdr_cpu_din(sdr_audio_cpu_din),
    .sdr_cpu_req(sdr_audio_cpu_req),
    .sdr_cpu_ack(sdr_audio_cpu_ack),
    .sdr_cpu_wr_sel(sdr_audio_cpu_wr_sel),

    .sdr_addr(sdr_audio_addr),
    .sdr_data(sdr_audio_dout),
    .sdr_req(sdr_audio_req),
    .sdr_ack(sdr_audio_ack)
);

assign AUDIO_L = sound_sample;
assign AUDIO_R = sound_sample;

`ifndef NO_EEPROM
eeprom_28C64 eeprom(
    .clk(clk_sys),
    .reset(~reset_n),
    .ce(1),
    
    .rd(MRD & eeprom_memrq),
    .wr(MWR & eeprom_memrq),

    .addr(cpu_mem_addr[13:1]),
    .q(eeprom_dout),
    .data(cpu_mem_out[7:0]),

    .ready(),

    .modified(ioctl_upload_req),
    .ioctl_download(ioctl_download | bram_cs[2]),
    .ioctl_wr(bram_cs[2] ? bram_wr : ioctl_wr),
    .ioctl_addr(bram_cs[2] ? bram_addr[12:0] : ioctl_addr[12:0]),
    .ioctl_dout(ioctl_dout),

    .ioctl_upload(ioctl_upload),
    .ioctl_din(ioctl_din),
    .ioctl_rd(ioctl_rd)
);
`endif

endmodule
