--
-- A simulation model of ORIC hardware
-- Copyright (c) seilebost - 2001 - 2009
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

package pack_oric_xilinx_prims is

  attribute INIT    : string;
  attribute INIT_00 : string;
  attribute INIT_01 : string;
  attribute INIT_02 : string;
  attribute INIT_03 : string;
  attribute INIT_04 : string;
  attribute INIT_05 : string;
  attribute INIT_06 : string;
  attribute INIT_07 : string;
  attribute INIT_08 : string;
  attribute INIT_09 : string;
  attribute INIT_0A : string;
  attribute INIT_0B : string;
  attribute INIT_0C : string;
  attribute INIT_0D : string;
  attribute INIT_0E : string;
  attribute INIT_0F : string;

  attribute RLOC   : string;
  attribute HU_SET : string;

  function str2slv (str : string) return std_logic_vector;


  component RAM16X1D
    port (
      A0, A1, A2, A3 : in std_logic;
      DPRA0, DPRA1, DPRA2, DPRA3 : in std_logic;
      WCLK : in std_logic;
      WE   : in std_logic;
      D    : in std_logic;
      SPO  : out std_logic;
      DPO  : out std_logic
      );
  end component;

  component RAMB4_S1
    --pragma translate_off
    generic (
      INIT_00 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_01 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_02 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_03 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_04 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_05 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_06 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_07 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_08 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_09 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0A : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0B : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0C : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0D : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0E : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0F : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000"
      );
    --pragma translate_on
    port (
      DO    : out std_logic_vector (0 downto 0);
      DI    : in  std_logic_vector (0 downto 0);
      ADDR  : in  std_logic_vector (11 downto 0);
      WE    : in  std_logic;
      EN    : in  std_logic;
      RST   : in  std_logic;
      CLK   : in  std_logic
      );
  end component;

  component RAMB4_S4
    --pragma translate_off
    generic (
      INIT_00 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_01 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_02 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_03 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_04 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_05 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_06 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_07 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_08 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_09 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0A : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0B : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0C : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0D : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0E : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0F : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000"
      );
    --pragma translate_on
    port (
      DO   : out std_logic_vector (3 downto 0);
      DI   : in  std_logic_vector (3 downto 0);
      ADDR : in  std_logic_vector (9 downto 0);
      WE   : in  std_logic;
      EN   : in  std_logic;
      RST  : in  std_logic;
      CLK  : in  std_logic
      );
  end component;

  component RAMB4_S8
    --pragma translate_off
    generic (
      INIT_00 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_01 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_02 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_03 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_04 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_05 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_06 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_07 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_08 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_09 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0A : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0B : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0C : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0D : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0E : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0F : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000"
      );
    --pragma translate_on
    port (
      DO   : out std_logic_vector (7 downto 0);
      DI   : in  std_logic_vector (7 downto 0);
      ADDR : in  std_logic_vector (8 downto 0);
      WE   : in  std_logic;
      EN   : in  std_logic;
      RST  : in  std_logic;
      CLK  : in  std_logic
      );
  end component;

  component RAMB4_S1_S1
    --pragma translate_off
    generic (
      INIT_00 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_01 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_02 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_03 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_04 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_05 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_06 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_07 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_08 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_09 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0A : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0B : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0C : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0D : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0E : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0F : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000"
      );
    --pragma translate_on
    port (
      DOB   : out std_logic_vector (0 downto 0);
      DIB   : in  std_logic_vector (0 downto 0);
      ADDRB : in  std_logic_vector (11 downto 0);
      WEB   : in  std_logic;
      ENB   : in  std_logic;
      RSTB  : in  std_logic;
      CLKB  : in  std_logic;

      DOA   : out std_logic_vector(0 downto 0);
      DIA   : in  std_logic_vector(0 downto 0);
      ADDRA : in  std_logic_vector (11 downto 0);
      WEA   : in  std_logic;
      ENA   : in  std_logic;
      RSTA  : in  std_logic;
      CLKA  : in  std_logic
      );
  end component;

  component RAMB4_S2_S2
    --pragma translate_off
    generic (
      INIT_00 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_01 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_02 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_03 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_04 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_05 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_06 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_07 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_08 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_09 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0A : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0B : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0C : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0D : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0E : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0F : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000"
      );
    --pragma translate_on
    port (
      DOB   : out std_logic_vector (1 downto 0);
      DIB   : in  std_logic_vector (1 downto 0);
      ADDRB : in  std_logic_vector (10 downto 0);
      WEB   : in  std_logic;
      ENB   : in  std_logic;
      RSTB  : in  std_logic;
      CLKB  : in  std_logic;

      DOA   : out std_logic_vector (1 downto 0);
      DIA   : in  std_logic_vector (1 downto 0);
      ADDRA : in  std_logic_vector (10 downto 0);
      WEA   : in  std_logic;
      ENA   : in  std_logic;
      RSTA  : in  std_logic;
      CLKA  : in  std_logic
      );
  end component;

  component RAMB4_S4_S4
    --pragma translate_off
    generic (
      INIT_00 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_01 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_02 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_03 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_04 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_05 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_06 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_07 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_08 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_09 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0A : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0B : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0C : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0D : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0E : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0F : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000"
      );
    --pragma translate_on
    port (
      DOB   : out std_logic_vector (3 downto 0);
      DIB   : in  std_logic_vector (3 downto 0);
      ADDRB : in  std_logic_vector (9 downto 0);
      WEB   : in  std_logic;
      ENB   : in  std_logic;
      RSTB  : in  std_logic;
      CLKB  : in  std_logic;

      DOA   : out std_logic_vector (3 downto 0);
      DIA   : in  std_logic_vector (3 downto 0);
      ADDRA : in  std_logic_vector (9 downto 0);
      WEA   : in  std_logic;
      ENA   : in  std_logic;
      RSTA  : in  std_logic;
      CLKA  : in  std_logic
      );
  end component;

  component RAMB4_S8_S8
    --pragma translate_off
    generic (
      INIT_00 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_01 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_02 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_03 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_04 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_05 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_06 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_07 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_08 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_09 : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0A : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0B : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0C : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0D : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0E : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0F : std_logic_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000"
      );
    --pragma translate_on
    port (
      DOB   : out std_logic_vector (7 downto 0);
      DIB   : in  std_logic_vector (7 downto 0);
      ADDRB : in  std_logic_vector (8 downto 0);
      WEB   : in  std_logic;
      ENB   : in  std_logic;
      RSTB  : in  std_logic;
      CLKB  : in  std_logic;

      DOA   : out std_logic_vector (7 downto 0);
      DIA   : in  std_logic_vector (7 downto 0);
      ADDRA : in  std_logic_vector (8 downto 0);
      WEA   : in  std_logic;
      ENA   : in  std_logic;
      RSTA  : in  std_logic;
      CLKA  : in  std_logic
      );
  end component;

  component PULLUP
    port (
      O : out std_logic
      );
  end component;

  component BUFG
    port (
      I : in std_logic; O: out std_logic
      );
  end component;

  component OBUF
    port (
      I : in std_logic; O: out std_logic
      );
  end component;

  component IBUFG
    port (
      I : in std_logic; O: out std_logic
      );
  end component;

  component IBUF
    port (
      I : in std_logic; O: out std_logic
      );
  end component;

  component CLKDLL
    port (
      CLKIN, CLKFB, RST : in std_logic;
      CLK0,CLK90,CLK180,CLK270,CLK2X,CLKDV,LOCKED : out std_logic
      );
  end component;

end pack_oric_xilinx_prims;

package body pack_oric_xilinx_prims is

  function str2slv (str : string) return std_logic_vector is
    variable result : std_logic_vector (str'length*4-1 downto 0);
  begin
    for i in 0 to str'length-1 loop
      case str(str'high-i) is
        when '0'       => result(i*4+3 downto i*4) := x"0";
        when '1'       => result(i*4+3 downto i*4) := x"1";
        when '2'       => result(i*4+3 downto i*4) := x"2";
        when '3'       => result(i*4+3 downto i*4) := x"3";
        when '4'       => result(i*4+3 downto i*4) := x"4";
        when '5'       => result(i*4+3 downto i*4) := x"5";
        when '6'       => result(i*4+3 downto i*4) := x"6";
        when '7'       => result(i*4+3 downto i*4) := x"7";
        when '8'       => result(i*4+3 downto i*4) := x"8";
        when '9'       => result(i*4+3 downto i*4) := x"9";
        when 'a' | 'A' => result(i*4+3 downto i*4) := x"A";
        when 'b' | 'B' => result(i*4+3 downto i*4) := x"B";
        when 'c' | 'C' => result(i*4+3 downto i*4) := x"C";
        when 'd' | 'D' => result(i*4+3 downto i*4) := x"D";
        when 'e' | 'E' => result(i*4+3 downto i*4) := x"E";
        when 'f' | 'F' => result(i*4+3 downto i*4) := x"F";
        when others => result(i*4+3 downto i*4) := "XXXX";
      end case;
    end loop;

    return result;
  end str2slv;

end pack_oric_xilinx_prims;
