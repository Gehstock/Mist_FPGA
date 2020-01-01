library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity tropical_spr_rgb_lut is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(4 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of tropical_spr_rgb_lut is
	type rom is array(0 to  31) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
		X"AF",X"57",X"FF",X"A7",X"F8",X"E0",X"01",X"30",X"98",X"77",X"90",X"E4",X"F4",X"80",X"C8",X"00",
		X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00");
begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
