library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity snd2 is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(10 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of snd2 is
	type rom is array(0 to  2047) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"C0",X"F0",X"F0",X"F8",X"38",X"7C",X"3C",X"7A",X"38",X"D1",X"E1",X"E1",X"E1",X"E0",X"E2",X"F0",
		X"F1",X"D1",X"DC",X"4E",X"9E",X"0F",X"0F",X"1E",X"1E",X"0E",X"1E",X"1E",X"1A",X"58",X"E1",X"E1",
		X"C0",X"F0",X"F0",X"F8",X"38",X"7C",X"3C",X"7A",X"38",X"D1",X"E1",X"E1",X"E1",X"E0",X"E2",X"F0",
		X"F1",X"D1",X"DC",X"4E",X"9E",X"0F",X"0F",X"1E",X"1E",X"0E",X"1E",X"1E",X"1A",X"58",X"E1",X"E1",
		X"C0",X"F0",X"F0",X"F8",X"38",X"7C",X"3C",X"7A",X"38",X"D1",X"E1",X"E1",X"E1",X"E0",X"E2",X"F0",
		X"F1",X"D1",X"DC",X"4E",X"9E",X"0F",X"0F",X"1E",X"1E",X"0E",X"1E",X"1E",X"1A",X"58",X"E1",X"E1",
		X"C0",X"F0",X"F0",X"F8",X"38",X"7C",X"3C",X"7A",X"38",X"D1",X"E1",X"E1",X"E1",X"E0",X"E2",X"F0",
		X"F1",X"D1",X"DC",X"4E",X"9E",X"0F",X"0F",X"1E",X"1E",X"0E",X"1E",X"1E",X"1A",X"58",X"E1",X"E1",
		X"1E",X"0E",X"3E",X"8F",X"27",X"0C",X"DC",X"38",X"7C",X"78",X"38",X"EC",X"6C",X"7C",X"78",X"70",
		X"CC",X"78",X"78",X"70",X"F8",X"78",X"78",X"78",X"78",X"66",X"B8",X"E4",X"E1",X"E0",X"E6",X"63",
		X"1E",X"0E",X"3E",X"8F",X"27",X"0C",X"DC",X"38",X"7C",X"78",X"38",X"EC",X"6C",X"7C",X"78",X"70",
		X"CC",X"78",X"78",X"70",X"F8",X"78",X"78",X"78",X"78",X"66",X"B8",X"E4",X"E1",X"E0",X"E6",X"63",
		X"1E",X"0E",X"3E",X"8F",X"27",X"0C",X"DC",X"38",X"7C",X"78",X"38",X"EC",X"6C",X"7C",X"78",X"70",
		X"CC",X"78",X"78",X"70",X"F8",X"78",X"78",X"78",X"78",X"66",X"B8",X"E4",X"E1",X"E0",X"E6",X"63",
		X"1E",X"0E",X"3E",X"8F",X"27",X"0C",X"DC",X"38",X"7C",X"78",X"38",X"EC",X"6C",X"7C",X"78",X"70",
		X"CC",X"78",X"78",X"70",X"F8",X"78",X"78",X"78",X"78",X"66",X"B8",X"E4",X"E1",X"E0",X"E6",X"63",
		X"1E",X"47",X"13",X"93",X"C6",X"E5",X"70",X"73",X"3C",X"1C",X"67",X"1F",X"19",X"E0",X"E2",X"78",
		X"CC",X"3E",X"39",X"1E",X"0E",X"63",X"8B",X"91",X"F0",X"E3",X"38",X"EC",X"73",X"1C",X"4E",X"33",
		X"1E",X"47",X"13",X"93",X"C6",X"E5",X"70",X"73",X"3C",X"1C",X"67",X"1F",X"19",X"E0",X"E2",X"78",
		X"CC",X"3E",X"39",X"1E",X"0E",X"63",X"8B",X"91",X"F0",X"E3",X"38",X"EC",X"73",X"1C",X"4E",X"33",
		X"1E",X"47",X"13",X"93",X"C6",X"E5",X"70",X"73",X"3C",X"1C",X"67",X"1F",X"19",X"E0",X"E2",X"78",
		X"CC",X"3E",X"39",X"1E",X"0E",X"63",X"8B",X"91",X"F0",X"E3",X"38",X"EC",X"73",X"1C",X"4E",X"33",
		X"1E",X"47",X"13",X"93",X"C6",X"E5",X"70",X"73",X"3C",X"1C",X"67",X"1F",X"19",X"E0",X"E2",X"78",
		X"CC",X"3E",X"39",X"1E",X"0E",X"63",X"8B",X"91",X"F0",X"E3",X"38",X"EC",X"73",X"1C",X"4E",X"33",
		X"E4",X"E2",X"E4",X"E4",X"D3",X"53",X"55",X"8D",X"53",X"33",X"33",X"34",X"D5",X"4D",X"55",X"35",
		X"8D",X"4D",X"55",X"4D",X"33",X"35",X"4D",X"33",X"34",X"D5",X"55",X"4D",X"94",X"CD",X"33",X"33",
		X"E4",X"E2",X"E4",X"E4",X"D3",X"53",X"55",X"8D",X"53",X"33",X"33",X"34",X"D5",X"4D",X"55",X"35",
		X"8D",X"4D",X"55",X"4D",X"33",X"35",X"4D",X"33",X"34",X"D5",X"55",X"4D",X"94",X"CD",X"33",X"33",
		X"E4",X"E2",X"E4",X"E4",X"D3",X"53",X"55",X"8D",X"53",X"33",X"33",X"34",X"D5",X"4D",X"55",X"35",
		X"8D",X"4D",X"55",X"4D",X"33",X"35",X"4D",X"33",X"34",X"D5",X"55",X"4D",X"94",X"CD",X"33",X"33",
		X"E4",X"E2",X"E4",X"E4",X"D3",X"53",X"55",X"8D",X"53",X"33",X"33",X"34",X"D5",X"4D",X"55",X"35",
		X"8D",X"4D",X"55",X"4D",X"33",X"35",X"4D",X"33",X"34",X"D5",X"55",X"4D",X"94",X"CD",X"33",X"33",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"55",X"55",X"55",X"56",X"66",X"66",X"66",X"66",X"66",
		X"66",X"55",X"65",X"55",X"56",X"66",X"66",X"66",X"59",X"99",X"99",X"99",X"95",X"55",X"55",X"66",
		X"65",X"66",X"66",X"66",X"66",X"59",X"59",X"59",X"59",X"59",X"59",X"59",X"96",X"56",X"59",X"59",
		X"66",X"56",X"66",X"66",X"66",X"66",X"55",X"55",X"95",X"56",X"59",X"99",X"99",X"99",X"95",X"99",
		X"99",X"99",X"99",X"99",X"99",X"59",X"59",X"99",X"96",X"66",X"56",X"55",X"99",X"99",X"A6",X"96",
		X"56",X"59",X"56",X"66",X"66",X"66",X"99",X"96",X"66",X"59",X"96",X"95",X"95",X"4D",X"93",X"66",
		X"65",X"99",X"66",X"59",X"59",X"39",X"39",X"56",X"59",X"5A",X"56",X"5A",X"5A",X"69",X"5A",X"59",
		X"64",X"E4",X"CD",X"4C",X"E4",X"E6",X"66",X"69",X"6A",X"66",X"A6",X"63",X"4D",X"4B",X"4D",X"59",
		X"59",X"9A",X"56",X"36",X"36",X"36",X"97",X"27",X"25",X"8E",X"8D",X"8A",X"CD",X"4D",X"4C",X"D6",
		X"65",X"A6",X"A6",X"66",X"64",X"D5",X"35",X"36",X"56",X"CE",X"4D",X"4A",X"6A",X"9B",X"26",X"26",
		X"36",X"DD",X"CC",X"88",X"89",X"22",X"CB",X"DD",X"DD",X"CA",X"92",X"46",X"65",X"95",X"65",X"96",
		X"65",X"95",X"95",X"4C",X"D3",X"4D",X"59",X"56",X"66",X"66",X"66",X"66",X"56",X"35",X"55",X"59",
		X"99",X"99",X"99",X"66",X"59",X"99",X"99",X"96",X"59",X"96",X"66",X"66",X"66",X"56",X"56",X"66",
		X"59",X"99",X"96",X"66",X"53",X"55",X"9A",X"65",X"99",X"94",X"D9",X"99",X"55",X"99",X"99",X"59",
		X"99",X"55",X"99",X"99",X"55",X"66",X"65",X"95",X"99",X"99",X"59",X"99",X"8D",X"99",X"99",X"56",
		X"65",X"96",X"59",X"59",X"95",X"66",X"66",X"59",X"66",X"65",X"55",X"9A",X"4D",X"56",X"64",X"D3",
		X"00",X"66",X"4E",X"56",X"99",X"53",X"9A",X"4E",X"4D",X"A9",X"54",X"DD",X"33",X"1D",X"C9",X"93",
		X"3D",X"49",X"25",X"E4",X"92",X"5E",X"48",X"95",X"E4",X"89",X"DD",X"44",X"BB",X"31",X"25",X"E4",
		X"46",X"5E",X"44",X"65",X"E4",X"45",X"5D",X"84",X"55",X"D8",X"45",X"67",X"61",X"16",X"76",X"12",
		X"6A",X"E1",X"4C",X"CF",X"21",X"A9",X"7A",X"1B",X"27",X"61",X"6C",X"9E",X"8D",X"98",X"E8",X"DC",
		X"C1",X"47",X"EC",X"09",X"FD",X"81",X"1F",X"E2",X"01",X"FF",X"02",X"1F",X"E0",X"C1",X"FE",X"0C",
		X"1F",X"C0",X"A0",X"FF",X"07",X"07",X"F0",X"70",X"7F",X"07",X"07",X"F0",X"70",X"7F",X"23",X"83",
		X"F0",X"38",X"3F",X"83",X"C3",X"F2",X"1C",X"3F",X"21",X"E0",X"FC",X"8E",X"0F",X"C0",X"F0",X"7F",
		X"07",X"83",X"F0",X"3C",X"3F",X"03",X"C3",X"F8",X"1E",X"1F",X"80",X"F0",X"FE",X"07",X"87",X"E0",
		X"78",X"3F",X"03",X"E1",X"F8",X"1E",X"0F",X"C0",X"F0",X"FC",X"07",X"8F",X"E0",X"3C",X"3F",X"03",
		X"C3",X"F8",X"1E",X"0F",X"C0",X"F8",X"7C",X"27",X"C3",X"E0",X"1E",X"3F",X"80",X"F0",X"FC",X"07",
		X"87",X"F0",X"3C",X"3F",X"01",X"E1",X"FC",X"0F",X"0F",X"C0",X"7C",X"3E",X"0B",X"E1",X"F0",X"0F",
		X"1F",X"80",X"F8",X"7C",X"13",X"C3",X"F0",X"1F",X"1F",X"80",X"78",X"FC",X"13",X"C3",X"F0",X"1E",
		X"0F",X"C0",X"F8",X"FC",X"07",X"C3",X"F0",X"1E",X"1F",X"84",X"F0",X"7C",X"27",X"C3",X"E0",X"1E",
		X"3F",X"01",X"F0",X"FC",X"0F",X"87",X"E0",X"3C",X"3F",X"01",X"E1",X"F8",X"1F",X"0F",X"C0",X"F8",
		X"7C",X"13",X"C3",X"F0",X"1E",X"1F",X"81",X"F0",X"FC",X"07",X"87",X"F0",X"1E",X"1F",X"09",X"F0",
		X"F8",X"07",X"8F",X"E0",X"78",X"3F",X"03",X"E1",X"F0",X"1E",X"1F",X"88",X"F0",X"FC",X"07",X"87",
		X"00",X"E2",X"38",X"3F",X"03",X"E1",X"F8",X"1E",X"1F",X"80",X"F0",X"FE",X"07",X"87",X"E1",X"38",
		X"1F",X"83",X"E1",X"F8",X"1E",X"0F",X"C0",X"F0",X"FC",X"0D",X"87",X"F0",X"78",X"3F",X"07",X"83",
		X"F0",X"3C",X"3F",X"03",X"C1",X"F8",X"9C",X"1F",X"81",X"E0",X"FC",X"1E",X"0F",X"C4",X"F0",X"FC",
		X"0F",X"07",X"C0",X"F8",X"7E",X"07",X"07",X"E2",X"78",X"7E",X"07",X"87",X"E0",X"3C",X"3F",X"03",
		X"C3",X"F0",X"3C",X"3F",X"03",X"C3",X"F0",X"3C",X"3F",X"03",X"C3",X"F0",X"2C",X"3F",X"22",X"C3",
		X"E2",X"2C",X"3F",X"06",X"C3",X"E2",X"3C",X"3F",X"21",X"C3",X"E4",X"78",X"3E",X"05",X"C7",X"E0",
		X"78",X"7E",X"05",X"87",X"E4",X"38",X"7E",X"0B",X"0F",X"C8",X"70",X"FC",X"87",X"1F",X"81",X"61",
		X"F9",X"0E",X"1F",X"83",X"C1",X"F2",X"3C",X"3E",X"23",X"87",X"E4",X"38",X"7C",X"87",X"0F",X"98",
		X"71",X"F9",X"0E",X"1F",X"81",X"C3",X"F0",X"5C",X"3E",X"21",X"87",X"E6",X"38",X"7C",X"47",X"0F",
		X"88",X"71",X"F9",X"0E",X"1F",X"11",X"C3",X"E6",X"1C",X"7C",X"87",X"0F",X"98",X"E1",X"F1",X"0E",
		X"3E",X"23",X"87",X"C8",X"38",X"FC",X"47",X"8F",X"80",X"E3",X"E2",X"1E",X"3E",X"23",X"87",X"8C",
		X"71",X"F0",X"C7",X"1E",X"31",X"C3",X"C7",X"1C",X"78",X"E1",X"8F",X"1C",X"71",X"E3",X"C6",X"1C",
		X"71",X"C7",X"87",X"18",X"F1",X"C7",X"1E",X"1C",X"63",X"C7",X"9C",X"70",X"79",X"8E",X"1E",X"75",
		X"C1",X"C7",X"3C",X"38",X"C7",X"87",X"1A",X"F0",X"E3",X"1E",X"1E",X"27",X"83",X"8D",X"78",X"38",
		X"AF",X"0E",X"33",X"E0",X"E2",X"7C",X"38",X"7F",X"07",X"07",X"E0",X"E0",X"FC",X"3C",X"1F",X"87",
		X"07",X"E0",X"71",X"FC",X"1C",X"1F",X"81",X"8B",X"F0",X"70",X"FE",X"0E",X"0F",X"C1",X"C3",X"F8",
		X"0F",X"38",X"3F",X"07",X"0F",X"C1",X"C1",X"FC",X"1C",X"3F",X"07",X"0F",X"E0",X"71",X"BC",X"1C",
		X"1F",X"83",X"87",X"E2",X"61",X"FC",X"0E",X"3F",X"03",X"87",X"E0",X"61",X"FC",X"5C",X"3B",X"13",
		X"86",X"E2",X"71",X"9C",X"4E",X"1F",X"19",X"8E",X"70",X"38",X"FC",X"27",X"39",X"C0",X"E3",X"71",
		X"B8",X"EE",X"07",X"1B",X"8D",X"C6",X"71",X"38",X"CC",X"66",X"3B",X"8C",X"C7",X"71",X"B8",X"CC",
		X"27",X"39",X"C0",X"E7",X"71",X"B8",X"CC",X"63",X"39",X"88",X"E7",X"71",X"19",X"CC",X"67",X"3B",
		X"88",X"C6",X"72",X"39",X"9C",X"C6",X"73",X"19",X"CC",X"62",X"73",X"B8",X"9C",X"6E",X"27",X"1D",
		X"88",X"CE",X"63",X"39",X"9C",X"8E",X"76",X"31",X"1B",X"C4",X"4E",X"73",X"13",X"9D",X"88",X"E7",
		X"62",X"3B",X"99",X"8E",X"C4",X"83",X"FB",X"01",X"FC",X"88",X"EE",X"62",X"3B",X"D8",X"1D",X"E6",
		X"07",X"79",X"83",X"BC",X"C0",X"EF",X"B0",X"37",X"9C",X"0D",X"E7",X"03",X"7B",X"80",X"DF",X"60",
		X"37",X"DC",X"04",X"FE",X"03",X"7B",X"C0",X"6F",X"78",X"0D",X"EE",X"07",X"77",X"81",X"CE",X"C6",
		X"3B",X"3C",X"13",X"BB",X"03",X"5D",X"86",X"37",X"26",X"65",X"D8",X"CB",X"24",X"E6",X"38",X"CE",
		X"67",X"64",X"D3",X"32",X"64",X"FB",X"26",X"61",X"BB",X"24",X"ED",X"99",X"99",X"39",X"16",X"72",
		X"4E",X"33",X"32",X"73",X"96",X"66",X"66",X"33",X"66",X"36",X"66",X"39",X"A6",X"71",X"98",X"9C",
		X"DD",X"91",X"99",X"99",X"B1",X"4C",X"E3",X"33",X"33",X"38",X"CC",X"CB",X"31",X"CC",X"E6",X"64",
		X"59",X"93",X"33",X"99",X"8B",X"33",X"8C",X"CB",X"1C",X"CC",X"C9",X"9C",X"CC",X"C9",X"9D",X"8C",
		X"66",X"CD",X"33",X"8C",X"E9",X"99",X"93",X"99",X"99",X"99",X"33",X"98",X"E6",X"66",X"2C",X"E0",
		X"00",X"00",X"00",X"AB",X"35",X"4C",X"65",X"9A",X"D9",X"8C",X"A6",X"B6",X"69",X"24",X"CD",X"B6",
		X"65",X"29",X"AD",X"B2",X"62",X"4C",X"DD",X"98",X"C9",X"9B",X"5B",X"32",X"8C",X"6D",X"B9",X"A4",
		X"99",X"B7",X"64",X"44",X"57",X"76",X"C9",X"25",X"77",X"6A",X"28",X"99",X"EE",X"D4",X"44",X"B5",
		X"D9",X"88",X"46",X"EB",X"99",X"89",X"99",X"EE",X"53",X"19",X"9C",X"F6",X"22",X"26",X"D9",X"98",
		X"C4",X"6E",X"F6",X"93",X"33",X"39",X"C8",X"85",X"76",X"79",X"26",X"31",X"76",X"C4",X"C6",X"76",
		X"7A",X"22",X"25",X"B3",X"91",X"85",X"CD",X"E9",X"14",X"CC",X"E6",X"64",X"67",X"37",X"A6",X"32",
		X"73",X"B3",X"42",X"9D",X"9B",X"33",X"19",X"99",X"C9",X"86",X"EE",X"B3",X"31",X"93",X"99",X"98",
		X"CE",X"CC",X"C6",X"66",X"67",X"32",X"33",X"BB",X"94",X"CC",X"99",X"CC",X"C4",X"F6",X"EA",X"66",
		X"62",X"76",X"31",X"4F",X"B4",X"4B",X"13",X"33",X"B0",X"9D",X"B9",X"13",X"66",X"33",X"63",X"3B",
		X"39",X"0D",X"60",X"B6",X"66",X"27",X"E9",X"33",X"31",X"B3",X"91",X"9C",X"E1",X"33",X"A4",X"F9",
		X"4C",X"6E",X"33",X"91",X"9D",X"98",X"EC",X"E5",X"36",X"27",X"33",X"19",X"B8",X"33",X"49",X"D8",
		X"C6",X"EE",X"98",X"9C",X"4E",X"62",X"67",X"8C",X"C8",X"D9",X"C4",X"EE",X"33",X"13",X"93",X"89",
		X"9E",X"61",X"9E",X"CD",X"66",X"71",X"46",X"76",X"63",X"33",X"C8",X"4F",X"26",X"53",X"3C",X"C1",
		X"E4",X"EC",X"67",X"D0",X"7C",X"1B",X"99",X"E1",X"1E",X"0D",X"C6",X"7C",X"0F",X"86",X"C3",X"F8",
		X"0F",X"07",X"C2",X"FC",X"0F",X"0D",X"C3",X"F0",X"1E",X"1B",X"8F",X"C0",X"E4",X"2E",X"37",X"83",
		X"B1",X"B8",X"DC",X"0B",X"85",X"C2",X"F0",X"3C",X"3E",X"17",X"81",X"E1",X"71",X"F8",X"1E",X"1B",
		X"0F",X"8D",X"C1",X"E1",X"B8",X"DC",X"1E",X"1B",X"8D",X"C1",X"E1",X"B8",X"D8",X"2E",X"33",X"1F",
		X"83",X"63",X"E3",X"30",X"D8",X"EE",X"37",X"07",X"8D",X"C6",X"E0",X"71",X"38",X"F8",X"4C",X"2F",
		X"33",X"83",X"8D",X"8E",X"E2",X"72",X"71",X"BC",X"1C",X"9C",X"6E",X"0E",X"67",X"1B",X"83",X"39",
		X"CD",X"C1",X"CC",X"E2",X"70",X"F2",X"63",X"B8",X"73",X"38",X"D8",X"39",X"9C",X"CE",X"1E",X"CC",
		X"67",X"1C",X"67",X"1B",X"86",X"37",X"19",X"C7",X"19",X"CC",X"C3",X"8C",X"E3",X"70",X"E6",X"71",
		X"B8",X"71",X"39",X"CC",X"1C",X"CE",X"67",X"0E",X"27",X"1B",X"87",X"19",X"8E",X"E1",X"C4",X"E3",
		X"78",X"78",X"3C",X"DC",X"1E",X"66",X"3B",X"83",X"9D",X"8C",X"E0",X"F0",X"F1",X"B8",X"38",X"DE",
		X"36",X"0F",X"0B",X"86",X"E1",X"F0",X"78",X"DC",X"1E",X"17",X"19",X"C1",X"E2",X"71",X"BC",X"1E",
		X"27",X"9B",X"C0",X"F0",X"78",X"FC",X"0F",X"07",X"89",X"E2",X"70",X"9C",X"7E",X"07",X"89",X"C6",
		X"F0",X"3C",X"4E",X"37",X"C0",X"E3",X"71",X"9E",X"43",X"89",X"E3",X"70",X"5C",X"27",X"0B",X"E1",
		X"98",X"9E",X"37",X"82",X"71",X"38",X"DF",X"04",X"E6",X"61",X"3E",X"33",X"0D",X"C3",X"78",X"53",
		X"13",X"8E",X"F1",X"1C",X"93",X"1D",X"E0",X"B1",X"46",X"7B",X"89",X"32",X"8D",X"3B",X"84",X"94",
		X"C5",X"9C",X"E2",X"4C",X"67",X"AE",X"72",X"22",X"4E",X"6F",X"9A",X"14",X"62",X"CF",X"7B",X"21",
		X"42",X"36",X"EF",X"64",X"98",X"C6",X"6E",X"F6",X"98",X"C2",X"2C",X"EF",X"34",X"91",X"11",X"5B",
		X"7A",X"D1",X"24",X"49",X"B6",X"E7",X"24",X"92",X"46",X"DD",X"DA",X"49",X"32",X"4A",X"CF",X"59",
		X"25",X"2A",X"56",X"77",X"35",X"14",X"AA",X"99",X"B7",X"35",X"25",X"2A",X"65",X"AD",X"B5",X"30");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;