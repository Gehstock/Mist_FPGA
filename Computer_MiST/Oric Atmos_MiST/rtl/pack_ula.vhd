--
--  ula_pkg.vhd
--
--  Package of ULA
--
--        Copyright (C)2001 - 2005 SEILEBOST
--                   All rights reserved.
--
-- $Id: ula_pkg.vhd, v0.02 2005/01/01 00:00:00 SEILEBOST $
--
-- TODO :
-- Remark :
library ieee;
use ieee.std_logic_1164.all;

package pack_ula is

  component video port (
        RESETn      : in  std_logic;
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
        VAP2        : out std_logic_vector(15 downto 0) );
  end component;

  component iodecode port (
        RESETn  : in  std_logic;
        CLK_1   : in  std_logic;
        ADDR    : in  std_logic_vector(15 downto 0);
		  ADDR_LE : in  std_logic;
        MAPn    : in  std_logic;
        CSROMn  : out std_logic;
        CSRAMn  : out std_logic;
        CSIOn   : out std_logic);
  end component;

  component memmap port (
        TXTHIR_SEL : in  std_logic;
        DBLHGT_SEL : in  std_logic;
        FORCETXT   : in  std_logic;
        CPT_H      : in  std_logic_vector(6  downto 0);
        CPT_V      : in  std_logic_vector(8  downto 0);
        VAP1       : out std_logic_vector(15 downto 0);
        CHROWCNT   : out std_logic_vector(2  downto 0);
        TXTHIR_DEC : out std_logic );
  end component;

  component vag port (
        CLK_1      : in  std_logic;
        RESETn     : in  std_logic;
        FREQ_SEL   : in  std_logic;
        CPT_H      : out std_logic_vector(6 downto 0);
        CPT_V      : out std_logic_vector(8 downto 0);
        RELOAD_SEL : out std_logic;
        FORCETXT   : out std_logic;
        CLK_FLASH  : out std_logic;
        COMPSYNC   : out std_logic;
        BLANKINGn  : out std_logic);
  end component;

  component ctrlseq port (
        RESETn       : in  std_logic;
        CLK_24       : in  std_logic;
        TXTHIR_DEC   : in  std_logic;
        isAttrib     : in  std_logic;
        iRW          : in  std_logic;
        CSRAMn       : in  std_logic;        
        CLK_1_CPU    : out std_logic;
	     CLK_4        : out std_logic;
		  CLK_6        : out std_logic; 
        VA1L         : out std_logic;
        VA1R         : out std_logic;
        VA1C         : out std_logic;
        VA2L         : out std_logic;
        VA2R         : out std_logic;
        VA2C         : out std_logic;
        BAC          : out std_logic;
        BAL          : out std_logic;
        RAS          : out std_logic;
        CAS          : out std_logic;
        MUX          : out std_logic;
        oRW          : out std_logic;
        ATTRIB_DEC   : out std_logic;
        LD_REG_0     : out std_logic;
        LD_REG       : out std_logic;
        LDFROMBUS    : out std_logic;
        DATABUS_EN   : out std_logic;
-- ajout du 09/02/09
        BAOE         : out std_logic;
-- ajout du 03/04/09
        SRAM_CE      : out std_logic;
        SRAM_OE      : out std_logic;
        SRAM_WE      : out std_logic;
        LATCH_SRAM   : out std_logic		  
        );
  end component;

  component addmemux port (
        RESETn     : in  std_logic;
        VAP1       : in  std_logic_vector(15 downto 0);
        VAP2       : in  std_logic_vector(15 downto 0);
        BAP        : in  std_logic_vector(15 downto 0);
        VA1L       : in  std_logic;
        VA1R       : in  std_logic;
        VA1C       : in  std_logic;
        VA2L       : in  std_logic;
        VA2R       : in  std_logic;
        VA2C       : in  std_logic;
        BAC        : in  std_logic;
        BAL        : in  std_logic;
        AD_DYN     : out std_logic_vector(15 downto 0) );
  end component;

  component gen_clock port (
        RESETn        : in  std_logic;
        CLK_12        : in  std_logic;
        CLK_24        : out std_logic;
        CLK_12_INT    : out std_logic;
        CLK_PIXEL_INT : out std_logic );
   end component;
end pack_ula;
