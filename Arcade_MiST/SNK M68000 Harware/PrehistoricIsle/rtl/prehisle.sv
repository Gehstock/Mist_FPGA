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

module prehisle
(
    input         pll_locked,
    input         clk_sys, // 72 MHz
    input         reset,
    input         pause_cpu,

    input         refresh_sel,
    input         gfx1_en,
    input         gfx2_en,
    input         gfx3_en,
    input         gfx4_en,

    // debug
    input         gfx_tx_en,
    input         gfx_fg_en,
    input         gfx_bg_en,
    input         gfx_sp_en,
    input         test_flip,

    input   [7:0] p1,
    input   [7:0] p2,
    input   [7:0] dsw1,
    input   [6:0] dsw2,
    input  [15:0] coin,

    output        hbl,
    output        vbl,
    output        hsync,
    output        vsync,
    output  [3:0] r,
    output  [3:0] g,
    output  [3:0] b,

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

assign m68k_a[0] = 0;

reg refresh_mod;
wire flip = test_flip ^ flip_screen;

always @(posedge clk_sys) begin
    if (refresh_mod != ~refresh_sel) begin
        refresh_mod <= ~refresh_sel;
    end
end


localparam  CLKSYS=72;

reg  [5:0]  clk18_count;
reg  [5:0]  clk9_count;
reg  [5:0]  clk6_count;
reg  [5:0]  clk4_count;
reg [15:0]  clk_upd_count;

reg clk4_en_p, clk4_en_n;
reg clk9_en_p, clk9_en_n;
reg clk6_en;
reg clk_upd_en;
reg real_pause;

always @(posedge clk_sys) begin
    if (reset) begin
        clk4_count <= 0;
        clk6_count <= 0;
        clk_upd_count <= 0;
        {clk4_en_p, clk4_en_n} <= 0;
        {clk9_en_p, clk9_en_n} <= 0;
        clk6_en <= 0;
        clk_upd_en <= 0;
    end else begin
        clk4_count <= clk4_count + 1'd1;
        if (clk4_count == 17) begin
            clk4_count <= 0;
        end
        clk4_en_p <= clk4_count == 0;
        clk4_en_n <= clk4_count == 9;

        clk9_count <= clk9_count + 1'd1;
        if (clk9_count == 7) begin
            clk9_count <= 0;
            real_pause <= pause_cpu & m68k_as_n;
        end
        clk9_en_p <= clk9_count == 0 && !real_pause;
        clk9_en_n <= clk9_count == 4 && !real_pause;

        clk6_count <= clk6_count + 1'd1;
        if (clk6_count == 11) clk6_count <= 0;
        clk6_en <= clk6_count == 0;

        clk_upd_count <= clk_upd_count + 1'd1;
        // 72MHz / 113 == 637.168KHz.  should be 640.
        // todo : use fractional divider 112.5  alternate between 112 & 113
        if (clk_upd_count == 112) clk_upd_count <= 0;
		clk_upd_en <= clk_upd_count == 0;
    end
end

wire  [8:0] hc;
wire  [8:0] vc;
wire  [8:0] hcflip = !flip ? hc[8:0] : { hc[8], ~hc[7:0] };
wire  [8:0] vcflip = !flip ? vc : {vc[8], ~vc[7:0]};

video_timing video_timing (
    .clk(clk_sys),
    .clk_pix(clk6_en),
    .refresh_mod(refresh_mod),
    .hc(hc),
    .vc(vc),
    .hs_offset(hs_offset),
    .vs_offset(vs_offset),
    .hs_width(hs_width),
    .vs_width(vs_width),
    .hbl(hbl),
    .vbl(vbl),
    .hsync(hsync),
    .vsync(vsync)
);


// text layer
assign txt_ram_addr = { tx_y[7:3], tx_x[7:3] };
reg   [3:0] txt_attr, txt_attr_d;
reg  [31:0] txt_pix_data;
wire  [8:0] tx_x = hcflip;
wire  [8:0] tx_y = vcflip;
reg   [7:0] tx;

always @(posedge clk_sys) begin
    if (clk6_en) begin
        if (tx_x[2:0] == ({3{flip}} ^ 3'b111)) begin
            txt_rom_addr <= { txt_ram_dout[11:0], tx_y[2:0] };
            txt_pix_data <= txt_rom_data;
            txt_attr <= txt_ram_dout[15:12];
            txt_attr_d <= txt_attr;
        end
        case ( tx_x[2:0] )
            0: tx <= { txt_attr_d, txt_pix_data[15:12] };
            1: tx <= { txt_attr_d, txt_pix_data[11: 8] };
            2: tx <= { txt_attr_d, txt_pix_data[ 7: 4] };
            3: tx <= { txt_attr_d, txt_pix_data[ 3: 0] };
            4: tx <= { txt_attr_d, txt_pix_data[31:28] };
            5: tx <= { txt_attr_d, txt_pix_data[27:24] };
            6: tx <= { txt_attr_d, txt_pix_data[23:20] };
            7: tx <= { txt_attr_d, txt_pix_data[19:16] };
        endcase
    end
end

// background layer
wire [13:0] bg_x = {{5{hcflip[8] & flip}}, hcflip} + bg_scroll_x;
wire  [8:0] bg_y = vcflip + bg_scroll_y;
wire [14:0] bg_tile  = { bg_x[13:4], bg_y[8:4] } ; 
assign      tilemap_rom_addr = bg_tile;
reg   [3:0] bg_attr, bg_attr_d;
reg         bg_flip, bg_flip_d;
reg  [31:0] bg_pix_data;
reg   [7:0] bg;

always @(posedge clk_sys) begin
    if (clk6_en) begin
        if (bg_x[2:0] == ({3{flip}} ^ 3'b111)) begin
            bg_rom_addr <= { tilemap_rom_data[10:0], tilemap_rom_data[11] ^ bg_x[3], bg_y[3:0] } ;
            bg_pix_data <= bg_rom_data;
            bg_attr <= tilemap_rom_data[15:12];
            bg_attr_d <= bg_attr;
            bg_flip <= tilemap_rom_data[11];
            bg_flip_d <= bg_flip;
        end
        case ( {3{bg_flip_d}} ^ bg_x[2:0] )
            0: bg <= { bg_attr_d, bg_pix_data[15:12] };
            1: bg <= { bg_attr_d, bg_pix_data[11: 8] };
            2: bg <= { bg_attr_d, bg_pix_data[ 7: 4] };
            3: bg <= { bg_attr_d, bg_pix_data[ 3: 0] };
            4: bg <= { bg_attr_d, bg_pix_data[31:28] };
            5: bg <= { bg_attr_d, bg_pix_data[27:24] };
            6: bg <= { bg_attr_d, bg_pix_data[23:20] };
            7: bg <= { bg_attr_d, bg_pix_data[19:16] };
        endcase
    end
end

// foreground layer
wire [13:0] fg_x = {{5{hcflip[8] & flip}}, hcflip} + fg_scroll_x;
wire  [8:0] fg_y = vcflip + fg_scroll_y;
wire [14:0] fg_tile  = { fg_x[11:4], fg_y[8:4] }; 
assign      fg_ram_addr = fg_tile; 
reg   [3:0] fg_attr, fg_attr_d;
reg  [31:0] fg_pix_data;
reg   [7:0] fg;

always @(posedge clk_sys) begin
    if (clk6_en) begin
        if (fg_x[2:0] == ({3{flip}} ^ 3'b111)) begin
            fg_rom_addr <= { fg_ram_dout[10:0], fg_x[3], { 4 { fg_ram_dout[11] } } ^ fg_y[3:0] } ;
            fg_pix_data <= fg_rom_data;
            fg_attr <= fg_ram_dout[15:12];
            fg_attr_d <= fg_attr;
        end
        case ( fg_x[2:0] )
            0: fg <= { fg_attr_d, fg_pix_data[15:12] };
            1: fg <= { fg_attr_d, fg_pix_data[11: 8] };
            2: fg <= { fg_attr_d, fg_pix_data[ 7: 4] };
            3: fg <= { fg_attr_d, fg_pix_data[ 3: 0] };
            4: fg <= { fg_attr_d, fg_pix_data[31:28] };
            5: fg <= { fg_attr_d, fg_pix_data[27:24] };
            6: fg <= { fg_attr_d, fg_pix_data[23:20] };
            7: fg <= { fg_attr_d, fg_pix_data[19:16] };
        endcase
    end
end

// sprite engine
reg   [3:0] sprite_state;
reg   [7:0] sprite_num;
wire  [8:0] sprite_y = sprite_ram_dout[8:0];
reg   [3:0] spr_y_ofs;

wire  [8:0] sp_y = vcflip + (flip ? -1'd1 : 1'd1);
reg   [8:0] spr_x_ofs;
reg   [8:0] spr_x_pos;
reg  [12:0] spr_tile_num;
reg         spr_flip_x;
reg         spr_flip_y;
reg   [3:0] sprite_colour;

always @(posedge clk_sys) begin
    spr_buf_w <= 0;
    if (reset) begin
        sprite_state <= 0;
    end else begin
        // sprites
        case(sprite_state)
        0: if (hc == 0) begin
            sprite_state <= 1;
            sprite_num <= 0;
            spr_x_pos <= 0;
        end
        1: begin
            sprite_ram_addr <= { sprite_num, 2'b0 }; // y
            sprite_state <= 2;
        end
        2: begin
            // address valid read y
            sprite_state <= 3;
            sprite_ram_addr <= sprite_ram_addr + 1'd1; // setup to read x
        end
        3: begin
            // y valid
            if ( sp_y >= sprite_y && sp_y < ( sprite_y + 16 ) ) begin
                spr_y_ofs <= sp_y - sprite_y ;
                sprite_ram_addr <= sprite_ram_addr + 1'd1; // setup to read attribute/tile index
                sprite_state <= 4;
            end else begin
                sprite_state <= 10;
            end
        end
        4: begin
            // x value valid 
            if ( sprite_ram_dout[7:0] < 8'hff ) begin
                spr_x_ofs <= 0;
                spr_x_pos <= sprite_ram_dout[8:0];
                sprite_ram_addr <= sprite_ram_addr + 1'd1; // setup to read color
                sprite_state <= 5;
            end else begin
                sprite_state <= 10;
            end
        end
        5: begin
            // attribute data valid
            spr_tile_num <= sprite_ram_dout[12:0];
            spr_flip_x <= sprite_ram_dout[14];
            spr_flip_y <= sprite_ram_dout[15];
            sprite_state <= 6;
        end
        6: begin
            // color data valid
            sprite_colour <= sprite_ram_dout[15:12];
            sprite_rom_addr <= { spr_tile_num, spr_flip_x ^ spr_x_ofs[3], { 4 {spr_flip_y} } ^ spr_y_ofs[3:0] } ;
            sprite_rom_req <= ~sprite_rom_req;
            sprite_state <= 7;
        end
        7: if (sprite_rom_req == sprite_rom_ack) begin
            spr_buf_addr_w <= { vc[0], spr_x_pos };
            case ( { 3 { spr_flip_x } } ^ spr_x_ofs[2:0] ) // case ( x[2:0] )
                0: spr_buf_din <= { sprite_colour, sprite_rom_data[15:12] };
                1: spr_buf_din <= { sprite_colour, sprite_rom_data[11: 8] };
                2: spr_buf_din <= { sprite_colour, sprite_rom_data[ 7: 4] };
                3: spr_buf_din <= { sprite_colour, sprite_rom_data[ 3: 0] };
                4: spr_buf_din <= { sprite_colour, sprite_rom_data[31:28] };
                5: spr_buf_din <= { sprite_colour, sprite_rom_data[27:24] };
                6: spr_buf_din <= { sprite_colour, sprite_rom_data[23:20] };
                7: spr_buf_din <= { sprite_colour, sprite_rom_data[19:16] };
            endcase
            sprite_state <= 8;
        end
        8: begin
            spr_buf_w <= ( spr_buf_din[3:0] < 15 );

            if ( spr_x_ofs < 15 ) begin
                sprite_state <= 9;
            end else begin
                sprite_state <= 10;
            end
        end
        9: begin
            spr_x_ofs <= spr_x_ofs + 1 ;
            spr_x_pos <= spr_x_pos + 1 ;
            sprite_state <= spr_x_ofs == 4'd7 ? 4'd6 : 4'd7;
        end
        10: begin
            if ( sprite_num != 255 ) begin
                // next sprite
                sprite_num <= sprite_num + 1 ;
                sprite_state <= 1;
            end else begin
                // done.
                sprite_state <= 0;
            end
        end
        endcase
    end
end

wire [8:0] spr_pos = (flip ? 8'd17 : -8'd17) + hcflip;
assign     spr_buf_addr_r = { ~vc[0], spr_pos };
reg  [7:0] sp;
always @(posedge clk_sys) if (clk6_en) sp <= spr_buf_dout;

// layer mixer
reg        pen_valid;
always @(posedge clk_sys) begin
    if (clk6_en) begin
        pen_valid <= 0;
        // priority
        if ( gfx_bg_en == 1 ) begin
            tile_pal_addr  <= 12'd768 + bg[7:0];
            pen_valid <= 1;
        end
        if ( sp[3:0] < 15 && gfx_sp_en == 1 && sp[7:4] >= 4) begin
            tile_pal_addr  <= 12'd256 + sp;
            pen_valid <= 1;
        end
        if ( fg[3:0] < 15 && gfx_fg_en == 1 ) begin
            tile_pal_addr  <= 12'd512 + fg[7:0];
            pen_valid <= 1;
        end
        if ( sp[3:0] < 15 && gfx_sp_en == 1 && sp[7:4] < 4) begin
            tile_pal_addr  <= 12'd256 + sp;
            pen_valid <= 1;
        end
        if ( tx[3:0] < 15 && gfx_tx_en == 1 ) begin
            tile_pal_addr  <= tx[7:0];
            pen_valid <= 1;
        end
        if (pen_valid) begin
            r <= tile_pal_dout[15:12];
            g <= tile_pal_dout[11:8];
            b <= tile_pal_dout[7:4];
        end else begin
            r <= 0;
            g <= 0;
            b <= 0;
        end
    end
end


/// 68k cpu

reg flip_screen ;
reg p1_invert;
assign m68k_dtack_n = m68k_rom_cs ? !m68k_rom_valid : 0; 

// select cpu data input based on what is active 
assign m68k_din =  m68k_rom_cs  ? m68k_rom_data :
                   m68k_ram_cs  ? m68k_ram_dout :
                   m68k_txt_ram_cs ? m68k_txt_ram_dout :
                   m68k_spr_cs  ? m68k_sprite_dout :
                   m68k_fg_ram_cs ? m68k_fg_ram_dout :
                   m68k_pal_cs ? m68k_pal_dout :
                   m_invert_ctrl_cs ? 16'd0 :
                   input_p1_cs ? {8'hff, {8{p1_invert}} ^ p1} :
                   input_p2_cs ? {8'hff, p2} :
                   input_dsw1_cs ? {8'hff, dsw1}:
                   input_dsw2_cs ? {8'hff, ~vbl, dsw2} :
                   input_coin_cs ? coin :
                   16'd0;

always @ (posedge clk_sys) begin

    if ( reset == 1 ) begin
        z80_nmi_n <= 1 ;
        flip_screen <= 0;
    end else begin

        if ( m68k_rw == 0 ) begin        

            if ( sound_latch_cs == 1 ) begin
                sound_latch <= m68k_dout[7:0];
                z80_nmi_n <= 0;
            end

            if ( fg_scroll_x_cs == 1 ) begin
                fg_scroll_x <= m68k_dout;
            end

            if ( fg_scroll_y_cs == 1 ) begin
                fg_scroll_y <= m68k_dout;
            end

            if ( bg_scroll_x_cs == 1 ) begin
                bg_scroll_x <= m68k_dout;
            end

            if ( bg_scroll_y_cs == 1 ) begin
                bg_scroll_y <= m68k_dout;
            end

            if ( m_invert_ctrl_cs == 1 ) begin
                p1_invert <= m68k_dout[0];
            end

            if ( flip_cs == 1 ) begin
                flip_screen <= m68k_dout[0];
            end
        end

        if (!z80_nmi_n && z80_addr == 16'h0066 && !M1_n && !MREQ_n) begin
            z80_nmi_n <= 1;
        end
    end
end 

wire    m68k_rom_cs;
wire    m68k_ram_cs;
wire    m68k_pal_cs;
wire    m68k_txt_ram_cs;
wire    m68k_spr_cs;
wire    m68k_fg_ram_cs;
wire    m68k_bg_ram_cs;
wire    input_p1_cs;
wire    input_p2_cs;
wire    input_coin_cs;
wire    input_dsw1_cs;
wire    input_dsw2_cs;
wire    irq_z80_cs;
wire    bg_scroll_x_cs;
wire    bg_scroll_y_cs;
wire    fg_scroll_x_cs;
wire    fg_scroll_y_cs;
wire    m_invert_ctrl_cs;
wire    sound_latch_cs;
wire    flip_cs;

wire    z80_rom_cs;
wire    z80_ram_cs;
wire    z80_latch_cs;
wire    z80_sound0_cs;
wire    z80_sound1_cs;
wire    z80_upd_cs;
wire    z80_upd_r_cs;

chip_select cs (
    // 68k bus
    .m68k_a(m68k_a),
    .m68k_as_n(m68k_as_n),
    .m68k_uds_n(m68k_uds_n),
    .m68k_lds_n(m68k_lds_n),

    .z80_addr(z80_addr),
    .MREQ_n(MREQ_n),
    .IORQ_n(IORQ_n),
    .M1_n(M1_n),
    .RFSH_n(RFSH_n),
    
    // 68k chip selects
    .m68k_rom_cs(m68k_rom_cs),
    .m68k_ram_cs(m68k_ram_cs),
    .m68k_txt_ram_cs(m68k_txt_ram_cs),
    .m68k_spr_cs(m68k_spr_cs),
    .m68k_pal_cs(m68k_pal_cs),
    .m68k_fg_ram_cs(m68k_fg_ram_cs),

    .input_p1_cs(input_p1_cs),
    .input_p2_cs(input_p2_cs),
    .input_dsw1_cs(input_dsw1_cs),
    .input_dsw2_cs(input_dsw2_cs),
    .input_coin_cs(input_coin_cs),

    .bg_scroll_x_cs(bg_scroll_x_cs),
    .bg_scroll_y_cs(bg_scroll_y_cs),
    .fg_scroll_x_cs(fg_scroll_x_cs),
    .fg_scroll_y_cs(fg_scroll_y_cs),
    .flip_cs(flip_cs),

    .m_invert_ctrl_cs(m_invert_ctrl_cs),

    .sound_latch_cs(sound_latch_cs),

    // z80 

    .z80_rom_cs(z80_rom_cs),
    .z80_ram_cs(z80_ram_cs),
    .z80_latch_cs(z80_latch_cs),
    .z80_sound0_cs(z80_sound0_cs),
    .z80_sound1_cs(z80_sound1_cs),
    .z80_upd_cs(z80_upd_cs),
    .z80_upd_r_cs(z80_upd_r_cs)
);
 
reg [15:0] bg_scroll_x;
reg [15:0] bg_scroll_y;

reg [15:0] fg_scroll_x;
reg [15:0] fg_scroll_y;

reg  [7:0] sound_latch;

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
reg  m68k_dtack_n ;         // Data transfer ack (always ready)
reg  m68k_ipl2_n ;

wire m68k_vpa_n = ~int_ack;//( m68k_lds_n == 0 && m68k_fc == 3'b111 ); // int ack

wire int_ack = !m68k_as_n && m68k_fc == 3'b111;

reg [1:0] vbl_sr;

// vblank handling 
// process interrupt and sprite buffering
always @ (posedge clk_sys ) begin
    if ( reset == 1 ) begin
        m68k_ipl2_n <= 1 ;
    end else begin
        vbl_sr <= { vbl_sr[0], vbl };

        if ( vbl_sr == 2'b01 ) begin // rising edge
            // trigger sprite buffer copy
            //  68k vbl interrupt
            m68k_ipl2_n <= 0;
        end else if ( int_ack == 1/* || vbl_sr == 2'b10*/ ) begin
            // deassert interrupt since 68k ack'ed.
            m68k_ipl2_n <= 1 ;
        end
    end
end

wire reset_n;

reg bg_enable;
reg fg_enable;
reg tx_enable;
reg sp_enable;

fx68k fx68k (
    // input
    .clk(clk_sys),
    .enPhi1(clk9_en_p),
    .enPhi2(clk9_en_n),

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
    
    .IPL0n(1'b1),
    .IPL1n(1'b1),
    .IPL2n(m68k_ipl2_n),

    // busses
    .iEdb(m68k_din),
    .oEdb(m68k_dout),
    .eab(m68k_a[23:1])
);

// z80 audio 
wire    [7:0] z80_rom_data;
wire    [7:0] z80_ram_data;

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
    .RESET_n    ( ~reset ),
    .CLK        ( clk_sys ),
    .CEN_p      ( clk4_en_p ),
    .CEN_n      ( clk4_en_n ),
    .WAIT_n     ( z80_wait_n ), // z80_wait_n
    .INT_n      ( opl_irq_n ),  // opl_irq_n
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
    .MREQ_n     ( MREQ_n ),
    .Stop       (),
    .REG        ()
);

reg opl_wait ;

assign z80_wait_n = z80_rom_cs ? z80_rom_valid : 1'b1;

assign z80_din = z80_rom_cs ? z80_rom_data :
                 z80_ram_cs ? z80_ram_data :
                 z80_latch_cs ? sound_latch :
                 z80_sound0_cs ? opl_dout : 8'hFF;

always @ (posedge clk_sys) begin

    if ( reset == 1 ) begin
    end else begin
        
        if ( z80_wr_n == 0 ) begin 
            
            // 7759
            if ( z80_upd_cs == 1 ) begin
                upd_din <= z80_dout ;
                upd_start_n <= 1 ;
                // need a pulse to trigger the 7759 start
                upd_start_flag <= 1;
            end
            
            if ( upd_start_flag == 1 ) begin
                upd_start_n <= 0 ;
                upd_start_flag <= 0;
            end
            
            if ( z80_upd_r_cs == 1 ) begin
                upd_reset <= 1;
            end else begin
                upd_reset <= 0;
            end

        end        
       
    end
end 
    
wire [7:0] opl_dout;
wire opl_irq_n;

reg signed [15:0] sample;

wire signed  [8:0] upd_sample_out;
wire signed [15:0] upd_sample = { upd_sample_out[8], upd_sample_out[8], upd_sample_out, 5'b0 }; 

wire opl_sample_clk;

jtopl #(.OPL_TYPE(2)) opl
(
    .rst(reset),
    .clk(clk_sys),
    .cen(clk4_en_p),
    .din(z80_dout),
    .addr(z80_addr[5]),
    .cs_n(~( z80_sound0_cs | z80_sound1_cs )),
    .wr_n(z80_wr_n),
    .dout(opl_dout),
    .irq_n(opl_irq_n),
    .snd(sample),
    .sample(opl_sample_clk)
);

reg [7:0] upd_din;
reg upd_reset ;
reg upd_start_n ;
reg upd_start_flag ;

jt7759 upd7759
(
    .rst( reset | upd_reset ),
    .clk(clk_sys),  // Use same clock as sound CPU
    .cen(clk_upd_en),  // 640kHz
    .stn(upd_start_n),  // STart (active low)
    .cs(1'b1),
    .mdn(1'b1),  // MODE: 1 for stand alone mode, 0 for slave mode
                 // see chart in page 13 of PDF
    .busyn(),
    // CPU interface
    .wrn(1'b1),  // for slave mode only, 31.7us after drqn is set
    .din(upd_din),
    .drqn(),  // data request. 50-70us delay after mdn goes low

    // ROM interface
    .rom_cs(upd_rom_cs),        // equivalent to DRQn in original chip
    .rom_addr(upd_rom_addr),  // output        [16:0]
    .rom_data(upd_rom_data),  // input         [ 7:0]   
    .rom_ok(upd_rom_valid),
    
    // Sound output
    .sound(upd_sample_out)  //output signed [ 8:0]
);

always @(*) begin
    // mix audio
    audio_l = ( sample + upd_sample ) >>> 1;
    audio_r = ( sample + upd_sample ) >>> 1;
end

wire [15:0] m68k_ram_dout;
wire [15:0] m68k_sprite_dout;
wire [15:0] m68k_pal_dout;

// main 68k ram high    
dual_port_ram #(.LEN(8192)) ram8kx8_H (
    .clock_a ( clk_sys ),
    .address_a ( m68k_a[13:1] ),
    .wren_a ( !m68k_rw & m68k_ram_cs & !m68k_uds_n ),
    .data_a ( m68k_dout[15:8]  ),
    .q_a (  m68k_ram_dout[15:8] )
    
//    .clock_b (  ),
//    .address_b (  ),
//    .wren_b (  ),
//    .data_b (  ),
//    .q_b ( )
    );

// main 68k ram low     
dual_port_ram #(.LEN(8192)) ram8kx8_L (
    .clock_a ( clk_sys ),
    .address_a ( m68k_a[13:1] ),
    .wren_a ( !m68k_rw & m68k_ram_cs & !m68k_lds_n ),
    .data_a ( m68k_dout[7:0]  ),
    .q_a ( m68k_ram_dout[7:0] )
    
//    .clock_b (  ),
//    .address_b (  ),
//    .wren_b (  ),
//    .data_b (  ),
//    .q_b ( )
    );

reg  [10:0] sprite_ram_addr;
wire [15:0] sprite_ram_dout;

    // main 68k sprite ram high  
// 2kx16
dual_port_ram #(.LEN(1024)) sprite_ram_H (
    .clock_a ( clk_sys ),
    .address_a ( m68k_a[10:1] ),
    .wren_a ( !m68k_rw & m68k_spr_cs & !m68k_uds_n ),
    .data_a ( m68k_dout[15:8]  ),
    .q_a (  m68k_sprite_dout[15:8] ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_ram_addr ),  
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( sprite_ram_dout[15:8] )
    
    );

// main 68k sprite ram low     
dual_port_ram #(.LEN(1024)) sprite_ram_L (
    .clock_a ( clk_sys ),
    .address_a ( m68k_a[10:1] ),
    .wren_a ( !m68k_rw & m68k_spr_cs & !m68k_lds_n ),
    .data_a ( m68k_dout[7:0]  ),
    .q_a ( m68k_sprite_dout[7:0] ),
     
    .clock_b ( clk_sys ),
    .address_b ( sprite_ram_addr ),  
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( sprite_ram_dout[7:0] )
    );

   
wire [12:0] fg_ram_addr;
wire [15:0] fg_ram_dout;

wire [15:0] m68k_fg_ram_dout;

// foreground high   
dual_port_ram #(.LEN(8192)) ram_fg_h (
    .clock_a ( clk_sys ),
    .address_a ( m68k_a[13:1] ),
    .wren_a ( !m68k_rw & m68k_fg_ram_cs & !m68k_uds_n ),
    .data_a ( m68k_dout[15:8]  ),
    .q_a ( m68k_fg_ram_dout[15:8] ),

    .clock_b ( clk_sys ),
    .address_b ( fg_ram_addr ),  
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( fg_ram_dout[15:8] )
    
    );

// foreground low
dual_port_ram #(.LEN(8192)) ram_fg_l (
    .clock_a ( clk_sys ),
    .address_a ( m68k_a[13:1] ),
    .wren_a ( !m68k_rw & m68k_fg_ram_cs & !m68k_lds_n ),
    .data_a ( m68k_dout[7:0]  ),
    .q_a ( m68k_fg_ram_dout[7:0] ),
     
    .clock_b ( clk_sys ),
    .address_b ( fg_ram_addr ),  
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( fg_ram_dout[7:0] )
    );
    
wire [15:0] m68k_txt_ram_dout ;
wire [15:0] txt_ram_dout;
wire  [9:0] txt_ram_addr;
    
// text ram high   
dual_port_ram #(.LEN(1024)) txt_ram_h (
    .clock_a ( clk_sys ),
    .address_a ( m68k_a[10:1] ),
    .wren_a ( !m68k_rw & m68k_txt_ram_cs & !m68k_uds_n ),
    .data_a ( m68k_dout[15:8]  ),
    .q_a ( m68k_txt_ram_dout[15:8]  ),

    .clock_b ( clk_sys ),
    .address_b ( txt_ram_addr ),  
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( txt_ram_dout[15:8] )
    );

//  text ram low
dual_port_ram #(.LEN(1024)) txt_ram_l (
    .clock_a ( clk_sys ),
    .address_a ( m68k_a[10:1] ),
    .wren_a ( !m68k_rw & m68k_txt_ram_cs & !m68k_lds_n ),
    .data_a ( m68k_dout[7:0]  ),
    .q_a ( m68k_txt_ram_dout[7:0] ),

    .clock_b ( clk_sys ),
    .address_b ( txt_ram_addr ),  
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( txt_ram_dout[7:0] )
    );   
    
reg  [9:0] tile_pal_addr;
reg [15:0] tile_pal_dout;
    
// tile palette high   
dual_port_ram #(.LEN(1024)) tile_pal_h (
    .clock_a ( clk_sys ),
    .address_a ( m68k_a[10:1] ),
    .wren_a ( !m68k_rw & m68k_pal_cs & !m68k_uds_n ),
    .data_a ( m68k_dout[15:8]  ),
    .q_a ( m68k_pal_dout[15:8]  ),

    .clock_b ( clk_sys ),
    .address_b ( tile_pal_addr ),  
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( tile_pal_dout[15:8] )
    );

//  tile palette low
dual_port_ram #(.LEN(1024)) tile_pal_l (
    .clock_a ( clk_sys ),
    .address_a ( m68k_a[10:1] ),
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

reg   [9:0] spr_buf_addr_w;
wire  [9:0] spr_buf_addr_r;
reg         spr_buf_w;
reg   [7:0] spr_buf_din;
wire  [7:0] spr_buf_dout;
    
dual_port_ram #(.LEN(1024), .DATA_WIDTH(8)) spr_buffer_ram (
    .clock_a ( clk_sys ),
    .address_a ( spr_buf_addr_w ),
    .wren_a ( spr_buf_w ),
    .data_a ( spr_buf_din ),
    .q_a (  ),

    .clock_b ( clk_sys ),
    .address_b ( spr_buf_addr_r ),
    .data_b ( 8'd15 ),
    .wren_b ( clk6_en ),
    .q_b ( spr_buf_dout )
    ); 

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
assign      z80_rom_data = z80_addr[0] ? cpu2_do[7:0] : cpu2_do[15:8];
wire        z80_rom_valid;

wire [15:0] cpu4_do;
wire [16:0] upd_rom_addr;
wire  [7:0] upd_rom_data = upd_rom_addr[0] ? cpu4_do[7:0] : cpu4_do[15:8];
wire        upd_rom_cs;
wire        upd_rom_valid;

wire [14:0] tilemap_rom_addr;
reg  [15:0] tilemap_rom_data;

reg  [17:0] sprite_rom_addr;
wire [31:0] sprite_rom_data;
reg         sprite_rom_req;
wire        sprite_rom_ack;

reg  [15:0] fg_rom_addr;
wire [31:0] fg_rom_data;

reg  [15:0] bg_rom_addr;
wire [31:0] bg_rom_data;

reg  [12:0] txt_rom_addr;
wire [31:0] txt_rom_data;

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
  .cpu1_rom_addr ( m68k_a[17:1]  ), //ioctl_addr >= 24'h000000) & (ioctl_addr < 24'h040000
  .cpu1_rom_cs   ( m68k_rom_cs   ),
  .cpu1_rom_q    ( m68k_rom_data ),
  .cpu1_rom_valid( m68k_rom_valid),

  .cpu1_ram_req  (  ),
  .cpu1_ram_ack  (  ),
  .cpu1_ram_addr (  ),
  .cpu1_ram_we   (  ),
  .cpu1_ram_d    (  ),
  .cpu1_ram_q    (  ),
  .cpu1_ram_ds   (  ),

  // Audio Z80
  .cpu2_addr     ( {4'hC, z80_addr[15:1]} ), // >= c0000
  .cpu2_rom_cs   ( z80_rom_cs    ),
  .cpu2_q        ( cpu2_do       ),
  .cpu2_valid    ( z80_rom_valid ),

  .cpu3_addr     ( {4'hF, tilemap_rom_addr} ),  // (ioctl_addr >= 24'hf0000) & (ioctl_addr < 24'h100000)
  .cpu3_rom_cs   ( 1'b1 ),
  .cpu3_q        ( tilemap_rom_data ),
  .cpu3_valid    ( ),

  .cpu4_addr     ( {20'h68000 + upd_rom_addr[16:1]} ), // (ioctl_addr >= 24'hd0000) & (ioctl_addr < 24'hf0000)
  .cpu4_rom_cs   ( upd_rom_cs ),
  .cpu4_q        ( cpu4_do ),
  .cpu4_valid    ( upd_rom_valid ),

  // Bank 2-3 ops
  .port2_a       ( ioctl_addr[23:1] ),
  .port2_req     ( port2_req ),
  .port2_ack     (),
  .port2_we      ( rom_download ),
  .port2_ds      ( {~ioctl_addr[0], ioctl_addr[0]} ),
  .port2_d       ( {ioctl_dout, ioctl_dout} ),
  .port2_q       (),

  .gfx1_addr     ( {2'd2, 5'd0, txt_rom_addr} ), // (ioctl_addr >= 24'h200000)
  .gfx1_q        ( txt_rom_data ),

  .gfx2_addr     ( {2'b01, fg_rom_addr} ),       // (ioctl_addr >= 24'h40000) & (ioctl_addr < 24'h80000)
  .gfx2_q        ( fg_rom_data ),

  .gfx3_addr     ( {2'b10, bg_rom_addr} ),       // (ioctl_addr >= 24'h80000) & (ioctl_addr < 24'hc0000)
  .gfx3_q        ( bg_rom_data ),

  .sp_addr       ( {1'b1, sprite_rom_addr} ),    // (ioctl_addr >= 24'h100000) & (ioctl_addr < 24'h200000)
  .sp_req        ( sprite_rom_req   ),
  .sp_ack        ( sprite_rom_ack   ),
  .sp_q          ( sprite_rom_data  )
);

endmodule
