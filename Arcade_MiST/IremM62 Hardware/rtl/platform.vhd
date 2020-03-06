library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
use work.pace_pkg.all;
use work.video_controller_pkg.all;
use work.sprite_pkg.all;
use work.platform_pkg.all;
use work.platform_variant_pkg.all;
--use work.project_pkg.all;

entity platform is
  generic
  (
    NUM_INPUT_BYTES   : integer
  );
  port
  (
    -- clocking and reset
    clkrst_i        : in from_CLKRST_t;

    hwsel           : in integer;

    -- misc I/O
    buttons_i       : in from_BUTTONS_t;
    switches_i      : in from_SWITCHES_t;
    leds_o          : out to_LEDS_t;

    -- controller inputs
    inputs_i        : in from_MAPPED_INPUTS_t(0 to NUM_INPUT_BYTES-1);

    -- graphics
    
    bitmap_i        : in from_BITMAP_CTL_a(1 to PACE_VIDEO_NUM_BITMAPS);
    bitmap_o        : out to_BITMAP_CTL_a(1 to PACE_VIDEO_NUM_BITMAPS);
    
    tilemap_i       : in from_TILEMAP_CTL_a(1 to PACE_VIDEO_NUM_TILEMAPS);
    tilemap_o       : out to_TILEMAP_CTL_a(1 to PACE_VIDEO_NUM_TILEMAPS);

    sprite_reg_o    : out to_SPRITE_REG_t;
    sprite_i        : in from_SPRITE_CTL_t;
    sprite_o        : out to_SPRITE_CTL_t;
    spr0_hit        : in std_logic;

    -- various graphics information
    graphics_i      : in from_GRAPHICS_t;
    graphics_o      : out to_GRAPHICS_t;
    sound_data_o    : out std_logic_vector(7 downto 0);

    -- custom i/o
--    project_i       : in from_PROJECT_IO_t;
--    project_o       : out to_PROJECT_IO_t;
    platform_i      : in from_PLATFORM_IO_t;
    platform_o      : out to_PLATFORM_IO_t;

    dl_addr         : in std_logic_vector(11 downto 0);
    dl_data         : in std_logic_vector(7 downto 0);
    dl_wr           : in std_logic;

    cpu_rom_addr    : out std_logic_vector(16 downto 0);
    cpu_rom_do      : in std_logic_vector(7 downto 0);
    gfx1_addr       : out std_logic_vector(17 downto 2);
    gfx1_do         : in std_logic_vector(31 downto 0);
    gfx2_addr       : out std_logic_vector(17 downto 2);
    gfx2_do         : in std_logic_vector(31 downto 0)
  );

end platform;

architecture SYN of platform is

  alias clk_sys         : std_logic is clkrst_i.clk(0);
  alias rst_sys         : std_logic is clkrst_i.rst(0);
  alias clk_video       : std_logic is clkrst_i.clk(1);

  -- cpu signals  
  signal clk_3M072_en   : std_logic;
  signal cpu_clk_en     : std_logic;
  signal cpu_a          : std_logic_vector(15 downto 0);
  signal cpu_d_i        : std_logic_vector(7 downto 0);
  signal cpu_d_o        : std_logic_vector(7 downto 0);
  signal cpu_mem_wr     : std_logic;
  signal cpu_io_rd      : std_logic;
  signal cpu_io_wr      : std_logic;
  signal cpu_irq        : std_logic;

  -- ROM signals        
  signal rom_cs         : std_logic;
--  signal rom_d_o        : std_logic_vector(7 downto 0);
  
  -- keyboard signals

  -- VRAM signals       
  signal vram_cs        : std_logic;
  signal vram_wr        : std_logic;
  signal vram_d_o       : std_logic_vector(7 downto 0);

  signal snd_cs         : std_logic;

  -- RAM signals        
  signal wram_cs        : std_logic;
  signal wram_wr        : std_logic;
  signal wram_d_o       : std_logic_vector(7 downto 0);

  -- CRAM/SPRITE signals        
  signal cram_cs        : std_logic;
  signal cram_wr        : std_logic;
  signal cram_d_o       : std_logic_vector(7 downto 0);
  signal sprite_cs      : std_logic;

  -- text RAM
  signal textram_cs     : std_logic;
  signal textram_wr     : std_logic;
  signal textram_d_o    : std_logic_vector(7 downto 0);
  
  -- misc signals      
  signal in_cs          : std_logic;
  signal in_d_o         : std_logic_vector(7 downto 0);
  signal pal_r_wr       : std_logic;
  signal pal_g_wr       : std_logic;
  signal pal_b_wr       : std_logic;
  signal sp_pal_r_wr    : std_logic;
  signal sp_pal_g_wr    : std_logic;
  signal sp_pal_b_wr    : std_logic;

  -- other signals
  signal rst_platform   : std_logic;
  signal pause          : std_logic;
  signal rot_en         : std_logic;

  -- Lode Runner 2,4
  signal ld2_bankr1     : std_logic_vector(5 downto 0);
  signal ld2_bankr2     : std_logic_vector(7 downto 0);
  signal ld24_bank       : std_logic;

  -- Lode Runner 3
  signal ld3_prot5_cs   : std_logic;
  signal ld3_prot7_cs   : std_logic;

  -- Kidniki, Battle Road
  signal kidniki_bank   : std_logic_vector(3 downto 0);

begin

  -- handle special keys
  process (clk_sys, rst_sys)
    variable spec_keys_r  : std_logic_vector(7 downto 0);
    alias spec_keys       : std_logic_vector(7 downto 0) is inputs_i(PACE_INPUTS_NUM_BYTES-1).d;
    variable layer_en     : std_logic_vector(4 downto 0);
  begin
    if rst_sys = '1' then
      rst_platform <= '0';
      pause <= '0';
      rot_en <= '0';  -- to default later
      spec_keys_r := (others => '0');
      layer_en := "11111";
    elsif rising_edge(clk_sys) then
      rst_platform <= spec_keys(0);
      if spec_keys_r(1) = '0' and spec_keys(1) = '1' then
        pause <= not pause;
      end if;
      if spec_keys_r(2) = '0' and spec_keys(2) = '1' then
        rot_en <= not rot_en;
        if layer_en = "11111" then
          layer_en := "00001";
        elsif layer_en = "10000" then
          layer_en := "11111";
        else
          layer_en := layer_en(3 downto 0) & layer_en(4);
        end if;
      end if;
      spec_keys_r := spec_keys;
    end if;
    graphics_o.bit8(0)(4 downto 0) <= layer_en;
  end process;
  
  --graphics_o.bit8(0)(0) <= rot_en;
  
  -- chip select logic
  -- ROM $0000-$7FFF
  --     $0000-$9FFF - LDRUN2
  --     $0000-$BFFF - LDRUN3,4, HORIZON
  --     $A000-$BFFF - BATTROAD
  rom_cs <=     '1' when STD_MATCH(cpu_a,  "0---------------") else 
                '1' when hwsel = HW_LDRUN2 and cpu_a(15 downto 13) = "100" else
                '1' when (hwsel = HW_LDRUN3 or hwsel = HW_LDRUN4 or hwsel = HW_HORIZON) and cpu_a(15 downto 14) = "10" else
                '1' when hwsel = HW_BATTROAD and cpu_a(15 downto 13) = "101" else
                '0';

  -- SPRITE $C000-$C0FF
  --        $C000-$C1FF - HORIZON
  sprite_cs <=  '1' when cpu_a(15 downto 8) = x"C0" else
                '1' when cpu_a(15 downto 9) = x"C"&"000" and hwsel = HW_HORIZON else
                '0';

  -- VRAM/CRAM $D000-$DFFF
  vram_cs <=    '1' when hwsel = HW_KUNGFUM and
                          STD_MATCH(cpu_a, X"D"&"0-----------") else 
                '1' when hwsel /= HW_KUNGFUM and
                          STD_MATCH(cpu_a, X"D"&"-----------0") else 
                '0';
  cram_cs <=    '1' when hwsel = HW_KUNGFUM and
                          STD_MATCH(cpu_a, X"D"&"1-----------") else 
                '1' when hwsel /= HW_KUNGFUM and
                          STD_MATCH(cpu_a, X"D"&"-----------1") else 
                '0';

  -- Text RAM $C800-$CFFF
  textram_cs <= '1' when hwsel = HW_BATTROAD and
                          cpu_a(15 downto 11) = x"C"&'1' else
                '0';

  -- RAM $E000-$EFFF
  wram_cs <=    '1' when STD_MATCH(cpu_a, X"E"&"------------") else '0';

  -- OUTPUT $XX00
  snd_cs <=      '1' when cpu_a(7 downto 0) = X"00" else '0';

  -- INPUTS (I/O) $00-$04
  in_cs <=      '1' when STD_MATCH(cpu_a(7 downto 0), X"0"&"00--") else 
                '1' when STD_MATCH(cpu_a(7 downto 0), X"04") else
                '0';

  -- Lode Runner 3 protection
  ld3_prot5_cs <= '1' when hwsel = HW_LDRUN3 and cpu_a = x"c800" else '0';
  ld3_prot7_cs <= '1' when hwsel = HW_LDRUN3 and (cpu_a = x"cc00" or cpu_a = x"cfff") else '0';

  process (clk_sys, rst_sys) begin
    if rst_sys = '1' then
      sound_data_o <= X"FF";
    elsif rising_edge(clk_sys) then
      if cpu_clk_en = '1' and cpu_io_wr = '1' and snd_cs = '1' then
        sound_data_o <= cpu_d_o;
      end if;
    end if; 
  end process;

  -- memory read mux
  cpu_d_i <=  in_d_o when (cpu_io_rd = '1' and in_cs = '1') else
              x"05" when ld3_prot5_cs = '1' else
              x"07" when ld3_prot7_cs = '1' else
              cpu_rom_do when rom_cs = '1' else
              vram_d_o when vram_cs = '1' else
              cram_d_o when cram_cs = '1' else
              wram_d_o when wram_cs = '1' else
              textram_d_o when textram_cs = '1' else
              (others => '1');

  -- memory block write signals 
  vram_wr <= vram_cs and cpu_mem_wr;
  cram_wr <= cram_cs and cpu_mem_wr;
  wram_wr <= wram_cs and cpu_mem_wr;
  textram_wr <= textram_cs and cpu_mem_wr;

  -- sprite registers
  sprite_reg_o.clk <= clk_sys;
  sprite_reg_o.clk_ena <= clk_3M072_en;
  sprite_reg_o.a <= cpu_a(8 downto 0)  when hwsel = HW_HORIZON else '0' & cpu_a(7 downto 0);
  sprite_reg_o.d <= cpu_d_o;
  sprite_reg_o.wr <= sprite_cs and cpu_mem_wr;

  --
  -- COMPONENT INSTANTIATION
  --

  BLK_CPU : block
    signal cpu_rst        : std_logic;
  begin
    -- generate CPU enable clock (3MHz from 27/30MHz)
    clk_en_inst : entity work.clk_div
      generic map
      (
        DIVISOR		=> M62_CPU_CLK_ENA_DIVIDE_BY
      )
      port map
      (
        clk				=> clk_sys,
        reset			=> rst_sys,
        clk_en		=> clk_3M072_en
      );
    
    -- gated CPU signals
    cpu_clk_en <= clk_3M072_en and not pause;
    cpu_rst <= rst_sys or rst_platform;
    
    cpu_inst : entity work.Z80                                                
      port map
      (
        clk     => clk_sys,                                   
        clk_en  => cpu_clk_en,
        reset   => cpu_rst,

        addr    => cpu_a,
        datai   => cpu_d_i,
        datao   => cpu_d_o,

        mem_rd  => open,
        mem_wr  => cpu_mem_wr,
        io_rd   => cpu_io_rd,
        io_wr   => cpu_io_wr,

        intreq  => cpu_irq,
        intvec  => cpu_d_i,
        intack  => open,
        nmi     => '0'
      );

    cpu_rom_addr <= 
      '0' & "10" & ld24_bank & cpu_a(12 downto 0) when hwsel = HW_LDRUN2 and cpu_a(15) = '1' else
      '0' & '1'  & ld24_bank & cpu_a(13 downto 0) when hwsel = HW_LDRUN4 and cpu_a(15) = '1' else
      '1' & kidniki_bank(2 downto 0) & cpu_a(12 downto 0) when hwsel = HW_BATTROAD and cpu_a(15 downto 13) = "101" else
      '0' & cpu_a(15 downto 0);

    -- Lode Runner 2 bank switching - some kind of protection, only the level number is used to select bank 0 or 1 at $8000
    -- writes to $80 (level number)
    -- writes to $81 (unknown, from a table)
    -- reads from $80 (number of times from a table)
    process (clk_sys, rst_sys)
    begin
      if rst_sys = '1' then
        ld2_bankr1 <= (others => '0');
        ld2_bankr2 <= (others => '0');
        ld24_bank <= '0';
        kidniki_bank <= (others => '0');
      elsif rising_edge(clk_sys) then
        if cpu_clk_en = '1' and cpu_io_wr = '1' then
          case cpu_a(7 downto 0) is
            when X"80" => ld2_bankr1 <= cpu_d_o(5 downto 0);
            when X"81" => ld2_bankr2 <= cpu_d_o;
            when X"83" => if hwsel = HW_BATTROAD then kidniki_bank <= cpu_d_o(3 downto 0); end if;
            when others => null;
          end case;
        end if;

        if cpu_clk_en = '1' and cpu_io_rd = '1' and cpu_a(7 downto 0) = x"80" then
          if ld2_bankr1 = 6 or ld2_bankr1 = 8 or ld2_bankr1 = 12 or ld2_bankr1 = 13 or ld2_bankr1 = 14 or ld2_bankr1 = 15 or ld2_bankr1 = 16 or
             ld2_bankr1 = 21 or ld2_bankr1 >= 23
          then
            ld24_bank <= '1';
          else
            ld24_bank <= '0';
          end if;
        end if;

        if cpu_clk_en = '1' and cpu_mem_wr = '1' then
          if cpu_a = x"c800" and hwsel = HW_LDRUN4 then
            ld24_bank <= cpu_d_o(0);
          end if;
        end if;

      end if;
    end process;
  end block BLK_CPU;

  BLK_INTERRUPTS : block
  
    signal vblank_int     : std_logic;

  begin
  
    process (clk_sys, rst_sys)
      variable vblank_r : std_logic_vector(3 downto 0);
      alias vblank_prev : std_logic is vblank_r(vblank_r'left);
      alias vblank_um   : std_logic is vblank_r(vblank_r'left-1);
      -- 1us duty for VBLANK_INT
      variable count    : integer range 0 to CLK0_FREQ_MHz * 100;
    begin
      if rst_sys = '1' then
        vblank_int <= '0';
        vblank_r := (others => '0');
        count := count'high;
      elsif rising_edge(clk_sys) then
        -- rising edge vblank only
        if vblank_prev = '0' and vblank_um = '1' then
          count := 0;
        end if;
        if count /= count'high then
          vblank_int <= '1';
          count := count + 1;
        else
          vblank_int <= '0';
        end if;
        vblank_r := vblank_r(vblank_r'left-1 downto 0) & graphics_i.vblank;
      end if; -- rising_edge(clk_sys)
    end process;

    -- generate INT
    cpu_irq <= vblank_int;
    
  end block BLK_INTERRUPTS;
  
  BLK_INPUTS : block
  begin
    in_d_o <= inputs_i(0).d when cpu_a(2 downto 0) = "000" else
              inputs_i(1).d when cpu_a(2 downto 0) = "001" else
              inputs_i(2).d when cpu_a(2 downto 0) = "010" else
              inputs_i(3).d when cpu_a(2 downto 0) = "011" else
              inputs_i(4).d;
  end block BLK_INPUTS;
  
  BLK_SCROLL : block
    signal m62_hscroll  : std_logic_vector(15 downto 0);
    signal m62_vscroll  : std_logic_vector(15 downto 0);
    signal m62_topbottom_mask: std_logic;
    signal scrollram_d_o  : std_logic_vector(15 downto 0);
    signal scrollram_wr   : std_logic;
  begin
    horizon_scrollram_inst : entity work.dpram
    generic map
    (
      init_file  => "",
      widthad_a  => 5,
      width_a    => 16,
      widthad_b  => 6,
      width_b    => 8
    )
    port map
    (
      clock_b    => clk_sys,
      address_b  => cpu_a(5 downto 0),
      wren_b     => scrollram_wr,
      data_b     => cpu_d_o,
      q_b        => open,

      clock_a    => clk_video,
      address_a  => tilemap_i(1).map_a(10 downto 6),
      wren_a     => '0',
      data_a     => (others => 'X'),
      q_a        => scrollram_d_o
    );

    scrollram_wr <= '1' when cpu_mem_wr = '1' and cpu_a(15 downto 6) = X"C8"&"00" else '0';

    process (clk_sys, rst_sys)
    begin
      if rst_sys = '1' then
        m62_hscroll <= (others => '0');
        m62_vscroll <= (others => '0');
        m62_topbottom_mask <= '0';
      elsif rising_edge(clk_sys) then
        if cpu_clk_en = '1' and cpu_mem_wr = '1' then
          case cpu_a is
            when X"A000" =>
              if hwsel = HW_KUNGFUM then
                m62_hscroll(7 downto 0) <= cpu_d_o;
              end if;
            when X"B000" =>
              if hwsel = HW_KUNGFUM then
                m62_hscroll(15 downto 8) <= cpu_d_o;
              end if;
            when others =>
              null;
          end case;
        end if; -- cpu_wr

        if cpu_clk_en = '1' and cpu_io_wr = '1' then
          if (hwsel = HW_LDRUN3 or hwsel = HW_BATTROAD) and cpu_a(7 downto 0) = x"80" then
            m62_vscroll(7 downto 0) <= cpu_d_o;
          end if;
          if hwsel = HW_LDRUN3 and cpu_a(7 downto 0) = x"81" then
            m62_topbottom_mask <= cpu_d_o(0);
          end if;
          if (hwsel = HW_LDRUN4 and cpu_a(7 downto 0) = x"82") or
             (hwsel = HW_BATTROAD and cpu_a(7 downto 0) = x"81") then
            m62_hscroll(15 downto 8) <= cpu_d_o;
          end if;
          if (hwsel = HW_LDRUN4 and cpu_a(7 downto 0) = x"83") or
             (hwsel = HW_BATTROAD and cpu_a(7 downto 0) = x"82") then
            m62_hscroll(7 downto 0) <= cpu_d_o;
          end if;

        end if;
      end if; -- rising_edge(clk_sys)
    end process;
    graphics_o.bit16(0) <= scrollram_d_o when hwsel = HW_HORIZON else m62_hscroll;
    graphics_o.bit16(1) <= m62_vscroll;
  end block BLK_SCROLL;


  BLK_GFX_ROMS : block
  
    type gfx_rom_d_a is array(M62_CHAR_ROM'range) of std_logic_vector(7 downto 0);
    signal chr_rom_d      : gfx_rom_d_a;
    type spr_rom_d_a is array(0 to 11) of std_logic_vector(7 downto 0);
    signal spr_rom        : spr_rom_d_a;
    
  begin

    -- external background ROMs
    gfx1_addr <= "00"&tilemap_i(1).tile_a(13 downto 0);
    tilemap_o(1).tile_d(23 downto 0) <= gfx1_do(7 downto 0) & gfx1_do(15 downto 8) & gfx1_do(23 downto 16);

    -- internal background ROMs
--    GEN_CHAR_ROMS : for i in M62_CHAR_ROM'range generate
--      char_rom_inst : entity work.sprom
--        generic map
--        (
--          init_file  => "./roms/" &
--                          M62_CHAR_ROM(i) & ".hex",
--          widthad_a  => 13
--        )
--        port map
--        (
--          clock      => clk_video,
--          address    => tilemap_i(1).tile_a(12 downto 0),
--          q          => chr_rom_d(i)
--        );
--    end generate GEN_CHAR_ROMS;
--
--    tilemap_o(1).tile_d(23 downto 0) <= chr_rom_d(0) & chr_rom_d(1) & chr_rom_d(2);

    -- external sprite ROMs
    gfx2_addr <= '0' & sprite_i.a(14 downto 0);
    sprite_o.d(23 downto 0) <= gfx2_do(7 downto 0) & gfx2_do(15 downto 8) & gfx2_do(23 downto 16);

    -- internal sprite ROMs
--    GEN_SPRITE_ROMS : for i in M62_SPRITE_ROM'range generate
--      sprite_rom_inst : entity work.sprom
--        generic map
--        (
--          init_file  => "./roms/" &
--                          M62_SPRITE_ROM(i) & ".hex",
--          widthad_a  => 13
--        )
--        port map
--        (
--          clock                 => clk_video,
--          address(12 downto 5)  => sprite_i.a(12 downto 5),
--          address(4 downto 0)   => sprite_i.a(4 downto 0),
--          q                     => spr_rom(i)
--        );
--    end generate GEN_SPRITE_ROMS;
--
--    sprite_o.d(sprite_o.d'left downto 24) <= (others => '0');
--    sprite_o.d(23 downto 0) <=  spr_rom(0) & 
--                                spr_rom(1) &
--                                spr_rom(2)
--                                  when sprite_i.a(14 downto 13) = "00" else
--                                spr_rom(3) &
--                                spr_rom(4) &
--                                spr_rom(5) 
--                                  when sprite_i.a(14 downto 13) = "01" else
--                                spr_rom(6) &
--                                spr_rom(7) &
--                                spr_rom(8)
--                                  when sprite_i.a(14 downto 13) = "10" else
--                                spr_rom(9) &
--                                spr_rom(10) &
--                                spr_rom(11);

  end block BLK_GFX_ROMS;

  BLK_VRAM : block
    signal vram_a   : std_logic_vector(10 downto 0);
    alias cram_a    : std_logic_vector(10 downto 0) is vram_a;
  begin
  
    vram_a <= cpu_a(10 downto 0) when hwsel = HW_KUNGFUM else
              cpu_a(11 downto 1);
              
    vram_inst : entity work.dpram
      generic map
      (
        init_file  => "",
        widthad_a  => 11,
        widthad_b  => 11
      )
      port map
      (
        clock_b    => clk_sys,
        address_b  => vram_a,
        wren_b     => vram_wr,
        data_b     => cpu_d_o,
        q_b        => vram_d_o,

        clock_a    => clk_video,
        address_a  => tilemap_i(1).map_a(10 downto 0),
        wren_a     => '0',
        data_a     => (others => 'X'),
        q_a        => tilemap_o(1).map_d(7 downto 0)
      );
    tilemap_o(1).map_d(15 downto 8) <= (others => '0');

    cram_inst : entity work.dpram
      generic map
      (
        init_file  => "",
        widthad_a  => 11,
        widthad_b  => 11
      )
      port map
      (
        clock_b     => clk_sys,
        address_b   => cram_a,
        wren_b      => cram_wr,
        data_b      => cpu_d_o,
        q_b         => cram_d_o,

        clock_a     => clk_video,
        address_a   => tilemap_i(1).attr_a(10 downto 0),
        wren_a      => '0',
        data_a      => (others => 'X'),
        q_a         => tilemap_o(1).attr_d(7 downto 0)
      );
    tilemap_o(1).attr_d(15 downto 8) <= (others => '0');

    textram_inst : entity work.dpram
      generic map
      (
        init_file  => "",
        widthad_a  => 11,
        widthad_b  => 11
      )
      port map
      (
        clock_b    => clk_sys,
        address_b  => cpu_a(10 downto 0),
        wren_b     => textram_wr,
        data_b     => cpu_d_o,
        q_b        => textram_d_o,

        clock_a    => clk_video,
        address_a  => (others => '0'),
        wren_a     => '0',
        data_a     => (others => 'X'),
        q_a        => open
      );
  end block BLK_VRAM;

  wram_inst : entity work.spram
    generic map
    (
      widthad_a => 12
    )
    port map
    (
      clock     => clk_sys,
      address   => cpu_a(11 downto 0),
      data      => cpu_d_o,
      wren      => wram_wr,
      q         => wram_d_o
    );

  -- tilemap 1 palettes
  pal_r : entity work.dpram
    generic map
    (
      init_file  => "",
      widthad_a  => 8,
      widthad_b  => 8
    )
    port map
    (
      clock_b     => clk_sys,
      address_b   => dl_addr(7 downto 0),
      wren_b      => pal_r_wr,
      data_b      => dl_data(3 downto 0) & dl_data(3 downto 0),
      q_b         => open,

      clock_a     => not clk_video,
      address_a   => tilemap_i(1).pal_a,
      wren_a      => '0',
      data_a      => (others => 'X'),
      q_a         => tilemap_o(1).rgb.r(9 downto 2)
    );
  pal_r_wr <= '1' when dl_wr = '1' and dl_addr(11 downto 8) = x"3" else '0';  -- 300-3FF

  pal_g : entity work.dpram
    generic map
    (
      init_file  => "",
      widthad_a  => 8,
      widthad_b  => 8
    )
    port map
    (
      clock_b     => clk_sys,
      address_b   => dl_addr(7 downto 0),
      wren_b      => pal_g_wr,
      data_b      => dl_data(3 downto 0) & dl_data(3 downto 0),
      q_b         => open,

      clock_a     => not clk_video,
      address_a   => tilemap_i(1).pal_a,
      wren_a      => '0',
      data_a      => (others => 'X'),
      q_a         => tilemap_o(1).rgb.g(9 downto 2)
    );
  pal_g_wr <= '1' when dl_wr = '1' and dl_addr(11 downto 8) = x"4" else '0';  -- 400-4FF

  pal_b : entity work.dpram
    generic map
    (
      init_file  => "",
      widthad_a  => 8,
      widthad_b  => 8
    )
    port map
    (
      clock_b     => clk_sys,
      address_b   => dl_addr(7 downto 0),
      wren_b      => pal_b_wr,
      data_b      => dl_data(3 downto 0) & dl_data(3 downto 0),
      q_b         => open,

      clock_a     => not clk_video,
      address_a   => tilemap_i(1).pal_a,
      wren_a      => '0',
      data_a      => (others => 'X'),
      q_a         => tilemap_o(1).rgb.b(9 downto 2)
    );
  pal_b_wr <= '1' when dl_wr = '1' and dl_addr(11 downto 8) = x"5" else '0';  -- 500-5FF

  -- sprite palettes
  sp_pal_r : entity work.dpram
    generic map
    (
      init_file  => "",
      widthad_a  => 8,
      widthad_b  => 8
    )
    port map
    (
      clock_b     => clk_sys,
      address_b   => dl_addr(7 downto 0),
      wren_b      => sp_pal_r_wr,
      data_b      => dl_data(3 downto 0) & dl_data(3 downto 0),
      q_b         => open,

      clock_a     => not clk_video,
      address_a   => sprite_i.pal_a,
      wren_a      => '0',
      data_a      => (others => '0'),
      q_a         => sprite_o.rgb.r(9 downto 2)
    );
  sp_pal_r_wr <= '1' when dl_wr = '1' and dl_addr(11 downto 8) = x"0" else '0';  -- 000-0FF

  sp_pal_g : entity work.dpram
    generic map
    (
      init_file  => "",
      widthad_a  => 8,
      widthad_b  => 8
    )
    port map
    (
      clock_b     => clk_sys,
      address_b   => dl_addr(7 downto 0),
      wren_b      => sp_pal_g_wr,
      data_b      => dl_data(3 downto 0) & dl_data(3 downto 0),
      q_b         => open,

      clock_a     => not clk_video,
      address_a   => sprite_i.pal_a,
      wren_a      => '0',
      data_a      => (others => '0'),
      q_a         => sprite_o.rgb.g(9 downto 2)
    );
  sp_pal_g_wr <= '1' when dl_wr = '1' and dl_addr(11 downto 8) = x"1" else '0';  -- 100-1FF

  sp_pal_b : entity work.dpram
    generic map
    (
      init_file  => "",
      widthad_a  => 8,
      widthad_b  => 8
    )
    port map
    (
      clock_b     => clk_sys,
      address_b   => dl_addr(7 downto 0),
      wren_b      => sp_pal_b_wr,
      data_b      => dl_data(3 downto 0) & dl_data(3 downto 0),
      q_b         => open,

      clock_a     => not clk_video,
      address_a   => sprite_i.pal_a,
      wren_a      => '0',
      data_a      => (others => '0'),
      q_a         => sprite_o.rgb.b(9 downto 2)
    );
  sp_pal_b_wr <= '1' when dl_wr = '1' and dl_addr(11 downto 8) = x"2" else '0';  -- 200-2FF

  -- unused outputs

  sprite_o.ld <= '0';
  --graphics_o <= NULL_TO_GRAPHICS;
  leds_o <= (others => '0');
  
end SYN;
