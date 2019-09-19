library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity nrx_pal_rom is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(4 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of nrx_pal_rom is
	type rom is array(0 to  31) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"00",X"00",X"06",X"3F",X"5A",X"F1",X"15",X"18",X"66",X"D1",X"2A",X"03",X"A4",X"91",X"BF",X"F6",
		X"00",X"07",X"F6",X"00",X"00",X"07",X"F6",X"00",X"00",X"07",X"F6",X"00",X"00",X"07",X"F6",X"F6");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
