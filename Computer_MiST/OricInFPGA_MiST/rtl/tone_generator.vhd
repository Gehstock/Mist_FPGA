--
--  TONE_GENERATOR.vhd
--
--  Generator a tone.
--
--        Copyright (C)2001 SEILEBOST
--                   All rights reserved.
--
-- $Id: TONE_GENERATOR.vhd, v0.56 2001/11/02 00:00:00 SEILEBOST $
--
-- Question : if WR is set To add one to count ?
--
-- Revision list
--
-- v0.2  2001/11/02 : Create
-- v0.46 2010/01/06 : Modification du générateur d'enveloppe 
--                    et de fréquence

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity TONE_GENERATOR is
    Port ( CLK          : in     std_logic;
	        --CLK_TONE     : in     std_logic;
           RST          : in     std_logic;
           WR           : in     std_logic;
           --CS_COARSE    : in     std_logic;
           --CS_FINE      : in     std_logic;
           DATA_COARSE  : in     std_logic_vector(7 downto 0);
           DATA_FINE    : in     std_logic_vector(7 downto 0);
           OUT_TONE     : inout  std_logic );
end TONE_GENERATOR;

architecture Behavioral of TONE_GENERATOR is

SIGNAL COUNT  : std_logic_vector(15 downto 0);
-- for debug : to clear ...
SIGNAL TMP_COUNT_MAX  : std_logic_vector(15 downto 0);
SIGNAL TMP_COUNT_FREQ : std_logic_vector(15 downto 0);
begin

 -- Génération de la fréquence de l'enveloppe
 PROCESS(CLK, RST)
 VARIABLE COUNT_FREQ : std_logic_vector(15 downto 0);
 VARIABLE COUNT_MAX  : std_logic_vector(15 downto 0);
 BEGIN
      if (RST = '1') then
         COUNT        <= "0000000000000000";
         OUT_TONE     <= '0';
      elsif ( CLK'event and  CLK = '1') then
         COUNT_FREQ := DATA_COARSE & DATA_FINE;
         if (COUNT_FREQ = x"0000") then
            COUNT_MAX := x"0000";
         else
            COUNT_MAX := (COUNT_FREQ - "1");
         end if;

         if (COUNT >= COUNT_MAX) then
            COUNT <= x"0000";
            OUT_TONE <= not OUT_TONE;
   		else
            COUNT <= (COUNT + "1");
         end if;
			
			-- for debug
			TMP_COUNT_MAX  <= COUNT_MAX;
			TMP_COUNT_FREQ <= COUNT_FREQ;
      end if;
 end process;
 
end Behavioral;
