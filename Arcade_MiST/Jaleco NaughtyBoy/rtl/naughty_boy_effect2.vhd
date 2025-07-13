---------------------------------------------------------------------------------
-- Naughty Boy sound effect2 by Dar (darfpga@aol.fr) (April 2025)
-- http://darfpga.blogspot.fr
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;

entity naughty_boy_effect2 is
port(
 clk12    : in std_logic;
 clksnd   : in std_logic;
 divider  : in std_logic_vector(3 downto 0);
 snd      : out std_logic
); end naughty_boy_effect2;

architecture struct of naughty_boy_effect2 is

 signal clksnd_r : std_logic := '0';
 signal sound    : std_logic := '0';
 
begin

-- Diviseur
-- LS163 : Count up, Sync load when 0xF (no toggle sound if divider = 0xF)
-- LS74  : Divide by 2

process (clk12)
	variable cnt  : unsigned(3 downto 0) := (others => '0');
begin
	if rising_edge(clk12) then
		if divider = "1111" then
			sound <=  '0';
		else
			clksnd_r <= clksnd;
			if clksnd = '1' and clksnd_r = '0' then
				cnt  := cnt + 1;
				if cnt = "0000" then
					cnt := unsigned(divider);
					sound <=  not sound;
				end if;
			end if;
		end if;
	end if;
end process;
 
snd <= sound;
 
end struct;

