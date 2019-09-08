library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity sbagman_palette is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(5 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of sbagman_palette is
	type rom is array(0 to  63) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"00",X"07",X"3F",X"C0",X"00",X"07",X"3F",X"C0",X"00",X"07",X"38",X"EA",X"00",X"FB",X"C7",X"3E",
		X"00",X"07",X"EA",X"FF",X"00",X"0F",X"8F",X"FA",X"00",X"07",X"27",X"F0",X"00",X"2F",X"F7",X"A7",
		X"00",X"2F",X"4F",X"FF",X"00",X"07",X"3F",X"C0",X"00",X"17",X"27",X"E8",X"00",X"07",X"1F",X"FF",
		X"00",X"27",X"EA",X"FF",X"00",X"3D",X"FF",X"E8",X"00",X"38",X"38",X"38",X"00",X"26",X"1D",X"FC");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
