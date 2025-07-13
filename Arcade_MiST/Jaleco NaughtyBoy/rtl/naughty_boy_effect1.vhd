---------------------------------------------------------------------------------
-- Naughty Boy sound effect1 by Dar (darfpga@aol.fr) (April 2025)
-- http://darfpga.blogspot.fr
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;

entity naughty_boy_effect1 is
port(
	clk12       : in std_logic;
	trigger_B54 : in std_logic_vector(1 downto 0);
	snd         : out std_logic_vector(1 downto 0)
); end naughty_boy_effect1;

architecture struct of naughty_boy_effect1 is

signal clk_div  : std_logic_vector(2 downto 0) := (others => '0');
signal ena_1p5M : std_logic;

signal u_c1  : unsigned(15 downto 0) := (others => '0');
signal u_c2  : unsigned(15 downto 0) := (others => '0');
signal u_c3  : unsigned(15 downto 0) := (others => '0');
signal flip1 : std_logic := '0';
signal flip2 : std_logic := '0';
 
begin

-- Commande
-- R1 = 10k, C=10e-6 SR=1.5MHz
-- Charge   : VF1 = 65536, k1 = 1172 (R1)
-- Decharge : VF2 =  2321, k2 = 1172 (R1)
-- Div = 2^7

process (clk12)
 variable cnt  : unsigned(15 downto 0) := (others => '0');
begin
 if rising_edge(clk12) then
		clk_div <= clk_div + 1;
		ena_1p5M <= '0';		
		if clk_div = "111" then
			clk_div <= (others => '0');
			ena_1p5M <= '1';
		end if;
 end if;
end process;


process (clk12)
	variable cnt  : unsigned(12 downto 0) := (others => '0');
begin
	if rising_edge(clk12) then
		if ena_1p5M = '1' then
			cnt  := cnt + 1;
			if trigger_B54(0) = '1' then
				if cnt > 1172 then
					cnt := (others => '0');
					u_c1 <= u_c1 + (65535 - u_c1)/128;
				end if;
			else
				if cnt > 1172 then
					cnt := (others => '0');
					u_c1 <= u_c1 - (u_c1 - 2321)/128; 
				end if; 
			end if;
		end if;
	end if;
end process;

-- Oscillateur 1 
-- R1 = 10k, R2 = 200k, C=0.01e-6 SR=12MHz
-- Charge   : VF1 = 65535, k1 = 197 (R1+R2)
-- Decharge : VF2 =  2621, k2 = 188 (R2)
-- Div = 2^7

process (clK12)
 variable cnt  : unsigned(7 downto 0) := (others => '0');
begin
	if rising_edge(clk12) then
		if trigger_B54(1) = '0' then
			cnt  := (others => '0');
			u_c2 <= (others => '0');
			flip1 <= '0';
		else
			if u_c2 > u_c1   then flip1 <= '0'; end if;
			if u_c2 < u_c1/2 then flip1 <= '1'; end if; 
			cnt  := cnt + 1;
			if flip1 = '1' then
				if cnt > 197 then
					cnt := (others => '0');
					u_c2 <= u_c2 + (65535 - u_c2)/128;
				end if;
			else
				if cnt > 188 then
					cnt := (others => '0');
					u_c2 <= u_c2 - (u_c2 - 2621)/128; 
				end if; 
			end if;
		end if;
	end if;
end process;

-- Oscillateur 2
-- R1 = 47k, R2 = 200k, C=0.01e-6 SR=12MHz
-- Charge   : VF1 = 65535, k1 = 232 (R1+R2)
-- Decharge : VF2 =  2621, k2 = 188 (R2)
-- Div = 2^7

process (clK12)
 variable cnt  : unsigned(7 downto 0) := (others => '0');
begin
	if rising_edge(clk12) then
		if trigger_B54(1) = '0' then
			cnt  := (others => '0');
			u_c3 <= (others => '0');
			flip2 <= '0';
		else
			if u_c3 > u_c1   then flip2 <= '0'; end if;
			if u_c3 < u_c1/2 then flip2 <= '1'; end if; 
			cnt  := cnt + 1;
			if flip2 = '1' then
				if cnt > 232 then
					cnt := (others => '0');
					u_c3 <= u_c3 + (65535 - u_c3)/128;
				end if;
			else
				if cnt > 188 then
					cnt := (others => '0');
					u_c3 <= u_c3 - (u_c3 - 2621)/128; 
				end if; 
			end if;
		end if;
	end if;
end process;
 
snd <= ('0'&flip1)+('0'&flip2);
 
end struct;

