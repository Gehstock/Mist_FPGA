---------------------------------------------------------------------------------
-- Naughty Boy sound effect3 (noise) by Dar (darfpga@aol.fr) (April 2016)
-- http://darfpga.blogspot.fr
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;

entity naughty_boy_noise is
port(
 clk12    : in std_logic;
 trigger  : in std_logic;
 noise    : out std_logic
); end naughty_boy_noise;

architecture struct of naughty_boy_noise is

signal u_c1      : unsigned(15 downto 0) := (others => '0');
signal flip1     : std_logic := '0';
signal flip1_r   : std_logic := '0';
signal u_ctrl    : unsigned(15 downto 0) := (others => '0');
signal shift_reg : std_logic_vector(17 downto 0) := (others => '0');
 
begin

-- control voltage from LS136 (open collector)

-- when trigger = '0', ouput LS136 H (Z): 2K open
--
--               u_ctrl = 2/3*VCC (0xAAAA)
--                  | 
--   VCC |---[ 5k ]-|-[ 5k ]---[ 5k ]---|GND
--                           

-- when trigger = '1', output LS136 L : 2K // (5K+5K) to GND 
-- 
--                u_ctrl = 0.25*VCC (0x4000)
--                  | 
--   VCC |---[ 5k ]-|-[ 5k ]---[ 5k ]---|GND
--                  |-[ 2K ]------------|


u_ctrl <=  x"AAAA" when trigger = '0' else x"4000";

-- Oscillateur
-- R1 = 200k, R2 = 1k, C=0.01e-6, SR=12MHz
-- Charge   : VF1 = 65536, k1 = 1508 (R1+R2, C)
-- Decharge : VF2 =  2621, k2 =    8 (R2, C)
-- Div = 2^4

process (clk12)
 variable cnt  : unsigned(15 downto 0) := (others => '0');
begin
	if rising_edge(clk12) then
		if u_c1 > u_ctrl   then flip1 <= '0'; end if;
		if u_c1 < u_ctrl/2 then flip1 <= '1'; end if; 
		cnt  := cnt + 1;
		if flip1 = '1' then
			if cnt > 1508 then
				cnt := (others => '0');
				u_c1 <= u_c1 + (65535 - u_c1)/16;
			end if;
		else
			if cnt > 8 then
				cnt := (others => '0');
				u_c1 <= u_c1 - (u_c1 - 2621)/16; 
			end if; 
		end if;
	end if;
end process;

-- noise generator triggered by oscillator output
process (clk12)
begin
	if rising_edge(clk12) then
		flip1_r <= flip1;
		if flip1_r = '0' and flip1 ='1' then
			shift_reg <= shift_reg(16 downto 0) & not(shift_reg(17) xor shift_reg(16));
		end if;
	end if;
end process;

noise <= not(shift_reg(17) xor shift_reg(16));
 
end struct;
