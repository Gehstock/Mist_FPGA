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
		INDEX		: natural;
		DELAY   : integer
	);
	port               
	(
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
  
  signal flipData : std_logic_vector(47 downto 0);   -- flipped row data
   
  alias rgb       : RGB_t is ctl_o.rgb;
  
begin

  flipData(47 downto 32) <= flip_1 (ctl_i.d(47 downto 32), reg_i.xflip);
  flipData(31 downto 16) <= flip_1 (ctl_i.d(31 downto 16), reg_i.xflip);
  flipData(15 downto 0) <= flip_1 (ctl_i.d(15 downto 0), reg_i.xflip);
  
	process (clk, clk_ena)

   	variable rowStore : std_logic_vector(47 downto 0);  -- saved row of spt to show during visibile period
		variable pel      : std_logic_vector(2 downto 0);
    variable x        : unsigned(video_ctl.x'range);
    variable y        : unsigned(video_ctl.y'range);
    variable yMat     : boolean;      -- raster is between first and last line of sprite
    variable xMat     : boolean;      -- raster in between left edge and end of line

    variable height     : unsigned(6 downto 0);
		-- the width of rowCount determines the scanline multipler
		-- - eg.	(4 downto 0) is 1:1
		-- 				(5 downto 0) is 2:1 (scan-doubling)
--  	variable rowCount : unsigned(3+PACE_VIDEO_V_SCALE downto 0);
--    alias row         : unsigned(4 downto 0) is 
--                          rowCount(rowCount'left downto rowCount'left-4);
    variable rowCount   : unsigned(height'range);
    alias row           : unsigned(rowCount'range) is rowCount;
    -- which part of the sprite is being drawn
    alias segment       : unsigned(1 downto 0) is rowCount(5 downto 4);
    
    variable prom_i     : integer range sprite_prom'range;
    variable code       : std_logic_vector(9 downto 0);
    variable pal_i      : std_logic_vector(7 downto 0);
		variable pal_rgb    : pal_rgb_t;
    
  begin

		if rising_edge(clk) then
      if clk_ena = '1' then
        if video_ctl.hblank = '1' then

          x := unsigned(reg_i.x) - M62_VIDEO_H_OFFSET + PACE_VIDEO_PIPELINE_DELAY - 3;
          y := 256 + 128 - 15 - unsigned(reg_i.y);

          -- hande sprite height, placement
          prom_i := to_integer(unsigned(reg_i.n(9 downto 5)));
          code := reg_i.n(9 downto 0); -- default
          case sprite_prom(prom_i) is
            when 1 =>
              -- double height
              height := to_unsigned(2*16,height'length);
              y := y - 16;
            when 2 =>
              -- quadruple height
              height := to_unsigned(4*16,height'length);
              y := y - 3*16;
            when others =>
              height := to_unsigned(16,height'length);
          end case;
          
          -- do this 1st because we don't have many clocks
          if y = unsigned(video_ctl.y) then
            -- start counting sprite row
            rowCount := (others => '0');
            yMat := true;
          elsif row = height then
            yMat := false;				
          end if;

          case sprite_prom(prom_i) is
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

          xMat := false;
          -- stop sprites wrapping from bottom of screen
          if y = 0 then
            yMat := false;
          end if;
          
          -- sprites not visible before row 16				
          if ctl_i.ld = '1' then
            if yMat then
              rowStore := flipData;			-- load sprite data
            else
              rowStore := (others => '0');
            end if;
          end if;
              
        end if; -- hblank='1'
        
        if video_ctl.stb = '1' then
      
          if x = unsigned(video_ctl.x) then
            -- count up at left edge of sprite
            rowCount := rowCount + 1;
            -- start of sprite
            --if unsigned(x) /= 0 and unsigned(x) < 240 then
              xMat := true;
            --end if;
          end if;
          
          if xMat then
            -- shift in next pixel
            pel := rowStore(rowStore'left-32) & rowStore(rowStore'left-16) & rowStore(rowStore'left);
            rowStore(47 downto 32) := rowStore(46 downto 32) & '0';
            rowStore(31 downto 16) := rowStore(30 downto 16) & '0';
            rowStore(15 downto 0) := rowStore(14 downto 0) & '0';
          end if;

        end if;

        if PLATFORM_VARIANT = "ldrun" or
            PLATFORM_VARIANT = "battroad" then
          pal_i := '0' & reg_i.colour(3 downto 0) & pel;
        else
          pal_i := reg_i.colour(4 downto 0) & pel;
        end if;
        --pal_i := "000" & std_logic_vector(to_unsigned(INDEX,5));
        pal_rgb := sprite_pal(to_integer(unsigned(pal_i)));
        rgb.r <= pal_rgb(0) & "00";
        rgb.g <= pal_rgb(1) & "00";
        rgb.b <= pal_rgb(2) & "00";

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
    ctl_o.a(4) <= '0'; -- dual-port RAM
    if reg_i.yflip = '0' then
      ctl_o.a(3 downto 0) <= std_logic_vector(row(3 downto 0));
    else
      ctl_o.a(3 downto 0) <=  not std_logic_vector(row(3 downto 0));
    end if;

  end process;

end architecture SYN;
