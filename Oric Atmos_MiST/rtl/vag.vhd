--
--  vag.vhd
--
--  Generate video signals
--
--        Copyright (C)2001 - 2005 SEILEBOST
--                   All rights reserved.
--
-- $Id: vag.vhd, v0.01 2005/01/01 00:00:00 SEILEBOST $
--
-- TODO :
-- Remark :

library IEEE;
use IEEE.std_logic_1164.all;
--use IEEE.std_logic_arith.all;
--use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity vag is
port (  CLK_1      : in  std_logic;
        RESETn     : in  std_logic;
        FREQ_SEL   : in  std_logic;                     -- Select 50/60 Hz frequency
        CPT_H      : out std_logic_vector(6 downto 0);  -- Horizontal Counter
        CPT_V      : out std_logic_vector(8 downto 0);  -- Vertical Counter
        RELOAD_SEL : out std_logic;                     -- Reload registe SEL
        FORCETXT   : out std_logic;                     -- Force Mode Text
        CLK_FLASH  : out std_logic;                     -- Flash Clock
        COMPSYNC   : out std_logic;                     -- Composite Synchro signal
        BLANKINGn  : out std_logic                      -- Blanking signal
      );
end entity vag;

architecture vag_arch of vag is 

signal lCPT_H      : std_logic_vector(6 downto 0);
signal lCPT_V      : std_logic_vector(8 downto 0);
signal lCPT_FLASH  : std_logic_vector(5 downto 0);
signal lVSYNCn     : std_logic;
signal lVBLANKn    : std_logic;
signal lVFRAME     : std_logic;
signal lFORCETXT   : std_logic;
signal lHSYNCn     : std_logic;
signal lHBLANKn    : std_logic;
signal lRELOAD_SEL : std_logic;
signal lCLK_V      : std_logic;

begin

-- Horizontal Counter 
u_CPT_H: PROCESS(CLK_1, RESETn)
BEGIN
     IF (RESETn = '0') THEN
        lCPT_H  <= (OTHERS => '0');
     ELSIF rising_edge(CLK_1) THEN
        IF lCPT_H < 63 then
           lCPT_H <= lCPT_H + "0000001";
        ELSE       
           lCPT_H <= (OTHERS => '0');
        END IF;                             
     END IF;
END PROCESS;

-- Horizontal Synchronisation
lHSYNCn  <= '0' when (lCPT_H >= 49) AND (lCPT_H <= 53) ELSE '1';

-- Horizontal Blank
lHBLANKn <= '0' when (lCPT_H >= 40) AND (lCPT_H <= 63) ELSE '1';

-- Signal to Reload Register to reset attribut
lRELOAD_SEL <= '1' WHEN (lCPT_H >= 56) AND (lCPT_H <= 63) ELSE '0';

-- Clock for Vertical counter
lCLK_V      <= '1' WHEN (lCPT_H = 63) ELSE '0';

-- Vertical Counter
u_CPT_V: PROCESS(lCLK_V, RESETn)
BEGIN
     IF (RESETn = '0') THEN
        lCPT_V <= (OTHERS => '0');
     ELSIF rising_edge(lCLK_V) THEN
        IF (lCPT_V < 311) THEN
           lCPT_V <= lCPT_V + "000000001";
        ELSE
           lCPT_V <= (OTHERS => '0');
        END IF;
     END IF;    
END PROCESS;

-- Vertical Synchronisation
lVSYNCn  <= '0' when(lCPT_V >= 258) AND (lCPT_V <= 259) ELSE '1';

-- Vertical Blank
lVBLANKn <= '0' when(lCPT_V >= 224) AND (lCPT_V <= 311) ELSE '1';

-- Clock to Flash Counter
lVFRAME   <= '1' WHEN (lCPT_V = 311) ELSE '0';

-- Signal To Force TEXT MODE
lFORCETXT <= '1' WHEN (lCPT_V > 199) ELSE '0'; 

-- Flash Counter
u_FLASH : PROCESS( lVSYNCn, RESETn )
BEGIN
 IF (RESETn = '0') THEN
    lCPT_FLASH <= (OTHERS => '0');
 ELSIF rising_edge(lVSYNCn) THEN
    lCPT_FLASH <= lCPT_FLASH + "000001";
 END IF;    
END PROCESS;

-- Assign signals
FORCETXT   <= '1' WHEN ((lFORCETXT = '1') OR (lVFRAME = '1') ) ELSE '0';
CLK_FLASH  <= lCPT_FLASH(5);
RELOAD_SEL <= lRELOAD_SEL;
COMPSYNC   <= NOT(lHSYNCn XOR lVSYNCn);

-- Assign counters
CPT_H     <= lCPT_H;
CPT_V     <= lCPT_V;

-- Assign blanking signal
BLANKINGn <= lVBLANKn AND lHBLANKn;

end architecture vag_arch;
