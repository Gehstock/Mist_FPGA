library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.pace_pkg.all;
use work.video_controller_pkg.all;
use work.platform_pkg.all;

--
--	Midway 8080 Bitmap Controller
--

architecture BITMAP_1 of bitmapCtl is

  alias clk       : std_logic is video_ctl.clk;
  alias clk_ena   : std_logic is video_ctl.clk_ena;
  alias stb       : std_logic is video_ctl.stb;
  alias hblank    : std_logic is video_ctl.hblank;
  alias vblank    : std_logic is video_ctl.vblank;
  --alias x         : std_logic_vector(video_ctl.x'range) is video_ctl.x;
  --alias y         : std_logic_vector(video_ctl.y'range) is video_ctl.y;
  
  alias rgb       : RGB_t is ctl_o.rgb;

  signal x        : std_logic_vector(video_ctl.x'range);
  signal y        : std_logic_vector(video_ctl.y'range);
  
  signal chr_x    : std_logic_vector(4 downto 0);
  signal chr_y    : std_logic_vector(4 downto 0);
  
  alias rot_en    : std_logic is graphics_i.bit8(0)(0);
  
begin

  -- flip X,Y to rotate the screen in the opposite direction for my cabinet
  x <= not video_ctl.x when rot_en = '0' else not video_ctl.y;
  y <= not video_ctl.y when rot_en = '0' else 32 + video_ctl.x;

  -- cellophane coordinate system independent of video for now
  chr_x <= video_ctl.x(7 downto 3) when rot_en = '0' else 1 + video_ctl.y(7 downto 3);
  -- bottom line green still not right... fix it later
  chr_y <= video_ctl.y(7 downto 3) when rot_en = '0' else not video_ctl.x(7 downto 3);
  
  -- generate pixel
  process (clk)
    variable bitmap_d_r   : std_logic_vector(7 downto 0);
    variable i            : integer range 0 to 7;
    variable pel          : std_logic;
  begin

  	if rising_edge(clk) and clk_ena = '1' then

      -- 1st stage of pipeline
      -- - read tile from tilemap
      if stb = '1' then
        ctl_o.a(12 downto 5) <= y(7 downto 0);
        ctl_o.a(4 downto 0) <= x(7 downto 3);
      end if;
      
      if rot_en = '0' then
        if x(2 downto 0) = 0 then
          bitmap_d_r := ctl_i.d(7 downto 0);
        else
          bitmap_d_r := bitmap_d_r(bitmap_d_r'left-1 downto 0) & '0';
        end if;
        pel := bitmap_d_r(bitmap_d_r'left);
      else
        i := to_integer(unsigned(x(2 downto 0)));
        pel := ctl_i.d(i);
      end if;
      
      -- emulate the coloured cellophane overlays
      rgb.r <= (others => '0');
      rgb.g <= (others => '0');
      rgb.b <= (others => '0');
      if pel = '1' then
        if chr_x < 5 then
          -- white
          rgb.r(9 downto 0) <= (others => '1');
          rgb.g(9 downto 0) <= (others => '1');
          rgb.b(9 downto 0) <= (others => '1');
        elsif chr_x < 9 then
          rgb.r(9 downto 0) <= (others => '1');	-- red
        elsif chr_x < 24 then
          -- white
          rgb.r(9 downto 0) <= (others => '1');
          rgb.g(9 downto 0) <= (others => '1');
          rgb.b(9 downto 0) <= (others => '1');
        elsif chr_x < 31 then
          rgb.g(9 downto 0) <= (others => '1');	-- green
        else
          if chr_y < 11 then
            -- white ("CREDIT 00")
            rgb.r(9 downto 0) <= (others => '1');
            rgb.g(9 downto 0) <= (others => '1');
            rgb.b(9 downto 0) <= (others => '1');
          elsif chr_y < 29 then
            -- green (bases)
            rgb.g(9 downto 0) <= (others => '1');
          else
            -- white (ships left)
            rgb.r(9 downto 0) <= (others => '1');
            rgb.g(9 downto 0) <= (others => '1');
            rgb.b(9 downto 0) <= (others => '1');
          end if;
        end if;
      else
        null; -- black
      end if;
      
		end if; -- rising_edge(clk)

  end process;

	-- not used/constant
	ctl_o.a(15 downto 13) <= (others => '0');
	ctl_o.set <= '1';

end architecture BITMAP_1;

