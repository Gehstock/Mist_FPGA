library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity PROM7_DST is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(4 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of PROM7_DST is
	type rom is array(0 to  31) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"00",X"07",X"66",X"EF",X"00",X"F8",X"EA",X"6F",X"00",X"3F",X"00",X"C9",X"38",X"AA",X"AF",X"F6",
		X"00",X"07",X"66",X"EF",X"00",X"F8",X"EA",X"6F",X"00",X"3F",X"00",X"C9",X"38",X"AA",X"AF",X"F6");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
