library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity jng_pal_rom is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(4 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of jng_pal_rom is
	type rom is array(0 to  31) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"00",X"07",X"38",X"3C",X"3F",X"8C",X"E0",X"27",X"AA",X"8C",X"1F",X"B6",X"C0",X"C7",X"F8",X"FE",
		X"00",X"3F",X"FE",X"67",X"00",X"3F",X"FE",X"67",X"00",X"3F",X"FE",X"67",X"00",X"3F",X"FE",X"67");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
