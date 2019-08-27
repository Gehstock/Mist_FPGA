library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity binary_counter is
port(
	C : in std_logic; 
	CLR : in std_logic;
	Q : out std_logic_vector(3 downto 0)
);
end binary_counter;

architecture struct of binary_counter is

signal tmp: std_logic_vector(3 downto 0);

begin

process (C, CLR)begin
	if (CLR = '1') then
		tmp <= "0000";
	elsif (C'event and C='1') then
		tmp <= tmp + 1;
	end if;
end process;

Q <= tmp;

end struct;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity moonwar_dail is
port(
	clk      		: in std_logic;
	moveleft      	: in std_logic;
	moveright      : in std_logic;
	btn      		: in std_logic_vector(2 downto 0);
	dailout      	: out std_logic_vector(4 downto 0)
);
end moonwar_dail;

architecture struct of moonwar_dail is

signal direction  : std_logic_vector(3 downto 0);
signal count  		: std_logic_vector(3 downto 0);
signal count2  		: std_logic_vector(4 downto 0);
begin

process (clk)begin
	if (moveleft = '1') then
		direction <= "0000";
	elsif (moveright = '1') then
		direction <= "1111";
	end if;
end process;

video_gen : entity work.binary_counter
port map (
	C     	=> clk,
	CLR     	=> not moveleft or not moveright,
	Q     	=> count
);

count2 <= count +
dailout <= direction or count or btn; 
end struct;