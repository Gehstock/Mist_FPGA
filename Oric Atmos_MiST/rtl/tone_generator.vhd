--
--  TONE_GENERATOR.vhd
--
--  Generator a tone.
--
--        Copyright (C)2001 SEILEBOST
--                   All rights reserved.
--
-- $Id: TONE_GENERATOR.vhd, v0.2 2001/11/02 00:00:00 SEILEBOST $
--
-- Question : if WR is set To add one to count ?

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity TONE_GENERATOR is
    Port ( CLK          : in     std_logic;
           RST          : in     std_logic;
           WR           : in     std_logic;
           CS_COARSE    : in     std_logic;
           CS_FINE      : in     std_logic;
           DATA_COARSE  : in     std_logic_vector(7 downto 0);
           DATA_FINE    : in     std_logic_vector(7 downto 0);
           OUT_TONE     : inout  std_logic );
end TONE_GENERATOR;

architecture Behavioral of TONE_GENERATOR is

SIGNAL COUNT : std_logic_vector(15 downto 0);

begin

 PROCESS(CLK, RST,CS_COARSE, CS_FINE)
 BEGIN
      if (RST = '1') then
         COUNT        <= "0000000000000000";
         OUT_TONE     <= '0';
      elsif (CLK'event and CLK = '1') then         
            if (WR = '1') then
               if (CS_FINE = '1') then
                  COUNT(7 downto 0) <= DATA_FINE;                               
               elsif (CS_COARSE = '1') then
                  COUNT(15 downto 8) <= DATA_COARSE;
               end if;
            else
               if (COUNT = "0000000000000000") then
                  COUNT(15 downto 8) <= DATA_COARSE;
                  COUNT(7  downto 0) <= DATA_FINE;  
                  OUT_TONE           <= NOT OUT_TONE;
               else
                  COUNT <= COUNT - 1;
               end if;
            end if;
      end if;
 end process;
 
end Behavioral;
