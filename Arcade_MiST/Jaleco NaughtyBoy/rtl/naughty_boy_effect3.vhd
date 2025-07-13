---------------------------------------------------------------------------------
-- Naughty boy sound effect3 by Dar (darfpga@aol.fr) (April 2025)
-- http://darfpga.blogspot.fr
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;

entity naughty_boy_effect3 is
port(
 clk12      : in std_logic;
 trigger_C4 : in std_logic;
 trigger_C5 : in std_logic;
 trigger_A5 : in std_logic;
 noise      : in std_logic;
 snd_C5     : out std_logic_vector(7 downto 0);
 snd_A5     : out std_logic_vector(7 downto 0)
); end naughty_boy_effect3;

architecture struct of naughty_boy_effect3 is

 signal u_c1    : unsigned(15 downto 0) := (others => '0');
 
 signal u_c2    : unsigned(15 downto 0) := (others => '0');
 signal u_ctrl2 : unsigned(15 downto 0) := (others => '0');
 signal flip2   : std_logic := '0';
 
 signal u_c3    : unsigned(15 downto 0) := (others => '0');
 signal u_c4    : unsigned(15 downto 0) := (others => '0');

 signal clk_div : std_logic_vector(7 downto 0) := (others => '0');
 signal ena_47k : std_logic;
 
begin

-- Commande1 (C4)
-- R1 = 3k, R2 = 2k, C=10e-6 SR=12MHz
-- Charge   : VF1 = 65536  k1 = 2344 (R1+R2)
-- Decharge : VF2 =  8651, k2 =  938 (R2)
-- Div = 2^8

process (clk12)
	variable cnt  : unsigned(15 downto 0) := (others => '0');
begin
if rising_edge(clk12) then
	cnt  := cnt + 1;
	if trigger_C4 = '1' then
		if cnt > 2344 then
			cnt := (others => '0');
			u_c1 <= u_c1 + (65535 - u_c1)/256;
		end if;
	else
		if cnt > 938 then
			cnt := (others => '0');
			u_c1 <= u_c1 - (u_c1 - 8651)/256; 
		end if; 
	end if;
end if;
end process;

-- Oscillateur
-- R1 = 33k, R2 = 100k, C=0.0047e-6, SR=12MHz
-- Charge   : VF1 = 65536, k1 = 469 (R1+R2, C)
-- Decharge : VF2 =  2621, k2 = 353 (R2, C)
-- Div = 2^4

u_ctrl2 <= u_c1/2 when noise = '0' else u_c1/2 + 65536/4;

process (clk12)
	variable cnt  : unsigned(15 downto 0) := (others => '0');
begin
if rising_edge(clk12) then
	if u_c2 > u_ctrl2   then flip2 <= '0'; end if;
	if u_c2 < u_ctrl2/2 then flip2 <= '1'; end if; 
	cnt  := cnt + 1;
	if flip2 = '1' then
		if cnt > 469 then
			cnt := (others => '0');
			u_c2 <= u_c2 + (65535 - u_c2)/16;
		end if;
	else
		if cnt > 353 then
			cnt := (others => '0');
			u_c2 <= u_c2 - (u_c2 - 2621)/16; 
		end if; 
	end if;
end if;
end process;


---- Commande2 (A5)
---- R1 = 330k, R2 = 220k,  C=10e-6 SR=0.046875MHz (12MHz/256)
---- Charge   : VF1 = 29753, k1 = 604 (R1)
---- Decharge : VF2 =     0, k2 = 403 (R2)
---- Div = 2^8

process (clk12)
 variable cnt  : unsigned(15 downto 0) := (others => '0');
begin
 if rising_edge(clk12) then
		clk_div <= clk_div + 1;
		ena_47k <= '0';		
		if clk_div = x"FF" then
			clk_div <= (others => '0');
			ena_47k <= '1';
		end if;
 end if;
end process;

process (clk12)
 variable cnt  : unsigned(15 downto 0) := (others => '0');
begin
if rising_edge(clk12) then
	if ena_47k = '1' then
		cnt  := cnt + 1;
		if trigger_A5 = '1' then
			if cnt > 604 then
				cnt := (others => '0');
				u_c3 <= u_c3 + (29753 - u_c3)/256;
			end if;
		else
			if cnt > 403 then
				cnt := (others => '0');
				u_c3 <= u_c3 - (u_c3 - 0)/256; 
			end if; 
		end if;
	end if;
end if;
end process;

-- chop u_C3 voltage with ocillator output
snd_A5 <= std_logic_vector(u_c3(15 downto 8)) when flip2 = '1' else  (others => '0');

---- Commande3 (C5)
---- R1 = 330, R2 = 330,  C=10e-6 SR=12MHz
---- Charge   : VF1 = 65536, k1 =  155 (R1)
---- Decharge : VF2 =     0, k2 = 4688 (R2)
---- Div = 2^8

process (clk12)
 variable cnt  : unsigned(15 downto 0) := (others => '0');
begin
if rising_edge(clk12) then
	cnt  := cnt + 1;
	if trigger_C5 = '1' then
		if cnt > 155 then
			cnt := (others => '0');
			u_c4 <= u_c4 + (65535 - u_c4)/256;
		end if;
	else
		if cnt > 4688 then
			cnt := (others => '0');
			u_c4 <= u_c4 - (u_c4 - 0)/256; 
		end if; 
	end if;
end if;
end process;

-- chop u_C4 voltage with ocillator output
snd_C5 <= std_logic_vector(u_c4(15 downto 8)) when flip2 = '1' else  (others => '0');
 
end struct;