library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity silverland_palette is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(5 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of silverland_palette is
	type rom is array(0 to  63) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (	
		X"F6",X"E0",X"07",X"07",X"00",X"F4",X"01",X"01",X"F6",X"C7",X"00",X"00",X"00",X"6F",X"00",X"6F",
		X"00",X"3F",X"00",X"3F",X"00",X"A7",X"00",X"A7",X"F6",X"E0",X"FF",X"E0",X"00",X"FF",X"00",X"FF",
		X"00",X"00",X"9C",X"7E",X"F6",X"00",X"9C",X"07",X"00",X"00",X"00",X"00",X"00",X"FF",X"BE",X"00",
		X"00",X"00",X"FF",X"07",X"00",X"87",X"87",X"00",X"F6",X"38",X"A7",X"1A",X"00",X"FA",X"FA",X"07");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
