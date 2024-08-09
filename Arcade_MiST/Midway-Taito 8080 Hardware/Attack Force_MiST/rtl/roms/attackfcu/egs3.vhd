library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity egs3 is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(9 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of egs3 is
	type rom is array(0 to  1023) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"3A",X"3D",X"20",X"B7",X"CA",X"59",X"08",X"3A",X"09",X"20",X"FE",X"01",X"CA",X"15",X"0C",X"CD",
		X"F0",X"03",X"C3",X"59",X"08",X"AF",X"32",X"09",X"20",X"32",X"3D",X"20",X"C3",X"59",X"08",X"3A",
		X"4B",X"20",X"B7",X"CA",X"02",X"0B",X"2A",X"49",X"20",X"11",X"00",X"1C",X"CD",X"77",X"00",X"CD",
		X"26",X"04",X"CD",X"1F",X"04",X"0D",X"C2",X"2F",X"0C",X"AF",X"32",X"4B",X"20",X"C3",X"02",X"0B",
		X"7C",X"E6",X"1F",X"FE",X"17",X"C8",X"C3",X"CE",X"03",X"AF",X"32",X"08",X"20",X"C3",X"B2",X"09",
		X"2A",X"0A",X"22",X"EB",X"CD",X"77",X"00",X"3A",X"08",X"22",X"D3",X"05",X"2A",X"06",X"22",X"CD",
		X"A3",X"01",X"CD",X"9A",X"0C",X"C2",X"5F",X"0C",X"C9",X"3A",X"08",X"22",X"D3",X"05",X"2A",X"0A",
		X"22",X"EB",X"CD",X"77",X"00",X"2A",X"06",X"22",X"CD",X"D2",X"01",X"CD",X"9A",X"0C",X"C2",X"78",
		X"0C",X"3A",X"08",X"22",X"3C",X"E6",X"07",X"CA",X"8E",X"0C",X"32",X"08",X"22",X"C9",X"AF",X"32",
		X"08",X"22",X"2A",X"06",X"22",X"23",X"22",X"06",X"22",X"C9",X"D5",X"11",X"1F",X"00",X"19",X"D1",
		X"0D",X"C9",X"21",X"02",X"31",X"CD",X"C1",X"0C",X"21",X"03",X"31",X"CD",X"C1",X"0C",X"21",X"04",
		X"31",X"CD",X"C1",X"0C",X"21",X"05",X"31",X"CD",X"C1",X"0C",X"21",X"06",X"31",X"CD",X"C1",X"0C",
		X"C9",X"11",X"76",X"1B",X"CD",X"63",X"01",X"C9",X"CD",X"31",X"07",X"CD",X"EE",X"01",X"CD",X"8F",
		X"04",X"CD",X"BF",X"04",X"CD",X"53",X"01",X"CD",X"A2",X"0C",X"21",X"BA",X"31",X"11",X"CB",X"1B",
		X"CD",X"63",X"01",X"21",X"06",X"38",X"11",X"AE",X"1B",X"CD",X"63",X"01",X"21",X"15",X"38",X"11",
		X"AE",X"1B",X"CD",X"63",X"01",X"C9",X"CD",X"50",X"1A",X"00",X"00",X"CD",X"C8",X"0C",X"3E",X"55",
		X"CD",X"C9",X"07",X"00",X"3E",X"05",X"32",X"50",X"22",X"21",X"58",X"1B",X"22",X"0A",X"22",X"21",
		X"67",X"1B",X"22",X"0C",X"22",X"3A",X"50",X"22",X"B7",X"CA",X"DE",X"07",X"21",X"01",X"31",X"85",
		X"6F",X"22",X"06",X"22",X"0E",X"0D",X"AF",X"77",X"CD",X"CA",X"0E",X"C2",X"26",X"0D",X"D3",X"06",
		X"CD",X"29",X"07",X"CD",X"FE",X"18",X"CD",X"74",X"0E",X"3A",X"51",X"20",X"E6",X"01",X"CA",X"4F",
		X"0D",X"2A",X"0A",X"22",X"EB",X"2A",X"0C",X"22",X"22",X"0A",X"22",X"EB",X"22",X"0C",X"22",X"3A",
		X"50",X"22",X"FE",X"01",X"CA",X"B5",X"18",X"FE",X"02",X"CA",X"9F",X"18",X"00",X"00",X"00",X"C3",
		X"C1",X"0E",X"C3",X"BC",X"1A",X"DA",X"95",X"1A",X"17",X"DA",X"BB",X"0E",X"00",X"00",X"00",X"CD",
		X"1B",X"00",X"DB",X"01",X"E6",X"10",X"00",X"C2",X"C5",X"0D",X"3A",X"3D",X"20",X"B7",X"CA",X"2E",
		X"0D",X"CD",X"F0",X"03",X"3A",X"09",X"20",X"FE",X"02",X"CA",X"E5",X"0D",X"C3",X"AD",X"0E",X"CD",
		X"E8",X"0C",X"CD",X"74",X"0E",X"C3",X"5F",X"0D",X"CD",X"69",X"0C",X"CD",X"74",X"0E",X"CD",X"69",
		X"0C",X"CD",X"74",X"0E",X"CD",X"69",X"0C",X"CD",X"74",X"0E",X"C3",X"5F",X"0D",X"CD",X"36",X"02",
		X"CD",X"94",X"0A",X"CD",X"1D",X"02",X"C3",X"72",X"0D",X"CD",X"93",X"02",X"CD",X"94",X"0A",X"CD",
		X"7A",X"02",X"C3",X"72",X"0D",X"3A",X"3D",X"20",X"B7",X"C2",X"7A",X"0D",X"CD",X"BB",X"03",X"3E",
		X"22",X"D3",X"03",X"C3",X"7A",X"0D",X"CD",X"1D",X"02",X"AF",X"32",X"09",X"20",X"32",X"3D",X"20",
		X"D3",X"02",X"C3",X"2E",X"0D",X"CD",X"30",X"1A",X"00",X"3A",X"3E",X"20",X"FE",X"38",X"D2",X"20",
		X"0E",X"2A",X"06",X"22",X"11",X"00",X"1B",X"CD",X"63",X"01",X"CD",X"9E",X"0E",X"CD",X"1D",X"02",
		X"2A",X"06",X"22",X"CD",X"C7",X"0A",X"AF",X"32",X"09",X"20",X"32",X"3D",X"20",X"C3",X"20",X"1A",
		X"00",X"00",X"3D",X"32",X"50",X"22",X"C3",X"EB",X"18",X"11",X"00",X"1B",X"CD",X"63",X"01",X"C9",
		X"21",X"06",X"38",X"CD",X"19",X"0E",X"21",X"15",X"38",X"CD",X"19",X"0E",X"CD",X"A4",X"0E",X"21",
		X"07",X"38",X"CD",X"19",X"0E",X"21",X"17",X"38",X"CD",X"19",X"0E",X"CD",X"A4",X"0E",X"CD",X"DD",
		X"0E",X"3E",X"50",X"CD",X"C9",X"07",X"CD",X"65",X"00",X"AF",X"32",X"09",X"20",X"32",X"4B",X"20",
		X"32",X"50",X"20",X"32",X"52",X"20",X"21",X"60",X"20",X"CD",X"DA",X"0F",X"CA",X"92",X"19",X"C3",
		X"63",X"0F",X"CD",X"98",X"0E",X"CD",X"98",X"0E",X"CD",X"98",X"0E",X"AF",X"D3",X"02",X"CD",X"65",
		X"00",X"C3",X"63",X"0F",X"3A",X"06",X"22",X"E6",X"1F",X"FE",X"19",X"C0",X"E1",X"21",X"19",X"31",
		X"11",X"85",X"1B",X"CD",X"63",X"01",X"CD",X"D2",X"0E",X"21",X"19",X"31",X"11",X"94",X"1B",X"CD",
		X"63",X"01",X"CD",X"D2",X"0E",X"C3",X"20",X"0E",X"CD",X"1A",X"07",X"CD",X"1A",X"07",X"CD",X"1A",
		X"07",X"CD",X"1A",X"07",X"CD",X"1A",X"07",X"CD",X"D0",X"0F",X"D3",X"06",X"C9",X"FE",X"01",X"CA",
		X"D6",X"0D",X"C3",X"2E",X"0D",X"CD",X"36",X"02",X"C3",X"AD",X"0D",X"CD",X"93",X"02",X"C3",X"B9",
		X"0D",X"CD",X"50",X"0C",X"CD",X"23",X"00",X"C3",X"99",X"0F",X"D5",X"11",X"20",X"00",X"19",X"D1",
		X"0D",X"C9",X"CD",X"98",X"0E",X"CD",X"98",X"0E",X"CD",X"98",X"0E",X"C9",X"FF",X"21",X"48",X"3D",
		X"E5",X"CD",X"B5",X"0F",X"3E",X"06",X"CD",X"C9",X"07",X"E1",X"23",X"23",X"3E",X"58",X"BD",X"C2",
		X"E0",X"0E",X"C9",X"CD",X"30",X"1A",X"00",X"CD",X"DD",X"0E",X"3E",X"50",X"CD",X"C9",X"07",X"AF",
		X"CD",X"50",X"1A",X"00",X"00",X"00",X"00",X"CD",X"65",X"00",X"C3",X"F4",X"0B",X"06",X"0A",X"CD",
		X"1F",X"0F",X"C2",X"55",X"04",X"CD",X"1F",X"04",X"05",X"CA",X"31",X"04",X"C3",X"0F",X"0F",X"1A",
		X"A6",X"C9",X"3A",X"00",X"21",X"B7",X"C0",X"E1",X"CD",X"0A",X"02",X"CD",X"D0",X"0F",X"CD",X"E6",
		X"0F",X"CA",X"59",X"08",X"AF",X"21",X"45",X"20",X"77",X"23",X"77",X"CD",X"65",X"00",X"3E",X"55",
		X"CD",X"C9",X"07",X"3E",X"20",X"D3",X"03",X"AF",X"32",X"4B",X"20",X"C3",X"90",X"0F",X"00",X"21",
		X"B7",X"C9",X"CD",X"DD",X"0E",X"3E",X"50",X"CD",X"C9",X"07",X"CD",X"65",X"00",X"CD",X"DA",X"0F",
		X"CA",X"F6",X"0C",X"3E",X"00",X"D3",X"03",X"CD",X"74",X"0F",X"AF",X"32",X"00",X"21",X"32",X"01",
		X"21",X"C3",X"90",X"0F",X"2A",X"45",X"20",X"EB",X"2A",X"47",X"20",X"CD",X"82",X"0F",X"DA",X"87",
		X"0F",X"C9",X"7D",X"93",X"7C",X"9A",X"C9",X"EB",X"22",X"47",X"20",X"00",X"CD",X"BF",X"04",X"C9",
		X"32",X"50",X"20",X"32",X"52",X"20",X"C3",X"F0",X"0F",X"CD",X"A0",X"0F",X"C3",X"62",X"0D",X"FF",
		X"3A",X"00",X"21",X"B7",X"C0",X"E1",X"CD",X"85",X"19",X"CD",X"D0",X"0F",X"CD",X"E6",X"0F",X"CA",
		X"2E",X"0D",X"C3",X"34",X"0F",X"AF",X"CD",X"50",X"1A",X"00",X"CD",X"D0",X"0F",X"CD",X"19",X"0E",
		X"CD",X"40",X"1A",X"00",X"C9",X"D3",X"02",X"3A",X"50",X"22",X"C3",X"12",X"0E",X"FF",X"FF",X"FF",
		X"DB",X"01",X"1F",X"D8",X"3E",X"01",X"C3",X"BD",X"19",X"C9",X"00",X"3A",X"00",X"21",X"B7",X"C9",
		X"31",X"00",X"23",X"C3",X"03",X"08",X"3A",X"01",X"21",X"32",X"00",X"21",X"B7",X"C9",X"FF",X"FF",
		X"32",X"60",X"20",X"32",X"09",X"20",X"32",X"4B",X"20",X"32",X"3D",X"20",X"00",X"C3",X"98",X"19");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
