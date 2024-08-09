library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity cont_table is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(7 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of cont_table is
	type rom is array(0 to  63) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"3f", X"3e", X"3c", X"3d", X"39", X"38", X"3a", X"3b",
		X"33", X"32", X"30", X"31", X"35", X"34", X"36", X"37",
		X"27", X"26", X"24", X"25", X"21", X"20", X"22", X"23",
		X"2b", X"2a", X"28", X"29", X"2d", X"2c", X"2e", X"2f",
		X"0f", X"0e", X"0c", X"0d", X"09", X"08", X"0a", X"0b",
		X"03", X"02", X"00", X"01", X"05", X"04", X"06", X"07",
		X"17", X"16", X"14", X"15", X"11", X"10", X"12", X"13",
		X"1b", X"1a", X"18", X"19", X"1d", X"1c", X"1e", X"1f");
	
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;