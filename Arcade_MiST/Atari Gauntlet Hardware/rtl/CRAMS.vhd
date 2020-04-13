--	(c) 2020 d18c7db(a)hotmail
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
--

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;

entity CRAMS is
	port(
		I_MCKR				: in	std_logic;
		I_UDSn				: in	std_logic;
		I_LDSn				: in	std_logic;
		I_CRAMn				: in	std_logic;
		I_BR_Wn				: in	std_logic;
		I_CRA					: in	std_logic_vector( 9 downto 0);
		I_DB					: in	std_logic_vector(15 downto 0);
		O_DB					: out	std_logic_vector(15 downto 0)
	);
end CRAMS;

architecture RTL of CRAMS is
	signal
		sl_CRAM_CS,
		sl_CRAMWRn
								: std_logic := '1';
	signal
		slv_CRAM_WE
								: std_logic_vector(1 downto 0) := (others=>'0');
begin
	------------------------
	-- sheet 15 Color RAM --
	------------------------

	-- 9L, 9M, 10L, 10M RAM
p_9L_10L  : entity work.spram--Lo
	generic map (
		widthad_a	=> 10,
		width_a	=> 8)
	port map (
		address			=> I_CRA(9 downto 0),
		clock				=> I_MCKR,-- and sl_CRAM_CS,
		data				=> I_DB(7 downto 0),
		wren				=> slv_CRAM_WE(0),
		q					=> O_DB(7 downto 0)
	);
	
p_9M_10M  : entity work.spram--Hi
	generic map (
		widthad_a	=> 10,
		width_a	=> 8)
	port map (
		address			=> I_CRA(9 downto 0),
		clock				=> I_MCKR,-- and sl_CRAM_CS,
		data				=> I_DB(15 downto 8),
		wren				=> slv_CRAM_WE(1),
		q					=> O_DB(15 downto 8)
	);
	


	slv_CRAM_WE <= not (
		(((not I_CRAMn) and I_UDSn) or sl_CRAMWRn) &
		(((not I_CRAMn) and I_LDSn) or sl_CRAMWRn)
	);

	-- gates 7W, 11P
	sl_CRAM_CS	<= not (I_UDSn and I_LDSn and (not I_CRAMn));

	-- gate 7X
	sl_CRAMWRn	<= I_CRAMn or I_BR_Wn;
end RTL;
