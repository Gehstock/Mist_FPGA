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

module Alpha68k
(
    input         pll_locked,
    input         clk_sys, // 72 MHz
    input         reset,
    input   [3:0] pcb,
    input   [7:0] brd,

    input         flip_in,
    output        flipped,

    input   [7:0] p1,
    input   [7:0] p2,
    input   [7:0] dsw_m68k,
    input   [7:0] dsw_sp85,
    input         coin_a,
    input         coin_b,
    input  [11:0] rotary1,
    input  [11:0] rotary2,

    output        hbl,
    output        vbl,
    output        hsync,
    output        vsync,
    output  [7:0] r,
    output  [7:0] g,
    output  [7:0] b,

    output [15:0] audio_l,
    output [15:0] audio_r,

    input   [3:0] hs_offset,
    input   [3:0] vs_offset,
    input   [3:0] hs_width,
    input   [3:0] vs_width,

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

assign m68k_a[0] = 0;

wire flip = flip_in ^ scr_flip;
assign flipped = flip;

//-- board config 6 bits
//        00 = II
//        01 = III
//        11 = V
//mcu id  00 = don't care
//        01 = 0x8814
//        10 = 0x8512
//        11 = 0x8713
//coin     0 = 0x2222 / 1 = 0x2423
//invert   0 = input not inverted / 1 = inverted
wire [1:0] board_rev = brd[5:4];
wire [1:0] mcu_type  = brd[3:2]; 
wire       coin_type = brd[1];
wire       invert_in = brd[0];

localparam  CLKSYS=72;

reg [15:0] clk_fx68_count;
reg  [5:0] clk6_count;
reg  [7:0] clk358_count;
reg  [5:0] clk3_count;
reg [23:0] clk_io_count;

reg clk3_en;
reg clk358_en;
reg clk4_en_p, clk4_en_n;
reg clk6_en_p, clk6_en_n;
reg clk_fx68_en_p, clk_fx68_en_n;
reg clk_io_en;
always @(posedge clk_sys) begin
    if (reset) begin
        clk3_count <= 0;
        clk358_count <= 0;
        clk_fx68_count <= 0;
        clk_io_count <= 0;
        clk358_en <= 0;
        {clk6_en_p, clk6_en_n} <= 0;
        {clk_fx68_en_p, clk_fx68_en_n} <= 0;
        clk_io_en <= 0;
    end else begin
        clk3_count <= clk3_count + 1'd1;
        if (clk3_count == 23) begin
            clk3_count <= 0;
        end
        clk3_en <= clk3_count == 0;

        // M=9 / N=181 
        clk358_en <= 0;
        if ( clk358_count > 180 ) begin
            clk358_en <= 1;
            clk358_count <= clk358_count - 8'd171;
        end else begin
            clk358_count <= clk358_count + 8'd9;
        end

        clk6_count <= clk6_count + 1'd1;
        if (clk6_count == 11) clk6_count <= 0;
        clk6_en_p <= clk6_count == 0;
        clk6_en_n <= clk6_count == 5;

        if ( board_rev == 3 ) begin
            // 10 MHz
            clk_fx68_en_p <= 0;
            clk_fx68_count <= clk_fx68_count + 8'd10;
            if ( (clk_fx68_count + 8'd10) >= 72 ) begin
                clk_fx68_en_p <= 1 ;
                clk_fx68_count <= clk_fx68_count - (8'd72 - 8'd10);
            end
            clk_fx68_en_n <= clk_fx68_en_p;
        end else begin
            // 9MHZ
            clk_fx68_en_p <= clk_fx68_count == 0;
            clk_fx68_en_n <= clk_fx68_count == 4;
            clk_fx68_count <= clk_fx68_count + 1'd1;
            if ( clk_fx68_count == 7 ) begin 
                clk_fx68_count <= 0;
            end
        end

        clk_io_en <= clk_io_count == 0;
        clk_io_count <= clk_io_count + 1'd1;
        if ( clk_io_count == (pcb == GOLDMEDL ? 720000 : 4_666_234) ) begin // 100 Hz/15.4 Hz
            clk_io_count <= 0;
        end
    end
end

wire  [8:0] hc;
wire  [8:0] vc;
wire  [8:0] hcflip = !flip ? hc[8:0] : { hc[8], ~hc[7:0] };
wire  [8:0] vcflip = !flip ? vc : {vc[8], ~vc[7:0]};

video_timing video_timing (
    .clk(clk_sys),
    .clk_pix(clk6_en_p),
    .hc(hc),
    .vc(vc),
    .hs_offset(hs_offset),
    .vs_offset(vs_offset),
    .hs_width(hs_width),
    .vs_width(vs_width),
    .hbl_shift(board_rev == 3),
    .hbl(hbl),
    .vbl(vbl),
    .hsync(hsync),
    .vsync(vsync)
);

// foreground layer
wire  [9:0] fg_tile = { hcflip[7:3], vcflip[7:3] };
assign fg_ram_addr = { fg_tile, hc[0] };
reg   [4:0] fg_colour, fg_colour_d;
wire  [8:0] fg_x = hcflip;
wire  [8:0] fg_y = vcflip;
reg  [15:0] fg_ram_dout0, fg_ram_dout1;
reg  [15:0] fg_pix_data;
reg   [8:0] fg;

always @(posedge clk_sys) begin
    if (clk6_en_p) begin
        if (hc[0])
            fg_ram_dout1 <= fg_ram_dout;
        else
            fg_ram_dout0 <= fg_ram_dout;

        if ( board_rev == 3 ) begin
            if (fg_x[0] == ~flip) begin
                fg_rom_addr <= { tile_bank[2:0], fg_ram_dout0[7:0], ~fg_x[2], fg_x[1], fg_y[2:0] } ;
                fg_colour   <=   fg_ram_dout0[15:12];
                fg_pix_data <= fg_rom_addr[1] ? fg_rom_data[31:16] : fg_rom_data[15:0];
                fg_colour <= fg_ram_dout1[4:0];
                fg_colour_d <= fg_colour;
            end
            case ( fg_x[0] )
                0: fg <= { fg_colour, ~fg_rom_addr[0] ? fg_pix_data[11: 8] : fg_pix_data[3:0] };
                1: fg <= { fg_colour, ~fg_rom_addr[0] ? fg_pix_data[15:12] : fg_pix_data[7:4] };
            endcase
        end
        else
        begin
            if (fg_x[1:0] == ({2{flip}} ^ 2'b11)) begin
                fg_rom_addr <= { tile_bank[6:4], fg_ram_dout0[7:0], ~fg_x[2], fg_y[2:0], 1'b0 };
                fg_pix_data <= fg_rom_addr[1] ? fg_rom_data[31:16] : fg_rom_data[15:0];
                fg_colour <= fg_ram_dout1[4:0];
                fg_colour_d <= fg_colour;
            end
            case ( fg_x[1:0] )
                0: fg <= { fg_colour_d, fg_pix_data[12], fg_pix_data[8], fg_pix_data[4], fg_pix_data[0] };
                1: fg <= { fg_colour_d, fg_pix_data[13], fg_pix_data[9], fg_pix_data[5], fg_pix_data[1] };
                2: fg <= { fg_colour_d, fg_pix_data[14], fg_pix_data[10], fg_pix_data[6], fg_pix_data[2] };
                3: fg <= { fg_colour_d, fg_pix_data[15], fg_pix_data[11], fg_pix_data[7], fg_pix_data[3] };
            endcase
        end
    end
end

// sprite rendering into dual line buffers
reg   [4:0] sprite_state;
reg  [31:0] spr_pix_data;

wire  [8:0] sp_y    = vcflip + (flip ? -1'd1 : 1'd1);

reg   [7:0] sprite_colour;
reg  [14:0] sprite_tile_num;
reg         sprite_flip_x;
reg         sprite_flip_y;
reg   [1:0] sprite_group;
reg   [4:0] sprite_col;
reg   [7:0] sprite_col_x;
reg  [15:0] sprite_col_y;
reg   [8:0] sprite_col_idx;
reg   [8:0] spr_x_pos;
reg   [3:0] spr_x_ofs;
reg   [1:0] sprite_layer;

wire  [3:0] spr_pen = { spr_pix_data[ 8 + { 3 { sprite_flip_x } } ^ spr_x_ofs[2:0]], 
                        spr_pix_data[ 0 + { 3 { sprite_flip_x } } ^ spr_x_ofs[2:0]], 
                        spr_pix_data[24 + { 3 { sprite_flip_x } } ^ spr_x_ofs[2:0]], 
                        spr_pix_data[16 + { 3 { sprite_flip_x } } ^ spr_x_ofs[2:0]] }  ;

always @ (posedge clk_sys) begin
    if ( reset == 1 ) begin
        sprite_state <= 0;
    end else begin
        // sprites. -- need 3 sprite layers
        spr_buf_w <= 0;
        if ( sprite_state == 0 && hc == 0 ) begin
            // init
            sprite_state <= 22;
            sprite_layer <= 0;
            spr_x_pos <= 0;
        end else if ( sprite_state == 22 )  begin  
            // start
            case ( sprite_layer )
                0: begin
                        sprite_group <= 1;
                        sprite_col   <= 31;
                   end
                1: begin
                        sprite_group <= 2;
                        sprite_col   <= 0;
                   end
                2: begin
                        sprite_group <= 3;
                        sprite_col   <= 0;
                   end
                3: begin
                        sprite_group <= 1;
                        sprite_col   <= 0;
                   end
            endcase
            sprite_state <= 1;
        end else if ( sprite_state == 1 )  begin
            // setup x/y read
            sprite_ram_addr <= { sprite_col, 3'b0, sprite_group };
            sprite_state <= 2;
        end else if ( sprite_state == 2 )  begin
            sprite_state <= 3;
        end else if ( sprite_state == 3 )  begin
            sprite_col_x <= sprite_ram_dout[7:0];
            sprite_col_y <= sprite_ram_dout[23:8];
            if ( sprite_layer == 0 ) begin
                if ( flip == 0 ) begin
                    sprite_col_y <= sprite_ram_dout[23:8] - 1'd1;
                end else begin
                    sprite_col_y <= sprite_ram_dout[23:8] + 1'd1;
                end
            end
            sprite_state <= 5;
        end else if ( sprite_state == 5 )  begin
            // tile ofset from the top of the column
            sprite_col_idx <= sp_y + sprite_col_y[8:0] ;
            sprite_state <= 6;
        end else if ( sprite_state == 6 )  begin
            // setup sprite tile index/colour read
            sprite_ram_addr <= { sprite_group[1:0], sprite_col[4:0], sprite_col_idx[8:4] };
            sprite_state <= 7;
        end else if ( sprite_state == 7 ) begin
            sprite_state <= 8;
        end else if ( sprite_state == 8 ) begin
            if ( board_rev == 3 ) begin
                sprite_colour <= sprite_ram_dout[7:0] ; // 0xff
            end else begin
                sprite_colour <= sprite_ram_dout[6:0] ; // 0x7f
            end
            if ( pcb == SKYADV || pcb == SKYADVU ) begin
                sprite_flip_x   <= 1'b0;  
                sprite_flip_y   <= sprite_ram_dout[23] ;
                sprite_tile_num <= sprite_ram_dout[22:8] ; 
            end else if (  pcb == GANGWARS ) begin
                sprite_flip_x   <= sprite_ram_dout[23];
                sprite_flip_y   <= 1'b0;  // 0x8000
                sprite_tile_num <= sprite_ram_dout[22:8] ;
            end else begin                
                sprite_flip_x   <= sprite_ram_dout[22] ;
                sprite_flip_y   <= sprite_ram_dout[23] ;
                sprite_tile_num <= sprite_ram_dout[21:8] ;
            end
            spr_x_ofs <= 0;
            spr_x_pos <= { sprite_col_x[7:0], sprite_col_y[15] } ;
            sprite_state <= 10;
        end else if ( sprite_state == 10 )  begin    
            sprite_rom_addr <= { sprite_tile_num, ~sprite_flip_x,  sprite_flip_y ? ~sprite_col_idx[3:0] : sprite_col_idx[3:0] };

            sprite_rom_req <= ~sprite_rom_req;
            sprite_state <= 11;
        end else if ( sprite_state == 11 ) begin
            // wait for sprite bitmap data
            if ( sprite_rom_req == sprite_rom_ack ) begin
                // prefetch pix 8-15 from rom
                if (spr_x_ofs == 0) begin
                    sprite_rom_addr[4] <= ~sprite_rom_addr[4];
                    sprite_rom_req <= ~sprite_rom_req;
                end
                spr_pix_data <= sprite_rom_data;
                sprite_state <= 12 ;
            end
        end else if ( sprite_state == 12 ) begin                    
            spr_buf_addr_w <= { vc[0], spr_x_pos };

            spr_buf_w <= | spr_pen  ; // don't write if 0 - transparent

            spr_buf_din <= { sprite_colour, spr_pen };

            if ( spr_x_ofs < 15 ) begin
                spr_x_ofs <= spr_x_ofs + 1'd1;
                spr_x_pos <= spr_x_pos + 1'd1;

                // the second 8 pixel needs another rom read
                if ( spr_x_ofs == 7 ) begin
                    if (sprite_rom_req == sprite_rom_ack)
                        spr_pix_data <= sprite_rom_data;
                    else
                        sprite_state <= 11;
                end

            end else begin
                if ( sprite_col < 30 || (sprite_col < 31 && sprite_layer < 3) ) begin
                    sprite_col <= sprite_col + 1'd1;
                    sprite_state <= 1; 
                end else begin
                    if ( sprite_layer < 3 ) begin
                        sprite_layer <= sprite_layer + 1'd1;
                        sprite_state <= 22;  
                    end else begin
                        sprite_state <= 0;  
                    end
                end
            end
        end
    end
end
wire  [7:0] spr_offs = board_rev == 3 ? 8'd4 : 8'd8;
wire  [8:0] spr_pos = (flip ? spr_offs : -spr_offs) + hcflip;
assign      spr_buf_addr_r = { ~vc[0], spr_pos };
reg  [11:0] sp;
always @ (posedge clk_sys) if (clk6_en_p) sp <= spr_buf_dout[11:0];

// final color mix
wire [11:0] pen = ( { fg[8], fg[3:0] } == 0 ) ? sp[11:0] : { 3'b0, fg[7:0] };  //   fg[8] == 1 means tile is opaque 

// resistor dac 220, 470, 1k, 2.2k, 3.9k / has 8.2k pulldown for dimming (2nd block of 16)
wire [7:0] dac_weight[0:63] = '{8'd0,8'd13,8'd22,8'd34,8'd46,8'd57,8'd65,8'd75,8'd91,8'd100,8'd107,8'd116,8'd126,8'd134,8'd140,8'd148,
                                8'd168,8'd175,8'd180,8'd187,8'd194,8'd200,8'd205,8'd211,8'd220,8'd226,8'd230,8'd235,8'd241,8'd246,8'd250,8'd255,
                                // dim
                                8'd0, 8'd7,8'd17,8'd28,8'd41,8'd52,8'd60,8'd71,8'd87,8'd96,8'd103,8'd112,8'd122,8'd130,8'd136,8'd144,
                                8'd165,8'd172,8'd177,8'd184,8'd191,8'd197,8'd202,8'd208,8'd218,8'd223,8'd227,8'd233,8'd239,8'd244,8'd248,8'd253};
always @ (posedge clk_sys) begin
    if (clk6_en_p) begin
        if ( pen[3:0] == 0 ) begin
            if ( board_rev == 3 ) begin
                tile_pal_addr <= 12'hfff ; // background pen
            end else begin
                tile_pal_addr <= 12'h7ff ; // background pen
            end
        end else begin
            tile_pal_addr <= pen[11:0] ;
        end
        r <= dac_weight[r_pal];
        g <= dac_weight[g_pal];
        b <= dac_weight[b_pal];
    end
end

/// 68k cpu

reg scr_flip ;
reg [2:0] tile_offset;

assign m68k_dtack_n = m68k_rom_cs ? !m68k_rom_valid :
                      m68k_rom_2_cs ? !m68k_rom_valid :
                      m68k_ram_cs ? !m68k_ram_dtack :
                      1'b0;

assign m68k_din =  m68k_rom_cs ? m68k_rom_data :
                   m68k_ram_cs  ? m68k_ram_dout :
                   m68k_rom_2_cs ? m68k_rom_data :
                   // high byte of even addressed sprite ram not connected.  pull high.
                   (m68k_spr_cs & !m68k_a[1]) ? {8'hff, m68k_sprite_dout[7:0]} :
                   (m68k_spr_cs &  m68k_a[1]) ? {m68k_sprite_dout[23:8]} :
                   m68k_fg_ram_cs ? m68k_fg_ram_dout :
                   m68k_pal_cs ? m68k_pal_dout :
                   input_p1_cs ? {16{invert_in}} ^ { p2, p1 } :
                   m68k_dsw_cs ? { rotary1[7:0], invert_in ? ~dsw_m68k[7:0] : dsw_m68k[7:0] } :
                   m68k_sp85_cs ? 16'h0 : 
                   m68k_rotary2_cs ? { rotary2[7:0], 8'h0 } :
                   m68k_rotary_msb_cs ? { rotary2[11:8], rotary1[11:8], 8'h0 } :
                   16'h0000;

reg [7:0] tile_bank;
reg [1:0] vbl_sr;
reg [1:0] hbl_sr;

reg [7:0] credits;
reg [3:0] coin_count;
reg       coin_latch;

// Coin tables for games with MCU id 2222

// Time Soldiers, Sky Soldiers
reg [7:0] coin_ratio_a_II [0:7] = '{ 8'h01, 8'h02, 8'h03, 8'h04, 8'h05, 8'h06, 8'h13, 8'h22 };  // (#coins-1) / credits
reg [7:0] coin_ratio_b_II [0:7] = '{ 8'h01, 8'h11, 8'h21, 8'h31, 8'h41, 8'h51, 8'h61, 8'h71 };  // (#coins-1) / credits
   
// Sky Adventure
reg [7:0] coin_ratio_a_V [0:7] = '{ 8'h01, 8'h05, 8'h03, 8'h13, 8'h02, 8'h06, 8'h04, 8'h22 };  // (#coins-1) / credits
reg [7:0] coin_ratio_b_V [0:7] = '{ 8'h01, 8'h41, 8'h21, 8'h61, 8'h11, 8'h51, 8'h31, 8'h71 };  // (#coins-1) / credits

wire [7:0] coin_ratio_a = (board_rev != 3) ? coin_ratio_a_II[~dsw_sp85[2:0]] : coin_ratio_a_V[~dsw_sp85[3:1]];
wire [7:0] coin_ratio_b = (board_rev != 3) ? coin_ratio_b_II[~dsw_sp85[2:0]] : coin_ratio_b_V[~dsw_sp85[3:1]];

reg [12:0]  mcu_addr;
reg  [7:0]  mcu_din;
reg  [7:0]  mcu_dout;
reg         mcu_wh;
reg         mcu_wl;

reg         mcu_busy;
reg         mcu_2nd_write;
reg [12:0]  mcu_2nd_addr;
reg  [7:0]  mcu_2nd_din;
reg         mcu_2nd_wh;
reg         mcu_2nd_wl;

always @ (posedge clk_sys) begin

    if ( reset == 1 ) begin
        scr_flip <= 0;

        m68k_ipl0_n <= 1 ;
        m68k_ipl1_n <= 1 ;
        
        m68k_latch <= 0;
        tile_bank <= 0;
        
        mcu_addr <= 0;
        mcu_din <= 0 ;
        mcu_wh <= 0;
        mcu_wl <= 0;
                
        z80_nmi_n <= 1 ;
        z80_bank <= 0;
        
        credits <= 0;
        coin_latch <= 0;
        mcu_2nd_write <= 0;
        mcu_2nd_wl <= 0;
        mcu_2nd_wh <= 0;
        mcu_busy <= 0;
    end else begin
        // vblank handling 
        vbl_sr <= { vbl_sr[0], vbl };
        if ( vbl_sr == 2'b01 ) begin // rising edge
            //  68k vbl interrupt
            m68k_ipl0_n <= 0;
        end

        // mcu interrupt handling
        hbl_sr <= { hbl_sr[0], clk_io_en };
        if ( hbl_sr == 2'b01 ) begin // rising edge
            //  68k mcu interrupt
            m68k_ipl1_n <= 0;
        end
        if ( vbl_int_clr_cs == 1 ) begin
            m68k_ipl0_n <= 1;
        end

        if ( cpu_int_clr_cs == 1 ) begin
            m68k_ipl1_n <= 1;
        end

        if (m68k_mcu_dtack) begin
            mcu_wh <= 0;
            mcu_wl <= 0;
        end
        if (m68k_rw) begin
                // mcu addresses are word 
                if ( m68k_sp85_cs == 1 ) begin
                    if (  mcu_busy == 0 ) begin
                        mcu_busy <= 1;
                        if ( m68k_a[8:1] == 8'h00 ) begin
                            mcu_addr <= m68k_a[13:1];
                            mcu_din <= dsw_sp85[7:0] ;
                            mcu_wl <= 1;
                        end else if ( m68k_a[8:1] == 8'h22 ) begin
                            mcu_addr <= m68k_a[13:1];
                            mcu_din <= credits ;
                            credits <= 0;
                            mcu_wl <= 1;
                        end else if ( m68k_a[8:1] == 8'h29 ) begin

                            // coins
                            if ( { coin_b, coin_a } == 0 )
                                coin_latch <= 0;

                            if ( coin_latch == 0 && {coin_b, coin_a} != 0 ) begin
                                coin_latch <= 1;
                                // set coin id
                                if ( coin_type == 1 ) begin 
                                    if ( coin_a == 1 ) begin
                                        mcu_din <= 8'h23 ;
                                    end else begin
                                        mcu_din <= 8'h24 ;
                                    end
                                end else begin
                                    mcu_din <= 8'h22 ;
                                    // only games with coin id 22 needs a coin counter
                                    if ( coin_a == 1 ) begin
                                        // calc before or after invert?
                                        if ( coin_ratio_a[7:4] == coin_count ) begin
                                            credits <= coin_ratio_a[3:0];
                                            coin_count <= 0;
                                        end else begin
                                            coin_count <= coin_count + 1'd1;
                                        end
                                    end if ( coin_b == 1 ) begin 
                                        if ( coin_ratio_b[7:4] == coin_count ) begin
                                            credits <= coin_ratio_b[3:0];
                                            coin_count <= 0;
                                        end else begin
                                            coin_count <= coin_count + 1'd1;
                                        end
                                    end

                                    // clear for sky adv
                                    mcu_2nd_write <= 1;
                                    mcu_2nd_addr  <= m68k_a[13:1] - 3'd7 ;
                                    mcu_2nd_din   <= 0 ;
                                    mcu_2nd_wl    <= 1;
                                end
                                mcu_addr <= m68k_a[13:1];
                                mcu_wl <= 1;
                            end else begin
                                mcu_addr <= m68k_a[13:1];
                                mcu_din <= pcb == GOLDMEDL ? 8'h21 : 8'h00;
                                mcu_wl <= 1;
                            end

                            // if gang wars trigger writing the dip value to ram
                            if ( pcb == GANGWARS ) begin
                                mcu_2nd_write <= 1;
                                mcu_2nd_addr  <= 13'h0163 ;
                                mcu_2nd_din   <= dsw_sp85[7:0] ;
                                mcu_2nd_wh    <= 1;
                            end
                        end else if ( m68k_a[8:1] == 8'hfe ) begin
                            // mcu id hign - gang wars 8512
                            mcu_addr <= m68k_a[13:1];
                            mcu_wl <= 0;
                            if ( mcu_type == 2'b01 ) begin
                                mcu_din <= 8'h88 ;
                                mcu_wl <= 1;
                            end else if ( mcu_type == 2'b10 ) begin
                                mcu_din <= 8'h85 ;
                                mcu_wl <= 1;
                            end else if ( mcu_type == 2'b11 ) begin
                                mcu_din <= 8'h87 ;
                                mcu_wl <= 1;
                            end
                        end else if ( m68k_a[8:1] == 8'hff ) begin
                            // mcu id low
                            mcu_addr <= m68k_a[13:1];
                            mcu_wl <= 0;
                            if ( mcu_type == 2'b01 ) begin
                                mcu_din <= 8'h14 ;
                                mcu_wl <= 1;
                            end else if ( mcu_type == 2'b10 ) begin
                                mcu_din <= 8'h12 ;
                                mcu_wl <= 1;
                            end else if ( mcu_type == 2'b11 ) begin
                                mcu_din <= 8'h13 ;
                                mcu_wl <= 1;
                            end
                        end
                    end
                end else begin
                    mcu_busy <= 0;
                end

                if ( !mcu_wl & !mcu_wh & mcu_2nd_write & !m68k_mcu_dtack ) begin
                    mcu_addr <= mcu_2nd_addr; 
                    mcu_din <= mcu_2nd_din ;
                    mcu_wl <= mcu_2nd_wl;
                    mcu_wh <= mcu_2nd_wh;

                    mcu_2nd_write <= 0;
                    mcu_2nd_wl <= 0;
                    mcu_2nd_wh <= 0;
                end

        end else begin        
                // writes
                if ( m68k_sp85_cs == 1 ) begin
                    if ( m68k_lds_n == 0 && m68k_a[8:1] == 8'h2d ) scr_flip <= m68k_dout[0];
                end

                if ( m68k_latch_cs == 1 ) begin
                    // text tile banking
                    if ( m68k_uds_n == 0 && board_rev == 3) begin // UDS 0x80000 only Rev V
                        tile_bank <= m68k_dout[11:8] ;
                    end 
                    if ( m68k_lds_n == 0 ) begin // LDS 0x80001
                        m68k_latch <= m68k_dout[7:0]; 
                    end
                end

                if ( m68k_lds_n == 0 && m68k_dsw_cs == 1 ) begin // LDS 0xc00xx
                    if  ( board_rev != 3 ) begin
                        tile_bank[m68k_a[5:3]] <= m68k_a[6] ;  // 
                    end
                end
        end

        if ( z80_wr_n == 0 ) begin 

            // DAC
            if ( z80_dac_cs == 1 ) begin
                dac <= z80_dout ;
            end

            if ( z80_latch_clr_cs == 1 ) begin
                m68k_latch <= 0 ;
            end

            if ( z80_bank_set_cs == 1 ) begin
                 z80_bank <= z80_dout[4:0];
            end
        end
        // ym2203 can disable z80 nmi by writting 1 to bit 0 of portA
        // if enabled, nmi is triggered by falling edge of bit 0 vertical line count
        // /NMI is negative edge triggered
        z80_nmi_n <= (~vc[0]) | ym2203_IOA[0] | ~ym2203_OE;
    end
end

wire    m68k_rom_cs;
wire    m68k_rom_2_cs;
wire    m68k_ram_cs;
wire    m68k_pal_cs;
wire    m68k_spr_cs;
wire    m68k_fg_ram_cs;
wire    m68k_spr_flip_cs;
wire    input_p1_cs;
wire    m68k_rotary2_cs;
wire    m68k_rotary_msb_cs;
wire    m68k_dsw_cs;
wire    irq_z80_cs;
wire    m68k_latch_cs;
wire    z80_latch_read_cs;
wire    vbl_int_clr_cs;
wire    cpu_int_clr_cs;
wire    watchdog_clr_cs;
wire    m68k_sp85_cs;
wire    m68k_ipl0_ack;
wire    m68k_ipl1_ack;

wire    z80_rom_cs;
wire    z80_ram_cs;
wire    z80_banked_cs;
    
wire    z80_latch_cs;
wire    z80_latch_clr_cs;
wire    z80_dac_cs;
wire    z80_ym2413_cs;
wire    z80_ym2203_cs;
wire    z80_bank_set_cs;
  
chip_select cs (
    .pcb(pcb),

    // 68k bus
    .m68k_a(m68k_a),
    .m68k_as_n(m68k_as_n),
    .m68k_rw(m68k_rw),
    .m68k_uds_n(m68k_uds_n),
    .m68k_lds_n(m68k_lds_n),

    .z80_addr(z80_addr),
    .MREQ_n(MREQ_n),
    .IORQ_n(IORQ_n),
    .M1_n(M1_n),
    .RFSH_n(RFSH_n),
    .RD_n( z80_rd_n ),
    .WR_n( z80_wr_n ),
   
    // 68k chip selects
    .m68k_rom_cs,
    .m68k_rom_2_cs,
    .m68k_ram_cs,
    .m68k_spr_cs,
    .m68k_sp85_cs,
    .m68k_fg_ram_cs,
    .m68k_pal_cs,

    .m68k_rotary2_cs,
    .m68k_rotary_msb_cs,

    .input_p1_cs,
    .m68k_dsw_cs,

    // interrupt clear & watchdog
    .vbl_int_clr_cs,
    .cpu_int_clr_cs,
    .watchdog_clr_cs,

    .m68k_latch_cs, // write commands to z80 from 68k
    
    // z80 

    .z80_rom_cs,
    .z80_ram_cs,
    .z80_banked_cs, 
    
    .z80_latch_cs,
    .z80_latch_clr_cs,
    .z80_dac_cs,
    .z80_ym2413_cs,
    .z80_ym2203_cs,
    .z80_bank_set_cs 

);

reg   [7:0] m68k_latch;

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
reg  [15:0] m68k_din        ;   
//assign m68k_a[0] = 1'b0;

// CPU inputs
reg  m68k_dtack_n;
reg  m68k_ipl0_n;
reg  m68k_ipl1_n;

wire m68k_vpa_n = ~int_ack;

wire int_ack = !m68k_as_n && m68k_fc == 3'b111;

fx68k fx68k (
    // input
    .clk(clk_sys),
    .enPhi1(clk_fx68_en_p),
    .enPhi2(clk_fx68_en_n),

    .extReset(reset),
    .pwrUp(reset),

    // output
    .eRWn(m68k_rw),
    .ASn(m68k_as_n),
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

// z80 audio 
wire    [7:0] z80_rom_data;
wire    [7:0] z80_ram_data;
wire    [7:0] z80_banked_data;

wire   [15:0] z80_addr;
reg     [7:0] z80_din;
wire    [7:0] z80_dout;

wire z80_wr_n;
wire z80_rd_n;
wire z80_wait_n;
reg  z80_nmi_n;

wire IORQ_n;
wire MREQ_n;
wire M1_n;
wire RFSH_n;

T80pa z80 (
    .RESET_n    ( ~reset  ),
    .CLK        ( clk_sys ),
    .CEN_p      ( clk6_en_p ),
    .CEN_n      ( clk6_en_n ),
    .WAIT_n     ( z80_wait_n ), // z80_wait_n
    .INT_n      ( 1'b1     ),
    .NMI_n      ( z80_nmi_n ),
    .BUSRQ_n    ( 1'b1 ),
    .RD_n       ( z80_rd_n ),
    .WR_n       ( z80_wr_n ),
    .A          ( z80_addr ),
    .DI         ( z80_din  ),
    .DO         ( z80_dout ),
    // unused
    .DIRSET     ( 1'b0     ),
    .DIR        ( 212'b0   ),
    .OUT0       ( 1'b0     ),
    .RFSH_n     ( RFSH_n   ),
    .IORQ_n     ( IORQ_n   ),
    .M1_n       ( M1_n     ), // for interrupt ack
    .BUSAK_n    (),
    .HALT_n     ( 1'b1 ),
    .MREQ_n     ( MREQ_n   ),
    .Stop       (),
    .REG        ()
);

assign z80_wait_n = (z80_rom_cs | z80_banked_cs) ? z80_rom_valid : 1'b1;

assign z80_din = z80_rom_cs ? z80_rom_data :
                 z80_ram_cs ? z80_ram_data :
                 z80_latch_cs ? m68k_latch :
                 z80_banked_cs ? z80_rom_data : 8'hFF;

// sound ic write enable

reg signed [15:0] opll_sample;
reg signed [15:0] opn_sample;

wire opll_sample_clk;
wire opn_sample_clk;

// OPLL (3.578 MHZ)
jt2413 ym2413 (
    .rst(reset),
    .clk(clk_sys),
    .cen(clk358_en), 
    .din( z80_dout ),
    .addr( z80_addr[0] ),
    .cs_n(~z80_ym2413_cs),
    .wr_n(0), //~opll_wr

    .snd(opll_sample),
    .sample(opll_sample_clk)
);

wire [7:0] ym2203_IOA;
wire       ym2203_OE;

// OPN (3 MHZ)
jt03 ym2203 (
    .rst(reset),
    .clk(clk_sys), // clock in is signal 1H (6MHz/2)
    .cen(clk3_en),
    .din( z80_dout ),
    .addr( z80_addr[0] ),
    .cs_n( ~z80_ym2203_cs ),
    .wr_n( z80_wr_n ),
    .IOA_out( ym2203_IOA ),
    .IOA_oe( ym2203_OE ),

    .snd(opn_sample)
);

reg  signed  [7:0] dac ;
wire signed [15:0] dac_sample = { ~dac[7], dac[6:0], 8'h0 } ;

// mix audio
assign audio_l = ( ( opn_sample + opll_sample + dac_sample  ) * 5 ) >>> 4;  // ( 3*5 ) / 16th
assign audio_r = ( ( opn_sample + opll_sample + dac_sample  ) * 5 ) >>> 4;  // ( 3*5 ) / 16th

wire [23:0] m68k_sprite_dout;
wire [15:0] m68k_pal_dout;

reg  [12:0] sprite_ram_addr;
wire [23:0] sprite_ram_dout;

// sprite RAM
// 3x8k
dual_port_ram #(.LEN(8192)) sprite_ram_00 (
    .clock_a ( clk_sys ),
    .address_a ( m68k_a[14:2] ),
    .wren_a ( !m68k_rw & m68k_spr_cs & !m68k_a[1] & !m68k_lds_n),
    .data_a ( m68k_dout[7:0]  ),
    .q_a (  m68k_sprite_dout[7:0] ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_ram_addr ),  
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( sprite_ram_dout[7:0] )
    );

dual_port_ram #(.LEN(8192)) sprite_ram_10 (
    .clock_a ( clk_sys ),
    .address_a ( m68k_a[14:2] ),
    .wren_a ( !m68k_rw & m68k_spr_cs & m68k_a[1] & !m68k_lds_n),
    .data_a ( m68k_dout[7:0]  ),
    .q_a (  m68k_sprite_dout[15:8] ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_ram_addr ),  
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( sprite_ram_dout[15:8] )
    );

dual_port_ram #(.LEN(8192)) sprite_ram_11 (
    .clock_a ( clk_sys ),
    .address_a ( m68k_a[14:2] ),
    .wren_a ( !m68k_rw & m68k_spr_cs & m68k_a[1] & !m68k_uds_n),
    .data_a ( m68k_dout[15:8]  ),
    .q_a (  m68k_sprite_dout[23:16] ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_ram_addr ),  
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( sprite_ram_dout[23:16] )
    );

wire [10:0] fg_ram_addr;
wire [15:0] fg_ram_dout;

wire [15:0] m68k_fg_ram_dout;

// foreground high
/*
dual_port_ram #(.LEN(2048)) ram_fg_h (
    .clock_a ( clk_sys ),
    .address_a ( m68k_a[11:1] ),
    .wren_a ( !m68k_rw & m68k_fg_ram_cs & !m68k_uds_n ), // can write to m68k_fg_mirror_cs but not read
    .data_a ( m68k_dout[15:8]  ),
    .q_a ( m68k_fg_ram_dout[15:8] ),

    .clock_b ( clk_sys ),
    .address_b ( fg_ram_addr ),  
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( fg_ram_dout[15:8] )
    
    );
*/
// foreground low
dual_port_ram #(.LEN(2048)) ram_fg_l (
    .clock_a ( clk_sys ),
    .address_a ( m68k_a[11:1] ),
    .wren_a ( !m68k_rw & m68k_fg_ram_cs/* & !(m68k_lds_n & m68k_uds_n)*/ ),
    .data_a ( m68k_dout[7:0]  ),
    .q_a ( m68k_fg_ram_dout[7:0] ),
     
    .clock_b ( clk_sys ),
    .address_b ( fg_ram_addr ),  
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( fg_ram_dout[7:0] )
    );
    
    
wire [5:0] r_pal = { tile_pal_dout[15], tile_pal_dout[11:8] , tile_pal_dout[14] };
wire [5:0] g_pal = { tile_pal_dout[15], tile_pal_dout[7:4]  , tile_pal_dout[13] };
wire [5:0] b_pal = { tile_pal_dout[15], tile_pal_dout[3:0]  , tile_pal_dout[12] };

reg  [11:0] tile_pal_addr;
wire [15:0] tile_pal_dout;
wire [15:0] tile_pal_din;

// tile palette high   
dual_port_ram #(.LEN(4096)) tile_pal_h (
    .clock_a ( clk_sys ),
    .address_a ( m68k_a[12:1] ),
    .wren_a ( !m68k_rw & m68k_pal_cs & !m68k_uds_n ),
    .data_a ( m68k_dout[15:8]  ),
    .q_a ( m68k_pal_dout[15:8]  ),

    .clock_b ( clk_sys ),
    .address_b ( tile_pal_addr ),  
    .wren_b ( 1'b0 ),
    .data_b (  ),
    .q_b( tile_pal_dout[15:8] )
    );

//  tile palette low
dual_port_ram #(.LEN(4096)) tile_pal_l (
    .clock_a ( clk_sys ),
    .address_a ( m68k_a[12:1] ),
    .wren_a ( !m68k_rw & m68k_pal_cs & !m68k_lds_n ),
    .data_a ( m68k_dout[7:0]  ),
    .q_a ( m68k_pal_dout[7:0] ),

    .clock_b ( clk_sys ),
    .address_b ( tile_pal_addr ),
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( tile_pal_dout[7:0] )
    );

// z80 ram 
dual_port_ram #(.LEN(2048)) z80_ram (
    .clock_b ( clk_sys ), 
    .address_b ( z80_addr[10:0] ),
    .wren_b ( z80_ram_cs & ~z80_wr_n ),
    .data_b ( z80_dout ),
    .q_b ( z80_ram_data )
    );
    
wire [15:0] spr_pal_dout ;
wire [15:0] m68k_spr_pal_dout ;

wire  [9:0] spr_buf_addr_r;
reg   [9:0] spr_buf_addr_w;
reg         spr_buf_w;
reg  [15:0] spr_buf_din;
wire [15:0] spr_buf_dout;

dual_port_ram #(.LEN(1024), .DATA_WIDTH(16)) spr_buffer_ram (
    .clock_a ( clk_sys ),
    .address_a ( spr_buf_addr_w ),
    .wren_a ( spr_buf_w ),
    .data_a ( spr_buf_din ),
    .q_a (  ),

    .clock_b ( clk_sys ),
    .address_b ( spr_buf_addr_r ),
    .data_b ( 16'd0 ),
    .wren_b ( clk6_en_p ),
    .q_b ( spr_buf_dout )
    ); 
    
// M68K RAM CONTROL
reg         m68k_ram_req;
wire        m68k_ram_ack;
reg  [21:1] m68k_ram_a;
reg         m68k_ram_we;
wire [15:0] m68k_ram_dout;
reg  [15:0] m68k_ram_din;
reg   [1:0] m68k_ram_ds;
reg         m68k_ram_dtack;
reg         m68k_mcu_dtack;

localparam M68K_RAM_IDLE = 0;
localparam M68K_RAM_M68K = 1;
localparam M68K_RAM_MCU = 2;

reg   [1:0] m68k_ram_state;

always @ (posedge clk_sys) begin
    if ( reset == 1 ) begin
        m68k_ram_dtack <= 0;
        m68k_mcu_dtack <= 0;
        m68k_ram_state <= M68K_RAM_IDLE;
    end else begin
        if (!m68k_ram_cs) m68k_ram_dtack  <= 0;
        if (!mcu_wl & !mcu_wh) m68k_mcu_dtack  <= 0;

        case (m68k_ram_state)
        M68K_RAM_IDLE:
            if ((mcu_wl | mcu_wh) & !m68k_mcu_dtack) begin
                m68k_ram_a <= mcu_addr;
                m68k_ram_din <= {mcu_din, mcu_din};
                m68k_ram_we <= 1;
                m68k_ram_ds <= {mcu_wh, mcu_wl};
                m68k_ram_req <= !m68k_ram_req;
                m68k_ram_state <= M68K_RAM_MCU;
            end
            else
            if (m68k_ram_cs & !m68k_ram_dtack) begin
                m68k_ram_a <= m68k_a[13:1];
                m68k_ram_din <= m68k_dout;
                m68k_ram_we <= !m68k_rw;
                m68k_ram_ds <= {!m68k_uds_n, !m68k_lds_n};
                m68k_ram_req <= !m68k_ram_req;
                m68k_ram_state <= M68K_RAM_M68K;
            end

        M68K_RAM_M68K:
            if (m68k_ram_req == m68k_ram_ack) begin
                m68k_ram_dtack <= 1;
                m68k_ram_state <= M68K_RAM_IDLE;
            end
        M68K_RAM_MCU:
            if (m68k_ram_req == m68k_ram_ack) begin
                m68k_mcu_dtack <= 1;
                m68k_ram_state <= M68K_RAM_IDLE;
            end
        endcase
    end
end

reg port1_req, port2_req;
always @(posedge clk_sys) begin
    if (rom_download) begin
        if (ioctl_wr) begin
            port1_req <= ~port1_req;
            port2_req <= ~port2_req;
        end
    end
end

wire [15:0] m68k_rom_data;
wire        m68k_rom_valid;

wire [15:0] cpu2_do;
reg   [4:0] z80_bank;
wire [18:0] z80_rom_addr = z80_banked_cs ? { z80_bank[4:0], z80_addr[13:0] } : z80_addr[14:0];
assign      z80_rom_data = z80_addr[0] ? cpu2_do[7:0] : cpu2_do[15:8];
wire        z80_rom_valid;

reg  [19:0] sprite_rom_addr;
wire [31:0] sprite_rom_data;
reg         sprite_rom_req;
wire        sprite_rom_ack;

reg  [15:0] fg_rom_addr;
wire [31:0] fg_rom_data;

sdram #(CLKSYS) sdram
(
  .*,
  .init_n        ( pll_locked ),
  .clk           ( clk_sys    ),

  // Bank 0-1 ops
  .port1_a       ( ioctl_addr[23:1] ),
  .port1_req     ( port1_req ),
  .port1_ack     (),
  .port1_we      ( rom_download ),
  .port1_ds      ( {~ioctl_addr[0], ioctl_addr[0]} ),
  .port1_d       ( {ioctl_dout, ioctl_dout} ),
  .port1_q       (),

  // M68K
  .cpu1_rom_addr ( {m68k_rom_2_cs, m68k_a[17:1]} ), //ioctl_addr >= 24'h000000) & (ioctl_addr < 24'h040000
  .cpu1_rom_cs   ( m68k_rom_cs | m68k_rom_2_cs ),
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
  .cpu2_addr     ( {1'b1, z80_rom_addr[18:1]} ), // (ioctl_addr >= 24'h080000) & (ioctl_addr < 24'h100000) ;
  .cpu2_rom_cs   ( z80_rom_cs | z80_banked_cs ),
  .cpu2_q        ( cpu2_do       ),
  .cpu2_valid    ( z80_rom_valid ),

  .cpu3_addr     (  ), 
  .cpu3_rom_cs   (  ),
  .cpu3_q        (  ),
  .cpu3_valid    (  ),

  .cpu4_addr     (  ),
  .cpu4_rom_cs   (  ),
  .cpu4_q        (  ),
  .cpu4_valid    (  ),

  // Bank 2-3 ops
  .port2_a       ( ioctl_addr[23:1] ),
  .port2_req     ( port2_req ),
  .port2_ack     (  ),
  .port2_we      ( rom_download ),
  .port2_ds      ( {~ioctl_addr[0], ioctl_addr[0]} ),
  .port2_d       ( {ioctl_dout, ioctl_dout} ),
  .port2_q       (  ),

  .gfx1_addr     ( {5'h10, fg_rom_addr[15:2]} ), // (ioctl_addr >= 24'h100000) & (ioctl_addr < 24'h110000) ;
  .gfx1_q        ( fg_rom_data ),

  .gfx2_addr     (  ),
  .gfx2_q        (  ),

  .gfx3_addr     (  ),
  .gfx3_q        (  ),

  .sp_addr       ( 20'h80000 + sprite_rom_addr ), // (ioctl_addr >= 24'h200000) & (ioctl_addr < 24'h480000)
  .sp_req        ( sprite_rom_req   ),
  .sp_ack        ( sprite_rom_ack   ),
  .sp_q          ( sprite_rom_data  )
);

endmodule
