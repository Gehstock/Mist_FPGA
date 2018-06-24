--
-- i8255.vhd
--
-- Intel 8255 (PPI:Programmable Peripheral Interface) partiality compatible module
-- for MZ-700 on FPGA
--
-- Port A : Output, mode 0 only
-- Port B : Input, mode 0 only
-- Port C : Input(7-4)&Output(3-0), mode 0 only, bit set/reset support
--
-- Nibbles Lab. 2005
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--  Uncomment the following lines to use the declarations that are
--  provided for instantiating Xilinx primitive components.
--library UNISIM;
--use UNISIM.VComponents.all;

entity i8255 is
    Port ( RST : in std_logic;
           A : in std_logic_vector(1 downto 0);
           CS : in std_logic;
           WR : in std_logic;
           DI : in std_logic_vector(7 downto 0);
           DO : out std_logic_vector(7 downto 0);
		 LDDAT : out std_logic_vector(7 downto 0);
--		 LDDAT2 : out std_logic;
--		 LDSNS : out std_logic;
           CLKIN : in std_logic;
		 KCLK : in std_logic;
--		 FCLK : in std_logic;
		 VBLNK : in std_logic;
		 INTMSK : out std_logic;
           RBIT : in std_logic;
		 SENSE : in std_logic;
		 MOTOR : out std_logic;
		 PS2CK : in std_logic;
		 PS2DT : in std_logic);
end i8255;

architecture Behavioral of i8255 is

--
-- Port Register
--
signal PA : std_logic_vector(7 downto 0);
signal PB : std_logic_vector(7 downto 0);
signal PC : std_logic_vector(7 downto 0);
--
-- Port Selecter
--
signal SELPA : std_logic;
signal SELPB : std_logic;
signal SELPC : std_logic;
signal SELCT : std_logic;
--
-- CURSOR blink
--
signal TBLNK : std_logic;
signal CCOUNT : std_logic_vector(3 downto 0);
--
-- Remote
--
signal SNS : std_logic;
signal MTR : std_logic;
signal M_ON : std_logic;
signal SENSE0 : std_logic;
signal SWIN : std_logic_vector(3 downto 0);

--
-- Components
--
component keymatrix
    Port ( RST : in std_logic;
    		 PA : in std_logic_vector(3 downto 0);
           PB : out std_logic_vector(7 downto 0);
           KCLK : in std_logic;
		 LDDAT : out std_logic_vector(7 downto 0);
		 PS2CK : in std_logic;
		 PS2DT : in std_logic);
end component;

begin

	--
	-- Instantiation
	--
	keys : keymatrix port map (
			RST => RST,
			PA => PA(3 downto 0),
			PB => PB,
			KCLK => KCLK,
			LDDAT => LDDAT,
			PS2CK => PS2CK,
			PS2DT => PS2DT);

	--
	-- Port select for Output
	--
	SELPA<='1' when A="00" else '0';
	SELPB<='1' when A="01" else '0';
	SELPC<='1' when A="10" else '0';
	SELCT<='1' when A="11" else '0';

	--
	-- Output
	--
	process( RST, WR, CS ) begin
		if( RST='0' ) then
			PA<=(others=>'0');
--			PB<=(others=>'0');
			PC<=(others=>'0');
		elsif( WR'event and WR='1' and CS='0' ) then
			if( SELPA='1' ) then
				PA<=DI;
			end if;
--			if( SELPB='1' ) then
--				PB<=DI;
--			end if;
			if( SELPC='1' ) then
				PC(3 downto 0)<=DI(3 downto 0);
			end if;
			if( SELCT='1' and DI(7)='0' ) then
				case DI(3 downto 0) is
					when "0000" => PC(0)<='0';
					when "0001" => PC(0)<='1';
					when "0010" => PC(1)<='0';
					when "0011" => PC(1)<='1';
					when "0100" => PC(2)<='0';
					when "0101" => PC(2)<='1';
					when "0110" => PC(3)<='0';
					when "0111" => PC(3)<='1';
--					when "1000" => PC(4)<='0';
--					when "1001" => PC(4)<='1';
--					when "1010" => PC(5)<='0';
--					when "1011" => PC(5)<='1';
--					when "1100" => PC(6)<='0';
--					when "1101" => PC(6)<='1';
--					when "1110" => PC(7)<='0';
--					when "1111" => PC(7)<='1';
					when others => PC<="XXXXXXXX";
				end case;
			end if;
		end if;
	end process;

	--
	-- CURSOR blink Clock
	--
	process( CLKIN, PA(7) ) begin
		if( PA(7)='0' ) then
			CCOUNT<=(others=>'0');
		elsif( CLKIN'event and CLKIN='1' ) then
			CCOUNT<=CCOUNT+'1';
			if( CCOUNT=13 ) then
				CCOUNT<=(others=>'0');
				TBLNK<=not TBLNK;
			end if;
		end if;
	end process;

	--
	-- Input select
	--
	DO<=PB                       when SELPB='1' else
	    VBLNK&TBLNK&RBIT&MTR&PC(3 downto 0) when SELPC='1' else (others=>'1');

	--
	-- Remote
	--
	MOTOR<=MTR;
	process( KCLK ) begin
		if( KCLK'event and KCLK='1' ) then
			M_ON<=PC(3);
			SNS<=SENSE0;
			if( SENSE0='1' ) then
				MTR<='0';
			elsif( SNS='1' and SENSE0='0' ) then
				MTR<='1';
			elsif( M_ON='0' and PC(3)='1' ) then
				MTR<=not MTR;
			end if;

			SWIN<=SWIN(2 downto 0)&(not SENSE);
			if( SWIN="1111" and SENSE='0' ) then
				SENSE0<='0';
			elsif( SWIN="0000" and SENSE='1' ) then
				SENSE0<='1';
			end if;
		end if;
	end process;

	--
	-- Others
	--
	INTMSK<=PC(2);

end Behavioral;
