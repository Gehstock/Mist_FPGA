//

module chip_select
(
    input [23:0] m68k_a,
    input        m68k_as_n,
    input        m68k_uds_n,
    input        m68k_lds_n,

    input [15:0] z80_addr,
    input        MREQ_n,
    input        IORQ_n,
    input        M1_n,
    input        RFSH_n,

    // M68K selects
    output reg m68k_rom_cs,
    output reg m68k_ram_cs,
    output reg m68k_txt_ram_cs,
    output reg m68k_spr_cs,
    output reg m68k_pal_cs,
    output reg m68k_fg_ram_cs,
    output reg input_p1_cs,
    output reg input_p2_cs,
    output reg input_dsw1_cs,
    output reg input_dsw2_cs,
    output reg input_coin_cs,
    output reg bg_scroll_x_cs,
    output reg bg_scroll_y_cs,
    output reg fg_scroll_x_cs,
    output reg fg_scroll_y_cs,
    output reg flip_cs,
    output reg m_invert_ctrl_cs,
    output reg sound_latch_cs,

    // Z80 selects
    output reg   z80_rom_cs,
    output reg   z80_ram_cs,
    output reg   z80_latch_cs,

    output reg   z80_sound0_cs,
    output reg   z80_sound1_cs,
    output reg   z80_upd_cs,
    output reg   z80_upd_r_cs
);


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
    z80_mem_cs = ( z80_addr >> width == base_address >> width ) & !MREQ_n & IORQ_n & RFSH_n;
end
endfunction

function z80_io_cs;
        input [7:0] address_lo;
begin
    z80_io_cs = ( z80_addr[7:0] == address_lo ) && !IORQ_n ;
end
endfunction

always @ (*) begin
//	map(0x000000, 0x03ffff).rom();
    m68k_rom_cs      = m68k_cs( 24'h000000, 24'h03ffff ) ;

//	map(0x070000, 0x073fff).ram();
    m68k_ram_cs      = m68k_cs( 24'h070000, 24'h073fff ) ; 

//	map(0x090000, 0x0907ff).ram().w(FUNC(prehisle_state::tx_vram_w)).share("tx_vram");
    m68k_txt_ram_cs  = m68k_cs( 24'h090000, 24'h0907ff ) ;

//	map(0x0a0000, 0x0a07ff).ram().share("spriteram");
    m68k_spr_cs      = m68k_cs( 24'h0a0000, 24'h0a07ff ) ;

//	map(0x0b0000, 0x0b3fff).ram().w(FUNC(prehisle_state::fg_vram_w)).share("fg_vram");
    m68k_fg_ram_cs   = m68k_cs( 24'h0b0000, 24'h0b3fff ) ; 

//	map(0x0d0000, 0x0d07ff).ram().w(m_palette, FUNC(palette_device::write16)).share("palette");
    m68k_pal_cs      = m68k_cs( 24'h0d0000, 24'h0d07ff ) ;

//	map(0x0e0010, 0x0e0011).portr("P2");                     // Player 2
    input_p2_cs      = m68k_cs( 24'h0e0010, 24'h0e0011 ) ;

//	map(0x0e0020, 0x0e0021).portr("COIN");                   // Coins, Tilt, Service
    input_coin_cs    = m68k_cs( 24'h0e0020, 24'h0e0021 ) ;

//	map(0x0e0041, 0x0e0041).lr8(NAME([this] () -> u8 { return m_io_p1->read() ^ m_invert_controls; })); // Player 1
    input_p1_cs      = m68k_cs( 24'h0e0040, 24'h0e0041 ) ;

//	map(0x0e0042, 0x0e0043).portr("DSW0");                   // DIPs
    input_dsw1_cs    = m68k_cs( 24'h0e0042, 24'h0e0043 ) ;

//	map(0x0e0044, 0x0e0045).portr("DSW1");                   // DIPs + VBLANK
    input_dsw2_cs    = m68k_cs( 24'h0e0044, 24'h0e0045 ) ;

//	map(0x0f0000, 0x0f0001).w(FUNC(prehisle_state::fg_scrolly_w));
    fg_scroll_y_cs   = m68k_cs( 24'h0f0000, 24'h0f0001 ) ;

//	map(0x0f0010, 0x0f0011).w(FUNC(prehisle_state::fg_scrollx_w));
    fg_scroll_x_cs   = m68k_cs( 24'h0f0010, 24'h0f0011 ) ;

//	map(0x0f0020, 0x0f0021).w(FUNC(prehisle_state::bg_scrolly_w));
    bg_scroll_y_cs   = m68k_cs( 24'h0f0020, 24'h0f0021 ) ;

//	map(0x0f0030, 0x0f0031).w(FUNC(prehisle_state::bg_scrollx_w));
    bg_scroll_x_cs   = m68k_cs( 24'h0f0030, 24'h0f0031 ) ;

//	map(0x0f0046, 0x0f0047).lw16(NAME([this] (u16 data) { m_invert_controls = data ? 0xff : 0x00; }));  // P1 Invert Controls
    m_invert_ctrl_cs   = m68k_cs( 24'h0f0046, 24'h0f0047 ) ;

    flip_cs          = m68k_cs( 24'h0f0060, 24'h0f0061 ) ;

//	map(0x0f0070, 0x0f0071).w(FUNC(prehisle_state::soundcmd_w));
    sound_latch_cs   = m68k_cs( 24'h0f0070, 24'h0f0071 ) ;


    z80_rom_cs       = RFSH_n && !MREQ_n && z80_addr[15:0] < 16'hf000;
    z80_ram_cs       = RFSH_n && !MREQ_n && z80_addr[15:0] >= 16'hf000 && z80_addr[15:0] < 16'hf800;
    z80_latch_cs     = RFSH_n && !MREQ_n && z80_addr[15:0] == 16'hf800;
    z80_sound0_cs    = z80_io_cs(8'h00); // ym3812 address
    z80_sound1_cs    = z80_io_cs(8'h20); // ym3812 data
    z80_upd_cs       = z80_io_cs(8'h40); // 7759 write
    z80_upd_r_cs     = z80_io_cs(8'h80); // 7759 reset
end


//	map(0x0f0046, 0x0f0047).lw16(NAME([this] (u16 data) { m_invert_controls = data ? 0xff : 0x00; }));
//	map(0x0f0050, 0x0f0051).lw16(NAME([this] (u16 data) { machine().bookkeeping().coin_counter_w(0, data & 1); }));
//	map(0x0f0052, 0x0f0053).lw16(NAME([this] (u16 data) { machine().bookkeeping().coin_counter_w(1, data & 1); }));
//	map(0x0f0060, 0x0f0061).lw16(NAME([this] (u16 data) { flip_screen_set(data & 0x01); }));
    
//	map(0x0000, 0xefff).rom();
//	map(0xf000, 0xf7ff).ram();
//	map(0xf800, 0xf800).r(m_soundlatch, FUNC(generic_latch_8_device::read));
//	map(0xf800, 0xf800).nopw();    // ???    

//	map.global_mask(0xff);
//	map(0x00, 0x00).rw("ymsnd", FUNC(ym3812_device::status_r), FUNC(ym3812_device::address_w));
//	map(0x20, 0x20).w("ymsnd", FUNC(ym3812_device::data_w));
//	map(0x40, 0x40).w(FUNC(prehisle_state::upd_port_w));
//	map(0x80, 0x80).lw8(NAME([this] (u8 data) { m_upd7759->reset_w(BIT(data, 7)); }));
endmodule
