library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity ROM_LUT is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(4 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of ROM_LUT is
	type rom is array(0 to  31) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"00",X"D4",X"5B",X"05",X"00",X"FF",X"17",X"07",X"00",X"29",X"FE",X"1F",X"00",X"4F",X"89",X"3F",
		X"00",X"97",X"6F",X"38",X"00",X"7B",X"87",X"E8",X"00",X"B8",X"1C",X"C0",X"00",X"0F",X"3C",X"85");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
