--
-- A simulation model of ORIC hardware
-- Copyright (c) seilebost - January 2009
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS CODE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- You are responsible for any legal issues arising from your use of this code.
--
-- The latest version of this file can be found at: www.fpgaarcade.com
--
-- Email seilebost@free.fr
--
--
-- Revision list
--
-- version 001 initial release

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;

package pkg_oric is
  component T65
      port(
          Mode    : in  std_logic_vector(1 downto 0);      -- "00" => 6502, "01" => 65C02, "10" => 65C816
          Res_n   : in  std_logic;
			 Enable  : in  std_logic;
          Clk     : in  std_logic;
          Rdy     : in  std_logic;
          Abort_n : in  std_logic;
          IRQ_n   : in  std_logic;
          NMI_n   : in  std_logic;
          SO_n    : in  std_logic;
          R_W_n   : out std_logic;
          Sync    : out std_logic;
          EF      : out std_logic;
          MF      : out std_logic;
          XF      : out std_logic;
          ML_n    : out std_logic;
          VP_n    : out std_logic;
          VDA     : out std_logic;
          VPA     : out std_logic;
          A       : out std_logic_vector(23 downto 0);
          DI      : in  std_logic_vector(7 downto 0);
          DO      : out std_logic_vector(7 downto 0)
      );
  end component;

  component ULA
    port (
          CLK        :   in  std_logic;
          PHI2       :   out std_logic;
			 CLK_4      :   out std_logic;
          RW         :   in  std_logic;
          RESETn     :   in  std_logic;
          MAPn       :   in  std_logic;
          DB         :   in  std_logic_vector(7 downto 0);
          AD         :   in  std_logic_vector(15 downto 0);
          AD_RAM     :   out std_logic_vector(7 downto 0);
			 AD_SRAM    :   out std_logic_vector(15 downto 0);
			 OE_SRAM    :   out std_logic;
		    CE_SRAM    :   out std_logic;
		    WE_SRAM    :   out std_logic;
			 LATCH_SRAM :   out std_logic;
          RASn       :   out std_logic;
          CASn       :   out std_logic;
          MUX        :   out std_logic;
          RW_RAM     :   out std_logic;
          CSIOn      :   out std_logic;
          CSROMn     :   out std_logic;
			 CSRAMn     :   out std_logic;
          R          :   out std_logic;
          G          :   out std_logic;
          B          :   out std_logic;
          SYNC       :   out std_logic
      );
  end component;

  component M6522 is
    port (
      RS              : in    std_logic_vector(3 downto 0);
      DATA_IN         : in    std_logic_vector(7 downto 0);
      DATA_OUT        : out   std_logic_vector(7 downto 0);
      DATA_OUT_OE_L   : out   std_logic;

      RW_L            : in    std_logic;
      CS1             : in    std_logic;
      CS2_L           : in    std_logic;

      IRQ_L           : out   std_logic; -- note, not open drain

      CA1_IN          : in    std_logic;
      CA2_IN          : in    std_logic;
      CA2_OUT         : out   std_logic;
      CA2_OUT_OE_L    : out   std_logic;

      PA_IN           : in    std_logic_vector(7 downto 0);
      PA_OUT          : out   std_logic_vector(7 downto 0);
      PA_OUT_OE_L     : out   std_logic_vector(7 downto 0);

      -- port b
      CB1_IN          : in    std_logic;
      CB1_OUT         : out   std_logic;
      CB1_OUT_OE_L    : out   std_logic;

      CB2_IN          : in    std_logic;
      CB2_OUT         : out   std_logic;
      CB2_OUT_OE_L    : out   std_logic;

      PB_IN           : in    std_logic_vector(7 downto 0);
      PB_OUT          : out   std_logic_vector(7 downto 0);
      PB_OUT_OE_L     : out   std_logic_vector(7 downto 0);

      RESET_L         : in    std_logic;
      P2_H            : in    std_logic; -- high for phase 2 clock  ____----__
      CLK_4           : in    std_logic  -- 4x system clock (4HZ)   _-_-_-_-_-
      );
  end component;

  component AY3819X
    port ( 
      DATA_IN     : in    std_logic_vector(7 downto 0);
      DATA_OUT    : out   std_logic_vector(7 downto 0);
		O_DATA_OE_L : out    std_logic;
      RESET       : in     std_logic;
      CLOCK       : in     std_logic;
		CLOCK_DAC   : in     std_logic;
      BDIR        : in     std_logic;
      BC1         : in     std_logic;
      BC2         : in     std_logic;
      IOA         : inout  std_logic_vector(7 downto 0);
      IOB         : inout  std_logic_vector(7 downto 0);
      AnalogA     : out    std_logic;
      AnalogB     : out    std_logic;
      AnalogC     : out    std_logic 
      );
  end component;

  component ORIC_PS2_IF
    port (
      PS2_CLK         : in    std_logic;
      PS2_DATA        : in    std_logic;

      COL_IN          : in    std_logic_vector(7 downto 0);
      ROW_IN          : in    std_logic_vector(7 downto 0);
      RESTORE         : out   std_logic;

      RESET_L         : in    std_logic;
      ENA_1MHZ        : in    std_logic;
      P2_H            : in    std_logic; -- high for phase 2 clock  ____----__
      CLK_4           : in    std_logic  -- 4x system clock (4HZ)   _-_-_-_-_-
      );
  end component;

  component ORIC_CHAR_ROM
    port (
      CLK         : in    std_logic;
      ADDR        : in    std_logic_vector(11 downto 0);
      DATA        : out   std_logic_vector(7 downto 0)
      );
  end component;

  component ORIC_BASIC_ROM
    port (
      CLK         : in    std_logic;
      ADDR        : in    std_logic_vector(12 downto 0);
      DATA        : out   std_logic_vector(7 downto 0)
      );
  end component;

  component ORIC_KERNAL_ROM
    port (
      CLK         : in    std_logic;
      ADDR        : in    std_logic_vector(12 downto 0);
      DATA        : out   std_logic_vector(7 downto 0)
      );
  end component;

  component ORIC_RAMS
    port (
      V_ADDR      : in  std_logic_vector(9 downto 0);
      DIN         : in  std_logic_vector(7 downto 0);
      DOUT        : out std_logic_vector(7 downto 0);
      V_RW_L      : in  std_logic;
      CS_L        : in  std_logic; -- used for write enable gate only
      CLK         : in  std_logic
    );
  end component;
  
  component keyboard 
    port (
	  	CLK		: in  std_logic;
		RESET		: in  std_logic;
		PS2CLK	: in  std_logic;
		PS2DATA	: in  std_logic;
		COL		: in  std_logic_vector(2 downto 0);
		ROWbit	: out std_logic_vector(7 downto 0)	
  );
  end component;
  
  component file_log
  generic (
           log_file:       string  := "res.log"
          );
  port(
       CLK              : in std_logic;
       RST              : in std_logic;
       x1               : in std_logic_vector(7  downto 0);
       x2               : in std_logic_vector(7  downto 0);
		 x3               : in std_logic_vector(15 downto 0);
		 x4               : in std_logic_vector(2  downto 0);
		 x5               : in std_logic
      );
  end component;

  component psg_log
   generic (
           log_psg:       string  := "psg.log"
          );
  port(
       CLK              : in std_logic;
       RST              : in std_logic;
       x1               : in std_logic
      );
  end component;

 component ula_log
   generic (
           log_ula:       string  := "ula.log"
          );
  port(
       CLK              : in std_logic;
       RST              : in std_logic;
       x1               : in std_logic_vector(7 downto 0);
		 x2               : in std_logic_vector(15 downto 0);
		 x3               : in std_logic
      );
  end component;  
end pkg_oric;

package body pkg_ORIC is

end pkg_oric;
