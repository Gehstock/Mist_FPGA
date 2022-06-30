//============================================================================
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
//
//============================================================================

`default_nettype none

module armedf
(
    input         pll_locked,
    input         clk_96M, // only for SDRAM and ROM download
    input         clk_24M,
    input         reset,
    input         pause_cpu,

    input   [3:0] pcb,
    input         gfx1_en,
    input         gfx2_en,
    input         gfx3_en,
    input         gfx4_en,

    input  [15:0] p1,
    input  [15:0] p2,
    input   [7:0] dsw1,
    input   [7:0] dsw2,

    output        hbl,
    output        vbl,
    output        hsync,
    output        vsync,
    output  [3:0] r,
    output  [3:0] g,
    output  [3:0] b,

    output [15:0] audio_l,
    output [15:0] audio_r,

    input   [8:0] hs_offset,
    input   [8:0] vs_offset,

    input         rom_download,
    input  [23:0] ioctl_addr,
    input         ioctl_wr,
    input   [7:0] ioctl_dout,

    output [12:0] SDRAM_A,
    output  [1:0] SDRAM_BA,
    inout  [15:0] SDRAM_DQ,
    output        SDRAM_DQML,
    output        SDRAM_DQMH,
    output        SDRAM_nCS,
    output        SDRAM_nCAS,
    output        SDRAM_nRAS,
    output        SDRAM_nWE
);

`include "defs.v"

assign m68k_a[0] = reset;

localparam  CLKSYS=96;

reg [1:0] clk6_count;
reg [2:0] clk4_count;
reg [8:0] clk_ym_count;

reg clk4_en_p, clk4_en_n;
reg clk8_en_p, clk8_en_n;
reg clk6_en;
reg real_pause;

always @(posedge clk_24M) begin
    if (reset) begin
        clk4_count <= 0;
        clk6_count <= 0;
        {clk4_en_p, clk4_en_n} <= 0;
        {clk8_en_p, clk8_en_n} <= 0;
        clk6_en <= 0;
    end else begin
        clk4_count <= clk4_count + 1'd1;
        if (clk4_count == 5) begin
            clk4_count <= 0;
            real_pause <= pause_cpu & m68k_as_n;
        end
        clk4_en_p <= clk4_count == 0;
        clk4_en_n <= clk4_count == 3;
        clk8_en_p <= (clk4_count == 0 || clk4_count == 3) && !real_pause;
        clk8_en_n <= (clk4_count == 2 || clk4_count == 5) && !real_pause;

        clk6_count <= clk6_count + 1'd1;
        clk6_en <= clk6_count == 0;

        if (clk4_count == 0) clk_ym_count <= clk_ym_count + 1'd1;

    end
end

//////////////////////////////////////////////////////////////////

wire [8:0] hc;
wire [8:0] vc;

video_timing video_timing (
    .clk(clk_24M),
    .clk_pix_en(clk6_en),
    .pcb(pcb),
    .hc(hc),
    .vc(vc),
    .hs_offset(hs_offset),
    .vs_offset(vs_offset),
    .hbl(hbl),
    .vbl(vbl),
    .hsync(hsync),
    .vsync(vsync)
);


//// SPRITE MACHINE
wire  [9:0] sprite_y_adj = ( pcb == 4 || pcb == 5 || pcb == 6 || pcb == 7) ? 10'd0 : 10'd128 ;

// armedf (2), cclimbr2 (4), legion (5,6,7)
// big fighter &  kozure (1) is 192 

wire  [9:0] max_sprites = ( pcb == 0 || pcb == 8 || pcb == 9 ) ? 10'd127 : (pcb == 1 || pcb == 3) ? 10'd191 : 10'd511;
reg   [9:0] sprite_count;
wire  [8:0] sprite_y_pos_final = sprite_y_adj + y_adj + 8'd239 - sprite_y_pos;

reg   [5:0] spr_pal_idx;

wire  [3:0] sprite_y_ofs = vc - sprite_y_pos_final;

wire  [3:0] flipped_x = ( sprite_flip_x == 0 ) ? sprite_x_ofs : 4'd15 - sprite_x_ofs;
wire  [3:0] flipped_y = ( sprite_flip_y == 0 ) ? sprite_y_ofs : 4'd15 - sprite_y_ofs;

reg  [10:0] sprite_shared_addr;
wire [15:0] sprite_shared_ram_dout;

reg   [3:0] copy_sprite_state;
reg   [2:0] draw_sprite_state;

reg   [1:0] sprite_pri;
reg   [8:0] sprite_x_ofs;
reg   [9:0] sprite_idx;
reg  [11:0] sprite_tile ;  
reg   [8:0] sprite_y_pos;
reg   [8:0] sprite_x_pos;
reg   [4:0] sprite_colour;
reg         sprite_x_256;
reg         sprite_flip_x;
reg         sprite_flip_y;
reg   [6:0] sprite_spr_lut;
reg  [31:0] sprite_data;

reg   [3:0] spr_pix;
always @ (*) begin
    case ( flipped_x[2:0] )
        3'b000: spr_pix = sprite_data[ 3: 0];
        3'b001: spr_pix = sprite_data[ 7: 4];
        3'b010: spr_pix = sprite_data[11: 8];
        3'b011: spr_pix = sprite_data[15:12];
        3'b100: spr_pix = sprite_data[19:16];
        3'b101: spr_pix = sprite_data[23:20];
        3'b110: spr_pix = sprite_data[27:24];
        3'b111: spr_pix = sprite_data[31:28];
    endcase
end

wire [10:0] spr_pal_addr = { sprite_spr_lut, spr_pix };  // [10:0]

always @ (posedge clk_24M) begin
    // copy sprite list to dedicated sprite list ram
    // start state machine for copy
    if ( copy_sprite_state == 0 && vbl_sr == 2'b01 ) begin
        copy_sprite_state <= 1;
        draw_sprite_state <= 0;
        sprite_count <= 0;
    end else if ( copy_sprite_state == 1 ) begin
        sprite_shared_addr <= 0;
        copy_sprite_state <= 2;
        sprite_buffer_addr <= 0;
    end else if ( copy_sprite_state == 2 ) begin
        // address now 0
        sprite_shared_addr <= sprite_shared_addr + 1'd1;
        copy_sprite_state <= 3; 
    end else if ( copy_sprite_state == 3 ) begin
       // address 0 result
        //sprite_y_pos <= sprite_y_adj + y_adj + 239 - sprite_shared_ram_dout[8:0];
        sprite_y_pos <= sprite_shared_ram_dout[8:0];
        sprite_pri   <= sprite_shared_ram_dout[13:12];
        sprite_shared_addr <= sprite_shared_addr + 1'd1;
        copy_sprite_state <= 4; 
    end else if ( copy_sprite_state == 4 ) begin
        // address 1 result
        // tile #
        sprite_tile[11:0] <= sprite_shared_ram_dout[11:0];

        // flip y
        sprite_flip_y <= sprite_shared_ram_dout[12];

        // flip x
        sprite_flip_x <= sprite_shared_ram_dout[13];

        sprite_shared_addr <= sprite_shared_addr + 1'd1;
        copy_sprite_state <= 5; 
    end else if ( copy_sprite_state == 5 ) begin
        // colour
        sprite_colour <= sprite_shared_ram_dout[12:8];
        sprite_spr_lut <= sprite_shared_ram_dout[6:0];
        sprite_shared_addr <= sprite_shared_addr + 1'd1;

        copy_sprite_state <= 6; 
    end else if ( copy_sprite_state == 6 ) begin
        sprite_x_pos <= sprite_shared_ram_dout[8:0] + 8'd16 - tile_x_ofs ;

        copy_sprite_state <= 7; 
    end else if ( copy_sprite_state == 7 ) begin
        sprite_buffer_w <= 1;
        sprite_buffer_din <= {sprite_tile,sprite_x_pos,sprite_y_pos,sprite_colour,sprite_spr_lut, sprite_flip_x,sprite_flip_y,sprite_pri};
        sprite_buffer_addr <= sprite_buffer_addr + 1'd1;

        copy_sprite_state <= 8;
    end else if ( copy_sprite_state == 8 ) begin
        sprite_count <= sprite_buffer_addr;
        // write is complete
        sprite_buffer_w <= 0;
        // sprite has been buffered.  are we done?
        if ( sprite_shared_addr[10:2] < max_sprites ) begin
            // start on next sprite
            copy_sprite_state <= 2;
        end else begin
            // we are done, go idle.
            copy_sprite_state <= 0;
            sprite_buffer_addr <= 0;
        end
    end

    // Rendering into dual line-buffers
    sprite_fb_w <= 0;
    case (draw_sprite_state)
    0:  if ( copy_sprite_state == 0 && hc == 2 ) begin
            // don't try to draw sprites while copying the buffer.
            sprite_x_ofs <= 0;
            sprite_buffer_addr <= 0;
            draw_sprite_state <= 1;
        end
    1:  if (sprite_buffer_addr < max_sprites) begin
            // get current sprite attributes
            {sprite_tile,sprite_x_pos,sprite_y_pos,sprite_colour,sprite_spr_lut,sprite_flip_x,sprite_flip_y,sprite_pri} <= sprite_buffer_dout;
            sprite_buffer_addr <= sprite_buffer_addr + 1'd1;
            draw_sprite_state <= 2;
            sprite_x_ofs <= 0;
        end else begin
            // all done!
            draw_sprite_state <= 0;
            sprite_buffer_addr <= 0;
        end
    2:  if ( sprite_pri != 3 && sprite_y_pos != 0 && vc >= sprite_y_pos_final && vc < ( sprite_y_pos_final + 16 ) ) begin
            sprite_rom_addr <= { sprite_tile, flipped_y[3:0], flipped_x[3] };  
            sprite_rom_req <= ~sprite_rom_req;
            draw_sprite_state <= 3;
        end else begin
            draw_sprite_state <= 1;
        end
    3:  if ( sprite_rom_req == sprite_rom_ack ) begin
            // wait for bitmap read to complete
            sprite_data <= sprite_rom_data;
            draw_sprite_state <= 4;
        end
    4:  begin
            if ( spr_pal_dout[3:0] != 15 && sprite_x_pos[8:0] < 353 ) begin // spr_pix

                sprite_fb_w <= 1;
                // 0-511 = even line / 512-1023 = odd line
                sprite_fb_addr_w <= { vc[0], sprite_x_pos[8:0] } ;
                sprite_fb_din    <= { sprite_colour[4:0],spr_pal_dout[3:0],sprite_pri[1:0] }; 

            end

            if ( sprite_x_ofs < 15 ) begin
                sprite_x_pos <= sprite_x_pos + 1'd1;
                sprite_x_ofs <= sprite_x_ofs + 1'd1;
                if (sprite_x_ofs[2:0] == 3'b111) draw_sprite_state <= 2;
            end else begin
                draw_sprite_state <= 1;
            end
        end
    endcase
    // For safety, if the sprite buffer is not scanned fully at the line end.
    // Should be safe, as the maximum number of visible sprites/scanline most probably surpassed already
    // (TODO: investigate this limit on the original HW, and stop scanning when it's reached)
    if (hc == 0) draw_sprite_state <= 0;
end

////// TILEMAP LAYERS
reg        bg_enable;
reg        fg_enable;
reg        tx_enable;
reg        sp_enable;

reg [15:0] bg_scroll_x;
reg [15:0] bg_scroll_y;

wire [9:0] tx_x;
wire [9:0] tx_y;

wire [9:0] tile_x_ofs = 10'd85;
wire [9:0] y_adj = ( pcb > 3 && pcb < 8 ) ? 10'd0 : 10'd8 ;

always @ (*) begin
    if ( pcb == 2 || pcb == 3 ) begin
        tx_x <= hc + tile_x_ofs;
        tx_y <= vc - y_adj ;
    end else begin
        tx_x <= hc - ( tile_x_ofs - 10'd42 );
        tx_y <= vc - y_adj ;
    end
end

// layer 1 / gfx3
wire  [9:0] bg_x = hc + bg_scroll_x[9:0] + tile_x_ofs /* synthesis keep */; //ok
wire  [9:0] bg_y = vc + bg_scroll_y[9:0] - y_adj ; 

// layer 2 / gfx2
wire  [9:0] fg_x = hc + fg_scroll_x[9:0] + tile_x_ofs ; //ok
wire  [9:0] fg_y = vc + fg_scroll_y[9:0] - y_adj ; 

// layer 3 / gfx1
reg   [7:0] gfx_txt_attr_latch;
reg   [7:0] gfx_txt_attr_latch2;
reg   [7:0] gfx_txt_attr_latch3;
reg         gfx_txt_attr_prio;

reg  [15:0] gfx_bg_latch;
reg  [15:0] gfx_fg_latch;
reg  [15:0] gfx_bg_latch2;
reg  [15:0] gfx_fg_latch2;

reg  [10:0] bg_pal_addr ;
reg  [10:0] fg_pal_addr ;
reg  [10:0] tx_pal_addr ;

always @ (posedge clk_24M) begin
    if ( reset == 1 ) begin

    end else if (clk6_en) begin

// background 0x3ff

        // tile #
        bg_ram_addr <=  { bg_x[9:4], bg_y[8:4] }; 

        // bitmap 
        if (bg_x[2:0] == 3'b111) begin // pipeline on char boundary
            gfx_bg_latch  <= bg_ram_dout;
            gfx_bg_latch2 <= gfx_bg_latch;
            gfx3_addr     <= { bg_ram_dout[9:0], bg_y[3:0], bg_x[3:1] };
        end

        // palette
        bg_pal_addr <=  11'h600 + { gfx_bg_latch2[15:11] , ~bg_x[0]  ? gfx3_dout[3:0] : gfx3_dout[7:4] };

// foreground 0x7ff

        fg_ram_addr <=  { fg_x[9:4], fg_y[8:4] };

        if (fg_x[2:0] == 3'b111) begin  // pipeline on char boundary
            gfx2_addr     <= { fg_ram_dout[10:0], fg_y[3:0], fg_x[3:1] };
            gfx_fg_latch  <= fg_ram_dout;
            gfx_fg_latch2 <= gfx_fg_latch;
        end

        fg_pal_addr <= 11'h400 + { gfx_fg_latch2[15:11] , ~fg_x[0] ? gfx2_dout[3:0] : gfx2_dout[7:4] };


// text layer

        // read from two addresses at once
        if ( pcb == 0 || pcb == 8 || pcb == 9 || pcb == 1 || pcb == 4) begin
            // terra force and crazy climber 2
            gfx_txt_addr      <= { tx_x[8], 1'b0, ~tx_y[7:3], tx_x[7:3] } ;//{ 1'b0, t1[9:0] };
            gfx_txt_attr_addr <= { tx_x[8], 1'b1, ~tx_y[7:3], tx_x[7:3] } ; //{ 1'b1, t1[9:0] } ;
        end else if ( pcb == 2 || pcb == 3) begin
            // armed f / big fighter
            gfx_txt_addr      <= { 1'b0, tx_x[8:3], tx_y[7:3] } ; 
            gfx_txt_attr_addr <= { 1'b1, tx_x[8:3], tx_y[7:3] } ;
        end else if ( pcb == 5 || pcb == 6 || pcb == 7  ) begin
            // legion
            gfx_txt_addr      <= { tx_x[8], 1'b0, tx_x[7:3], tx_y[7:3] } ;
            gfx_txt_attr_addr <= { tx_x[8], 1'b1, tx_x[7:3], tx_y[7:3] } ;
        end

        if (tx_x[2:0] == 3'b011)
            gfx_txt_attr_latch  <= gfx_txt_dout;

        if (tx_x[2:0] == 3'b111) begin  // pipeline on char boundary
            gfx_txt_attr_latch2 <= gfx_txt_attr_latch;
            gfx_txt_attr_latch3 <= gfx_txt_attr_latch2;
            gfx1_addr           <= { gfx_txt_attr_latch[1:0], ( has_nb1414m4 == 0 || gfx_txt_addr > 12'h12 ) ? gfx_txt_dout[7:0] : 8'h0 , tx_y[2:0], tx_x[2:1] } ;  
        end

        tx_pal_addr <= { gfx_txt_attr_latch3[7:4] , ( ~tx_x[0] ? gfx1_dout[3:0] : gfx1_dout[7:4] ) };
        gfx_txt_attr_prio <= gfx_txt_attr_latch3[3];
    end
end


// Layer mux
reg draw_pix;
reg  [10:0] sprite_pal_ofs = 11'h200;
assign      sprite_fb_addr_r = { ~vc[0], hc[8:0] };
reg  [15:0] sprite_fb_out_r;

always @ (posedge clk_24M) begin
    if (clk6_en) begin
        draw_pix <= 0;
        sprite_fb_out_r <= sprite_fb_out;

        // 15 == transparent
        // lowest priority
        if ( gfx1_en == 1 && tx_enable == 1 && tx_pal_addr[3:0] != 15 ) begin
            tile_pal_addr <= tx_pal_addr;
            draw_pix <= 1;
        end

        // background
        if ( gfx3_en == 1 && bg_enable == 1 && bg_pal_addr[3:0] != 15 ) begin
            tile_pal_addr <= bg_pal_addr ;
            draw_pix <= 1;
        end

        // sprite priority 2
        if ( gfx4_en == 1 && sp_enable == 1 && sprite_fb_out_r[1:0] == 2 ) begin  
            tile_pal_addr <= ( sprite_pal_ofs + sprite_fb_out_r[10:2] ) ;
            draw_pix <= 1;
        end

        if ( gfx2_en == 1 && fg_enable == 1 && fg_pal_addr[3:0] != 15 ) begin
            tile_pal_addr <= fg_pal_addr ;
            draw_pix <= 1;
        end

        // sprite priority 1
        if ( gfx4_en == 1 && sp_enable == 1 && sprite_fb_out_r[1:0] == 1 ) begin 
            tile_pal_addr <= ( sprite_pal_ofs + sprite_fb_out_r[10:2] ) ;
            draw_pix <= 1;
        end

        // highest priority 
        if ( gfx1_en == 1 && tx_enable == 1 && tx_pal_addr[3:0] != 15 && !gfx_txt_attr_prio ) begin
            tile_pal_addr <=  tx_pal_addr;
            draw_pix <= 1;
        end

        // sprite priority 0
        if ( gfx4_en == 1 && sp_enable == 1 && sprite_fb_out_r[1:0] == 0 ) begin 
            tile_pal_addr <= ( sprite_pal_ofs + sprite_fb_out_r[10:2] ) ;
            draw_pix <= 1;
        end

        {r, g, b} <= 0;

        if ( draw_pix == 1 ) begin
            r <= tile_pal_dout[11:8];
            g <= tile_pal_dout[7:4];
            b <= tile_pal_dout[3:0];
        end
    end
end

//// ADDRESS DECODERS
wire    m68k_rom_cs;
wire    m68k_ram_cs;
wire    m68k_tile_pal_cs;
wire    m68k_txt_ram_cs;
wire    m68k_spr_cs;
wire    m68k_ram_2_cs;
wire    m68k_ram_3_cs;
wire    m68k_spr_pal_cs;
wire    m68k_fg_ram_cs;
wire    m68k_bg_ram_cs;
wire    input_p1_cs;
wire    input_p2_cs;
wire    input_dsw1_cs;
wire    input_dsw2_cs;
wire    irq_z80_cs;
wire    bg_scroll_x_cs;
wire    irq_i8751_cs;
wire    bg_scroll_y_cs;
wire    fg_scroll_x_cs;
wire    fg_scroll_y_cs;
wire    sound_latch_cs;
wire    irq_ack_cs;

wire    z80_a_rom_cs;
wire    z80_a_ram_cs;

wire    z80_a_sound0_cs;
wire    z80_a_sound1_cs;
wire    z80_a_dac1_cs;
wire    z80_a_dac2_cs;
wire    z80_a_latch_clr_cs;
wire    z80_a_latch_r_cs;

chip_select cs (
    .pcb(pcb),

    // 68k bus
    .m68k_a(m68k_a),
    .m68k_as_n(m68k_as_n),
    .m68k_uds_n(m68k_uds_n),
    .m68k_lds_n(m68k_lds_n),

    // 68k chip selects
    .m68k_rom_cs(m68k_rom_cs),
    .m68k_ram_cs(m68k_ram_cs),
    .m68k_tile_pal_cs(m68k_tile_pal_cs),
    .m68k_txt_ram_cs(m68k_txt_ram_cs),
    .m68k_spr_cs(m68k_spr_cs),
    .m68k_ram_2_cs(m68k_ram_2_cs),
    .m68k_ram_3_cs(m68k_ram_3_cs),
    .m68k_spr_pal_cs(m68k_spr_pal_cs),
    .m68k_fg_ram_cs(m68k_fg_ram_cs),
    .m68k_bg_ram_cs(m68k_bg_ram_cs),
    .input_p1_cs(input_p1_cs),
    .input_p2_cs(input_p2_cs),
    .input_dsw1_cs(input_dsw1_cs),
    .input_dsw2_cs(input_dsw2_cs),
    .irq_z80_cs(irq_z80_cs),
    .bg_scroll_x_cs(bg_scroll_x_cs),
    .bg_scroll_y_cs(bg_scroll_y_cs),
    .fg_scroll_x_cs(fg_scroll_x_cs),
    .fg_scroll_y_cs(fg_scroll_y_cs),
    .sound_latch_cs(sound_latch_cs),
    .irq_ack_cs(irq_ack_cs),
    .irq_i8751_cs(irq_i8751_cs),

    // sound z80 bus
    .z80_addr(z80_a_addr),
    .RFSH_n(RFSH_a_n),
    .MREQ_n(MREQ_a_n),
    .IORQ_n(IORQ_a_n),
    .M1_n(M1_a_n),

    .z80_rom_cs(z80_a_rom_cs),
    .z80_ram_cs(z80_a_ram_cs),

    .z80_sound0_cs(z80_a_sound0_cs),
    .z80_sound1_cs(z80_a_sound1_cs),
    .z80_dac1_cs(z80_a_dac1_cs),
    .z80_dac2_cs(z80_a_dac2_cs),
    .z80_latch_clr_cs(z80_a_latch_clr_cs),
    .z80_latch_r_cs(z80_a_latch_r_cs)
);
 
/// NB1414M4 custom chip
reg         nb1414m4_busy;
reg  [7:0]  nb1414m4_cmd_state;
reg  [3:0]  nb1414m4_dma_state;
reg         nb1414m4_wr;
reg         nb1414m4_erase;
reg  [15:0] nb1414m4_cmd;
reg  [15:0] nb1414m4_next_cmd;
reg  [14:0] nb1414m4_cmd_addr;
reg  [14:0] nb1414m4_cmd_src;
reg  [13:0] nb1414m4_src;
reg  [13:0] nb1414m4_dst; // might need to change
reg  [13:0] nb1414m4_dst_attr;
reg  [13:0] nb1414m4_idx;
reg  [13:0] nb1414m4_dma_size;
reg  [4:0]  nb1414m4_frame;
reg         nb1414m4_use_buffer;
reg  [7:0]  nb1414m4_buffer[15:0];

reg  [13:0] nb1414m4_address;
wire [7:0]  nb1414m4_dout;
wire [7:0]  nb1414m4_din;
wire [7:0]  nb1414m4_tile;
wire [7:0]  nb1414m4_pal;
reg  [7:0]  nb1414m4_credits;
reg [23:0]  nb1414m4_p1;
reg [23:0]  nb1414m4_p2;

wire has_nb1414m4 = ( pcb < 6 && pcb != 2 && pcb != 3);
//	dst = (m_data[0x330 + ((mcu_cmd & 0xf) * 2)] << 8) | (m_data[0x331 + ((mcu_cmd & 0xf) * 2)] & 0xff);
//	dst &= 0x3fff;

always @ (posedge clk_24M) begin
    if ( reset == 1 ) begin
        nb1414m4_cmd_state <= 0;
        nb1414m4_dma_state <= 0;
        nb1414m4_wr <= 0;
        nb1414m4_erase <= 0;
        nb1414m4_use_buffer <= 0;
    end else if ( nb1414m4_busy == 1 ) begin
        // 0x200 command
        // default to draw

        if ( nb1414m4_cmd[15:8] == 8'h02 ) begin
            // 200 command
            // lookup dst in m4 rom table. index is part of command
            if ( nb1414m4_cmd_state == 0 ) begin
                nb1414m4_cmd_state <= 1;
                // setup read for high byte of destination
                // mcu_cmd & 0x87
                nb1414m4_address[13:0] <= 14'h330 + { nb1414m4_cmd[2:0], 1'b0 } ;
            end else if ( nb1414m4_cmd_state == 1 ) begin
                // need a cycle to read
                if (nb1414m4_dout_valid) nb1414m4_cmd_state <= 2;
            end else if ( nb1414m4_cmd_state == 2 ) begin
                // latch in high byte of source
                nb1414m4_src[13:8] <= nb1414m4_dout[5:0];
                // setup read for low byte of destination
                nb1414m4_address[13:0] <= 14'h331 + { nb1414m4_cmd[2:0], 1'b0 } ;
                nb1414m4_cmd_state <= 3;
            end else if ( nb1414m4_cmd_state == 3 ) begin
                // need a cycle to read
                if (nb1414m4_dout_valid) nb1414m4_cmd_state <= 4;
            end else if ( nb1414m4_cmd_state == 4 ) begin
                // latch in low byte of source
                nb1414m4_src[7:0] <= nb1414m4_dout[7:0];
                // start dma
                nb1414m4_cmd_state <= 5;
            end else if ( nb1414m4_cmd_state == 5 ) begin
                nb1414m4_idx <= 0;
                if ( nb1414m4_src[10:0] == 0 ) begin
                    // start after command data
                    // dma(src, 0x0000, 0x400, 1, vram);
                    nb1414m4_dma_size <= 14'h400;
                    nb1414m4_dst <= 0;
                    nb1414m4_dma_state <= 4'h1;
                    nb1414m4_cmd_state <= 8'h06 ;
                end else begin
                    //fill(0x0000, m_data[src], m_data[src + 1], vram);
                    nb1414m4_cmd_state <= 8'h90;
                end
            end else if ( nb1414m4_cmd_state == 8'h06 ) begin
                // wait for dma
                if ( nb1414m4_dma_state == 4'hf ) begin
                    // done
                    nb1414m4_cmd_state <= 8'hff;
                end
            end
        end if ( nb1414m4_cmd[15:8] == 8'h00 ) begin
            if ( nb1414m4_cmd_state == 0 ) begin
                // read credits
                nb1414m4_cmd_state <= 1;
                nb1414m4_use_buffer <= 0;

                // setup read for high byte of destination
                // mcu_cmd & 0x87
                // nb1414m4_address[13:0] <= 14'h00f ;
            end else if ( nb1414m4_cmd_state == 1 ) begin
                // need a cycle to read
                nb1414m4_cmd_state <= 2;
            end else if ( nb1414m4_cmd_state == 2 ) begin
                if ( nb1414m4_credits == 0 ) begin
                    // insert coin
                    nb1414m4_cmd_addr  <= 14'h001 ;
                    nb1414m4_cmd_src   <= 14'h003 ;
                    nb1414m4_dma_size  <= 14'h010 ;
                    nb1414m4_erase     <= nb1414m4_frame[4];
                    nb1414m4_cmd_state <=   8'h80 ;
                    nb1414m4_next_cmd  <=   8'h03 ;
                end else begin
                    // press start
                    nb1414m4_cmd_addr  <= 14'h049 ;
                    nb1414m4_cmd_src   <= 14'h04b ;
                    nb1414m4_dma_size  <= 14'h018 ;
                    nb1414m4_erase     <= 0;
                    nb1414m4_cmd_state <=   8'h80 ;
                    nb1414m4_next_cmd  <=   8'h03 ;
                end
            end else if ( nb1414m4_cmd_state == 8'h03 ) begin
                // credit
                nb1414m4_cmd_addr  <= 14'h023 ;
                nb1414m4_cmd_src   <= 14'h025 ;
                nb1414m4_dma_size  <= 14'h010 ;
                nb1414m4_erase     <= 0;
                nb1414m4_cmd_state <=   8'h80 ;
                nb1414m4_next_cmd  <=   8'h04 ;
            end else if ( nb1414m4_cmd_state == 8'h04 ) begin
                // default - skip to next if no credits?
                nb1414m4_cmd_state <=   8'h05 ;
                if ( nb1414m4_credits == 1 ) begin
                    // press 1 player
                    nb1414m4_cmd_addr  <= 14'h07b ;
                    nb1414m4_cmd_src   <= 14'h07d ;
                    nb1414m4_dma_size  <= 14'h018 ;
                    nb1414m4_erase     <= nb1414m4_frame[4];
                    nb1414m4_cmd_state <=   8'h80 ;
                    nb1414m4_next_cmd  <=   8'h05 ;
                end else if ( nb1414m4_credits > 1 ) begin
                    // press 1 or 2 players
                    nb1414m4_cmd_addr  <= 14'h0ad ;
                    nb1414m4_cmd_src   <= 14'h0af ;
                    nb1414m4_dma_size  <= 14'h018 ;
                    nb1414m4_erase     <= nb1414m4_frame[4];
                    nb1414m4_cmd_state <=   8'h80 ;
                    nb1414m4_next_cmd  <=   8'h05 ;
                end
            end else if ( nb1414m4_cmd_state == 8'h05 ) begin
                    nb1414m4_cmd_addr  <= 14'h045 ;
                    nb1414m4_cmd_src   <= 14'h045 ;
                    nb1414m4_dma_size  <= 14'h002 ;
                    nb1414m4_use_buffer <= 1;
                    nb1414m4_buffer[0] <= ( nb1414m4_credits[7:4] == 0 ) ? 8'h20 : { 4'h3, nb1414m4_credits[7:4] };
                    nb1414m4_buffer[1] <= { 4'h3, nb1414m4_credits[3:0] };
                    nb1414m4_erase     <= 0;
                    nb1414m4_cmd_state <=   8'h80 ;
                    nb1414m4_next_cmd  <=   8'hff ;  // done

//                    nb1414m4_cmd_state <=   8'h06 ;
            end

        end else if ( nb1414m4_cmd[15:8] == 8'h06 ) begin
            // service mode
        end else if ( nb1414m4_cmd[15:8] == 8'h0e ) begin
            // gameplay
            if ( nb1414m4_cmd_state == 0 ) begin
                // read credits
                nb1414m4_cmd_state <= 1;
                nb1414m4_use_buffer <= 0;

                // setup read for high byte of destination
                // mcu_cmd & 0x87
                // nb1414m4_address[13:0] <= 14'h00f ;
            end else if ( nb1414m4_cmd_state == 1 ) begin
                // need a cycle to read
                nb1414m4_cmd_state <= 2;
            end else if ( nb1414m4_cmd_state == 2 ) begin    
                // p1 score
                nb1414m4_cmd_addr  <= 14'h10d ;
                nb1414m4_cmd_src   <= 14'h107 ;
                nb1414m4_dma_size  <= 14'h008 ;
                nb1414m4_use_buffer <= 1;
                nb1414m4_erase     <= 0;
                nb1414m4_cmd_state <=   8'h80 ;
                nb1414m4_next_cmd  <=   8'h03 ;

                nb1414m4_buffer[0] <= { (nb1414m4_p1[23:20] == 0 ) ? 4'h2 : 4'h3, nb1414m4_p1[23:20] };
                nb1414m4_buffer[1] <= { (nb1414m4_p1[23:16] == 0 ) ? 4'h2 : 4'h3, nb1414m4_p1[19:16] };
                nb1414m4_buffer[2] <= { (nb1414m4_p1[23:12] == 0 ) ? 4'h2 : 4'h3, nb1414m4_p1[15:12] };
                nb1414m4_buffer[3] <= { (nb1414m4_p1[23:8]  == 0 ) ? 4'h2 : 4'h3, nb1414m4_p1[11:8] };
                nb1414m4_buffer[4] <= { (nb1414m4_p1[23:4]  == 0 ) ? 4'h2 : 4'h3, nb1414m4_p1[7:4] };
                nb1414m4_buffer[5] <= { (nb1414m4_p1[23:0]  == 0 ) ? 4'h2 : 4'h3, nb1414m4_p1[3:0] };
                nb1414m4_buffer[6] <=   (nb1414m4_p1[23:0]  == 0 ) ? 8'h20 : 8'h30;
                nb1414m4_buffer[7] <= 8'h30;

            end else if ( nb1414m4_cmd_state == 3 ) begin
                // high score
                nb1414m4_cmd_addr  <= 14'h0df ;
                nb1414m4_cmd_src   <= 14'h0e1 ;
                nb1414m4_dma_size  <= 14'h008 ;
                nb1414m4_erase     <= 0;
                nb1414m4_cmd_state <=   8'h80 ;
                nb1414m4_next_cmd  <=   8'h04 ;
            end else if ( nb1414m4_cmd_state == 4 )  begin
                // p1 message
                nb1414m4_cmd_addr  <= 14'h0fb ;
                nb1414m4_cmd_src   <= 14'h0fd ;
                nb1414m4_dma_size  <= 14'h008 ;
                nb1414m4_erase     <= ~nb1414m4_cmd[0] ;
                nb1414m4_cmd_state <=   8'h80 ;
                nb1414m4_next_cmd  <=   8'h05 ;
            end else if ( nb1414m4_cmd_state == 5 ) begin
                if ( nb1414m4_cmd[7] == 1 ) begin
                    // p2 message
                    nb1414m4_cmd_addr  <= 14'h117 ;
                    nb1414m4_cmd_src   <= 14'h119 ;
                    nb1414m4_dma_size  <= 14'h008 ;
                    nb1414m4_erase     <= ~nb1414m4_cmd[1] ;
                    nb1414m4_cmd_state <=   8'h80 ;
                    nb1414m4_next_cmd  <=   8'h06 ;
                end else begin
                    nb1414m4_cmd_state <=   8'h07 ;
                end
            end else if ( nb1414m4_cmd_state == 8'h06 ) begin
                // p2 score
                nb1414m4_cmd_addr  <= 14'h129 ;
                nb1414m4_cmd_src   <= 14'h123 ;
                nb1414m4_dma_size  <= 14'h008 ;
                nb1414m4_use_buffer <= 1;
                nb1414m4_erase     <= 0;
                nb1414m4_cmd_state <=   8'h80 ;
                nb1414m4_next_cmd  <=   8'h07 ;

                nb1414m4_buffer[0] <= { (nb1414m4_p2[23:20] == 0 ) ? 4'h2 : 4'h3, nb1414m4_p2[23:20] };
                nb1414m4_buffer[1] <= { (nb1414m4_p2[23:16] == 0 ) ? 4'h2 : 4'h3, nb1414m4_p2[19:16] };
                nb1414m4_buffer[2] <= { (nb1414m4_p2[23:12] == 0 ) ? 4'h2 : 4'h3, nb1414m4_p2[15:12] };
                nb1414m4_buffer[3] <= { (nb1414m4_p2[23:8]  == 0 ) ? 4'h2 : 4'h3, nb1414m4_p2[11:8] };
                nb1414m4_buffer[4] <= { (nb1414m4_p2[23:4]  == 0 ) ? 4'h2 : 4'h3, nb1414m4_p2[7:4] };
                nb1414m4_buffer[5] <= { (nb1414m4_p2[23:0]  == 0 ) ? 4'h2 : 4'h3, nb1414m4_p2[3:0] };
                nb1414m4_buffer[6] <=   (nb1414m4_p2[23:0]  == 0 ) ? 8'h20 : 8'h30;
                nb1414m4_buffer[7] <= 8'h30;
            end else if ( nb1414m4_cmd_state == 8'h07 ) begin  
                if ( nb1414m4_cmd[6] == 1 ) begin
                    // game over man
                    nb1414m4_cmd_addr  <= 14'h133 ;
                    nb1414m4_cmd_src   <= 14'h135 ;
                    nb1414m4_dma_size  <= 14'h010 ;
                    nb1414m4_erase     <= 0;
                    nb1414m4_cmd_state <=   8'h80 ;
                    nb1414m4_next_cmd  <=   8'hff ;
                end else begin
                    nb1414m4_cmd_state <=   8'hff ;
                end
            end
        end

        // show message
        if ( nb1414m4_cmd_state == 8'h80 ) begin
            nb1414m4_cmd_state <= 8'h81;
            // setup read for high byte of destination
            nb1414m4_address[13:0] <= nb1414m4_cmd_addr ;
        end else if ( nb1414m4_cmd_state == 8'h81 ) begin
            // need a cycle to read
            if (nb1414m4_dout_valid) nb1414m4_cmd_state <= 8'h82;
        end else if ( nb1414m4_cmd_state == 8'h82 ) begin
            // latch in high byte of source
            nb1414m4_dst[13:8] <= nb1414m4_dout[5:0];
            // setup read for low byte of destination
            nb1414m4_address[13:0] <= nb1414m4_cmd_addr + 1'd1 ;
            nb1414m4_cmd_state <= 8'h83;
        end else if ( nb1414m4_cmd_state == 8'h83 ) begin
            // need a cycle to read
            if (nb1414m4_dout_valid) nb1414m4_cmd_state <= 8'h84;
        end else if ( nb1414m4_cmd_state == 8'h84 ) begin
            nb1414m4_src <= nb1414m4_cmd_src;
            // latch in low byte of source
            nb1414m4_dst[7:0] <= nb1414m4_dout[7:0];
            // start dma
            nb1414m4_idx <= 0;
            nb1414m4_cmd_state <= 8'h85;
            // start a transfer
            nb1414m4_dma_state <= 4'h1;
        end else if ( nb1414m4_cmd_state == 8'h85 ) begin
            // wait until transfer is done
            if ( nb1414m4_dma_state == 4'hf ) begin
                nb1414m4_cmd_state <= nb1414m4_next_cmd ;
            end
        end

        // DMA transfer
        if ( nb1414m4_dma_state == 4'h1 ) begin 
            nb1414m4_dst_attr <= nb1414m4_dst + 14'h400;
            nb1414m4_dma_state <= 4'h2;
            nb1414m4_idx <= 0;
        end else if ( nb1414m4_dma_state == 4'h2 ) begin
            // start transfer
            nb1414m4_address <= nb1414m4_src + nb1414m4_idx;
            nb1414m4_wr <= 0;
            nb1414m4_dma_state <= 4'h3;
        end else if ( nb1414m4_dma_state == 4'h3 ) begin
            // read takes a cycle
            if (nb1414m4_dout_valid) nb1414m4_dma_state <= 4'h4;
        end else if ( nb1414m4_dma_state == 4'h4 ) begin
            if ( nb1414m4_use_buffer == 1 ) begin
                nb1414m4_din <= nb1414m4_buffer[nb1414m4_idx];
            end else if ( nb1414m4_erase == 0 ) begin
                nb1414m4_din <= nb1414m4_dout;
            end else begin
                nb1414m4_din <= 8'h20;
            end

            // address is valid.  clock in the read
            nb1414m4_dma_state <= 4'h5;
            // setup a write.  the data will be valid in the next clock
            // writes to shared ram at ofset nb1414m4_dst
            if ( nb1414m4_dst > 18 ) begin
                // only write if not in the command buffer
                nb1414m4_wr <= 1;
            end
        end else if ( nb1414m4_dma_state == 4'h5 ) begin
            nb1414m4_wr <= 0;
            // source data is valid.  write 
            // disable write
            // first 0x400 is char data, second 0x400 is attributes
            if ( nb1414m4_idx < (nb1414m4_dma_size-1) ) begin 
                if ( nb1414m4_dst > 18 ) begin
                    nb1414m4_wr <= 1;
                end

                nb1414m4_idx <= nb1414m4_idx + 1'd1;
                nb1414m4_dst <= nb1414m4_dst + 1'd1;

                nb1414m4_dma_state <= 4'h2;
            end else begin
                // done
                nb1414m4_idx <= 0;
                // start attributes
                nb1414m4_dst <= nb1414m4_dst_attr;
                nb1414m4_dma_state <= 4'h6;
            end
        end else if ( nb1414m4_dma_state == 4'h6 ) begin 
            // start attribute transfer
            if ( nb1414m4_erase == 0 ) begin
                nb1414m4_address <= nb1414m4_src + nb1414m4_dma_size + nb1414m4_idx;
            end else begin
                nb1414m4_address <= 14'h013;
            end
            nb1414m4_wr <= 0;
            nb1414m4_dma_state <= 4'h7;
        end else if ( nb1414m4_dma_state == 4'h7 ) begin
            // read takes a cycle
            if (nb1414m4_dout_valid) nb1414m4_dma_state <= 4'h8;
        end else if ( nb1414m4_dma_state == 4'h8 ) begin
            nb1414m4_din <= nb1414m4_dout;

            // address is valid.  clock in the read
            nb1414m4_dma_state <= 4'h9;
            // setup a write.  the data will be valid in the next clock
            // writes to shared ram at ofset nb1414m4_dst
            nb1414m4_wr <= 1;
        end else if ( nb1414m4_dma_state == 4'h9 ) begin
            nb1414m4_wr <= 0;
            // source data is valid.  write 
            // disable write
            // first 0x400 is char data, second 0x400 is attributes
            if ( nb1414m4_idx < (nb1414m4_dma_size-1) ) begin 

                nb1414m4_idx <= nb1414m4_idx + 1'd1;
                nb1414m4_dst <= nb1414m4_dst + 1'd1;

                nb1414m4_dma_state <= 4'h6;
            end else begin
                // done
                nb1414m4_wr <= 0;
                nb1414m4_use_buffer <= 0;
                nb1414m4_dma_state <= 4'hf;
            end

        end

        // fill
        if ( nb1414m4_cmd_state == 8'h90 ) begin 
            nb1414m4_wr <= 0;
            nb1414m4_dst <= 0;
            nb1414m4_idx <= 8'h0;
            nb1414m4_address[13:0] <= nb1414m4_src ;
            nb1414m4_cmd_state <= 8'h91;
        end else if ( nb1414m4_cmd_state == 8'h91 ) begin
            // need a cycle to read
            if (nb1414m4_dout_valid) nb1414m4_cmd_state <= 8'h92;
        end else if ( nb1414m4_cmd_state == 8'h92 ) begin
            nb1414m4_tile <= nb1414m4_dout;
            nb1414m4_address[13:0] <= nb1414m4_src + 1'd1;
            nb1414m4_cmd_state <= 8'h93;
        end else if ( nb1414m4_cmd_state == 8'h93 ) begin            
            if (nb1414m4_dout_valid) nb1414m4_cmd_state <= 8'h94;
        end else if ( nb1414m4_cmd_state == 8'h94 ) begin
            nb1414m4_pal <= nb1414m4_dout;
            nb1414m4_cmd_state <= 8'h95;
            nb1414m4_din <= nb1414m4_tile;
            if ( nb1414m4_dst > 18 ) begin
                nb1414m4_wr <= 1;
            end
        end else if ( nb1414m4_cmd_state == 8'h95 ) begin
            nb1414m4_wr <= 0;
            if ( nb1414m4_idx < 14'h7ff ) begin
                if ( nb1414m4_dst > 18 ) begin
                    nb1414m4_wr <= 1;
                end

                // increment write pos
                nb1414m4_dst <= nb1414m4_dst + 1'd1;
                // increment count
                nb1414m4_idx <= nb1414m4_idx + 1'd1;
                if ( nb1414m4_idx == 14'h400 ) begin
                    // switch to writing the txt pal value
                    nb1414m4_din <= nb1414m4_pal;
                end
            end else begin
                // done
                nb1414m4_cmd_state <= 8'hff;
            end
        end

        // reset state
        if ( nb1414m4_cmd_state == 8'hff ) begin
            nb1414m4_wr <= 0;
            nb1414m4_cmd_state <= 0;
            nb1414m4_dma_state <= 0;
            nb1414m4_erase <= 0 ;
        end
    end
end

/// M68K

// CPU outputs
wire m68k_rw         ;    // Read = 1, Write = 0
wire m68k_as_n       ;    // Address strobe
wire m68k_lds_n      ;    // Lower byte strobe
wire m68k_uds_n      ;    // Upper byte strobe
wire m68k_E;
wire [2:0] m68k_fc    ;   // Processor state
wire m68k_reset_n_o  ;    // Reset output signal
wire m68k_halted_n   ;    // Halt output

// CPU busses
wire [15:0] m68k_dout       ;
wire [23:0] m68k_a   /* synthesis keep */       ;
wire [15:0] m68k_din        ;
//assign m68k_a[0] = 1'b0;

// CPU inputs
wire m68k_dtack_n ;         // Data transfer ack (always ready)
reg  m68k_ipl0_n ;
reg  m68k_ipl1_n ;

wire reset_n;
wire m68k_vpa_n = !(m68k_fc == 3'b111); // autovector interrupts

// tell 68k to wait for valid data. 0=ready 1=wait
// always ack when it's not shared program/text ram
assign  m68k_dtack_n = m68k_rom_cs ? !m68k_rom_valid : 
                       (m68k_ram_cs | m68k_ram_2_cs | m68k_ram_3_cs) ? !m68k_ram_dtack :
                        m68k_txt_ram_cs ? !m68k_txt_ram_dtack :
//                        irq_z80_cs ? nb1414m4_busy : 
                        1'b0; 

// select cpu data input based on what is active 
assign   m68k_din =  m68k_rom_cs  ? m68k_rom_data :
                     m68k_ram_cs  ? ram68k_dout :
                     m68k_ram_2_cs ? ram68k_dout :
                     m68k_ram_3_cs ? ram68k_dout :
                     m68k_tile_pal_cs ? m68k_tile_pal_dout :
                     m68k_spr_cs  ? ram68k_sprite_dout :
                     m68k_spr_pal_cs ? m68k_spr_pal_dout :
                     m68k_txt_ram_cs ? { 8'h00, m68k_txt_attr_ram_dout } :
                     m68k_bg_ram_cs ? m68k_bg_ram_dout :
                     m68k_fg_ram_cs ? m68k_fg_ram_dout :
                     input_p1_cs ? p1 :
                     input_p2_cs ? p2 :
                     input_dsw1_cs ? {8'd0, dsw1} :
                     input_dsw2_cs ? {8'd0, dsw2} :
                     16'd0;
reg [1:0] vbl_sr;

fx68k fx68k (
    // input
    .clk(clk_24M),
    .enPhi1(clk8_en_p),
    .enPhi2(clk8_en_n),

    .extReset(reset),
    .pwrUp(reset),

    // output
    .eRWn(m68k_rw),
    .ASn( m68k_as_n),
    .LDSn(m68k_lds_n),
    .UDSn(m68k_uds_n),
    .E(),
    .VMAn(),
    .FC0(m68k_fc[0]),
    .FC1(m68k_fc[1]),
    .FC2(m68k_fc[2]),
    .BGn(),
    .oRESETn(m68k_reset_n_o),
    .oHALTEDn(m68k_halted_n),

    // input
    .VPAn( m68k_vpa_n ),
    .DTACKn( m68k_dtack_n ),
    .BERRn(1'b1), 
    .BRn(1'b1),  
    .BGACKn(1'b1),

    .IPL0n(m68k_ipl0_n),
    .IPL1n(m68k_ipl1_n),
    .IPL2n(1'b1),

    // busses
    .iEdb(m68k_din),
    .oEdb(m68k_dout),
    .eab(m68k_a[23:1])
);

reg scroll_msb;

always @ (posedge clk_24M) begin

    // both the 68k and the bootleg z80 write to the scroll registers
    // 68k writes
    if ( !m68k_rw ) begin
        if ( bg_scroll_x_cs == 1) begin
          bg_scroll_x <= m68k_dout[15:0];
        end else if ( bg_scroll_y_cs == 1) begin
          bg_scroll_y <= m68k_dout[15:0];
        end else if ( fg_scroll_y_cs == 1 ) begin 
            if ( pcb == 2 || pcb == 3) begin
                fg_scroll_y[9:0] <= m68k_dout[9:0];
            end else if ( pcb == 6 || pcb == 7 ) begin
                // legion bootlegs
                if ( m68k_a[7:0] == 8'h16 ) begin
                    fg_scroll_y[7:0] <= m68k_dout[7:0]; // b
                end else if ( m68k_a[7:0] == 8'h18 ) begin
                    fg_scroll_y[9:8] <= m68k_dout[1:0]; // c
                end 
            end else if ( pcb == 9 ) begin
                fg_scroll_y[7:0] <= m68k_dout[7:0];
                scroll_msb <= 1;
                // terrafb
            end
        end else if ( fg_scroll_x_cs == 1 ) begin  // && m68k_rw == 0
            if ( pcb == 2 || pcb == 3 ) begin
                fg_scroll_x[9:0] <= m68k_dout[9:0];
            end else if ( pcb == 6 || pcb == 7 ) begin
                // legion bootlegs

                if ( m68k_a[7:0] == 8'h1a ) begin
                    fg_scroll_x[7:0] <= m68k_dout[7:0];
                end else if ( m68k_a[7:0] == 8'h1c ) begin
                    fg_scroll_x[9:8] <= m68k_dout[1:0];
                end
            end else if ( pcb == 9 ) begin
                // terrafb
                if ( scroll_msb == 1 ) begin
                    fg_scroll_x[9:8] <= m68k_dout[5:4];
                    fg_scroll_y[9:8] <= m68k_dout[1:0];
                end else begin
                    fg_scroll_x[7:0] <= m68k_dout[7:0];
                end
            end
        end else if ( terrafb_fg_scroll_msb_w == 1 ) begin
            scroll_msb <= 0;
        end
    end

    if ( reset == 1 ) begin
    end else begin
        if ( pcb == 8 ) begin
            // bootleg z80 controls foreground scrolling
            if ( z80_b_fg_scroll_x_cs == 1 && z80_b_wr_n == 0 ) begin
                fg_scroll_x[7:0] <= z80_b_dout;
            end else if ( z80_b_fg_scroll_y_cs == 1 && z80_b_wr_n == 0 ) begin
                fg_scroll_y[7:0] <= z80_b_dout;
            end else if ( z80_b_fg_scroll_msb_cs == 1 && z80_b_wr_n == 0 ) begin
                fg_scroll_x[9:8] <= z80_b_dout[3:2];
                fg_scroll_y[9:8] <= z80_b_dout[1:0];
            end
         end
    end

    if ( reset == 1 ) begin
        m68k_ipl0_n  <= 1 ;
        m68k_ipl1_n  <= 1 ;
        z80_b_irq_n <= 1;
        bg_enable <= 1;
        fg_enable <= 1;
        sp_enable <= 1;
        tx_enable <= 1;
        nb1414m4_frame <= 0;
    end else begin

        vbl_sr <= { vbl_sr[0], vbl };

        if ( nb1414m4_cmd_state == 8'hff ) begin
            nb1414m4_busy <= 0;
        end

        // only a write to 0x07c00e clears to interrupt line
        if ( irq_ack_cs == 1 ) begin
            m68k_ipl0_n <= 1 ;
            m68k_ipl1_n <= 1 ;
        end else if ( irq_z80_cs == 1 ) begin
            //if (data & 0x4000 && ((m_vreg & 0x4000) == 0)) //0 -> 1 transition
            //    m_extra->set_input_line(0, HOLD_LINE);

            if ( has_nb1414m4 == 1 ) begin
                // nb1414m4
                if ( m68k_dout[14] == 1 ) begin 
                    // trigger nb1414m4 command handler
                    nb1414m4_busy <= 1;

                    fg_scroll_x[9:0] <= { nb_scroll_x_h[1:0], nb_scroll_x_l[7:0] };
                    fg_scroll_y[9:0] <= { nb_scroll_y_h[1:0], nb_scroll_y_l[7:0] };
                end
            end else begin
                if ( m68k_dout[14] == 1 ) begin 
                    z80_b_irq_n <= 0;
                end
            end
            bg_enable <= m68k_dout[11];
            fg_enable <= m68k_dout[10];
            sp_enable <= m68k_dout[9];
            tx_enable <= m68k_dout[8];

        end

        if ( M1_b_n == 0 && IORQ_b_n == 0 ) begin
            // z80 acknowledged so deassert
            z80_b_irq_n <= 1;
        end

        if ( vbl_sr == 2'b01 ) begin // rising edge
            // increment frame counter - used for flashing text
            nb1414m4_frame <= nb1414m4_frame + 1'd1;
            //  68k vbl interrupt
            if ( pcb == 4 || pcb == 5 || pcb == 6 || pcb == 7 ) begin
                m68k_ipl1_n <= 0;
            end else begin
                m68k_ipl0_n <= 0;
            end
        end 
    end
end

//	map(0x0c0000, 0x0c0000).w(FUNC(armedf_state::terrafb_fg_scroll_msb_arm_w)); 
wire terrafb_fg_scroll_msb_w = ( pcb == 9 && m68k_a[23:0] >= 24'h0c0000 && m68k_a[23:0] <= 24'h0c0001) & !m68k_as_n;
 
//Z80 AUDIO
wire          z80_a_rom_valid;
wire    [7:0] z80_a_rom_data;
wire    [7:0] z80_a_ram_data;

wire   [15:0] z80_a_addr;
reg     [7:0] z80_a_din;
wire    [7:0] z80_a_dout;

wire z80_a_wr_n;
wire z80_a_rd_n;
wire z80_a_wait_n = z80_a_rom_cs ? z80_a_rom_valid : 1'b1;
reg  z80_a_irq_n;

wire IORQ_a_n;
wire MREQ_a_n;
wire M1_a_n;
wire RFSH_a_n;

T80pa z80_a (
    .RESET_n    ( ~reset ),
    .CLK        ( clk_24M ),
    .CEN_p      ( clk4_en_p ),
    .CEN_n      ( clk4_en_n ),
    .WAIT_n     ( z80_a_wait_n ), 
    .INT_n      ( z80_a_irq_n ),  
    .NMI_n      ( 1'b1 ),
    .BUSRQ_n    ( 1'b1 ),
    .RD_n       ( z80_a_rd_n ),
    .WR_n       ( z80_a_wr_n ),
    .A          ( z80_a_addr ),
    .DI         ( z80_a_din  ),
    .DO         ( z80_a_dout ),
    // unused
    .DIRSET     ( 1'b0     ),
    .DIR        ( 212'b0   ),
    .OUT0       ( 1'b0     ),
    .RFSH_n     ( RFSH_a_n ),
    .IORQ_n     ( IORQ_a_n ),
    .M1_n       ( M1_a_n ), // for interrupt ack
    .BUSAK_n    (),
    .HALT_n     ( 1'b1 ),
    .MREQ_n     ( MREQ_a_n ),
    .Stop       (),
    .REG        ()
);

//Periodic IRQ generation
always @(posedge clk_24M) begin

    if ( reset == 1 ) begin
        z80_a_irq_n <= 1;
    end else if ( clk_ym_count == 9'h1ff ) begin // 4MHz/512
        z80_a_irq_n <= 0;
    end 

    // check for interrupt ack and deassert int
    if ( !M1_a_n && !IORQ_a_n ) begin
        z80_a_irq_n <= 1;
    end
end

always @(posedge clk_24M) begin

    if ( z80_a_rd_n == 0 ) begin 
        if ( z80_a_rom_cs ) begin
            z80_a_din <= z80_a_rom_data;
        end else if ( z80_a_ram_cs ) begin
            z80_a_din <= z80_a_ram_data;
        end else if ( z80_a_latch_r_cs ) begin
            z80_a_din <= sound_latch;
        end else begin
            z80_a_din <= 8'h00;
        end
    end

    if ( z80_a_wr_n == 0 ) begin
        if (z80_a_dac1_cs == 1 ) begin
            dac1 <= z80_a_dout;
        end else if (z80_a_dac2_cs == 1 ) begin
            dac2 <= z80_a_dout;
        end
    end
end

reg  [7:0] sound_latch;
always @(posedge clk_24M) begin
    if (reset) begin
        sound_latch <= 0;
    end else begin
        if (sound_latch_cs)
            sound_latch <= {m68k_dout[6:0],1'b1};
        if (z80_a_latch_clr_cs)
            sound_latch <= 0;
    end
end

// sound ic write enable
wire [7:0] opl_dout;
wire opl_irq_n;

reg signed [15:0] sample;

jtopl #(.OPL_TYPE(2)) opl
(
    .rst(reset),
    .clk(clk_24M),
    .cen(clk4_en_p),
    .din(z80_a_dout),
    .addr(z80_a_addr[0]),
    .cs_n(~( z80_a_sound0_cs | z80_a_sound1_cs )),
    .wr_n(z80_a_wr_n),
    .dout(opl_dout),
    .irq_n(opl_irq_n),
    .snd(sample),
    .sample()
);

// mix audio
assign audio_l = sample + ($signed({ ~dac1[7], dac1[6:0], 8'b0 }) >>> 1) + ($signed({ ~dac2[7], dac2[6:0], 8'b0 }) >>> 1) ;
assign audio_r = sample + ($signed({ ~dac1[7], dac1[6:0], 8'b0 }) >>> 1) + ($signed({ ~dac2[7], dac2[6:0], 8'b0 }) >>> 1) ;

reg [7:0] dac1;
reg [7:0] dac2;

///// Z80 BOOTLEG
wire          z80_b_rom_valid;
wire    [7:0] z80_b_rom_data;
wire    [7:0] z80_b_ram_dout;

wire   [15:0] z80_b_addr;
reg     [7:0] z80_b_din;
wire    [7:0] z80_b_dout;

wire z80_b_wr_n;
wire z80_b_rd_n;
wire z80_b_wait_n = z80_b_rom_cs ? z80_b_rom_valid : z80_b_ram_txt_cs ? z80_b_txt_ram_dtack : 1'b1;
reg  z80_b_irq_n;

wire IORQ_b_n;
wire MREQ_b_n;
wire M1_b_n;
wire RFSH_b_n;

reg [9:0] fg_scroll_x;
reg [9:0] fg_scroll_y;

T80pa z80_b (
    .RESET_n    ( ~reset & (pcb == 8) ),  // don't run if no bootleg cpu
    .CLK        ( clk_24M ),
    .CEN_p      ( clk4_en_p ),
    .CEN_n      ( clk4_en_n ),
    .WAIT_n     ( z80_b_wait_n ), // wait?
    .INT_n      ( z80_b_irq_n ),  // from 68k 7c000
    .NMI_n      ( 1'b1 ),
    .BUSRQ_n    ( 1'b1 ),
    .RD_n       ( z80_b_rd_n ),
    .WR_n       ( z80_b_wr_n ),
    .A          ( z80_b_addr ),
    .DI         ( z80_b_din  ),
    .DO         ( z80_b_dout ),
    // unused
    .DIRSET     ( 1'b0     ),
    .DIR        ( 212'b0   ),
    .OUT0       ( 1'b0     ),
    .RFSH_n     ( RFSH_b_n ),
    .IORQ_n     ( IORQ_b_n ),
    .M1_n       ( M1_b_n ), // for interrupt ack
    .BUSAK_n    (),
    .HALT_n     ( 1'b1 ),
    .MREQ_n     ( MREQ_b_n ),
    .Stop       (),
    .REG        ()
);


// bootleg protection hack 16k
wire z80_b_rom_cs          = ( !MREQ_b_n && RFSH_b_n && z80_b_addr[15:0]  < 16'h4000 );
// shared ram 4k
wire z80_b_ram_txt_cs      = ( !MREQ_b_n && RFSH_b_n && !(z80_b_wr_n & z80_b_rd_n) & z80_b_addr[15:0] >= 16'h4000 && z80_b_addr[15:0] < 16'h5000);
// 4k
wire z80_b_ram_1_cs        = ( !MREQ_b_n && RFSH_b_n && z80_b_addr[15:0] >= 16'h5000 && z80_b_addr[15:0] < 16'h6000);
// 2k
wire z80_b_ram_2_cs        = ( !MREQ_b_n && RFSH_b_n && z80_b_addr[15:0] >= 16'h8000 && z80_b_addr[15:0] < 16'h8800);

wire z80_b_fg_scroll_x_cs   = ( !IORQ_b_n && z80_b_addr[7:0] == 8'h00 );
wire z80_b_fg_scroll_y_cs   = ( !IORQ_b_n && z80_b_addr[7:0] == 8'h01 );
wire z80_b_fg_scroll_msb_cs = ( !IORQ_b_n && z80_b_addr[7:0] == 8'h02 );

always @ (posedge clk_24M) begin

    if ( z80_b_rd_n == 0 ) begin 
        if ( z80_b_rom_cs ) begin
            z80_b_din <= z80_b_rom_data;
        end else if ( z80_b_ram_txt_cs ) begin
            z80_b_din <= z80_b_ram_txt_dout;
        end else if ( z80_b_ram_1_cs ) begin
            z80_b_din <= z80_b_ram_1_dout;
        end else if ( z80_b_ram_2_cs ) begin
            z80_b_din <= z80_b_ram_2_dout;
        end else begin
            z80_b_din <= 8'h00;
        end
    end
end
// SHARED TEXT RAM ARBITER
reg shared_w;
reg [11:0] shared_addr;
reg  [7:0] shared_data;
wire [7:0] shared_dout;

// the text ram will need to be accessible from the 68k, bootleg z80, and nb1414m4
// for now hack in scrolling for nb1414m4

reg [7:0] nb_scroll_x_l;
reg [7:0] nb_scroll_x_h;
reg [7:0] nb_scroll_y_l;
reg [7:0] nb_scroll_y_h;

reg m68k_txt_ram_dtack;
reg z80_b_txt_ram_dtack;

localparam SHARE_TXT_IDLE = 0;
localparam SHARE_TXT_M68K_WAIT = 1;
localparam SHARE_TXT_M68K = 2;
localparam SHARE_TXT_Z80_WAIT = 3;
localparam SHARE_TXT_Z80 = 4;

reg [2:0] share_state;

always @ (posedge clk_24M) begin
    if ( reset == 1 ) begin
        nb1414m4_credits <= 0;
        nb1414m4_p1 <= 0;
        shared_w <= 0;
        m68k_txt_ram_dtack <= 0;
        z80_b_txt_ram_dtack <= 0;
        share_state <= SHARE_TXT_IDLE;
    end else begin
        shared_w <= 0;
        if (!m68k_txt_ram_cs)  m68k_txt_ram_dtack  <= 0;
        if (!z80_b_ram_txt_cs) z80_b_txt_ram_dtack <= 0;

        case (share_state)
        SHARE_TXT_IDLE:
            if ( has_nb1414m4 == 1 && nb1414m4_wr == 1 ) begin
                shared_addr <= nb1414m4_dst;
                shared_data <= nb1414m4_din;
                shared_w    <= 1;
            end
            else
            if (m68k_txt_ram_cs & !m68k_lds_n & !m68k_txt_ram_dtack) begin
                shared_addr <= m68k_a[12:1];
                shared_data <= m68k_dout[7:0];
                if (!m68k_rw) begin
                    shared_w <= 1;

                    case ( m68k_a[12:1] )
                        13'h00: nb1414m4_cmd[15:8] <= m68k_dout[7:0];
                        13'h01: nb1414m4_cmd[7:0]  <= m68k_dout[7:0];
                        13'h05: nb1414m4_p1[23:16] <= m68k_dout[7:0];
                        13'h06: nb1414m4_p1[15:8]  <= m68k_dout[7:0];
                        13'h07: nb1414m4_p1[7:0]   <= m68k_dout[7:0];
                        13'h08: nb1414m4_p2[23:16] <= m68k_dout[7:0];
                        13'h09: nb1414m4_p2[15:8]  <= m68k_dout[7:0];
                        13'h0a: nb1414m4_p2[7:0]   <= m68k_dout[7:0];
                        13'h0d: nb_scroll_x_l      <= m68k_dout[7:0];
                        13'h0e: nb_scroll_x_h      <= m68k_dout[7:0];
                        13'h0b: nb_scroll_y_l      <= m68k_dout[7:0];
                        13'h0c: nb_scroll_y_h      <= m68k_dout[7:0];
                    endcase
                    if ( m68k_a[23:0] == 24'h06801e )
                        nb1414m4_credits <= m68k_dout[7:0];

                end
                share_state <= SHARE_TXT_M68K_WAIT;
            end
            else
            if (z80_b_ram_txt_cs & !z80_b_txt_ram_dtack) begin
                shared_addr <= z80_b_addr[11:0];
                shared_data <= z80_b_dout;
                shared_w <= ~z80_b_wr_n;
                share_state <= SHARE_TXT_Z80_WAIT;
            end

        SHARE_TXT_M68K_WAIT:
            share_state <= SHARE_TXT_M68K;

        SHARE_TXT_M68K:
        begin
            m68k_txt_attr_ram_dout[7:0] <= shared_dout;
            m68k_txt_ram_dtack <= 1;
            share_state <= SHARE_TXT_IDLE;
        end

        SHARE_TXT_Z80_WAIT:
            share_state <= SHARE_TXT_Z80;

        SHARE_TXT_Z80:
        begin
            z80_b_ram_txt_dout <= shared_dout;
            z80_b_txt_ram_dtack <= 1;
            share_state <= SHARE_TXT_IDLE;
        end

        endcase
    end
end

/// I8751 MCU
wire [15:0] i8751_addr;
wire        i8751_ram_acc;
wire [15:0] i8751_ram_addr;
wire        i8751_ram_wr;
wire [7:0]  i8751_ram_dout;
wire [7:0]  i8751_rom_data;
reg  [7:0]  i8751_shared_ram_data ;

wire i8751_int0_n = ~irq_i8751_cs;

wire i8751_ioctl_wr = rom_download & ioctl_wr & (ioctl_addr >= 24'h170000) & (ioctl_addr < 24'h171000) ;

reg p0_o,p1_o,p2_o,p3_o;

jtframe_8751mcu #(.SYNC_INT(0), .DIVCEN(1)) i8751 (
    .rst( reset ),
    .clk( clk_24M ),
    .cen( clk8_en_p & (~i8751_ram_acc | i8751_ram_dtack) ),

    .int0n( i8751_int0_n ),
    .int1n( 1'b1 ),

    .p0_i( 8'hdf ),
    .p0_o( p0_o ),

    .p1_i( 8'hdf ),
    .p1_o( p1_o ),

    .p2_i( 0 ),
    .p2_o( p2_o ),

    .p3_i( 0 ),
    .p3_o( p3_o ),

    // shared ram
    .x_din( i8751_shared_ram_data ),
    .x_dout( i8751_ram_dout ),
    .x_addr( i8751_ram_addr ),
    .x_wr( i8751_ram_wr ),
    .x_acc( i8751_ram_acc ),

    // ROM programming
    .clk_rom( clk_96M ),
    .prog_addr( ioctl_addr[13:0] ),
    .prom_din( ioctl_dout ),
    .prom_we( i8751_ioctl_wr )
);

// SHARED M68K RAM ARBITER
reg         m68k_ram_req;
wire        m68k_ram_ack;
reg  [19:1] m68k_ram_a;
reg         m68k_ram_we;
wire [15:0] m68k_ram_dout;
reg  [15:0] m68k_ram_din;
reg   [1:0] m68k_ram_ds;

reg         m68k_ram_dtack;
reg         i8751_ram_dtack;

localparam M68K_RAM_IDLE = 0;
localparam M68K_RAM_M68K = 1;
localparam M68K_RAM_I8751 = 2;

reg [1:0] m68k_share_state;

always @ (posedge clk_24M) begin
    if ( reset == 1 ) begin
        m68k_ram_dtack <= 0;
        i8751_ram_dtack <= 0;
        m68k_share_state <= M68K_RAM_IDLE;
    end else begin
        if (!(m68k_ram_cs | m68k_ram_2_cs | m68k_ram_3_cs)) m68k_ram_dtack  <= 0;
        if (!i8751_ram_acc) i8751_ram_dtack <= 0;

        case (m68k_share_state)
        M68K_RAM_IDLE:
            if ((m68k_ram_cs | m68k_ram_2_cs | m68k_ram_3_cs) & !m68k_ram_dtack) begin
                m68k_ram_a <= m68k_a[19:1];
                m68k_ram_din <= m68k_dout;
                m68k_ram_we <= !m68k_rw;
                m68k_ram_ds <= {!m68k_uds_n, !m68k_lds_n};
                m68k_ram_req <= !m68k_ram_req;
                m68k_share_state <= M68K_RAM_M68K;
            end
            else
            if (i8751_ram_acc & !i8751_ram_dtack && pcb == 3) begin
                m68k_ram_a <= {6'b100000, i8751_ram_addr[13:1]};
                m68k_ram_din <= {i8751_ram_dout, i8751_ram_dout};
                m68k_ram_we <= i8751_ram_wr;
                m68k_ram_ds <= {~i8751_ram_addr[0], i8751_ram_addr[0]};
                m68k_ram_req <= !m68k_ram_req;
                m68k_share_state <= M68K_RAM_I8751;
            end

        M68K_RAM_M68K:
            if (m68k_ram_req == m68k_ram_ack) begin
                if (m68k_rw) ram68k_dout <= m68k_ram_dout;
                m68k_ram_dtack <= 1;
                m68k_share_state <= M68K_RAM_IDLE;
            end

        M68K_RAM_I8751:
            if (m68k_ram_req == m68k_ram_ack) begin
                if (!i8751_ram_wr) i8751_shared_ram_data <= i8751_ram_addr[0] ? m68k_ram_dout[7:0] : m68k_ram_dout[15:8];
                i8751_ram_dtack <= 1;
                m68k_share_state <= M68K_RAM_IDLE;
            end

        endcase
    end
end

//// RAMs/ROMs

reg  [7:0] z80_b_ram_txt_dout;
wire [7:0] z80_b_ram_1_dout;
wire [7:0] z80_b_ram_2_dout;

reg [16:0] gfx1_addr;
reg [17:0] gfx2_addr;
reg [16:0] gfx3_addr;
reg [16:0] gfx4_addr;

reg [7:0] gfx1_dout;
reg [7:0] gfx2_dout;
reg [7:0] gfx3_dout;
reg [7:0] gfx4_dout;

reg  [15:0] ram68k_dout;
wire [15:0] ram68k_sprite_dout;
wire [15:0] m68k_tile_pal_dout;

// main 68k sprite ram high
// 2kx16
dual_port_ram #(.LEN(2048)) sprite_ram_H (
    .clock_a ( clk_24M ),
    .address_a ( m68k_a[11:1] ),
    .wren_a ( !m68k_rw & m68k_spr_cs & !m68k_uds_n ),
    .data_a ( m68k_dout[15:8]  ),
    .q_a (  ram68k_sprite_dout[15:8] ),

    .clock_b ( clk_24M ),
    .address_b ( sprite_shared_addr ),
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( sprite_shared_ram_dout[15:8] )

    );

// main 68k sprite ram low
dual_port_ram #(.LEN(2048)) sprite_ram_L (
    .clock_a ( clk_24M ),
    .address_a ( m68k_a[11:1] ),
    .wren_a ( !m68k_rw & m68k_spr_cs & !m68k_lds_n ),
    .data_a ( m68k_dout[7:0]  ),
    .q_a ( ram68k_sprite_dout[7:0] ),

    .clock_b ( clk_24M ),
    .address_b ( sprite_shared_addr ),
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( sprite_shared_ram_dout[7:0] )
    );

reg  [10:0] fg_ram_addr;
wire [15:0] fg_ram_dout;

reg  [10:0] bg_ram_addr;
wire [15:0] bg_ram_dout;


wire [15:0] m68k_fg_ram_dout;

// foreground high
dual_port_ram #(.LEN(2048)) ram_fg_h (
    .clock_a ( clk_24M ),
    .address_a ( m68k_a[11:1] ),
    .wren_a ( !m68k_rw & m68k_fg_ram_cs & !m68k_uds_n ),
    .data_a ( m68k_dout[15:8]  ),
    .q_a ( m68k_fg_ram_dout[15:8] ),

    .clock_b ( clk_24M ),
    .address_b ( fg_ram_addr ),
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( fg_ram_dout[15:8] )

    );

// foreground low
dual_port_ram #(.LEN(2048)) ram_fg_l (
    .clock_a ( clk_24M ),
    .address_a ( m68k_a[11:1] ),
    .wren_a ( !m68k_rw & m68k_fg_ram_cs & !m68k_lds_n ),
    .data_a ( m68k_dout[7:0]  ),
    .q_a ( m68k_fg_ram_dout[7:0] ),

    .clock_b ( clk_24M ),
    .address_b ( fg_ram_addr ),
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( fg_ram_dout[7:0] )
    );

wire [15:0] m68k_bg_ram_dout;

// background high
dual_port_ram #(.LEN(2048)) ram_bg_h (
    .clock_a ( clk_24M ),
    .address_a ( m68k_a[11:1] ),
    .wren_a ( !m68k_rw & m68k_bg_ram_cs & !m68k_uds_n ),
    .data_a ( m68k_dout[15:8]  ),
    .q_a ( m68k_bg_ram_dout[15:8] ),

    .clock_b ( clk_24M ),
    .address_b ( bg_ram_addr ),
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( bg_ram_dout[15:8] )

    );

// background low
dual_port_ram #(.LEN(2048)) ram_bg_l (
    .clock_a ( clk_24M ),
    .address_a ( m68k_a[11:1] ),
    .wren_a ( !m68k_rw & m68k_bg_ram_cs & !m68k_lds_n ),
    .data_a ( m68k_dout[7:0]  ),
    .q_a ( m68k_bg_ram_dout[7:0] ),

    .clock_b ( clk_24M ),
    .address_b ( bg_ram_addr ),
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( bg_ram_dout[7:0] )
    );

reg [15:0] tile_pal_dout;
reg [10:0] tile_pal_addr;

// tile palette high
dual_port_ram #(.LEN(2048)) tile_pal_h (
    .clock_a ( clk_24M ),
    .address_a ( m68k_a[11:1] ),
    .wren_a ( !m68k_rw & m68k_tile_pal_cs & !m68k_uds_n ),
    .data_a ( m68k_dout[15:8]  ),
    .q_a ( m68k_tile_pal_dout[15:8]  ),

    .clock_b ( clk_24M ),
    .address_b ( tile_pal_addr ),
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( tile_pal_dout[15:8] )
    );

//  tile palette low
dual_port_ram #(.LEN(2048)) tile_pal_l (
    .clock_a ( clk_24M ),
    .address_a ( m68k_a[11:1] ),
    .wren_a ( !m68k_rw & m68k_tile_pal_cs & !m68k_lds_n ),
    .data_a ( m68k_dout[7:0]  ),
    .q_a ( m68k_tile_pal_dout[7:0] ),

    .clock_b ( clk_24M ),
    .address_b ( tile_pal_addr ),
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( tile_pal_dout[7:0] )
    );

wire [15:0] spr_pal_dout ;
wire [15:0] m68k_spr_pal_dout ;


// sprite pal lut high
dual_port_ram #(.LEN(2048)) spr_pal_h (
    .clock_a ( clk_24M ),
    .address_a ( m68k_a[11:1] ),
    .wren_a ( !m68k_rw & m68k_spr_pal_cs & !m68k_uds_n ),
    .data_a ( m68k_dout[15:8]  ),
    .q_a ( m68k_spr_pal_dout[15:8] ),

    .clock_b ( ~clk_24M ),
    .address_b ( spr_pal_addr ),
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( spr_pal_dout[15:8] )

    );

// sprite pal lut high
dual_port_ram #(.LEN(2048)) spr_pal_L (
    .clock_a ( clk_24M ),
    .address_a ( m68k_a[11:1] ),
    .wren_a ( !m68k_rw & m68k_spr_pal_cs & !m68k_lds_n ),
    .data_a ( m68k_dout[7:0]  ),
    .q_a (m68k_spr_pal_dout[7:0]),

    .clock_b ( ~clk_24M ),
    .address_b ( spr_pal_addr ),
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( spr_pal_dout[7:0] )
    );

reg  [8:0]  sprite_buffer_addr;  // 128 sprites
reg  [63:0] sprite_buffer_din;
wire [63:0] sprite_buffer_dout;
reg  sprite_buffer_w;

dual_port_ram #(.LEN(512), .DATA_WIDTH(64)) sprite_buffer (
    .clock_a ( clk_24M ),
    .address_a ( sprite_buffer_addr ),
    .wren_a ( 1'b0 ),
    .data_a ( ),
    .q_a ( sprite_buffer_dout ),

    .clock_b ( clk_24M ),
    .address_b ( sprite_buffer_addr ),
    .wren_b ( sprite_buffer_w ),
    .data_b ( sprite_buffer_din  ),
    .q_b( )

    );

reg          sprite_fb_w;
wire  [9:0]  sprite_fb_addr_w;
reg  [15:0]  sprite_fb_din;
wire [15:0]  sprite_fb_out;
wire  [9:0]  sprite_fb_addr_r;

// two line buffer for sprite rendering
dual_port_ram #(.LEN(1024), .DATA_WIDTH(16)) sprite_line_buffer_ram (
    .clock_a ( clk_24M ),
    .address_a ( sprite_fb_addr_w ),
    .wren_a ( sprite_fb_w ),
    .data_a ( sprite_fb_din ),
    .q_a ( ),

    .clock_b ( clk_24M ),
    .address_b ( sprite_fb_addr_r ),
    .wren_b ( clk6_en ), // clear the buffer after read with
    .data_b ( 16'd15 ),  // transparent color
    .q_b ( sprite_fb_out )
    );

reg  [11:0] gfx_txt_addr;
wire  [7:0] gfx_txt_dout;

reg  [11:0] gfx_txt_attr_addr;

wire  [7:0] m68k_txt_attr_ram_dout;

// text layer vram
dual_port_ram #(.LEN(4096)) txt_ram_0 (
    // 68k read and write txt ram
    .clock_a ( clk_24M ),
    .address_a ( shared_addr ),
    .wren_a ( shared_w ),
    .data_a ( shared_data ),
    .q_a ( shared_dout ),

    // tile render read txt tile # / attr
    .clock_b ( clk_24M ),
    .address_b ( tx_x[2] ? gfx_txt_addr : gfx_txt_attr_addr ),
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( gfx_txt_dout[7:0] )
    );

// audio CPU RAM
dual_port_ram #(.LEN(2048)) z80_a_ram (
    .clock_a ( clk_24M ),
    .address_a ( z80_a_addr[10:0] ),
    .wren_a ( z80_a_ram_cs & ~z80_a_wr_n ),
    .data_a ( z80_a_dout ),
    .q_a ( z80_a_ram_data )
    );

// z80 protection ram 1
dual_port_ram #(.LEN(4096)) z80_b_ram_1 (
    .clock_b ( clk_24M ),
    .address_b ( z80_b_addr[11:0] ),
    .wren_b ( z80_b_ram_1_cs & ~z80_b_wr_n ),
    .data_b ( z80_b_dout ),
    .q_b ( z80_b_ram_1_dout )
    );

// z80 protection ram 1
dual_port_ram #(.LEN(2048)) z80_b_ram_2 (
    .clock_b ( clk_24M ),
    .address_b ( z80_b_addr[10:0] ),
    .wren_b ( z80_b_ram_2_cs & ~z80_b_wr_n ),
    .data_b ( z80_b_dout ),
    .q_b ( z80_b_ram_2_dout )
    );


//// external memory (SDRAM)
wire [15:0] m68k_rom_data;
wire m68k_rom_valid;

reg  [17:2] sprite_rom_addr;
wire [31:0] sprite_rom_data;
reg sprite_rom_req;
wire sprite_rom_ack;

reg port1_req, port2_req;
always @(posedge clk_96M) begin
    if (rom_download) begin
        if (ioctl_wr) begin
            port1_req <= ~port1_req;
            port2_req <= ~port2_req;
        end
    end
end

wire [31:0] gfx1_q;
reg  [31:0] gfx1_r;
wire [31:0] gfx2_q;
reg  [31:0] gfx2_r;
wire [31:0] gfx3_q;
reg  [31:0] gfx3_r;

wire [15:0] cpu2_do;
assign      z80_a_rom_data = z80_a_addr[0] ? cpu2_do[7:0] : cpu2_do[15:8];

wire [15:0] cpu3_do;
assign      z80_b_rom_data = z80_b_addr[0] ? cpu3_do[7:0] : cpu3_do[15:8];

wire [15:0] cpu4_do;
wire        nb1414m4_dout_valid;
assign      nb1414m4_dout = nb1414m4_address[0] ? cpu4_do[7:0] : cpu4_do[15:8];

sdram #(CLKSYS) sdram
(
  .*,
  .init_n        ( pll_locked ),
  .clk           ( clk_96M    ),

  // Bank 0-1 ops
  .port1_a       ( ioctl_addr[23:1] ),
  .port1_req     ( port1_req ),
  .port1_ack     (),
  .port1_we      ( rom_download ),
  .port1_ds      ( {~ioctl_addr[0], ioctl_addr[0]} ),
  .port1_d       ( {ioctl_dout, ioctl_dout} ),
  .port1_q       (),

  // M68K
  .cpu1_rom_addr ( m68k_a[23:1]  ),
  .cpu1_rom_cs   ( m68k_rom_cs   ),
  .cpu1_rom_q    ( m68k_rom_data ),
  .cpu1_rom_valid( m68k_rom_valid),

  .cpu1_ram_req  ( m68k_ram_req  ),
  .cpu1_ram_ack  ( m68k_ram_ack  ),
  .cpu1_ram_addr ( m68k_ram_a    ),
  .cpu1_ram_we   ( m68k_ram_we   ),
  .cpu1_ram_d    ( m68k_ram_din  ),
  .cpu1_ram_q    ( m68k_ram_dout ),
  .cpu1_ram_ds   ( m68k_ram_ds   ),

  // Audio Z80
  .cpu2_addr     ( {5'h15, z80_a_addr[15:1]} ),
  .cpu2_rom_cs   ( z80_a_rom_cs  ),
  .cpu2_q        ( cpu2_do       ),
  .cpu2_valid    ( z80_a_rom_valid ),

  // Bootleg Z80
  .cpu3_addr     ( {5'h16, 2'b00, z80_b_addr[13:1]} ), // (ioctl_addr >= 24'h160000) & (ioctl_addr < 24'h164000) ;
  .cpu3_rom_cs   ( z80_b_rom_cs  ),
  .cpu3_q        ( cpu3_do       ),
  .cpu3_valid    ( z80_b_rom_valid ),

  // NB1414M4
  .cpu4_addr     ( {5'h18, 2'b00, nb1414m4_address[13:1]} ), // (ioctl_addr >= 24'h180000) & (ioctl_addr < 24'h184000)
  .cpu4_q        ( cpu4_do       ),
  .cpu4_valid    ( nb1414m4_dout_valid ),

  // Bank 2-3 ops
  .port2_a       ( ioctl_addr[23:1] ),
  .port2_req     ( port2_req ),
  .port2_ack     (),
  .port2_we      ( rom_download ),
  .port2_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
  .port2_d       ( {ioctl_dout, ioctl_dout} ),
  .port2_q       (),

  .gfx1_addr     ( {5'h14, 1'b0, gfx1_addr[14:2]} ), // (ioctl_addr >= 24'h140000) & (ioctl_addr < 24'h148000) ;
  .gfx1_q        ( gfx1_q ),

  .gfx2_addr     ( {3'b010, gfx2_addr[17:2]} ),      // (ioctl_addr >= 24'h080000) & (ioctl_addr < 24'h0b0000)
  .gfx2_q        ( gfx2_q ),

  .gfx3_addr     ( {4'b0110, gfx3_addr[16:2]} ),     // (ioctl_addr >= 24'h0c0000) & (ioctl_addr < 24'h0e0000)
  .gfx3_q        ( gfx3_q ),

  .sp_addr       ( {3'b100, sprite_rom_addr} ),      // (ioctl_addr >= 24'h100000) & (ioctl_addr < 24'h140000)
  .sp_req        ( sprite_rom_req   ),
  .sp_ack        ( sprite_rom_ack   ),
  .sp_q          ( sprite_rom_data  )
);

always @(posedge clk_24M) begin
    if (clk6_en) begin
        if (tx_x[2:0] == 3'b111) gfx1_r <= gfx1_q;
        if (fg_x[2:0] == 3'b111) gfx2_r <= gfx2_q;
        if (bg_x[2:0] == 3'b111) gfx3_r <= gfx3_q;
    end
end

always @(*) begin
    case (tx_x[2:1])
        2'b00: gfx1_dout = gfx1_r[ 7: 0];
        2'b01: gfx1_dout = gfx1_r[15: 8];
        2'b10: gfx1_dout = gfx1_r[23:16];
        2'b11: gfx1_dout = gfx1_r[31:24];
        default: ;
    endcase

    case (fg_x[2:1])
        2'b00: gfx2_dout = gfx2_r[ 7: 0];
        2'b01: gfx2_dout = gfx2_r[15: 8];
        2'b10: gfx2_dout = gfx2_r[23:16];
        2'b11: gfx2_dout = gfx2_r[31:24];
        default: ;
    endcase

    case (bg_x[2:1])
        2'b00: gfx3_dout = gfx3_r[ 7: 0];
        2'b01: gfx3_dout = gfx3_r[15: 8];
        2'b10: gfx3_dout = gfx3_r[23:16];
        2'b11: gfx3_dout = gfx3_r[31:24];
        default: ;
    endcase

end

endmodule
