library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity time_pilot_palette_blue_green is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(4 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of time_pilot_palette_blue_green is
	type rom is array(0 to  31) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"00",X"00",X"05",X"06",X"07",X"FC",X"05",X"BD",X"B5",X"FD",X"05",X"B0",X"A5",X"E0",X"00",X"F7",
		X"00",X"00",X"F8",X"07",X"07",X"FD",X"F8",X"FA",X"05",X"DE",X"50",X"51",X"32",X"FD",X"30",X"F7");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
