library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity loc_pal_rom is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(4 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of loc_pal_rom is
	type rom is array(0 to  31) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"00",X"07",X"A0",X"97",X"67",X"3F",X"7D",X"38",X"F0",X"A8",X"C0",X"18",X"5E",X"A8",X"1B",X"FF",
		X"00",X"FF",X"B7",X"00",X"00",X"FF",X"B7",X"00",X"00",X"FF",X"B7",X"00",X"00",X"FF",X"B7",X"00");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
