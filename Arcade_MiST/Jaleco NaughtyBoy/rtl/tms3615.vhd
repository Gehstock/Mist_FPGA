---------------------------------------------------------------------------------
-- TMS3615 by Dar (darfpga@aol.fr) (April 2025)
-- http://darfpga.blogspot.fr
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;

entity tms3615 is
port(
	clk_sys  : in std_logic;
	clk_snd  : in std_logic; 
	trigger  : in std_logic_vector(12 downto 0);
	
	audio    : out std_logic_vector(11 downto 0)
	
); end tms3615;

architecture struct of tms3615 is

type ton_array is array(0 to 12) of integer range 956 downto 478;
constant tons : ton_array := (956,902,852,804,758,716,676,638,602,568,536,506,478);

type cnt_array is array(0 to 12) of std_logic_vector(9 downto 0);
signal cnts : cnt_array := (others => (others => '0'));

signal freqs : std_logic_vector(12 downto 0) := "0000000000000";

type amp_array is array(0 to 12) of unsigned(6 downto 0);
signal amps : amp_array := (others => (others => '0'));

type level_array is array(0 to 12) of signed(11 downto 0);
signal levels : level_array := (others => (others => '0'));

type decay_array is array(0 to 12) of std_logic_vector(15 downto 0);
signal decays : decay_array := (others => (others => '0'));

signal trigger_r : std_logic_vector(12 downto 0);
signal clk_snd_r : std_logic;
signal clk_ena   : std_logic;

signal sum     : signed(11 downto 0) := (others=>'0');
signal sum_lim : signed(11 downto 0) := (others=>'0');

begin


process (clk_sys)
begin
	if rising_edge(clk_sys) then
		clk_snd_r <= clk_snd;
		clk_ena <= '0';
		if clk_snd = '1' and clk_snd_r = '0' then
			clk_ena <= '1';
		end if;
	end if;
end process;

voices : for kv in 0 to 11 generate
process (clk_sys)
begin
	if rising_edge(clk_sys) then
	
		trigger_r(kv) <= trigger(kv);
	
		if clk_ena = '1' then
		
			cnts(kv) <= cnts(kv) + 1;
			if cnts(kv) = std_logic_vector(to_unsigned(tons(kv),10)) then
				cnts(kv) <= (others => '0');
				freqs(kv) <= not freqs(kv);
			end if;
			
		end if;
		
		if trigger(kv) = '1' then
			amps(kv) <= (others => '1');
			decays(kv) <= (others => '0');
		else			
			if amps(kv) > 0 then
				decays(kv) <= decays(kv) + 1;
				if decays(kv) = x"4000" then
					decays(kv) <= (others => '0');
					amps(kv) <= amps(kv) - (amps(kv) srl 3);  -- Exponential decay: A = A - (A >> 3)
				end if;
			end if;
		end if;
		
		if freqs(kv) = '1' then
			levels(kv) <=  to_signed(to_integer(amps(kv)),12);
		else
			levels(kv) <= -to_signed(to_integer(amps(kv)),12);
		end if;
		
	end if;
end process;
end generate;
 
sum <=  ( levels(0) + levels(1) + levels( 2) + levels( 3) +
			 levels(4) + levels(5) + levels( 6) + levels( 7) +
			 levels(8) + levels(9) + levels(10) + levels(11) ) / 8 ;

sum_lim <= to_signed( 511,12) when sum > to_signed( 511,12) 
		else to_signed(-511,12) when sum < to_signed(-511,12) 
		else sum;

audio <= std_logic_vector(sum_lim)+std_logic_vector(to_unsigned(512,12));
 
end struct;