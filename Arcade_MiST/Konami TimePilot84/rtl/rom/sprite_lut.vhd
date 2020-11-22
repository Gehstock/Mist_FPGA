library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity sprite_lut is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(7 downto 0);
	data : out std_logic_vector(3 downto 0)
);
end entity;

architecture prom of sprite_lut is
	type rom is array(0 to  255) of std_logic_vector(3 downto 0);
	signal rom_data: rom := (
		X"0",X"1",X"2",X"3",X"4",X"5",X"6",X"7",X"8",X"9",X"A",X"B",X"C",X"D",X"E",X"F",
		X"0",X"0",X"1",X"2",X"3",X"4",X"6",X"9",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"E",
		X"0",X"0",X"0",X"1",X"2",X"3",X"6",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"1",
		X"0",X"1",X"2",X"3",X"4",X"5",X"6",X"6",X"6",X"6",X"0",X"0",X"0",X"0",X"E",X"F",
		X"0",X"1",X"2",X"3",X"4",X"5",X"6",X"9",X"9",X"6",X"0",X"0",X"E",X"F",X"0",X"0",
		X"0",X"1",X"2",X"3",X"4",X"5",X"6",X"8",X"8",X"9",X"E",X"F",X"0",X"0",X"0",X"0",
		X"0",X"6",X"9",X"9",X"6",X"F",X"6",X"7",X"8",X"9",X"A",X"B",X"C",X"D",X"E",X"8",
		X"0",X"9",X"6",X"6",X"0",X"8",X"6",X"7",X"8",X"9",X"A",X"B",X"C",X"D",X"E",X"0",
		X"0",X"8",X"6",X"6",X"5",X"0",X"6",X"7",X"8",X"9",X"A",X"B",X"C",X"D",X"E",X"0",
		X"0",X"7",X"9",X"9",X"0",X"5",X"6",X"7",X"8",X"9",X"A",X"B",X"C",X"D",X"E",X"0",
		X"0",X"7",X"8",X"8",X"0",X"0",X"6",X"7",X"8",X"9",X"A",X"B",X"C",X"D",X"E",X"5",
		X"0",X"8",X"7",X"7",X"0",X"0",X"6",X"7",X"8",X"9",X"A",X"B",X"C",X"D",X"E",X"A",
		X"0",X"9",X"7",X"7",X"0",X"0",X"6",X"7",X"8",X"9",X"A",X"B",X"C",X"D",X"E",X"7",
		X"0",X"6",X"8",X"8",X"0",X"0",X"6",X"7",X"8",X"9",X"A",X"B",X"C",X"D",X"E",X"3",
		X"0",X"0",X"0",X"0",X"2",X"3",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"8",
		X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
