library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity swimmer_big_sprite_palette is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(4 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of swimmer_big_sprite_palette is
	type rom is array(0 to  31) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"00",X"F0",X"17",X"27",X"FF",X"18",X"30",X"37",X"00",X"6F",X"1D",X"14",X"03",X"02",X"25",X"00",
		X"00",X"00",X"4D",X"4F",X"30",X"27",X"37",X"FF",X"00",X"94",X"47",X"97",X"98",X"4D",X"3F",X"00");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
