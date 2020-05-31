library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity col is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(4 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of col is
	type rom is array(0 to  31) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"00",X"AF",X"83",X"D2",X"1A",X"0F",X"8F",X"DB",X"24",X"32",X"3F",X"2C",X"00",X"57",X"AA",X"FF",
		X"00",X"C6",X"00",X"B4",X"24",X"26",X"7B",X"0F",X"5F",X"8F",X"1B",X"2F",X"3E",X"A8",X"AB",X"FF");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
