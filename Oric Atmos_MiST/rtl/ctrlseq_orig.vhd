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
		  CLK_4        : out std_logic; -- CLK interne for ram statique
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

signal lCPT_GEN  : std_logic_vector(4 downto 0); -- counter
signal lstate    : std_logic_vector(7 downto 0); -- states
signal lreload   : std_logic;                    -- to reload null value to lCPT_GEN
signal lld_reg_p : std_logic;                    -- to load value into register for VIDEO

signal c_ras     : std_logic; -- RAS
signal c_cas     : std_logic; -- CAS
signal c_mux     : std_logic; -- MUX
signal c_clk_cpu : std_logic; -- CLK_CPU

signal c_0       : std_logic; -- state number 0
signal c_1       : std_logic; -- state number 1
signal c_2       : std_logic; -- state number 2
signal c_3       : std_logic; -- state number 3
signal c_4       : std_logic; -- state number 4
signal c_5       : std_logic; -- state number 5
signal c_6       : std_logic; -- state number 6
signal c_7       : std_logic; -- state number 7

signal p_0       : std_logic; -- phase number 0
signal p_1       : std_logic; -- phase number 1
signal p_2       : std_logic; -- phase number 2

-- Constants for states
constant cd_step_0 : integer :=0;
constant cd_step_1 : integer :=1;
constant cd_step_2 : integer :=2;
constant cd_step_3 : integer :=3;
constant cd_step_4 : integer :=4;
constant cd_step_5 : integer :=5;
constant cd_step_6 : integer :=6;
constant cd_step_7 : integer :=7;

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
   lstate <= "00000000";
   case lCPT_GEN(2 downto 0) is
    when "000" => lstate(cd_step_0) <= '1';
    when "001" => lstate(cd_step_1) <= '1';
    when "010" => lstate(cd_step_2) <= '1';
    when "011" => lstate(cd_step_3) <= '1';
    when "100" => lstate(cd_step_4) <= '1';
    when "101" => lstate(cd_step_5) <= '1';
    when "110" => lstate(cd_step_6) <= '1';
    when "111" => lstate(cd_step_7) <= '1';
    when others => null;
   end case;
END PROCESS;

-- Assign states
c_0  <= lstate(cd_step_0);
c_1  <= lstate(cd_step_1);
c_2  <= lstate(cd_step_2);
c_3  <= lstate(cd_step_3);
c_4  <= lstate(cd_step_4);
c_5  <= lstate(cd_step_5);
c_6  <= lstate(cd_step_6);
c_7  <= lstate(cd_step_7);

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
ras <= c_2 or c_3 or c_4 or c_5;
cas <= not (c_2 or c_3) and (not p_2 or CSRAMn);
-- Mux permet de sélectionner soit l'adresse haute d'une adresse cpu
-- soit l'adresse haute d'une adresse ula
mux <= '1' when ((c_1 = '1' or c_2 = '1') and p_2 = '1') else '0';
oRW <= iRW and p_2;

---------------------
-- GESTION INTERNE --
---------------------

--Generation pour la gestion de l'adresse video 1
VA1L <= '1' when (c_1='1' and p_0='1') ELSE '0';
VA1R <= '1' when ((c_1='1' or c_2='1') and p_0='1') ELSE '0';
VA1C <= '1' when ((c_3='1' or c_4='1' or c_5='1') and p_0='1') ELSE '0';

--Generation pour la gestion de l'adresse video 2
VA2L <= '1' when  (c_1='1' and p_1='1') ELSE '0';
VA2R <= '1' when ((c_1='1' or  c_2='1') and p_1='1') ELSE '0';
VA2C <= '1' when ((c_3='1' or  c_4='1' or c_5='1') and p_1='1') ELSE '0';

--Generation pour la gestion de l'adresse CPU
BAL  <= '1' when (c_1='1' and p_2='1') ELSE '0';
--Modif. du 22/02/09 BAC  <= '1' when ((c_3='1' or c_4='1' or c_5='1') and p_2='1' and CSRAMn='0') ELSE '0';
BAC  <= '1' when ((c_3='1' or c_4='1' or c_5='1') and p_2='1') ELSE '0';
-- Ajout du 09/02/09 : output enable pour la rom/ram lors de l'adressage par le CPU
BAOE <= '1' when (not(c_0='1' or c_1 ='1') and p_2='1') ELSE '0';

--Pour la partie video
lld_reg_p   <= NOT isAttrib and (c_7 and p_1) and NOT TXTHIR_DEC; 

ATTRIB_DEC  <= '1' when (isAttrib='1' and  c_2='1' and p_1='1')  ELSE '0';
LD_REG_0    <= '1' when (isAttrib='1' and  c_7='1' and p_1='1')  ELSE '0';
LD_REG      <= '1' when (lld_reg_p='1' or (c_7='1' and p_0='1')) ELSE '0';
DATABUS_EN  <= '1' when (lld_reg_p='1' or (c_7='1' and p_0='1')) ELSE '0';
LDFROMBUS   <= '1' when (c_0='1' and p_2='1') ELSE '0';

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

-- for ram statique
CLK_4 <= c_6 or c_7;

end architecture ctrlseq_arch;
