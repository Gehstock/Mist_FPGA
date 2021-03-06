library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity ROM_N2 is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(10 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of ROM_N2 is
	type rom is array(0 to  2047) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"BD",X"DC",X"38",X"85",X"8F",X"A0",X"14",X"B1",X"8E",X"29",X"3F",X"05",X"8D",X"99",X"A6",X"0A",
		X"88",X"10",X"F4",X"E0",X"02",X"F0",X"26",X"E0",X"04",X"F0",X"22",X"A5",X"8C",X"0A",X"0A",X"0A",
		X"0A",X"29",X"C0",X"85",X"8D",X"BD",X"E3",X"38",X"85",X"8E",X"BD",X"E4",X"38",X"85",X"8F",X"A0",
		X"11",X"B1",X"8E",X"29",X"3F",X"05",X"8D",X"99",X"C7",X"0A",X"88",X"10",X"F4",X"A5",X"8C",X"6A",
		X"6A",X"6A",X"29",X"C0",X"85",X"8D",X"A9",X"FF",X"85",X"D0",X"A5",X"63",X"29",X"02",X"F0",X"0A",
		X"A5",X"80",X"29",X"10",X"D0",X"04",X"A9",X"00",X"85",X"D0",X"BD",X"EB",X"38",X"85",X"8E",X"BD",
		X"EC",X"38",X"85",X"8F",X"A0",X"14",X"B1",X"8E",X"29",X"3F",X"05",X"8D",X"25",X"D0",X"99",X"86",
		X"09",X"88",X"10",X"F2",X"A5",X"63",X"29",X"02",X"F0",X"30",X"BD",X"FB",X"38",X"85",X"8E",X"BD",
		X"FC",X"38",X"85",X"8F",X"A0",X"07",X"B1",X"8E",X"29",X"3F",X"05",X"8D",X"99",X"CF",X"08",X"88",
		X"10",X"F4",X"BD",X"03",X"39",X"85",X"8E",X"BD",X"04",X"39",X"85",X"8F",X"A0",X"0A",X"B1",X"8E",
		X"29",X"3F",X"05",X"8D",X"99",X"0E",X"09",X"88",X"10",X"F4",X"60",X"A5",X"60",X"29",X"03",X"0A",
		X"85",X"D2",X"A5",X"61",X"29",X"02",X"4A",X"05",X"D2",X"0A",X"AA",X"60",X"A5",X"62",X"29",X"03",
		X"F0",X"0D",X"C9",X"03",X"F0",X"09",X"AE",X"00",X"20",X"E0",X"4C",X"F0",X"02",X"A9",X"00",X"0A",
		X"AA",X"60",X"0D",X"0B",X"39",X"04",X"20",X"0E",X"20",X"15",X"39",X"1F",X"39",X"18",X"20",X"2D",
		X"20",X"34",X"39",X"49",X"39",X"5B",X"39",X"5B",X"39",X"5B",X"39",X"6D",X"39",X"42",X"20",X"57",
		X"20",X"82",X"39",X"97",X"39",X"6C",X"20",X"7F",X"20",X"AA",X"39",X"C5",X"39",X"92",X"20",X"9A",
		X"20",X"CD",X"39",X"D5",X"39",X"A2",X"20",X"AD",X"20",X"E0",X"39",X"50",X"45",X"52",X"40",X"43",
		X"4F",X"49",X"4E",X"40",X"40",X"50",X"52",X"4F",X"40",X"4D",X"55",X"45",X"4E",X"5A",X"45",X"40",
		X"40",X"40",X"40",X"40",X"50",X"55",X"53",X"48",X"40",X"53",X"54",X"41",X"52",X"54",X"40",X"40",
		X"40",X"40",X"40",X"40",X"53",X"54",X"41",X"52",X"54",X"4B",X"4E",X"4F",X"45",X"50",X"46",X"45",
		X"40",X"44",X"52",X"55",X"45",X"43",X"4B",X"45",X"4E",X"50",X"52",X"45",X"50",X"41",X"52",X"45",
		X"40",X"46",X"4F",X"52",X"40",X"42",X"41",X"54",X"54",X"4C",X"45",X"40",X"42",X"45",X"52",X"45",
		X"54",X"54",X"40",X"5A",X"55",X"4D",X"40",X"4B",X"41",X"4D",X"50",X"46",X"40",X"40",X"40",X"40",
		X"40",X"49",X"4E",X"53",X"45",X"52",X"54",X"40",X"43",X"4F",X"49",X"4E",X"53",X"40",X"40",X"40",
		X"40",X"40",X"40",X"40",X"40",X"47",X"45",X"4C",X"44",X"40",X"41",X"55",X"53",X"57",X"45",X"52",
		X"46",X"45",X"4E",X"40",X"40",X"40",X"40",X"59",X"4F",X"55",X"40",X"48",X"41",X"56",X"45",X"40",
		X"40",X"40",X"43",X"52",X"45",X"44",X"49",X"54",X"53",X"40",X"53",X"49",X"45",X"40",X"48",X"41",
		X"42",X"45",X"4E",X"40",X"40",X"40",X"4B",X"52",X"45",X"44",X"49",X"54",X"45",X"09",X"09",X"0A",
		X"0A",X"07",X"07",X"0A",X"0A",X"40",X"31",X"40",X"43",X"4F",X"49",X"4E",X"40",X"31",X"40",X"4D",
		X"55",X"45",X"4E",X"5A",X"45",X"50",X"45",X"52",X"40",X"50",X"4C",X"41",X"59",X"45",X"52",X"40",
		X"50",X"52",X"4F",X"40",X"53",X"50",X"49",X"45",X"4C",X"45",X"52",X"F6",X"F6",X"F7",X"F9",X"FB",
		X"FD",X"00",X"03",X"05",X"07",X"09",X"0A",X"0A",X"0A",X"09",X"07",X"05",X"03",X"00",X"FD",X"FB",
		X"F9",X"F7",X"F6",X"F6",X"F6",X"F7",X"F9",X"FB",X"FD",X"F9",X"F9",X"FA",X"FB",X"FB",X"FC",X"FF",
		X"03",X"05",X"06",X"07",X"08",X"08",X"08",X"07",X"06",X"05",X"04",X"01",X"FD",X"FB",X"FB",X"FA",
		X"F9",X"00",X"02",X"04",X"05",X"06",X"07",X"07",X"07",X"06",X"05",X"04",X"02",X"FF",X"FD",X"FB",
		X"FA",X"F9",X"F8",X"F8",X"F8",X"F9",X"FA",X"FB",X"FD",X"DC",X"DD",X"DE",X"DB",X"DF",X"E0",X"E1",
		X"DE",X"DB",X"E2",X"E3",X"E1",X"DC",X"DC",X"E4",X"E5",X"DE",X"DB",X"E1",X"E3",X"DB",X"DD",X"DE",
		X"DB",X"E2",X"D4",X"C9",X"CD",X"C5",X"2A",X"28",X"28",X"28",X"28",X"28",X"28",X"28",X"28",X"2B",
		X"2B",X"29",X"29",X"29",X"29",X"29",X"29",X"29",X"29",X"29",X"29",X"2A",X"1B",X"1B",X"1B",X"1B",
		X"1B",X"1B",X"1B",X"1B",X"14",X"0A",X"15",X"0A",X"33",X"0A",X"34",X"0A",X"35",X"0A",X"53",X"0A",
		X"54",X"0A",X"72",X"0A",X"73",X"0A",X"74",X"0A",X"92",X"0A",X"93",X"0A",X"CC",X"08",X"EA",X"08",
		X"EB",X"08",X"EC",X"08",X"09",X"09",X"0A",X"09",X"0B",X"09",X"29",X"09",X"2A",X"09",X"2B",X"09",
		X"49",X"09",X"4A",X"09",X"4B",X"09",X"45",X"0B",X"46",X"0B",X"47",X"0B",X"48",X"0B",X"56",X"08",
		X"99",X"08",X"DA",X"08",X"FB",X"08",X"3C",X"09",X"5C",X"0A",X"9B",X"0A",X"BA",X"0A",X"F9",X"0A",
		X"17",X"0B",X"36",X"0B",X"4A",X"0B",X"2A",X"0B",X"E6",X"0A",X"A5",X"0A",X"84",X"0A",X"43",X"0A",
		X"23",X"09",X"E4",X"08",X"C5",X"08",X"86",X"08",X"49",X"08",X"82",X"09",X"A2",X"09",X"C2",X"09",
		X"E2",X"09",X"9D",X"09",X"BD",X"09",X"DD",X"09",X"FD",X"09",X"28",X"29",X"2A",X"2B",X"2C",X"2D",
		X"2E",X"2F",X"30",X"31",X"32",X"33",X"34",X"35",X"36",X"37",X"38",X"46",X"47",X"48",X"57",X"58",
		X"59",X"65",X"66",X"67",X"78",X"79",X"7A",X"7A",X"04",X"05",X"1A",X"1B",X"24",X"25",X"3A",X"3B",
		X"43",X"44",X"5B",X"5C",X"62",X"63",X"7C",X"7D",X"82",X"83",X"9C",X"9D",X"A2",X"BD",X"C2",X"DD",
		X"E2",X"FD",X"04",X"04",X"04",X"04",X"02",X"1D",X"22",X"3D",X"42",X"5D",X"62",X"63",X"7C",X"7D",
		X"82",X"83",X"9C",X"9D",X"A3",X"A4",X"BB",X"BC",X"C4",X"C5",X"DA",X"DB",X"E4",X"E5",X"FA",X"FB",
		X"02",X"02",X"02",X"02",X"05",X"06",X"07",X"18",X"19",X"1A",X"26",X"27",X"28",X"29",X"37",X"38",
		X"39",X"49",X"55",X"56",X"57",X"69",X"6A",X"6B",X"6C",X"6D",X"6E",X"6F",X"70",X"71",X"72",X"73",
		X"74",X"75",X"6A",X"3B",X"B8",X"20",X"D8",X"20",X"8A",X"3B",X"59",X"4F",X"55",X"52",X"40",X"53",
		X"43",X"4F",X"52",X"45",X"40",X"40",X"40",X"40",X"40",X"40",X"40",X"40",X"40",X"40",X"40",X"45",
		X"4E",X"45",X"4D",X"59",X"40",X"53",X"43",X"4F",X"52",X"45",X"45",X"49",X"47",X"4E",X"45",X"40",
		X"54",X"52",X"45",X"46",X"51",X"40",X"40",X"40",X"40",X"40",X"40",X"40",X"40",X"40",X"40",X"46",
		X"45",X"49",X"4E",X"44",X"40",X"54",X"52",X"45",X"46",X"51",X"08",X"08",X"08",X"38",X"03",X"08",
		X"08",X"08",X"48",X"08",X"07",X"08",X"04",X"48",X"04",X"08",X"08",X"80",X"07",X"48",X"08",X"80",
		X"80",X"80",X"80",X"80",X"80",X"80",X"80",X"80",X"80",X"07",X"38",X"08",X"01",X"80",X"80",X"08",
		X"18",X"08",X"08",X"06",X"28",X"08",X"08",X"08",X"08",X"08",X"04",X"03",X"08",X"08",X"04",X"48",
		X"80",X"08",X"06",X"07",X"80",X"80",X"80",X"80",X"80",X"80",X"80",X"80",X"80",X"80",X"03",X"05",
		X"68",X"13",X"80",X"80",X"08",X"10",X"20",X"30",X"3F",X"3F",X"00",X"00",X"00",X"00",X"00",X"00",
		X"20",X"10",X"08",X"04",X"02",X"02",X"0F",X"07",X"03",X"01",X"00",X"00",X"30",X"00",X"00",X"01",
		X"30",X"01",X"00",X"02",X"30",X"02",X"00",X"03",X"30",X"03",X"00",X"04",X"78",X"D8",X"A2",X"FF",
		X"9A",X"A9",X"00",X"85",X"00",X"85",X"6D",X"85",X"6F",X"24",X"26",X"10",X"2B",X"95",X"00",X"CA",
		X"30",X"FB",X"A9",X"55",X"85",X"8A",X"A9",X"AA",X"85",X"8B",X"20",X"40",X"3C",X"4C",X"F2",X"2A",
		X"A9",X"00",X"A2",X"00",X"9D",X"00",X"08",X"9D",X"00",X"09",X"9D",X"00",X"0A",X"E0",X"80",X"B0",
		X"03",X"9D",X"00",X"0B",X"CA",X"D0",X"ED",X"60",X"A0",X"01",X"A2",X"00",X"98",X"9D",X"00",X"08",
		X"C8",X"98",X"9D",X"00",X"09",X"C8",X"98",X"9D",X"00",X"0A",X"C8",X"98",X"9D",X"00",X"0B",X"88",
		X"88",X"E8",X"D0",X"E8",X"98",X"5D",X"00",X"08",X"9D",X"00",X"08",X"D0",X"2A",X"C8",X"98",X"5D",
		X"00",X"09",X"9D",X"00",X"09",X"D0",X"20",X"C8",X"98",X"5D",X"00",X"0A",X"9D",X"00",X"0A",X"D0",
		X"16",X"C8",X"98",X"5D",X"00",X"0B",X"9D",X"00",X"0B",X"D0",X"0C",X"88",X"88",X"E8",X"D0",X"D4",
		X"98",X"0A",X"A8",X"90",X"B5",X"B0",X"45",X"85",X"6A",X"85",X"68",X"85",X"64",X"85",X"66",X"85",
		X"61",X"85",X"63",X"A2",X"F0",X"86",X"95",X"A2",X"00",X"A0",X"00",X"C9",X"00",X"F0",X"FE",X"0A",
		X"90",X"0C",X"86",X"69",X"86",X"60",X"88",X"D0",X"F9",X"CA",X"D0",X"F6",X"F0",X"0C",X"86",X"65",
		X"86",X"67",X"86",X"62",X"88",X"D0",X"F7",X"CA",X"D0",X"F4",X"86",X"68",X"86",X"64",X"86",X"66",
		X"86",X"61",X"86",X"63",X"88",X"D0",X"F3",X"CA",X"D0",X"F0",X"F0",X"CB",X"85",X"6A",X"85",X"64",
		X"85",X"66",X"A2",X"0C",X"BD",X"C8",X"3F",X"09",X"C0",X"9D",X"89",X"08",X"CA",X"10",X"F5",X"A9",
		X"3F",X"85",X"8D",X"A0",X"03",X"A2",X"00",X"8A",X"85",X"8C",X"41",X"8C",X"C6",X"8C",X"D0",X"FA",
		X"C6",X"8D",X"88",X"10",X"F5",X"48",X"A5",X"8D",X"38",X"E9",X"1F",X"4A",X"4A",X"AA",X"68",X"5D",
		X"C0",X"3F",X"85",X"8E",X"D0",X"12",X"A5",X"8D",X"C9",X"28",X"B0",X"D7",X"C9",X"1F",X"F0",X"3F",
		X"A9",X"20",X"85",X"8D",X"A0",X"00",X"F0",X"CD",X"A2",X"00",X"8E",X"94",X"08",X"8E",X"95",X"08",
		X"29",X"0F",X"F0",X"17",X"A5",X"8D",X"38",X"E9",X"1D",X"4A",X"09",X"01",X"48",X"4A",X"AA",X"68",
		X"09",X"C0",X"9D",X"95",X"08",X"A5",X"8E",X"29",X"F0",X"F0",X"CB",X"A5",X"8D",X"38",X"E9",X"1B",
		X"4A",X"29",X"FE",X"48",X"4A",X"AA",X"CA",X"68",X"09",X"C0",X"9D",X"B5",X"08",X"30",X"B7",X"A9",
		X"F9",X"85",X"99",X"85",X"9B",X"85",X"9D",X"85",X"9F",X"85",X"69",X"A2",X"13",X"BD",X"D5",X"3F",
		X"9D",X"86",X"09",X"CA",X"10",X"F7",X"A2",X"09",X"BD",X"E9",X"3F",X"9D",X"6B",X"0A",X"CA",X"10",
		X"F7",X"A2",X"02",X"A0",X"9B",X"A9",X"00",X"85",X"95",X"95",X"61",X"B5",X"25",X"20",X"11",X"3E",
		X"9D",X"A6",X"09",X"B5",X"21",X"20",X"11",X"3E",X"9D",X"AC",X"09",X"24",X"02",X"20",X"11",X"3E",
		X"9D",X"B1",X"09",X"B5",X"20",X"49",X"80",X"20",X"11",X"3E",X"9D",X"B6",X"09",X"8A",X"9D",X"8B",
		X"0A",X"9D",X"91",X"0A",X"B5",X"05",X"10",X"11",X"20",X"13",X"3E",X"B5",X"04",X"10",X"06",X"98",
		X"9D",X"91",X"0A",X"D0",X"04",X"98",X"9D",X"8B",X"0A",X"CA",X"CA",X"30",X"04",X"A0",X"5B",X"10",
		X"B8",X"85",X"20",X"A2",X"03",X"A0",X"00",X"B5",X"60",X"49",X"03",X"48",X"29",X"01",X"09",X"F0",
		X"99",X"0B",X"09",X"68",X"29",X"02",X"4A",X"09",X"F0",X"C8",X"99",X"0B",X"09",X"C8",X"C8",X"CA",
		X"10",X"E5",X"24",X"24",X"10",X"FC",X"24",X"24",X"30",X"FC",X"A5",X"00",X"10",X"0F",X"4C",X"91",
		X"3D",X"30",X"08",X"95",X"60",X"A9",X"F0",X"85",X"95",X"98",X"60",X"8A",X"60",X"20",X"40",X"3C",
		X"85",X"68",X"85",X"6A",X"85",X"61",X"85",X"63",X"A9",X"00",X"85",X"95",X"85",X"91",X"85",X"93",
		X"A2",X"01",X"95",X"8C",X"95",X"8E",X"95",X"D0",X"CA",X"10",X"F7",X"A2",X"06",X"A9",X"F9",X"95",
		X"99",X"A9",X"00",X"95",X"90",X"95",X"98",X"CA",X"CA",X"10",X"F2",X"A4",X"D0",X"B9",X"7C",X"3E",
		X"85",X"8C",X"B9",X"7D",X"3E",X"85",X"8D",X"6C",X"8C",X"00",X"24",X"24",X"10",X"FC",X"24",X"24",
		X"30",X"FC",X"A5",X"00",X"2A",X"66",X"8E",X"A5",X"8E",X"C9",X"7F",X"D0",X"DE",X"20",X"40",X"3C",
		X"E6",X"D0",X"E6",X"D0",X"A5",X"D0",X"C9",X"11",X"90",X"D1",X"B0",X"A1",X"8E",X"3E",X"94",X"3E",
		X"A0",X"3E",X"DC",X"3E",X"0E",X"3F",X"51",X"3F",X"78",X"3F",X"92",X"3F",X"A8",X"3F",X"20",X"40",
		X"3C",X"4C",X"5A",X"3E",X"A2",X"00",X"8A",X"9D",X"00",X"08",X"E8",X"D0",X"F9",X"4C",X"5A",X"3E",
		X"A9",X"F3",X"8D",X"00",X"08",X"A9",X"00",X"85",X"99",X"85",X"9B",X"85",X"9D",X"85",X"9F",X"A9",
		X"20",X"85",X"98",X"A9",X"40",X"85",X"9A",X"A9",X"60",X"85",X"9C",X"A9",X"80",X"85",X"9E",X"A5",
		X"01",X"10",X"0C",X"E6",X"8F",X"D0",X"08",X"A5",X"91",X"49",X"80",X"85",X"91",X"85",X"93",X"A5",
		X"8F",X"85",X"90",X"85",X"92",X"85",X"94",X"85",X"96",X"4C",X"5A",X"3E",X"A9",X"F4",X"8D",X"00",
		X"08",X"A9",X"20",X"85",X"90",X"A9",X"40",X"85",X"92",X"A9",X"60",X"85",X"94",X"A9",X"80",X"85",
		X"96",X"A5",X"01",X"10",X"0C",X"E6",X"8F",X"D0",X"08",X"A5",X"91",X"49",X"80",X"85",X"91",X"85",
		X"93",X"A5",X"8F",X"85",X"98",X"85",X"9A",X"85",X"9C",X"85",X"9E",X"4C",X"5A",X"3E",X"A9",X"F5",
		X"8D",X"00",X"08",X"A9",X"20",X"85",X"90",X"85",X"98",X"A9",X"50",X"85",X"92",X"85",X"9A",X"A9",
		X"80",X"85",X"94",X"85",X"9C",X"85",X"91",X"85",X"93",X"A9",X"B0",X"85",X"96",X"85",X"9E",X"A5",
		X"01",X"10",X"11",X"E6",X"8F",X"30",X"0D",X"A9",X"E0",X"85",X"8F",X"A5",X"D1",X"49",X"01",X"18",
		X"69",X"04",X"85",X"D1",X"A5",X"D1",X"85",X"99",X"85",X"9B",X"85",X"9D",X"85",X"9F",X"4C",X"5A",
		X"3E",X"A9",X"F6",X"8D",X"00",X"08",X"A9",X"F9",X"85",X"99",X"85",X"9B",X"85",X"9D",X"85",X"9F",
		X"A5",X"01",X"10",X"02",X"E6",X"8F",X"24",X"8F",X"10",X"07",X"85",X"65",X"85",X"66",X"4C",X"5A",
		X"3E",X"85",X"67",X"85",X"64",X"4C",X"5A",X"3E",X"A9",X"F7",X"8D",X"00",X"08",X"85",X"64",X"85",
		X"66",X"A5",X"01",X"10",X"02",X"E6",X"8F",X"A5",X"8F",X"4A",X"4A",X"4A",X"4A",X"85",X"95",X"4C",
		X"5A",X"3E",X"A9",X"F8",X"8D",X"00",X"08",X"85",X"69",X"A5",X"01",X"10",X"02",X"E6",X"8F",X"A5",
		X"8F",X"29",X"F0",X"85",X"95",X"4C",X"5A",X"3E",X"A9",X"F9",X"8D",X"00",X"08",X"85",X"68",X"85",
		X"6B",X"A5",X"01",X"10",X"02",X"E6",X"8F",X"A5",X"8F",X"29",X"F0",X"85",X"95",X"4C",X"5A",X"3E",
		X"12",X"0F",X"34",X"56",X"78",X"9A",X"BC",X"DE",X"D2",X"C1",X"CD",X"00",X"CF",X"CB",X"00",X"D2",
		X"CF",X"CD",X"00",X"CF",X"CB",X"C6",X"C9",X"D2",X"C5",X"00",X"D3",X"D4",X"C1",X"D2",X"D4",X"00",
		X"D3",X"CC",X"C1",X"CD",X"00",X"C3",X"CF",X"C9",X"CE",X"CC",X"C5",X"C6",X"D4",X"00",X"D2",X"C9",
		X"C7",X"C8",X"D4",X"00",X"00",X"00",X"00",X"00",X"00",X"AA",X"EB",X"2C",X"1C",X"3C",X"1C",X"3C");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
