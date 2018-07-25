--
-- A simulation model of Bally Astrocade hardware
-- Copyright (c) MikeJ - Nov 2004
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
-- Email support@fpgaarcade.com
--
-- Revision list
--
-- version 003 spartan3e release
-- version 001 initial release
--
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;

entity BALLY_CHECK_CART is
  port (
    I_EXP_ADDR         : in    std_logic_vector(15 downto 0);
    I_EXP_DATA         : in    std_logic_vector( 7 downto 0);
    O_EXP_DATA         : out   std_logic_vector( 7 downto 0);
    O_EXP_OE_L         : out   std_logic;

    I_EXP_M1_L         : in    std_logic;
    I_EXP_MREQ_L       : in    std_logic;
    I_EXP_IORQ_L       : in    std_logic;
    I_EXP_WR_L         : in    std_logic;
    I_EXP_RD_L         : in    std_logic;
    --
    O_CHAR_MSB         : out   std_logic_vector(3 downto 0);
    O_CHAR_LSB         : out   std_logic_vector(3 downto 0);
    --
    I_RESET_L          : in    std_logic;
    ENA                : in    std_logic;
    CLK                : in    std_logic
    );
end;

architecture RTL of BALLY_CHECK_CART is

  component BALLY_CHECK
    port (
      CLK         : in    std_logic;
      ADDR        : in    std_logic_vector(10 downto 0);
      DATA        : out   std_logic_vector(7 downto 0)
      );
  end component;

  signal dout : std_logic_vector(7 downto 0);

begin
  -- chars 0-9, a = '-', b = 'E', c = 'H', d = 'L', e = 'P', f = blank
  u_rom : entity work.BALLY_CHECK
    port map (
      clock         => CLK,
      clken         => ENA,
      address        => I_EXP_ADDR(10 downto 0),
      q        => dout
      );

  p_dout : process(dout, I_EXP_ADDR)
  begin
    O_EXP_DATA <= dout;
    -- jump direct for intercept or / xor test - the tricky one !
    --if I_EXP_ADDR = x"20c4" then O_EXP_DATA <= x"31"; end if;
    --if I_EXP_ADDR = x"20c5" then O_EXP_DATA <= x"c8"; end if;
    --if I_EXP_ADDR = x"20c6" then O_EXP_DATA <= x"4f"; end if;
    --if I_EXP_ADDR = x"20c7" then O_EXP_DATA <= x"c3"; end if;
    --if I_EXP_ADDR = x"20c8" then O_EXP_DATA <= x"c8"; end if;
    --if I_EXP_ADDR = x"20c9" then O_EXP_DATA <= x"21"; end if;
  end process;

  p_cs : process(I_EXP_ADDR, I_EXP_RD_L, I_EXP_MREQ_L)
  begin
    O_EXP_OE_L <= '1';
    if (I_EXP_RD_L = '0') and (I_EXP_MREQ_L = '0') and (I_EXP_ADDR(14 downto 13) = "01") then
      O_EXP_OE_L <= '0';
    end if;
  end process;

  p_latch : process
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then
      if (I_EXP_ADDR(7 downto 4) = "1111") and (I_EXP_IORQ_L = '0') and (I_EXP_M1_L = '1') then
        O_CHAR_MSB <= I_EXP_DATA(7 downto 4);
        O_CHAR_LSB <= I_EXP_DATA(3 downto 0);
      end if;
    end if;
  end process;

end RTL;
