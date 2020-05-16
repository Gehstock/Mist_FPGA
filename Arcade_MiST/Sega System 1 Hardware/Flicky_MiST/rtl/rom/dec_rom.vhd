library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity dec_rom is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(6 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of dec_rom is
	type rom is array(0 to  127) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"08",X"88",X"00",X"80",X"A0",X"80",X"A8",X"88",X"80",X"00",X"A0",X"20",X"88",X"80",X"08",X"00",
		X"A0",X"80",X"A8",X"88",X"28",X"08",X"20",X"00",X"28",X"08",X"20",X"00",X"A0",X"80",X"A8",X"88",
		X"08",X"88",X"00",X"80",X"80",X"00",X"A0",X"20",X"80",X"00",X"A0",X"20",X"88",X"80",X"08",X"00",
		X"28",X"08",X"20",X"00",X"28",X"08",X"20",X"00",X"28",X"08",X"20",X"00",X"88",X"80",X"08",X"00",
		X"08",X"88",X"00",X"80",X"A8",X"88",X"28",X"08",X"A8",X"88",X"28",X"08",X"80",X"00",X"A0",X"20",
		X"28",X"08",X"20",X"00",X"88",X"80",X"08",X"00",X"A8",X"88",X"28",X"08",X"88",X"80",X"08",X"00",
		X"08",X"88",X"00",X"80",X"80",X"00",X"A0",X"20",X"A8",X"88",X"28",X"08",X"80",X"00",X"A0",X"20",
		X"28",X"08",X"20",X"00",X"28",X"08",X"20",X"00",X"08",X"88",X"00",X"80",X"88",X"80",X"08",X"00");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
