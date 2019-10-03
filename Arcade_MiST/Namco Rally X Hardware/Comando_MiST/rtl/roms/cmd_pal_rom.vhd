library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity cmd_pal_rom is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(4 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of cmd_pal_rom is
	type rom is array(0 to  31) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"00",X"A0",X"25",X"3F",X"07",X"A4",X"2D",X"5D",X"27",X"A7",X"E0",X"B7",X"20",X"84",X"7A",X"FF",
		X"00",X"3F",X"07",X"00",X"00",X"3F",X"07",X"00",X"00",X"3F",X"07",X"00",X"00",X"3F",X"07",X"00");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
