library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity ckong_palette is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(5 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of ckong_palette is
	type rom is array(0 to  63) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"00",X"79",X"04",X"87",X"00",X"B7",X"FF",X"5F",X"00",X"C0",X"E8",X"F4",X"00",X"3F",X"04",X"38",
		X"00",X"0D",X"7A",X"B7",X"00",X"07",X"26",X"02",X"00",X"27",X"16",X"30",X"00",X"B7",X"F4",X"0C",
		X"00",X"4F",X"F6",X"24",X"00",X"B6",X"FF",X"5F",X"00",X"33",X"00",X"B7",X"00",X"66",X"00",X"3A",
		X"00",X"C0",X"3F",X"B7",X"00",X"20",X"F4",X"16",X"00",X"FF",X"7F",X"87",X"00",X"B6",X"F4",X"C0");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
