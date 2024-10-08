library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity b1 is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(10 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of b1 is
	type rom is array(0 to  2047) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"C3",X"E9",X"50",X"C3",X"60",X"51",X"C3",X"9B",X"50",X"C3",X"33",X"50",X"C3",X"C6",X"51",X"C3",
		X"B6",X"52",X"C3",X"53",X"53",X"C3",X"B4",X"53",X"C3",X"8E",X"54",X"C3",X"D1",X"54",X"00",X"00",
		X"00",X"C3",X"29",X"55",X"C3",X"AD",X"55",X"C3",X"1B",X"56",X"C3",X"6B",X"56",X"C3",X"2A",X"52",
		X"C3",X"CE",X"56",X"3A",X"12",X"20",X"E6",X"07",X"21",X"62",X"22",X"11",X"02",X"22",X"CA",X"67",
		X"50",X"11",X"22",X"22",X"3D",X"CA",X"67",X"50",X"11",X"42",X"22",X"3D",X"CA",X"67",X"50",X"EB",
		X"11",X"22",X"22",X"3D",X"CA",X"67",X"50",X"11",X"02",X"22",X"3D",X"CA",X"67",X"50",X"EB",X"11",
		X"22",X"22",X"3D",X"CA",X"67",X"50",X"C9",X"1A",X"96",X"D2",X"6E",X"50",X"2F",X"3C",X"FE",X"04",
		X"D0",X"23",X"13",X"1A",X"96",X"D2",X"7A",X"50",X"2F",X"3C",X"FE",X"04",X"D0",X"23",X"23",X"23",
		X"13",X"13",X"13",X"1A",X"AE",X"E6",X"80",X"C0",X"23",X"23",X"23",X"13",X"13",X"13",X"1A",X"AE",
		X"E6",X"80",X"C0",X"2B",X"2B",X"2B",X"7E",X"2F",X"3C",X"77",X"C9",X"3A",X"D7",X"20",X"B7",X"C8",
		X"3A",X"12",X"20",X"E6",X"03",X"21",X"10",X"22",X"CA",X"BF",X"50",X"3D",X"21",X"30",X"22",X"CA",
		X"BF",X"50",X"3D",X"21",X"50",X"22",X"CA",X"BF",X"50",X"21",X"70",X"22",X"C3",X"BF",X"50",X"7E",
		X"2F",X"23",X"B6",X"C0",X"7D",X"D6",X"0E",X"6F",X"7E",X"FE",X"D0",X"D2",X"D1",X"50",X"C6",X"16",
		X"77",X"2B",X"3A",X"47",X"20",X"D6",X"80",X"2F",X"3C",X"BE",X"DA",X"E4",X"50",X"7E",X"C6",X"10",
		X"77",X"C3",X"E8",X"50",X"7E",X"D6",X"10",X"77",X"C9",X"21",X"62",X"20",X"7E",X"B7",X"23",X"CA",
		X"15",X"51",X"DF",X"7E",X"11",X"40",X"51",X"CD",X"38",X"51",X"21",X"0E",X"20",X"86",X"FE",X"10",
		X"D8",X"77",X"0F",X"0F",X"E6",X"3E",X"C6",X"06",X"2B",X"77",X"3A",X"0E",X"20",X"0F",X"0F",X"E6",
		X"3F",X"32",X"0B",X"20",X"C9",X"3A",X"0E",X"20",X"FE",X"80",X"D0",X"34",X"3E",X"0F",X"BE",X"D2",
		X"23",X"51",X"77",X"11",X"50",X"51",X"CD",X"38",X"51",X"21",X"0E",X"20",X"86",X"FE",X"80",X"DA",
		X"34",X"51",X"3E",X"80",X"77",X"C3",X"02",X"51",X"83",X"D2",X"3D",X"51",X"14",X"5F",X"1A",X"C9",
		X"FF",X"FC",X"F8",X"F4",X"F4",X"F4",X"F4",X"F4",X"F4",X"F4",X"F4",X"F4",X"F4",X"F4",X"F4",X"F4",
		X"03",X"03",X"03",X"03",X"03",X"03",X"02",X"02",X"02",X"02",X"02",X"02",X"02",X"02",X"02",X"02",
		X"21",X"D8",X"20",X"3A",X"D7",X"20",X"B7",X"CA",X"84",X"51",X"DF",X"7E",X"11",X"B6",X"51",X"CD",
		X"38",X"51",X"21",X"0A",X"20",X"86",X"FE",X"B8",X"DA",X"7D",X"51",X"3E",X"B8",X"77",X"C6",X"08",
		X"32",X"0C",X"20",X"C9",X"7E",X"3C",X"E6",X"0F",X"C2",X"8D",X"51",X"3E",X"0F",X"77",X"11",X"A6",
		X"51",X"CD",X"38",X"51",X"21",X"0A",X"20",X"86",X"FE",X"40",X"D2",X"9F",X"51",X"3E",X"40",X"77",
		X"C6",X"10",X"32",X"0C",X"20",X"C9",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",
		X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"08",X"08",X"08",X"08",X"08",X"08",X"08",X"08",X"08",X"08",
		X"08",X"08",X"08",X"08",X"08",X"08",X"CD",X"CD",X"51",X"CD",X"62",X"52",X"C9",X"CD",X"2D",X"50",
		X"21",X"90",X"21",X"11",X"41",X"20",X"1A",X"FE",X"09",X"DA",X"DF",X"51",X"3E",X"09",X"12",X"B7",
		X"CA",X"06",X"52",X"7E",X"B7",X"C0",X"2F",X"77",X"23",X"77",X"23",X"77",X"21",X"FF",X"00",X"22",
		X"48",X"20",X"CD",X"38",X"55",X"21",X"E8",X"52",X"22",X"80",X"21",X"21",X"42",X"28",X"22",X"82",
		X"21",X"AF",X"32",X"FF",X"3F",X"C9",X"3A",X"3E",X"20",X"B7",X"23",X"C2",X"14",X"52",X"7E",X"B7",
		X"C0",X"2F",X"77",X"C9",X"23",X"7E",X"B7",X"C0",X"2F",X"77",X"CD",X"38",X"55",X"21",X"25",X"53",
		X"22",X"80",X"21",X"21",X"42",X"28",X"22",X"82",X"21",X"C9",X"21",X"3E",X"20",X"7E",X"B7",X"C8",
		X"DB",X"02",X"E6",X"04",X"CA",X"4F",X"52",X"7E",X"B7",X"1F",X"47",X"3E",X"00",X"17",X"77",X"23",
		X"23",X"23",X"7E",X"80",X"77",X"DB",X"02",X"E6",X"08",X"C8",X"7E",X"80",X"80",X"77",X"C9",X"46",
		X"36",X"00",X"23",X"23",X"23",X"7E",X"80",X"77",X"DB",X"02",X"E6",X"08",X"C8",X"7E",X"80",X"80",
		X"77",X"C9",X"3A",X"22",X"20",X"B7",X"C8",X"2A",X"48",X"20",X"CD",X"0F",X"50",X"22",X"48",X"20",
		X"C2",X"BF",X"52",X"DA",X"A1",X"52",X"3A",X"90",X"21",X"B7",X"C8",X"21",X"FF",X"FF",X"22",X"E0",
		X"21",X"DB",X"00",X"E6",X"40",X"C0",X"CD",X"17",X"5C",X"AF",X"21",X"90",X"21",X"77",X"23",X"77",
		X"23",X"77",X"32",X"01",X"20",X"2F",X"32",X"02",X"20",X"21",X"41",X"20",X"35",X"CD",X"12",X"50",
		X"C9",X"21",X"C9",X"52",X"22",X"80",X"21",X"21",X"A2",X"29",X"22",X"82",X"21",X"3E",X"07",X"32",
		X"E3",X"21",X"CD",X"14",X"5C",X"C9",X"7D",X"B4",X"C8",X"2B",X"7D",X"B4",X"C0",X"37",X"C9",X"2A",
		X"80",X"21",X"7D",X"B4",X"C0",X"CD",X"86",X"5A",X"C9",X"20",X"50",X"52",X"45",X"53",X"53",X"20",
		X"46",X"49",X"52",X"45",X"20",X"42",X"55",X"54",X"54",X"4F",X"4E",X"20",X"54",X"4F",X"20",X"42",
		X"45",X"47",X"49",X"4E",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"59",
		X"4F",X"55",X"20",X"48",X"41",X"56",X"45",X"20",X"43",X"52",X"45",X"44",X"49",X"54",X"20",X"20",
		X"20",X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",
		X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",
		X"20",X"20",X"20",X"20",X"FF",X"20",X"20",X"20",X"20",X"20",X"20",X"49",X"4E",X"53",X"45",X"52",
		X"54",X"20",X"53",X"45",X"43",X"4F",X"4E",X"44",X"20",X"43",X"4F",X"49",X"4E",X"20",X"20",X"20",
		X"20",X"20",X"20",X"FF",X"E0",X"EE",X"6E",X"20",X"2A",X"A2",X"E0",X"6E",X"A6",X"80",X"22",X"A2",
		X"E0",X"E2",X"6E",X"CD",X"38",X"55",X"3E",X"FF",X"32",X"22",X"20",X"32",X"D9",X"20",X"32",X"E2",
		X"21",X"32",X"7B",X"20",X"2A",X"74",X"20",X"22",X"7C",X"20",X"21",X"80",X"11",X"22",X"74",X"20",
		X"3E",X"20",X"32",X"E6",X"21",X"3E",X"05",X"32",X"E3",X"21",X"AF",X"32",X"C4",X"21",X"11",X"44",
		X"53",X"21",X"8E",X"24",X"0E",X"05",X"CD",X"EE",X"02",X"21",X"00",X"00",X"22",X"28",X"20",X"22",
		X"2E",X"20",X"AF",X"32",X"2A",X"20",X"32",X"30",X"20",X"3E",X"01",X"32",X"A0",X"21",X"21",X"90",
		X"07",X"F7",X"7C",X"32",X"39",X"20",X"AF",X"32",X"DE",X"22",X"32",X"EE",X"22",X"32",X"F1",X"22",
		X"32",X"F2",X"22",X"C9",X"CD",X"D7",X"53",X"21",X"35",X"20",X"EF",X"C0",X"36",X"3C",X"CD",X"E3",
		X"56",X"CD",X"4A",X"05",X"C0",X"AF",X"32",X"35",X"20",X"3A",X"22",X"20",X"B7",X"C8",X"21",X"03",
		X"20",X"36",X"00",X"23",X"36",X"FF",X"C9",X"3A",X"12",X"20",X"E6",X"07",X"FE",X"07",X"C0",X"CD",
		X"6F",X"57",X"01",X"A2",X"21",X"21",X"AE",X"21",X"EF",X"D2",X"F1",X"53",X"0A",X"E6",X"E3",X"02",
		X"C9",X"23",X"C2",X"F8",X"53",X"36",X"00",X"C9",X"EF",X"C0",X"36",X"04",X"0A",X"EE",X"0C",X"02",
		X"C9",X"10",X"20",X"30",X"40",X"21",X"11",X"22",X"CD",X"24",X"54",X"21",X"31",X"22",X"CD",X"24",
		X"54",X"21",X"51",X"22",X"CD",X"24",X"54",X"21",X"71",X"22",X"CD",X"24",X"54",X"21",X"31",X"23",
		X"CD",X"24",X"54",X"C9",X"3E",X"FF",X"BE",X"C8",X"7D",X"D6",X"06",X"6F",X"36",X"40",X"2B",X"36",
		X"D0",X"2B",X"36",X"01",X"2B",X"36",X"01",X"2B",X"36",X"01",X"C9",X"21",X"7D",X"23",X"EF",X"D0",
		X"21",X"A2",X"21",X"7E",X"E6",X"EF",X"77",X"C9",X"CD",X"3B",X"54",X"3A",X"12",X"20",X"E6",X"0F",
		X"C0",X"CD",X"E3",X"56",X"21",X"39",X"20",X"7E",X"36",X"00",X"B7",X"C2",X"61",X"54",X"36",X"AA",
		X"C9",X"CD",X"65",X"54",X"C9",X"CD",X"29",X"5C",X"21",X"7C",X"23",X"79",X"BE",X"D8",X"34",X"78",
		X"32",X"7D",X"23",X"21",X"A2",X"21",X"7E",X"F6",X"10",X"77",X"C9",X"3A",X"22",X"20",X"B7",X"C0",
		X"CD",X"E3",X"56",X"3A",X"89",X"21",X"B7",X"C0",X"3E",X"FF",X"32",X"8D",X"21",X"C9",X"CD",X"48",
		X"54",X"CD",X"D7",X"53",X"3A",X"50",X"23",X"B7",X"C0",X"CD",X"0A",X"48",X"CD",X"49",X"57",X"CD",
		X"7B",X"54",X"3A",X"8D",X"21",X"B7",X"C8",X"3A",X"22",X"20",X"B7",X"C8",X"3E",X"FF",X"32",X"50",
		X"23",X"32",X"C4",X"21",X"32",X"C5",X"21",X"CD",X"38",X"55",X"21",X"C7",X"54",X"22",X"80",X"21",
		X"21",X"0C",X"28",X"22",X"82",X"21",X"C9",X"47",X"41",X"4D",X"45",X"20",X"4F",X"56",X"45",X"52",
		X"FF",X"3A",X"50",X"23",X"B7",X"C8",X"3A",X"12",X"20",X"E6",X"0F",X"FE",X"04",X"C0",X"21",X"37",
		X"20",X"35",X"21",X"52",X"23",X"34",X"7E",X"FE",X"07",X"D8",X"21",X"51",X"23",X"34",X"FE",X"0A",
		X"D8",X"C2",X"0C",X"55",X"11",X"28",X"20",X"21",X"2E",X"20",X"CD",X"10",X"48",X"CD",X"15",X"55",
		X"2A",X"2B",X"20",X"22",X"2E",X"20",X"3A",X"2D",X"20",X"32",X"30",X"20",X"3A",X"52",X"23",X"FE",
		X"12",X"D8",X"C3",X"C9",X"01",X"21",X"2D",X"20",X"11",X"2A",X"20",X"CD",X"21",X"50",X"D8",X"11",
		X"2B",X"20",X"21",X"28",X"20",X"06",X"03",X"FF",X"C9",X"1A",X"BE",X"D8",X"C0",X"2B",X"1B",X"1A",
		X"BE",X"D8",X"C0",X"2B",X"1B",X"1A",X"BE",X"C9",X"21",X"00",X"00",X"22",X"C2",X"22",X"22",X"D2",
		X"22",X"22",X"E2",X"22",X"AF",X"32",X"D9",X"20",X"AF",X"32",X"18",X"23",X"32",X"19",X"23",X"21",
		X"03",X"22",X"06",X"E8",X"0E",X"FF",X"70",X"21",X"11",X"22",X"71",X"21",X"23",X"22",X"70",X"21",
		X"31",X"22",X"71",X"21",X"43",X"22",X"70",X"21",X"51",X"22",X"71",X"21",X"63",X"22",X"70",X"21",
		X"71",X"22",X"71",X"21",X"83",X"22",X"70",X"21",X"A3",X"22",X"70",X"21",X"A5",X"55",X"F7",X"22",
		X"E0",X"21",X"3E",X"07",X"32",X"E3",X"21",X"21",X"60",X"27",X"AF",X"0E",X"04",X"47",X"77",X"23",
		X"05",X"C2",X"8E",X"55",X"0D",X"C2",X"8D",X"55",X"AF",X"32",X"80",X"21",X"32",X"81",X"21",X"3E",
		X"FF",X"32",X"C5",X"21",X"C9",X"00",X"04",X"40",X"05",X"80",X"06",X"C0",X"07",X"3A",X"12",X"20",
		X"E6",X"03",X"FE",X"03",X"C0",X"11",X"A2",X"21",X"21",X"A9",X"21",X"EF",X"DA",X"D0",X"55",X"C8",
		X"1A",X"F6",X"01",X"12",X"CD",X"F4",X"55",X"21",X"AA",X"21",X"EF",X"D0",X"CD",X"19",X"48",X"C9",
		X"1A",X"E6",X"FE",X"12",X"23",X"36",X"00",X"CD",X"E1",X"55",X"21",X"80",X"11",X"22",X"74",X"20",
		X"C9",X"F5",X"21",X"7B",X"20",X"3E",X"FF",X"BE",X"CA",X"F2",X"55",X"77",X"2A",X"74",X"20",X"22",
		X"7C",X"20",X"F1",X"C9",X"21",X"AB",X"21",X"EF",X"C0",X"36",X"02",X"23",X"7E",X"2F",X"B7",X"77",
		X"CD",X"E1",X"55",X"21",X"80",X"11",X"CA",X"17",X"56",X"3A",X"6A",X"20",X"FE",X"78",X"21",X"C8",
		X"42",X"DA",X"17",X"56",X"21",X"48",X"41",X"22",X"74",X"20",X"C9",X"3A",X"12",X"20",X"E6",X"03",
		X"C0",X"21",X"CA",X"21",X"EF",X"C0",X"36",X"FF",X"23",X"34",X"7E",X"07",X"E6",X"06",X"21",X"63",
		X"56",X"85",X"D2",X"36",X"56",X"24",X"6F",X"5E",X"23",X"56",X"EB",X"7E",X"B7",X"C8",X"7D",X"D6",
		X"0D",X"6F",X"7E",X"FE",X"40",X"D8",X"23",X"23",X"23",X"3E",X"80",X"BE",X"DA",X"59",X"56",X"3E",
		X"02",X"BE",X"DA",X"57",X"56",X"36",X"03",X"35",X"C9",X"3E",X"FE",X"BE",X"D2",X"61",X"56",X"36",
		X"FD",X"34",X"C9",X"10",X"22",X"30",X"22",X"50",X"22",X"70",X"22",X"3A",X"01",X"20",X"B7",X"C0",
		X"CD",X"B6",X"56",X"3A",X"18",X"23",X"47",X"0E",X"0C",X"AF",X"81",X"05",X"C2",X"7A",X"56",X"47",
		X"21",X"1C",X"23",X"7E",X"90",X"E6",X"F8",X"D6",X"08",X"0F",X"0F",X"0F",X"E6",X"1F",X"5F",X"23",
		X"6E",X"2C",X"2C",X"2C",X"26",X"00",X"29",X"29",X"29",X"29",X"29",X"16",X"24",X"19",X"22",X"58",
		X"23",X"EB",X"D5",X"3A",X"2E",X"23",X"0F",X"CD",X"47",X"0F",X"D1",X"13",X"3A",X"2E",X"23",X"07",
		X"07",X"07",X"CD",X"47",X"0F",X"C9",X"2A",X"58",X"23",X"EB",X"D5",X"3E",X"0A",X"07",X"07",X"07",
		X"CD",X"47",X"0F",X"D1",X"3E",X"0A",X"07",X"07",X"07",X"13",X"CD",X"47",X"0F",X"C9",X"2A",X"8A",
		X"21",X"23",X"22",X"8A",X"21",X"11",X"C8",X"43",X"06",X"08",X"CD",X"0A",X"0E",X"3E",X"10",X"32",
		X"F4",X"21",X"C9",X"3A",X"50",X"23",X"B7",X"C0",X"3A",X"8C",X"21",X"FE",X"03",X"D0",X"47",X"DB",
		X"02",X"E6",X"30",X"FE",X"30",X"C8",X"C5",X"21",X"28",X"20",X"11",X"86",X"21",X"06",X"03",X"FF",
		X"11",X"86",X"21",X"21",X"2E",X"20",X"CD",X"10",X"48",X"C1",X"DB",X"02",X"E6",X"03",X"4F",X"07",
		X"07",X"07",X"81",X"4F",X"78",X"07",X"80",X"81",X"5F",X"16",X"00",X"21",X"D8",X"57",X"19",X"23",
		X"23",X"11",X"88",X"21",X"CD",X"21",X"50",X"D8",X"3A",X"89",X"21",X"3C",X"32",X"89",X"21",X"3A",
		X"8C",X"21",X"3C",X"32",X"8C",X"21",X"CD",X"30",X"50",X"21",X"AE",X"21",X"36",X"10",X"23",X"36",
		X"00",X"21",X"A2",X"21",X"3E",X"10",X"B6",X"77",X"C9",X"3A",X"EF",X"22",X"B7",X"C0",X"3A",X"43",
		X"22",X"C6",X"40",X"21",X"6B",X"20",X"96",X"DA",X"64",X"57",X"AF",X"32",X"F4",X"22",X"3E",X"02",
		X"32",X"E9",X"22",X"C9",X"3E",X"FF",X"32",X"F4",X"22",X"3E",X"04",X"32",X"E9",X"22",X"C9",X"21",
		X"F4",X"21",X"EF",X"C8",X"7E",X"E6",X"01",X"11",X"C8",X"43",X"CC",X"86",X"57",X"2A",X"8A",X"21",
		X"06",X"08",X"CD",X"0A",X"0E",X"C9",X"11",X"D0",X"43",X"C9",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"20",X"00",X"00",X"40",X"00",X"00",X"80",
		X"00",X"00",X"30",X"00",X"00",X"60",X"00",X"00",X"20",X"01",X"00",X"40",X"00",X"00",X"80",X"00",
		X"00",X"60",X"01",X"00",X"50",X"00",X"00",X"00",X"01",X"00",X"00",X"02",X"00",X"00",X"00",X"00");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
