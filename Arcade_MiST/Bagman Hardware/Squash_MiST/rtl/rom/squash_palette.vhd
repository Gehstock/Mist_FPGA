library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity squash_palette is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(5 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of squash_palette is
	type rom is array(0 to  63) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"00",X"18",X"2D",X"FF",X"00",X"F0",X"1D",X"AF",X"00",X"3F",X"1D",X"AF",X"00",X"1D",X"3E",X"07",
		X"00",X"FF",X"1D",X"AF",X"00",X"1D",X"FF",X"2D",X"00",X"C0",X"31",X"07",X"00",X"00",X"00",X"00",
		X"00",X"00",X"00",X"00",X"00",X"2D",X"18",X"07",X"00",X"18",X"29",X"FF",X"00",X"F0",X"29",X"FF",
		X"00",X"18",X"2D",X"07",X"00",X"F0",X"E0",X"FC",X"00",X"07",X"3F",X"31",X"00",X"18",X"2D",X"FF");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
