library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity palette is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(7 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of palette is
	type rom is array(0 to  255) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"00",X"00",X"F0",X"F0",X"36",X"26",X"00",X"FF",X"00",X"00",X"F0",X"F6",X"26",X"36",X"00",X"FF",
		X"00",X"00",X"F0",X"36",X"00",X"06",X"00",X"FF",X"00",X"00",X"F0",X"06",X"06",X"00",X"00",X"00",
		X"00",X"00",X"F0",X"38",X"06",X"06",X"00",X"00",X"00",X"00",X"36",X"C6",X"46",X"85",X"00",X"FF",
		X"00",X"00",X"36",X"06",X"06",X"06",X"06",X"00",X"00",X"C0",X"DB",X"F6",X"F0",X"E0",X"80",X"06",
		X"00",X"04",X"02",X"F0",X"06",X"06",X"04",X"02",X"00",X"00",X"9B",X"A3",X"A4",X"EC",X"A3",X"A4",
		X"00",X"F0",X"E0",X"36",X"26",X"06",X"FF",X"00",X"00",X"18",X"85",X"B4",X"AC",X"14",X"84",X"E0",
		X"00",X"24",X"1B",X"82",X"E0",X"36",X"12",X"80",X"00",X"00",X"F6",X"18",X"40",X"B4",X"AC",X"A4",
		X"00",X"B4",X"AC",X"E0",X"18",X"40",X"A4",X"00",X"00",X"AC",X"B4",X"36",X"F6",X"A4",X"00",X"18",
		X"00",X"C6",X"06",X"F0",X"36",X"26",X"04",X"34",X"00",X"F6",X"DB",X"E0",X"06",X"26",X"03",X"00",
		X"00",X"00",X"20",X"06",X"26",X"34",X"32",X"30",X"00",X"F6",X"00",X"B4",X"AC",X"52",X"A5",X"06",
		X"00",X"A4",X"00",X"05",X"04",X"16",X"26",X"F6",X"00",X"A3",X"36",X"34",X"30",X"A4",X"16",X"20",
		X"00",X"26",X"85",X"F6",X"D2",X"C0",X"80",X"82",X"00",X"26",X"85",X"F6",X"30",X"28",X"20",X"18",
		X"00",X"26",X"85",X"F6",X"07",X"06",X"05",X"04",X"00",X"A3",X"26",X"06",X"04",X"A4",X"16",X"5D",
		X"00",X"F6",X"36",X"06",X"04",X"26",X"03",X"00",X"00",X"16",X"00",X"EE",X"E6",X"C6",X"5D",X"00",
		X"00",X"07",X"06",X"04",X"C4",X"85",X"05",X"05",X"00",X"00",X"36",X"16",X"05",X"EE",X"E6",X"C6",
		X"00",X"EE",X"E6",X"C4",X"16",X"05",X"C6",X"00",X"00",X"E6",X"EE",X"85",X"36",X"C6",X"00",X"16");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
