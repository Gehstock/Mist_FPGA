----------------------------------------------------------------------
-- Bosconian - Star Destroyer
-- Video board VHDL implementation
-- by Nolan Nicholson, 2021
----------------------------------------------------------------------

-- Bosconian's video board handles not only video rendering, but also
-- some of the memory map, plus a second Namco custom subsystem,
-- consisting of a 06xx controller managing two MB88-based MCUs:
-- a second 50xx, and the 52xx sound sample player.
-- This file contains just the rendering logic. The video RAMs,
-- the remaining memory mapping, and the Namco subsystem are all
-- defined in a separate file.

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

entity bosconian_video is port (
  -- input: clock/reset
  clk_i      : in    std_ulogic;
  clkn_i     : in    std_ulogic;
  clk_en_i   : in    std_ulogic;
  clkn_en_i  : in    std_ulogic;
  resn_i     : in    std_ulogic;

  -- inputs: user controls (not on original hardware)
  pause      : in  std_logic;
  h_offset   : in  signed(3 downto 0);
  v_offset   : in  signed(3 downto 0);

  -- input control signals
  flip_n_s        : in std_ulogic;                   -- flip screen (active low)
  playfield_posix : in std_logic_vector(7 downto 0); -- playfield X scroll
  playfield_posiy : in std_logic_vector(7 downto 0); -- playfield Y scroll
  sf_x_s          : in std_logic_vector(2 downto 0); -- starfield X scroll speed
  sf_y_s          : in std_logic_vector(2 downto 0); -- starfield Y scroll speed
  sf_blk_s        : in std_logic_vector(1 downto 0); -- starfield active subset
  sf_starclr_s    : in std_logic;                    -- starfield reset (active low)

  -- input from video RAMs
  db_a2_s     : in std_logic_vector(7 downto 0); -- "DATA BUS A2" on schematic
  db_a3_s     : in std_logic_vector(7 downto 0); -- "DATA BUS A3" on schematic
  ram_2E_do_n : in std_ulogic_vector(3 downto 0); -- (inverted) outputs from RAM 2E, small-object registers

  -- input from initial setup
--  a_i            : in std_logic_vector(15 downto 0);
--  d_i            : in std_logic_vector(7 downto 0);
  romchar_wren   : in std_ulogic;
  romsprite_wren : in std_ulogic;
  romradar_wren  : in std_ulogic;

  -- OUTPUT TO GAME LOGIC
  video_ram_addr_o : out    std_ulogic_vector(10 downto 0);  -- "BUFFER ADDRESS BUS" on schematic

  -- VIDEO OUT
  hblankn_o  : out std_ulogic; -- additionally for blanking
  vblankn_o  : out std_ulogic; -- additionally for blanking
  syncn_o    : out std_ulogic;  -- original signal
  hsyncn_o   : out std_ulogic;  -- detailed signals for remapping
  vsyncn_o   : out std_ulogic;  -- detailed signals for remapping
  r_o        : out std_logic_vector(2 downto 0);
  g_o        : out std_logic_vector(2 downto 0);
  b_o        : out std_logic_vector(1 downto 0)
);
end bosconian_video;

use work.C07_SYNCGEN_PACK.all;

architecture rtl of bosconian_video is
  -- horizontal counter
  signal hcount_07xx_s : std_ulogic_vector(8 downto 0);
  signal hcount_07xx_s_lv : std_logic_vector(hcount_07xx_s'range);
  signal hcount_s : std_ulogic_vector(8 downto 0);
  signal hblankn_s  : std_ulogic;
  signal hblank_x_s : std_ulogic;
  signal hblankn_x_s : std_ulogic;
  signal hblankn_x_fall_ena_s : std_ulogic;
  signal hblank_xx_s : std_ulogic;
  signal hblankn_xx_s : std_ulogic;
  signal hsyncn_s  : std_ulogic;
  signal h256_x_s  : std_ulogic;

  signal addr_out_ena      : std_ulogic;

  -- vertical counter
  signal vcount_s : std_ulogic_vector(7 downto 0);
  signal vcount_s_lv : std_logic_vector(vcount_s'range);
  signal vblankn_s  : std_ulogic;
  signal vsyncn_s  : std_ulogic;

  -- adjustable sync override
  signal vsync_override_vcount_ena : std_ulogic;
  signal hsync_start : integer range 0 to 511;
  signal hsync_end   : integer range 0 to 511;
  signal vsync_start : integer range 0 to 255;
  signal vsync_end   : integer range 0 to 255;
  signal hsyncn_override : std_ulogic;
  signal vsyncn_override : std_ulogic;

  -- c07 clock enables
  signal c07_clken_s : r_c07_syncgen_clken;
  signal c07_clken_posedge_s,
         c07_clken_negedge_s  : r_c07_syncgen_clken_out;

  -- PROM 2R timing signals
  signal prom_2R_do_s : std_ulogic_vector(7 downto 0);
  signal flip_s : std_ulogic;

  -- PROM 7H timing signals
  signal LD_s : std_ulogic;
  signal LDn_s : std_ulogic;
  signal prom_7H_do_s : std_ulogic_vector(7 downto 0);
  signal OBCLDn_s  : std_ulogic;
  signal CCLRn_s   : std_ulogic;
  signal SOCLDn_s  : std_ulogic;
  signal COLSETn_s : std_ulogic;
  signal VPSETn_s  : std_ulogic;
  signal DSETn_s   : std_ulogic;

  signal VPSETn_delay_s : std_ulogic;
  signal DSETn_delay_s  : std_ulogic;
  signal VPSETn_ena_s : std_ulogic;
  signal DSETn_ena_s  : std_ulogic;
  
  -- playfield
  signal pf_n_s             :  std_logic; -- 0 in left-side playfield, 1 in right-side radar/score pane

  -- video RAM addressing
  signal posix           : std_ulogic_vector(7 downto 0);
  signal posiy           : std_ulogic_vector(7 downto 0);
  signal hcount_flipped   : std_ulogic_vector(4 downto 0); -- hcount after applying some non-straightforward flips
  signal vcount_flipped   : std_ulogic_vector(7 downto 0); -- vcount after applying flips
  signal posix_plus_hcount  : std_ulogic_vector(5 downto 0);
  signal posiy_plus_vcount  : std_ulogic_vector(7 downto 0);

  signal hcount_flipped_2_ena : std_ulogic;
  signal dff_6K_Qn34 : std_ulogic_vector(1 downto 0);
  signal s_256H_x : std_ulogic;

  -- Graphics ROMs
  signal gfx_addr_upper_s : std_ulogic_vector(5 downto 0); -- upper bits of the GFX ROM address
  signal sprite_flipy_s : std_ulogic;
  signal sprite_flipx_s : std_ulogic;
  signal tile_flipy_s : std_ulogic;
  signal tile_flipx_s : std_ulogic;
  signal flipy_s : std_ulogic;
  signal flipx_s : std_ulogic;
  signal dff_5F_Q1 : std_ulogic;
  signal dff_5F_Q6 : std_ulogic;
  signal dff_5F_Q32 : std_ulogic_vector(1 downto 0);
  signal mux_6H_Y : std_ulogic_vector(3 downto 0);
  signal mux_6F_1Y2Y : std_ulogic_vector(1 downto 0);
  signal rom_5D5E_addr : std_logic_vector(11 downto 0);
  signal rom_5D_do : std_logic_vector(7 downto 0);
  signal rom_5E_do : std_logic_vector(7 downto 0);
  signal rom_5D5E_do : std_ulogic_vector(7 downto 0);

  -- Tile palette and attribute handling
  signal xor_6J_outpin11 : std_ulogic;
  signal and_7F_outpin8 : std_ulogic;
  signal and_7F_outpin11 : std_ulogic;
  signal buffer_03xx_4K_do : std_ulogic_vector(5 downto 0); -- output from 4K (03xx custom buffer)
  signal flip_pixels : std_ulogic;
  signal reg_4L_4Q : std_ulogic;
  signal palette_color : std_ulogic_vector(5 downto 0);

  -- Pixel shifters
  signal shiftreg_6D6C_S : std_ulogic_vector(1 downto 0); -- S1, S0; 2Y, 1Y from MUX 7C
  signal shiftreg_6D_Q : std_ulogic_vector(3 downto 0); -- order: ABCD
  signal shiftreg_6C_Q : std_ulogic_vector(3 downto 0); -- order: ABCD
  signal tilepixel_2bpp : std_ulogic_vector(1 downto 0); -- 3Y, 4Y from MUX 7C

  -- Sprite engine
  signal sprite_vcount : std_ulogic_vector(3 downto 0);
  signal HCOUNT_ena_s : std_ulogic; -- 1 to activate horizontal counter for "stepping" across a sprite
  signal dff_5H_1Q : std_ulogic;
  signal dba3_plus_vcount : std_ulogic_vector(7 downto 0);
  signal sprite_linematch_n : std_ulogic;
  signal smallobj_linematch_n : std_ulogic;
  signal sprite_linematch : std_ulogic;

  -- Object buffer RAM
  signal nand_3N_outpin6 : std_ulogic;
  signal nand_3N_outpin8 : std_ulogic;
  signal ram_4J_addr : std_logic_vector(7 downto 0);
  signal ram_4J_cs_n : std_ulogic;
  signal ram_4J_we : std_ulogic;
  signal ram_4J_di : std_logic_vector(3 downto 0);
  signal ram_4J_do_pre_cs : std_logic_vector(3 downto 0);
  signal ram_4J_do : std_logic_vector(3 downto 0);

  -- Small-object addressing
  signal SHIFT_s : std_ulogic_vector(1 downto 0);
  signal rom_2D_cs : std_ulogic;
  signal rom_2D_do : std_logic_vector(2 downto 0);
  signal rom_2D_do_gated : std_ulogic_vector(2 downto 0);
  signal rom_2D_addr : std_logic_vector(7 downto 0);
  signal reg_1D_Q43218 : std_ulogic_vector(4 downto 0);

  -- Small-object buffer RAM
  signal ram_2B_addr : std_logic_vector(8 downto 0);
  signal ram_2B_cs_n : std_ulogic;
  signal ram_2B_we : std_ulogic;
  signal ram_2B_di : std_logic_vector(1 downto 0);
  signal ram_2B_do_pre_cs : std_logic_vector(1 downto 0);
  signal ram_2B_do : std_logic_vector(1 downto 0);

  -- starfield setup (05xx)
  signal n05_xctrl   : std_logic_vector(2 downto 0);
  signal n05_yctrl   : std_logic_vector(2 downto 0);
  signal n05_oen_s   : std_ulogic;
  signal star_oe     : std_ulogic;
  signal star_rgb : std_logic_vector(5 downto 0);

  -- Final palette and color LUT
  signal color_smallobj : std_ulogic_vector(1 downto 0);
  signal color_sprite : std_ulogic_vector(3 downto 0);
  signal rom_4M_do : std_ulogic_vector(3 downto 0);
  signal buffer_03xx_4N_do : std_ulogic_vector(4 downto 0); -- output from 4N (03xx custom buffer)
  signal palette_playfield_n : std_ulogic; -- palette needs to know if it is in the playfield or not
  signal color_tile : std_ulogic_vector(3 downto 0);
  signal pal_hblankn_s : std_ulogic;
  signal pal_blankn_s : std_ulogic;
  signal palette_5A_do : std_ulogic_vector(4 downto 0);
  signal prom_6B_do : std_logic_vector(7 downto 0);

begin


  ---------------------------------------------------------------------------
  -- Video timing
  ---------------------------------------------------------------------------

  -- 1R: Namco 07xx Clock Divider / Sync Generator
  -- There are two synchronized 07xx devices - one on the CPU board, one on the video board.
  -- The one on the CPU board may actually be what generates the VBLANK signal used by the CRT?
  -- But it shouldn't make a difference, since the two produce synchronized VBLANK signals.
  -- Extracted and simplified from Mike Johnson: "C07_SYNCGEN.VHD".
  c07_clken_s <= (clk_rise => clk_en_i,
                  clk_fall => clkn_en_i);
  i_1R : entity work.C07_SYNCGEN
  generic map (
    g_use_clk_en => true
  )
  port map (
    clk     => clk_i,
    clken   => c07_clken_s,
    hcount_o => hcount_07xx_s_lv,
    hblank_l => open,
    hsync_l => open,
    hreset_l_i => resn_i,
    vreset_l_i => resn_i,
    vsync_l => vsyncn_s,
    vblank_l => vblankn_s,
    vcount_o => vcount_s_lv,
    clken_posegde_o => c07_clken_posedge_s,
    clken_negegde_o => c07_clken_negedge_s
  );

  hcount_07xx_s <= std_ulogic_vector(hcount_07xx_s_lv);
  vcount_s <= std_ulogic_vector(vcount_s_lv);

  -- 2R: MB7051 PROM (BS-4) - 5-bit addr, 8-bit data
  -- This PROM is used to "patch" the horizontal video timing
  -- output from the 07xx.
  -- Note that the 07xx output on the CPU board is not modified in this way.
  -- This PROM also outputs the flag of whether we are in the playfield
  -- area of the screen, or the score/radar/etc area.

  i_2R : entity work.rom_2R port map (
    ADDR(4) => flip_n_s,
    ADDR(3 downto 0) => hcount_07xx_s(8 downto 5),
    DATA => prom_2R_do_s
  );

  -- The schematic says that the /HSYNC signal is obtained directly from the
  -- 07xx. However, the modified /HSYNC output from 2R is what's used to make
  -- the composite signal, so I'm guessing that's the one that actually matters.

  flip_s       <= prom_2R_do_s(7);
  hblankn_s    <= prom_2R_do_s(4); -- note that this generates hblank signal instead of the 07xx
  hsyncn_s     <= prom_2R_do_s(5);
  pf_n_s       <= prom_2R_do_s(3); -- 0 in left-side playfield, 1 in right-side radar/score pane
  HCOUNT_ena_s <= prom_2R_do_s(0); -- labeled "HCOUNT" on schematic

  hcount_s <= prom_2R_do_s(6) & prom_2R_do_s(2 downto 1) & hcount_07xx_s(5 downto 0);

  -- On original hardware, this is the H2 pin, or hcount_s(1). So when hcount_s(1) is 1,
  -- the video system is driving (pins 10 through 0 of) the address bus. When hcount_s(1)
  -- is 0, the game is driving the bus (i.e., to write to the video RAMs.)
  -- This implementation takes advantage of the 18 MHz-derived access slots to determine
  -- whether the renderer or logic gets to address VRAM, so this enable can just be 1.
  -- addr_out_ena     <= hcount_s(1);
  addr_out_ena <= '1';


  ---------------------------------------------------------------------------
  -- Adjustable video sync signals
  ---------------------------------------------------------------------------

  -- The 07xx and the 2R PROM produce the following sync timings:
  -- HSync: the 07xx HSync output is ignored; timing comes from PROM 2R.
  --   When screen flip is disabled (flip_n_s = 1):
  --    - start HSync at 07xx hcount 0x140
  --    - end   HSync at 07xx hcount 0x160
  --   When screen flip is disabled (flip_n_s = 1):
  --    - start HSync at 07xx hcount 0x100
  --    - end   HSync at 07xx hcount 0x120
  --   The screen is not flipped for normal gameplay, but it is flipped
  --   for the startup grid pattern (and maybe also the self-test.)
  -- VSync: uses the 07xx VSync output
  --  - start VSync at 07xx hcount 0x130, 07xx vcount 0xF8 (after 0xF7)
  --  - end   VSync at 07xx hcount 0x130, 07xx vcount 0x00 (after 0xFF)
  -- Here, we'll redundantly produce these timings, so that we can
  -- also make them configurable using the OSD, but we'll leave the original
  -- sync timings intact and available for things like the 05xx.

  -- adjustable hsync position
  hsync_override_mux : process(flip_n_s, h_offset) is
  begin
    if (flip_n_s = '1') then
      hsync_start <= 16#13F# + to_integer(h_offset);
      hsync_end   <= 16#15F# + to_integer(h_offset);
    else
      hsync_start <= 16#0FF# + to_integer(h_offset);
      hsync_end   <= 16#11F# + to_integer(h_offset);
    end if;
  end process hsync_override_mux;

  -- adjustable vsync position
  vsync_start <= 16#F7# + to_integer(v_offset);
  vsync_end   <= 16#FF# + to_integer(v_offset);

  vsync_override_vcount_ena <= '1' when hcount_07xx_s = "100101111" else '0'; -- x12F

  p_sync_override : process(clk_i, clk_en_i) is
  begin
    if resn_i='0' then
      hsyncn_override  <= '1';
      vsyncn_override  <= '1';
    elsif rising_edge(clk_i) and clk_en_i='1' then
      if unsigned(hcount_07xx_s) = hsync_start then
        hsyncn_override <= '0';
      elsif unsigned(hcount_07xx_s) = hsync_end then
        hsyncn_override <= '1';
      end if;

      if (vsync_override_vcount_ena = '1') then
        if unsigned(vcount_s) = vsync_start then
          vsyncn_override <= '0';
        elsif unsigned(vcount_s) = vsync_end then
          vsyncn_override <= '1';
        end if;
      end if;
   end if;
  end process p_sync_override;

  hsyncn_o <= hsyncn_override;
  vsyncn_o <= vsyncn_override;
  syncn_o  <= hsyncn_override nand vsyncn_override;


  -- 7J: 74LS175 DFF
  -- Produces delayed hblank signals.
  hblank_delay : process(clk_i, resn_i, c07_clken_negedge_s) is
  begin
    if resn_i='0' then
      hblankn_x_s   <= '0';  -- 3Q
      hblankn_xx_s  <= '0';  -- 1Q
      pal_hblankn_s <= '0';  -- 2Q
    elsif rising_edge(clk_i) and c07_clken_negedge_s.hcount(1) = '1' then
      hblankn_x_s   <= hblankn_s;       -- 3Q
      hblankn_xx_s  <= hblankn_x_s;     -- 1Q
      pal_hblankn_s <= prom_7H_do_s(7); -- 2Q
    end if;
  end process hblank_delay;

  hblank_x_s <= not hblankn_x_s;
  hblank_xx_s <= not hblankn_xx_s;

  hblankn_x_fall_ena_s <= '1' when hblankn_s = '0' and hblankn_x_s = '1' and c07_clken_negedge_s.hcount(1) = '1' else '0';

  -- This is not part of the original I/O, but is needed for the video DAC.
  -- The schematic is not very clear about which of the hblank signals
  -- actually gets sent to the CRT. I initially used the one labelled simply
  -- "/HBLANK", but using that results in the rightmost column of tiles being
  -- cut off. Using /HBLANK** results in correct alignment for both tiles and
  -- sprites.
  hblankn_o <= hblankn_xx_s;
  vblankn_o <= vblankn_s;

  -- 6L: 74LS08 AND
  -- 7J 2Q seems to be a slightly "tweaked" version of the hblank_n signal.
  -- So this appears to be intended for preventing any drawing during blanking.
  pal_blankn_s <= vblankn_s and pal_hblankn_s;

  -- The schematic is most likely wrong here. It assigns LD_n to 2H & 1H,
  -- but that means LD is active 3 out of 4 pixels. It appears it should be
  -- active 1 out of every 4 pixels, since graphics data comes out in 4-pixel
  -- "batches" for use in the pixel shifter, etc. Also, if LD is set as
  -- described in the schematic, the pixel shifter doesn't work - and even if
  -- you hack it to work, other graphical glitches still result.
  LD_s <= hcount_s(1) and hcount_s(0);
  LDn_s <= not LD_s;

  -- 7H: MB7051 PROM (BS-7) - 5-bit addr, 8-bit data
  -- This PROM sets various flags for loading objects/tiles, based on the
  -- horizontal counter and the current and previous values of hblank.
  i_7H : entity work.rom_7H port map (
    ADDR(4) => hblankn_s,
    ADDR(3) => hblankn_xx_s,
    ADDR(2) => hblankn_x_s,
    ADDR(1 downto 0) => hcount_s(3 downto 2),
    CSn => LDn_s,
    DATA => prom_7H_do_s
  );

  -- Data pin 7 is used above. Data pin 6 is not used.
  OBCLDn_s  <= prom_7H_do_s(5);
  CCLRn_s   <= prom_7H_do_s(4);
  SOCLDn_s  <= prom_7H_do_s(3);
  COLSETn_s <= prom_7H_do_s(2);
  VPSETn_s  <= prom_7H_do_s(1);
  DSETn_s   <= prom_7H_do_s(0);

  -- VPSET and DSET are used as clocks, so rising-edge enables
  -- are needed in order to keep everything synchronous.
  dset_vpset_delay : process(clk_i, clk_en_i) is
  begin
    if rising_edge(clk_i) and clk_en_i='1' then
      VPSETn_delay_s <= VPSETn_s;
      DSETn_delay_s  <= DSETn_s;
    end if;
  end process dset_vpset_delay;

  -- NOTE: This way of generating the enables keeps timing for these
  -- particular signals, since they only go low for one 6M cycle.
  -- But it is not generally correct for other signals.
  VPSETn_ena_s <= clk_en_i and VPSETn_delay_s and not VPSETn_s;
  DSETn_ena_s  <= clk_en_i and  DSETn_delay_s and not  DSETn_s;


  ---------------------------------------------------------------------------
  -- Video RAM Addressing
  ---------------------------------------------------------------------------

  -- Unlike Galaga, Bosconian does not use the Namco 00xx VRAM addresser.
  -- Instead, it accomplishes its addressing through discrete logic.

  -- It is useful for overall context to note here that Bosconian handles tile
  -- addressing while not in HBLANK, and handles sprite addressing while in
  -- HBLANK.

  -- mux here instead of original hardware's tristate.
  -- 1J, 1K: 74LS374 DFF
  -- playfield_posix and playfield_posiy represent the internal state of
  -- registers 1J and 1K; posix and posiy are those registers' outputs, which
  -- are pulled up when not in the playfield
  posix <= std_ulogic_vector(playfield_posix) when pf_n_s = '0' else "11111111";
  posiy <= std_ulogic_vector(playfield_posiy) when pf_n_s = '0' else "11111111";

  -- 3L, 3M: XOR
  -- Vertical position flip is simple
  vcount_flipped <= vcount_s xor (flip_s & flip_s & flip_s & flip_s & flip_s & flip_s & flip_s & flip_s);
  -- 3P, 6J: XOR
  -- Horizontal position flip is more complex, using some of hcount and some of posix
  hcount_flipped <= (hcount_s(4 downto 2) & posix(1 downto 0)) xor (flip_s & flip_s & flip_s & flip_s & flip_s);
                      
  -- 2K, 2J: 2x 74LS283 4-bit adder, combined to make an 8-bit adder
  -- When outside the playfield, since posiy is pulled up to 11111111
  -- and PF_n is the lower carry in, this will just be vcount.
  posiy_plus_vcount <= std_ulogic_vector(unsigned(posiy) + unsigned(vcount_flipped) + ("" & pf_n_s));

  -- 3M, 2L: 2x 74LS283 4-bit adder, combined to make a 6-bit adder
  -- The playfield flag is used as the low carry input.
  posix_plus_hcount <= std_ulogic_vector(unsigned(posix(7 downto 2)) + unsigned(hcount_s(7 downto 5) & hcount_flipped(4 downto 2)) + ("" & pf_n_s));

  -- note: original hardware uses tristate for a lot of this
  ab_mux : process(posix_plus_hcount, posiy_plus_vcount, pf_n_s, hblankn_s, hcount_s, addr_out_ena)
  begin
    -- The address bus is weakly (2.2k) pulled up if not driven.
    video_ram_addr_o <= "11111111111";

    -- 2N: 74LS244 Line Driver
    -- Applies the upper bits of the playfield-adjusted x/y positions
    -- to the address bus.
    if addr_out_ena = '1' and hblankn_s = '1' then
      video_ram_addr_o(9 downto 6) <= posiy_plus_vcount(7 downto 4);
    end if;
    -- The enable pin here is 2H_n, but active low. So it drives when 2H is up.
    if addr_out_ena = '1' then
      video_ram_addr_o(10) <= not pf_n_s;
      video_ram_addr_o(4 downto 2) <= posix_plus_hcount(5 downto 3);
    end if;

    -- 2P: 74LS257 MUX
    if addr_out_ena = '1' then
      if hblankn_s = '1' then
        video_ram_addr_o(5) <= posiy_plus_vcount(3); -- 4B
        video_ram_addr_o(1) <= posix_plus_hcount(2); -- 1B
        video_ram_addr_o(0) <= posix_plus_hcount(1); -- 2B
      else
        video_ram_addr_o(5) <= hcount_s(3); -- 4A
        video_ram_addr_o(1) <= hcount_s(4); -- 1A
        video_ram_addr_o(0) <= hcount_s(2); -- 2A
      end if;
    end if;
  end process;

  -- Original hardware uses hcount_flipped[2] as the clock for the following DFF,
  -- so an enable is needed.
  -- Since hcount_flipped[2] is equal to flip ^ hcount_07xx[2],
  -- we can use the edge enables output by the 07xx for this.
  hcount_flipped_2_ena <= c07_clken_negedge_s.hcount(2) when flip_s='1' else c07_clken_posedge_s.hcount(2);

  -- 6K: 74LS175 DFF with Clear
  -- Strangely, on the schematic, PF_n is input at 2D, but there is neither a 2Q
  -- nor a /2Q. So I ignore the 2D input here.
  i_6K : process(clk_i, hcount_flipped_2_ena) is
  begin
    if rising_edge(clk_i) and hcount_flipped_2_ena='1' then
      dff_6K_Qn34 <= not hcount_flipped(1 downto 0);
      s_256H_x <= hcount_s(8);
    end if;
  end process;


  ---------------------------------------------------------------------------
  -- Tile layout addressing
  ---------------------------------------------------------------------------

  -- 4C: 74LS243 8-Bit Register with Clear
  -- This latches the upper bits of the graphics ROM address
  -- (used for fetching both sprite and tile data), along with
  -- the flip flags for sprites.
  -- On original, this is clocked with /DSET.
  i_4C : process(clk_i, resn_i, DSETn_ena_s) is
  begin
    if resn_i='0' then
      gfx_addr_upper_s <= "000000"; -- 5Q, 6Q, 7Q, 8Q, 1Q, 2Q
      sprite_flipy_s   <= '0'; -- 3Q
      sprite_flipx_s   <= '0'; -- 4Q
    elsif rising_edge(clk_i) and DSETn_ena_s='1' then
      gfx_addr_upper_s <= std_ulogic_vector(db_a2_s(7 downto 2)); -- 5Q, 6Q, 7Q, 8Q, 1Q, 2Q
      sprite_flipy_s   <= db_a2_s(1); -- 3Q
      sprite_flipx_s   <= db_a2_s(0); -- 4Q
    end if;
  end process i_4C;

  -- 5F: 74LS174 DFF with Clear
  i_5F : process(clk_i, resn_i, c07_clken_negedge_s) is
  begin
    if resn_i='0' then
      dff_5F_Q1 <= '0';
      dff_5F_Q6 <= '0';
      dff_5F_Q32 <= "00";  -- 3Q, 2Q
      tile_flipy_s <= '0'; -- 4Q
      tile_flipx_s <= '0'; -- 5Q
    elsif rising_edge(clk_i) and c07_clken_negedge_s.hcount(1) = '1' then
      dff_5F_Q1 <= posiy_plus_vcount(2);
      dff_5F_Q6 <= posix_plus_hcount(0);
      dff_5F_Q32 <= posiy_plus_vcount(1 downto 0); -- 3Q, 2Q
      tile_flipy_s <= db_a3_s(7); -- 4Q
      tile_flipx_s <= db_a3_s(6); -- 5Q
    end if;
  end process i_5F;

  -- 6H, 6F: 74LS157 MUX
  -- Always enabled. Selector is /HBLANK*.
  -- This mux prepares to address the graphics ROMs.
  -- During hblank, it selects sprite info.
  -- When not in hblank, it grabs tile info.
  i_6H6F : process(sprite_flipy_s, sprite_flipx_s, hblankn_x_s, dff_5F_Q6, dff_5F_Q1, dff_5F_Q32, tile_flipy_s, tile_flipx_s, sprite_vcount, hcount_s) is
  begin
    if hblankn_x_s = '1' then -- use B inputs
      mux_6H_Y <= sprite_flipy_s & sprite_flipx_s & dff_5F_Q6 & dff_5F_Q1;
      mux_6F_1Y2Y <= dff_5F_Q32;
      flipy_s <= tile_flipy_s; -- 4Y <- 4B
      flipx_s <= tile_flipx_s; -- 3Y <- 3B
    else -- use A inputs
      -- XOR 6J outpin3, 8H, 4H, 5H 4Q
      mux_6H_Y <= (sprite_vcount(3) xor sprite_flipy_s) & hcount_s(3 downto 2) & sprite_vcount(2);
      -- 5H 2Q, 5H 3Q
      mux_6F_1Y2Y <= sprite_vcount(1 downto 0);
      flipy_s <= sprite_flipy_s; -- 4Y <- 4A
      flipx_s <= sprite_flipx_s; -- 3Y <- 3A
    end if;
  end process i_6H6F;


  ---------------------------------------------------------------------------
  -- Tile/sprite layout ROMs
  ---------------------------------------------------------------------------

  -- This address is used for both ROMs, 5D and 5E
  rom_5D5E_addr <= std_logic_vector(
    (gfx_addr_upper_s) &                    -- DB27 through DB22
    (mux_6H_Y(3 downto 2)) &                -- DB21, DB20
    (mux_6H_Y(1) xor flipx_s) &             -- DB19
    (mux_6H_Y(0) xor flipy_s) &             -- DB18
    (mux_6F_1Y2Y xor (flipy_s & flipy_s))); -- DB17, DB16


  -- 5D: 2732 EPROM (ROM section BS-P) - 12-bit addr, 8-bit data
  -- Contains tile layout data, 2bpp.
--  i_5D : entity work.dpram generic map (12,8)
--  port map
--  (
--    -- port A: initial load
--    clock_a   => clk_i,
--    wren_a    => romchar_wren,
--    address_a => a_i(11 downto 0),
--    data_a    => d_i,
--
--    -- port B: read during play
--    clock_b   => clkn_i,
--    address_b => rom_5D5E_addr,
--    q_b       => rom_5D_do
--  );

i_5D : entity work.gfx1
  port map(
	clk  => clkn_i,
	addr => rom_5D5E_addr,
	data => rom_5D_do
);

  -- 5D: 2732 EPROM (ROM section BS-N) - 12-bit addr, 8-bit data
  -- Contains sprite layout data, 2bpp.
--  i_5E : entity work.dpram generic map (12,8)
--  port map
--  (
--    -- port A: initial load
--    clock_a   => clk_i,
--    wren_a    => romsprite_wren,
--    address_a => a_i(11 downto 0),
--    data_a    => d_i,
--
--    -- port B: read during play
--    clock_b   => clkn_i,
--    address_b => rom_5D5E_addr,
--    q_b       => rom_5E_do
--  );
  
i_5E : entity work.gfx2
  port map(
	clk  => clkn_i,
	addr => rom_5D5E_addr,
	data => rom_5E_do
);  

  -- 2Hn is the output enable for both pins. When it is high (i.e., when
  -- hcount[1] is low), both ROMs output Hi-Z. However, there are no other
  -- drivers for this bus, so it's not clear what happens then - but it
  -- shouldn't matter, since shift registers 6D and 6C are only loading data
  -- when this bus is properly driven. I just assume a pullup.
  rom_5D5E_do <= "11111111" when hcount_s(1) = '0' else
                 std_ulogic_vector(rom_5D_do) when hblankn_x_s = '1' else
                 std_ulogic_vector(rom_5E_do);


  ---------------------------------------------------------------------------
  -- Tile palette and attribute handling
  ---------------------------------------------------------------------------

  -- 4K: Namco 03xx Custom Playfield Data Buffer / Controllable-Depth FIFO
  -- Delays output by 4 pixel clock cycles - but only when not in hblank.
  -- When in hblank, simply passes data through.
  i_4K : entity work.n03xx port map (
    clk_i               => clk_i,
    clk_en_i            => c07_clken_negedge_s.hcount(1),
    shift_i(2)          => hblankn_x_s,
    shift_i(1 downto 0) => "00",
    data_i              => std_ulogic_vector(db_a3_s(5 downto 0)),
    data_o              => buffer_03xx_4K_do
  );

  -- wire and_7F_outpin11 = dff_5H_1Q & hblank_x;
  and_7F_outpin11 <= dff_5H_1Q and hblank_x_s;

  -- 7F: 74LS08 AND - outpin 8; mislabeled on schematic as outpin 11
  -- Determine if the screen is flipped AND we're not in hblank.
  -- (When in hblank, sprite data is being sent to RAM; it will be
  -- flipped later when it actually gets rendered on the next line,
  -- so it should not be flipped now.)
  and_7F_outpin8 <= hblankn_x_s and flip_n_s;

  -- 6J: 74LS86 XOR - outpin 11
  -- Determine whether the next batch of pixels should be flipped
  -- while being shifted out.
  xor_6J_outpin11 <= flipx_s xor and_7F_outpin8;

  -- 4L: 74LS377 D-Register with Common Enable and Clock
  -- Original has 6MHZ as the clock and /COLSET as the enable
  i_4L : process(clk_i, clk_en_i, COLSETn_s) is
  begin
    if rising_edge(clk_i) and clk_en_i='1' and COLSETn_s='0' then
      reg_4L_4Q <= and_7F_outpin11;
      flip_pixels <= xor_6J_outpin11; -- 5Q
      palette_color <= buffer_03xx_4K_do; -- (618273)Q
    end if;
  end process i_4L;


  ---------------------------------------------------------------------------
  -- Pixel Shifters
  ---------------------------------------------------------------------------

  -- 6D, 6C: 74LS194 Bidirectional Universal Shift Register
  -- Original hardware clocked by 6MHZ.
  -- P is used as CLR (active low)
  -- Mode inputs S1 and S0 are common between the two registers.
  -- Serial inputs L and R are grounded, so shifts in both directions backfill with 0s.
  i_6D6C : process(clk_i, clk_en_i, resn_i) is
  begin
    if resn_i='0' then
      shiftreg_6D_Q <= "0000";
      shiftreg_6C_Q <= "0000";
    elsif rising_edge(clk_i) and clk_en_i='1' then
      if shiftreg_6D6C_S = "11" then
        shiftreg_6D_Q <= rom_5D5E_do(7 downto 4);
        shiftreg_6C_Q <= rom_5D5E_do(3 downto 0);
      elsif shiftreg_6D6C_S = "01" then
        shiftreg_6D_Q <= '0' & shiftreg_6D_Q(3 downto 1);
        shiftreg_6C_Q <= '0' & shiftreg_6C_Q(3 downto 1);
      elsif shiftreg_6D6C_S = "10" then
        shiftreg_6D_Q <= shiftreg_6D_Q(2 downto 0) & '0';
        shiftreg_6C_Q <= shiftreg_6C_Q(2 downto 0) & '0';
      end if;
      -- shiftreg_6D6C_S = "00": do nothing
    end if;
  end process i_6D6C;

  -- 7C: 74LS157 MUX
  -- Always enabled; selector is output 5Q from 4L
  -- NOTE: The schematic here appears to have some errors; if implemented
  -- exactly as diagrammed, the pixel shifter doesn't work properly.
  --
  --  * As mentioned (and addressed) elsewhere, LD and LD_n are most likely swapped.
  --  * The shift direction appears to be swapped.
  i_7C : process(flip_pixels, LD_s, shiftreg_6D_Q, shiftreg_6C_Q) is
  begin
    if flip_pixels='1' then
      shiftreg_6D6C_S <= LD_s & '1'; -- labelled 2A, 1A; using as 2B, 1B

      tilepixel_2bpp(1) <= shiftreg_6D_Q(0); -- 3B <- 6D QD
      tilepixel_2bpp(0) <= shiftreg_6C_Q(0); -- 4B <- 6C QD
    else
      shiftreg_6D6C_S <= '1' & LD_s; -- labelled 2B, 1B; using as 2A, 1A

      tilepixel_2bpp(1) <= shiftreg_6D_Q(3); -- 3A <- 6D QA
      tilepixel_2bpp(0) <= shiftreg_6C_Q(3); -- 4A <- 6C QA
    end if;
  end process i_7C;


  ---------------------------------------------------------------------------
  -- Tile Color Lookup
  ---------------------------------------------------------------------------

  -- 4M: MB7052 PROM (data BS-5) - 8-bit addr, 4-bit data
  -- This is the tile color lookup table. Always enabled.
  -- The real MB7052 appears to drive low, so it has 1K pullups
  -- on the outputs. Those are not needed here.
  i_4M : entity work.rom_4M port map (
    ADDR(7 downto 2) => palette_color,
    ADDR(1 downto 0) => tilepixel_2bpp,
    DATA => rom_4M_do
  );

  -- 4N: Namco 03xx Custom Playfield Data Buffer / Controllable-Depth FIFO
  -- Pins 7 and 12 (bit 5, both input and output) are not used.
  i_4N : entity work.n03xx port map (
    clk_i               => clk_i,
    clk_en_i            => clk_en_i,
    shift_i(2)          => '0',
    shift_i(1 downto 0) => SHIFT_s,
    data_i(5)           => '0',
    data_i(4)           => palette_color(5),
    data_i(3 downto 0)  => rom_4M_do,
    data_o(5)           => open,
    data_o(4 downto 0)  => buffer_03xx_4N_do
  );

  color_tile <= buffer_03xx_4N_do(3 downto 0);


  ---------------------------------------------------------------------------
  -- Object Position Matching / Vertical Addressing
  ---------------------------------------------------------------------------

  -- First, the game determines whether each sprite is about to be drawn and
  -- needs to be put into RAM. This is done by adding the Y position of the
  -- sprite (which is being sent over data bus A3) to the current y-position
  -- in the screen. If the upper four bits are 1111, then we have a match,
  -- and a line of the sprite needs to be put into the buffer.

  -- 3H, 3K: 74LS283 4-bit adders, paired to make an 8-bit adder.
  dba3_plus_vcount <= std_ulogic_vector(unsigned(db_a3_s) + unsigned(vcount_s));
  -- 3J: 74LS20 4-input NAND, outpin 6
  sprite_linematch_n <= '0' when dba3_plus_vcount(7 downto 4) = "1111" else '1';

  -- The small object linematch is choosier, since the small objects are only
  -- four pixels tall/wide.
  -- 3J: 74LS20 4-input NAND, outpin 8
  smallobj_linematch_n <= not (sprite_linematch and hcount_s(3) and dba3_plus_vcount(3) and dba3_plus_vcount(2));

  -- 6J: 74LS86 XOR (but one operand is P, so this is functionally an inverter)
  sprite_linematch <= sprite_linematch_n xor resn_i; -- outpin 6

  -- 5H: 74LS174 DFF with Clear
  -- Original hardware clocked by /VPSET.
  i_5H : process(clk_i, resn_i, VPSETn_ena_s) is
  begin
    if resn_i='0' then
      sprite_vcount <= "0000";
      dff_5H_1Q <= '0';
    elsif rising_edge(clk_i) and VPSETn_ena_s='1' then
      sprite_vcount <= dba3_plus_vcount(3 downto 0); -- 5Q, 4Q, 2Q, 3Q
      dff_5H_1Q <= sprite_linematch; -- 1Q
    end if;
  end process i_5H;


  ---------------------------------------------------------------------------
  -- Object RAM Addressing
  ---------------------------------------------------------------------------

  -- 3D, 3E: 74LS163 Binary Counters, Fully Synchronous
  -- Note: On the 74LS163, the reset is also synchronous.
  --
  -- Probable schematic error: The upper bits' counter is gated with
  -- the HCOUNT signal, and the lower bits' counter is gated with the
  -- upper bits' RC. I am pretty sure that is backwards.

  i_3D3E : process(clk_i, clk_en_i, CCLRn_s) is
  begin
    if rising_edge(clk_i) and clk_en_i='1' then
      if CCLRn_s='0' then
        ram_4J_addr <= "00000000";
      elsif OBCLDn_s='0' then
        ram_4J_addr <= db_a2_s;
      elsif HCOUNT_ena_s='1' then
        ram_4J_addr <= std_logic_vector(unsigned(ram_4J_addr) + 1);
      end if;
    end if;
  end process i_3D3E;

  -- 3N: 74LS20 dual 4-input NAND
  nand_3N_outpin6 <= '0' when rom_4M_do = "1111" else '1'; -- outpin 6
  nand_3N_outpin8 <= not (reg_4L_4Q and nand_3N_outpin6); -- outpin 8

  -- The CS (active low) for RAM 4J is low when either:
  --  * hblank_xx is low (we are displaying a line)
  --  * or nand_3N_outpin8 is low (we are writing a sprite to RAM)
  ram_4J_cs_n <= hblank_xx_s and nand_3N_outpin8; -- 7F: 74LS08 AND, outpin 3

  -- 4B: 74LS365 Buffer
  -- Original hardware enables (active low) are 6MHZ and /HBLANK**.
  -- Note: The i_clken_6M timing may not be quite right here. May need to investigate.
  ram_4J_di <= std_logic_vector(rom_4M_do) when clk_en_i='0' and hblankn_xx_s='0' else "1111";

  -- since our RAM module doesn't have an explicit CE pin
  ram_4J_we <= '1' when ram_4J_cs_n = '0' and clkn_en_i='1' else '0';

  -- 4J: M2148 RAM - 8-bit address, 4-bit data
  -- This RAM's write enable (active low) is the 6MHZ clock signal,
  -- meaning that it writes every single time 6MHz goes low if the RAM is
  -- selected. This means that, while scanning across the screen and reading
  -- this RAM, each nibble in the RAM will be cleared IMMEDIATELY after it is
  -- read!
  i_4J : entity work.gen_ram
  generic map(aWidth => 8, dWidth => 4)
  port map (
    clk  => clk_i,
    we   => ram_4J_we,
    addr => ram_4J_addr,
    d    => ram_4J_di,
    q    => ram_4J_do_pre_cs
  );

  -- The original hardware uses a bus for the RAM data I/O, with 1K pullups.
  -- Instead of using tristate logic, I just always read from the RAM, and
  -- drive the output to 1111 instead if the chip select is inactive.
  ram_4J_do <= ram_4J_do_pre_cs when ram_4J_cs_n = '0' else "1111";


  ---------------------------------------------------------------------------
  -- Small Object ROM Addressing
  ---------------------------------------------------------------------------

  -- 2C, 3F, 3C: 74LS163 Binary Counters, Fully Synchronous
  -- Note: On the 74LS163, the reset is also synchronous.
  -- The schematic is almost certainly incorrect here:
  -- it has the 6MHZ signal going to CLR instead of CK.
  -- Instead, I assume CCLR should be the clear signal
  -- (as it is for the sprite objects.)
  i_2C_3F_3C : process(clk_i, clk_en_i, CCLRn_s, SOCLDn_s) is
  begin
    if rising_edge(clk_i) and clk_en_i='1' then
      if CCLRn_s='0' then
        ram_2B_addr <= "000000000";
      elsif SOCLDn_s='0' then
        ram_2B_addr <= ram_2E_do_n(0) & db_a2_s;
      else
        ram_2B_addr <= std_logic_vector(unsigned(ram_2B_addr) + 1);
      end if;
    end if;
  end process i_2C_3F_3C;

  -- 1D: 74LS377 D-Register with Common Enable and Clock
  -- Original hardware: 6MHZ clock, LD_n as active-low enable
  -- Sets up the address for reading the Small Object ROM.
  -- Latches the SHIFT signals (sent to an 03XX).
  i_1D : process(clk_i, clk_en_i, LD_s) is
  begin
    if rising_edge(clk_i) and clk_en_i='1' and LD_s='1' then
      SHIFT_s <= dff_6K_Qn34; -- 7Q, 6Q
      rom_2D_cs <= smallobj_linematch_n; -- 5Q
      reg_1D_Q43218 <= ram_2E_do_n(3 downto 1) & dba3_plus_vcount(1 downto 0);
    end if;
  end process i_1D;


  ---------------------------------------------------------------------------
  -- Small Object Layout ROM
  ---------------------------------------------------------------------------

  -- 2D: MB7052 PROM (data BS-3) - 8-bit addr, 3-bit data
  -- Contains small-object layout data.
  -- Only uses the first half of the address space; hence, the top bit of the
  -- address is grounded. Also only uses the lower 3 bits of the data.
--  rom_2D_addr <= std_logic_vector('0' & reg_1D_Q43218 & hcount_s(1 downto 0));
--  i_2D : entity work.dpram generic map (8,3)
--  port map
--  (
--    -- port A: initial load
--    clock_a   => clk_i,
--    wren_a    => romradar_wren,
--    address_a => a_i(7 downto 0),
--    data_a    => d_i(2 downto 0),
--
--    -- port B: read during play
--    clock_b   => clkn_i,
--    address_b => rom_2D_addr,
--    q_b       => rom_2D_do
--  );

--i_2D : entity work.gfx3
--port map(
--	clk	=> clkn_i,
--	addr 	=> rom_2D_addr(4 downto 0),
--	data  => rom_2D_do(2 downto 0)
--);

  ---------------------------------------------------------------------------
  -- Small Object Buffer RAM
  ---------------------------------------------------------------------------

  -- Small objects are loaded from ROM into a buffer that is populated during
  -- hblank, then read (and immediately cleared) during display.
  -- (So it works the same as the "large" object (sprite) buffer.

  -- CS is from 1D; OE is /HBLANK** (active low).
  -- If output not active, output has 1K pullups.
  rom_2D_do_gated <= std_ulogic_vector(rom_2D_do) when rom_2D_cs='0' and hblankn_xx_s='0' else "111";

  -- 4B: 74LS365 Hex Buffer - Just used as a simple buffer, so not implemented.
  -- 74LS365 has output enables, but they're not used according to the schematic.

  ram_2B_cs_n <= hblank_xx_s and rom_2D_do_gated(2); -- 7F: 74LS08 AND, outpin6

  -- since our RAM module doesn't have an explicit CE pin
  ram_2B_we <= '1' when ram_2B_cs_n = '0' and clkn_en_i='1' else '0';

  ram_2B_di <= std_logic_vector(rom_2D_do_gated(1 downto 0));

  -- 2B: MB2148 RAM - 9-bit address, 2-bit data
  -- (actually appears to be 10-bit x 4-bit, but the upper address bit and upper
  -- two data bits are unused and grounded.)
  --
  -- The schematic is almost certainly wrong here: the write input for the RAM
  -- is connected only to the CLK input for binary counters 2C, 3F, and 3C.
  -- My best guess is that these are all actually driven by the 6MHZ clock
  -- signal, same as the sprite buffer RAM.
  --
  -- This RAM's write enable (active low) is the 6MHZ clock signal,
  -- meaning that it writes when 6MHZ is low.
  i_2B : entity work.gen_ram
  generic map(aWidth => 9, dWidth => 2)
  port map (
    clk  => clk_i,
    we   => ram_2B_we,
    addr => ram_2B_addr,
    d    => ram_2B_di,
    q    => ram_2B_do_pre_cs
  );

  -- The original hardware uses a bus for the RAM data I/O, with 1K pullups.
  -- Instead of using tristate logic, I just always read from the RAM, and
  -- drive the output to 11 instead if the chip select is inactive.
  ram_2B_do <= ram_2B_do_pre_cs when ram_2B_cs_n = '0' else "11";


  ---------------------------------------------------------------------------
  -- Final Color Mixing and Starfield Generator
  ---------------------------------------------------------------------------

  -- 7D: 74LS174 DFF with Clear
  -- The clock for this flip-flop is /6MHZ. It latches pixel data from the
  -- sprite and small-object RAMs in preparation for drawing the next pixel.
  i_7D : process(clk_i, resn_i, clkn_en_i) is
  begin
    if resn_i='0' then
      color_smallobj <= "11"; -- 1Q, 2Q
      color_sprite <= "1111"; -- 3Q, 4Q, 5Q, 6Q
    elsif rising_edge(clk_i) and clkn_en_i='1' then
      color_smallobj <= std_ulogic_vector(ram_2B_do); -- 1Q, 2Q
      color_sprite <= std_ulogic_vector(ram_4J_do); -- 3Q, 4Q, 5Q, 6Q
    end if;
  end process i_7D;


  -- 5A: PAL (BS-8)
  -- 5A has not been dumped as far as I'm aware, so its function here
  -- is inferred from the inputs it is given and the output it is supposed to
  -- produce (based on comparisons to MAME.)
  i_5A : process(pal_blankn_s, color_tile, color_sprite, color_smallobj) is
  begin
    -- Only draw when not in hblank or vblank
    if pal_blankn_s='1' then
      -- Precedence: small objs > tiles > sprites
      if color_smallobj /= "11" then
        palette_5A_do <= "111" & not color_smallobj;
      elsif color_tile /= "1111" then
        palette_5A_do <= '1' & color_tile;
      else
        palette_5A_do <= '0' & color_sprite;
      end if;
    else
      palette_5A_do <= "11111";
    end if;
  end process i_5A;

  -- 6B: MB7051 PROM (data BS-6) - 5-bit addr, 8-bit data
  -- This is the final RGB lookup table.
  i_6B: entity work.rom_6b port map (
    ADDR => palette_5A_do,
    DATA => prom_6B_do
  );

  -- The 4th bit (highest bit) of the output from 4N appears to correspond to
  -- whether the game is currently drawing the playfield area. This is
  -- important here, since the stars are not drawn outside the playfield.
  palette_playfield_n <= buffer_03xx_4N_do(4);
  n05_oen_s <= '0' when palette_5A_do(3 downto 0) = "1111" and palette_playfield_n = '0' else '1';

  -- Not on original hardware: When the user pauses, we need to override the
  -- 05xx scroll speeds; otherwise, the playfield will be fixed but the stars
  -- will continue to scroll.
  n05_xctrl <= "111" when pause = '1' else sf_x_s;
  n05_yctrl <= "000" when pause = '1' else sf_y_s;

  -- 5B: Namco 05xx Starfield Generator
  i_5B : entity work.n05xx
    port map (
      clk_i    => clk_i,
      clk_en_i => clk_en_i,
      resn_i   => sf_starclr_s,
      oen_i    => n05_oen_s,
      en_i     => s_256H_x,
      vsn_i    => vsyncn_s,
      hsn_i    => hsyncn_s,
      xctrl_i  => n05_xctrl,
      yctrl_i  => n05_yctrl,
      map_i    => sf_blk_s,
      rgb_o    => star_rgb,
      lsfr_o   => open,
      oe_o     => star_oe
      );

  -- Final mix of palette colors with star colors.
  -- On original hardware, the 05xx output-enable output is used as the
  -- (active-low) chip select for the 6B RGB PROM, but it's equivalent
  -- (and simpler) to just mux the colors directly here.
  r_o <= star_rgb(5 downto 4) & '0' when star_oe = '1' else prom_6B_do(2 downto 0);
  g_o <= star_rgb(3 downto 2) & '0' when star_oe = '1' else prom_6B_do(5 downto 3);
  b_o <= star_rgb(1 downto 0)       when star_oe = '1' else prom_6B_do(7 downto 6);

end rtl;
