-- -----------------------------------------------------------------------
--
-- Syntiac's generic VHDL support",x"iles.
--
-- -----------------------------------------------------------------------
-- Copyright 2005-2008 by Peter Wendrich (pwsoft@syntiac.com)
-- http://www.syntiac.com/fpga64.html
--
-- Modified April 2016 by Dar (darfpga@aol.fr) 
-- http://darfpga.blogspot.fr
--   Remove address register when writing
--
-- Modifies March 2022 by Dar 
--   Add init data with tshoot cmos value
-- -----------------------------------------------------------------------
--
-- gen_rwram.vhd init with tshoot cmos value
--
-- -----------------------------------------------------------------------
--
-- generic ram.
--
-- -----------------------------------------------------------------------
-- tshoot cmos settings --
--
--@00-03:Extra fowl every (XXYY XX=value*1000 YY=index default 320A)
-- 0000/0501/0A02/0F03/1404/1905/1E06/2307
-- 2808/2D09/320A/370B/3C0C/410D/460E/4B0F
-- 5010/5511/5A12/5F13
--
--@04-07: Missions for 1 credit (XXYY XX=value YY=index default 0301)
-- 0200/0301/0402/0503
--
--@08-0B: attract mode no/yes (XXYY XX=value YY=index default 0101)	
-- 0000/0101
--
--@0C-0F: pricing selection (XXYY XX=value YY=index [0000 custom, 0909 free play] default 0303)
-- 0000/0101/.../0909
--
--@10-13 -> CC1C-CC1F: coin slot units (XXYY XX=value YY=index, index is used only when custom)
-- 0000/0101/.../6262
--
--@20-23 -> CC24-CC27: unit for credit/bonus credit (XXYY XX=value YY=index)
-- 0000/0101/.../6262
--
--@28-2B: difficulty (XXYY XX=value YY=index default 0505)
-- 0000/0101/../0909
--
--@2C-2F: ?
-- 0300
--
--@30-33: gun recoil no/yes (XXYY XX=value YY=index default 0101)
-- 0000/0101
--
--@34-35: control sum : sum of nibbles from @00 to @33 + 3
-- -----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
-- -----------------------------------------------------------------------
entity t_shoot_cmos_ram is
	generic (
		dWidth : integer := 8;  -- must be  4",x"or tshoot_cmos_ram
		aWidth : integer := 10  -- must be 10",x"or tshoot_cmos_ram
	);
	port (
		clk : in std_logic;
		we : in std_logic;
		addr : in std_logic_vector((aWidth-1) downto 0);
		d : in std_logic_vector((dWidth-1) downto 0);
		q : out std_logic_vector((dWidth-1) downto 0)
	);
end entity;
-- -----------------------------------------------------------------------
-- tshoot cmos data
-- (ram is 128x4 => only 4 bits/address, that is only 1 hex digit/address)

architecture rtl of t_shoot_cmos_ram is
subtype addressRange is integer range 0 to ((2**aWidth)-1);
type ramDef is array(addressRange) of std_logic_vector((dWidth-1) downto 0);
	
signal ram: ramDef := (		
 x"3",x"2",x"0",x"A",x"0",x"3",x"0",x"1",x"0",x"1",x"0",x"1",x"0",x"3",x"0",x"3",
 x"0",x"1",x"0",x"0",x"0",x"4",x"0",x"0",x"0",x"1",x"0",x"0",x"0",x"1",x"0",x"0",  
 x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"5",x"0",x"5",x"0",x"3",x"0",x"0",
 x"0",x"1",x"0",x"1",x"5",x"F",x"A",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
 X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
 X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
 X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
 X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
 X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
 X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
 X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
 X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
 X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
 X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
 X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
 X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
 x"0",x"7",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",
 x"0",x"0",x"0",x"7",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"6",
 x"0",x"0",x"0",x"0",x"1",x"5",x"0",x"0",x"0",x"0",x"0",x"5",x"0",x"0",x"0",x"0",
 x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"5",x"0",x"0",x"0",x"0",x"1",x"7",x"0",x"1",
 x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"1",x"8",x"1",x"0",x"0",x"0",x"0",x"0",x"5",
 x"0",x"2",x"D",x"5",x"5",x"7",x"4",x"9",x"4",x"C",x"0",x"0",x"4",x"0",x"3",x"5",
 x"4",x"D",x"5",x"2",x"5",x"3",x"0",x"0",x"4",x"0",x"2",x"0",x"5",x"2",x"4",x"F",
 x"4",x"E",x"0",x"0",x"3",x"9",x"1",x"5",x"4",x"A",x"5",x"2",x"4",x"E",x"0",x"0",
 x"3",x"8",x"3",x"4",x"5",x"4",x"4",x"E",x"4",x"4",x"0",x"0",x"3",x"7",x"2",x"5",
 x"5",x"7",x"5",x"0",x"4",x"2",x"0",x"0",x"3",x"6",x"1",x"0",x"4",x"3",x"4",x"C",
 x"5",x"3",x"0",x"0",x"3",x"5",x"0",x"3",x"4",x"C",x"4",x"5",x"4",x"F",x"0",x"0",
 x"3",x"4",x"7",x"8",x"4",x"4",x"5",x"2",x"5",x"9",x"0",x"0",x"3",x"3",x"2",x"1",
 x"4",x"A",x"5",x"3",x"4",x"3",x"0",x"0",x"3",x"2",x"5",x"0",x"4",x"A",x"4",x"5",
 x"4",x"8",x"0",x"0",x"3",x"1",x"3",x"6",x"5",x"2",x"4",x"D",x"4",x"9",x"0",x"0",
 x"3",x"0",x"1",x"8",x"4",x"B",x"4",x"5",x"4",x"E",x"0",x"0",x"2",x"9",x"1",x"0",
 x"5",x"0",x"4",x"7",x"4",x"4",x"0",x"0",x"2",x"8",x"0",x"0",x"5",x"0",x"4",x"1",
 x"4",x"8",x"0",x"0",x"2",x"7",x"9",x"8",x"4",x"E",x"5",x"6",x"4",x"2",x"0",x"0",
 x"2",x"6",x"7",x"2",x"4",x"1",x"4",x"7",x"5",x"2",x"0",x"0",x"2",x"5",x"2",x"9",
 x"5",x"6",x"4",x"C",x"4",x"7",x"0",x"0",x"2",x"4",x"7",x"3",x"4",x"4",x"4",x"F",
 x"4",x"E",x"0",x"0",x"2",x"3",x"9",x"0",x"5",x"7",x"4",x"5",x"5",x"3",x"0",x"0",
 x"2",x"2",x"6",x"2",x"4",x"A",x"5",x"0",x"4",x"4",x"0",x"0",x"2",x"1",x"8",x"3",
 x"5",x"0",x"4",x"6",x"5",x"A",x"0",x"0",x"2",x"0",x"2",x"1",x"4",x"B",x"4",x"7",
 x"4",x"D",x"0",x"0",x"1",x"9",x"1",x"8",x"4",x"B",x"5",x"2",x"4",x"4",x"0",x"0",
 x"1",x"8",x"9",x"9",x"5",x"3",x"4",x"3",x"4",x"C",x"0",x"0",x"1",x"7",x"2",x"1",
 x"5",x"2",x"4",x"1",x"5",x"7",x"0",x"0",x"1",x"6",x"7",x"8",x"4",x"2",x"4",x"1",
 x"4",x"E",x"0",x"0",x"1",x"5",x"2",x"1",x"5",x"0",x"5",x"6",x"4",x"1",x"0",x"0",
 x"1",x"4",x"5",x"2",x"4",x"A",x"4",x"3",x"2",x"0",x"0",x"0",x"1",x"3",x"7",x"8",
 x"2",x"0",x"4",x"5",x"5",x"3",x"0",x"0",x"1",x"2",x"6",x"4",x"4",x"8",x"4",x"5",
 x"4",x"3",x"0",x"0",x"1",x"1",x"3",x"7",x"4",x"D",x"4",x"2",x"5",x"3",x"0",x"0",
 x"1",x"0",x"6",x"2",x"5",x"2",x"4",x"3",x"4",x"2",x"0",x"0",x"0",x"9",x"3",x"5",
 x"5",x"0",x"4",x"A",x"4",x"5",x"0",x"0",x"0",x"8",x"2",x"8",x"4",x"2",x"4",x"6",
 x"4",x"4",x"0",x"0",x"0",x"7",x"9",x"0",x"4",x"4",x"4",x"1",x"5",x"2",x"0",x"0",
 x"0",x"7",x"5",x"0",x"5",x"3",x"4",x"4",x"5",x"7",x"0",x"0",x"0",x"6",x"7",x"8",
 x"A",x"D",x"0",x"0",x"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
 X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
 X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
 X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
 X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
 X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
 X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
 X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
 X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
 X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
 X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
 X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
 X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
 X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",
 X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0",X"0");
	
signal rAddrReg : std_logic_vector((aWidth-1) downto 0);
signal qReg : std_logic_vector((dWidth-1) downto 0);

begin
-- -----------------------------------------------------------------------
-- Signals to entity interface
-- -----------------------------------------------------------------------
--	q <= qReg;
-- -----------------------------------------------------------------------
-- Memory write
-- -----------------------------------------------------------------------
	process(clk)
	begin
		if rising_edge(clk) then
			if we = '1' then
				ram(to_integer(unsigned(addr))) <= d;
			end if;
		end if;
	end process;
-- -----------------------------------------------------------------------
-- Memory read
-- -----------------------------------------------------------------------
process(clk)
	begin
		if rising_edge(clk) then
--			qReg <= ram(to_integer(unsigned(rAddrReg)));
--			rAddrReg <= addr;
--			qReg <= ram(to_integer(unsigned(addr)));
			q <= ram(to_integer(unsigned(addr)));
		end if;
	end process;
--q <= ram(to_integer(unsigned(addr)));
end architecture;

