library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity rgb is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(4 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

-- This is actually a PROM and could be loaded into a DPRAM like the other ROMs,
-- but for such a short entry it's easier to do what Galaga did and hard-code it here.
-- That said, the values for Bosconian are different from those for Galaga,
-- and have been altered.
architecture prom of rgb is
	type rom is array(0 to  31) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"F6",X"07",X"1F",X"3F",X"C4",X"DF",X"F8",X"D8",X"0B",X"28",X"C3",X"51",X"26",X"0D",X"A4",X"00",
		X"A4",X"0D",X"1F",X"3F",X"C4",X"DF",X"F8",X"D8",X"0B",X"28",X"C3",X"51",X"26",X"07",X"F6",X"00");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
