----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:13:33 02/03/2009 
-- Design Name: 
-- Module Name:    RAM - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
-- -----------------------------------------------------------------------
--
-- Syntiac's generic VHDL support files.
--
-- -----------------------------------------------------------------------
-- Copyright 2005-2008 by Peter Wendrich (pwsoft@syntiac.com)
-- http://www.syntiac.com/fpga64.html
-- -----------------------------------------------------------------------
--
-- gen_ram.vhd
--
-- -----------------------------------------------------------------------
--
-- Simple dual port ram: One read and one write port
--
-- -----------------------------------------------------------------------
library IEEE;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

-- -----------------------------------------------------------------------

entity ram is
	generic (
		dWidth : integer := 8;
		aWidth : integer := 16
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

architecture rtl of ram is
	type RAM_ARRAY is array(0 to 65535) of std_logic_vector(7 downto 0);
	signal RAM : RAM_ARRAY := ((others=> (others=>'0')));
	signal rAddrReg : std_logic_vector((aWidth-1) downto 0);
	signal qReg : std_logic_vector((dWidth-1) downto 0);
begin

-- -----------------------------------------------------------------------
-- Memory write
-- -----------------------------------------------------------------------
	process(clk)
	begin
		if rising_edge(clk) then
			if we = '0' then
				RAM(to_integer(unsigned(addr))) <= d;
			end if;
		end if;
	end process;
	
-- -----------------------------------------------------------------------
-- Memory read
-- -----------------------------------------------------------------------
	process(clk)
	begin
		if rising_edge(clk) then
			rAddrReg <= addr;
		end if;
	end process;
   q <= RAM(to_integer(unsigned(rAddrReg)));
end rtl;

