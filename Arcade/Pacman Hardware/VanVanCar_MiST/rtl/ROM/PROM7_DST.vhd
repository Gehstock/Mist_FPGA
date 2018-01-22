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
		X"00",X"C0",X"38",X"07",X"87",X"3F",X"F0",X"FF",X"27",X"14",X"1C",X"80",X"A4",X"01",X"AE",X"28");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
