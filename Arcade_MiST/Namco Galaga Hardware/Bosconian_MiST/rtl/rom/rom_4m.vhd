----------------------------------------------------------------------------------
--
-- Description:
-- async. 256 value LUT implementation,
--
-- by Nolan Nicholson, 2021
-- This is a derivative work of the color PROMs for FPGA Galaga,
-- (c) copyright 2011...2015 by WoS (Wolfgang Scherr)
-- http://www.pin4.at - WoS <at> pin4 <dot> at
--
-- All Rights Reserved
--
-- Version 1.0
-- SVN: $Id$
--
----------------------------------------------------------------------------------
-- Redistribution and use in source and synthesized forms, with or without
-- modification, also in projects with different (but compatible) licenses,
-- are permitted provided that the following conditions are met:
--
-- * Redistributions of source code must retain the above copyright notice,
--   this list of conditions, a modification note and the following disclaimer.
--
-- * Redistributions in synthesized form must reproduce the above copyright
--   notice, this list of conditions and the following disclaimer in the
--   documentation or other materials provided with the distribution.
--
-- * The code must not be used for commercial purposes or re-licensed without
--   specific prior written permission of the author and contributors. It is
--   strictly for private use in hobby projects, without commercial interests.
--
-- * A person redistributing this code or any work products in private or 
--   public is also responsible for any legal issues which may arise by that.
--
-- Please feel free to report bugs to the author, but before you do so, please
-- make sure that this is not a derivative work and that you have the latest 
-- version of this file. 
-------------------------------------------------------------------------------
-- DISCLAIMER
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
-- ARISING IN ANY WAY OUT OF THE USE OF THIS CODE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity rom_4m is
  port (
    ADDR        : in    std_ulogic_vector(7 downto 0);
    DATA        : out   std_ulogic_vector(3 downto 0)
    );
end;

architecture RTL of rom_4m is
  type ROM_ARRAY is array(0 to 255) of std_ulogic_vector(3 downto 0);
  constant ROM : ROM_ARRAY := (
    x"F",x"F",x"F",x"F",x"F",x"1",x"0",x"E", -- 0x0000
    x"F",x"2",x"6",x"1",x"F",x"5",x"4",x"1", -- 0x0008
    x"F",x"6",x"7",x"2",x"F",x"2",x"7",x"8", -- 0x0010
    x"F",x"C",x"1",x"B",x"F",x"3",x"9",x"1", -- 0x0018

    x"F",x"0",x"E",x"1",x"F",x"0",x"1",x"2", -- 0x0020
    x"F",x"E",x"0",x"C",x"F",x"7",x"E",x"D", -- 0x0028
    x"F",x"E",x"3",x"D",x"F",x"0",x"0",x"7", -- 0x0030
    x"F",x"D",x"0",x"6",x"F",x"9",x"B",x"4", -- 0x0038

    x"F",x"9",x"B",x"9",x"F",x"9",x"B",x"B", -- 0x0040
    x"F",x"D",x"5",x"E",x"F",x"9",x"B",x"1", -- 0x0048
    x"F",x"9",x"4",x"1",x"F",x"9",x"B",x"5", -- 0x0050
    x"F",x"9",x"B",x"D",x"F",x"9",x"9",x"1", -- 0x0058

    x"F",x"D",x"7",x"E",x"0",x"0",x"0",x"0", -- 0x0060
    x"0",x"0",x"0",x"F",x"0",x"0",x"0",x"E", -- 0x0068
    x"0",x"D",x"F",x"D",x"F",x"F",x"F",x"D", -- 0x0070
    x"F",x"F",x"F",x"E",x"F",x"D",x"F",x"7", -- 0x0078

    x"F",x"F",x"F",x"F",x"F",x"D",x"E",x"0", -- 0x0080
    x"F",x"F",x"F",x"E",x"F",x"B",x"9",x"4", -- 0x0088
    x"F",x"9",x"B",x"9",x"F",x"9",x"B",x"B", -- 0x0090
    x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"F", -- 0x0098

    x"0",x"0",x"0",x"E",x"F",x"D",x"F",x"D", -- 0x00A0
    x"F",x"F",x"F",x"D",x"F",x"F",x"F",x"E", -- 0x00A8
    x"F",x"F",x"F",x"7",x"F",x"F",x"F",x"2", -- 0x00B0
    x"F",x"F",x"F",x"7",x"F",x"F",x"F",x"F", -- 0x00B8

    x"F",x"F",x"E",x"E",x"F",x"1",x"F",x"1", -- 0x00C0
    x"F",x"9",x"3",x"7",x"F",x"2",x"7",x"9", -- 0x00C8
    x"F",x"C",x"5",x"1",x"D",x"D",x"F",x"F", -- 0x00D0
    x"3",x"3",x"F",x"F",x"9",x"9",x"F",x"F", -- 0x00D8

    x"F",x"F",x"F",x"D",x"F",x"F",x"F",x"6", -- 0x00E0
    x"F",x"F",x"F",x"5",x"F",x"3",x"F",x"3", -- 0x00E8
    x"F",x"3",x"F",x"5",x"F",x"F",x"F",x"3", -- 0x00F0
    x"F",x"F",x"3",x"5",x"F",x"3",x"F",x"F"  -- 0x00F8
  );
begin
  p_rom : process(ADDR)
  begin
    DATA <= ROM(to_integer(unsigned(ADDR)));
  end process;
end RTL;
