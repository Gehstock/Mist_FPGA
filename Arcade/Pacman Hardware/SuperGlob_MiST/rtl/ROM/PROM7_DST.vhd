library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity PROM7_DST is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(3 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of PROM7_DST is
	type rom is array(0 to  15) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"00",X"47",X"38",X"C8",X"E8",X"3F",X"C6",X"FF",X"9F",X"29",X"DF",X"37",X"86",X"1F",X"27",X"1D");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
