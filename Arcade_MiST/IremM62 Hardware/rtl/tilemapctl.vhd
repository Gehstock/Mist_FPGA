library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pace_pkg.all;
--use work.project_pkg.all;
use work.platform_pkg.all;
use work.platform_variant_pkg.all;
use work.video_controller_pkg.all;

--
--  Irem M62 Tilemap Controller
--
--  Tile data is 2 BPP.
--
entity tilemapCtl is          
  generic
  (
    DELAY       : integer
  );
  port               
  (
    reset       : in std_logic;
    hwsel       : in integer;

    -- video control signals		
    video_ctl   : in from_VIDEO_CTL_t;

    -- tilemap controller signals
    ctl_i       : in to_TILEMAP_CTL_t;
    ctl_o       : out from_TILEMAP_CTL_t;

    graphics_i  : in to_GRAPHICS_t
  );
end entity tilemapCtl;

architecture TILEMAP_1 of tilemapCtl is

  alias clk       : std_logic is video_ctl.clk;
  alias clk_ena   : std_logic is video_ctl.clk_ena;
  alias stb       : std_logic is video_ctl.stb;
  alias hblank    : std_logic is video_ctl.hblank;
  alias vblank    : std_logic is video_ctl.vblank;
  
  signal x        : std_logic_vector(video_ctl.x'range);
  signal y        : std_logic_vector(video_ctl.y'range);
  
  alias rot_en    : std_logic is graphics_i.bit8(0)(0);
  alias hscroll   : std_logic_vector(15 downto 0) is graphics_i.bit16(0);
  alias vscroll   : std_logic_vector(15 downto 0) is graphics_i.bit16(1);

begin

  ctl_o.rgb <= ctl_i.rgb;

  -- not used
  ctl_o.map_a(ctl_o.map_a'left downto 12) <= (others => '0');
  ctl_o.attr_a(ctl_o.attr_a'left downto 12) <= (others => '0');
  ctl_o.tile_a(ctl_o.tile_a'left downto 15) <= (others => '0');

  -- tilemap scroll
  x <=  std_logic_vector(video_ctl.video_h_offset + unsigned(video_ctl.x)) when unsigned(y) < 6*8 and HWSEL = HW_KUNGFUM else
        std_logic_vector(video_ctl.video_h_offset + unsigned(video_ctl.x) + unsigned(hscroll(8 downto 0))); 
  y <= std_logic_vector(unsigned(video_ctl.y) + unsigned(vscroll(8 downto 0)) + 128) when hwsel = HW_SPELUNKR else
       std_logic_vector(unsigned(video_ctl.y) + unsigned(vscroll(8 downto 0))); -- when rot_en = '0' else video_ctl.x;
  -- generate pixel
  process (clk, clk_ena)

    variable tile_d_r   : std_logic_vector(23 downto 0);
    variable attr_d_r   : std_logic_vector(7 downto 0);
    variable flipx      : std_logic;
    variable pel        : std_logic_vector(2 downto 0);

  begin
  
    if rising_edge(clk) then
      if clk_ena = '1' then

        -- 1st stage of pipeline
        -- - set tilemap, attribute address
        if hwsel = HW_SPELUNKR or hwsel = HW_SPELUNK2 then
          -- 64x64 tilemap
          ctl_o.map_a(11) <= y(8);
          ctl_o.attr_a(11) <= y(8);
        else
          ctl_o.map_a(11) <= '0';
          ctl_o.attr_a(11) <= '0';
        end if;
        ctl_o.map_a(10 downto 6) <= y(7 downto 3);
        ctl_o.map_a(5 downto 0) <= x(8 downto 3);
        ctl_o.attr_a(10 downto 6) <= y(7 downto 3);
        ctl_o.attr_a(5 downto 0) <= x(8 downto 3);

        -- 2nd stage of pipeline
        -- - set tile address
        if x(2 downto 0) = "010" then
          if hwsel = HW_SPELUNKR or hwsel = HW_SPELUNK2 then
            ctl_o.tile_a(14) <= ctl_i.attr_d(5);
          else
            ctl_o.tile_a(14) <= '0';
          end if;
          if hwsel = HW_LDRUN4 or hwsel = HW_HORIZON then
            ctl_o.tile_a(13) <= ctl_i.attr_d(5);
          elsif hwsel = HW_KIDNIKI or hwsel = HW_SPELUNKR or hwsel = HW_SPELUNK2 then
            ctl_o.tile_a(13) <= ctl_i.attr_d(7);
          else
            ctl_o.tile_a(13) <= '0';
          end if;
          if hwsel = HW_BATTROAD or hwsel = HW_SPELUNKR or hwsel = HW_SPELUNK2 then
            ctl_o.tile_a(12 downto 11) <= ctl_i.attr_d(6) & ctl_i.attr_d(4);
          elsif hwsel = HW_KIDNIKI then
            ctl_o.tile_a(12 downto 11) <= ctl_i.attr_d(6 downto 5);
          else
            ctl_o.tile_a(12 downto 11) <= ctl_i.attr_d(7 downto 6);
          end if;
          ctl_o.tile_a(10 downto 3) <= ctl_i.map_d(7 downto 0);
          ctl_o.tile_a(2 downto 0) <= y(2 downto 0);
        end if;

        -- 3rd stage of pipeline
        -- - read tile, attribute data from ROM
        if x(2 downto 0) = "100" then
          attr_d_r := ctl_i.attr_d(7 downto 0);
          if hwsel = HW_KUNGFUM or
             hwsel = HW_LOTLOT or
             hwsel = HW_LDRUN or
             hwsel = HW_LDRUN2 or
             hwsel = HW_BATTROAD
          then
            flipx := attr_d_r(5);
          else
            flipx := '0';
          end if;
          tile_d_r := ctl_i.tile_d(tile_d_r'range);
        elsif stb = '1' then
          if flipx = '0' then
            tile_d_r := tile_d_r(tile_d_r'left-1 downto 0) & '0';
          else
            tile_d_r := '0' & tile_d_r(tile_d_r'left downto 1);
          end if;
        end if;

        -- extract R,G,B from colour palette
        if flipx = '0' then
          pel := tile_d_r(tile_d_r'left-16) & tile_d_r(tile_d_r'left-8) & tile_d_r(tile_d_r'left);
        else
          pel := tile_d_r(tile_d_r'right) & tile_d_r(tile_d_r'right+8) & tile_d_r(tile_d_r'right+16);
        end if;

        ctl_o.pal_a <= attr_d_r(4 downto 0) & pel;
        ctl_o.set <= '0'; -- default
--        if pel /= "000" then
--            pal_rgb(0)(7 downto 5) /= "000" or
--            pal_rgb(1)(7 downto 5) /= "000" or
--            pal_rgb(2)(7 downto 5) /= "000" then
          if graphics_i.bit8(0)(3) = '1' then
            ctl_o.set <= '1';
          end if;
--        end if;

      end if; -- clk_ena
    end if; -- rising_edge_clk

  end process;

end architecture TILEMAP_1;
