--
--  GEN_ENV.vhd
--
--  GENERATOR of ENVELOPE.
--
--        Copyright (C)2001-2010 SEILEBOST
--                   All rights reserved.
--
-- $Id: GEN_ENV.vhd, v0.50 2010/01/19 00:00:00 SEILEBOST $
--
-- NO BUGS  
-- NEARLY TESTED
-- 
-- Revision list
--
-- v0.4  2001/11/21 : Modification
-- v0.46 2010/01/06 : Modification du générateur d'enveloppe 
--                    et de fréquence

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity gen_env is
    Port ( CLK_ENV      : in      std_logic;
           DATA         : in      std_logic_vector(3 downto 0);
           RST_ENV      : in      std_logic;
           WR           : in      std_logic;
           --CS           : in      std_logic;
           OUT_DATA     : inout   std_logic_vector(3 downto 0) );
end gen_env;

architecture Behavioral of gen_env is

SIGNAL DIR   : std_logic; -- direction
SIGNAL HOLD  : std_logic; -- continue the sound

begin

 PROCESS(CLK_ENV, RST_ENV, DATA, WR)
  variable isMin       : boolean;
  variable isNearlyMin : boolean;
  variable isNearlyMax : boolean;
  variable isMax       : boolean;
 BEGIN
    if (RST_ENV = '1') then  -- Reset : to load the good value to generate enveloppe
       if (DATA(2) = '0') then -- front initial : 0 = descendant et 1 = montant 
 	       OUT_DATA <= "1111";
          DIR      <= '0';
		 else
		    OUT_DATA <= "0000";
          DIR      <= '1';
	    end if;
		 HOLD     <= '0';
    elsif (CLK_ENV'event and CLK_ENV = '1') then -- edge clock
	    -- To simply the written code ! 
       isMin       := (OUT_DATA = "00000");
       isNearlyMin := (OUT_DATA = "00001");
       isNearlyMax := (OUT_DATA = "11110");
       isMax       := (OUT_DATA = "11111");
		 
		 -- To manage the next value
		 if (HOLD = '0') then
		    if (DIR = '0') then
             OUT_DATA <= OUT_DATA - 1;
          else
             OUT_DATA <= OUT_DATA + 1;
          end if;
       end if;					 
		 
		 -- To generate the shape of envelope
       if (DATA(3) = '0') then
          if (DIR = '0') then 
			    if (isNearlyMin) then
                HOLD <= '1';
				 end if;
			 else
			    if (isMax) then
				    HOLD <= '1'; -- Astuce : il faut que OUT_DATE = "0000" au prochain tick donc comparaison de la sortie sur "1111" car incrementation automatique
				 end if;
		    end if;
       else
		     if (DATA(0) = '1') then -- hold = 1
              if (DIR = '0') then -- down
                if (DATA(1) = '1') then -- alt
                  if isMin    then HOLD <= '1'; end if;
                else
                  if isNearlyMin then HOLD <= '1'; end if;
                end if;
              else
                if (DATA(1) = '1') then -- alt
                  if isMax    then HOLD <= '1'; end if;
                else
                  if isNearlyMax then HOLD <= '1'; end if;
                end if;
              end if;
           elsif (DATA(1) = '1') then -- alternate
              if (DIR = '0') then -- down
                if isNearlyMin then HOLD <= '1'; end if;
                if isMin       then HOLD <= '0'; DIR <= '1'; end if;
              else
                if isNearlyMax then HOLD <= '1'; end if;
                if isMax    then HOLD <= '0'; DIR <= '0'; end if;
              end if;
           end if;
		 end if;
    end if; -- fin elsif
 END PROCESS;

end Behavioral;
