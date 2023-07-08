//

module chip_select
(
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
    output       reset_z80_cs,

    // Z80 selects
    output       z80_p1_cs,
    output       z80_p2_cs,
    output       z80_dswa_cs,
    output       z80_dswb_cs,
    output       z80_system_cs,
    output       z80_tjump_cs,
    output       z80_sound0_cs,
    output       z80_sound1_cs,

    // other params
    output reg [15:0] scroll_y_offset
);

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

always @ (*) begin

    scroll_y_offset = 16 ;

    prog_rom_cs       = m68k_cs( 24'h000000, 24'h07ffff );
    ram_cs            = m68k_cs( 24'h080000, 24'h083fff );

    sprite_ram_cs     = m68k_cs( 24'h0c0000, 24'h0c0fff );

    bcu_flip_cs       = m68k_cs( 24'h100000, 24'h100001 );
    tile_ofs_cs       = m68k_cs( 24'h100002, 24'h100003 );
    tile_attr_cs      = m68k_cs( 24'h100004, 24'h100005 );
    tile_num_cs       = m68k_cs( 24'h100006, 24'h100007 );
    scroll_cs         = m68k_cs( 24'h100010, 24'h10001f );

    vblank_cs         = m68k_cs( 24'h140000, 24'h140001 );
    int_en_cs         = m68k_cs( 24'h140002, 24'h140003 );
    crtc_cs           = m68k_cs( 24'h140008, 24'h14000f );

    tile_palette_cs   = m68k_cs( 24'h144000, 24'h1447ff );
    sprite_palette_cs = m68k_cs( 24'h146000, 24'h1467ff );

    shared_ram_cs     = m68k_cs( 24'h180000, 24'h180fff );

    scroll_ofs_x_cs   = m68k_cs( 24'h1c0000, 24'h1c0001 );
    scroll_ofs_y_cs   = m68k_cs( 24'h1c0002, 24'h1c0003 );
    reset_z80_cs      = m68k_cs( 24'h1c8000, 24'h1c8001 );

    z80_p1_cs         = z80_cs( 8'h00 );
    z80_p2_cs         = z80_cs( 8'h10 );
    z80_system_cs     = z80_cs( 8'h20 );
    z80_dswa_cs       = z80_cs( 8'h40 );
    z80_dswb_cs       = z80_cs( 8'h50 );
    z80_sound0_cs     = z80_cs( 8'h60 );
    z80_sound1_cs     = z80_cs( 8'h61 );
    z80_tjump_cs      = z80_cs( 8'h70 );
end

endmodule
