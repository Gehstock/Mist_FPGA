library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity guzzler_big_sprite_palette is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(4 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of guzzler_big_sprite_palette is
	type rom is array(0 to  31) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"00",X"38",X"FF",X"37",X"24",X"25",X"2E",X"2F",X"00",X"38",X"FF",X"37",X"F0",X"86",X"07",X"00",
		X"00",X"00",X"07",X"87",X"C0",X"F0",X"37",X"FF",X"00",X"00",X"05",X"87",X"00",X"F0",X"37",X"FF");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
