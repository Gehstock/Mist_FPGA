--
--  video.vhd
--
--  Manage video attribute
--
--        Copyright (C)2001 - 2005 SEILEBOST
--                   All rights reserved.
--
-- $Id: video.vhd, v0.01 2005/01/01 00:00:00 SEILEBOST $
--
-- TODO :
-- Remark :

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_STD.all;

entity video is
port (  RESETn      : in  std_logic;
        CLK_PIXEL   : in  std_logic;
        CLK_FLASH   : in  std_logic;
        -- delete 17/11/2009 FLASH_SEL   : in  std_logic;
        BLANKINGn   : in  std_logic;
        RELOAD_SEL  : in  std_logic;
        DATABUS     : in  std_logic_vector(7 downto 0);
        ATTRIB_DEC  : in  std_logic;
        DATABUS_EN  : in  std_logic;
        LDFROMBUS   : in  std_logic;
        LD_REG_0    : in  std_logic;
        RELD_REG    : in  std_logic;
        CHROWCNT    : in  std_logic_vector(2 downto 0);
        RGB         : out std_logic_vector(2 downto 0);
        FREQ_SEL    : out std_logic;
        TXTHIR_SEL  : out std_logic;
        isAttrib    : out std_logic;        
        DBLSTD_SEL  : out std_logic;
        VAP2        : out std_logic_vector(15 downto 0)
      );
end entity video;

architecture video_arch of video is

-- locals signals
signal lDATABUS   : std_logic_vector(7 downto 0);
signal lSHFREG    : std_logic_vector(5 downto 0);
signal lREGHOLD   : std_logic_vector(5 downto 0);
signal lRGB       : std_logic_vector(2 downto 0);
signal lCLK_REG   : std_logic_vector(3 downto 0);
signal lREG_0     : std_logic_vector(2 downto 0);
signal lREG_1     : std_logic_vector(2 downto 0);
signal lREG_2     : std_logic_vector(2 downto 0);
signal lREG_3     : std_logic_vector(2 downto 0);
signal tmp        : std_logic_vector(1 downto 0);
signal lADD       : std_logic_vector(1 downto 0);
signal lDIN       : std_logic;                    -- SET INVERSE SIGNAL
signal lSHFVIDEO  : std_logic;
signal lBGFG_SEL  : std_logic;
signal lFLASH_SEL : std_logic;
signal lIsATTRIB  : std_logic;

begin

-- Latch data from Data Bus
u_data_bus: PROCESS( DATABUS, DATABUS_EN)
BEGIN
      -- Correctif 03/02/09 if (DATABUS_EN = '1') then
		if (rising_edge(DATABUS_EN)) then
         lDATABUS <= DATABUS;
      end if;
END PROCESS;

-- Ajout du 04/02/09 / Commentaire le 05/12/09
--isAttrib <= not lDATABUS(6); -- =1 is an attribut, = 0 is not an attribut 

-- Decode register
u_attr_dec: PROCESS(lDATABUS, ATTRIB_DEC)
BEGIN
  lCLK_REG <= "0000"; -- Ajout 11/11/09
  if rising_edge(ATTRIB_DEC) then
     if (lDATABUS(6 downto 5) = "00") then
      case lDATABUS(4 downto 3) is
       when "00" => lCLK_REG <= "0001";
       when "01" => lCLK_REG <= "0010";
       when "10" => lCLK_REG <= "0100";
       when "11" => lCLK_REG <= "1000";
       when others => lCLK_REG <= "1111"; -- 11/11/09 null;
      end case;
	  end if;
  end if;
END PROCESS;

-- ajout le 05/12/09 
u_isattrib : PROCESS(DATABUS_EN, ATTRIB_DEC, RESETn)
BEGIN
 if (RESETn = '0') then
     lIsATTRIB <= '0';
 elsif rising_edge(ATTRIB_DEC) then
     lIsATTRIB <= not (DATABUS(6) or DATABUS(5)); -- =1 is an attribut, = 0 is not an attribut
 end if;
END PROCESS;

-- Assignation 
isAttrib <= lIsATTRIB;

-- get value for register number 0 : INK
u_ld_reg0: PROCESS(lCLK_REG, RELOAD_SEL, lDATABUS, RESETn)
BEGIN
  -- Ajout du 17/11/2009
  if (RESETn = '0') then
     lREG_0 <= "000";
  elsif (RELOAD_SEL = '1') then
     lREG_0 <= "000";
  -- le 17/11/2009 elsif (lCLK_REG(0) = '1') then
  elsif rising_edge(lCLK_REG(0)) then
     lREG_0 <= lDATABUS(2 downto 0);
  end if;
END PROCESS;

-- get value for register number 1 : STYLE : Alt/std, Dbl/std, Flash sel
u_ld_reg1: PROCESS(lCLK_REG, RELOAD_SEL, lDATABUS, RESETN)
BEGIN
  -- Ajout du 17/11/2009
  if (RESETn = '0') then
     lREG_1 <= "000";
  elsif (RELOAD_SEL = '1') then
     lREG_1 <= "000";
  -- le 17/11/2009 elsif (lCLK_REG(1) = '1') then
  elsif rising_edge(lCLK_REG(1)) then
     lREG_1 <= lDATABUS(2 downto 0);
  end if;
END PROCESS;

-- get value for register number 2 : PAPER
u_ld_reg2: PROCESS(lCLK_REG, RELOAD_SEL, lDATABUS, RESETN)
BEGIN
  -- Ajout du 17/11/2009
  if (RESETn = '0') then
     lREG_2 <= "111";
  elsif (RELOAD_SEL = '1') then
     lREG_2 <= "111";
  -- le 17/11/2009 elsif (lCLK_REG(2) = '1') then
  elsif rising_edge(lCLK_REG(2)) then
     lREG_2 <= lDATABUS(2 downto 0);
  end if;
END PROCESS;

-- get value for register number 3 : Mode
u_ld_reg3: PROCESS(lCLK_REG, lDATABUS, RESETn)
BEGIN
  if (RESETn = '0') then
     lREG_3 <= "000";
  -- modif 04/02/09 elsif (lCLK_REG(3) = '1') then
  elsif rising_edge(lCLK_REG(3)) then
     lREG_3 <= lDATABUS(2 downto 0);
  end if;
END PROCESS;

-- hold data value
u_hold_reg: PROCESS( LD_REG_0, LDFROMBUS, lDATABUS)
BEGIN
  -- Chargement si attribut
  if (LD_REG_0 = '1') then
     lREGHOLD <= (OTHERS => '0');
  elsif (rising_edge(LDFROMBUS)) then
     lREGHOLD <= lDATABUS(5 downto 0);
	  lDIN <= lDATABUS(7); -- Ajout du 15/12/2009
  end if;
  ---mise en commentaire 15/12/2009 lDIN <= lDATABUS(7);
END PROCESS;

-- shift data for video 
u_shf_reg: PROCESS(RELD_REG, CLK_PIXEL, lREGHOLD)
BEGIN
   -- Chargement du shifter avant le front montant de PHI2
   if (RELD_REG = '1') then
      lSHFREG <= lREGHOLD;
	-- 6 bits à envoyer
   elsif (rising_edge(CLK_PIXEL)) then
         lSHFVIDEO <= lSHFREG(5);
         lSHFREG   <= lSHFREG(4 downto 0) & '0';
   end if;
END PROCESS;

lFLASH_SEL <= lREG_1(2);
lBGFG_SEL  <= NOT(lSHFVIDEO) when ( (CLK_FLASH = '1') AND (lFLASH_SEL = '1') ) else lSHFVIDEO;
-- le 17/11/2009 : lBGFG_SEL  <= NOT(lSHFVIDEO) when ( (CLK_FLASH = '1') AND (FLASH_SEL = '1') ) else lSHFVIDEO;
-- lBGFG_SEL  <= lSHFVIDEO and not ( CLK_FLASH AND FLASH_SEL );

-- local assign for R(ed)G(reen)B(lue) signal
lRGB <= lREG_0 when lBGFG_SEL = '0' else lREG_2;

-- Assign out signal
RGB <= lRGB      when (lDIN = '0' and BLANKINGn = '1') else
       not(lRGB) when (lDIN = '1' and BLANKINGn = '1') else
       "000";

DBLSTD_SEL <= lREG_1(1); -- Double/Standard height character select
FREQ_SEL   <= lREG_3(1); -- Frenquecy video (50/60Hz) select
TXTHIR_SEL <= lREG_3(2); -- Texte/Hires mode select

-- Compute offset 
tmp <= lREG_3(2) & lREG_1(0);
with tmp  select
lADD <= "01" when "00",   -- TXT & STD
        "10" when "01",   -- TXT & ALT
        "10" when "10",   -- HIRES & STD
        "11" when "11",   -- HIRES & ALT
        "01" when others; -- Du fait que le design original de l'ULA
		                    -- n'a pas de reset, nous supposerons que
								  -- l'ULA est en mode text et standard 

-- Generate Address Phase 2
VAP2 <= "10" & not lREG_3(2) & '1' & lADD & lDATABUS(6 downto 0) & CHROWCNT;

end architecture video_arch;
