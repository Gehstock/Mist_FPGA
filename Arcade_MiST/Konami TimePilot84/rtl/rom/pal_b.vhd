library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity pal_b is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(7 downto 0);
	data : out std_logic_vector(3 downto 0)
);
end entity;

architecture prom of pal_b is
	type rom is array(0 to  255) of std_logic_vector(3 downto 0);
	signal rom_data: rom := (
		X"0",X"6",X"8",X"A",X"C",X"E",X"1",X"3",X"2",X"1",X"2",X"3",X"4",X"5",X"6",X"D",
		X"0",X"5",X"7",X"9",X"A",X"C",X"1",X"3",X"2",X"1",X"2",X"3",X"4",X"5",X"6",X"D",
		X"0",X"5",X"6",X"9",X"A",X"C",X"1",X"3",X"2",X"1",X"1",X"2",X"4",X"5",X"6",X"D",
		X"0",X"5",X"6",X"9",X"9",X"B",X"1",X"3",X"2",X"1",X"1",X"2",X"4",X"4",X"4",X"D",
		X"0",X"5",X"D",X"9",X"B",X"E",X"1",X"3",X"2",X"1",X"1",X"9",X"3",X"4",X"6",X"D",
		X"0",X"4",X"B",X"8",X"A",X"E",X"1",X"3",X"2",X"1",X"1",X"A",X"2",X"3",X"6",X"D",
		X"0",X"6",X"8",X"A",X"C",X"E",X"1",X"3",X"2",X"1",X"2",X"3",X"4",X"5",X"6",X"D",
		X"0",X"6",X"8",X"A",X"C",X"E",X"1",X"3",X"2",X"1",X"2",X"3",X"4",X"5",X"6",X"D",
		X"0",X"0",X"0",X"0",X"0",X"A",X"7",X"5",X"9",X"3",X"9",X"6",X"5",X"3",X"0",X"D",
		X"0",X"0",X"0",X"0",X"0",X"9",X"5",X"3",X"5",X"1",X"5",X"4",X"3",X"1",X"0",X"D",
		X"0",X"0",X"2",X"2",X"1",X"5",X"4",X"3",X"7",X"7",X"6",X"3",X"3",X"2",X"0",X"D",
		X"0",X"0",X"3",X"4",X"4",X"5",X"4",X"3",X"7",X"7",X"7",X"4",X"3",X"2",X"0",X"D",
		X"0",X"F",X"0",X"7",X"F",X"5",X"4",X"6",X"6",X"6",X"8",X"5",X"4",X"3",X"0",X"D",
		X"0",X"F",X"6",X"8",X"F",X"4",X"3",X"6",X"6",X"6",X"7",X"4",X"3",X"4",X"0",X"D",
		X"0",X"D",X"B",X"A",X"3",X"3",X"5",X"D",X"D",X"0",X"0",X"0",X"0",X"8",X"D",X"A",
		X"0",X"D",X"0",X"0",X"0",X"0",X"0",X"D",X"0",X"0",X"0",X"4",X"6",X"8",X"B",X"0");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
