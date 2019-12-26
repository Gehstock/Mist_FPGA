library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity ORBITRON_6L is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(4 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of ORBITRON_6L is
	type rom is array(0 to  31) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"00",X"7A",X"36",X"07",X"00",X"F0",X"38",X"1F",X"00",X"C7",X"F0",X"3F",X"00",X"DB",X"C6",X"38",
		X"00",X"36",X"07",X"F0",X"00",X"33",X"3F",X"DB",X"00",X"3F",X"57",X"C6",X"00",X"C6",X"3F",X"FF");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
