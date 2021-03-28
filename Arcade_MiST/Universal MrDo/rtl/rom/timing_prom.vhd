library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity timing_prom is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(4 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of timing_prom is
	type rom is array(0 to  31) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"06",X"06",X"0D",X"0D",X"13",X"13",X"1F",X"1F",X"07",X"07",X"87",X"27",X"27",X"27",X"A7",X"47",
		X"47",X"47",X"C7",X"67",X"67",X"67",X"E7",X"67",X"67",X"67",X"67",X"07",X"07",X"07",X"07",X"07");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
