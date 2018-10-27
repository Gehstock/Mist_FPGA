--
--  iodecode.vhd
--
--  Manage access for I/O, Ram and Rom
--
--        Copyright (C)2001 - 2005 SEILEBOST
--                   All rights reserved.
--
-- $Id: iodecode.vhd, v0.10 2009/06/25 00:00:00 SEILEBOST $
--
-- TODO :
-- Remark :
-- 08/03/09 : Retour en arrière
Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_STD.all;
--use IEEE.std_logic_unsigned.all;

entity iodecode is
port (  RESETn  : in  std_logic;
        CLK_1   : in  std_logic;
        ADDR    : in  std_logic_vector(15 downto 0);
        ADDR_LE : in  std_logic;
        MAPn    : in  std_logic;
        CSROMn  : out std_logic;
        CSRAMn  : out std_logic;
        CSIOn   : out std_logic
      );
end entity iodecode;

architecture iodecode_arch of iodecode is 

signal lCSROMn : std_logic;
signal lCSRAMn : std_logic;
signal lCSIOn  : std_logic;
signal lADDR   : std_logic_vector(15 downto 0);

begin

-- Latch BAP
u_laddr: PROCESS ( ADDR_LE, resetn )
begin
     if (resetn = '0') then
        lADDR<= (OTHERS => '0');
     elsif rising_edge(ADDR_LE) then
        lAddr<= Addr;
     end if;
end process;


-- PAGE I/O : 0x300-0x3FF
-- lCSIOn  <= '0' WHEN (lADDR(7 downto 0) = "00000011") AND (CLK_1 = '1') ELSE '1';
lCSIOn  <= '0' WHEN (ADDR(15 downto 8) = "00000011") AND (ADDR_LE = '1') ELSE '1';
--p_CSION : process(CLK_1)
--begin
-- lCSIOn <= '1';
-- if (rising_edge(CLK_1)) then
--    if (lADDR(7 downto 0) = "00000011") then
--            lCSION <= '0';
--    end if;
-- end if;
--end process;
         
-- PAGE ROM : 0xC000-0xFFFF   
-- lCSROMn <= '0' WHEN (lADDR(7 downto 6) = "11" AND MAPn = '1' AND CLK_1 = '1') ELSE '1'; p_CSION : process(CLK_1)
lCSROMn <= '0' WHEN (ADDR(15 downto 14) = "11" AND MAPn = '1' AND ADDR_LE = '1') ELSE '1';
--p_CSROMN : process(CLK_1)
--begin
-- lCSROMn <= '1';
-- if (rising_edge(CLK_1)) then
--    if (lADDR(7 downto 6) = "11" AND MAPn = '1') then
--            lCSROMn <= '0';
--    end if;
-- end if;
-- end process;

-- PAGR RAM : le reste ...
-- lCSRAMn <= '0' WHEN  -- Partie Ram shadow
--                      (lADDR(7 downto 6) = "11" AND MAPn = '0' AND CLK_1 = '1') 
--                   OR
--                                                  -- Partie Ram normale
--                     (    (lADDR(7 downto 0) /= "00000011" and lADDR(7 downto 6) /= "11")
--                       AND MAPn = '1' AND CLK_1 = '1')
--               ELSE '1';
lCSRAMn <= '0' WHEN  -- Partie Ram shadow
                      (ADDR(15 downto 14) = "11" AND MAPn = '0' AND ADDR_LE = '1') 
                   OR
                     -- Partie Ram normale
                     (((ADDR(15 downto 8) /= "00000011") AND (ADDR(15 downto 14) /= "11")) AND MAPn = '1' AND ADDR_LE = '1')				 
               ELSE '1';

--p_CSRAMN : process(CLK_1)
--begin
-- lCSRAMn <= '1';
-- if (rising_edge(CLK_1)) then
--    if ((lADDR(7 downto 6) = "11" AND MAPn = '0') 
--            OR ((lADDR(7 downto 0) /= "00000011" and lADDR(7 downto 6) /= "11")
--           AND MAPn = '1')) then
--            lCSRAMn <= '0';
--    end if;
-- end if;
--end process;

-- Assign output signal
CSROMn  <= lCSROMn;
CSRAMn  <= lCSRAMn;
CSIOn   <= lCSIOn;     
             
end architecture iodecode_arch;



