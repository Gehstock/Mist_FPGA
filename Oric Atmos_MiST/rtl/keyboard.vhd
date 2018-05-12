library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity keyboard is
	port(
		CLK		: in std_logic;
		RESET		: in std_logic;

		PS2CLK	: in std_logic;
		PS2DATA	: in std_logic;

		COL		: in std_logic_vector(2 downto 0);
		ROWbit	: out std_logic_vector(7 downto 0)	
	);
end keyboard;

architecture arch of keyboard is

-- Gestion du protocole sur PS/2
component ps2key is
	generic (
		FREQ		: integer := 24
	);
	port(
		CLK		: in std_logic;
		RESET		: in std_logic;
		
		PS2CLK	: in std_logic;
		PS2DATA	: in std_logic;

		BREAK		: out std_logic;
		EXTENDED	: out std_logic;
		CODE		: out std_logic_vector(6 downto 0);
		LATCH		: out std_logic		
	);	
end component;


-- La matrice du clavier
component keymatrix is
	port(
		CLK		: in std_logic;
		wROW		: in std_logic_vector(2 downto 0);
		wCOL		: in std_logic_vector(2 downto 0);
		wVAL		: in std_logic;
		wEN		: in std_logic;
		WE			: in std_logic;
		
		rCOL		: in std_logic_vector(2 downto 0);
		rROWbit	: out std_logic_vector(7 downto 0)
	);
end component;

signal MAT_wROW	: std_logic_vector(2 downto 0);
signal MAT_wCOL	: std_logic_vector(2 downto 0);
signal MAT_wVAL 	: std_logic;
signal MAT_WE		: std_logic;
signal MAT_wEN		: std_logic;

signal ROM_A		: std_logic_vector(7 downto 0);

signal DISPLAY		: std_logic_vector(15 downto 0);


begin

PS2 : ps2key port map(
	CLK	=> CLK,
	RESET	=> RESET,

	PS2CLK	=> PS2CLK,
	PS2DATA	=> PS2DATA,
	
	BREAK		=> MAT_wVAL,
	EXTENDED	=> ROM_A(7),
	CODE(0)	=> ROM_A(0),
	CODE(1)	=> ROM_A(1),
	CODE(2)	=> ROM_A(2),
	CODE(3)	=> ROM_A(3),
	CODE(4)	=> ROM_A(4),
	CODE(5)	=> ROM_A(5),
	CODE(6)	=> ROM_A(6),

	LATCH		=> MAT_WE
);

ROM : entity work.keymap port map(
	A		=> ROM_A,
	ROW	=> MAT_wROW,
	COL	=> MAT_wCOL,
	clk_sys		=> CLK,
	EN		=> MAT_wEN
);

MAT : keymatrix port map(
		CLK		=> CLK,
		wROW		=> MAT_wROW,
		wCOL		=> MAT_wCOL,
		wVAL		=> MAT_wVAL,
		wEN		=> MAT_wEN,
		WE			=> MAT_WE,
		
		rCOL		=> COL,
		rROWbit	=> ROWbit
);

end arch;