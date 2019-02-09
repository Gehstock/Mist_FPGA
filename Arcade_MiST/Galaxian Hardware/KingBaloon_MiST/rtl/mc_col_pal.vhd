-------------------------------------------------------------------------------
-- FPGA MOONCRESTA COLOR-PALETTE
--
-- Version : 2.00
--
-- Copyright(c) 2004 Katsumi Degawa , All rights reserved
--
-- Important !
--
-- This program is freeware for non-commercial use.
-- The author does not guarantee this program.
-- You can use this at your own risk.
--
-- 2004- 9-18 added Xilinx Device.  K.Degawa
-------------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
--  use ieee.numeric_std.all;

--library UNISIM;
--  use UNISIM.Vcomponents.all;

entity MC_COL_PAL is
port (
	I_CLK_12M    : in  std_logic;
	I_CLK_6M     : in  std_logic;
	I_VID        : in  std_logic_vector(1 downto 0);
	I_COL        : in  std_logic_vector(2 downto 0);
	I_C_BLnX     : in  std_logic;

	O_C_BLXn     : out std_logic;
	O_STARS_OFFn : out std_logic;
	O_R          : out std_logic_vector(2 downto 0);
	O_G          : out std_logic_vector(2 downto 0);
	O_B          : out std_logic_vector(2 downto 0)
);
end;

architecture RTL of MC_COL_PAL is
	---    Parts 6M    --------------------------------------------------------
	signal W_COL_ROM_DO : std_logic_vector(7 downto 0) := (others => '0');
	signal W_6M_DI      : std_logic_vector(6 downto 0) := (others => '0');
	signal W_6M_DO      : std_logic_vector(6 downto 0) := (others => '0');
	signal W_6M_CLR     : std_logic := '0';

begin
	W_6M_DI      <= I_COL(2 downto 0) & I_VID(1 downto 0) & not (I_VID(0) or I_VID(1)) & I_C_BLnX;
	W_6M_CLR     <= W_6M_DI(0) or W_6M_DO(0);
	O_C_BLXn     <= W_6M_DI(0) or W_6M_DO(0);
	O_STARS_OFFn <= W_6M_DO(1);

--always@(posedge I_CLK_6M or negedge W_6M_CLR)
	process(I_CLK_6M, W_6M_CLR)
	begin
		if (W_6M_CLR = '0') then
			W_6M_DO <= (others => '0');
		elsif rising_edge(I_CLK_6M) then
			W_6M_DO <= W_6M_DI;
		end if;
	end process;

	---    COL ROM     --------------------------------------------------------
--wire   W_COL_ROM_OEn = W_6M_DO[1];

	galaxian_6l : entity work.sprom
	generic map (
		init_file  => "./ROM/col.hex",
		widthad_a  => 5,
		width_a  => 8)
	port map (
		address => W_6M_DO(6 downto 2),
		clock  => I_CLK_12M,
		q => W_COL_ROM_DO
	);

	---    VID OUT     --------------------------------------------------------
	O_R <= W_COL_ROM_DO(2 downto 0);
	O_G <= W_COL_ROM_DO(5 downto 3);
	O_B <= W_COL_ROM_DO(7 downto 6) & "0";

end;
