library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;


entity decodeur_7_seg is
port(
  di : in std_logic_vector(3 downto 0);
  do : out std_logic_vector(7 downto 0)
);
end decodeur_7_seg;

architecture struct of decodeur_7_seg is

begin

with di select
  do <=
    "11000000" when "0000",
    "11111001" when "0001",
    "10100100" when "0010",
    "10110000" when "0011",
    "10011001" when "0100",
    "10010010" when "0101",
    "10000010" when "0110",
    "11111000" when "0111",
    "10000000" when "1000",
    "10010000" when "1001",
    "10001000" when "1010",
    "10000011" when "1011",
    "11000110" when "1100",
    "10100001" when "1101",
    "10000110" when "1110",
    "10001110" when others;

end architecture;