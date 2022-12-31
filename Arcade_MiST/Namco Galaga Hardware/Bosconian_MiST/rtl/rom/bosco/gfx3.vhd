library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity gfx3 is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(4 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of gfx3 is
	type rom is array(0 to  31) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"F7",X"F5",X"F5",X"F3",X"F3",X"F1",X"F1",X"AD",X"8F",X"AF",X"B9",X"F8",X"81",X"81",X"81",X"81",
		X"71",X"71",X"73",X"73",X"75",X"75",X"77",X"79",X"39",X"2D",X"0F",X"2F",X"01",X"01",X"01",X"01");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
