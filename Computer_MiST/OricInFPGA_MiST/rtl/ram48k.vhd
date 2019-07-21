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

--only 32k so we can use Internal BRAM

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
	signal ro0 : std_logic_vector(7 downto 0);--, ro1, ro2
--	signal cs0, cs1, cs2 : std_logic := '0';
begin

--	cs0 <= '1' when cs='1' and addr(15 downto 14)="00" else '0';
--	cs1 <= '1' when cs='1' and addr(15 downto 14)="01" else '0';
--	cs2 <= '1' when cs='1' and addr(15 downto 14)="10" else '0';

	do <=
		ro0 when oe='1' and cs='1' else -- and cs0='1' else
--		ro1 when oe='1' and cs1='1' else
--		ro2 when oe='1' and cs2='1' else
		(others=>'0');
		
RAM_0000_3FFF : entity work.spram--32k
	generic map (
		widthad_a  => 15,
		width_a  => 8)
	port map (
		address => addr(14 downto 0),
		clock  => clk,
		data   => di,
		wren  => we,
		q   => ro0
	);		

--RAM_4000_7FFF : entity work.spram
--	generic map (
--		widthad_a  => 14,
--		width_a  => 8)
--	port map (
--		address => addr(13 downto 0),
--		clock  => clk,
--		data   => di,
--		wren  => we,
--		q   => ro1
--	);	

--RAM_8000_BFFF : entity work.spram
--	generic map (
--		widthad_a  => 14,
--		width_a  => 8)
--	port map (
--		address => addr(13 downto 0),
--		clock  => clk,
--		data   => di,
--		wren  => we,
--		q   => ro2
--	);	


end RTL;
