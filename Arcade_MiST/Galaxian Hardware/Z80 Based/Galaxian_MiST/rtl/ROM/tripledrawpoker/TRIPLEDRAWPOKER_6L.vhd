library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity TRIPLEDRAWPOKER_6L is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(4 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of TRIPLEDRAWPOKER_6L is
	type rom is array(0 to  31) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"C0",X"07",X"FF",X"00",X"00",X"07",X"FF",X"C0",X"00",X"3F",X"07",X"C0",X"00",X"17",X"3F",X"C0",
		X"00",X"C7",X"3F",X"C0",X"00",X"38",X"3F",X"C0",X"00",X"3F",X"17",X"C0",X"00",X"07",X"F8",X"C0");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
