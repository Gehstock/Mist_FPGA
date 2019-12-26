library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity MRDONIGHTMARE_6L is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(4 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of MRDONIGHTMARE_6L is
	type rom is array(31 downto 0) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"C6",X"07",X"76",X"00",X"C0",X"80",X"1E",X"00",X"80",X"C0",X"1E",X"00",X"76",X"C0",X"F6",X"00",
		X"07",X"C4",X"C0",X"00",X"A4",X"07",X"F6",X"00",X"F6",X"07",X"C0",X"00",X"F6",X"21",X"1E",X"00");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;

        
