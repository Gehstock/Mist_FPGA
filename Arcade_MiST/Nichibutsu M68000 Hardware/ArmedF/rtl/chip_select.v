//

module chip_select
(
    input  [3:0] pcb,

    input [23:0] m68k_a,
    input        m68k_as_n,
    input        m68k_lds_n,
    input        m68k_uds_n,

    input [15:0] z80_addr,
    input        RFSH_n,
    input        MREQ_n,
    input        IORQ_n,
    input        M1_n,

    // M68K selects
    output reg m68k_rom_cs,
    output reg m68k_ram_cs,
    output reg m68k_tile_pal_cs,
    output reg m68k_txt_ram_cs,
    output reg m68k_ram_2_cs,
    output reg m68k_ram_3_cs,
    output reg m68k_spr_cs,
    output reg m68k_spr_pal_cs,
    output reg m68k_fg_ram_cs,
    output reg m68k_bg_ram_cs,
    output reg input_p1_cs,
    output reg input_p2_cs,
    output reg input_dsw1_cs,
    output reg input_dsw2_cs,
    output reg irq_z80_cs,
    output reg bg_scroll_x_cs,
    output reg bg_scroll_y_cs,
    output reg fg_scroll_x_cs,
    output reg fg_scroll_y_cs,
    output reg sound_latch_cs,
    output reg irq_ack_cs,
    output reg irq_i8751_cs,

    // Z80 selects
    output reg   z80_rom_cs,
    output reg   z80_ram_cs,

    output reg   z80_sound0_cs,
    output reg   z80_sound1_cs,
    output reg   z80_dac1_cs,
    output reg   z80_dac2_cs,
    output reg   z80_latch_clr_cs,
    output reg   z80_latch_r_cs

);

`include "defs.v"

function m68k_cs;
        input [23:0] start_address;
        input [23:0] end_address;
begin
    m68k_cs = ( m68k_a[23:0] >= start_address && m68k_a[23:0] <= end_address) & !m68k_as_n & ~(m68k_uds_n & m68k_lds_n);
end
endfunction

function z80_mem_cs;
        input [15:0] base_address;
        input  [7:0] width;
begin
    z80_mem_cs = ( z80_addr >> width == base_address >> width ) & !MREQ_n & RFSH_n;
end
endfunction

function z80_io_cs;
        input [7:0] address_lo;
begin
    z80_io_cs = ( IORQ_n == 0 && z80_addr[7:0] == address_lo );
end
endfunction

always @ (*) begin
    m68k_rom_cs      = 0;
    m68k_spr_cs      = 0;
    m68k_ram_cs      = 0;

    m68k_tile_pal_cs = 0;
    m68k_txt_ram_cs  = 0;
    m68k_ram_2_cs    = 0;
    m68k_spr_pal_cs  = 0;

    m68k_fg_ram_cs   = 0;
    m68k_bg_ram_cs   = 0;

    input_p1_cs      = 0;
    input_p2_cs      = 0;
    input_dsw1_cs    = 0;
    input_dsw2_cs    = 0;

    irq_z80_cs       = 0;

    bg_scroll_x_cs   = 0;
    bg_scroll_y_cs   = 0;

    fg_scroll_y_cs   = 0;
    fg_scroll_x_cs   = 0;

    sound_latch_cs   = 0;
    irq_ack_cs       = 0;

    
    m68k_ram_3_cs    = 0;
    irq_i8751_cs     = 0;

    z80_rom_cs       = 0;
    z80_ram_cs       = 0;

    z80_sound0_cs    = 0;
    z80_sound1_cs    = 0;
    z80_dac1_cs      = 0;
    z80_dac2_cs      = 0;
    z80_latch_clr_cs = 0;
    z80_latch_r_cs   = 0;
    // Memory mapping based on PCB type
    case (pcb)
        pcb_terraf: begin

            m68k_rom_cs      = m68k_cs( 24'h000000, 24'h05ffff ) ;
            m68k_spr_cs      = m68k_cs( 24'h060000, 24'h0603ff ) ; // 1k
            m68k_ram_cs      = m68k_cs( 24'h060400, 24'h063fff ) ; // 15k

            m68k_tile_pal_cs = m68k_cs( 24'h064000, 24'h064fff ) ; // 4k
            m68k_txt_ram_cs  = m68k_cs( 24'h068000, 24'h069fff ) ; // 4k shared (1k tile attr) low byte
            m68k_ram_2_cs    = m68k_cs( 24'h06a000, 24'h06afff ) ; // 4k
            m68k_spr_pal_cs  = m68k_cs( 24'h06c000, 24'h06cfff ) ; // 4k

            m68k_fg_ram_cs   = m68k_cs( 24'h070000, 24'h070fff ) ; // 4k
            m68k_bg_ram_cs   = m68k_cs( 24'h074000, 24'h074fff ) ; // 4k

            input_p1_cs      = m68k_cs( 24'h078000, 24'h078001 ) ; // P1
            input_p2_cs      = m68k_cs( 24'h078002, 24'h078003 ) ; // P2
            input_dsw1_cs    = m68k_cs( 24'h078004, 24'h078005 ) ; // DSW1
            input_dsw2_cs    = m68k_cs( 24'h078006, 24'h078007 ) ; // DSW2

            irq_z80_cs       = m68k_cs( 24'h07c000, 24'h07c001 ) ; // z80 interrupt

            bg_scroll_x_cs   = m68k_cs( 24'h07c002, 24'h07c003 ) ; // SCROLL X
            bg_scroll_y_cs   = m68k_cs( 24'h07c004, 24'h07c005 ) ; // SCROLL Y

            sound_latch_cs   = m68k_cs( 24'h07c00a, 24'h07c00b ) ; // sound latch
            irq_ack_cs       = m68k_cs( 24'h07c00e, 24'h07c00f ) ; // irq ack

            fg_scroll_y_cs   = 0 ;
            fg_scroll_x_cs   = 0 ;

            m68k_ram_3_cs    = 0 ; // unused
            irq_i8751_cs     = 0 ; // unused

            z80_rom_cs       = ( !MREQ_n && RFSH_n && z80_addr[15:0]  < 16'hf800 );
            z80_ram_cs       = ( !MREQ_n && RFSH_n && z80_addr[15:0] >= 16'hf800 );

            z80_sound0_cs    = z80_io_cs(8'h00);
            z80_sound1_cs    = z80_io_cs(8'h01);
            z80_dac1_cs      = z80_io_cs(8'h02);
            z80_dac2_cs      = z80_io_cs(8'h03);
            z80_latch_clr_cs = z80_io_cs(8'h04);
            z80_latch_r_cs   = z80_io_cs(8'h06);
        end

        pcb_kozure: begin

            m68k_rom_cs      = m68k_cs( 24'h000000, 24'h05ffff ) ;

            m68k_spr_cs      = m68k_cs( 24'h060000, 24'h060fff ) ; // 4k
            m68k_ram_cs      = m68k_cs( 24'h061000, 24'h063fff ) ; // 12k

            m68k_tile_pal_cs = m68k_cs( 24'h064000, 24'h064fff ) ; // 4k
            m68k_txt_ram_cs  = m68k_cs( 24'h068000, 24'h069fff ) ; // 4k shared (1k tile attr) low byte
            m68k_spr_pal_cs  = m68k_cs( 24'h06c000, 24'h06cfff ) ; // 4k

            m68k_fg_ram_cs   = m68k_cs( 24'h070000, 24'h070fff ) ; // 4k
            m68k_bg_ram_cs   = m68k_cs( 24'h074000, 24'h074fff ) ; // 4k

            input_p1_cs      = m68k_cs( 24'h078000, 24'h078001 ) ; // P1
            input_p2_cs      = m68k_cs( 24'h078002, 24'h078003 ) ; // P2
            input_dsw1_cs    = m68k_cs( 24'h078004, 24'h078005 ) ; // DSW1
            input_dsw2_cs    = m68k_cs( 24'h078006, 24'h078007 ) ; // DSW2

            irq_z80_cs       = m68k_cs( 24'h07c000, 24'h07c001 ) ; // z80 interrupt

            bg_scroll_x_cs   = m68k_cs( 24'h07c002, 24'h07c003 ) ; // SCROLL X
            bg_scroll_y_cs   = m68k_cs( 24'h07c004, 24'h07c005 ) ; // SCROLL Y

            sound_latch_cs   = m68k_cs( 24'h07c00a, 24'h07c00b ) ; // sound latch
            irq_ack_cs       = m68k_cs( 24'h07c00e, 24'h07c00f ) ; // irq ack

            irq_i8751_cs     = 0 ; // unused
            m68k_ram_3_cs    = m68k_cs( 24'h080000, 24'h800fff ) ; // 4k debug ram support

            z80_rom_cs       = ( !MREQ_n && RFSH_n && z80_addr[15:0]  < 16'hf800 );
            z80_ram_cs       = ( !MREQ_n && RFSH_n && z80_addr[15:0] >= 16'hf800 );

            z80_sound0_cs    = z80_io_cs(8'h00);
            z80_sound1_cs    = z80_io_cs(8'h01);
            z80_dac1_cs      = z80_io_cs(8'h02);
            z80_dac2_cs      = z80_io_cs(8'h03);
            z80_latch_clr_cs = z80_io_cs(8'h04);
            z80_latch_r_cs   = z80_io_cs(8'h06);
        end
        
        pcb_armedf: begin
            m68k_rom_cs      = m68k_cs( 24'h000000, 24'h05ffff ) ;
            
            m68k_spr_cs      = m68k_cs( 24'h060000, 24'h0603ff ) ; // 1k
            m68k_ram_cs      = m68k_cs( 24'h060400, 24'h063fff ) ; // 15k
            
            m68k_ram_2_cs    = m68k_cs( 24'h064000, 24'h065fff ) ; // 8k  

            m68k_bg_ram_cs   = m68k_cs( 24'h066000, 24'h066fff ) ; // 4k
            m68k_fg_ram_cs   = m68k_cs( 24'h067000, 24'h067fff ) ; // 4k

            m68k_txt_ram_cs  = m68k_cs( 24'h068000, 24'h069fff ) ; // 8k shared (1k tile attr) low byte

            m68k_tile_pal_cs = m68k_cs( 24'h06a000, 24'h06afff ) ; // 4k
            
            m68k_spr_pal_cs  = m68k_cs( 24'h06b000, 24'h06bfff ) ; // 4k

            input_p1_cs      = m68k_cs( 24'h06c000, 24'h06c001 ) ; // P1
            input_p2_cs      = m68k_cs( 24'h06c002, 24'h06c003 ) ; // P2
            input_dsw1_cs    = m68k_cs( 24'h06c004, 24'h06c005 ) ; // DSW1
            input_dsw2_cs    = m68k_cs( 24'h06c006, 24'h06c007 ) ; // DSW2
            
            m68k_ram_3_cs    = m68k_cs( 24'h06c008, 24'h06c7ff ) ; // 4k  *** x2

            bg_scroll_x_cs   = m68k_cs( 24'h06d002, 24'h06d003 ) ; // SCROLL X
            bg_scroll_y_cs   = m68k_cs( 24'h06d004, 24'h06d005 ) ; // SCROLL Y

            fg_scroll_x_cs   = m68k_cs( 24'h06d006, 24'h06d007 ) ; // SCROLL X
            fg_scroll_y_cs   = m68k_cs( 24'h06d008, 24'h06d009 ) ; // SCROLL Y

            irq_z80_cs       = m68k_cs( 24'h06d000, 24'h06d001 ) ; // 
            irq_i8751_cs     = 0;
            
            sound_latch_cs   = m68k_cs( 24'h06d00a, 24'h06d00b ) ; // sound latch

            irq_ack_cs       = m68k_cs( 24'h06d00e, 24'h06d00f ) ; // irq ack

            z80_rom_cs       = ( !MREQ_n && RFSH_n && z80_addr[15:0]  < 16'hf800 );
            z80_ram_cs       = ( !MREQ_n && RFSH_n && z80_addr[15:0] >= 16'hf800 );

            z80_sound0_cs    = z80_io_cs(8'h00);
            z80_sound1_cs    = z80_io_cs(8'h01);
            z80_dac1_cs      = z80_io_cs(8'h02);
            z80_dac2_cs      = z80_io_cs(8'h03);
            z80_latch_clr_cs = z80_io_cs(8'h04);
            z80_latch_r_cs   = z80_io_cs(8'h06);
        end        


        pcb_bigfghtr: begin

            m68k_rom_cs      = m68k_cs( 24'h000000, 24'h07ffff ) ;

            m68k_spr_cs      = m68k_cs( 24'h080000, 24'h0805ff ) ; // 4k
            m68k_ram_cs      = m68k_cs( 24'h080600, 24'h083fff ) ; // 12k

            m68k_ram_2_cs    = m68k_cs( 24'h084000, 24'h085fff ) ; //

            m68k_bg_ram_cs   = m68k_cs( 24'h086000, 24'h086fff ) ; // 4k
            m68k_fg_ram_cs   = m68k_cs( 24'h087000, 24'h087fff ) ; // 4k

            m68k_txt_ram_cs  = m68k_cs( 24'h088000, 24'h089fff ) ; // 4k shared (1k tile attr) low byte
            m68k_tile_pal_cs = m68k_cs( 24'h08a000, 24'h08afff ) ; // 4k
            m68k_spr_pal_cs  = m68k_cs( 24'h08b000, 24'h08bfff ) ; // 4k

            input_p1_cs      = m68k_cs( 24'h08c000, 24'h08c001 ) ; // P1
            input_p2_cs      = m68k_cs( 24'h08c002, 24'h08c003 ) ; // P2
            input_dsw1_cs    = m68k_cs( 24'h08c004, 24'h08c005 ) ; // DSW0
            input_dsw2_cs    = m68k_cs( 24'h08c006, 24'h08c007 ) ; // DSW1

            irq_z80_cs       = m68k_cs( 24'h08d000, 24'h08d001 ) ; // z80 interrupt

            bg_scroll_x_cs   = m68k_cs( 24'h08d002, 24'h08d003 ) ; // SCROLL X
            bg_scroll_y_cs   = m68k_cs( 24'h08d004, 24'h08d005 ) ; // SCROLL Y

            fg_scroll_x_cs   = m68k_cs( 24'h08d006, 24'h08d007 ) ; // SCROLL X
            fg_scroll_y_cs   = m68k_cs( 24'h08d008, 24'h08d009 ) ; // SCROLL Y

            sound_latch_cs   = m68k_cs( 24'h08d00a, 24'h08d00b ) ; // sound latch
            irq_ack_cs       = m68k_cs( 24'h08d00e, 24'h08d00f ) ; // irq ack

            irq_i8751_cs     = m68k_cs( 24'h400000, 24'h400001 ) ; // i8751 interrupt

            z80_rom_cs       = ( !MREQ_n && RFSH_n && z80_addr[15:0]  < 16'hf800 );
            z80_ram_cs       = ( !MREQ_n && RFSH_n && z80_addr[15:0] >= 16'hf800 );

            z80_sound0_cs    = z80_io_cs(8'h00);
            z80_sound1_cs    = z80_io_cs(8'h01);
            z80_dac1_cs      = z80_io_cs(8'h02);
            z80_dac2_cs      = z80_io_cs(8'h03);
            z80_latch_clr_cs = z80_io_cs(8'h04);
            z80_latch_r_cs   = z80_io_cs(8'h06);
        end

        pcb_cclimbr2: begin

            m68k_rom_cs      = m68k_cs( 24'h000000, 24'h05ffff ) ;

            m68k_spr_cs      = m68k_cs( 24'h060000, 24'h060fff ) ; // 4k
            m68k_ram_cs      = m68k_cs( 24'h061000, 24'h063fff ) ; // 12k

            m68k_tile_pal_cs = m68k_cs( 24'h064000, 24'h064fff ) ; // 4k
            m68k_txt_ram_cs  = m68k_cs( 24'h068000, 24'h069fff ) ; // 4k shared (1k tile attr) low byte
            m68k_ram_3_cs    = m68k_cs( 24'h06a000, 24'h06a9ff ) ; // 4k *** x2
            m68k_spr_pal_cs  = m68k_cs( 24'h06c000, 24'h06cfff ) ; // 4k

            m68k_fg_ram_cs   = m68k_cs( 24'h070000, 24'h070fff ) ; // 4k
            m68k_bg_ram_cs   = m68k_cs( 24'h074000, 24'h074fff ) ; // 4k

            input_p1_cs      = m68k_cs( 24'h078000, 24'h078001 ) ; // P1
            input_p2_cs      = m68k_cs( 24'h078002, 24'h078003 ) ; // P2
            input_dsw1_cs    = m68k_cs( 24'h078004, 24'h078005 ) ; // DSW1
            input_dsw2_cs    = m68k_cs( 24'h078006, 24'h078007 ) ; // DSW2

            irq_z80_cs       = m68k_cs( 24'h07c000, 24'h07c001 ) ; // z80 interrupt

            bg_scroll_x_cs   = m68k_cs( 24'h07c002, 24'h07c003 ) ; // SCROLL X
            bg_scroll_y_cs   = m68k_cs( 24'h07c004, 24'h07c005 ) ; // SCROLL Y

            sound_latch_cs   = m68k_cs( 24'h07c00a, 24'h07c00b ) ; // sound latch
            irq_ack_cs       = m68k_cs( 24'h07c00e, 24'h07c00f ) ; // irq ack

            irq_i8751_cs     = 0 ; // unused
            fg_scroll_x_cs   = 0 ;
            fg_scroll_y_cs   = 0 ;

            z80_rom_cs       = ( !MREQ_n && RFSH_n && z80_addr[15:0]  < 16'hc000 );
            z80_ram_cs       = ( !MREQ_n && RFSH_n && z80_addr[15:0] >= 16'hc000 );

            z80_sound0_cs    = z80_io_cs(8'h00);
            z80_sound1_cs    = z80_io_cs(8'h01);
            z80_dac1_cs      = z80_io_cs(8'h02);
            z80_dac2_cs      = z80_io_cs(8'h03);
            z80_latch_clr_cs = z80_io_cs(8'h04);
            z80_latch_r_cs   = z80_io_cs(8'h06);
        end

        pcb_legion: begin

            m68k_rom_cs      = m68k_cs( 24'h000000, 24'h03ffff ) ;

            m68k_spr_cs      = m68k_cs( 24'h060000, 24'h060fff ) ; // 4k
            m68k_ram_cs      = m68k_cs( 24'h061000, 24'h063fff ) ; // 12k

            m68k_tile_pal_cs = m68k_cs( 24'h064000, 24'h064fff ) ; // 4k
            m68k_txt_ram_cs  = m68k_cs( 24'h068000, 24'h069fff ) ; // 4k shared (1k tile attr) low byte
            m68k_ram_3_cs    = m68k_cs( 24'h06a000, 24'h06a9ff ) ; // 4k *** x2
            m68k_spr_pal_cs  = m68k_cs( 24'h06c000, 24'h06cfff ) ; // 4k

            m68k_fg_ram_cs   = m68k_cs( 24'h070000, 24'h070fff ) ; // 4k
            m68k_bg_ram_cs   = m68k_cs( 24'h074000, 24'h074fff ) ; // 4k

            irq_z80_cs       = m68k_cs( 24'h07c000, 24'h07c001 ) ; // z80 interrupt

            input_p1_cs      = m68k_cs( 24'h078000, 24'h078001 ) ; // P1
            input_p2_cs      = m68k_cs( 24'h078002, 24'h078003 ) ; // P2
            input_dsw1_cs    = m68k_cs( 24'h078004, 24'h078005 ) ; // DSW1
            input_dsw2_cs    = m68k_cs( 24'h078006, 24'h078007 ) ; // DSW2

            bg_scroll_x_cs   = m68k_cs( 24'h07c002, 24'h07c003 ) ; // SCROLL X
            bg_scroll_y_cs   = m68k_cs( 24'h07c004, 24'h07c005 ) ; // SCROLL Y

            sound_latch_cs   = m68k_cs( 24'h07c00a, 24'h07c00b ) ; // sound latch
            irq_ack_cs       = m68k_cs( 24'h07c00e, 24'h07c00f ) ; // irq ack

            irq_i8751_cs     = 0 ; // unused
            fg_scroll_x_cs   = 0 ;
            fg_scroll_y_cs   = 0 ;


            z80_rom_cs       = ( !MREQ_n && RFSH_n && z80_addr[15:0]  < 16'hc000 );
            z80_ram_cs       = ( !MREQ_n && RFSH_n && z80_addr[15:0] >= 16'hc000 );

            z80_sound0_cs    = z80_io_cs(8'h00);
            z80_sound1_cs    = z80_io_cs(8'h01);
            z80_dac1_cs      = z80_io_cs(8'h02);
            z80_dac2_cs      = z80_io_cs(8'h03);
            z80_latch_clr_cs = z80_io_cs(8'h04);
            z80_latch_r_cs   = z80_io_cs(8'h06);
        end

        pcb_legionjb: begin

            m68k_rom_cs      = m68k_cs( 24'h000000, 24'h03ffff ) ;

            fg_scroll_y_cs   = m68k_cs( 24'h040016, 24'h040019 ) ; // SCROLL X
            fg_scroll_x_cs   = m68k_cs( 24'h04001a, 24'h04001d ) ; // SCROLL Y

            m68k_spr_cs      = m68k_cs( 24'h060000, 24'h060fff ) ; // 4k
            m68k_ram_cs      = m68k_cs( 24'h061000, 24'h063fff ) ; // 12k

            m68k_tile_pal_cs = m68k_cs( 24'h064000, 24'h064fff ) ; // 4k
            m68k_txt_ram_cs  = m68k_cs( 24'h068000, 24'h069fff ) ; // 4k shared (1k tile attr) low byte
            m68k_ram_3_cs    = m68k_cs( 24'h06a000, 24'h06a9ff ) ; // 4k *** x2
            m68k_spr_pal_cs  = m68k_cs( 24'h06c000, 24'h06cfff ) ; // 4k

            m68k_fg_ram_cs   = m68k_cs( 24'h070000, 24'h070fff ) ; // 4k
            m68k_bg_ram_cs   = m68k_cs( 24'h074000, 24'h074fff ) ; // 4k

            irq_z80_cs       = m68k_cs( 24'h07c000, 24'h07c001 ) ; // z80 interrupt

            input_p1_cs      = m68k_cs( 24'h078000, 24'h078001 ) ; // P1
            input_p2_cs      = m68k_cs( 24'h078002, 24'h078003 ) ; // P2
            input_dsw1_cs    = m68k_cs( 24'h078004, 24'h078005 ) ; // DSW1
            input_dsw2_cs    = m68k_cs( 24'h078006, 24'h078007 ) ; // DSW2

            bg_scroll_x_cs   = m68k_cs( 24'h07c002, 24'h07c003 ) ; // SCROLL X
            bg_scroll_y_cs   = m68k_cs( 24'h07c004, 24'h07c005 ) ; // SCROLL Y

            sound_latch_cs   = m68k_cs( 24'h07c00a, 24'h07c00b ) ; // sound latch
            irq_ack_cs       = m68k_cs( 24'h07c00e, 24'h07c00f ) ; // irq ack

            irq_i8751_cs     = 0 ; // unused

            z80_rom_cs       = ( !MREQ_n && RFSH_n && z80_addr[15:0]  < 16'hc000 );
            z80_ram_cs       = ( !MREQ_n && RFSH_n && z80_addr[15:0] >= 16'hc000 );

            z80_sound0_cs    = z80_io_cs(8'h00);
            z80_sound1_cs    = z80_io_cs(8'h01);
            z80_dac1_cs      = z80_io_cs(8'h02);
            z80_dac2_cs      = z80_io_cs(8'h03);
            z80_latch_clr_cs = z80_io_cs(8'h04);
            z80_latch_r_cs   = z80_io_cs(8'h06);
        end

        pcb_legionjb2: begin

            m68k_rom_cs      = m68k_cs( 24'h000000, 24'h03ffff ) ;

            // fg_scroll is write only. fg_scroll_y_cs handles both x & y. m68k_rom_cs will also be asserted
            fg_scroll_y_cs   = m68k_cs( 24'h000016, 24'h000019 ) ; // SCROLL X
            fg_scroll_x_cs   = m68k_cs( 24'h00001a, 24'h00001d ) ; // SCROLL Y

            m68k_spr_cs      = m68k_cs( 24'h060000, 24'h060fff ) ; // 4k
            m68k_ram_cs      = m68k_cs( 24'h061000, 24'h063fff ) ; // 12k

            m68k_tile_pal_cs = m68k_cs( 24'h064000, 24'h064fff ) ; // 4k
            m68k_txt_ram_cs  = m68k_cs( 24'h068000, 24'h069fff ) ; // 4k shared (1k tile attr) low byte
            m68k_ram_3_cs    = m68k_cs( 24'h06a000, 24'h06a9ff ) ; // 4k *** x2
            m68k_spr_pal_cs  = m68k_cs( 24'h06c000, 24'h06cfff ) ; // 4k

            m68k_fg_ram_cs   = m68k_cs( 24'h070000, 24'h070fff ) ; // 4k
            m68k_bg_ram_cs   = m68k_cs( 24'h074000, 24'h074fff ) ; // 4k

            irq_z80_cs       = m68k_cs( 24'h07c000, 24'h07c001 ) ; // z80 interrupt

            input_p1_cs      = m68k_cs( 24'h078000, 24'h078001 ) ; // P1
            input_p2_cs      = m68k_cs( 24'h078002, 24'h078003 ) ; // P2
            input_dsw1_cs    = m68k_cs( 24'h078004, 24'h078005 ) ; // DSW1
            input_dsw2_cs    = m68k_cs( 24'h078006, 24'h078007 ) ; // DSW2

            bg_scroll_x_cs   = m68k_cs( 24'h07c002, 24'h07c003 ) ; // SCROLL X
            bg_scroll_y_cs   = m68k_cs( 24'h07c004, 24'h07c005 ) ; // SCROLL Y

            sound_latch_cs   = m68k_cs( 24'h07c00a, 24'h07c00b ) ; // sound latch
            irq_ack_cs       = m68k_cs( 24'h07c00e, 24'h07c00f ) ; // irq ack

            irq_i8751_cs     = 0 ; // unused

            z80_rom_cs       = ( !MREQ_n && RFSH_n && z80_addr[15:0]  < 16'hc000 );
            z80_ram_cs       = ( !MREQ_n && RFSH_n && z80_addr[15:0] >= 16'hc000 );

            z80_sound0_cs    = z80_io_cs(8'h00);
            z80_sound1_cs    = z80_io_cs(8'h01);
            z80_dac1_cs      = z80_io_cs(8'h02);
            z80_dac2_cs      = z80_io_cs(8'h03);
            z80_latch_clr_cs = z80_io_cs(8'h04);
            z80_latch_r_cs   = z80_io_cs(8'h06);
        end

        pcb_terrafjb: begin

            m68k_rom_cs      = m68k_cs( 24'h000000, 24'h05ffff ) ;
            m68k_spr_cs      = m68k_cs( 24'h060000, 24'h0603ff ) ; // 1k
            m68k_ram_cs      = m68k_cs( 24'h060400, 24'h063fff ) ; // 15k

            m68k_tile_pal_cs = m68k_cs( 24'h064000, 24'h064fff ) ; // 4k
            m68k_txt_ram_cs  = m68k_cs( 24'h068000, 24'h069fff ) ; // 4k shared (1k tile attr) low byte
            m68k_ram_2_cs    = m68k_cs( 24'h06a000, 24'h06afff ) ; // 4k
            m68k_spr_pal_cs  = m68k_cs( 24'h06c000, 24'h06cfff ) ; // 4k

            m68k_fg_ram_cs   = m68k_cs( 24'h070000, 24'h070fff ) ; // 4k
            m68k_bg_ram_cs   = m68k_cs( 24'h074000, 24'h074fff ) ; // 4k

            input_p1_cs      = m68k_cs( 24'h078000, 24'h078001 ) ; // P1
            input_p2_cs      = m68k_cs( 24'h078002, 24'h078003 ) ; // P2
            input_dsw1_cs    = m68k_cs( 24'h078004, 24'h078005 ) ; // DSW1
            input_dsw2_cs    = m68k_cs( 24'h078006, 24'h078007 ) ; // DSW2

            irq_z80_cs       = m68k_cs( 24'h07c000, 24'h07c001 ) ; // z80 interrupt

            bg_scroll_x_cs   = m68k_cs( 24'h07c002, 24'h07c003 ) ; // SCROLL X
            bg_scroll_y_cs   = m68k_cs( 24'h07c004, 24'h07c005 ) ; // SCROLL Y

            sound_latch_cs   = m68k_cs( 24'h07c00a, 24'h07c00b ) ; // sound latch
            irq_ack_cs       = m68k_cs( 24'h07c00e, 24'h07c00f ) ; // irq ack

            fg_scroll_y_cs   = 0 ; // unused
            fg_scroll_x_cs   = 0 ; // unused

            m68k_ram_3_cs    = 0 ; // unused
            irq_i8751_cs     = 0 ; // unused

            z80_rom_cs       = ( !MREQ_n && RFSH_n && z80_addr[15:0]  < 16'hf800 );
            z80_ram_cs       = ( !MREQ_n && RFSH_n && z80_addr[15:0] >= 16'hf800 );

            z80_sound0_cs    = z80_io_cs(8'h00);
            z80_sound1_cs    = z80_io_cs(8'h01);
            z80_dac1_cs      = z80_io_cs(8'h02);
            z80_dac2_cs      = z80_io_cs(8'h03);
            z80_latch_clr_cs = z80_io_cs(8'h04);
            z80_latch_r_cs   = z80_io_cs(8'h06);
        end

        pcb_terrafb: begin

            m68k_rom_cs      = m68k_cs( 24'h000000, 24'h05ffff ) ;
            m68k_spr_cs      = m68k_cs( 24'h060000, 24'h0603ff ) ; // 1k
            m68k_ram_cs      = m68k_cs( 24'h060400, 24'h063fff ) ; // 15k

            m68k_tile_pal_cs = m68k_cs( 24'h064000, 24'h064fff ) ; // 4k
            m68k_txt_ram_cs  = m68k_cs( 24'h068000, 24'h069fff ) ; // 4k shared (1k tile attr) low byte
            m68k_ram_2_cs    = m68k_cs( 24'h06a000, 24'h06afff ) ; // 4k
            m68k_spr_pal_cs  = m68k_cs( 24'h06c000, 24'h06cfff ) ; // 4k

            m68k_fg_ram_cs   = m68k_cs( 24'h070000, 24'h070fff ) ; // 4k
            m68k_bg_ram_cs   = m68k_cs( 24'h074000, 24'h074fff ) ; // 4k

            input_p1_cs      = m68k_cs( 24'h078000, 24'h078001 ) ; // P1
            input_p2_cs      = m68k_cs( 24'h078002, 24'h078003 ) ; // P2
            input_dsw1_cs    = m68k_cs( 24'h078004, 24'h078005 ) ; // DSW1
            input_dsw2_cs    = m68k_cs( 24'h078006, 24'h078007 ) ; // DSW2

            irq_z80_cs       = m68k_cs( 24'h07c000, 24'h07c001 ) ; // z80 interrupt

            bg_scroll_x_cs   = m68k_cs( 24'h07c002, 24'h07c003 ) ; // SCROLL X
            bg_scroll_y_cs   = m68k_cs( 24'h07c004, 24'h07c005 ) ; // SCROLL Y

            fg_scroll_y_cs   = m68k_cs( 24'h07c006, 24'h07c007 ) ; // SCROLL Y
            fg_scroll_x_cs   = m68k_cs( 24'h07c008, 24'h07c009 ) ; // SCROLL X

            sound_latch_cs   = m68k_cs( 24'h07c00a, 24'h07c00b ) ; // sound latch
            irq_ack_cs       = m68k_cs( 24'h07c00e, 24'h07c00f ) ; // irq ack

    
            m68k_ram_3_cs    = 0 ; // unused
            irq_i8751_cs     = 0 ; // unused

            z80_rom_cs       = ( !MREQ_n && RFSH_n && z80_addr[15:0]  < 16'hf800 );
            z80_ram_cs       = ( !MREQ_n && RFSH_n && z80_addr[15:0] >= 16'hf800 );

            z80_sound0_cs    = z80_io_cs(8'h00);
            z80_sound1_cs    = z80_io_cs(8'h01);
            z80_dac1_cs      = z80_io_cs(8'h02);
            z80_dac2_cs      = z80_io_cs(8'h03);
            z80_latch_clr_cs = z80_io_cs(8'h04);
            z80_latch_r_cs   = z80_io_cs(8'h06);
        end
        default:;
    endcase
end

endmodule
