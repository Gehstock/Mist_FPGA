---------------------------------------------------------------------------------
-- Line doubler - Dar - Feb 2014
---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity line_doubler is
port(
	clock   : in std_logic;
	video_i : in std_logic_vector(3 downto 0);
	hsync_i : in std_logic;
	vsync_i : in std_logic;  
	video_o : out std_logic_vector(3 downto 0);
	hsync_o : out std_logic;
	vsync_o : out std_logic
);
end line_doubler;

architecture struct of line_doubler is

signal hsync_i_reg  : std_logic;
signal vsync_i_reg  : std_logic;
signal hcnt_i       : integer range 0 to 1023;
signal vcnt_i       : integer range 0 to 511;
signal hcnt_o       : integer range 0 to 511;

signal flip_flop : std_logic;
signal blank     : std_logic;

type ram_1024x8 is array(0 to 1023) of std_logic_vector(3 downto 0);
signal ram1  : ram_1024x8;
signal ram2  : ram_1024x8;
signal video : std_logic_vector(3 downto 0);

begin

process(clock)
begin
	if rising_edge(clock) then

		hsync_i_reg <= hsync_i;
		vsync_i_reg <= vsync_i;

		if (vsync_i = '0' and vsync_i_reg = '1') then
			vcnt_i <= 0;
		else
			if (hsync_i = '0' and hsync_i_reg = '1') then
				vcnt_i <= vcnt_i + 1;
			end if;
		end if;

		if (hsync_i = '0' and hsync_i_reg = '1') then
			flip_flop <= not flip_flop;
			hcnt_i <= 0;
		else
			hcnt_i <= hcnt_i + 1;
		end if;

		if (hsync_i = '0' and hsync_i_reg = '1') or hcnt_o = 319 then
			hcnt_o <= 0;
		else
			hcnt_o <= hcnt_o + 1;
		end if;

--		if     hcnt_o = 0 then hsync_o <= '0';
--		elsif  hcnt_o = 4 then hsync_o <= '1';
--		end if;

		if     hcnt_o = 319-2-4 then hsync_o <= '0';
		elsif  hcnt_o = 319-2 then hsync_o <= '1';
		end if;

		if     hcnt_o =  54 then blank <= '0';
		elsif  hcnt_o = 308 then blank <= '1';
		end if;

		if     vcnt_i = 0 then vsync_o <= '0';
		elsif  vcnt_i = 4 then vsync_o <= '1';
		end if;

	end if;
end process;

process(clock)
begin
	if rising_edge(clock) then
		if flip_flop = '0' then
			ram1(hcnt_i/2) <= video_i;
			video <= ram2(hcnt_o);
		else
			ram2(hcnt_i/2) <= video_i;
			video <= ram1(hcnt_o);
		end if;
	end if;
	
	if blank = '0' then
		video_o <= video;
	else
		video_o <= (others => '0');
	end if;
	
end process;

end architecture;