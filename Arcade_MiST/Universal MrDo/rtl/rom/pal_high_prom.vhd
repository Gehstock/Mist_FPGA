library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity pal_high_prom is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(4 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of pal_high_prom is
	type rom is array(0 to  31) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"00",X"0C",X"03",X"00",X"0F",X"0B",X"0C",X"3F",X"0D",X"0F",X"0F",X"0C",X"0C",X"3C",X"0C",X"30",
		X"0C",X"03",X"30",X"03",X"0C",X"0F",X"00",X"3F",X"03",X"1E",X"00",X"0F",X"37",X"36",X"0D",X"33");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
