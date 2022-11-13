library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity exerion_i8 is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(7 downto 0);
	data : out std_logic_vector(3 downto 0)
);
end entity;

architecture prom of exerion_i8 is
	type rom is array(0 to  255) of std_logic_vector(3 downto 0);
	signal rom_data: rom := (
		X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
		X"3",X"3",X"A",X"A",X"5",X"5",X"D",X"D",X"9",X"9",X"9",X"9",X"9",X"9",X"9",X"9",
		X"F",X"F",X"1",X"1",X"D",X"D",X"9",X"9",X"1",X"1",X"1",X"1",X"1",X"1",X"1",X"1",
		X"6",X"6",X"7",X"7",X"1",X"1",X"F",X"F",X"3",X"3",X"3",X"3",X"3",X"3",X"3",X"3",
		X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
		X"3",X"3",X"A",X"A",X"5",X"5",X"3",X"3",X"7",X"7",X"7",X"7",X"7",X"7",X"7",X"7",
		X"F",X"F",X"1",X"1",X"D",X"D",X"0",X"0",X"F",X"F",X"F",X"F",X"F",X"F",X"F",X"F",
		X"6",X"6",X"7",X"7",X"1",X"1",X"E",X"E",X"D",X"D",X"D",X"D",X"D",X"D",X"D",X"D",
		X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
		X"3",X"3",X"A",X"A",X"5",X"5",X"0",X"F",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
		X"F",X"F",X"1",X"1",X"D",X"D",X"0",X"F",X"B",X"C",X"1",X"0",X"E",X"E",X"E",X"E",
		X"6",X"6",X"7",X"7",X"1",X"1",X"3",X"D",X"1",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
		X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
		X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
		X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
		X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
