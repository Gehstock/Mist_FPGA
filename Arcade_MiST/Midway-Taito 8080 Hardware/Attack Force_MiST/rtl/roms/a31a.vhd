library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity a31a is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(9 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of a31a is
	type rom is array(0 to  1023) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"C3",X"E0",X"0F",X"00",X"00",X"00",X"AF",X"D3",X"04",X"D3",X"06",X"CD",X"65",X"00",X"CD",X"9E",
		X"19",X"AF",X"32",X"08",X"20",X"00",X"3E",X"08",X"32",X"53",X"20",X"21",X"1A",X"1D",X"22",X"0A",
		X"20",X"21",X"07",X"1E",X"22",X"0C",X"20",X"CD",X"3F",X"07",X"CD",X"E5",X"01",X"CD",X"8F",X"04",
		X"CD",X"BF",X"04",X"21",X"00",X"18",X"22",X"4D",X"20",X"2A",X"4D",X"20",X"5E",X"CD",X"9D",X"05",
		X"3A",X"00",X"20",X"B7",X"C2",X"59",X"08",X"CD",X"D4",X"09",X"2A",X"4D",X"20",X"23",X"22",X"4D",
		X"20",X"C3",X"39",X"08",X"3A",X"4C",X"20",X"B7",X"C9",X"CD",X"68",X"07",X"D3",X"06",X"CD",X"54",
		X"08",X"CA",X"6A",X"08",X"CD",X"62",X"03",X"C3",X"6D",X"08",X"CD",X"E8",X"02",X"3A",X"03",X"20",
		X"B7",X"CC",X"4E",X"09",X"3A",X"51",X"20",X"E6",X"01",X"C4",X"71",X"05",X"CD",X"7F",X"07",X"FE",
		X"0D",X"D2",X"94",X"08",X"FE",X"04",X"D2",X"D0",X"08",X"3A",X"4F",X"20",X"FE",X"03",X"CA",X"DE",
		X"08",X"C3",X"DE",X"09",X"CD",X"54",X"08",X"C2",X"B8",X"08",X"CD",X"00",X"03",X"CD",X"D9",X"08",
		X"CC",X"4E",X"09",X"CD",X"00",X"03",X"CD",X"D9",X"08",X"CC",X"4E",X"09",X"CD",X"00",X"03",X"CD",
		X"D9",X"08",X"CC",X"4E",X"09",X"C3",X"89",X"08",X"CD",X"7A",X"03",X"CD",X"D9",X"08",X"CC",X"4E",
		X"09",X"CD",X"7A",X"03",X"CD",X"D9",X"08",X"CC",X"4E",X"09",X"CD",X"7A",X"03",X"C3",X"AF",X"08",
		X"CD",X"54",X"08",X"C2",X"CA",X"08",X"C3",X"AC",X"08",X"3A",X"03",X"20",X"B7",X"C9",X"00",X"00",
		X"00",X"CD",X"7F",X"07",X"FE",X"0D",X"D2",X"F7",X"08",X"FE",X"06",X"D2",X"45",X"09",X"CD",X"54",
		X"08",X"C2",X"3F",X"09",X"C3",X"18",X"09",X"CD",X"54",X"08",X"C2",X"24",X"09",X"CD",X"00",X"03",
		X"23",X"00",X"3A",X"4B",X"20",X"B7",X"C2",X"39",X"0A",X"3A",X"52",X"20",X"B7",X"C2",X"68",X"0A",
		X"3A",X"4F",X"20",X"FE",X"03",X"CA",X"D6",X"0A",X"3A",X"00",X"20",X"E6",X"1F",X"47",X"3A",X"06",
		X"20",X"E6",X"1F",X"B8",X"CA",X"39",X"0A",X"3C",X"B8",X"CA",X"39",X"0A",X"C3",X"D6",X"0A",X"39",
		X"0A",X"3C",X"B8",X"CA",X"39",X"0A",X"C3",X"D6",X"0A",X"CD",X"EF",X"04",X"3A",X"4B",X"20",X"FE",
		X"02",X"CA",X"4C",X"0A",X"FE",X"04",X"CA",X"53",X"0A",X"C3",X"D6",X"0A",X"AF",X"32",X"4B",X"20",
		X"C3",X"D6",X"0A",X"2A",X"49",X"20",X"3E",X"3C",X"BC",X"D2",X"6F",X"0A",X"AF",X"32",X"4B",X"20",
		X"3E",X"02",X"32",X"52",X"20",X"CD",X"C5",X"09",X"3E",X"08",X"D3",X"06",X"C3",X"75",X"0A",X"CD",
		X"9E",X"0A",X"C3",X"D6",X"0A",X"2A",X"49",X"20",X"3A",X"51",X"20",X"E6",X"02",X"CA",X"89",X"0A",
		X"11",X"00",X"1B",X"CD",X"63",X"01",X"C3",X"00",X"0C",X"11",X"2C",X"1B",X"C3",X"83",X"0A",X"21",
		X"61",X"20",X"35",X"C9",X"3A",X"08",X"20",X"E6",X"02",X"C0",X"CD",X"84",X"05",X"C9",X"3E",X"08",
		X"D3",X"06",X"2A",X"3D",X"20",X"11",X"00",X"1B",X"CD",X"63",X"01",X"CD",X"1A",X"07",X"CD",X"1A",
		X"07",X"CD",X"1D",X"02",X"2A",X"3D",X"20",X"CD",X"C7",X"0A",X"AF",X"32",X"4B",X"20",X"32",X"09",
		X"20",X"32",X"3D",X"20",X"D3",X"02",X"C9",X"06",X"1F",X"AF",X"77",X"23",X"77",X"11",X"1F",X"00",
		X"19",X"05",X"C2",X"C9",X"0A",X"C9",X"CD",X"22",X"0F",X"00",X"00",X"00",X"DB",X"00",X"1F",X"D2",
		X"14",X"0B",X"1F",X"D2",X"26",X"0B",X"CD",X"23",X"00",X"00",X"00",X"00",X"00",X"C3",X"5B",X"07",
		X"3A",X"3D",X"20",X"B7",X"CA",X"11",X"0B",X"CD",X"F0",X"03",X"3A",X"09",X"20",X"FE",X"02",X"CA",
		X"CD",X"D9",X"08",X"CC",X"4E",X"09",X"CD",X"00",X"03",X"CD",X"D9",X"08",X"CC",X"4E",X"09",X"CD",
		X"00",X"03",X"CD",X"D9",X"08",X"CC",X"4E",X"09",X"CD",X"00",X"03",X"CD",X"D9",X"08",X"CC",X"4E",
		X"09",X"C3",X"DE",X"09",X"CD",X"7A",X"03",X"CD",X"D9",X"08",X"CC",X"4E",X"09",X"CD",X"7A",X"03",
		X"CD",X"D9",X"08",X"CC",X"4E",X"09",X"CD",X"7A",X"03",X"CD",X"D9",X"08",X"CC",X"4E",X"09",X"CD",
		X"7A",X"03",X"C3",X"1B",X"09",X"CD",X"54",X"08",X"C2",X"36",X"09",X"C3",X"0F",X"09",X"AF",X"D3",
		X"06",X"CD",X"54",X"08",X"CA",X"5E",X"09",X"2A",X"00",X"20",X"23",X"22",X"00",X"20",X"2A",X"4D",
		X"20",X"5E",X"16",X"20",X"2A",X"00",X"20",X"EB",X"73",X"23",X"72",X"2A",X"4D",X"20",X"5E",X"CD",
		X"9D",X"05",X"2A",X"04",X"20",X"EB",X"2A",X"00",X"20",X"CD",X"63",X"01",X"2A",X"4D",X"20",X"23",
		X"22",X"4D",X"20",X"D3",X"05",X"00",X"00",X"3A",X"52",X"20",X"B7",X"CA",X"C1",X"09",X"3D",X"32",
		X"52",X"20",X"C2",X"C1",X"09",X"11",X"60",X"FF",X"2A",X"06",X"20",X"19",X"06",X"1A",X"0E",X"06",
		X"AF",X"77",X"23",X"0D",X"C2",X"A0",X"09",X"05",X"CA",X"49",X"0C",X"11",X"1A",X"00",X"19",X"C3",
		X"9E",X"09",X"21",X"4E",X"3D",X"22",X"06",X"20",X"CD",X"E5",X"01",X"CD",X"C5",X"09",X"AF",X"D3",
		X"02",X"E1",X"C3",X"39",X"08",X"2A",X"50",X"20",X"E5",X"2A",X"53",X"20",X"22",X"50",X"20",X"E1",
		X"22",X"53",X"20",X"C9",X"3A",X"50",X"20",X"FE",X"12",X"C0",X"E1",X"C3",X"A8",X"07",X"D3",X"05",
		X"00",X"CD",X"D0",X"0F",X"CD",X"54",X"08",X"C2",X"F0",X"09",X"CD",X"CF",X"02",X"C3",X"F3",X"09",
		X"CD",X"49",X"03",X"2A",X"00",X"20",X"3E",X"3B",X"BC",X"CA",X"52",X"0F",X"00",X"00",X"00",X"CD",
		X"4C",X"0B",X"3A",X"62",X"20",X"B7",X"C2",X"8D",X"0B",X"3A",X"09",X"20",X"FE",X"01",X"CA",X"DD",
		X"0B",X"C3",X"EA",X"0B",X"CD",X"36",X"02",X"CD",X"36",X"02",X"CD",X"94",X"0A",X"CD",X"1D",X"02",
		X"00",X"00",X"00",X"C3",X"5B",X"07",X"CD",X"93",X"02",X"CD",X"93",X"02",X"CD",X"94",X"0A",X"CD",
		X"7A",X"02",X"00",X"00",X"00",X"C3",X"5B",X"07",X"00",X"00",X"00",X"3A",X"3D",X"20",X"B7",X"C2",
		X"F0",X"0A",X"CD",X"BB",X"03",X"3E",X"10",X"D3",X"02",X"C3",X"F0",X"0A",X"3A",X"01",X"20",X"C6",
		X"05",X"47",X"3A",X"3E",X"20",X"B8",X"FA",X"5F",X"0B",X"CD",X"9E",X"0A",X"C3",X"02",X"0B",X"CD",
		X"63",X"18",X"FE",X"01",X"CA",X"81",X"0B",X"FE",X"02",X"CA",X"87",X"0B",X"11",X"1E",X"00",X"2A",
		X"45",X"20",X"19",X"22",X"45",X"20",X"CD",X"8F",X"04",X"3E",X"4F",X"32",X"62",X"20",X"C3",X"6F",
		X"07",X"11",X"0A",X"00",X"C3",X"6F",X"0B",X"11",X"14",X"00",X"C3",X"6F",X"0B",X"3A",X"62",X"20",
		X"E6",X"02",X"CA",X"A1",X"0B",X"11",X"00",X"1B",X"2A",X"00",X"20",X"CD",X"63",X"01",X"C3",X"A7",
		X"0B",X"11",X"2C",X"1B",X"C3",X"98",X"0B",X"3A",X"62",X"20",X"3D",X"32",X"62",X"20",X"C2",X"1F",
		X"0C",X"AF",X"32",X"00",X"20",X"32",X"09",X"20",X"32",X"3D",X"20",X"2A",X"4D",X"20",X"5E",X"16",
		X"20",X"EB",X"77",X"2A",X"4D",X"20",X"23",X"22",X"4D",X"20",X"21",X"50",X"20",X"34",X"CD",X"31",
		X"07",X"CD",X"10",X"06",X"CD",X"4E",X"07",X"CD",X"1D",X"02",X"C3",X"79",X"07",X"AF",X"32",X"09",
		X"20",X"32",X"3D",X"20",X"D3",X"02",X"00",X"CD",X"1D",X"02",X"00",X"00",X"00",X"00",X"00",X"00",
		X"C3",X"59",X"08",X"76",X"76",X"CD",X"2C",X"07",X"3A",X"51",X"20",X"E6",X"01",X"C9",X"FF",X"FF");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
