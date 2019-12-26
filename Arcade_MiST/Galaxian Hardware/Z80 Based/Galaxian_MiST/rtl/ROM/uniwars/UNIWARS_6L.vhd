library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity UNIWARS_6L is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(4 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of UNIWARS_6L is
	type rom is array(0 to  31) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"00",X"E8",X"17",X"3F",X"00",X"2F",X"87",X"20",X"00",X"FF",X"3F",X"38",X"00",X"83",X"3F",X"06",
		X"00",X"DC",X"1F",X"D0",X"00",X"EF",X"20",X"96",X"00",X"3F",X"17",X"F0",X"00",X"3F",X"17",X"14");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
