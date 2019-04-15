library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity bagman_palette is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(5 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of bagman_palette is
	type rom is array(0 to  63) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"00",X"3F",X"FF",X"F0",X"00",X"36",X"29",X"1D",X"00",X"36",X"1D",X"FF",X"00",X"FF",X"07",X"29",
		X"00",X"07",X"3C",X"F0",X"00",X"FF",X"8F",X"FA",X"00",X"07",X"38",X"30",X"00",X"2F",X"F7",X"3F",
		X"00",X"3F",X"07",X"C0",X"00",X"00",X"3F",X"38",X"00",X"00",X"00",X"E8",X"00",X"00",X"00",X"06",
		X"00",X"2F",X"4F",X"FF",X"00",X"00",X"00",X"3D",X"00",X"00",X"00",X"26",X"00",X"00",X"00",X"FC");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
