library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity PROM7_DST is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(3 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of PROM7_DST is
	type rom is array(0 to  15) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"00",X"62",X"85",X"2F",X"07",X"1D",X"28",X"8C",X"C7",X"3F",X"F8",X"C9",X"AC",X"18",X"38",X"F6");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
