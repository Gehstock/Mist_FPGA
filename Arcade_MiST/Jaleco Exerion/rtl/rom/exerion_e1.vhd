library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity exerion_e1 is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(4 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of exerion_e1 is
	type rom is array(0 to  31) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"00",X"06",X"1D",X"24",X"2B",X"30",X"68",X"A0",X"98",X"C0",X"83",X"84",X"45",X"AD",X"6B",X"9B",
		X"00",X"07",X"16",X"3F",X"34",X"38",X"F5",X"F8",X"E0",X"C0",X"C6",X"87",X"46",X"FF",X"BD",X"AF");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
