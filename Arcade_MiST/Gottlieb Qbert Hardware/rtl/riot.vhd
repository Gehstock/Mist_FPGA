-- MOS 6532 RIOT chip, built upon the A2600 RIOT by Adam Wozniak. This 
-- has been modified to have separate input and output ports for easier
-- implementation into modern FPGA designs.
-- James Sweet 2015

--
-- Distributed under the Gnu General Public License
--
-- riot.vhdl ; VHDL implementation of Atari 2600 RIOT chip
-- Copyright (C) 2003,2004 Adam Wozniak
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 2 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
--
-- The author may be contacted
-- by email: adam@cuddlepuddle.org
-- by snailmail: Adam Wozniak, 1352 - 14th Street, Los Osos, CA 93402

-- RIOT implementation

-- Works with :
--   Space Invaders
--   Asteroids
--   Missile Command
--   Pesco
--   Pitfall
--   Cosmic Ark

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity RIOT is
   port(  
   PHI2   	: in  std_logic;
   RES_N  	: in  std_logic;
   CS1    	: in  std_logic;
   CS2_N  	: in  std_logic;
   RS_N   	: in  std_logic;
   R_W    	: in  std_logic;
   A      	: in  std_logic_vector(6 downto 0);
   D_I      : in 	std_logic_vector(7 downto 0);
	D_O		: out std_logic_vector(7 downto 0) := (others => 'Z');
   --  NOTE: for true emulation, PA and PB should all have weak pullups
	PA_I		: in	std_logic_vector(7 downto 0) := (others => '1');
   PA_O     : out std_logic_vector(7 downto 0) := (others => 'Z');
	DDRA_O	: out std_logic_vector(7 downto 0);
	PB_I		: in	std_logic_vector(7 downto 0) := (others => '1');
   PB_O   	: out 	std_logic_vector(7 downto 0) := (others => 'Z');
	DDRB_O	: out std_logic_vector(7 downto 0);
   IRQ_N  	: out std_logic := '1'
   );
end RIOT;

architecture ARCH of RIOT is
   type RAMTYPE is array (127 downto 0) of std_logic_vector(7 downto 0);
   signal RAM             : RAMTYPE;
   
   type   PERIODTYPE is    (TIM1T, TIM8T, TIM64T, TIM1024T);
   signal PERIOD          : PERIODTYPE := TIM1T;
   
   signal DDRA            : std_logic_vector(7 downto 0) := "00000000";
   signal DDRB            : std_logic_vector(7 downto 0) := "00000000";
   signal ORA             : std_logic_vector(7 downto 0) := "00000000";
   signal ORB             : std_logic_vector(7 downto 0) := "00000000";
   signal PA7FLAG         : std_logic := '0';
   signal TIMERFLAG       : std_logic := '0';
   signal PA7FLAGENABLE   : std_logic := '0';
   signal TIMERFLAGENABLE : std_logic := '0';
   signal EDGEDETECT      : std_logic := '0';
   
   signal PA7CLEARNEED    : std_logic := '0';
   signal PA7CLEARDONE    : std_logic := '0';
   
   signal TIMERCLEARNEED  : std_logic := '0';
   signal TIMERCLEARDONE  : std_logic := '0';
   
   signal COUNTER   : std_logic_vector(18 downto 0) := "0000000000000000000";
   
begin
   
   IRQ_N <= not ((TIMERFLAG and TIMERFLAGENABLE) or (PA7FLAG and PA7FLAGENABLE));
   
   -- For all functions, R_W and A are valid on the rising edge of PHI2
   -- D_I must be stable by the falling edge of PHI2
   
   process(PHI2)
   begin
      if PHI2'event and PHI2 = '1' then                                    --! [0]
         if RES_N = '1' and CS1 = '1' and CS2_N = '0' then                 --! [1]
            if R_W = '1' then                                              --! [2]
               if RS_N = '0' then                                          --! [3]
                  D_O <= RAM(CONV_INTEGER(A));
               else                                                        --! [3]
                  if A(2) = '0' then                                       --! [4]
                     if A(1 downto 0) = "00" then                          --! [5]
                        D_O <= PA_I;
                     elsif A(1 downto 0) = "01" then                       --! [5]
                        D_O <= DDRA;
                     elsif A(1 downto 0) = "10" then                       --! [5]
                        D_O <= PB_I;
                     elsif A(1 downto 0) = "11" then                       --! [5]
                        D_O <= DDRB;
                     end if;                                               --! [5]
                  else                                                     --! [4]
                     if A(0) = '0' then                                    --! [6]
                        TIMERCLEARNEED <= not TIMERCLEARNEED;
                        if COUNTER(18) = '1' then                          --! [7]
                           D_O <= COUNTER(7 downto 0);
                        else                                               --! [7]
                           if PERIOD = TIM1T then                          --! [8]
                              D_O <= COUNTER(7 downto 0);
                           elsif PERIOD = TIM8T then                       --! [8]
                              D_O <= COUNTER(10 downto 3);
                           elsif PERIOD = TIM64T then                      --! [8]
                              D_O <= COUNTER(13 downto 6);
                           elsif PERIOD = TIM1024T then                    --! [8]
                              D_O <= COUNTER(17 downto 10);
                           end if;                                         --! [8]
                        end if;                                            --! [7]
                     else                                                  --! [6]
                        D_O(7) <= TIMERFLAG;
                        D_O(6) <= PA7FLAG;
                        D_O(5 downto 0) <= "000000";
                        PA7CLEARNEED <= not PA7CLEARNEED;
                     end if;                                               --! [6]
                  end if;                                                  --! [4]
               end if;                                                     --! [3]
            else                                                           --! [2]
               D_O <= "ZZZZZZZZ";
            end if;                                                        --! [2]
         else                                                              --! [1]
            D_O <= "ZZZZZZZZ";
         end if;                                                           --! [1]
      end if;                                                              --! [0]
   end process;
   
   process(PHI2)
   begin
      if PHI2'event and PHI2 = '0' then                                    --! [9]
         
         if EDGEDETECT = PA_I(7) then                                        --! [10]
            PA7FLAG <= '1';
         end if;                                                           --! [10]
         
         if COUNTER(18) = '1' then                                         --! [11]
            PERIOD <= TIM1T;
            TIMERFLAG <= '1';
         end if;                                                           --! [11]
         
         COUNTER <= COUNTER - "0000000000000000001";
         
         if PA7CLEARNEED /= PA7CLEARDONE then                              --! [12]
            PA7CLEARDONE <= PA7CLEARNEED;
            PA7FLAG <= '0';
         end if;                                                           --! [12]
         
         if TIMERCLEARNEED /= TIMERCLEARDONE then                          --! [13]
            TIMERCLEARDONE <= TIMERCLEARNEED;
            TIMERFLAG <= '0';
         end if;                                                           --! [13]
         
         if RES_N = '1' and CS1 = '1' and CS2_N = '0' then                 --! [14]
            if R_W = '0' then                                              --! [15]
               if RS_N = '0' then                     -- ram               --! [16]
                  RAM(CONV_INTEGER(A)) <= D_I;
                  --                  COUNTER <= COUNTER - "0000000000000000001";
               else                                                        --! [16]
                  if A(2) = '0' then                                       --! [17]
                     if A(1 downto 0) = "00" then                          --! [18]
                        ORA <= D_I;
                     elsif A(1 downto 0) = "01" then                       --! [18]
                        DDRA <= D_I;
                     elsif A(1 downto 0) = "10" then                       --! [18]
                        ORB <= D_I;
                     elsif A(1 downto 0) = "11" then                       --! [18]
                        DDRB <= D_I;
                     end if;                                               --! [18]
                     --                    COUNTER <= COUNTER - "0000000000000000001";
                  else                                                     --! [17]
                     if A(4) = '1' then                                    --! [19]
                        if A(1 downto 0) = "00" then                       --! [20]
                           PERIOD <= TIM1T;
                           COUNTER(18 downto 8) <= "00000000000";
                           COUNTER(7 downto 0) <= D_I;
                           TIMERFLAG <= '0';
                        elsif A(1 downto 0) = "01" then                    --! [20]
                           PERIOD <= TIM8T;
                           COUNTER(18 downto 11) <= "00000000";
                           COUNTER(10 downto 3) <= D_I;
                           COUNTER(2 downto 0) <= "000";
                           TIMERFLAG <= '0';
                        elsif A(1 downto 0) = "10" then                    --! [20]
                           PERIOD <= TIM64T;
                           COUNTER(18 downto 14) <= "00000";
                           COUNTER(13 downto 6) <= D_I;
                           COUNTER(5 downto 0) <= "000000";
                           TIMERFLAG <= '0';
                        else                                               --! [20]
                           PERIOD <= TIM1024T;
                           COUNTER(18) <= '0';
                           COUNTER(17 downto 10) <= D_I;
                           COUNTER(9 downto 0) <= "0000000000";
                           TIMERFLAG <= '0';
                        end if;                                            --! [20]
                        TIMERFLAGENABLE <= A(3);
                     else                                                  --! [19]
                        if A(2) = '1' then                                 --! [21]
                           PA7FLAGENABLE <= A(1);
                           EDGEDETECT <= A(0);
                        end if;                                            --! [21]
                        --                      COUNTER <= COUNTER - "0000000000000000001";
                     end if;                                               --! [19]
                  end if;                                                  --! [17]
               end if;                                                     --! [16]
            else                                                           --! [15]
               if A(2) = '1' and A(0) = '0' then                           --! [22]
                  TIMERFLAGENABLE <= A(3);
               end if;                                                     --! [22]
               --             COUNTER <= COUNTER - "0000000000000000001";
            end if;                                                        --! [15]
         else                                                              --! [14]
            if RES_N = '0' then                                            --! [23]
               ORA  <= "00000000";
               ORB  <= "00000000";
               DDRA <= "00000000";
               DDRB <= "00000000";
               PA7FLAG         <= '0';
               TIMERFLAG       <= '0';
               PA7FLAGENABLE   <= '0';
               TIMERFLAGENABLE <= '0';
               EDGEDETECT      <= '0';
               PERIOD          <= TIM1T;
               COUNTER <= "0000000000000000000";
               --            else
               --               COUNTER <= COUNTER - "0000000000000000001";
            end if;                                                        --! [23]
         end if;                                                           --! [14]
      end if;                                                              --! [9]
   end process;
   
   -- I/O port handling
   process(ORA,DDRA,ORB,DDRB)
   begin
      for i in 7 downto 0 loop
         if DDRA(i) = '1' then                                             --! [24]
            PA_O(i) <= ORA(i);
         else                                                              --! [24]
            PA_O(i) <= 'Z';
         end if;                                                           --! [24]
         if DDRB(i) = '1' then                                             --! [25]
            PB_O(i) <= ORB(i);
         else                                                              --! [25]
            PB_O(i) <= 'Z';
         end if;                                                           --! [25]
      end loop;
   end process;
   DDRA_O <= DDRA;
	DDRB_O <= DDRB;
end;
