--
-- 48K RAM comprised of three smaller 16K RAMs
--
--	(c) 2012 d18c7db(a)hotmail
--
--	This program is free software; you can redistribute it and/or modify it under
--	the terms of the GNU General Public License version 3 or, at your option,
--	any later version as published by the Free Software Foundation.
--
--	This program is distributed in the hope that it will be useful,
--	but WITHOUT ANY WARRANTY; without even the implied warranty of
--	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
--
-- For full details, see the GNU General Public License at www.gnu.org/licenses

-- Changed for Mist FPGA Gehstock(2018)
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

entity ram48k is
port (
	clk  : in  std_logic;
	cs   : in  std_logic;
	oe   : in  std_logic;
	we   : in  std_logic;
	addr : in  std_logic_vector(15 downto 0);
	di   : in  std_logic_vector( 7 downto 0);
	do   : out std_logic_vector( 7 downto 0)
);
end;

architecture RTL of ram48k is
	signal ro0, ro1, ro2, ro3 : std_logic_vector(7 downto 0);
	signal cs0, cs1, cs2, cs3 : std_logic := '0';
begin
	cs0 <= '1';
--	cs0 <= '1' when cs='1' and addr(15 downto 14)="00" else '0';
--	cs1 <= '1' when cs='1' and addr(15 downto 14)="01" else '0';
--	cs2 <= '1' when cs='1' and addr(15 downto 14)="10" else '0';
--	cs3 <= '1' when cs='1' and addr(15 downto 14)="11" else '0';
	do <= ro0;
	--	ro0 when oe='1' and cs0='1' else
	--	ro1 when oe='1' and cs1='1' else
	--	ro2 when oe='1' and cs2='1' else
	--	ro3 when oe='1' and cs3='1' else
	--	(others=>'0');
		
--16kb		
	RAM_0000_3FFF : entity work.spram
	port map (
		clk_i  => clk,
		we_i   => cs0 and we,
		addr_i => addr(13 downto 0),
		data_i   => di,
		data_o   => ro0
	);
--32kb
--	RAM_4000_7FFF : entity work.spram
--	port map (
--		clk_i  => clk,
--		we_i   => cs1 and we,
--		addr_i => addr(13 downto 0),
--		data_i   => di,
--		data_o   => ro1
--	);
--48kb
--	RAM_8000_BFFF : entity work.spram
--	port map (
--		clk_i  => clk,
--		we_i   => cs2 and we,
--		addr_i => addr(13 downto 0),
--		data_i   => di,
--		data_o   => ro2
--	);
--64kb
--	RAM_C000_FFFF : entity work.spram
--	port map (
--		clk_i  => clk,
--		we_i   => cs3 and we,
--		addr_i => addr(13 downto 0),
--		data_i   => di,
--		data_o   => ro3
--	);

end RTL;
