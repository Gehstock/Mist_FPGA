library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pace_pkg.all;
use work.video_controller_pkg.all;
use work.sprite_pkg.all;
--use work.project_pkg.all;
use work.platform_pkg.all;    
use work.platform_variant_pkg.all;

entity spritectl is
  generic
  (
    INDEX   : natural;
    DELAY   : integer
  );
  port
  (
    hwsel       : in integer range 0 to 15;
    
    -- sprite registers
    reg_i       : in from_SPRITE_REG_t;

    -- video control signals
    video_ctl   : in from_VIDEO_CTL_t;

    -- sprite control signals
    ctl_i       : in to_SPRITE_CTL_t;
    ctl_o       : out from_SPRITE_CTL_t;

    graphics_i  : in to_GRAPHICS_t
  );
end entity spritectl;

architecture SYN of spritectl is

  alias clk       : std_logic is video_ctl.clk;
  alias clk_ena   : std_logic is video_ctl.clk_ena;

  signal ld_r     : std_logic;
  signal left_d   : std_logic;
  signal hblank_r : std_logic;
  signal rowStore : std_logic_vector(47 downto 0);  -- saved row of spt to show during visibile period
  signal rowCount : unsigned(5 downto 0);
  -- which part of the sprite is being drawn
  alias segment   : unsigned(1 downto 0) is rowCount(5 downto 4);

begin

  process (clk, clk_ena, left_d, rowCount, reg_i)

    variable pel      : std_logic_vector(2 downto 0);
    variable x        : unsigned(video_ctl.x'range);
    variable y        : unsigned(video_ctl.y'range);
    variable xMat     : boolean;      -- raster in between left edge and end of line
    variable yMat     : boolean;      -- raster is between first and last line of sprite

    variable height   : unsigned(1 downto 0);

    variable code     : std_logic_vector(9 downto 0);

  begin

    if rising_edge(clk) then
      if clk_ena = '1' then
        ld_r <= ctl_i.ld;
        hblank_r <= video_ctl.hblank;
        if video_ctl.hblank = '1' then

          x := unsigned(reg_i.x) - video_ctl.video_h_offset + PACE_VIDEO_PIPELINE_DELAY - 2;
          y := 256 + 128 - 18 - unsigned(reg_i.y);

          -- hande sprite height, placement
          code := reg_i.n(9 downto 0); -- default
          case ctl_i.height is
            when 1 =>
              -- double height
              y := y - 16;
            when 2 =>
              -- quadruple height
              y := y - 3*16;
            when others =>
              null;
          end case;

          height := to_unsigned(ctl_i.height,2);
          height(0) := height (0) or height(1);

          -- count row at start of hblank
          if hblank_r = '0' then
            if y = unsigned(video_ctl.y) then
              -- start counting sprite row
              rowCount <= (others => '0');
              yMat := true;
            elsif rowCount = height & "1111" then
              yMat := false;
            else
              rowCount <= rowCount + 1;
            end if;

            -- stop sprites wrapping from bottom of screen
            if y = 0 then
              yMat := false;
            end if;
          end if;

          case ctl_i.height is
            when 1 =>
              -- double height
              if reg_i.yflip = '1' then
                code(0) := not segment(0);
              else
                code(0) := segment(0);
              end if;
            when 2 =>
              -- quadruple height
              if reg_i.yflip = '1' then
                code(1 downto 0) := not std_logic_vector(segment);
              else
                code(1 downto 0) := std_logic_vector(segment);
              end if;
            when others =>
              null;
          end case;

          if ld_r = '0' and ctl_i.ld = '1' then
            xMat := false;
            left_d <= not left_d; -- switch sprite half
            if yMat then
              if left_d = '1' then
                -- store first half of the sprite line data
                rowStore(39 downto 32) <= ctl_i.d(23 downto 16);
                rowStore(23 downto 16) <= ctl_i.d(15 downto  8);
                rowStore( 7 downto  0) <= ctl_i.d( 7 downto  0);
              else
                -- load sprite data
                rowStore(47 downto 40) <= ctl_i.d(23 downto 16);
                rowStore(31 downto 24) <= ctl_i.d(15 downto  8);
                rowStore(15 downto  8) <= ctl_i.d( 7 downto  0);
              end if;
            else
              rowStore <= (others => '0');
            end if;
          end if;
        else
          left_d <= '0';
        end if; -- hblank='1'

        if video_ctl.stb = '1' then

          if x = unsigned(video_ctl.x) then
              xMat := true;
          end if;

          if xMat then
            -- shift in next pixel
            if reg_i.xflip = '1' then
              pel := rowStore(rowStore'right) & rowStore(rowStore'right+16) & rowStore(rowStore'right+32);
              rowStore(47 downto 32) <= '0' & rowStore(47 downto 33);
              rowStore(31 downto 16) <= '0' & rowStore(31 downto 17);
              rowStore(15 downto  0) <= '0' & rowStore(15 downto  1);
            else
              pel := rowStore(rowStore'left-32) & rowStore(rowStore'left-16) & rowStore(rowStore'left);
              rowStore(47 downto 32) <= rowStore(46 downto 32) & '0';
              rowStore(31 downto 16) <= rowStore(30 downto 16) & '0';
              rowStore(15 downto  0) <= rowStore(14 downto  0) & '0';
            end if;
          end if;

        end if;

        ctl_o.pal_a <= reg_i.colour(4 downto 0) & pel;

        -- set pixel transparency based on match
        ctl_o.set <= '0';
        if xMat and pel /= "000" then
          if graphics_i.bit8(0)(4) = '1' then
            ctl_o.set <= '1';
          end if;
        end if;

      end if; -- clk_ena='1'
    end if; -- rising_edge(clk)
    
    -- generate sprite data address
    ctl_o.a(15) <= '0'; -- unused
    ctl_o.a(14 downto 5) <= code;
    ctl_o.a(4) <= left_d;
    if reg_i.yflip = '0' then
      ctl_o.a(3 downto 0) <= std_logic_vector(rowCount(3 downto 0));
    else
      ctl_o.a(3 downto 0) <=  not std_logic_vector(rowCount(3 downto 0));
    end if;

  end process;

end architecture SYN;
