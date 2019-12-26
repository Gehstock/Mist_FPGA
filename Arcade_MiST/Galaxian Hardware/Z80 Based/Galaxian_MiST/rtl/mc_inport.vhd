-----------------------------------------------------------------------
-- FPGA MOONCRESTA INPORT
--
-- Version : 1.01
--
-- Copyright(c) 2004 Katsumi Degawa , All rights reserved
--
-- Important !
--
-- This program is freeware for non-commercial use.
-- The author does not guarantee this program.
-- You can use this at your own risk.
--
-- 2004-4-30  galaxian modify by K.DEGAWA
-----------------------------------------------------------------------

--    DIP SW        0     1     2     3     4     5
-----------------------------------------------------------------
--  COIN CHUTE
-- 1 COIN/1 PLAY   1'b0  1'b0
-- 2 COIN/1 PLAY   1'b1  1'b0
-- 1 COIN/2 PLAY   1'b0  1'b1
-- FREE PLAY       1'b1  1'b1
--   BOUNS
--                             1'b0  1'b0
--                             1'b1  1'b0
--                             1'b0  1'b1
--                             1'b1  1'b1
--   LIVES
--     2                                   1'b0
--     3                                   1'b1
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

entity MC_INPORT is
generic (
	name       : in  string
);
port (
	I_COIN1    : in  std_logic;   --  active high
	I_COIN2    : in  std_logic;   --  active high
	I_1P_LE    : in  std_logic;   --  active high
	I_1P_RI    : in  std_logic;   --  active high
	I_1P_UP    : in  std_logic;   --  active high
	I_1P_DN    : in  std_logic;   --  active high
	I_1P_SH    : in  std_logic;   --  active high
	I_2P_LE    : in  std_logic;
	I_2P_RI    : in  std_logic;
	I_2P_UP    : in  std_logic;
	I_2P_DN    : in  std_logic;
	I_2P_SH    : in  std_logic;
	I_1P_START : in  std_logic;   --  active high
	I_2P_START : in  std_logic;   --  active high
	I_SW0_OE   : in  std_logic;
	I_SW1_OE   : in  std_logic;
	I_DIP_OE   : in  std_logic;
	O_D        : out std_logic_vector(7 downto 0)
);

end;

architecture RTL of MC_INPORT is

	constant W_TABLE   : std_logic := '0';  -- UP = 0;
	constant W_TEST    : std_logic := '0';
	constant W_SERVICE : std_logic := '0';

	signal W_SW0_DO : std_logic_vector(7 downto 0) := (others => '0');
	signal W_SW1_DO : std_logic_vector(7 downto 0) := (others => '0');
	signal W_DIP_DO : std_logic_vector(7 downto 0) := (others => '0');

begin

	ioports: if name = "AZURIAN" generate
		W_SW0_DO <= x"00" when I_SW0_OE = '0' else '0'  & I_1P_SH & I_1P_SH & I_COIN1 & I_1P_LE & I_1P_RI & I_1P_UP  & I_1P_DN;
		W_SW1_DO <= x"00" when I_SW1_OE = '0' else "10" & I_1P_LE & I_1P_RI & I_2P_UP & I_2P_DN & I_2P_START & I_1P_START;
		W_DIP_DO <= x"00" when I_DIP_OE = '0' else "00000100";
	elsif name = "DEVILFSH" or name = "TRIPLEDR" generate
		W_SW0_DO <= x"00" when I_SW0_OE = '0' else I_1P_UP & I_2P_UP &  I_1P_DN &  I_1P_SH &  I_1P_RI & I_1P_LE & I_COIN2    & I_COIN1;
		W_SW1_DO <= x"00" when I_SW1_OE = '0' else "01"              &  I_2P_DN &  I_2P_SH &  I_2P_RI & I_2P_LE & I_2P_START & I_1P_START;
		W_DIP_DO <= x"00" when I_DIP_OE = '0' else "00000100";
	elsif name = "MRDONIGH" generate
		W_SW0_DO <= x"00" when I_SW0_OE = '0' else W_SERVICE & W_TEST &  W_TABLE &  I_1P_SH &  I_1P_RI & I_1P_LE & I_COIN2    & I_COIN1;
		W_SW1_DO <= x"00" when I_SW1_OE = '0' else "000"                         &  I_1P_SH &  I_1P_DN & I_1P_UP & I_2P_START & I_1P_START;
		W_DIP_DO <= x"00" when I_DIP_OE = '0' else "00000100";
	elsif name = "ORBITRON" or name = "VICTORY" or name = "WAROFBUG" generate
		W_SW0_DO <= x"00" when I_SW0_OE = '0' else I_1P_UP & I_1P_DN &  I_2P_DN  &  I_1P_SH &  I_1P_RI &  I_1P_LE &    I_COIN2 &    I_COIN1;
		W_SW1_DO <= x"00" when I_SW1_OE = '0' else I_2P_UP &     "1" & "0"       &  I_1P_SH &  I_1P_RI &  I_1P_LE & I_2P_START & I_1P_START;
		W_DIP_DO <= x"00" when I_DIP_OE = '0' else "00001000";
	elsif name = "ZIGZAG" generate
		W_SW0_DO <= x"00" when I_SW0_OE = '0' else '0' & I_1P_DN & I_1P_UP &  I_1P_SH &  I_1P_RI & I_1P_LE & I_COIN2 & I_COIN1;
		W_SW1_DO <= x"00" when I_SW1_OE = '0' else "000000" & I_2P_START & I_1P_START;
		W_DIP_DO <= x"00" when I_DIP_OE = '0' else "00000011";
	else generate
		W_SW0_DO <= x"00" when I_SW0_OE = '0' else W_SERVICE & W_TEST &  W_TABLE &  I_1P_SH &  I_1P_RI & I_1P_LE & I_COIN2    & I_COIN1;
		W_SW1_DO <= x"00" when I_SW1_OE = '0' else "000"                         &  I_2P_SH &  I_2P_RI & I_2P_LE & I_2P_START & I_1P_START;
		W_DIP_DO <= x"00" when I_DIP_OE = '0' else "00000100";
	end generate;
	O_D      <= W_SW0_DO or W_SW1_DO or W_DIP_DO ;

end RTL;