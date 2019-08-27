---------------------------------------------------------------------------------
-- Silver Land sound AY-3-8910 - Dar - June 2018
---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity silverland_sound is
port	(
	cpu_clock    : in std_logic;
	cpu_addr     : in std_logic_vector(15 downto 0);
	cpu_data     : in std_logic_vector( 7 downto 0);
	cpu_iorq_n   : in std_logic;
	reg4_we_n    : in std_logic;
	reg5_we_n    : in std_logic;
	reg6_we_n    : in std_logic;
	ym_2149_data : out std_logic_vector(7 downto 0);
	sound_sample : out std_logic_vector(7 downto 0)
);
end silverland_sound;

architecture struct of silverland_sound is

signal hdiv         : std_logic_vector(1 downto 0);
signal clock_1_5mhz : std_logic; -- 1.50Mhz

signal ym_2149_audio : std_logic_vector(7 downto 0);


begin

clock_1_5mhz <= hdiv(0);

process(cpu_clock)
begin
	if falling_edge(cpu_clock) then

		if hdiv = "11" then
			hdiv <= "00";
		else
			hdiv <= std_logic_vector(unsigned(hdiv) + 1);
		end if;

	end if;
end process;

ym2149 : entity work.ym2149
port map (
-- data bus
	I_DA            => cpu_data,     --: in  std_logic_vector(7 downto 0);
	O_DA            => ym_2149_data, --: out std_logic_vector(7 downto 0);
	O_DA_OE_L       => open,         --: out std_logic;
-- control
	I_A9_L          => '0', --scs_n,	--: in  std_logic;
	I_A8            =>     cpu_iorq_n or cpu_addr(3),  --: in  std_logic;
	I_BDIR          => not(cpu_iorq_n or cpu_addr(2)), --: in  std_logic;
	I_BC2           => not(cpu_iorq_n or cpu_addr(1)), --: in  std_logic;
	I_BC1           => not(cpu_iorq_n or cpu_addr(0)), --: in  std_logic;
	I_SEL_L         => '1',                            --: in  std_logic;
-- audio
	O_AUDIO         => sound_sample, --: out std_logic_vector(7 downto 0);
-- port a
	I_IOA           => "11111111",    --: in  std_logic_vector(7 downto 0);
	O_IOA           => open,          --: out std_logic_vector(7 downto 0);
	O_IOA_OE_L      => open,          --: out std_logic;
-- port b
	I_IOB           => "11111111",    --: in  std_logic_vector(7 downto 0);
	O_IOB           => open,          --: out std_logic_vector(7 downto 0);
	O_IOB_OE_L      => open,          --: out std_logic;

	ENA             => '1',           --: in  std_logic; -- clock enable for higher speed operation
	RESET_L         => '1',           --: in  std_logic;
	CLK             => clock_1_5mhz   --: in  std_logic  -- note 6 Mhz!
);

end architecture;