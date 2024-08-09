library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity egs6 is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(9 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of egs6 is
	type rom is array(0 to  1023) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"2E",X"16",X"30",X"22",X"32",X"24",X"32",X"2C",X"26",X"32",X"18",X"20",X"26",X"30",X"1A",X"1A",
		X"14",X"26",X"2A",X"2E",X"32",X"12",X"28",X"10",X"18",X"24",X"28",X"26",X"16",X"1E",X"10",X"26",
		X"2E",X"2A",X"22",X"22",X"1C",X"16",X"1C",X"24",X"12",X"14",X"30",X"18",X"1E",X"1A",X"1A",X"2C",
		X"14",X"18",X"2C",X"12",X"20",X"10",X"20",X"30",X"16",X"2A",X"10",X"16",X"30",X"2E",X"12",X"24",
		X"28",X"1E",X"24",X"1C",X"18",X"22",X"28",X"12",X"1C",X"14",X"28",X"22",X"12",X"2A",X"1E",X"1A",
		X"14",X"10",X"2A",X"1E",X"20",X"10",X"1E",X"2C",X"20",X"14",X"2C",X"1C",X"20",X"1C",X"1C",X"FF",
		X"1C",X"1C",X"20",X"2A",X"00",X"20",X"7C",X"FE",X"30",X"D0",X"3A",X"4F",X"20",X"FE",X"01",X"CA",
		X"85",X"18",X"FE",X"02",X"CA",X"8B",X"18",X"11",X"1E",X"00",X"2A",X"45",X"20",X"19",X"22",X"45",
		X"20",X"3A",X"4F",X"20",X"C9",X"11",X"0A",X"00",X"C3",X"7A",X"18",X"11",X"14",X"00",X"C3",X"7A",
		X"18",X"CD",X"D0",X"0F",X"CD",X"23",X"00",X"C9",X"DB",X"01",X"E6",X"02",X"C8",X"37",X"C9",X"CD",
		X"98",X"18",X"DA",X"C6",X"18",X"3A",X"60",X"20",X"FE",X"00",X"CA",X"A4",X"0D",X"FE",X"01",X"CA",
		X"A4",X"0D",X"C3",X"98",X"0D",X"CD",X"98",X"18",X"DA",X"DB",X"18",X"3A",X"60",X"20",X"FE",X"00",
		X"CA",X"A4",X"0D",X"C3",X"98",X"0D",X"3A",X"60",X"20",X"FE",X"00",X"CA",X"5F",X"0D",X"FE",X"01",
		X"CA",X"A4",X"0D",X"FE",X"02",X"CA",X"A4",X"0D",X"C3",X"98",X"0D",X"3A",X"60",X"20",X"FE",X"00",
		X"CA",X"A4",X"0D",X"FE",X"01",X"CA",X"A4",X"0D",X"C3",X"98",X"0D",X"00",X"00",X"00",X"11",X"32",
		X"00",X"2A",X"45",X"20",X"19",X"22",X"45",X"20",X"CD",X"8F",X"04",X"C3",X"15",X"0D",X"CD",X"69",
		X"0C",X"CD",X"98",X"18",X"DA",X"19",X"19",X"3A",X"50",X"22",X"FE",X"03",X"DA",X"14",X"19",X"3E",
		X"22",X"D3",X"06",X"C9",X"3E",X"30",X"C3",X"11",X"19",X"3A",X"60",X"20",X"B7",X"C2",X"07",X"19",
		X"3A",X"50",X"22",X"FE",X"01",X"CA",X"14",X"19",X"C3",X"0F",X"19",X"04",X"16",X"F8",X"FF",X"FF",
		X"0F",X"04",X"00",X"00",X"10",X"F2",X"FF",X"FF",X"27",X"F9",X"FF",X"FF",X"4F",X"1D",X"1C",X"1C",
		X"5C",X"1D",X"1C",X"1C",X"5C",X"DD",X"DF",X"DD",X"5D",X"DD",X"DF",X"DD",X"5D",X"DD",X"DF",X"DF",
		X"5F",X"DD",X"DF",X"DF",X"5F",X"1D",X"DF",X"1F",X"5C",X"1D",X"DF",X"1F",X"5C",X"DD",X"5F",X"FC",
		X"5D",X"DD",X"5F",X"FC",X"5D",X"DD",X"DF",X"DD",X"5D",X"DD",X"DF",X"DD",X"5D",X"1D",X"1C",X"1C",
		X"5C",X"1D",X"14",X"14",X"54",X"F9",X"FF",X"FF",X"4F",X"F2",X"FF",X"FF",X"27",X"04",X"00",X"00",
		X"10",X"F8",X"FF",X"FF",X"0F",X"CD",X"0A",X"02",X"21",X"0E",X"29",X"11",X"2B",X"19",X"CD",X"63",
		X"01",X"C9",X"CD",X"E1",X"13",X"C3",X"11",X"08",X"C3",X"A5",X"19",X"C3",X"11",X"08",X"CD",X"5F",
		X"05",X"CD",X"9E",X"11",X"C9",X"3A",X"01",X"21",X"B7",X"C2",X"11",X"08",X"CD",X"B8",X"13",X"C3",
		X"11",X"08",X"CD",X"EB",X"11",X"3A",X"01",X"21",X"B7",X"C8",X"F1",X"C1",X"C9",X"32",X"01",X"21",
		X"B7",X"00",X"00",X"00",X"21",X"2D",X"19",X"AF",X"06",X"65",X"86",X"23",X"05",X"C2",X"CA",X"19",
		X"0E",X"FD",X"2F",X"81",X"CA",X"D9",X"0F",X"39",X"C3",X"42",X"00",X"C9",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FD",X"19",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"DB",X"01",X"1F",X"DA",X"1B",X"1A",X"3E",X"01",X"32",X"01",X"21",X"CD",X"28",X"00",X"C9",X"FF",
		X"3E",X"20",X"D3",X"03",X"C3",X"C5",X"0F",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"3A",X"01",X"21",X"A7",X"C8",X"3E",X"28",X"D3",X"03",X"C9",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"3A",X"01",X"21",X"A7",X"C8",X"3E",X"24",X"D3",X"03",X"C9",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"3A",X"01",X"21",X"A7",X"CA",X"5C",X"1A",X"3E",X"20",X"D3",X"03",X"C9",X"3E",X"00",X"D3",X"03",
		X"C9",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"7D",X"D6",X"40",X"6F",X"7C",X"DE",X"00",X"67",X"CD",X"61",X"01",X"C9",X"2A",X"06",X"20",X"7D",
		X"E6",X"1F",X"6F",X"3E",X"EB",X"85",X"D2",X"14",X"0B",X"CD",X"90",X"1A",X"C3",X"E2",X"0A",X"00",
		X"DB",X"01",X"17",X"17",X"C9",X"2A",X"06",X"20",X"7D",X"E6",X"1F",X"6F",X"3E",X"EB",X"85",X"D2",
		X"B5",X"0E",X"CD",X"90",X"1A",X"C3",X"68",X"0D",X"3A",X"FF",X"3F",X"A7",X"3E",X"00",X"32",X"FF",
		X"3F",X"C2",X"7C",X"1A",X"DB",X"01",X"17",X"17",X"00",X"C3",X"DF",X"0A",X"3A",X"FF",X"3F",X"A7",
		X"3E",X"00",X"32",X"FF",X"3F",X"C2",X"95",X"1A",X"DB",X"01",X"17",X"17",X"00",X"C3",X"65",X"0D",
		X"3E",X"80",X"32",X"FF",X"3F",X"C3",X"00",X"0C",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"02",X"15",X"00",X"04",X"44",X"02",X"68",X"01",X"00",X"20",X"98",X"10",X"8C",X"03",X"E4",X"05",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"02",X"14",X"40",X"00",
		X"80",X"04",X"04",X"00",X"10",X"12",X"24",X"08",X"80",X"01",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"80",X"00",X"01",X"0D",X"18",X"18",X"08",X"1C",X"5F",X"7D",
		X"1D",X"1C",X"7C",X"44",X"44",X"C4",X"0C",X"01",X"0D",X"18",X"18",X"08",X"1E",X"1E",X"12",X"7C",
		X"1C",X"1C",X"14",X"17",X"11",X"30",X"01",X"0D",X"18",X"1A",X"0C",X"10",X"08",X"38",X"58",X"18",
		X"18",X"18",X"18",X"18",X"38",X"01",X"0D",X"0C",X"0C",X"04",X"0E",X"1E",X"F6",X"06",X"0E",X"1A",
		X"12",X"12",X"12",X"36",X"02",X"0C",X"30",X"00",X"30",X"00",X"1C",X"00",X"0E",X"00",X"3E",X"00",
		X"E7",X"01",X"0F",X"1F",X"1B",X"04",X"12",X"04",X"12",X"1F",X"12",X"1F",X"36",X"1F",X"03",X"09",
		X"FC",X"FF",X"3F",X"FC",X"FF",X"3F",X"EE",X"6A",X"71",X"4E",X"4A",X"7D",X"AC",X"2A",X"39",X"EC",
		X"6A",X"3D",X"EC",X"6A",X"31",X"FC",X"FF",X"3F",X"30",X"00",X"0C",X"01",X"08",X"1F",X"04",X"04",
		X"04",X"04",X"1F",X"1F",X"1F",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
