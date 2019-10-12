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
		X"00",X"6D",X"07",X"3F",X"00",X"29",X"07",X"39",X"00",X"92",X"07",X"DB",X"00",X"0E",X"07",X"2F",
		X"00",X"C9",X"07",X"F0",X"00",X"A4",X"07",X"FF",X"00",X"84",X"07",X"C7",X"00",X"4B",X"07",X"5F");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
