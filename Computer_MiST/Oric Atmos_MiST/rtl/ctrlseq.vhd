--
--  ctrlseq.vhd
--
--  Manage internal register
--
--        Copyright (C)2001 - 2005 SEILEBOST
--                   All rights reserved.
--
-- $Id: ctrlseq.vhd, v0.01 2005/01/01 00:00:00 SEILEBOST $
--
-- TODO :
-- Remark :


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
--use IEEE.std_logic_arith.all;
--use IEEE.numeric_std.all;

entity ctrlseq is
port (  RESETn       : in  std_logic; -- RESET
        CLK_24       : in  std_logic; -- 2 x CLOCK SYSTEM
        TXTHIR_DEC   : in  std_logic; -- TeXT HIRes DECode signal
        isAttrib     : in  std_logic; -- Is a attribute byte
        iRW          : in  std_logic; -- Read/Write signal from CPU
        CSRAMn       : in  std_logic; -- SELECT RAM (Active low)
 -- OUTPUTS       
        CLK_1_CPU    : out std_logic; -- CLK for CPU
	     CLK_4        : out std_logic; -- CLK internal for VIA
		  CLK_6        : out std_logic; -- CLK internal for video generation
        VA1L         : out std_logic; -- VIDEO ADDRESS PHASE1 LATCH
        VA1R         : out std_logic; -- VIDEO ADDRESS PHASE1 ROW
        VA1C         : out std_logic; -- VIDEO ADDRESS PHASE1 COLUMN
        VA2L         : out std_logic; -- VIDEO ADDRESS PHASE2 LATCH
        VA2R         : out std_logic; -- VIDEO ADDRESS PHASE2 ROW
        VA2C         : out std_logic; -- VIDEO ADDRESS PHASE2 COLUMN
        BAC          : out std_logic; -- BUS ADDRESS COLUMN
        BAL          : out std_logic; -- BUS ADDRESS LATCH
        RAS          : out std_logic; -- RAS FOR DYNAMIC RAM
        CAS          : out std_logic; -- CAS FOR DYNAMIC RAM
        MUX          : out std_logic; -- MUX
        oRW          : out std_logic; -- Output Read/Write 
        ATTRIB_DEC   : out std_logic; -- Decode attribute
        LD_REG_0     : out std_logic; -- Initialization of video register
        LD_REG       : out std_logic; -- Load data into video register
        LDFROMBUS    : out std_logic; -- Load data from data bus
        DATABUS_EN   : out std_logic; -- Enable data bus 
-- ajout du 09/02/09
        BAOE         : out std_logic; -- Output enable for ram/rom
-- ajout du 03/04/09        
        SRAM_CE      : out std_logic; -- Chip select enable for SRAM
        SRAM_OE      : out std_logic; -- Ouput enable for SRAM
        SRAM_WE      : out std_logic; -- Write enable for SRAM =1 for a read cycle
		  LATCH_SRAM   : out std_logic; -- Latch data from SRAM for cpu
-- FOR DEBUG/TESTBENCH
	c0_out       : out std_logic;
	c1_out       : out std_logic;
	c2_out       : out std_logic;
	c3_out       : out std_logic;
	c4_out       : out std_logic;
	c5_out       : out std_logic;
	c6_out       : out std_logic;
	c7_out       : out std_logic;
	CLK_12       : out std_logic;
	TB_CPT       : out std_logic_vector(4 downto 0)
      );
end entity ctrlseq;

architecture ctrlseq_arch of ctrlseq is

signal lCPT_GEN  : std_logic_vector(4 downto 0);  -- counter
signal lstate    : std_logic_vector(23 downto 0); -- states
signal lreload   : std_logic;                     -- to reload null value to lCPT_GEN
signal lld_reg_p : std_logic;                     -- to load value into register for VIDEO

signal c_ras     : std_logic; -- RAS
signal c_cas     : std_logic; -- CAS
signal c_mux     : std_logic; -- MUX
signal c_clk_cpu : std_logic; -- CLK_CPU

-- Phase P0
signal c_0       : std_logic; -- state number 0
signal c_1       : std_logic; -- state number 1
signal c_2       : std_logic; -- state number 2
signal c_3       : std_logic; -- state number 3
signal c_4       : std_logic; -- state number 4
signal c_5       : std_logic; -- state number 5
signal c_6       : std_logic; -- state number 6
signal c_7       : std_logic; -- state number 7
-- Phase P1
signal c_8       : std_logic; -- state number 8
signal c_9       : std_logic; -- state number 9
signal c_10      : std_logic; -- state number 10
signal c_11      : std_logic; -- state number 11
signal c_12      : std_logic; -- state number 12
signal c_13      : std_logic; -- state number 13
signal c_14      : std_logic; -- state number 14
signal c_15      : std_logic; -- state number 15
-- Phase P2
signal c_16      : std_logic; -- state number 16
signal c_17      : std_logic; -- state number 17
signal c_18      : std_logic; -- state number 18
signal c_19      : std_logic; -- state number 19
signal c_20      : std_logic; -- state number 20
signal c_21      : std_logic; -- state number 21
signal c_22      : std_logic; -- state number 22
signal c_23      : std_logic; -- state number 23

signal p_0       : std_logic; -- phase number 0
signal p_1       : std_logic; -- phase number 1
signal p_2       : std_logic; -- phase number 2

-- Constants for states
-- Phase P0
constant cd_step_0 : integer :=0;
constant cd_step_1 : integer :=1;
constant cd_step_2 : integer :=2;
constant cd_step_3 : integer :=3;
constant cd_step_4 : integer :=4;
constant cd_step_5 : integer :=5;
constant cd_step_6 : integer :=6;
constant cd_step_7 : integer :=7;
-- Phase P1
constant cd_step_8 : integer :=8;
constant cd_step_9 : integer :=9;
constant cd_step_10: integer :=10;
constant cd_step_11: integer :=11;
constant cd_step_12: integer :=12;
constant cd_step_13: integer :=13;
constant cd_step_14: integer :=14;
constant cd_step_15: integer :=15;
-- Phase P2
constant cd_step_16: integer :=16;
constant cd_step_17: integer :=17;
constant cd_step_18: integer :=18;
constant cd_step_19: integer :=19;
constant cd_step_20: integer :=20;
constant cd_step_21: integer :=21;
constant cd_step_22: integer :=22;
constant cd_step_23: integer :=23;

begin

-- Increment counter
U_TB_CPT: PROCESS (RESETn, CLK_24)
BEGIN
  if (RESETn = '0') then
     lCPT_GEN <= "00000";
  elsif falling_edge(clk_24) then
     if (lreload = '1') then
        lCPT_GEN <= "00000";
     else
        lCPT_GEN <= lCPT_GEN + "00001";
     end if;
  end if;
END PROCESS;
lreload <= '1' when lCPT_GEN = "10111" else '0';

-- Manage states
U_SM_GEST: PROCESS(lCPT_GEN)
BEGIN
   lstate <= "000000000000000000000000";
   case lCPT_GEN(4 downto 0) is
    -- Phase P0
    when "00000" => lstate(cd_step_0) <= '1';
    when "00001" => lstate(cd_step_1) <= '1';
    when "00010" => lstate(cd_step_2) <= '1';
    when "00011" => lstate(cd_step_3) <= '1';
    when "00100" => lstate(cd_step_4) <= '1';
    when "00101" => lstate(cd_step_5) <= '1';
    when "00110" => lstate(cd_step_6) <= '1';
    when "00111" => lstate(cd_step_7) <= '1';
	-- Phase P1
    when "01000" => lstate(cd_step_8) <= '1';
    when "01001" => lstate(cd_step_9) <= '1';
    when "01010" => lstate(cd_step_10) <= '1';
    when "01011" => lstate(cd_step_11) <= '1';
    when "01100" => lstate(cd_step_12) <= '1';
    when "01101" => lstate(cd_step_13) <= '1';
    when "01110" => lstate(cd_step_14) <= '1';
    when "01111" => lstate(cd_step_15) <= '1';
	-- Phase P2
    when "10000" => lstate(cd_step_16) <= '1';
    when "10001" => lstate(cd_step_17) <= '1';
    when "10010" => lstate(cd_step_18) <= '1';
    when "10011" => lstate(cd_step_19) <= '1';
    when "10100" => lstate(cd_step_20) <= '1';
    when "10101" => lstate(cd_step_21) <= '1';
    when "10110" => lstate(cd_step_22) <= '1';
    when "10111" => lstate(cd_step_23) <= '1';	
    when others => null;
   end case;
END PROCESS;

-- Assign states
-- Phase P0
c_0  <= lstate(cd_step_0);
c_1  <= lstate(cd_step_1);
c_2  <= lstate(cd_step_2);
c_3  <= lstate(cd_step_3);
c_4  <= lstate(cd_step_4);
c_5  <= lstate(cd_step_5);
c_6  <= lstate(cd_step_6);
c_7  <= lstate(cd_step_7);
-- Phase P1
c_8  <= lstate(cd_step_8);
c_9  <= lstate(cd_step_9);
c_10 <= lstate(cd_step_10);
c_11 <= lstate(cd_step_11);
c_12 <= lstate(cd_step_12);
c_13 <= lstate(cd_step_13);
c_14 <= lstate(cd_step_14);
c_15 <= lstate(cd_step_15);
-- Phase P2
c_16 <= lstate(cd_step_16);
c_17 <= lstate(cd_step_17);
c_18 <= lstate(cd_step_18);
c_19 <= lstate(cd_step_19);
c_20 <= lstate(cd_step_20);
c_21 <= lstate(cd_step_21);
c_22 <= lstate(cd_step_22);
c_23 <= lstate(cd_step_23);

-- Three phases
p_0  <= NOT lCPT_GEN(4) and NOT lCPT_GEN(3); -- 00
p_1  <= NOT lCPT_GEN(4) and lCPT_GEN(3);     -- 01
p_2  <=     lCPT_GEN(4) and NOT lCPT_GEN(3); -- 10

--------------------------------
-- GENERATION DE LA CLOCK CPU --
--------------------------------
CLK_1_CPU <= p_2;

---------------------------------
-- GESTION DE LA RAM DYNAMIQUE --
---------------------------------
ras <= c_2 or c_3 or c_4 or c_5  or c_10 or c_11 or c_12 or c_13 or c_18 or c_19 or c_20 or c_20;
cas <= not (c_2 or c_3) and  not (c_10 or c_11) and not (c_18 or c_19);
-- Mux permet de slectionner soit l'adresse haute d'une adresse cpu
-- soit l'adresse haute d'une adresse ula
mux <= '1' when ((c_1 = '1' or c_2 = '1') and p_2 = '1') else '0';
oRW <= iRW and p_2;

---------------------------------
-- GESTION DE LA RAM STATIQUE  --
---------------------------------
SRAM_OE <= not (c_2 or c_3) and not (c_10 or c_11) and not iRW ;
SRAM_CE <= not (c_1 or c_2 or c_3 or c_4) and not (c_9 or c_10 or c_11 or c_12) AND (CSRAMn or not (c_19 or c_20));
SRAM_WE <= CSRAMn or not (c_19 or c_20) or irW;
LATCH_SRAM <= not c_4 and not c_12 and not c_20; -- le 19/12/2011 : Ajout not c_4 and c_12 à not c_20

---------------------
-- GESTION INTERNE --
---------------------

--Generation pour la gestion de l'adresse video 1
VA1L <= '1' when (c_1='1') ELSE '0';
--VA1R <= '1' when (c_1='1' or c_2='1')  ELSE '0';
VA1R <= '1' when (p_0='1')  ELSE '0';
VA1C <= '1' when (c_3='1' or c_4='1' or c_5='1') ELSE '0';

--Generation pour la gestion de l'adresse video 2
VA2L <= '1' when (c_8='1') ELSE '0';
--VA2R <= '1' when (c_8='1'  or c_9='1') ELSE '0';
VA2R <= '1' when (p_1='1')  ELSE '0';
VA2C <= '1' when (c_10='1' or c_11='1' or c_12='1') ELSE '0';

--Generation pour la gestion de l'adresse CPU
BAL  <= '1' when (c_17='1' or c_18='1' or c_19='1' or c_20='1' or c_21='1' or c_22='1' or c_23='1') ELSE '0';
--Modif. du 22/02/09 BAC  <= '1' when ((c_3='1' or c_4='1' or c_5='1') and p_2='1' and CSRAMn='0') ELSE '0';
BAC  <= '1' when (c_19='1' or c_20='1' or c_21='1')  ELSE '0';
-- Ajout du 09/02/09 : output enable pour la rom/ram lors de l'adressage par le CPU
BAOE <= '1' when (c_18='1') ELSE '0';

--Pour la partie video 
-- 27/07/09 lld_reg_p   <= NOT isAttrib and c_7 and NOT TXTHIR_DEC;
-- 27/07/09 c_7 aurait du tre c_15 en ram dynamique 
-- 27/07/09 en ram statique :
-- 11/11/09 Modif c_10 en c_11
lld_reg_p   <= not isAttrib and c_11 and NOT TXTHIR_DEC; -- Partie texte

-- 04/12/09 ATTRIB_DEC  <= '1' when (isAttrib='1' and  c_10='1')  ELSE '0';
--ATTRIB_DEC  <= '1' when (c_4='1')  ELSE '0';
-- 04/12/09 LD_REG_0    <= '1' when (isAttrib='1' and  c_15='1')  ELSE '0';
--LD_REG_0    <= '1' when (isAttrib='1' and c_11='1' and TXTHIR_DEC = '0')  ELSE '0';
-- 05/12/09 LD_REG      <= '1' when (lld_reg_p='1' or c_4='1') ELSE '0';
--LD_REG      <= '1' when (lld_reg_p='1' or (c_4='1' and TXTHIR_DEC = '0')) ELSE '0';
--DATABUS_EN  <= '1' when (lld_reg_p='1' or c_3='1') ELSE '0';
--LDFROMBUS   <= '1' when (c_16='1') ELSE '0';

-- 15/12/2009 : 
ATTRIB_DEC  <= '1' when (c_4='1')  ELSE '0';
DATABUS_EN  <= '1' when (c_11='1' or c_3='1') ELSE '0';
LD_REG_0    <= '1' when (isAttrib='1' and c_5='1')  ELSE '0';
LDFROMBUS   <= '1' when (   (isAttrib='0' and c_12='1' and TXTHIR_DEC='0')
                         or (isAttrib='0' and c_5 ='1' and TXTHIR_DEC='1')
								) ELSE '0';
LD_REG      <= '1' when (c_15='1') ELSE '0';

-- for TEST BENCH
c0_OUT  <= lstate(cd_step_0);
c1_OUT  <= lstate(cd_step_1);
c2_OUT  <= lstate(cd_step_2);
c3_OUT  <= lstate(cd_step_3);
c4_OUT  <= lstate(cd_step_4);
c5_OUT  <= lstate(cd_step_5);
c6_OUT  <= lstate(cd_step_6);
c7_OUT  <= lstate(cd_step_7);
TB_CPT  <= lCPT_GEN;
CLK_12  <= lCPT_GEN(0);

-- for VIA 6522
CLK_4 <= c_0 or c_1 or c_2
      or c_6 or c_7 or c_8 
		or c_12 or c_13 or c_14 
		or c_18 or c_19 or c_20;

-- for Video Generation
CLK_6 <= c_0 or c_1 or c_4 or c_5 or c_8 or c_9 or c_12 or c_13 or c_16 or c_17 or c_20 or c_21;
end architecture ctrlseq_arch;
