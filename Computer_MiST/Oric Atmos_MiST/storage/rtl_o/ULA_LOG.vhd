----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:12:00 08/14/2011 
-- Design Name: 
-- Module Name:    ula_log - Behavioral 
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
library ieee;
use ieee.std_logic_1164.all;

use std.textio.all;
use work.txt_util.all;
  
entity ula_log is
  generic (
           log_ula:       string  := "ula.log"
          );
  port(
       CLK              : in std_logic;
       RST              : in std_logic;
       x1               : in std_logic_vector(7 downto 0);
		 x2               : in std_logic_vector(15 downto 0);
		 x3               : in std_logic
      );
end ula_log;
 
architecture log_to_file of ula_log is
  
file l_file_ula: TEXT open write_mode is log_ula;

begin

-- write data and control information to a file

receive_data: process (CLK,RST)

variable l: line;
variable cnt : integer:=0;
 
begin                                       
  if (RST = '0') then
	  print(l_file_ula, "---- 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23");	
	  
  elsif (clk'event and clk='0') then
    -- Low period of PHI2
    if (x3 ='0') then
	   if (cnt = 0) then
		   write (l, hstr(x2) & " " & hstr(x1) & " ");
		else
		   -- Je récupére que le code ASCII 
		   if (cnt mod 2 = 0) then
		      write(l, hstr(x1) & " ");
			end if;
		end if;
		
		cnt:=cnt+1;
		
		-- Il y a 64 pixels dont 40 utiles par ligne et deux accès à la mémoire donc 64 X 2 = 128
		if (cnt = 128) then
			writeline(l_file_ula, l); 
			cnt:=0;
		end if;
    end if;
  end if;
		
end process receive_data;

end log_to_file;
 