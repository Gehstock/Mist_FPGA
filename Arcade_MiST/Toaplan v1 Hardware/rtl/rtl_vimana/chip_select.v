//

module chip_select
(
    input  [1:0] pcb,

    input [23:0] cpu_a,
    input        cpu_as_n,

    input [15:0] z80_addr,
    input        MREQ_n,
    input        IORQ_n,

    // M68K selects
    output       prog_rom_cs,
    output       ram_cs,
    output       scroll_ofs_x_cs,
    output       scroll_ofs_y_cs,
    output       frame_done_cs,
    output       int_en_cs,
    output       crtc_cs,
    output       tile_ofs_cs,
    output       tile_attr_cs,
    output       tile_num_cs,
    output       scroll_cs,
    output       shared_ram_cs,
    output       vblank_cs,
    output       tile_palette_cs,
    output       bcu_flip_cs,
    output       sprite_palette_cs,
    output       sprite_ofs_cs,
    output       sprite_cs,
    output       sprite_size_cs,
    output       sprite_ram_cs,
    output       fcu_flip_cs,
    output       reset_z80_cs,

    output       p1_cs,
    output       p2_cs,
    output       dswa_cs,
    output       dswb_cs,
    output       system_cs,
    output       tjump_cs,

    output       sound_latch_w_cs,
    output       sound_latch_r_cs,
    output       sound_status_cs,
    output       sound_done_cs,

    output       sound0_cs,
    output       sound1_cs,

    // other params
    output reg [15:0] scroll_y_offset
);

localparam pcb_vimana   = 0;
localparam pcb_samesame = 1;

function m68k_cs;
        input [23:0] start_address;
        input [23:0] end_address;
begin
    m68k_cs = ( cpu_a[23:0] >= start_address && cpu_a[23:0] <= end_address) & !cpu_as_n;
end
endfunction

function z80_cs;
        input [7:0] address_lo;
begin
    z80_cs = ( IORQ_n == 0 && z80_addr[7:0] == address_lo );
end
endfunction

always @(*) begin

    scroll_y_offset = 0;

    // Setup lines depending on pcb
    case (pcb)
        pcb_vimana: begin
            prog_rom_cs       = m68k_cs( 24'h000000, 24'h03ffff );

            scroll_ofs_x_cs   = m68k_cs( 24'h080000, 24'h080001 );
            scroll_ofs_y_cs   = m68k_cs( 24'h080002, 24'h080003 );
            fcu_flip_cs       = m68k_cs( 24'h080006, 24'h080007 );
            
            frame_done_cs     = m68k_cs( 24'h0c0000, 24'h0c0001 );
            sprite_ofs_cs     = m68k_cs( 24'h0c0002, 24'h0c0003 );
            sprite_cs         = m68k_cs( 24'h0c0004, 24'h0c0005 );
            sprite_size_cs    = m68k_cs( 24'h0c0006, 24'h0c0007 );

            vblank_cs         = m68k_cs( 24'h400000, 24'h400001 );
            int_en_cs         = m68k_cs( 24'h400002, 24'h400003 );
            crtc_cs           = m68k_cs( 24'h400008, 24'h40000f );

            tile_palette_cs   = m68k_cs( 24'h404000, 24'h4047ff );
            sprite_palette_cs = m68k_cs( 24'h406000, 24'h4067ff );

            shared_ram_cs     = m68k_cs( 24'h440000, 24'h4407ff );

            ram_cs            = m68k_cs( 24'h480000, 24'h487fff );

            bcu_flip_cs       = m68k_cs( 24'h4c0000, 24'h4c0001 );
            tile_ofs_cs       = m68k_cs( 24'h4c0002, 24'h4c0003 );
            tile_attr_cs      = m68k_cs( 24'h4c0004, 24'h4c0005 );
            tile_num_cs       = m68k_cs( 24'h4c0006, 24'h4c0007 );
            scroll_cs         = m68k_cs( 24'h4c0010, 24'h4c001f );

            reset_z80_cs      = 0;

            dswb_cs           = z80_cs( 8'h60 ); // port a inverted
            tjump_cs          = z80_cs( 8'h66 ); // port g ( x ^ 0xFF) | 0xC0
            p1_cs             = z80_cs( 8'h80 );
            p2_cs             = z80_cs( 8'h81 );
            dswa_cs           = z80_cs( 8'h82 );
            system_cs         = z80_cs( 8'h83 );

            sound_latch_w_cs  = 0;
            sound_latch_r_cs  = 0;
            sound_status_cs   = 0;
            sound_done_cs     = 0;

            sound0_cs         = z80_cs( 8'h87 );
            sound1_cs         = z80_cs( 8'h8f );
        end

        pcb_samesame: begin
            prog_rom_cs       = m68k_cs( 24'h000000, 24'h07ffff );

            scroll_ofs_x_cs   = m68k_cs( 24'h080000, 24'h080001 );
            scroll_ofs_y_cs   = m68k_cs( 24'h080002, 24'h080003 );
            fcu_flip_cs       = m68k_cs( 24'h080006, 24'h080007 );

            ram_cs            = m68k_cs( 24'h0c0000, 23'h0c3fff );
            
            vblank_cs         = m68k_cs( 24'h100000, 24'h100001 );
            int_en_cs         = m68k_cs( 24'h100002, 24'h100003 );
            crtc_cs           = m68k_cs( 24'h100008, 24'h10000f );

            tile_palette_cs   = m68k_cs( 24'h104000, 24'h1047ff );
            sprite_palette_cs = m68k_cs( 24'h106000, 24'h1067ff );

            shared_ram_cs     = 0;

            p1_cs             = m68k_cs( 24'h140000, 24'h140001 );
            p2_cs             = m68k_cs( 24'h140002, 24'h140003 );
            dswa_cs           = m68k_cs( 24'h140004, 24'h140005 );
            dswb_cs           = m68k_cs( 24'h140006, 24'h140007 );
            system_cs         = m68k_cs( 24'h140008, 24'h140009 );
            tjump_cs          = m68k_cs( 24'h14000a, 24'h14000b );
            sound_latch_w_cs  = m68k_cs( 24'h14000e, 24'h14000f );

            bcu_flip_cs       = m68k_cs( 24'h180000, 24'h180001 );
            tile_ofs_cs       = m68k_cs( 24'h180002, 24'h180003 );
            tile_attr_cs      = m68k_cs( 24'h180004, 24'h180005 );
            tile_num_cs       = m68k_cs( 24'h180006, 24'h180007 );
            scroll_cs         = m68k_cs( 24'h180010, 24'h18001f );

            frame_done_cs     = m68k_cs( 24'h1c0000, 24'h1c0001 );
            sprite_ofs_cs     = m68k_cs( 24'h1c0002, 24'h1c0003 );
            sprite_cs         = m68k_cs( 24'h1c0004, 24'h1c0005 );
            sprite_size_cs    = m68k_cs( 24'h1c0006, 24'h1c0007 );

            reset_z80_cs      = 0;

            sound_status_cs   = z80_cs( 8'h63 );

            sound0_cs         = z80_cs( 8'h80 );
            sound1_cs         = z80_cs( 8'h81 );

            sound_latch_r_cs  = z80_cs( 8'ha0 );
            sound_done_cs     = z80_cs( 8'hb0 );
        end

        default:;
    endcase
end

endmodule
