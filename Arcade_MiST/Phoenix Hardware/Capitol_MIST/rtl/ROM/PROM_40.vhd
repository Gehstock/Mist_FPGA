library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity PROM_40 is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(10 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of PROM_40 is
	type rom is array(0 to  2047) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
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
		X"00",X"00",X"00",X"18",X"18",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"24",X"18",X"7E",X"18",X"24",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"F0",X"00",X"00",X"1F",X"00",X"00",X"F0",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"18",X"18",X"00",X"00",X"00",
		X"00",X"00",X"3C",X"3C",X"3C",X"3C",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"FF",
		X"00",X"00",X"26",X"05",X"2A",X"A4",X"50",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"FF",X"00",
		X"00",X"40",X"B4",X"19",X"85",X"52",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"FF",X"00",X"00",
		X"8D",X"17",X"00",X"44",X"08",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"FF",X"00",X"00",X"00",
		X"00",X"00",X"00",X"FF",X"00",X"00",X"00",X"00",X"00",X"00",X"10",X"08",X"04",X"40",X"0B",X"06",
		X"00",X"00",X"FF",X"00",X"00",X"00",X"00",X"00",X"57",X"A2",X"4C",X"04",X"10",X"00",X"00",X"00",
		X"00",X"FF",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"10",X"04",X"0C",X"02",X"52",X"BD",
		X"FF",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"FF",X"00",X"00",X"00",X"FF",X"00",X"00",X"00",X"00",X"00",X"C3",
		X"00",X"00",X"00",X"FF",X"00",X"00",X"00",X"00",X"00",X"FF",X"00",X"00",X"00",X"00",X"C3",X"00",
		X"00",X"00",X"FF",X"00",X"00",X"00",X"00",X"00",X"FF",X"00",X"00",X"00",X"00",X"C3",X"00",X"00",
		X"FF",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"FF",X"00",X"00",X"00",X"C3",X"00",X"00",X"00",
		X"00",X"00",X"00",X"C3",X"00",X"00",X"00",X"FF",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"FF",
		X"00",X"00",X"C3",X"00",X"00",X"00",X"00",X"FF",X"00",X"00",X"00",X"00",X"00",X"FF",X"00",X"00",
		X"00",X"C3",X"00",X"00",X"00",X"00",X"FF",X"00",X"00",X"00",X"00",X"00",X"FF",X"00",X"00",X"00",
		X"C3",X"00",X"00",X"00",X"00",X"00",X"FF",X"00",X"00",X"00",X"FF",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"FF",X"00",X"00",X"00",X"00",X"00",X"00",X"FF",X"00",
		X"00",X"00",X"00",X"00",X"00",X"FF",X"00",X"00",X"00",X"00",X"00",X"00",X"FF",X"00",X"00",X"00",
		X"00",X"00",X"00",X"FF",X"00",X"00",X"00",X"00",X"00",X"00",X"FF",X"00",X"00",X"00",X"00",X"00",
		X"00",X"FF",X"00",X"00",X"00",X"00",X"00",X"00",X"FF",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"03",X"0E",X"03",X"00",X"00",X"00",X"00",X"00",X"0E",X"00",X"00",
		X"00",X"00",X"03",X"0E",X"03",X"00",X"00",X"00",X"00",X"0E",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"30",X"E0",X"30",X"00",X"00",X"00",X"00",X"00",X"E0",X"00",X"00",
		X"00",X"00",X"30",X"E0",X"30",X"00",X"00",X"00",X"00",X"E0",X"00",X"00",X"00",X"00",X"00",X"00",
		X"0C",X"0C",X"80",X"80",X"0C",X"0C",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"80",X"80",X"0C",X"0C",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"0C",X"0C",
		X"0C",X"0C",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"0C",X"0C",X"80",X"80",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"0C",X"0C",X"80",X"80",X"0C",X"0C",
		X"30",X"30",X"00",X"00",X"30",X"30",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"30",X"30",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"30",X"30",
		X"30",X"30",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"30",X"30",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"30",X"30",X"00",X"00",X"30",X"30",
		X"06",X"0F",X"1F",X"1F",X"0F",X"06",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"1C",
		X"1F",X"1F",X"0F",X"06",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"06",X"0F",
		X"0F",X"06",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"06",X"0F",X"1F",X"1F",
		X"07",X"05",X"02",X"02",X"05",X"07",X"00",X"00",X"00",X"00",X"06",X"0F",X"1F",X"1F",X"0F",X"06",
		X"00",X"18",X"3C",X"3C",X"18",X"00",X"00",X"00",X"03",X"03",X"00",X"00",X"03",X"03",X"00",X"00",
		X"3C",X"3C",X"18",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"18",
		X"18",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"18",X"3C",X"3C",
		X"00",X"00",X"00",X"00",X"00",X"00",X"C0",X"C0",X"00",X"00",X"00",X"18",X"3C",X"3C",X"18",X"00",
		X"C0",X"C0",X"00",X"00",X"C0",X"C0",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"C0",X"C0",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"C0",X"C0",
		X"C0",X"C0",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"C0",X"C0",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"C0",X"C0",X"00",X"00",X"C0",X"C0",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"60",X"60",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"78",X"84",
		X"60",X"60",X"00",X"00",X"00",X"00",X"00",X"00",X"0E",X"09",X"01",X"01",X"09",X"0E",X"00",X"00",
		X"22",X"22",X"02",X"02",X"22",X"22",X"1C",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"60",X"60",
		X"07",X"0B",X"08",X"08",X"0B",X"87",X"84",X"78",X"00",X"00",X"00",X"00",X"60",X"60",X"00",X"00",
		X"03",X"03",X"00",X"00",X"03",X"03",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"00",X"00",X"03",X"03",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"03",X"03",
		X"03",X"03",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"03",X"03",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"03",X"03",X"00",X"00",X"03",X"03",
		X"00",X"30",X"00",X"00",X"30",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"82",X"82",X"B2",X"84",X"48",X"30",X"00",X"00",X"00",X"00",X"00",X"00",X"30",X"48",X"84",X"B2",
		X"B3",X"86",X"CC",X"78",X"30",X"00",X"00",X"00",X"00",X"30",X"78",X"CC",X"86",X"B3",X"83",X"83",
		X"48",X"30",X"00",X"00",X"00",X"00",X"00",X"00",X"30",X"48",X"84",X"82",X"82",X"82",X"82",X"84",
		X"00",X"C0",X"00",X"00",X"C0",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"20",X"20",X"20",X"40",X"80",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"80",X"40",X"20",
		X"CC",X"18",X"30",X"E0",X"C0",X"00",X"00",X"00",X"00",X"C0",X"E0",X"30",X"18",X"CC",X"0C",X"0C",
		X"80",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"80",X"40",X"20",X"20",X"20",X"20",X"40",
		X"00",X"0C",X"00",X"00",X"0C",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"30",X"60",X"C0",X"80",X"00",X"00",X"00",X"00",X"00",X"00",X"80",X"C0",X"60",X"30",X"30",X"30",
		X"0B",X"08",X"0C",X"07",X"03",X"00",X"00",X"00",X"00",X"03",X"07",X"0C",X"08",X"0B",X"08",X"08",
		X"00",X"00",X"08",X"10",X"22",X"14",X"00",X"00",X"00",X"00",X"1C",X"22",X"2A",X"02",X"14",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"10",X"08",X"12",X"69",X"2A",X"04",X"08",
		X"08",X"08",X"0B",X"08",X"04",X"03",X"00",X"00",X"00",X"00",X"00",X"00",X"03",X"04",X"08",X"0B",
		X"06",X"06",X"03",X"01",X"00",X"00",X"00",X"00",X"00",X"00",X"01",X"03",X"06",X"06",X"06",X"06",
		X"04",X"03",X"00",X"00",X"00",X"00",X"00",X"00",X"03",X"04",X"08",X"0B",X"08",X"08",X"0B",X"08",
		X"8C",X"6C",X"10",X"10",X"6C",X"8C",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
		X"10",X"10",X"2C",X"4C",X"80",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"8C",X"6C",
		X"4C",X"8C",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"8C",X"4C",X"20",X"20",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"80",X"4C",X"2C",X"10",X"10",X"6C",X"8C",
		X"E3",X"00",X"00",X"00",X"00",X"E3",X"1C",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"1C",
		X"E0",X"00",X"10",X"10",X"08",X"07",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"03",X"1C",
		X"CC",X"03",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"03",X"CC",X"30",X"30",
		X"00",X"10",X"0A",X"55",X"02",X"55",X"22",X"08",X"07",X"08",X"10",X"10",X"00",X"E0",X"1C",X"03",
		X"00",X"80",X"40",X"20",X"10",X"08",X"44",X"00",X"04",X"00",X"80",X"EA",X"80",X"01",X"A0",X"10",
		X"44",X"00",X"10",X"62",X"C0",X"80",X"08",X"20",X"12",X"09",X"20",X"04",X"80",X"42",X"00",X"20",
		X"97",X"15",X"0A",X"51",X"1B",X"24",X"0E",X"0B",X"24",X"80",X"28",X"80",X"04",X"04",X"01",X"2A",
		X"00",X"10",X"00",X"4C",X"0C",X"00",X"00",X"20",X"80",X"C0",X"42",X"80",X"21",X"62",X"E0",X"C0",
		X"00",X"4C",X"01",X"00",X"08",X"00",X"84",X"C0",X"00",X"00",X"00",X"20",X"02",X"40",X"08",X"00",
		X"06",X"0E",X"18",X"98",X"03",X"20",X"14",X"02",X"08",X"40",X"04",X"00",X"00",X"09",X"1C",X"30",
		X"00",X"00",X"04",X"00",X"04",X"0E",X"14",X"00",X"00",X"10",X"00",X"02",X"00",X"00",X"00",X"00",
		X"00",X"00",X"40",X"10",X"00",X"68",X"60",X"00",X"04",X"00",X"00",X"08",X"80",X"00",X"00",X"00",
		X"48",X"18",X"30",X"00",X"00",X"10",X"40",X"00",X"00",X"C0",X"E8",X"2C",X"0C",X"18",X"00",X"00",
		X"00",X"20",X"80",X"C0",X"00",X"DA",X"D0",X"80",X"20",X"C0",X"88",X"18",X"38",X"30",X"00",X"00",
		X"00",X"00",X"40",X"70",X"18",X"68",X"28",X"20",X"00",X"00",X"00",X"00",X"00",X"00",X"30",X"30",
		X"00",X"C0",X"40",X"00",X"00",X"00",X"00",X"18",X"14",X"A0",X"B0",X"3A",X"3C",X"1C",X"00",X"00",
		X"00",X"00",X"18",X"3C",X"36",X"62",X"00",X"00",X"20",X"60",X"60",X"E0",X"D0",X"20",X"80",X"00",
		X"80",X"8C",X"4C",X"4C",X"8C",X"18",X"40",X"40",X"00",X"80",X"E0",X"60",X"30",X"30",X"10",X"00",
		X"33",X"3C",X"0C",X"01",X"01",X"00",X"20",X"80",X"00",X"02",X"06",X"4C",X"0E",X"27",X"10",X"00",
		X"40",X"00",X"83",X"03",X"16",X"24",X"00",X"00",X"00",X"68",X"60",X"02",X"10",X"00",X"00",X"00",
		X"1C",X"1E",X"00",X"03",X"00",X"00",X"10",X"00",X"08",X"00",X"24",X"26",X"26",X"17",X"03",X"00",
		X"00",X"02",X"00",X"01",X"01",X"1A",X"10",X"04",X"0C",X"0E",X"27",X"20",X"30",X"18",X"80",X"40",
		X"00",X"40",X"00",X"18",X"1A",X"26",X"2C",X"0C",X"01",X"1E",X"3F",X"3E",X"1F",X"0F",X"02",X"01",
		X"20",X"10",X"08",X"24",X"00",X"41",X"00",X"00",X"0E",X"39",X"FC",X"FF",X"3B",X"28",X"98",X"22",
		X"01",X"00",X"02",X"00",X"08",X"40",X"31",X"CE",X"76",X"3C",X"08",X"00",X"93",X"60",X"0C",X"03",
		X"11",X"00",X"38",X"04",X"02",X"40",X"E0",X"60",X"00",X"18",X"21",X"9C",X"34",X"62",X"00",X"0C",
		X"00",X"00",X"30",X"46",X"4E",X"1C",X"00",X"00",X"00",X"00",X"00",X"30",X"1C",X"00",X"81",X"00",
		X"20",X"00",X"00",X"30",X"19",X"00",X"40",X"00",X"00",X"01",X"00",X"98",X"18",X"00",X"00",X"00");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
