--
--  addmenux.vhd
--
--  Manage bus address multiplexer
--
--        Copyright (C)2001 - 2005 SEILEBOST
--                   All rights reserved.
--
-- $Id: addmenux.vhd, v0.10 2009/06/25 00:00:00 SEILEBOST $
-- MODIFICATION :
--   v0.01 : 200X/??/??
--   v0.10 : 2009/06/25 : Intégration de la partie multiplexage de l'accès ram
-- TODO :
--
-- TODO :
-- Remark :

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_STD.all;
--use IEEE.std_logic_unsigned.all;

entity addmemux is
port (  RESETn   : in  std_logic;
        VAP1     : in  std_logic_vector(15 downto 0);-- Video address phase 1
        VAP2     : in  std_logic_vector(15 downto 0);-- Video address phase 2
        BAP      : in  std_logic_vector(15 downto 0);-- Bus address processor (A15-A0)
        VA1L     : in  std_logic;                    -- Video address phase 1 LATCH
        VA1R     : in  std_logic;                    -- Video address phase 1 ROW
        VA1C     : in  std_logic;                    -- Video address phase 1 COLUMN
        VA2L     : in  std_logic;                    -- Video address phase 2 LATCH
        VA2R     : in  std_logic;                    -- Video address phase 2 ROW
        VA2C     : in  std_logic;                    -- Video address phase 2 COLUMN
        BAC      : in  std_logic;                    -- Bus address COLUMN
        BAL      : in  std_logic;                    -- Bus address LATCH
        AD_DYN   : out std_logic_vector(15 downto 0) -- Address Bus dynamic
      );
end entity addmemux;

architecture addmemux_arch of addmemux is

signal lVAP1 : std_logic_vector(15 downto 0);
signal lVAP2 : std_logic_vector(15 downto 0);
signal lBAP  : std_logic_vector(15 downto 0);

begin

-- Latch VAP1 
u_VAP1 : PROCESS ( VAP1, VA1L,resetn )
begin
     if (resetn = '0') then
        lVAP1 <= (OTHERS => '0');
     elsif rising_edge(VA1L) then
        lVAP1 <= VAP1;
     end if;
end process;

-- Latch VAP2
u_VAP2 : PROCESS ( VAP2, VA2L, resetn )
begin
     if (resetn = '0') then
         lVAP2 <= (OTHERS => '0');
     elsif rising_edge(VA2L) then
        lVAP2 <= VAP2;
     end if;
end process;

-- Latch BAP
u_BAP: PROCESS ( BAP, BAL, resetn )
begin
     if (resetn = '0') then
        lBAP<= (OTHERS => '0');
     elsif rising_edge(BAL) then
        lBAP<= BAP;
     end if;
end process;

-- Assignation

 AD_DYN <= lVAP1(15 downto 0) when VA1R = '1' else
 --          lVAP1(7  downto 0) when VA1C = '1' else
           lVAP2(15 downto 0) when VA2R = '1' else
 --          lVAP2(7  downto 0) when VA2C = '1' else
 --          lBAP               when BAL  = '1' else
 --          (OTHERS => 'Z');
           lBAP;         
end architecture addmemux_arch;
