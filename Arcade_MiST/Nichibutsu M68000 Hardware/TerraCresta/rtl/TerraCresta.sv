//============================================================================
//
//  (c) 2022 Darren Olafson
//
//  Enhancements/fixes/SDRAM handling (c) 2022 Gyorgy Szombathelyi
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

module TerraCresta
(
    input         pll_locked,
    input         clk_96M, // for ROM downloading and SDRAM
    input         clk_24M,
    input         reset,
    input         pause_cpu,

    input   [3:0] pcb,
    input         fg_enable,
    input         bg_enable,
    input         spr_enable,

    input   [7:0] p1,
    input   [7:0] p2,
    input  [15:0] dsw1,
    input   [7:0] sys,

    output        hbl,
    output        vbl,
    output        hsync,
    output        vsync,
    output reg [3:0] r,
    output reg [3:0] g,
    output reg [3:0] b,
    output        flipped,

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

// undefine to use BRAM for all ROMs
`define SDRAM 1

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
reg        flip = 0;
assign     flipped = flip;

wire [8:0] hc;
wire [8:0] vc;

video_timing video_timing (
    .clk(clk_24M),
    .clk_pix_en(clk6_en),
    .hc(hc),
    .vc(vc),
    .hs_offset(hs_offset),
    .vs_offset(vs_offset),
    .hbl(hbl),
    .vbl(vbl),
    .hsync(hsync),
    .vsync(vsync)
);

reg [11:0] spr_pix, sprite_line_buffer_q;
always @(posedge clk_24M) begin
    sprite_line_buffer_q <= sprite_line_buffer[{vc[0], hc_x[7:0]}];
    if (clk6_en) begin
        spr_pix <= sprite_line_buffer_q;
        sprite_line_buffer[{vc[0], hc_x[7:0]}] <= sprite_trans_pen;
    end
end

reg   [7:0] spi, spi_r;
reg         spr_transp, spr_transp_r;
wire  [9:0] hc_s = flip ? ~hc[7:0] + scroll_x + 9'd256 : hc[7:0] + scroll_x ;
wire  [8:0] vc_s = flip ? ~vc[7:0] + scroll_y + 9'd256 : vc[7:0] + scroll_y;

wire  [8:0] hc_x = {hc[8], hc[7:0] ^ {8{flip}}};
wire  [8:0] vc_x = vc ^ {9{flip}};

reg   [3:0] gfx1_pix ;
reg   [7:0] gfx2_pix ;

wire [11:0] bg_tile = { hc_s[9:4], vc_s[8:4] };
wire  [9:0] fg_tile = { hc_x[7:3], vc_x[7:3] };

reg   [7:0] pal_idx;

always @(posedge clk_24M) begin
    if (clk6_en) begin
        r <= prom_r[pal_idx];
        g <= prom_g[pal_idx];
        b <= prom_b[pal_idx];
    end
end

wire  [7:0] gfx1_dout;
wire  [7:0] gfx2_dout;
wire  [7:0] gfx3_dout;

// tile attributes
assign bg_ram_addr = bg_tile ;
assign fg_ram_addr = fg_tile ;

reg  [13:0] gfx1_addr;
reg  [16:0] gfx2_addr;

reg   [1:0] gfx2_pal_h;
reg   [1:0] gfx2_pal_l;
reg   [1:0] gfx2_pal_h_r;
reg   [1:0] gfx2_pal_l_r;

always @ (posedge clk_24M) begin
    if (clk6_en) begin
    // 0
        if (hc_x[0])
            gfx1_addr <= { 1'b0 , fg_ram_dout[7:0],   vc_x[2:0],   hc_x[2:1] } ;  // tile #.  set of 256 tiles -- fg_ram_dout[7:0]

        if (hc_s[0]) begin
            gfx2_addr <= { bg_ram_dout[9:0], vc_s[3:0], hc_s[3:1] } ;
        
            gfx2_pal_h   <= bg_ram_dout[14:13];
            gfx2_pal_l   <= bg_ram_dout[12:11];
            gfx2_pal_h_r <= gfx2_pal_h;
            gfx2_pal_l_r <= gfx2_pal_l;
        end
        spi <= { 2'b10, ( ( spr_pix[3] == 1'b0 ) ? spr_pix[9:8] : spr_pix[11:10] ), prom_s[ spr_pix[7:0] ][3:0] };  //p[3:0];
        spr_transp <= spr_pix == sprite_trans_pen;

    // 1
        gfx1_pix <= ~hc[0] ? gfx1_dout[3:0] : gfx1_dout[7:4];

        gfx2_pix <= { 2'b11 , ((gfx2_pen[3] == 0 ) ? gfx2_pal_l_r : gfx2_pal_h_r ), gfx2_pen } ;

        spi_r <= spi;

        spr_transp_r <= spr_transp;
    // 2
        pal_idx <= ( gfx1_pix < 4'hf && fg_enable ) ? { 4'b0, gfx1_pix } : ( spr_enable == 0 || ( bg_enable == 1 && spr_transp_r && scroll_x[13] == 0 )) ? gfx2_pix :  spi_r;
    end
end
    
wire  [3:0] gfx2_pen = (flip ^ ~hc_s[0]) ? gfx2_dout[3:0] : gfx2_dout[7:4];

reg   [1:0] vbl_sr;

wire  [3:0] sprite_trans_pen = (pcb == 0 || pcb == 1 || pcb == 3 ) ? 4'd0 : 4'd15;

reg   [3:0] copy_sprite_state;
reg   [3:0] draw_sprite_state;

wire  [7:0] sprite_shared_ram_dout;
reg   [7:0] sprite_shared_addr;
reg   [5:0] sprite_buffer_addr;  // 64 sprites
reg  [63:0] sprite_buffer_din;
wire [63:0] sprite_buffer_dout;
reg         sprite_buffer_w;

reg   [3:0] sprite_x_ofs;
wire  [3:0] sprite_x_new_ofs = {sprite_x_ofs[2:1], sprite_x_ofs[3],sprite_x_ofs[0]};

reg   [9:0] sprite_tile ;  // terra cresta has 512 tiles ,  HORE HORE Kid has 1024
reg   [7:0] sprite_y_pos;
reg   [8:0] sprite_x_pos;
wire  [8:0] sprite_x_new_pos = sprite_x_pos + sprite_x_new_ofs;
reg   [3:0] sprite_colour;
reg         sprite_x_256;
reg         sprite_flip_x;
reg         sprite_flip_y;

// vblank handling 
// process interrupt and sprite buffering
always @ (posedge clk_24M) begin
    if ( vbl_sr == 2'b01 ) begin // rising edge
        // trigger sprite buffer copy
        copy_sprite_state <= 1;
        draw_sprite_state <= 0;
    end

    //   copy sprite list to dedicated sprite list ram
    // start state machine for copy
    if ( copy_sprite_state == 1 ) begin
        sprite_shared_addr <= 0;
        copy_sprite_state <= 2;
        sprite_buffer_addr <= 0;
    end else if ( copy_sprite_state == 2 ) begin
        // address now 0
        sprite_shared_addr <= sprite_shared_addr + 1'd1 ;
        copy_sprite_state <= 3; 
    end else if ( copy_sprite_state == 3 ) begin        
       // address 0 result
        sprite_y_pos <= flip ? sprite_shared_ram_dout - 1'd1 : 8'd239 - sprite_shared_ram_dout;

        sprite_shared_addr <= sprite_shared_addr + 1'd1 ;
        copy_sprite_state <= 4; 
    end else if ( copy_sprite_state == 4 ) begin    
        // address 1 result
        sprite_tile[7:0] <= sprite_shared_ram_dout;

        sprite_shared_addr <= sprite_shared_addr + 1'd1 ;
        copy_sprite_state <= 5; 
    end else if ( copy_sprite_state == 5 ) begin        
            // add 256 to x?
        sprite_x_256 <= sprite_shared_ram_dout[0];
        // add 256 to tile?

        if ( pcb == 0 || pcb == 1 || pcb == 3 ) begin
            sprite_tile[9:8] <= { 1'b0, sprite_shared_ram_dout[1] };
        end else begin
            sprite_tile[9:8] <= { sprite_shared_ram_dout[1], sprite_shared_ram_dout[4] };
        end

        // flip x?
        sprite_flip_x <= sprite_shared_ram_dout[2];
        // flip y?
        sprite_flip_y <= sprite_shared_ram_dout[3] ^ flip ;
        // colour
        sprite_colour <= sprite_shared_ram_dout[7:4];

        sprite_shared_addr <= sprite_shared_addr + 1'd1 ;

        copy_sprite_state <= 6; 
    end else if ( copy_sprite_state == 6 ) begin        
        sprite_x_pos <=  { sprite_x_256, sprite_shared_ram_dout } - (flip ? 8'h81 : 8'h7e) ;

        copy_sprite_state <= 7; 
    end else if ( copy_sprite_state == 7 ) begin                
        sprite_buffer_w <= 1;
        sprite_buffer_din <= {sprite_tile,sprite_x_pos,sprite_y_pos,sprite_colour,sprite_flip_x,sprite_flip_y};
        
        copy_sprite_state <= 8;
    end else if ( copy_sprite_state == 8 ) begin                

        // write is complete
        sprite_buffer_w <= 0;
        // sprite has been buffered.  are we done?
        if ( sprite_buffer_addr < 8'h3f ) begin
            // start on next sprite
            sprite_buffer_addr <= sprite_buffer_addr + 1'd1;
            copy_sprite_state <= 2;
        end else begin
            // we are done, go idle.  
            copy_sprite_state <= 0; 
        end
    end

    if ( draw_sprite_state == 0 && copy_sprite_state == 0 && hc == 2 ) begin // 0xe0
        sprite_x_ofs <= 0;
        draw_sprite_state <= 1;
        sprite_buffer_addr <= 0;
    end else if (draw_sprite_state == 1) begin
        draw_sprite_state <= 2;
    end else if (draw_sprite_state == 2) begin
        // get current sprite attributes
        {sprite_tile,sprite_x_pos,sprite_y_pos,sprite_colour,sprite_flip_x,sprite_flip_y} <= sprite_buffer_dout; //[34:0];
        draw_sprite_state <= 3;
        sprite_rom_req <= ~sprite_rom_req;
        sprite_x_ofs <= 0;
    end else if (draw_sprite_state == 3) begin    
        if (sprite_rom_req == sprite_rom_ack) begin
            draw_sprite_state <= 4;
        end
    end else if (draw_sprite_state == 4) begin                
        if ( vc >= sprite_y_pos && vc < ( sprite_y_pos + 16 ) ) begin
            // fetch bitmap 
            if ( p[3:0] != sprite_trans_pen && ~sprite_x_new_pos[8]) begin
                sprite_line_buffer[{~vc[0], sprite_x_new_pos[7:0]}] <= p;
            end
            if ( sprite_x_ofs < 15 ) begin
                sprite_x_ofs <= sprite_x_ofs + 1'd1;
                if (sprite_x_ofs == 7) begin
                    draw_sprite_state <= 3;
                    sprite_rom_req <= ~sprite_rom_req;
                end
            end else begin
                draw_sprite_state <= 5;
            end
        end else begin
            draw_sprite_state <= 5;
        end
    end else if (draw_sprite_state == 5) begin                        
        // done. next sprite
        if ( sprite_buffer_addr < 63 ) begin
            sprite_buffer_addr <= sprite_buffer_addr + 1'd1;
            draw_sprite_state <= 2;
        end else begin
            // all sprites done
            draw_sprite_state <= 0;
        end
    end
    if (hc == 0) draw_sprite_state <= 0;
end

wire    [3:0] sprite_y_ofs = vc - sprite_y_pos ;

wire    [3:0] flipped_x = ( sprite_flip_x == 0 ) ? sprite_x_new_ofs : 4'd15 - sprite_x_new_ofs;
wire    [3:0] flipped_y = ( sprite_flip_y == 0 ) ? sprite_y_ofs : 4'd15 - sprite_y_ofs;

wire    [3:0] gfx3_pix = (flipped_x[0] == 1 ) ? gfx3_dout[7:4] : gfx3_dout[3:0];

wire   [11:0] p ;
wire   [16:0] gfx3_addr ;

reg     [3:0] prom_u_dout;
reg     [7:0] prom_u_addr;

always @(posedge clk_24M) begin
    if ( pcb == 0 || pcb == 1 || pcb == 3 )
        prom_u_addr <= sprite_tile[8:1];
    else
        prom_u_addr <= {sprite_tile[9],sprite_tile[7:2],sprite_tile[8]};

    prom_u_dout <= prom_u[prom_u_addr];
end

always @ (*) begin
    if ( pcb == 0 || pcb == 1 || pcb == 3 ) begin
        // terra cresta / amazon
        gfx3_addr = { 1'b0, flipped_x[1], sprite_tile[8:0], flipped_y[3:0], flipped_x[3:2] };
        
        p = { prom_u_dout, sprite_colour, gfx3_pix};
    end else begin
        // hori
        gfx3_addr = { flipped_x[1],       sprite_tile[9:0], flipped_y[3:0], flipped_x[3:2] };

        p = { prom_u_dout, sprite_colour[3:1], 1'b0, gfx3_pix};
    end
end

reg    [11:0] sprite_line_buffer[512];

dual_port_ram #(.LEN(64), .DATA_WIDTH(64)) sprite_buffer (
    .clock_a ( clk_24M ),
    .address_a ( sprite_buffer_addr ),
    .wren_a ( 1'b0 ),
    .data_a ( ),
    .q_a ( sprite_buffer_dout ),

    .clock_b ( clk_96M ),
    .address_b ( sprite_buffer_addr ),
    .wren_b ( sprite_buffer_w ),
    .data_b ( sprite_buffer_din  ),
    .q_b( )
    );

// Chip select mux
// M68K selects
wire prog_rom_cs;
wire m68k_ram_cs;
wire bg_ram_cs;
wire m68k_ram1_cs;
wire fg_ram_cs;

wire input_p1_cs;
wire input_p2_cs;
wire input_system_cs;
wire input_dsw_cs;

wire flip_cs;
wire scroll_x_cs;
wire scroll_y_cs;

wire sound_latch_cs;

wire prot_chip_data_cs;
wire prot_chip_cmd_cs;

// Z80 selects
wire z80_rom_cs;
wire z80_ram_cs;

wire z80_sound0_cs;
wire z80_sound1_cs;
wire z80_dac1_cs;
wire z80_dac2_cs;
wire z80_latch_clr_cs;
wire z80_latch_r_cs;

// Select PCB Title and set chip select lines
reg [15:0] scroll_x;
reg [15:0] scroll_y;
reg [7:0]  sound_latch;

chip_select cs (
    .pcb(pcb),

    .m68k_a(m68k_a),
    .m68k_as_n(m68k_as_n),
    .m68k_uds_n(m68k_uds_n),
    .m68k_lds_n(m68k_lds_n),

    .z80_addr(z80_addr),
    .RFSH_n(RFSH_n),
    .MREQ_n(MREQ_n),
    .IORQ_n(IORQ_n),

    // M68K selects
    .prog_rom_cs(prog_rom_cs),
    .m68k_ram_cs(m68k_ram_cs),
    .bg_ram_cs(bg_ram_cs),
    .m68k_ram1_cs(m68k_ram1_cs),
    .fg_ram_cs(fg_ram_cs),

    .input_p1_cs(input_p1_cs),
    .input_p2_cs(input_p2_cs),
    .input_system_cs(input_system_cs),
    .input_dsw_cs(input_dsw_cs),

    .scroll_x_cs(scroll_x_cs),
    .scroll_y_cs(scroll_y_cs),
    .flip_cs(flip_cs),

    .sound_latch_cs(sound_latch_cs),

    .prot_chip_data_cs(prot_chip_data_cs),
    .prot_chip_cmd_cs(prot_chip_cmd_cs),

    // Z80 selects
    .z80_rom_cs(z80_rom_cs),
    .z80_ram_cs(z80_ram_cs),

    .z80_sound0_cs(z80_sound0_cs),
    .z80_sound1_cs(z80_sound1_cs),
    .z80_dac1_cs(z80_dac1_cs),
    .z80_dac2_cs(z80_dac2_cs),
    .z80_latch_clr_cs(z80_latch_clr_cs),
    .z80_latch_r_cs(z80_latch_r_cs)
);

// CPU outputs
wire m68k_rw         ;    // Read = 1, Write = 0
wire m68k_as_n       ;    // Address strobe
wire m68k_lds_n      ;    // Lower byte strobe
wire m68k_uds_n      ;    // Upper byte strobe
wire [2:0] m68k_fc    ;   // Processor state

// CPU busses
wire [15:0] m68k_dout       ;
wire [23:0] m68k_a          ;
wire [15:0] m68k_din        ;   
assign m68k_a[0] = 1'b0;

// CPU inputs
wire        m68k_dtack_n;         // Data transfer ack (always ready)
reg         m68k_ipl0_n;
wire        m68k_vpa_n = ~(m68k_fc == 3'b111); // autovectoring

fx68k fx68k (
    // input
    .clk( clk_24M ),
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
    .oRESETn(),
    .oHALTEDn(),

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

wire int_ack = !m68k_as_n && m68k_fc == 3'b111; // cpu acknowledged the interrupt

/// 68k cpu
always @ (posedge clk_24M) begin
    if ( reset == 1 ) begin
        m68k_ipl0_n <= 1 ;
    end else begin
        vbl_sr <= { vbl_sr[0], vbl };

        if ( vbl_sr == 2'b01 ) begin // rising edge
            //  68k vbl interrupt
            m68k_ipl0_n <= 0;
        end else if ( int_ack || vbl_sr == 2'b10 ) begin
            // deassert interrupt since 68k ack'ed.
            m68k_ipl0_n <= 1 ;
        end
    end
end

// tell 68k to wait for valid data. 0=ready 1=wait
// always ack when it's not program rom
assign m68k_dtack_n = 0; 

// select cpu data input based on what is active
assign m68k_din =  prog_rom_cs  ? prog_rom_data :
                   m68k_ram_cs  ? ram68k_dout :
                   m68k_ram1_cs ? m68k_ram1_dout :
                   input_p1_cs ? { 8'd0, p1 } :
                   input_p2_cs ? { 8'd0, p2 } :
                   input_system_cs ? { sys, 8'd0 }:
                   input_dsw_cs ? dsw1 :
                   prot_chip_data_cs ? { 8'h00, nb1412m2_decrypt_dout }:
                   16'hffff;

// z80 bus
wire    [7:0] z80_rom_data;
wire    [7:0] z80_ram_dout;

wire   [15:0] z80_addr;
reg     [7:0] z80_din;
wire    [7:0] z80_dout;

wire z80_wr_n;
wire z80_rd_n;
reg  z80_wait_n;
reg  z80_irq_n;

wire RFSH_n;
wire IORQ_n;
wire MREQ_n;
wire M1_n;

T80pa u_cpu(
    .RESET_n    ( ~reset ),
    .CLK        ( clk_24M ),
    .CEN_p      ( clk4_en_p ),
    .CEN_n      ( clk4_en_n ),
    .WAIT_n     ( z80_wait_n ), // don't wait if data is valid or rom access isn't selected
    .INT_n      ( z80_irq_n ),  // opl timer
    .NMI_n      ( 1'b1 ),
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
    .M1_n       ( M1_n     ),
    .BUSAK_n    (),
    .HALT_n     ( 1'b1 ),
    .MREQ_n     ( MREQ_n   ),
    .Stop       (),
    .REG        ()
);

//IORQ gets together with M1-pin active/low. 
always @ (posedge clk_24M) begin

    if ( reset == 1 ) begin
        z80_irq_n <= 1;
    end else begin
        if ( clk_ym_count == 9'h1ff ) begin
            z80_irq_n <= 0;
        end

        // check for interrupt ack and deassert int
        if ( !M1_n && !IORQ_n ) begin
            z80_irq_n <= 1;
        end
    end
end
wire [7:0] opl_dout;
wire opl_irq_n;

reg signed [15:0] sample;

jtopl #(.OPL_TYPE(1)) opl
(
    .rst(reset),
    .clk(clk_24M),
    .cen(clk4_en_p),
    .din(z80_dout),
    .addr(z80_addr[0]),
    .cs_n(~( z80_sound0_cs | z80_sound1_cs )),
    .wr_n(z80_wr_n),
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

wire z80_rom_valid;

assign z80_din = z80_rom_cs ? z80_rom_data :
                 z80_ram_cs ? z80_ram_dout :
                 z80_latch_r_cs ? sound_latch :
                 (z80_sound0_cs | z80_sound1_cs) ? opl_dout :
                 8'hff;

assign z80_wait_n = z80_rom_cs ? z80_rom_valid : 1'b1;

always @ (posedge clk_24M) begin
    if (reset)
        sound_latch <= 0;
    else begin
        if ( !z80_rd_n && z80_latch_clr_cs )
            sound_latch <= 0;

        if (!m68k_rw & sound_latch_cs )
            sound_latch <= {m68k_dout[6:0],1'b1};

        if ( z80_wr_n == 0 ) begin 
            if (z80_dac1_cs == 1 ) begin
                dac1 <= z80_dout;
            end else if (z80_dac2_cs == 1 ) begin
                dac2 <= z80_dout;
            end
        end
    end
end

always @ (posedge clk_24M) begin

    if (reset) begin
        flip <= 0;
        scroll_x <= 0;
        scroll_y <= 0;
        prot_state <= 0;
    end else begin
        if (!m68k_rw & !m68k_lds_n & flip_cs) begin
            flip <= m68k_dout[2];
        end
        if (!m68k_rw & scroll_x_cs ) begin
            scroll_x <= m68k_dout[15:0];
        end

        if (!m68k_rw & scroll_y_cs ) begin
            scroll_y <= m68k_dout[15:0];
        end

        if (!m68k_rw & prot_chip_cmd_cs ) begin
            prot_cmd <= m68k_dout[7:0] ;
        end

        if (!m68k_rw & prot_chip_data_cs ) begin
            if ( prot_cmd == 8'h33 ) begin
                if ( prot_state == 0 ) begin
                    nb1412m2_addr[15:8] <= m68k_dout[7:0] ; 
                    prot_state <= 8'h11;
                end
            end else if ( prot_cmd == 8'h34 ) begin
                if ( prot_state == 0 ) begin
                    nb1412m2_addr[7:0] <= m68k_dout[7:0] ; 
                    prot_state <= 8'h21;
                end
            end else if ( prot_cmd == 8'h35 ) begin
                if ( prot_state == 0 ) begin
                    nb1412m2_addr[15:8] <= m68k_dout[7:0] ; 
                    prot_state <= 8'h31;
                end
            end else if ( prot_cmd == 8'h36 ) begin
                if ( prot_state == 0 ) begin
                    nb1412m2_addr[7:0] <= m68k_dout[7:0] ; 
                    prot_state <= 8'h41;
                end
            end
        end

        // writes to nb1412m2 are queued and handled here
        // each write to the nb1412m2 causes a read to the nb1412m2 rom
        // and updates the current decryted value
        if ( prot_state == 8'h11 ) begin
            // address now vaild, wait for read
            prot_state <= 8'h12;
        end else if ( prot_state == 8'h12 ) begin
            nb1412m2_rom_dout[7:0] <= nb1412m2_dout;
            prot_state <= 0;

        end else if ( prot_state == 8'h21 ) begin
            prot_state <= 8'h22;
        end else if ( prot_state == 8'h22 ) begin
            nb1412m2_rom_dout[7:0] <= nb1412m2_dout;
            prot_state <= 0;

        end else if ( prot_state == 8'h31 ) begin
            prot_state <= 8'h32;
        end else if ( prot_state == 8'h32 ) begin
            nb1412m2_adj_dout[7:0] <= nb1412m2_dout;
            prot_state <= 0;

        end else if ( prot_state == 8'h41 ) begin
            prot_state <= 8'h42;
        end else if ( prot_state == 8'h42 ) begin
            nb1412m2_adj_dout[7:0] <= nb1412m2_dout;
            prot_state <= 0;
        end
    end
end

reg [7:0]  prot_dout;
reg [15:0] prot_rom_addr;
reg [15:0] prot_adj_addr;
reg [7:0]  prot_cmd;
reg [7:0]  prot_state;

reg [15:0] nb1412m2_addr;
wire [7:0] nb1412m2_dout;

reg  [7:0] nb1412m2_adj_dout;
reg  [7:0] nb1412m2_rom_dout;
wire [7:0] nb1412m2_decrypt_dout = nb1412m2_rom_dout - ( 8'h43 - nb1412m2_adj_dout ) ;

//	prot_adj = (0x43 - m_data[m_adj_address]) & 0xff;
//	return m_data[m_rom_address & 0x1fff] - prot_adj;

dual_port_ram #(.LEN(8192)) nb1412m2_adj (
    .clock_a ( clk_24M ),
    .address_a ( nb1412m2_addr ),
    .wren_a ( 1'b0 ),
    .data_a ( ),
    .q_a ( nb1412m2_dout ),

    .clock_b ( clk_96M ),
    .address_b ( ioctl_addr[12:0] ),
    .wren_b ( nb1412m2_ioctl_wr ),
    .data_b ( ioctl_dout  ),
    .q_b( )
    );

wire [15:0] ram68k_dout;
wire [15:0] prog_rom_data;

// ioctl download addressing
`ifndef SDRAM
wire m68k_rom_h_ioctl_wr = rom_download & ioctl_wr & (ioctl_addr  <  24'h020000) & (ioctl_addr[0] == 1);
wire m68k_rom_l_ioctl_wr = rom_download & ioctl_wr & (ioctl_addr  <  24'h020000) & (ioctl_addr[0] == 0);

wire gfx2_ioctl_wr       = rom_download & ioctl_wr & (ioctl_addr >=  24'h020000) & (ioctl_addr <  24'h040000) ;
wire gfx3_ioctl_wr       = rom_download & ioctl_wr & (ioctl_addr >=  24'h040000) & (ioctl_addr <  24'h060000) ;
wire gfx1_ioctl_wr       = rom_download & ioctl_wr & (ioctl_addr >=  24'h060000) & (ioctl_addr <  24'h064000) ;

wire z80_rom_ioctl_wr    = rom_download & ioctl_wr & (ioctl_addr >=  24'h070000) & (ioctl_addr <  24'h07c000) ;
`endif

wire nb1412m2_ioctl_wr   = rom_download & ioctl_wr & (ioctl_addr >=  24'h07c000) & (ioctl_addr <  24'h07e000) ;

wire prom_r_wr           = rom_download & ioctl_wr & (ioctl_addr >=  24'h07E000) & (ioctl_addr <  24'h07E100) ;
wire prom_g_wr           = rom_download & ioctl_wr & (ioctl_addr >=  24'h07E100) & (ioctl_addr <  24'h07E200) ;
wire prom_b_wr           = rom_download & ioctl_wr & (ioctl_addr >=  24'h07E200) & (ioctl_addr <  24'h07E300) ;
wire prom_s_wr           = rom_download & ioctl_wr & (ioctl_addr >=  24'h07E300) & (ioctl_addr <  24'h07E400) ;
wire prom_u_wr           = rom_download & ioctl_wr & (ioctl_addr >=  24'h07E400) & (ioctl_addr <  24'h07E500) ;

reg [3:0] prom_r [255:0] ;
reg [3:0] prom_g [255:0] ;
reg [3:0] prom_b [255:0] ;
reg [3:0] prom_s [255:0] ;
reg [3:0] prom_u [255:0] ;

always @ (posedge clk_96M) begin

    if ( prom_r_wr == 1 ) begin
        prom_r[ioctl_addr[7:0]] <= ioctl_dout[3:0];
    end

    if ( prom_g_wr == 1 ) begin
        prom_g[ioctl_addr[7:0]] <= ioctl_dout[3:0];
    end

    if ( prom_b_wr == 1 ) begin
        prom_b[ioctl_addr[7:0]] <= ioctl_dout[3:0];
    end

    if ( prom_s_wr == 1 ) begin
        prom_s[ioctl_addr[7:0]] <= ioctl_dout[3:0];
    end

    if ( prom_u_wr == 1 ) begin
        prom_u[ioctl_addr[7:0]] <= ioctl_dout[3:0];
    end

end

`ifndef SDRAM
// main 68k ROM low
// 3.4d & 4.6d
dual_port_ram #(.LEN(65536)) rom64kx8_H (
    .clock_a ( clk_24M ),
    .address_a ( m68k_a[16:1] ),
    .wren_a ( 1'b0 ),
    .data_a ( ),
    .q_a ( prog_rom_data[15:8] ),
    
    .clock_b ( clk_96M ),
    .address_b ( ioctl_addr[16:1] ),
    .wren_b ( m68k_rom_h_ioctl_wr ),
    .data_b ( ioctl_dout  ),
    .q_b( )

    );

// main 68k ROM high 
// // rom 1.4b & 2.6b

dual_port_ram #(.LEN(65536)) rom64kx8_L (
    .clock_a ( clk_24M ),
    .address_a ( m68k_a[16:1] ),
    .wren_a ( 1'b0 ),
    .data_a ( ),
    .q_a ( prog_rom_data[7:0] ),
    
    .clock_b ( clk_96M ),
    .address_b ( ioctl_addr[16:1] ),
    .wren_b ( m68k_rom_l_ioctl_wr ),
    .data_b ( ioctl_dout  ),
    .q_b( )
    );
`endif

// main 68k ram high    
dual_port_ram #(.LEN(4096)) ram4kx8_H (
    .clock_a ( clk_24M ),
    .address_a ( m68k_a[12:1] ),
    .wren_a ( !m68k_rw & m68k_ram_cs & !m68k_uds_n ),
    .data_a ( m68k_dout[15:8]  ),
    .q_a (  ram68k_dout[15:8] )
    );

// main 68k ram low
// 0x200 shared with sound cpu
dual_port_ram #(.LEN(4096)) ram4kx8_L (
    .clock_a ( clk_24M ),
    .address_a ( m68k_a[12:1] ),
    .wren_a ( !m68k_rw & m68k_ram_cs & !m68k_lds_n ),
    .data_a ( m68k_dout[7:0]  ),
    .q_a ( ram68k_dout[7:0] ),

    .clock_b ( clk_24M ),
    .address_b ( sprite_shared_addr[7:0] ),  // 64 sprites * 4 bytes for each == 256
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( sprite_shared_ram_dout )
    );

`ifndef SDRAM
// z80 rom (48k)
dual_port_ram #(.LEN(16'hc000)) rom_z80 (
    .clock_a ( clk_24M ),
    .address_a ( z80_addr[15:0] ),
    .wren_a ( 1'b0 ),
    .data_a (  ),
    .q_a ( z80_rom_data ),

    .clock_b ( clk_96M ),
    .address_b ( ioctl_addr[15:0] ),
    .wren_b ( z80_rom_ioctl_wr ),
    .data_b ( ioctl_dout  ),
    .q_b( )
    );
`endif

// z80 ram
dual_port_ram #(.LEN(4096)) z80_ram (
    .clock_b ( clk_24M ),  // z80 clock is 4M
    .address_b ( z80_addr[11:0] ),
    .data_b ( z80_dout ),
    .wren_b ( z80_ram_cs & ~z80_wr_n ),
    .q_b ( z80_ram_dout )
    );

`ifndef SDRAM
//  <!-- gfx1   ioctl    0x060000-0x063fff 16K -->
dual_port_ram #(.LEN(16384)) gfx1 (
    .clock_a ( clk_24M ),
    .address_a ( gfx1_addr[13:0] ),
    .wren_a ( 1'b0 ),
    .data_a ( ),
    .q_a ( gfx1_dout[7:0] ),

    .clock_b ( clk_96M ),
    .address_b ( ioctl_addr[13:0] ),
    .wren_b ( gfx1_ioctl_wr ),
    .data_b ( ioctl_dout  ),
    .q_b( )
    );

//  <!-- gfx2   ioctl    0x020000-0x03FFFF 128K -->
dual_port_ram #(.LEN(131072)) gfx2 (
    .clock_a ( clk_24M ),
    .address_a ( gfx2_addr[16:0] ),
    .wren_a ( 1'b0 ),
    .data_a ( ),
    .q_a ( gfx2_dout[7:0] ),

    .clock_b ( clk_96M ),
    .address_b ( ioctl_addr[16:0] ),
    .wren_b ( gfx2_ioctl_wr ),
    .data_b ( ioctl_dout  ),
    .q_b( )
    );

//  <!-- gfx3   ioctl   0x40000-0x5fffff  128K -->     
dual_port_ram #(.LEN(131072)) gfx3 (
    .clock_a ( clk_24M ),
    .address_a ( gfx3_addr[16:0] ),
    .wren_a ( 1'b0 ),
    .data_a ( ),
    .q_a ( gfx3_dout[7:0] ),

    .clock_b ( clk_96M ),
    .address_b ( ioctl_addr[16:0] ),
    .wren_b ( gfx3_ioctl_wr ),
    .data_b ( ioctl_dout  ),
    .q_b( )
    );
`endif
reg   [9:0] fg_ram_addr;
wire [15:0] fg_ram_dout;

// 2 x 1k
dual_port_ram #(.LEN(2048)) fg_ram_l (
    .clock_a ( clk_24M ),
    .address_a ( m68k_a[11:1] ),
    .wren_a ( !m68k_rw & fg_ram_cs & !m68k_lds_n ),
    .data_a ( m68k_dout[7:0]  ),
    .q_a (  ),

    .clock_b ( clk_24M ),
    .address_b ( fg_ram_addr  ),
    .wren_b ( 1'b0 ),
    .data_b (  ),
    .q_b( fg_ram_dout[7:0]  )

    );

dual_port_ram #(.LEN(2048)) fg_ram_h (
    .clock_a ( clk_24M ),
    .address_a ( m68k_a[11:1] ),
    .wren_a ( !m68k_rw & fg_ram_cs & !m68k_lds_n ),
    .data_a ( m68k_dout[15:8]  ),
    .q_a (  ),

    .clock_b ( clk_24M ),
    .address_b ( fg_ram_addr  ),
    .wren_b ( 1'b0 ),
    .data_b (  ),
    .q_b( fg_ram_dout[15:8]  )
    );

reg  [11:0] bg_ram_addr;
wire [15:0] bg_ram_dout;

dual_port_ram #(.LEN(2048)) bg_ram_l (
    .clock_a ( clk_24M ),
    .address_a ( m68k_a[11:1] ),
    .wren_a ( !m68k_rw & bg_ram_cs & !m68k_lds_n ),
    .data_a ( m68k_dout[7:0]  ),
    .q_a (  ),

    .clock_b ( clk_24M ),
    .address_b ( bg_ram_addr  ),
    .wren_b ( 1'b0 ),
    .data_b (  ),
    .q_b( bg_ram_dout[7:0]  )

    );

dual_port_ram #(.LEN(2048)) bg_ram_h (
    .clock_a ( clk_24M ),
    .address_a ( m68k_a[11:1] ),
    .wren_a ( !m68k_rw & bg_ram_cs & !m68k_lds_n ),
    .data_a ( m68k_dout[15:8]  ),
    .q_a (  ),

    .clock_b ( clk_24M ),
    .address_b ( bg_ram_addr  ),
    .wren_b ( 1'b0 ),
    .data_b (  ),
    .q_b( bg_ram_dout[15:8]  )
    );

reg  [11:0] m68k_ram1_addr;
wire [15:0] m68k_ram1_dout;

dual_port_ram #(.LEN(2048)) m68k_ram1_l (
    .clock_a ( clk_24M ),
    .address_a ( m68k_a[11:1] ),
    .wren_a ( !m68k_rw & m68k_ram1_cs & !m68k_lds_n ),
    .data_a ( m68k_dout[7:0]  ),
    .q_a ( m68k_ram1_dout[7:0] )
    );

dual_port_ram #(.LEN(2048)) m68k_ram1_h (
    .clock_a ( clk_24M ),
    .address_a ( m68k_a[11:1] ),
    .wren_a ( !m68k_rw & m68k_ram1_cs & !m68k_lds_n ),
    .data_a ( m68k_dout[15:8]  ),
    .q_a ( m68k_ram1_dout[15:8] )
    );

//// external memory (SDRAM)
wire [15:0] m68k_rom_data;
wire m68k_rom_valid;
reg sprite_rom_req;
wire sprite_rom_ack;

`ifdef SDRAM

wire [31:0] sprite_rom_data;

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
reg  [16:2] sp_addr;

wire [15:0] cpu2_do;
assign      z80_rom_data = z80_addr[0] ? cpu2_do[15:8] : cpu2_do[7:0];

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
  .port1_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
  .port1_d       ( {ioctl_dout, ioctl_dout} ),
  .port1_q       (),

  // M68K
  .cpu1_rom_addr ( m68k_a[23:1]  ),
  .cpu1_rom_cs   ( prog_rom_cs   ),
  .cpu1_rom_q    ( prog_rom_data ),
  .cpu1_rom_valid( ),

  .cpu1_ram_req  ( 1'b0 ),
  .cpu1_ram_ack  ( ),
  .cpu1_ram_addr ( ),
  .cpu1_ram_we   ( ),
  .cpu1_ram_d    ( ),
  .cpu1_ram_q    ( ),
  .cpu1_ram_ds   ( ),

  // Audio Z80
  .cpu2_addr     ( {5'b00111, z80_addr[15:1]} ), // (ioctl_addr >=  24'h070000) & (ioctl_addr <  24'h07c000) ;
  .cpu2_rom_cs   ( z80_rom_cs  ),
  .cpu2_q        ( cpu2_do     ),
  .cpu2_valid    ( z80_rom_valid ),

  // Bootleg Z80
  .cpu3_addr     ( ),
  .cpu3_rom_cs   ( 1'b0 ),
  .cpu3_q        ( ),
  .cpu3_valid    ( ),

  // NB1414M4
  .cpu4_addr     ( ),
  .cpu4_q        ( ),
  .cpu4_valid    ( ),

  // Bank 2-3 ops
  .port2_a       ( ioctl_addr[23:1] ),
  .port2_req     ( port2_req ),
  .port2_ack     (),
  .port2_we      ( rom_download ),
  .port2_ds      ( {ioctl_addr[0], ~ioctl_addr[0]} ),
  .port2_d       ( {ioctl_dout, ioctl_dout} ),
  .port2_q       (),

  .gfx1_addr     ( {5'b00110, 2'b00, gfx1_addr[13:2]} ), // (ioctl_addr >=  24'h060000) & (ioctl_addr <  24'h064000)
  .gfx1_q        ( gfx1_q ),
  
  .gfx2_addr     ( {4'b0001, gfx2_addr[16:2]} ),      // (ioctl_addr >=  24'h020000) & (ioctl_addr <  24'h040000)
  .gfx2_q        ( gfx2_q ),

  .gfx3_addr     (  ),
  .gfx3_q        (  ),

  .sp_addr       ( {4'b0010, gfx3_addr[16:2]} ), // (ioctl_addr >=  24'h040000) & (ioctl_addr <  24'h060000)
  .sp_req        ( sprite_rom_req   ),
  .sp_ack        ( sprite_rom_ack   ),
  .sp_q          ( sprite_rom_data  )
);

always @(posedge clk_24M) begin
    if (clk6_en) begin

        case ({flip, hc[2:0]})
            4'b0011: gfx1_dout <= gfx1_q[ 7: 0];
            4'b0101: gfx1_dout <= gfx1_q[15: 8];
            4'b0111: gfx1_dout <= gfx1_q[23:16];
            4'b0001: gfx1_dout <= gfx1_q[31:24];

            4'b1000: gfx1_dout <= gfx1_q[ 7: 0];
            4'b1110: gfx1_dout <= gfx1_q[15: 8];
            4'b1100: gfx1_dout <= gfx1_q[23:16];
            4'b1010: gfx1_dout <= gfx1_q[31:24];
            default: ;
        endcase

        case ({flip, hc_s[2:0]})
            4'b0011: gfx2_dout <= gfx2_q[ 7: 0];
            4'b0101: gfx2_dout <= gfx2_q[15: 8];
            4'b0111: gfx2_dout <= gfx2_q[23:16];
            4'b0001: gfx2_dout <= gfx2_q[31:24];

            4'b1111: gfx2_dout <= gfx2_q[ 7: 0];
            4'b1001: gfx2_dout <= gfx2_q[15: 8];
            4'b1011: gfx2_dout <= gfx2_q[23:16];
            4'b1101: gfx2_dout <= gfx2_q[31:24];
            default: ;
        endcase
    end
end

always @(*) begin
    case (flipped_x[3:2])
        2'b00: gfx3_dout = sprite_rom_data[ 7: 0];
        2'b01: gfx3_dout = sprite_rom_data[15: 8];
        2'b10: gfx3_dout = sprite_rom_data[23:16];
        2'b11: gfx3_dout = sprite_rom_data[31:24];
        default: ;
    endcase
end
`else // not SDRAM
assign sprite_rom_ack = sprite_rom_req;
assign z80_rom_valid = 1'b1;
assign SDRAM_A = 0;
assign SDRAM_BA = 0;
assign SDRAM_DQML = 1;
assign SDRAM_DQMH = 1;
assign SDRAM_nCS = 1;
assign SDRAM_nCAS = 1;
assign SDRAM_nRAS = 1;
assign SDRAM_nWE = 1;
assign SDRAM_DQ = 16'hZZZZ;
`endif 

endmodule
