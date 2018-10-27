--
--  GEN_CLK.vhd
--
--  GENERATOR of CLOCK.
--
--        Copyright (C)2001 SEILEBOST
--                   All rights reserved.
--
-- $Id: GEN_CLK.vhd, v0.42 2002/01/03 00:00:00 SEILEBOST $
--
-- Generate secondary CLK from CLK_MASTER
-- CLK     : Clock Master, 16 MHz
-- CLK_16  : for the tone generator,
-- CLK_256 : for the envelope generator

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity GEN_CLK is
    Port ( CLK      : in  std_logic;
           RST      : in  std_logic;
           CLK_16   : out std_logic;
			  CLK_256  : out std_logic
          );
end GEN_CLK;

architecture Behavioral of GEN_CLK is

SIGNAL COUNT : std_logic_vector(7 downto 0);
begin

 PROCESS(CLK, RST)
 BEGIN
      if (RST = '1') then
            COUNT  <= (OTHERS => '0');
      elsif (CLK'event and CLK = '1') then
            COUNT      <= COUNT + 1;
            CLK_16     <= COUNT(3);
				CLK_256    <= COUNT(7);
      end if;
 END PROCESS;
end Behavioral;
