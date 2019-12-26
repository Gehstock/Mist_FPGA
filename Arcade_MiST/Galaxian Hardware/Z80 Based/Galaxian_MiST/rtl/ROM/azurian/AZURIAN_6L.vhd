library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity AZURIAN_6L is
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(4 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of AZURIAN_6L is
	type rom is array(0 to  31) of std_logic_vector(7 downto 0);
	signal rom_data: rom := (
    x"00",x"7A",x"36",x"07",x"00",x"F0",x"38",x"1F", -- 0x0000
    x"00",x"C7",x"F0",x"3F",x"00",x"DB",x"C6",x"38", -- 0x0008
    x"00",x"36",x"07",x"F0",x"00",x"33",x"3F",x"DB", -- 0x0010
    x"00",x"3F",x"57",x"C6",x"00",x"C6",x"3F",x"FF"  -- 0x0018
  );

begin
process(clk)
begin
	if rising_edge(clk) then
		data <= rom_data(to_integer(unsigned(addr)));
	end if;
end process;
end architecture;
