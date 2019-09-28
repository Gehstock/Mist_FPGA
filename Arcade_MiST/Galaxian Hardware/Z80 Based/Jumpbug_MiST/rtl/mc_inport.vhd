-----------------------------------------------------------------------
-- FPGA JUMPBUG INPORT

--	PORT_START("IN0")
--	PORT_BIT( 0x01, IP_ACTIVE_HIGH, IPT_COIN1 )
--	PORT_BIT( 0x02, IP_ACTIVE_HIGH, IPT_JOYSTICK_UP ) PORT_8WAY PORT_COCKTAIL
--	PORT_BIT( 0x04, IP_ACTIVE_HIGH, IPT_JOYSTICK_LEFT ) PORT_8WAY
--	PORT_BIT( 0x08, IP_ACTIVE_HIGH, IPT_JOYSTICK_RIGHT ) PORT_8WAY
--	PORT_BIT( 0x10, IP_ACTIVE_HIGH, IPT_BUTTON1 )
--	PORT_DIPNAME( 0x20, 0x00, DEF_STR( Cabinet ) )
--	PORT_DIPSETTING(    0x00, DEF_STR( Upright ) )
--	PORT_DIPSETTING(    0x20, DEF_STR( Cocktail ) )
--	PORT_BIT( 0x40, IP_ACTIVE_HIGH, IPT_JOYSTICK_DOWN ) PORT_8WAY
--	PORT_BIT( 0x80, IP_ACTIVE_HIGH, IPT_JOYSTICK_UP ) PORT_8WAY

-- PORT_START("IN1")
--	PORT_BIT( 0x01, IP_ACTIVE_HIGH, IPT_START1 )
--	PORT_BIT( 0x02, IP_ACTIVE_HIGH, IPT_START2 )
--	PORT_BIT( 0x04, IP_ACTIVE_HIGH, IPT_JOYSTICK_LEFT ) PORT_8WAY PORT_COCKTAIL
--	PORT_BIT( 0x08, IP_ACTIVE_HIGH, IPT_JOYSTICK_RIGHT ) PORT_8WAY PORT_COCKTAIL
--	PORT_BIT( 0x10, IP_ACTIVE_HIGH, IPT_BUTTON1 ) PORT_COCKTAIL
--	PORT_BIT( 0x20, IP_ACTIVE_HIGH, IPT_COIN2 )
--	PORT_DIPNAME( 0x40, 0x00, "Difficulty ?" )
--	PORT_DIPSETTING(    0x00, DEF_STR( Hard ) )
--	PORT_DIPSETTING(    0x40, DEF_STR( Easy ) )
--	PORT_BIT( 0x80, IP_ACTIVE_HIGH, IPT_JOYSTICK_DOWN ) PORT_8WAY PORT_COCKTAIL

--	PORT_START("IN2")
--	PORT_DIPNAME( 0x03, 0x01, DEF_STR( Lives ) )
--	PORT_DIPSETTING(    0x01, "3" )
--	PORT_DIPSETTING(    0x02, "4" )
--	PORT_DIPSETTING(    0x03, "5" )
--	PORT_DIPSETTING(    0x00, "Infinite (Cheat)")
--	PORT_DIPNAME( 0x0c, 0x00, DEF_STR( Coinage ) )
--	PORT_DIPSETTING(    0x04, "A 2C/1C  B 2C/1C" )
--	PORT_DIPSETTING(    0x08, "A 2C/1C  B 1C/3C" )
--	PORT_DIPSETTING(    0x00, "A 1C/1C  B 1C/1C" )
--	PORT_DIPSETTING(    0x0c, "A 1C/1C  B 1C/6C" )
--	PORT_BIT( 0xf0, IP_ACTIVE_HIGH, IPT_UNUSED )

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

entity MC_INPORT is
port (
	I_COIN1    : in  std_logic;
	I_COIN2    : in  std_logic;
	I_1P_LE    : in  std_logic;
	I_1P_RI    : in  std_logic;
	I_1P_UP    : in  std_logic;
	I_1P_DW    : in  std_logic;
	I_1P_SH    : in  std_logic;
	I_2P_LE    : in  std_logic;
	I_2P_RI    : in  std_logic;
	I_2P_UP    : in  std_logic;
	I_2P_DW    : in  std_logic;
	I_2P_SH    : in  std_logic;
	I_1P_START : in  std_logic;
	I_2P_START : in  std_logic;
	I_SW0_OE   : in  std_logic;
	I_SW1_OE   : in  std_logic;
	I_DIP_OE   : in  std_logic;
	O_D        : out std_logic_vector(7 downto 0)
);

end;

architecture RTL of MC_INPORT is

	constant W_TABLE   : std_logic := '0';  -- UP = 0;
	constant W_DIFF    : std_logic := '0';  -- HARD/EASY
	constant W_LIVES : std_logic_vector(1 downto 0) := "11"; --3,4,5
	constant W_CHEAT : std_logic := '1';    --Infinite
	constant W_COINAGE : std_logic_vector(3 downto 0) := "0000";

	signal W_SW0_DO : std_logic_vector(7 downto 0) := (others => '0');
	signal W_SW1_DO : std_logic_vector(7 downto 0) := (others => '0');
	signal W_DIP_DO : std_logic_vector(7 downto 0) := (others => '0');

begin

	W_SW0_DO <= x"00" when I_SW0_OE = '0' else I_1P_UP & I_1P_DW & W_TABLE & I_1P_SH & I_1P_RI & I_1P_LE & I_2P_UP & I_COIN1;
	W_SW1_DO <= x"00" when I_SW1_OE = '0' else I_2P_DW & W_DIFF & I_COIN2 &  I_2P_SH &  I_2P_RI & I_2P_LE & I_2P_START & I_1P_START;
	W_DIP_DO <= x"00" when I_DIP_OE = '0' else '0' & W_COINAGE & W_CHEAT& W_LIVES;
	O_D      <= W_SW0_DO or W_SW1_DO or W_DIP_DO ;

end RTL;