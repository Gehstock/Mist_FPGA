--
--  memmap.vhd
--
--  Manage offset for read ula 
--
--        Copyright (C)2001 - 2005 SEILEBOST
--                   All rights reserved.
--
-- $Id: memmap.vhd, v0.02 2005/01/01 00:00:00 SEILEBOST $
--
-- TODO :
-- Remark :

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
--use IEEE.std_logic_arith.all;
--use IEEE.numeric_std.all;

entity memmap is
port (  TXTHIR_SEL : in  std_logic;
        DBLHGT_SEL : in  std_logic;
        FORCETXT   : in  std_logic;        
        CPT_H      : in  std_logic_vector(6  downto 0);
        CPT_V      : in  std_logic_vector(8  downto 0);
        VAP1       : out std_logic_vector(15 downto 0);
        CHROWCNT   : out std_logic_vector(2  downto 0);        
        TXTHIR_DEC : out std_logic        
      );
end entity memmap;

architecture memmap_arch of memmap is 

signal lDBLHGT_EN   : std_logic;                     -- ENABLE DOUBLE HEIGT
signal lTXTHIR_DEC  : std_logic;                     -- MODE TEXT / HIRES
signal lCPT_V_TMP   : std_logic_vector(8  downto 0); -- VERTICAL COUNTER
signal lCPT_V_8_TMP : std_logic_vector(8  downto 0); -- VERTICAL COUNTER DIVIDE OR NOT BY 8
signal lVAP1        : std_logic_vector(12 downto 0); -- VIDEO ADDRESS PHASE 1
signal lOFFSCR      : std_logic_vector(15 downto 0); -- OFFSET SCREEN
signal ltmpBy10     : std_logic_vector(12 downto 0); -- Using to mult by 10


begin
 -- local signal
 lTXTHIR_DEC  <= (TXTHIR_SEL and FORCETXT);
 lDBLHGT_EN   <= (DBLHGT_SEL and lTXTHIR_DEC);
 
 -- Compute video adress phase 1
 lCPT_V_TMP   <= '0'&CPT_V(8 downto 1) when lDBLHGT_EN = '1' else CPT_V(8 downto 0);
 
 -- divide by 8 if necessary : erreur sur la manière de diviser par 8? 03/02/2010
 --lCPT_V_8_TMP <= lCPT_V_TMP when lTXTHIR_DEC = '1' else lCPT_V_TMP(8 downto 3) & "000";
 
 lCPT_V_8_TMP <= lCPT_V_TMP when lTXTHIR_DEC = '1' else "000" & lCPT_V_TMP(8 downto 3) ;
 
 -- 03/02/2010 : Le bonne blague : après la phase de synthese, le 'bench' ne 
 -- fonctionnait plus. Le synthetiseur de XILINX avait utilisé un multiplieur 18x18
 -- pour générer la multiplication par 10 et la simulation a repris cela. Or le 
 -- multiplier a une latence de 1 µs (latence de l'horloge PHI2) d'où les problèmes
 -- durant les simulations (génération de 2 fois de suite de l'adresse vidéo)
 -- On revient à la bonne vieille méthode Bx10 = Bx8 + Bx2 !!
 --lVAP1        <= ("0000000" & CPT_H) + (lCPT_V_8_TMP * "1010");
 ltmpBy10     <= ("0" & lCPT_V_8_TMP & "000") + ("000" & lCPT_V_8_TMP & "0");
 -- le décalage en Y : il faut multiplier par 40 donc 4 * ltmpBy10
 lVAP1        <= ("00000" & CPT_H) + (ltmpBy10(10 downto 0) & "00");
 lOFFSCR      <= X"A000" when lTXTHIR_DEC = '1' else X"BB80";
 VAP1         <= ("000" & lVAP1) + lOFFSCR;

 -- Compute character row counter
 CHROWCNT     <= CPT_V(2 downto 0) when lDBLHGT_EN = '1' else CPT_V(3 downto 1);
 
 -- Output signal for texte/hires mode decode
 TXTHIR_DEC   <= lTXTHIR_DEC;

end architecture memmap_arch;



