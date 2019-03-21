library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity cclimber_palette is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(5 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of cclimber_palette is
	type rom is array(0 to  63) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"80",X"F7",X"F7",X"F6",X"00",X"F4",X"01",X"01",X"00",X"31",X"07",X"00",X"00",X"7F",X"66",X"00",
		X"00",X"FA",X"F6",X"00",X"00",X"B8",X"00",X"3F",X"00",X"FC",X"B7",X"FA",X"00",X"4E",X"AF",X"00",
		X"00",X"00",X"9C",X"7E",X"00",X"00",X"9C",X"07",X"00",X"00",X"00",X"00",X"00",X"FF",X"BE",X"00",
		X"00",X"FA",X"76",X"00",X"00",X"87",X"87",X"00",X"00",X"B7",X"6F",X"00",X"00",X"FA",X"FA",X"07");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
