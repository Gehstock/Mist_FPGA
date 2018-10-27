library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

entity keyboardX is
port (
	CLK  : in  std_logic;
	RESET   : in  std_logic;
	PS2CLK   : in  std_logic;
	PS2DATA   : in  std_logic_vector( 7 downto 0);
	COL : in  std_logic_vector(2 downto 0);
	ROWbit   : out  std_logic_vector( 7 downto 0)
);
end;

architecture RTL of keyboardX is

begin

		CLKp: PROCESS ( CLK )
begin
     if (RESET = '0') then
        COL<= (OTHERS => '0');
		  ROWbit<= (OTHERS => '0');
     elsif rising_edge(CLK) then
        ---
     end if;
end process;
end RTL;