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
		X"00",X"0A",X"13",X"FF",X"00",X"26",X"07",X"ED",X"00",X"07",X"E0",X"37",X"00",X"37",X"07",X"E0",
		X"00",X"E0",X"37",X"07",X"00",X"C0",X"38",X"B7",X"00",X"E0",X"80",X"EC",X"00",X"F6",X"07",X"C0");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
