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

entity VRAMS is
	port(
		I_CK					: in	std_logic;
		I_VRAMWE				: in	std_logic;
		I_SELB				: in	std_logic;
		I_SELA				: in	std_logic;
		I_UDSn				: in	std_logic;
		I_LDSn				: in	std_logic;
		I_VRA					: in	std_logic_vector(11 downto 0);
		I_VRD					: in	std_logic_vector(15 downto 0);
		O_VRD					: out	std_logic_vector(15 downto 0)
	);
end VRAMS;

architecture RTL of VRAMS is
	signal
		sl_PF_HI,
		sl_MO_HI,
		sl_AL_HI,
		sl_PF_LO,
		sl_MO_LO,
		sl_AL_LO,
		sl_PF_CSn,
		sl_MO_CSn,
		sl_AL_CSn
								: std_logic := '1';
	signal
		sl_VRAMWE
								: std_logic := '0';
	signal
		slv_PF,
		slv_MO,
		slv_AL
								: std_logic_vector(15 downto 0) := (others=>'0');
begin
	-------------------------
	-- sheet 9 RAM decoder --
	-------------------------
	-- 9C decoders
	sl_PF_CSn <= (     I_SELB ) or (     I_SELA );
	sl_MO_CSn <= (     I_SELB ) or ( not I_SELA );
	sl_AL_CSn <= ( not I_SELB ) or (     I_SELA );

	-- Xilinx Block RAM chip selects
	sl_PF_HI <= not (I_UDSn or sl_PF_CSn);
	sl_MO_HI <= not (I_UDSn or sl_MO_CSn);
	sl_AL_HI <= not (I_UDSn or sl_AL_CSn);

	sl_PF_LO <= not (I_LDSn or sl_PF_CSn);
	sl_MO_LO <= not (I_LDSn or sl_MO_CSn);
	sl_AL_LO <= not (I_LDSn or sl_AL_CSn);

	-----------------------
	-- sheet 8 RAM banks --
	-----------------------
	sl_VRAMWE <= I_VRAMWE;

	O_VRD <=
		slv_PF when sl_PF_CSn = '0' else
		slv_MO when sl_MO_CSn = '0' else
		slv_AL when sl_AL_CSn = '0' else
--		slv_AL when sl_AL_CSn = '0' and (I_VRA < x"800" or I_VRA > x"F69") else 	-- disables reads from alphanumerics range 905000-905BB0
		(others=>'Z'); -- floating

-- PF video RAMs 6D, 7D, 6J, 7J
p_7J_RAM  : entity work.spram
	generic map (
		widthad_a	=> 12,
		width_a	=> 4)
	port map (
		address			=> I_VRA,
		clock				=> I_CK,-- and sl_PF_LO,
		data				=> I_VRD(3 downto 0),
		wren				=> sl_VRAMWE,
		q					=> slv_PF(3 downto 0)
	);

p_6J_RAM  : entity work.spram
	generic map (
		widthad_a	=> 12,
		width_a	=> 4)
	port map (
		address			=> I_VRA,
		clock				=> I_CK,-- and sl_PF_LO,
		data				=> I_VRD(7 downto 4),
		wren				=> sl_VRAMWE,
		q					=> slv_PF(7 downto 4)
	);
	
p_7D_RAM  : entity work.spram
	generic map (
		widthad_a	=> 12,
		width_a	=> 4)
	port map (
		address			=> I_VRA,
		clock				=> I_CK,-- and sl_PF_HI,
		data				=> I_VRD(11 downto 8),
		wren				=> sl_VRAMWE,
		q					=> slv_PF(11 downto 8)
	);
	
p_6D_RAM  : entity work.spram
	generic map (
		widthad_a	=> 12,
		width_a	=> 4)
	port map (
		address			=> I_VRA,
		clock				=> I_CK,-- and sl_PF_HI,
		data				=> I_VRD(15 downto 12),
		wren				=> sl_VRAMWE,
		q					=> slv_PF(15 downto 12)
	);
	
-- MO video RAMs 6C, 7C, 6F, 7F
p_7F_RAM  : entity work.spram
	generic map (
		widthad_a	=> 12,
		width_a	=> 4)
	port map (
		address			=> I_VRA,
		clock				=> I_CK,-- and sl_MO_LO,
		data				=> I_VRD(3 downto 0),
		wren				=> sl_VRAMWE,
		q					=> slv_MO(3 downto 0)
	);	
	
p_6F_RAM  : entity work.spram
	generic map (
		widthad_a	=> 12,
		width_a	=> 4)
	port map (
		address			=> I_VRA,
		clock				=> I_CK,-- and sl_MO_LO,
		data				=> I_VRD(7 downto 4),
		wren				=> sl_VRAMWE,
		q					=> slv_MO(7 downto 4)
	);
	
p_7C_RAM  : entity work.spram
	generic map (
		widthad_a	=> 12,
		width_a	=> 4)
	port map (
		address			=> I_VRA,
		clock				=> I_CK,-- and sl_MO_HI,
		data				=> I_VRD(11 downto 8),
		wren				=> sl_VRAMWE,
		q					=> slv_MO(11 downto 8)
	);
	
p_6C_RAM  : entity work.spram
	generic map (
		widthad_a	=> 12,
		width_a	=> 4)
	port map (
		address			=> I_VRA,
		clock				=> I_CK,-- and sl_MO_HI,
		data				=> I_VRD(15 downto 12),
		wren				=> sl_VRAMWE,
		q					=> slv_MO(15 downto 12)
	);
	
-- AL video RAMs 6E, 7E, 6K, 7K
p_7K_RAM  : entity work.spram
	generic map (
		widthad_a	=> 12,
		width_a	=> 4)
	port map (
		address			=> I_VRA,
		clock				=> I_CK,-- and sl_AL_LO,
		data				=> I_VRD(3 downto 0),
		wren				=> sl_VRAMWE,
		q					=> slv_AL(3 downto 0)
	);	
	
p_6K_RAM  : entity work.spram
	generic map (
		widthad_a	=> 12,
		width_a	=> 4)
	port map (
		address			=> I_VRA,
		clock				=> I_CK,-- and sl_AL_LO,
		data				=> I_VRD(7 downto 4),
		wren				=> sl_VRAMWE,
		q					=> slv_AL(7 downto 4)
	);	
	
p_7E_RAM  : entity work.spram
	generic map (
		widthad_a	=> 12,
		width_a	=> 4)
	port map (
		address			=> I_VRA,
		clock				=> I_CK,-- and sl_AL_HI,
		data				=> I_VRD(11 downto 8),
		wren				=> sl_VRAMWE,
		q					=> slv_AL(11 downto 8)
	);	
	
p_6E_RAM  : entity work.spram
	generic map (
		widthad_a	=> 12,
		width_a	=> 4)
	port map (
		address			=> I_VRA,
		clock				=> I_CK,-- and sl_AL_HI,
		data				=> I_VRD(15 downto 12),
		wren				=> sl_VRAMWE,
		q					=> slv_AL(15 downto 12)
	);
	
end RTL;