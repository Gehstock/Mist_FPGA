library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity ROM_LUT is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(4 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of ROM_LUT is
	type rom is array(0 to  31) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"00",X"1C",X"36",X"05",X"00",X"79",X"A7",X"07",X"00",X"5B",X"F8",X"27",X"00",X"A5",X"07",X"3F",
		X"00",X"FF",X"87",X"38",X"00",X"27",X"FF",X"C1",X"00",X"1B",X"3F",X"80",X"00",X"18",X"1F",X"86");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
