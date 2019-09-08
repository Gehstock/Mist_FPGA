library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity guzzler_palette1 is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(7 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of guzzler_palette1 is
	type rom is array(0 to  255) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"00",X"00",X"0F",X"08",X"0F",X"0C",X"02",X"0F",X"00",X"00",X"00",X"03",X"0F",X"08",X"0F",X"02",
		X"00",X"00",X"00",X"0C",X"03",X"0F",X"00",X"0C",X"00",X"00",X"00",X"0F",X"0F",X"0F",X"00",X"03",
		X"00",X"0C",X"02",X"03",X"0F",X"0F",X"00",X"03",X"00",X"0C",X"00",X"0B",X"0F",X"0F",X"00",X"08",
		X"00",X"0C",X"0C",X"00",X"0F",X"0F",X"00",X"02",X"00",X"00",X"03",X"0C",X"00",X"0C",X"00",X"0F",
		X"00",X"00",X"00",X"03",X"03",X"03",X"03",X"0F",X"00",X"00",X"03",X"08",X"03",X"0C",X"00",X"0F",
		X"00",X"00",X"00",X"08",X"0B",X"03",X"03",X"0F",X"00",X"03",X"0F",X"03",X"02",X"0F",X"0F",X"00",
		X"00",X"0B",X"0F",X"0B",X"00",X"0F",X"0F",X"0C",X"00",X"0F",X"0F",X"03",X"00",X"0F",X"0F",X"03",
		X"00",X"0C",X"0F",X"08",X"0F",X"0C",X"02",X"0F",X"00",X"02",X"00",X"08",X"0F",X"03",X"03",X"0F",
		X"00",X"00",X"0F",X"08",X"0F",X"0C",X"02",X"0F",X"00",X"00",X"00",X"03",X"0F",X"08",X"0F",X"02",
		X"00",X"00",X"00",X"0C",X"03",X"0F",X"00",X"0C",X"00",X"00",X"00",X"0F",X"0F",X"0F",X"00",X"03",
		X"00",X"00",X"02",X"03",X"0F",X"0F",X"00",X"03",X"00",X"00",X"00",X"0B",X"0F",X"0F",X"00",X"08",
		X"00",X"00",X"0C",X"00",X"0F",X"0F",X"00",X"02",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"0C",X"0F",X"02",X"00",X"0F",X"0F",X"0F",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"03",X"00",X"0F",X"03",X"02",X"02",X"02",X"02",X"0F",
		X"00",X"00",X"00",X"00",X"00",X"00",X"0C",X"0F",X"00",X"02",X"00",X"08",X"0B",X"03",X"03",X"0F");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
