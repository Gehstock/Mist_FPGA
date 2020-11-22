library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity pal_g is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(7 downto 0);
	data : out std_logic_vector(3 downto 0)
);
end entity;

architecture prom of pal_g is
	type rom is array(0 to  255) of std_logic_vector(3 downto 0);
	signal rom_data: rom := (
		X"0",X"4",X"6",X"8",X"A",X"C",X"1",X"7",X"3",X"1",X"3",X"5",X"8",X"A",X"E",X"D",
		X"0",X"3",X"5",X"7",X"9",X"A",X"1",X"7",X"3",X"1",X"3",X"5",X"8",X"A",X"C",X"D",
		X"0",X"2",X"4",X"7",X"9",X"A",X"1",X"7",X"3",X"1",X"3",X"5",X"7",X"9",X"A",X"D",
		X"0",X"2",X"4",X"7",X"8",X"9",X"1",X"7",X"3",X"1",X"3",X"5",X"7",X"8",X"8",X"D",
		X"0",X"3",X"A",X"7",X"9",X"C",X"1",X"7",X"3",X"1",X"2",X"B",X"6",X"8",X"D",X"D",
		X"0",X"2",X"6",X"6",X"8",X"C",X"1",X"7",X"3",X"1",X"2",X"C",X"5",X"7",X"D",X"D",
		X"0",X"4",X"6",X"8",X"A",X"C",X"1",X"7",X"3",X"1",X"3",X"5",X"7",X"9",X"D",X"D",
		X"0",X"4",X"6",X"8",X"A",X"C",X"1",X"7",X"3",X"1",X"3",X"5",X"7",X"9",X"D",X"D",
		X"0",X"9",X"7",X"5",X"3",X"0",X"0",X"0",X"9",X"3",X"9",X"6",X"5",X"3",X"7",X"D",
		X"0",X"7",X"6",X"4",X"2",X"0",X"0",X"0",X"7",X"1",X"7",X"5",X"3",X"1",X"7",X"D",
		X"0",X"5",X"4",X"2",X"1",X"1",X"1",X"1",X"B",X"B",X"6",X"4",X"2",X"1",X"7",X"D",
		X"0",X"6",X"4",X"2",X"1",X"1",X"0",X"1",X"B",X"B",X"4",X"3",X"2",X"1",X"7",X"D",
		X"0",X"0",X"0",X"B",X"F",X"0",X"0",X"3",X"3",X"3",X"3",X"2",X"1",X"0",X"7",X"D",
		X"0",X"0",X"F",X"C",X"F",X"0",X"0",X"4",X"4",X"4",X"2",X"1",X"0",X"0",X"7",X"D",
		X"0",X"D",X"B",X"A",X"E",X"A",X"0",X"0",X"0",X"0",X"5",X"C",X"E",X"D",X"9",X"0",
		X"0",X"D",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"3",X"0",X"0",X"0",X"0",X"0",X"0");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
