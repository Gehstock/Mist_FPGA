library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity SRAM is
		port(
			A 		: in std_logic_vector(15 downto 0);

			nOE	: in std_logic;
			nWE	: in std_logic;
			
			nCE1	: in std_logic;
			nUB1	: in std_logic;
			nLB1	: in std_logic;

			D		: inout std_logic_vector(7 downto 0)
	);
end SRAM;

architecture sim of SRAM is
-- write timings :
constant Thzwe : time := 6 ns;  -- nWE LOW to High-Z Output 
-- read timings :
constant Taa   : time := 12 ns; -- address access time      

constant numWords : integer := 65536; -- 262144 max;   
type memType is array (numWords-1 downto 0) of std_logic_vector( 7 downto 0); 
signal memory : memType := (others => (others => '0')); 

begin

rdMem: process (nCE1, nWE, nOE, nUB1, nLB1, A)
begin
   D <= (others => 'Z'); -- defaults to hi-Z

   if nCE1 = '0' then
     if nOE = '0' then 
       if nWE = '1' then
         if nUB1 = '1' and nLB1 = '0' then
	       D <= memory(conv_integer(to_x01(A))) after Taa;  
	      else
	       assert false report "%W : nUB1 and nLB1 are both deasserted during ram read" severity warning;
	      end if;
	    else
	      assert false report "%W : signal assertion violation : nOE and nWE asserted" severity warning;
	    end if;
     end if;
   end if;
end process;


wrMem: process (nCE1, nWE, nOE, A, D)
begin
if nCE1 = '0' then 
   if nWE= '0' then
 	   if nOE = '1' then   
		   memory(conv_integer(to_x01(A))) <= D(7 downto 0) after Thzwe; 
      else
           assert false report "%W : ubL and lbL are both deasserted during ram write" severity warning;
      end if;
   -- else
   --   assert false report "%W : signal assertion violation : oeL and weL asserted" severity warning;
   end if;
end if;

end process;
	
end sim;
