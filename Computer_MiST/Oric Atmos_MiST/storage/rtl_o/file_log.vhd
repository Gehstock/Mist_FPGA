----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:00:59 03/08/2011 
-- Design Name: 
-- Module Name:    file_log - Behavioral 
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
  
entity FILE_LOG is
  generic (
           log_file:       string  := "res.log"
          );
  port(
       CLK              : in std_logic;
       RST              : in std_logic;
       x1               : in std_logic_vector(7  downto 0);
       x2               : in std_logic_vector(7  downto 0);
		 x3               : in std_logic_vector(15 downto 0);
		 x4               : in std_logic_vector(2  downto 0);
		 x5               : in std_logic
      );
end FILE_LOG;
   
   
architecture log_to_file of FILE_LOG is
  
file l_file: TEXT open write_mode is log_file;

begin

-- write data and control information to a file

receive_data: process (CLK,RST)

variable l: line;
   
begin                                       
  if (RST = '0') then
			print(l_file, "#x3(AD)   x1(IN)   x2(OUT)  RGB  SYNC");
			print(l_file, "#------------------------------------");
			print(l_file, " ");	
  elsif (clk'event and clk='1') then
         write(l,  hstr(x3)& "   " &  hstr(x1) & "h  " & hstr(x2)& "h  " &hstr(x4)& "h  " &chr(x5));
         writeline(l_file, l); 
  end if;
		
end process receive_data;

end log_to_file;
 