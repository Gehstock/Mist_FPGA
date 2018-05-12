--
--  MIXER.vhd
--
--  Mix tone generator and noise generator.
--
--        Copyright (C)2001-2010 SEILEBOST
--                   All rights reserved.
--
-- $Id: MIXER.vhd, v0.50 2010/01/19 00:00:00 SEILEBOST $
--
-- A lot of work !!
-- ATTENTION : IT'S NOT USED !!

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity MIXER is
    Port ( CLK          : in     std_logic;
           CS           : in     std_logic;
           RST          : in     std_logic;
           WR           : in     std_logic;
           IN_A         : in     std_logic;
           IN_B         : in     std_logic;
           IN_C         : in     std_logic;
           IN_NOISE     : in     std_logic;
           DATA         : in     std_logic_vector(5 downto 0);
           OUT_A        : out    std_logic;
           OUT_B        : out    std_logic;
           OUT_C        : out    std_logic );
end MIXER;

architecture Behavioral of MIXER is


begin
  PROCESS(CLK, RST, CS, WR, DATA, IN_A, IN_B, IN_C, IN_NOISE)
  BEGIN
  if (RST = '1') then
     OUT_A <= '0';
     OUT_B <= '0';
     OUT_C <= '0';
  elsif ( CLK'event and CLK = '1') then
    if not (CS = '1' and WR = '1') then
-- TONE A
       if (DATA(0) = '0') then
          if (DATA(3) = '0') then 
             OUT_A <= IN_A xor IN_NOISE;
          else
             OUT_A <= IN_A;
          end if;
       else 
          OUT_A <= '1';
       end if;

-- TONE B
       if (DATA(1) = '0') then
          if (DATA(4) = '0') then 
             OUT_B <= IN_B xor IN_NOISE;
          else
             OUT_B <= IN_B;
          end if;
       else 
          OUT_B <= '1';
       end if;

-- TONE C
       if (DATA(2) = '0') then
          if (DATA(5) = '0') then 
             OUT_C <= IN_C xor IN_NOISE;
          else
             OUT_C <= IN_C;
          end if;
       else 
          OUT_C <= '1';
       end if;
    end if;
  end if;
  end process;
end Behavioral;
