library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity ROM_LUT is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(4 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of ROM_LUT is
	type rom is array(0 to  31) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"00",X"F6",X"07",X"F0",X"00",X"80",X"3F",X"C7",X"00",X"FF",X"07",X"27",X"00",X"FF",X"C9",X"39",
		X"00",X"3C",X"17",X"F0",X"00",X"27",X"29",X"FF",X"00",X"C7",X"17",X"F6",X"00",X"C7",X"39",X"3F");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
