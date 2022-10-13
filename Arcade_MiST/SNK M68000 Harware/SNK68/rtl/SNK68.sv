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

module SNK68
(
    input         pll_locked,
    input         clk_sys, // 72 MHz
    input         reset,
    input   [3:0] pcb,
    input         pause_cpu,

    input         refresh_sel,

    // debug
    input         test_flip,
    output        flip,

    input   [7:0] p1,
    input   [7:0] p2,
    input   [7:0] dsw1,
    input   [7:0] dsw2,
    input  [15:0] coin,
    input  [11:0] rotary1,
    input  [11:0] rotary2,

    output        hbl,
    output        vbl,
    output        hsync,
    output        vsync,
    output  [4:0] r,
    output  [4:0] g,
    output  [4:0] b,

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
assign flip = test_flip ^ scr_flip;

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

// foreground layer
wire  [9:0] fg_tile = { hcflip[7:3], vcflip[7:3] };
assign fg_ram_addr = { fg_tile, hc[0] };
reg   [6:0] fg_colour, fg_colour_d;
wire  [8:0] fg_x = hcflip;
wire  [8:0] fg_y = vcflip;
reg  [15:0] fg_ram_dout0, fg_ram_dout1;
reg  [15:0] fg_pix_data;
reg  [10:0] fg;

always @(posedge clk_sys) begin
    if (clk6_en) begin
        if (hc[0])
            fg_ram_dout1 <= fg_ram_dout;
        else
            fg_ram_dout0 <= fg_ram_dout;

        if (fg_x[1:0] == ({2{flip}} ^ 2'b11)) begin
            if ( pcb == 0 ) begin
                fg_rom_addr <= { fg_ram_dout0[10:0], ~fg_x[2], fg_y[2:0] };
                fg_colour   <=   fg_ram_dout0[15:12];
            end else begin
                // POW only has 256 text tiles in each bank.  offset selects bank
                fg_rom_addr <= { tile_offset, fg_ram_dout0[7:0], ~fg_x[2], fg_y[2:0] } ;
                fg_colour <= fg_ram_dout1[2:0] ;
            end
            fg_pix_data <= fg_rom_data;
            fg_colour_d <= fg_colour;
        end
        case ( fg_x[1:0] )
            0: fg <= { fg_colour_d, fg_pix_data[12], fg_pix_data[8],  fg_pix_data[4], fg_pix_data[0] } ; 
            1: fg <= { fg_colour_d, fg_pix_data[13], fg_pix_data[9],  fg_pix_data[5], fg_pix_data[1] } ; 
            2: fg <= { fg_colour_d, fg_pix_data[14], fg_pix_data[10], fg_pix_data[6], fg_pix_data[2] } ; 
            3: fg <= { fg_colour_d, fg_pix_data[15], fg_pix_data[11], fg_pix_data[7], fg_pix_data[3] } ; 
        endcase
    end
end

// sprite rendering into dual line buffers
reg   [4:0] sprite_state;
reg  [31:0] spr_pix_data;

wire  [8:0] sp_y    = vcflip + (flip ? -1'd1 : 1'd1);

reg   [6:0] sprite_colour;
reg  [14:0] sprite_tile_num;
reg         sprite_flip_x;
reg         sprite_flip_y;
reg   [1:0] sprite_group;
reg   [4:0] sprite_col;
reg  [15:0] sprite_col_x;
reg  [15:0] sprite_col_y;
reg   [8:0] sprite_col_idx;
reg   [8:0] spr_x_pos;
reg   [3:0] spr_x_ofs;
reg   [1:0] sprite_layer;
reg         sprite_overrun;

wire  [3:0] spr_pen = { spr_pix_data[ 8 + { 3 { sprite_flip_x } } ^ spr_x_ofs[2:0]], 
                        spr_pix_data[ 0 + { 3 { sprite_flip_x } } ^ spr_x_ofs[2:0]], 
                        spr_pix_data[24 + { 3 { sprite_flip_x } } ^ spr_x_ofs[2:0]], 
                        spr_pix_data[16 + { 3 { sprite_flip_x } } ^ spr_x_ofs[2:0]] }  ;

always @ (posedge clk_sys) begin
    if ( reset == 1 ) begin
        sprite_state <= 0;
        sprite_overrun <= 0;
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
            sprite_col <= 0;

            case ( sprite_layer )
                0: sprite_group <= 2;
                1: sprite_group <= 3;
                2: sprite_group <= 1;
            endcase
            sprite_state <= 1;
        end else if ( sprite_state == 1 )  begin
            // setup x read
            sprite_ram_addr <= { sprite_col, 3'b0, sprite_group, 1'b0 } ; 
            sprite_state <= 2;
        end else if ( sprite_state == 2 )  begin
            // setup y read
            sprite_ram_addr <= sprite_ram_addr + 1'd1;
            sprite_state <= 3;
        end else if ( sprite_state == 3 )  begin
            // x valid
            sprite_col_x <= sprite_ram_dout;
            sprite_state <= 4;
        end else if ( sprite_state == 4 )  begin
            if ( sprite_col_x[7:0] > 16 ) begin
                sprite_state <= 17;
            end
            // y valid
            sprite_col_y <= sprite_ram_dout;
            sprite_state <= 5;
        end else if ( sprite_state == 5 )  begin
            // tile ofset from the top of the column
            sprite_col_idx <= sp_y + sprite_col_y[8:0] ;
            sprite_state <= 6;
        end else if ( sprite_state == 6 )  begin
            // setup sprite tile colour read
            sprite_ram_addr <= { sprite_group[1:0], sprite_col[4:0], sprite_col_idx[8:4], 1'b0 };
            sprite_state <= 7;

        end else if ( sprite_state == 7 ) begin
            // setup sprite tile index read
            sprite_ram_addr <= sprite_ram_addr + 1'd1;
            sprite_state <= 8;
        end else if ( sprite_state == 8 ) begin
            // tile colour ready
            sprite_colour <= sprite_ram_dout[6:0]; // 0x7f
            sprite_state <= 9;
        end else if ( sprite_state == 9 ) begin
            // tile index ready
            if (pcb == 0 || pcb == 2) begin
                sprite_tile_num <= sprite_ram_dout[14:0] ;  // 0x7fff
                sprite_flip_x   <= sprite_ram_dout[15] & ~spr_flip_orientation ;  // 0x8000
                sprite_flip_y   <= sprite_ram_dout[15] &  spr_flip_orientation;   // 0x8000
            end else begin
                sprite_tile_num <= sprite_ram_dout[13:0] ;  // 0x3fff
                sprite_flip_x   <= sprite_ram_dout[14] & ~spr_flip_orientation ;  // 0x4000
                sprite_flip_y   <= sprite_ram_dout[15] &  spr_flip_orientation;   // 0x8000
            end
            spr_x_ofs <= 0;
            spr_x_pos <= { sprite_col_x[7:0], sprite_col_y[15:12] } ;
            sprite_state <= 10;
        end else if ( sprite_state == 10 )  begin    

            // sprite_rom_addr <= { tile[10:0], ~dx[3], dy[3:0] } ;
            case ( { sprite_flip_y, sprite_flip_x } )
                2'b00: sprite_rom_addr <= { sprite_tile_num, ~spr_x_ofs[3],  sprite_col_idx[3:0] } ;
                2'b01: sprite_rom_addr <= { sprite_tile_num,  spr_x_ofs[3],  sprite_col_idx[3:0] } ;
                2'b10: sprite_rom_addr <= { sprite_tile_num, ~spr_x_ofs[3], ~sprite_col_idx[3:0] } ;
                2'b11: sprite_rom_addr <= { sprite_tile_num,  spr_x_ofs[3], ~sprite_col_idx[3:0] } ;
            endcase 

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
                    sprite_state <= 11;
                end
                
            end else begin
                sprite_state <= 17;
            end

        end else if ( sprite_state == 17) begin
            if ( hc > 360 ) begin
                sprite_state <= 0;  
                sprite_overrun <= 1;
            end else if ( sprite_col < 31 ) begin
                sprite_col <= sprite_col + 1'd1;
                sprite_state <= 1;
            end else begin
                if ( sprite_layer < 2 ) begin
                    sprite_layer <= sprite_layer + 1'd1;
                    sprite_state <= 22;
                end else begin
                    sprite_state <= 0;
                end
            end
        end
    end
end

wire  [8:0] spr_pos = (flip ? 8'd8 : -8'd8) + hcflip;
assign      spr_buf_addr_r = { ~vc[0], spr_pos };
reg  [10:0] sp;
always @ (posedge clk_sys) if (clk6_en) sp <= spr_buf_dout[10:0];

// final color mix
wire [10:0] pen = ( fg[3:0] == 0 && ( pcb == 1 || pcb == 2 || fg[7] == 0 ) ) ? sp[10:0] : fg[6:0];

always @ (posedge clk_sys) begin
    if (clk6_en) begin
        if ( pen[3:0] == 0 ) begin
            tile_pal_addr <= 11'h7ff ; // background pen
        end else begin
            tile_pal_addr <= pen[10:0] ;
        end
        r <= r_pal;
        g <= g_pal;
        b <= b_pal;
    end
end

/// 68k cpu

reg spr_flip_orientation ;
reg scr_flip ;
reg [2:0] tile_offset;
reg invert_input;

assign m68k_dtack_n = m68k_rom_cs ? !m68k_rom_valid :
                      m68k_rom_2_cs ? !m68k_rom_valid :
                      m68k_ram_cs ? !m68k_ram_dtack :
                      1'b0;

assign     m68k_din = m68k_rom_cs ? m68k_rom_data :
                      m68k_rom_2_cs ? m68k_rom_data :
                      m68k_ram_cs  ? m68k_ram_dout :
                      // high byte of even addressed sprite ram not connected.  pull high.
                      m68k_spr_cs  ? ( m68k_a[1] == 0 ) ? ( m68k_sprite_dout | 16'hff00 ) : m68k_sprite_dout : // 0xff000000
                      m68k_fg_ram_cs ? m68k_fg_ram_dout :
                      m68k_pal_cs ? m68k_pal_dout :
                      (input_p1_cs & !input_p2_cs ) ? (invert_input ? ~{p1, p1} : {p1, p1}) :
                      (input_p2_cs & !input_p1_cs ) ? (invert_input ? ~{p2, p2} : {p2, p2}) :
                      (input_p2_cs &  input_p1_cs ) ? (invert_input ? ~{ p2[7:0], p1[7:0] } : { p2[7:0], p1[7:0] }) :
                      input_dsw1_cs ? {dsw1, dsw1} :
                      input_dsw2_cs ? {dsw2, dsw2} :
                      input_coin_cs ? (invert_input ? ~coin : coin) :
                      m68k_rotary1_cs ? ~{ rotary1[11:4], 8'h0 } :
                      m68k_rotary2_cs ? ~{ rotary2[11:4], 8'h0 } :
                      m68k_rotary_lsb_cs ? ~{ rotary2[3:0], rotary1[3:0], 8'h0 } :
                      z80_latch_read_cs ? { z80_latch, z80_latch } :
                      16'd0;

always @ (posedge clk_sys) begin

    if ( reset == 1 ) begin
        z80_nmi_n <= 1 ;
        scr_flip <= 0;
    end else begin

        if ( !m68k_rw) begin        

            if ( m68k_latch_cs == 1 ) begin
                m68k_latch <= m68k_dout[7:0];
                z80_nmi_n <= 0;
            end

            if ( m68k_scr_flip_cs == 1 ) begin
                scr_flip <= m68k_dout[3];
                spr_flip_orientation <= m68k_dout[2];
                if ( pcb > 0 ) begin
                    tile_offset <= m68k_dout[6:4];
                end
            end

            if ( m_invert_ctrl_cs == 1 ) begin
                invert_input <= ( m68k_dout[7:0] == 8'h07 );
            end
        end

        if (!z80_nmi_n && z80_addr == 16'h0066 && !M1_n && !MREQ_n) begin
            z80_nmi_n <= 1;
        end
    end
end

wire    m68k_rom_cs;
wire    m68k_rom_2_cs;
wire    m68k_ram_cs;
wire    m68k_pal_cs;
wire    m68k_spr_cs;
wire    m68k_fg_ram_cs;
wire    m68k_scr_flip_cs;
wire    input_p1_cs;
wire    input_p2_cs;
wire    input_coin_cs;
wire    input_dsw1_cs;
wire    input_dsw2_cs;
wire    irq_z80_cs;
wire    m_invert_ctrl_cs;
wire    m68k_latch_cs;
wire    z80_latch_read_cs;
wire    m68k_rotary1_cs;
wire    m68k_rotary2_cs;
wire    m68k_rotary_lsb_cs;

wire    z80_rom_cs;
wire    z80_ram_cs;
wire    z80_latch_cs;
wire    z80_sound0_cs;
wire    z80_sound1_cs;
wire    z80_upd_cs;
wire    z80_upd_r_cs;

chip_select cs (
    // 68k bus
    .pcb(pcb),
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
    
    // 68k chip selects
    .m68k_rom_cs(m68k_rom_cs),
    .m68k_rom_2_cs(m68k_rom_2_cs),
    .m68k_ram_cs(m68k_ram_cs),
    .m68k_spr_cs(m68k_spr_cs),
    .m68k_scr_flip_cs(m68k_scr_flip_cs),
    .m68k_fg_ram_cs(m68k_fg_ram_cs),
    .m68k_pal_cs(m68k_pal_cs),

    .input_p1_cs(input_p1_cs),
    .input_p2_cs(input_p2_cs),
    .input_dsw1_cs(input_dsw1_cs),
    .input_dsw2_cs(input_dsw2_cs),
    .input_coin_cs(input_coin_cs),

    .m68k_rotary1_cs(m68k_rotary1_cs),
    .m68k_rotary2_cs(m68k_rotary2_cs),
    .m68k_rotary_lsb_cs(m68k_rotary_lsb_cs),
    .m_invert_ctrl_cs(m_invert_ctrl_cs),

    .m68k_latch_cs(m68k_latch_cs), // write commands to z80 from 68k
    .z80_latch_read_cs(z80_latch_read_cs), // read commands from z80

    // z80 
    .z80_rom_cs(z80_rom_cs),
    .z80_ram_cs(z80_ram_cs),
    .z80_latch_cs(z80_latch_cs),
    .z80_sound0_cs(z80_sound0_cs),
    .z80_sound1_cs(z80_sound1_cs),
    .z80_upd_cs(z80_upd_cs),
    .z80_upd_r_cs(z80_upd_r_cs)
);

reg   [7:0] z80_latch;
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
reg  m68k_dtack_n ;         // Data transfer ack (always ready)
reg  m68k_ipl0_n ;

wire m68k_vpa_n = ~int_ack;//( m68k_lds_n == 0 && m68k_fc == 3'b111 ); // int ack

wire int_ack = !m68k_as_n && m68k_fc == 3'b111;

reg [1:0] vbl_sr;

// vblank handling 
// process interrupt and sprite buffering
always @ (posedge clk_sys ) begin
    if ( reset == 1 ) begin
        m68k_ipl0_n <= 1 ;
    end else begin
        vbl_sr <= { vbl_sr[0], vbl };

        if ( vbl_sr == 2'b01 ) begin // rising edge
            // trigger sprite buffer copy
            //  68k vbl interrupt
            m68k_ipl0_n <= 0;
        end else if ( int_ack == 1/* || vbl_sr == 2'b10*/ ) begin
            // deassert interrupt since 68k ack'ed.
            m68k_ipl0_n <= 1 ;
        end
    end
end

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
    
    .IPL0n(m68k_ipl0_n),
    .IPL1n(1'b1),
    .IPL2n(1'b1),

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
                 z80_latch_cs ? m68k_latch :
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

            if ( z80_latch_cs == 1 ) begin
                z80_latch <= z80_dout ;
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

wire [15:0] m68k_sprite_dout;
wire [15:0] m68k_pal_dout;

reg  [13:0] sprite_ram_addr;
wire [15:0] sprite_ram_dout /* synthesis keep */;

// main 68k sprite ram high  
// 2kx16
dual_port_ram #(.LEN(16384)) sprite_ram_H (
    .clock_a ( clk_sys ),
    .address_a ( m68k_a[14:1] ),
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
dual_port_ram #(.LEN(16384)) sprite_ram_L (
    .clock_a ( clk_sys ),
    .address_a ( m68k_a[14:1] ),
    .wren_a ( !m68k_rw & m68k_spr_cs & !m68k_lds_n ),
    .data_a ( m68k_dout[7:0]  ),
    .q_a ( m68k_sprite_dout[7:0] ),
     
    .clock_b ( clk_sys ),
    .address_b ( sprite_ram_addr ),  
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( sprite_ram_dout[7:0] )
    );


wire [10:0] fg_ram_addr /* synthesis keep */;
wire [15:0] fg_ram_dout /* synthesis keep */;

wire [15:0] m68k_fg_ram_dout;

// foreground high   
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

// foreground low
dual_port_ram #(.LEN(2048)) ram_fg_l (
    .clock_a ( clk_sys ),
    .address_a ( m68k_a[11:1] ),
    .wren_a ( !m68k_rw & m68k_fg_ram_cs & !m68k_lds_n ),
    .data_a ( m68k_dout[7:0]  ),
    .q_a ( m68k_fg_ram_dout[7:0] ),
     
    .clock_b ( clk_sys ),
    .address_b ( fg_ram_addr ),  
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( fg_ram_dout[7:0] )
    );
    
    
reg  [10:0] tile_pal_addr;
wire [15:0] tile_pal_dout;

//	int dark = pal_data >> 15;
//	int r = ((pal_data >> 7) & 0x1e) | ((pal_data >> 14) & 0x1) ;
//	int g = ((pal_data >> 3) & 0x1e) | ((pal_data >> 13) & 0x1) ;
//	int b = ((pal_data << 1) & 0x1e) | ((pal_data >> 12) & 0x1) ;

// todo: shift for dark bit
wire [4:0] r_pal = { tile_pal_dout[11:8] , tile_pal_dout[14] };
wire [4:0] g_pal = { tile_pal_dout[7:4]  , tile_pal_dout[13] };
wire [4:0] b_pal = { tile_pal_dout[3:0]  , tile_pal_dout[12] };

// tile palette high   
dual_port_ram #(.LEN(2048)) tile_pal_h (
    .clock_a ( clk_sys ),
    .address_a ( m68k_a[11:1] ),
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
dual_port_ram #(.LEN(2048)) tile_pal_l (
    .clock_a ( clk_sys ),
    .address_a ( m68k_a[11:1] ),
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
    .wren_b ( clk6_en ),
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

localparam M68K_RAM_IDLE = 0;
localparam M68K_RAM_M68K = 1;

reg   [1:0] m68k_ram_state;

always @ (posedge clk_sys) begin
    if ( reset == 1 ) begin
        m68k_ram_dtack <= 0;
        m68k_ram_state <= M68K_RAM_IDLE;
    end else begin
        if (!m68k_ram_cs) m68k_ram_dtack  <= 0;

        case (m68k_ram_state)
        M68K_RAM_IDLE:
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
assign      z80_rom_data = z80_addr[0] ? cpu2_do[7:0] : cpu2_do[15:8];
wire        z80_rom_valid;

wire [15:0] cpu4_do;
wire [16:0] upd_rom_addr;
wire  [7:0] upd_rom_data = upd_rom_addr[0] ? cpu4_do[7:0] : cpu4_do[15:8];
wire        upd_rom_cs;
wire        upd_rom_valid;

reg  [19:0] sprite_rom_addr;
wire [31:0] sprite_rom_data;
reg         sprite_rom_req;
wire        sprite_rom_ack;

reg  [14:0] fg_rom_addr;
wire [15:0] fg_rom_data;
wire        fg_rom_valid;

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
  .cpu2_addr     ( {4'h8, z80_addr[15:1]} ), // (ioctl_addr >= 24'h080000) & (ioctl_addr < 24'h090000) ;
  .cpu2_rom_cs   ( z80_rom_cs    ),
  .cpu2_q        ( cpu2_do       ),
  .cpu2_valid    ( z80_rom_valid ),

  .cpu3_addr     ( {4'hC, fg_rom_addr} ),    // (ioctl_addr >= 24'h0c0000) & (ioctl_addr < 24'h0d0000) ;
  .cpu3_rom_cs   ( 1'b1 ),
  .cpu3_q        ( fg_rom_data ),
  .cpu3_valid    ( fg_rom_valid ),

  .cpu4_addr     ( {3'b101, upd_rom_addr[16:1]} ), // (ioctl_addr >= 24'hA0000) & (ioctl_addr < 24'hC0000)
  .cpu4_rom_cs   ( upd_rom_cs ),
  .cpu4_q        ( cpu4_do ),
  .cpu4_valid    ( upd_rom_valid ),

  // Bank 2-3 ops
  .port2_a       ( ioctl_addr[23:1] ),
  .port2_req     ( port2_req ),
  .port2_ack     (  ),
  .port2_we      ( rom_download ),
  .port2_ds      ( {~ioctl_addr[0], ioctl_addr[0]} ),
  .port2_d       ( {ioctl_dout, ioctl_dout} ),
  .port2_q       (  ),

  .gfx1_addr     (  ),
  .gfx1_q        (  ),

  .gfx2_addr     (  ),
  .gfx2_q        (  ),

  .gfx3_addr     (  ),
  .gfx3_q        (  ),

  .sp_addr       ( 20'h40000 + sprite_rom_addr ),    // (ioctl_addr >= 24'h100000) & (ioctl_addr < 24'h400000)
  .sp_req        ( sprite_rom_req   ),
  .sp_ack        ( sprite_rom_ack   ),
  .sp_q          ( sprite_rom_data  )
);

endmodule
