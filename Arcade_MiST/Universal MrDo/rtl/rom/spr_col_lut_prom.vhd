library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity spr_col_lut_prom is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(4 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of spr_col_lut_prom is
	type rom is array(0 to  31) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"00",X"97",X"71",X"F9",X"00",X"27",X"A5",X"13",X"00",X"32",X"77",X"3F",X"00",X"A7",X"72",X"F9",
		X"00",X"1F",X"9A",X"77",X"00",X"15",X"27",X"38",X"00",X"C2",X"55",X"69",X"00",X"7F",X"76",X"7A");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
