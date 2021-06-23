library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity N7 is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(7 downto 0);
	data : out std_logic_vector(3 downto 0)
);
end entity;

architecture prom of N7 is
	type rom is array(0 to  255) of std_logic_vector(3 downto 0);
	signal rom_data: rom := (
		X"0",X"3",X"2",X"7",X"4",X"4",X"4",X"4",X"3",X"3",X"3",X"3",X"6",X"6",X"6",X"6",
		X"0",X"5",X"1",X"7",X"4",X"4",X"4",X"4",X"5",X"5",X"5",X"5",X"6",X"6",X"6",X"6",
		X"0",X"2",X"5",X"7",X"4",X"4",X"4",X"4",X"2",X"2",X"2",X"2",X"6",X"6",X"6",X"6",
		X"0",X"1",X"3",X"7",X"4",X"4",X"4",X"4",X"1",X"1",X"1",X"1",X"6",X"6",X"6",X"6",
		X"0",X"4",X"2",X"6",X"4",X"4",X"4",X"4",X"2",X"2",X"2",X"2",X"6",X"6",X"6",X"6",
		X"0",X"4",X"2",X"6",X"4",X"4",X"4",X"4",X"2",X"2",X"2",X"2",X"6",X"6",X"6",X"6",
		X"0",X"4",X"2",X"6",X"4",X"4",X"4",X"4",X"2",X"2",X"2",X"2",X"6",X"6",X"6",X"6",
		X"0",X"4",X"2",X"6",X"4",X"4",X"4",X"4",X"2",X"2",X"2",X"2",X"6",X"6",X"6",X"6",
		X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",
		X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",
		X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",
		X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",
		X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",
		X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",
		X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",
		X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
