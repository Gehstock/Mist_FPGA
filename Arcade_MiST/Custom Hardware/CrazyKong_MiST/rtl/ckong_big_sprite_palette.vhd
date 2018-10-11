library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity ckong_big_sprite_palette is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(4 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of ckong_big_sprite_palette is
	type rom is array(0 to  31) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"00",X"FF",X"18",X"C0",X"00",X"FF",X"C6",X"8F",X"00",X"16",X"27",X"2F",X"00",X"FF",X"C0",X"67",
		X"00",X"47",X"7F",X"88",X"00",X"88",X"47",X"7F",X"00",X"7F",X"88",X"47",X"00",X"40",X"08",X"FF");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
