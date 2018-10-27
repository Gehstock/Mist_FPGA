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
-- version 004 spartan3e hires release
-- version 003 spartan3e release
-- version 001 initial release
--
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;

entity BALLY_TOP is
  port (
    cas_addr         : out   std_logic_vector(12 downto 0);
    cas_data         : in    std_logic_vector( 7 downto 0);
    cas_cs_l         : out   std_logic;
    I_PS2_CLK             : in    std_logic;
    I_PS2_DATA            : in    std_logic;
    r             : out   std_logic_vector(3 downto 0);
    g             : out   std_logic_vector(3 downto 0);
    b             : out   std_logic_vector(3 downto 0);
    hs               : out   std_logic;
    vs               : out   std_logic;
    audio             : out   std_logic_vector( 7 downto 0);
    ena             : in   std_logic;
	 pix_ena				: out   std_logic;
    clk_14             : in   std_logic;
	 clk_7             : in   std_logic;
    reset           : in   std_logic
    );
end;

architecture RTL of BALLY_TOP is

    --
    signal switch_col       : std_logic_vector(7 downto 0);
    signal switch_row       : std_logic_vector(7 downto 0);
    signal ps2_1mhz_ena     : std_logic;
    signal ps2_1mhz_cnt     : std_logic_vector(5 downto 0);
    --
    signal video_r          : std_logic_vector(3 downto 0);
    signal video_g          : std_logic_vector(3 downto 0);
    signal video_b          : std_logic_vector(3 downto 0);
    signal hsync            : std_logic;
    signal vsync            : std_logic;
    signal fpsync           : std_logic;


    signal exp_addr         : std_logic_vector(15 downto 0);
    signal exp_data_out     : std_logic_vector(7 downto 0);
    signal exp_data_in      : std_logic_vector(7 downto 0);
    signal exp_oe_l         : std_logic;

    signal exp_m1_l         : std_logic;
    signal exp_mreq_l       : std_logic;
    signal exp_iorq_l       : std_logic;
    signal exp_wr_l         : std_logic;
    signal exp_rd_l         : std_logic;
    --
    signal check_cart_msb   : std_logic_vector(3 downto 0);
    signal check_cart_lsb   : std_logic_vector(7 downto 4);


begin


  p_ena1mhz : process
  begin
    wait until rising_edge(clk_7);
    -- divide by 7
    ps2_1mhz_ena <= '0';
    if (ps2_1mhz_cnt = "000110") then
      ps2_1mhz_cnt <= "000000";
      ps2_1mhz_ena <= '1';
    else
      ps2_1mhz_cnt <= ps2_1mhz_cnt + '1';
    end if;
  end process;


  u_bally : entity work.BALLY
    port map (
      O_AUDIO        => audio,
      --
      O_VIDEO_R      => r,
      O_VIDEO_G      => g,
      O_VIDEO_B      => b,

      O_HSYNC        => hs,
      O_VSYNC        => vs,
      O_COMP_SYNC_L  => open,
      O_FPSYNC       => open,
      --
      -- cart slot
      O_CAS_ADDR     => cas_addr,
      O_CAS_DATA     => open,
      I_CAS_DATA     => cas_data,
      O_CAS_CS_L     => cas_cs_l,

      -- exp slot (subset for now)
      O_EXP_ADDR     => exp_addr,
      O_EXP_DATA     => exp_data_out,
      I_EXP_DATA     => exp_data_in,
      I_EXP_OE_L     => exp_oe_l,

      O_EXP_M1_L     => exp_m1_l,
      O_EXP_MREQ_L   => exp_mreq_l,
      O_EXP_IORQ_L   => exp_iorq_l,
      O_EXP_WR_L     => exp_wr_l,
      O_EXP_RD_L     => exp_rd_l,
      --
      O_SWITCH_COL   => switch_col,
      I_SWITCH_ROW   => switch_row,
      I_RESET_L      => not reset,
      ENA            => ena,
		pix_ena			=> pix_ena,
      CLK            => clk_14,
		CLK7            => clk_7
      );

  u_ps2 : entity work.BALLY_PS2_IF
    port map (

      I_PS2_CLK         => I_PS2_CLK,
      I_PS2_DATA        => I_PS2_DATA,

      I_COL             => switch_col,
      O_ROW             => switch_row,

      I_RESET_L         => not reset,
      I_1MHZ_ENA        => ps2_1mhz_ena,
      CLK               => clk_7
      );

--  u_check_cart : entity work.BALLY_CHECK_CART
--    port map (
 --     I_EXP_ADDR         => exp_addr,
 --     I_EXP_DATA         => exp_data_out,
 --     O_EXP_DATA         => exp_data_in,
 --     O_EXP_OE_L         => exp_oe_l,

--      I_EXP_M1_L         => exp_m1_l,
 --     I_EXP_MREQ_L       => exp_mreq_l,
  --    I_EXP_IORQ_L       => exp_iorq_l,
 --     I_EXP_WR_L         => exp_wr_l,
 --     I_EXP_RD_L         => exp_rd_l,
      ----
--      O_CHAR_MSB         => check_cart_msb,
 --     O_CHAR_LSB         => check_cart_lsb,
      ----
 --     I_RESET_L          => not reset,
 --     ENA                => ena,
 --     CLK                => clk_7
 --     );

  -- if no expansion cart
  exp_data_in <= x"ff";
  exp_oe_l <= '1';
 

end RTL;
