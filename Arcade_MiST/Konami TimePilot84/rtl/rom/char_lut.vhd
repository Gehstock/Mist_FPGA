library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity char_lut is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(7 downto 0);
	data : out std_logic_vector(3 downto 0)
);
end entity;

architecture prom of char_lut is
	type rom is array(0 to  255) of std_logic_vector(3 downto 0);
	signal rom_data: rom := (
		X"0",X"2",X"3",X"4",X"1",X"2",X"3",X"4",X"5",X"6",X"3",X"4",X"A",X"B",X"D",X"0",
		X"A",X"B",X"D",X"C",X"0",X"B",X"D",X"C",X"D",X"B",X"D",X"9",X"A",X"B",X"D",X"E",
		X"A",X"C",X"3",X"4",X"A",X"B",X"D",X"8",X"0",X"B",X"D",X"9",X"A",X"B",X"C",X"E",
		X"A",X"B",X"D",X"0",X"A",X"B",X"B",X"B",X"5",X"6",X"7",X"0",X"F",X"0",X"0",X"E",
		X"9",X"5",X"B",X"6",X"4",X"6",X"0",X"9",X"9",X"1",X"B",X"6",X"9",X"5",X"2",X"6",
		X"9",X"1",X"2",X"6",X"2",X"9",X"0",X"6",X"9",X"3",X"2",X"6",X"9",X"3",X"0",X"6",
		X"9",X"3",X"0",X"2",X"9",X"5",X"0",X"6",X"B",X"9",X"0",X"6",X"C",X"0",X"0",X"F",
		X"D",X"4",X"0",X"1",X"E",X"0",X"0",X"8",X"7",X"0",X"0",X"A",X"1",X"6",X"0",X"9",
		X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
		X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
		X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
		X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"F",X"0",X"0",X"E",
		X"0",X"B",X"C",X"0",X"A",X"B",X"C",X"0",X"5",X"6",X"C",X"0",X"A",X"B",X"D",X"0",
		X"A",X"B",X"D",X"C",X"0",X"B",X"D",X"C",X"2",X"B",X"D",X"4",X"A",X"B",X"D",X"E",
		X"A",X"C",X"C",X"0",X"A",X"B",X"D",X"3",X"0",X"B",X"D",X"3",X"A",X"B",X"C",X"E",
		X"A",X"B",X"D",X"1",X"A",X"9",X"8",X"7",X"5",X"6",X"0",X"0",X"F",X"0",X"0",X"E");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
