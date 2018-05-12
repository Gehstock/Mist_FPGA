----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:12:00 08/14/2011 
-- Design Name: 
-- Module Name:    psg_log - Behavioral 
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
  
entity psg_log is
  generic (
           log_psg:       string  := "psg.log"
          );
  port(
       CLK              : in std_logic;
       RST              : in std_logic;
       x1               : in std_logic
      );
end psg_log;
 
architecture log_to_file of psg_log is
  
file l_file_psg: TEXT open write_mode is log_psg;

begin

-- write data and control information to a file

receive_data: process (CLK,RST)

variable l: line;
   
begin                                       
  if (RST = '0') then
	  print(l_file_psg, "");	
  elsif (clk'event and clk='1') then
     write(l,  chr(x1));
     writeline(l_file_psg, l); 
  end if;
		
end process receive_data;

end log_to_file;
 