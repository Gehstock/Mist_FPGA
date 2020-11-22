library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity pal_r is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(7 downto 0);
	data : out std_logic_vector(3 downto 0)
);
end entity;

architecture prom of pal_r is
	type rom is array(0 to  255) of std_logic_vector(3 downto 0);
	signal rom_data: rom := (
		X"0",X"2",X"4",X"6",X"8",X"A",X"1",X"F",X"B",X"5",X"3",X"5",X"7",X"9",X"B",X"D",
		X"0",X"2",X"3",X"6",X"A",X"C",X"1",X"F",X"B",X"5",X"3",X"5",X"7",X"A",X"C",X"D",
		X"0",X"1",X"3",X"5",X"B",X"D",X"1",X"F",X"B",X"5",X"2",X"4",X"6",X"9",X"E",X"D",
		X"0",X"1",X"3",X"5",X"C",X"E",X"1",X"F",X"B",X"5",X"2",X"4",X"6",X"9",X"E",X"D",
		X"0",X"1",X"A",X"5",X"7",X"A",X"1",X"F",X"B",X"5",X"2",X"A",X"5",X"7",X"A",X"D",
		X"0",X"1",X"B",X"4",X"6",X"A",X"1",X"F",X"B",X"5",X"2",X"B",X"4",X"6",X"A",X"D",
		X"0",X"2",X"4",X"6",X"8",X"A",X"1",X"F",X"B",X"5",X"3",X"5",X"6",X"8",X"A",X"D",
		X"0",X"2",X"4",X"6",X"8",X"A",X"1",X"F",X"B",X"5",X"3",X"5",X"6",X"8",X"A",X"D",
		X"0",X"B",X"9",X"6",X"4",X"4",X"2",X"1",X"9",X"3",X"9",X"6",X"5",X"3",X"F",X"D",
		X"0",X"C",X"A",X"6",X"4",X"4",X"2",X"1",X"A",X"3",X"A",X"6",X"5",X"3",X"F",X"D",
		X"0",X"B",X"A",X"6",X"4",X"4",X"2",X"1",X"0",X"0",X"A",X"6",X"5",X"3",X"F",X"D",
		X"0",X"9",X"8",X"5",X"3",X"3",X"2",X"1",X"0",X"0",X"9",X"5",X"4",X"3",X"F",X"D",
		X"0",X"C",X"0",X"0",X"7",X"1",X"2",X"6",X"5",X"4",X"6",X"3",X"2",X"2",X"F",X"D",
		X"0",X"F",X"F",X"0",X"7",X"1",X"1",X"6",X"5",X"4",X"5",X"2",X"2",X"5",X"F",X"D",
		X"0",X"D",X"B",X"A",X"F",X"A",X"1",X"9",X"9",X"A",X"E",X"C",X"7",X"0",X"0",X"C",
		X"0",X"D",X"0",X"0",X"0",X"0",X"0",X"9",X"0",X"B",X"0",X"1",X"3",X"5",X"7",X"0");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
