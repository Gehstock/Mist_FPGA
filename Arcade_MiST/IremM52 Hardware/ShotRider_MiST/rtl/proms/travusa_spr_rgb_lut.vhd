library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity travusa_spr_rgb_lut is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(4 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of travusa_spr_rgb_lut is
	type rom is array(0 to  31) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"00",X"F8",X"90",X"C0",X"04",X"07",X"01",X"FF",X"F0",X"D8",X"DA",X"20",X"10",X"E4",X"D4",X"F3",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
