library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity egs1 is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(9 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of egs1 is
	type rom is array(0 to  1023) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"F8",X"03",X"2A",X"3D",X"20",X"11",X"00",X"FF",X"19",X"22",X"3D",X"20",X"11",X"36",X"20",X"0E",
		X"05",X"CD",X"0D",X"0F",X"CD",X"2C",X"04",X"CD",X"1F",X"04",X"0D",X"C2",X"14",X"04",X"C9",X"D5",
		X"11",X"20",X"00",X"19",X"D1",X"C9",X"1A",X"2F",X"A6",X"77",X"13",X"C9",X"1A",X"B6",X"77",X"13",
		X"C9",X"1A",X"47",X"7E",X"A0",X"C2",X"55",X"04",X"CD",X"1F",X"04",X"7E",X"A0",X"C2",X"55",X"04",
		X"CD",X"1F",X"04",X"7E",X"A0",X"C2",X"55",X"04",X"2A",X"3D",X"20",X"3E",X"23",X"BC",X"C0",X"3E",
		X"01",X"32",X"09",X"20",X"C9",X"3E",X"02",X"C3",X"00",X"06",X"C9",X"F5",X"C5",X"D5",X"E5",X"EB",
		X"01",X"F0",X"D8",X"CD",X"7F",X"04",X"01",X"18",X"FC",X"CD",X"7F",X"04",X"01",X"9C",X"FF",X"CD",
		X"7F",X"04",X"01",X"F6",X"FF",X"CD",X"7F",X"04",X"7D",X"12",X"E1",X"D1",X"C1",X"F1",X"C9",X"AF",
		X"D5",X"5D",X"54",X"3C",X"09",X"DA",X"81",X"04",X"3D",X"6B",X"62",X"D1",X"12",X"13",X"C9",X"2A",
		X"45",X"20",X"EB",X"21",X"40",X"20",X"CD",X"5B",X"04",X"21",X"41",X"20",X"E5",X"11",X"0D",X"1F",
		X"01",X"11",X"00",X"1A",X"BE",X"CA",X"AE",X"04",X"EB",X"09",X"EB",X"C3",X"A3",X"04",X"01",X"38",
		X"1D",X"09",X"13",X"CD",X"63",X"01",X"E1",X"23",X"3E",X"45",X"BD",X"C8",X"C3",X"9C",X"04",X"2A",
		X"47",X"20",X"EB",X"21",X"40",X"20",X"CD",X"5B",X"04",X"21",X"41",X"20",X"E5",X"11",X"0D",X"1F",
		X"01",X"11",X"00",X"1A",X"BE",X"CA",X"DE",X"04",X"EB",X"09",X"EB",X"C3",X"D3",X"04",X"01",X"22",
		X"1D",X"09",X"13",X"CD",X"63",X"01",X"E1",X"23",X"3E",X"45",X"BD",X"C8",X"C3",X"CC",X"04",X"3A",
		X"4B",X"20",X"B7",X"C2",X"05",X"05",X"11",X"C0",X"01",X"2A",X"00",X"20",X"19",X"22",X"49",X"20",
		X"3E",X"01",X"32",X"4B",X"20",X"2A",X"49",X"20",X"11",X"00",X"1C",X"CD",X"77",X"00",X"CD",X"26",
		X"04",X"CD",X"1F",X"04",X"0D",X"C2",X"0E",X"05",X"2A",X"49",X"20",X"11",X"E0",X"00",X"19",X"22",
		X"49",X"20",X"11",X"00",X"1C",X"CD",X"77",X"00",X"CD",X"36",X"05",X"CD",X"2C",X"04",X"CD",X"1F",
		X"04",X"0D",X"C2",X"2B",X"05",X"C9",X"1A",X"47",X"7E",X"A0",X"C2",X"5A",X"05",X"CD",X"1F",X"04",
		X"7E",X"A0",X"C2",X"5A",X"05",X"CD",X"1F",X"04",X"7E",X"A0",X"C2",X"5A",X"05",X"2A",X"49",X"20",
		X"3E",X"3E",X"BC",X"D0",X"3E",X"02",X"C3",X"49",X"07",X"00",X"3E",X"04",X"C3",X"06",X"06",X"06",
		X"22",X"21",X"00",X"20",X"AF",X"77",X"BE",X"C2",X"65",X"05",X"23",X"7C",X"B8",X"C2",X"64",X"05",
		X"C9",X"D5",X"E5",X"2A",X"04",X"20",X"EB",X"2A",X"0E",X"20",X"22",X"04",X"20",X"EB",X"22",X"0E",
		X"20",X"E1",X"D1",X"C9",X"D5",X"E5",X"2A",X"0A",X"20",X"EB",X"2A",X"0C",X"20",X"22",X"0A",X"20",
		X"EB",X"22",X"0C",X"20",X"E1",X"D1",X"C9",X"1A",X"6F",X"13",X"1A",X"67",X"C9",X"16",X"20",X"CD",
		X"97",X"05",X"22",X"00",X"20",X"1B",X"7D",X"E6",X"1F",X"06",X"F8",X"80",X"F5",X"21",X"B7",X"1F",
		X"06",X"06",X"7E",X"BB",X"CA",X"C8",X"05",X"3C",X"3C",X"05",X"C2",X"B3",X"05",X"3E",X"0A",X"85",
		X"6F",X"D2",X"B0",X"05",X"24",X"C3",X"B0",X"05",X"23",X"7E",X"32",X"4F",X"20",X"23",X"F1",X"D2",
		X"F3",X"05",X"23",X"23",X"23",X"23",X"3E",X"01",X"32",X"4C",X"20",X"EB",X"CD",X"97",X"05",X"13",
		X"22",X"04",X"20",X"CD",X"97",X"05",X"22",X"0E",X"20",X"3E",X"01",X"32",X"03",X"20",X"AF",X"32",
		X"02",X"20",X"C9",X"AF",X"32",X"4C",X"20",X"C3",X"DB",X"05",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"32",X"09",X"20",X"C3",X"48",X"04",X"32",X"4B",X"20",X"C3",X"4D",X"05",X"FF",X"FF",X"FF",X"FF",
		X"2A",X"10",X"20",X"CD",X"E7",X"06",X"CA",X"1C",X"06",X"CD",X"EA",X"06",X"2A",X"12",X"20",X"CD",
		X"E7",X"06",X"CA",X"28",X"06",X"CD",X"EA",X"06",X"2A",X"14",X"20",X"CD",X"E7",X"06",X"CA",X"34",
		X"06",X"CD",X"EA",X"06",X"2A",X"16",X"20",X"CD",X"E7",X"06",X"CA",X"40",X"06",X"CD",X"EA",X"06",
		X"2A",X"18",X"20",X"CD",X"E7",X"06",X"CA",X"4C",X"06",X"CD",X"EA",X"06",X"2A",X"1A",X"20",X"CD",
		X"E7",X"06",X"CA",X"58",X"06",X"CD",X"EA",X"06",X"2A",X"1C",X"20",X"CD",X"E7",X"06",X"CA",X"64",
		X"06",X"CD",X"FA",X"06",X"2A",X"1E",X"20",X"CD",X"E7",X"06",X"CA",X"70",X"06",X"CD",X"FA",X"06",
		X"2A",X"20",X"20",X"CD",X"E7",X"06",X"CA",X"7C",X"06",X"CD",X"FA",X"06",X"2A",X"22",X"20",X"CD",
		X"E7",X"06",X"CA",X"88",X"06",X"CD",X"FA",X"06",X"2A",X"24",X"20",X"CD",X"E7",X"06",X"CA",X"94",
		X"06",X"CD",X"FA",X"06",X"2A",X"26",X"20",X"CD",X"E7",X"06",X"CA",X"A0",X"06",X"CD",X"FA",X"06",
		X"2A",X"28",X"20",X"CD",X"E7",X"06",X"CA",X"AC",X"06",X"CD",X"0A",X"07",X"2A",X"2A",X"20",X"CD",
		X"E7",X"06",X"CA",X"B8",X"06",X"CD",X"0A",X"07",X"2A",X"2C",X"20",X"CD",X"E7",X"06",X"CA",X"C4",
		X"06",X"CD",X"0A",X"07",X"2A",X"2E",X"20",X"CD",X"E7",X"06",X"CA",X"D0",X"06",X"CD",X"0A",X"07",
		X"2A",X"30",X"20",X"CD",X"E7",X"06",X"CA",X"DC",X"06",X"CD",X"0A",X"07",X"2A",X"32",X"20",X"CD",
		X"E7",X"06",X"C8",X"CD",X"0A",X"07",X"C9",X"7D",X"B7",X"C9",X"E6",X"10",X"C2",X"F3",X"06",X"CD",
		X"60",X"01",X"C9",X"11",X"10",X"1C",X"CD",X"63",X"01",X"C9",X"E6",X"10",X"C2",X"03",X"07",X"CD",
		X"6A",X"01",X"C9",X"11",X"4C",X"1C",X"CD",X"63",X"01",X"C9",X"E6",X"10",X"C2",X"13",X"07",X"CD",
		X"74",X"01",X"C9",X"11",X"2E",X"1C",X"CD",X"63",X"01",X"C9",X"2A",X"00",X"20",X"7C",X"FE",X"30",
		X"D2",X"29",X"07",X"CD",X"1B",X"00",X"C3",X"2C",X"07",X"CD",X"23",X"00",X"21",X"51",X"20",X"34",
		X"C9",X"06",X"3D",X"21",X"00",X"23",X"97",X"77",X"23",X"7C",X"B8",X"C2",X"36",X"07",X"C9",X"CD",
		X"7E",X"00",X"21",X"4E",X"3D",X"22",X"06",X"20",X"C9",X"32",X"4B",X"20",X"D1",X"C9",X"CD",X"3B",
		X"01",X"CD",X"EE",X"01",X"CD",X"8F",X"04",X"CD",X"BF",X"04",X"C9",X"DB",X"01",X"E6",X"10",X"00",
		X"C2",X"3B",X"0B",X"D3",X"06",X"C3",X"F0",X"0A",X"CD",X"1A",X"07",X"3A",X"4F",X"20",X"C9",X"CD",
		X"F9",X"07",X"CD",X"30",X"1A",X"00",X"C3",X"02",X"0B",X"AF",X"D3",X"02",X"C3",X"39",X"08",X"3A",
		X"60",X"20",X"B7",X"CA",X"8C",X"07",X"47",X"87",X"05",X"C2",X"87",X"07",X"47",X"3A",X"50",X"20",
		X"80",X"C9",X"00",X"F5",X"CD",X"23",X"00",X"F1",X"D3",X"06",X"3D",X"C2",X"93",X"07",X"00",X"00",
		X"00",X"21",X"60",X"20",X"34",X"C3",X"11",X"08",X"AF",X"32",X"50",X"20",X"D3",X"06",X"CD",X"F9",
		X"07",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"C3",X"D5",X"07",X"CD",X"30",X"1A",
		X"00",X"2A",X"3D",X"20",X"C3",X"A5",X"0A",X"3E",X"FF",X"F5",X"CD",X"91",X"18",X"F1",X"D3",X"06",
		X"3D",X"C2",X"C9",X"07",X"C9",X"CD",X"E7",X"07",X"CD",X"31",X"07",X"C3",X"F6",X"0C",X"CD",X"E7",
		X"07",X"CD",X"65",X"00",X"C3",X"A1",X"07",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"3E",X"04",X"D3",X"06",X"CD",X"C7",X"07",X"00",X"C9",X"C3",X"50",X"1A",X"00",X"C9",X"FF",X"FF");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
