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
		X"00",X"3F",X"07",X"EF",X"F8",X"6F",X"38",X"C9",X"AF",X"AA",X"20",X"D5",X"BF",X"5D",X"ED",X"F6");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
