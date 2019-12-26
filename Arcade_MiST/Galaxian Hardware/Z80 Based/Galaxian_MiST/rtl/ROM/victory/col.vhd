library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity VICTORY_6L is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(4 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of VICTORY_6L is
	type rom is array(0 to  31) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"00",X"07",X"15",X"E4",X"00",X"BC",X"6C",X"6C",X"00",X"38",X"00",X"A7",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"07",X"00",X"07",X"5B",X"40",X"00",X"00",X"00",X"00",X"00",X"3F",X"18",X"FF");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
