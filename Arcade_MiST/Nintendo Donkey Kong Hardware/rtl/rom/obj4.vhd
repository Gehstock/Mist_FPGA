library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity obj4 is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(10 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of obj4 is
	type rom is array(0 to  2047) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"00",X"00",X"00",X"FF",X"FF",X"E7",X"E5",X"E8",X"BF",X"FF",X"FF",X"39",X"00",X"00",X"00",X"00",
		X"00",X"06",X"8F",X"9F",X"FD",X"FC",X"F8",X"B8",X"F8",X"FC",X"FC",X"BC",X"5C",X"3C",X"00",X"00",
		X"1E",X"1C",X"1C",X"1C",X"FC",X"FC",X"F8",X"FB",X"FF",X"FF",X"1D",X"18",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"F0",X"FE",X"FF",X"FF",X"FF",X"F7",X"FB",X"F8",X"F8",X"F8",X"60",X"00",X"00",
		X"00",X"80",X"C0",X"F0",X"FE",X"FF",X"FF",X"BF",X"FF",X"F3",X"F0",X"E0",X"80",X"00",X"00",X"00",
		X"80",X"80",X"F0",X"F8",X"FC",X"FE",X"FE",X"DE",X"44",X"C0",X"C0",X"C0",X"80",X"80",X"00",X"00",
		X"00",X"C0",X"C0",X"FD",X"FF",X"FF",X"FF",X"FB",X"FB",X"FF",X"FF",X"FF",X"FD",X"C0",X"C0",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"1F",X"FF",X"FF",X"FD",X"F8",X"BF",X"FF",X"FF",X"39",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"FF",X"FF",X"FF",X"FD",X"F8",X"FF",X"FF",X"FF",X"F9",X"C0",X"00",X"00",X"00",
		X"00",X"06",X"0F",X"1F",X"FD",X"FC",X"F8",X"F8",X"B8",X"FC",X"7C",X"1C",X"1C",X"3C",X"00",X"00",
		X"00",X"06",X"0F",X"1F",X"FD",X"FC",X"F8",X"F8",X"F8",X"FC",X"FC",X"DC",X"1C",X"1C",X"00",X"00",
		X"1E",X"1C",X"1C",X"1C",X"FC",X"FC",X"F8",X"FB",X"FF",X"DF",X"FD",X"38",X"00",X"00",X"00",X"00",
		X"1E",X"1C",X"1C",X"1C",X"FC",X"FC",X"F8",X"FB",X"FF",X"FF",X"FD",X"78",X"00",X"00",X"00",X"00",
		X"04",X"0C",X"18",X"9C",X"CE",X"FF",X"FF",X"FE",X"DC",X"FC",X"FC",X"7C",X"4C",X"CC",X"4C",X"1C",
		X"80",X"80",X"00",X"F8",X"FC",X"FE",X"FE",X"BF",X"FF",X"FF",X"FE",X"9F",X"0F",X"06",X"0C",X"00",
		X"00",X"80",X"80",X"A0",X"83",X"81",X"E1",X"D3",X"FF",X"6F",X"0E",X"0E",X"1F",X"36",X"25",X"00",
		X"00",X"00",X"00",X"E0",X"E0",X"E0",X"E0",X"E0",X"C0",X"C0",X"80",X"80",X"00",X"00",X"00",X"00",
		X"00",X"00",X"80",X"80",X"80",X"C0",X"C0",X"C0",X"C0",X"C0",X"C0",X"C0",X"C0",X"40",X"00",X"00",
		X"00",X"40",X"C0",X"E0",X"E0",X"E0",X"E0",X"E0",X"E0",X"E0",X"E0",X"E0",X"E0",X"C0",X"40",X"00",
		X"60",X"E0",X"E0",X"E0",X"F0",X"E0",X"C0",X"C0",X"E0",X"E0",X"C0",X"00",X"00",X"00",X"80",X"80",
		X"00",X"00",X"C0",X"E0",X"F0",X"F0",X"F8",X"78",X"B8",X"F8",X"F0",X"F0",X"E0",X"C0",X"00",X"00",
		X"E0",X"00",X"F0",X"F8",X"F8",X"F8",X"F8",X"F8",X"F8",X"F8",X"F8",X"F8",X"F8",X"F0",X"00",X"E0",
		X"E0",X"00",X"F0",X"F8",X"F8",X"F8",X"F8",X"F8",X"F8",X"F8",X"F8",X"F8",X"F8",X"F0",X"00",X"E0",
		X"00",X"00",X"00",X"F8",X"FC",X"FD",X"FD",X"FD",X"FD",X"FD",X"FD",X"FC",X"F8",X"00",X"00",X"00",
		X"00",X"00",X"C0",X"E0",X"70",X"B0",X"58",X"B8",X"B8",X"38",X"70",X"F0",X"E0",X"C0",X"00",X"00",
		X"E0",X"00",X"F0",X"F8",X"F8",X"F8",X"F8",X"F8",X"F8",X"F8",X"F8",X"F8",X"F8",X"F0",X"00",X"E0",
		X"E0",X"00",X"F0",X"F8",X"F8",X"F8",X"F8",X"F8",X"F8",X"F8",X"F8",X"F8",X"F8",X"F0",X"00",X"E0",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"80",X"00",X"80",X"8F",X"80",X"80",X"80",X"00",X"00",X"00",X"00",X"00",
		X"40",X"42",X"48",X"44",X"42",X"00",X"00",X"00",X"00",X"00",X"78",X"02",X"42",X"0A",X"14",X"02",
		X"CC",X"E6",X"EF",X"C3",X"E7",X"E7",X"E7",X"C3",X"F7",X"F7",X"E7",X"C3",X"E7",X"F6",X"E6",X"FC",
		X"CC",X"E6",X"EF",X"C3",X"E7",X"E7",X"E7",X"C3",X"F7",X"F7",X"E7",X"C3",X"E7",X"F6",X"E6",X"FC",
		X"CC",X"E6",X"EF",X"C3",X"E7",X"E7",X"E7",X"C3",X"F7",X"F7",X"E7",X"C3",X"E7",X"F6",X"E6",X"FC",
		X"E0",X"D8",X"B8",X"BC",X"BC",X"BC",X"BC",X"BC",X"BC",X"BC",X"BC",X"BC",X"B8",X"D8",X"E0",X"E0",
		X"D0",X"F8",X"D8",X"8C",X"DC",X"FC",X"DC",X"8C",X"DC",X"FC",X"DC",X"8C",X"D8",X"F8",X"D8",X"F0",
		X"00",X"00",X"40",X"80",X"80",X"C0",X"00",X"80",X"C0",X"80",X"C0",X"80",X"80",X"40",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"04",X"04",X"04",X"04",X"08",X"0C",X"0C",X"14",X"1C",X"1C",X"0C",
		X"01",X"03",X"07",X"E3",X"07",X"05",X"03",X"03",X"03",X"07",X"05",X"03",X"06",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"40",X"80",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"E0",
		X"0E",X"1A",X"1D",X"18",X"00",X"10",X"30",X"30",X"60",X"40",X"80",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"03",X"3C",X"60",X"C0",X"80",X"00",X"00",X"00",X"00",X"01",X"03",X"E0",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"40",X"E0",X"70",X"B0",X"F8",X"18",X"00",
		X"00",X"00",X"00",X"00",X"00",X"78",X"FE",X"33",X"07",X"81",X"83",X"03",X"03",X"01",X"00",X"00",
		X"03",X"07",X"03",X"03",X"05",X"07",X"07",X"03",X"00",X"0C",X"0E",X"5E",X"FF",X"FF",X"CF",X"C6",
		X"00",X"00",X"00",X"00",X"00",X"60",X"E0",X"E0",X"E0",X"E0",X"C0",X"C1",X"83",X"87",X"07",X"03",
		X"00",X"01",X"07",X"3C",X"C0",X"00",X"00",X"00",X"00",X"00",X"FC",X"07",X"01",X"00",X"00",X"00",
		X"00",X"00",X"C0",X"60",X"30",X"1C",X"3E",X"7E",X"F6",X"EE",X"DC",X"DC",X"DC",X"D8",X"D0",X"60",
		X"40",X"80",X"00",X"00",X"00",X"42",X"33",X"07",X"07",X"07",X"07",X"07",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"80",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"80",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"60",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"40",X"60",X"20",X"20",X"20",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"0C",X"0E",X"0F",X"0F",X"0F",X"07",X"07",X"03",X"03",X"01",X"00",X"00",X"00",X"00",
		X"00",X"00",X"10",X"70",X"70",X"F0",X"F0",X"F0",X"F0",X"E0",X"C0",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"00",X"00",X"80",X"40",X"E0",X"30",X"18",X"54",X"54",X"18",X"30",X"E0",X"40",X"80",X"00",X"00",
		X"20",X"50",X"70",X"50",X"D8",X"88",X"88",X"04",X"04",X"88",X"88",X"D8",X"50",X"70",X"50",X"20",
		X"00",X"00",X"00",X"78",X"FE",X"86",X"03",X"73",X"7B",X"3B",X"33",X"86",X"FE",X"3C",X"00",X"00",
		X"00",X"80",X"78",X"FC",X"86",X"03",X"71",X"F9",X"F9",X"79",X"7B",X"32",X"86",X"FC",X"38",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"14",X"64",X"EB",X"03",X"94",X"A7",X"6F",X"35",X"05",X"2A",X"30",X"0C",X"02",X"00",
		X"00",X"80",X"F6",X"38",X"0F",X"3D",X"CF",X"84",X"5B",X"07",X"01",X"8F",X"7C",X"38",X"08",X"00",
		X"0C",X"13",X"3D",X"F4",X"C9",X"07",X"1C",X"18",X"70",X"9E",X"23",X"04",X"EC",X"9E",X"25",X"CC",
		X"00",X"0D",X"04",X"FE",X"83",X"0E",X"BC",X"BC",X"78",X"9C",X"8F",X"87",X"7B",X"9D",X"01",X"44",
		X"10",X"10",X"10",X"10",X"10",X"10",X"10",X"10",X"10",X"10",X"10",X"10",X"10",X"10",X"10",X"10",
		X"00",X"54",X"00",X"7C",X"7C",X"5C",X"4C",X"64",X"54",X"6C",X"74",X"7C",X"7C",X"00",X"54",X"00",
		X"00",X"00",X"00",X"FF",X"44",X"44",X"44",X"44",X"44",X"44",X"44",X"44",X"FF",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"01",X"FF",X"F7",X"FF",X"F7",X"F7",X"FF",X"F7",X"F7",X"FF",X"F7",X"F7",X"FF",X"01",X"FE",X"01",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"E0",X"F0",X"F0",X"F0",X"F0",X"70",X"F0",X"F0",X"F0",X"70",X"F0",X"F0",X"70",X"F0",X"F0",X"60",
		X"00",X"30",X"58",X"08",X"A0",X"C0",X"F8",X"DE",X"8F",X"57",X"0B",X"2D",X"04",X"08",X"00",X"00",
		X"70",X"DA",X"EC",X"36",X"D3",X"21",X"01",X"81",X"C1",X"E3",X"E6",X"C6",X"0E",X"7C",X"BC",X"00",
		X"20",X"F0",X"68",X"34",X"F6",X"02",X"03",X"E1",X"F1",X"F1",X"F1",X"E1",X"83",X"66",X"BE",X"1C",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"80",X"C0",X"E0",X"E0",X"E0",X"E0",X"C0",X"80",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"80",X"C0",X"E0",X"E0",X"E0",X"E0",X"C0",X"80",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"80",X"C0",X"E0",X"E0",X"E0",X"E0",X"C0",X"80",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"C0",X"E0",X"30",X"18",X"0C",X"0C",X"0C",X"0C",X"0C",X"0C",X"18",X"30",X"E0",X"C0",X"00",
		X"00",X"00",X"00",X"80",X"C0",X"60",X"30",X"30",X"30",X"30",X"60",X"C0",X"80",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"80",X"C0",X"60",X"60",X"C0",X"80",X"00",X"00",X"00",X"00",X"00",
		X"00",X"84",X"88",X"90",X"20",X"00",X"00",X"00",X"1C",X"00",X"00",X"20",X"90",X"88",X"84",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"FE",X"02",X"02",X"02",X"02",X"02",X"02",X"02",X"02",X"02",X"02",X"02",X"02",X"FE",X"00",
		X"04",X"0E",X"8C",X"CC",X"EE",X"EE",X"EE",X"EE",X"EC",X"EC",X"6C",X"0E",X"0E",X"0E",X"04",X"00",
		X"00",X"00",X"00",X"00",X"DE",X"3E",X"7E",X"7E",X"7E",X"7E",X"7E",X"3E",X"DE",X"00",X"00",X"00",
		X"80",X"00",X"00",X"00",X"80",X"00",X"04",X"02",X"FC",X"00",X"00",X"80",X"00",X"00",X"00",X"80",
		X"00",X"C0",X"E0",X"F0",X"F0",X"F8",X"FC",X"FE",X"FC",X"F8",X"F0",X"F0",X"E0",X"C0",X"00",X"00",
		X"00",X"C0",X"E0",X"F0",X"F0",X"F8",X"F4",X"E0",X"4A",X"1C",X"B8",X"F0",X"F0",X"E0",X"C0",X"00",
		X"38",X"BC",X"9C",X"DC",X"FC",X"BC",X"F8",X"F8",X"F8",X"FC",X"BE",X"FE",X"DE",X"8C",X"8C",X"00",
		X"E0",X"F0",X"50",X"08",X"6C",X"CC",X"A0",X"FE",X"FE",X"F8",X"D0",X"FB",X"FF",X"FF",X"3E",X"0C",
		X"5E",X"3F",X"07",X"05",X"09",X"7B",X"01",X"3D",X"7F",X"7F",X"BF",X"FF",X"FF",X"F0",X"F8",X"70",
		X"C0",X"20",X"20",X"20",X"C0",X"00",X"C0",X"20",X"20",X"20",X"C0",X"00",X"20",X"E0",X"20",X"00",
		X"C0",X"20",X"20",X"C0",X"00",X"C0",X"20",X"20",X"C0",X"00",X"20",X"20",X"A0",X"60",X"20",X"00",
		X"C0",X"20",X"20",X"C0",X"00",X"C0",X"20",X"20",X"C0",X"00",X"C0",X"20",X"20",X"20",X"20",X"00",
		X"C0",X"20",X"20",X"C0",X"00",X"C0",X"20",X"20",X"C0",X"00",X"C0",X"20",X"20",X"20",X"40",X"00",
		X"C0",X"20",X"20",X"C0",X"00",X"C0",X"20",X"20",X"C0",X"00",X"C0",X"20",X"20",X"20",X"C0",X"00");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;