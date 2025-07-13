---------------------------------------------------------------------------------
-- Naughty boy sound effect4 by Dar (darfpga@aol.fr) (April 2025)
-- http://darfpga.blogspot.fr
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;

entity naughty_boy_effect4 is
port(
 clk12      : in std_logic;
 trigger_A6 : in std_logic;
 trigger_A7 : in std_logic;
 noise      : in std_logic;
 snd_A6     : out std_logic_vector(7 downto 0);
 snd_A7     : out std_logic_vector(7 downto 0)
); end naughty_boy_effect4;

architecture struct of naughty_boy_effect4 is

 signal u_c1    : unsigned(15 downto 0) := (others => '0');
  
begin

-- Commande1 (A6)
-- R1 = 330, R2 = 10k, C=10e-6 SR=12MHz
-- Charge   : VF1 = 59507  k1 =   34 (R1)
-- Decharge : VF2 =     0  k2 = 1031 (R2)
-- Div = 2^8

process (clk12)
	variable cnt  : unsigned(15 downto 0) := (others => '0');
begin
if rising_edge(clk12) then
	cnt  := cnt + 1;
	if trigger_A6 = '1' then
		if cnt > 34 then
			cnt := (others => '0');
			u_c1 <= u_c1 + (59507 - u_c1)/256;
		end if;
	else
		if cnt > 1031 then
			cnt := (others => '0');
			u_c1 <= u_c1 - (u_c1 - 0)/256; 
		end if; 
	end if;
end if;
end process;

-- chop u_C3 voltage with noise
snd_A6 <= std_logic_vector(u_c1(15 downto 8)) when noise = '1' else  (others => '0');

-- chop trigger A7 with noise
snd_A7 <= (others => '1') when trigger_A7 ='1' and noise = '1' else  (others => '0');
 
end struct;