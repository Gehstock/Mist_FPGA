library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity ROM_PGM_1 is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(13 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of ROM_PGM_1 is
begin
	data <= X"FF";
end architecture;
