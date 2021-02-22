library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity time_pilot_palette_green_red is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(4 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of time_pilot_palette_green_red is
	type rom is array(0 to  31) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"00",X"3E",X"3E",X"80",X"FE",X"00",X"AC",X"EE",X"AC",X"C0",X"14",X"00",X"28",X"38",X"16",X"BC",
		X"00",X"3E",X"00",X"C0",X"FE",X"C0",X"3E",X"80",X"3E",X"F6",X"00",X"80",X"80",X"00",X"0C",X"BC");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
