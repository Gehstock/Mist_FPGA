--
--  REG_ADDR.vhd
--
--  DECODER of Registre.
--
--        Copyright (C)2001 SEILEBOST
--                   All rights reserved.
--
-- $Id: REG_ADDR.vhd, v0.2 2001/11/02 00:00:00 SEILEBOST $
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity REG_ADRESSE is
    Port ( REG_ADDR : in     std_logic_vector(3 downto 0);
           RST      : in     std_logic,
           SEL_REG  : out    std_logic_vector(15 downto 0) );
end REG_ADRESSE;

architecture Behavioral of REG_ADRESSE is

-- DECODER 4 -> 16
begin

end Behavioral;
