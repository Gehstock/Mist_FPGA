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
use ieee.numeric_std.all;

entity BALLY_COL_PAL is
  port (
    ADDR        : in    std_logic_vector(7 downto 0);
    DATA        : out   std_logic_vector(11 downto 0)
    );
end;

architecture RTL of BALLY_COL_PAL is

  type ROM_ARRAY is array(0 to 255) of std_logic_vector(11 downto 0);
  constant ROM : ROM_ARRAY := (
  x"000", x"222", x"444", x"666", x"999", x"BBB", x"DDD", x"FFF",
  x"20B", x"40E", x"61F", x"93F", x"B5F", x"D7F", x"FAF", x"FCF",
  x"40B", x"60D", x"90F", x"B2F", x"D4F", x"F6F", x"F9F", x"FBF",
  x"609", x"80C", x"B0E", x"D1F", x"F3F", x"F6F", x"F8F", x"FAF",
  x"808", x"A0A", x"D0D", x"F0F", x"F3F", x"F5F", x"F7F", x"F9F",
  x"906", x"C08", x"E0B", x"F0D", x"F2F", x"F5F", x"F7F", x"F9F",
  x"B04", x"D06", x"F09", x"F0B", x"F2D", x"F4F", x"F7F", x"F9F",
  x"B02", x"E04", x"F06", x"F09", x"F2B", x"F4D", x"F7F", x"F9F",
  x"B00", x"E02", x"F04", x"F06", x"F39", x"F5B", x"F7D", x"F9F",
  x"B00", x"E00", x"F02", x"F14", x"F36", x"F59", x"F8B", x"FAD",
  x"B00", x"D00", x"F00", x"F22", x"F44", x"F66", x"F89", x"FBB",
  x"900", x"C00", x"E00", x"F30", x"F52", x"F74", x"F97", x"FC9",
  x"800", x"A00", x"D10", x"F40", x"F60", x"F82", x"FA5", x"FD7",
  x"600", x"800", x"B30", x"D50", x"F70", x"F91", x"FC3", x"FE5",
  x"400", x"620", x"940", x"B60", x"D80", x"FB0", x"FD2", x"FF4",
  x"210", x"430", x"650", x"970", x"BA0", x"DC0", x"FE1", x"FF4",
  x"020", x"240", x"460", x"690", x"9B0", x"BD0", x"DF1", x"FF3",
  x"030", x"050", x"280", x"4A0", x"6C0", x"9E0", x"BF1", x"DF4",
  x"040", x"060", x"090", x"2B0", x"4D0", x"6F0", x"9F2", x"BF4",
  x"050", x"070", x"090", x"0C0", x"2E0", x"4F1", x"7F3", x"9F5",
  x"050", x"080", x"0A0", x"0C0", x"0F0", x"2F2", x"5F5", x"7F7",
  x"060", x"080", x"0A0", x"0D0", x"0F2", x"1F4", x"3F7", x"5F9",
  x"060", x"080", x"0B0", x"0D2", x"0F4", x"0F6", x"2F9", x"4FB",
  x"060", x"080", x"0A2", x"0D4", x"0F6", x"0F9", x"1FB", x"4FD",
  x"060", x"082", x"0A4", x"0C6", x"0F9", x"0FB", x"1FD", x"3FF",
  x"052", x"074", x"0A6", x"0C9", x"0EB", x"0FD", x"1FF", x"4FF",
  x"044", x"076", x"099", x"0BB", x"0DD", x"0FF", x"2FF", x"4FF",
  x"036", x"068", x"08B", x"0AD", x"0CF", x"1FF", x"3FF", x"5FF",
  x"028", x"04A", x"07D", x"09F", x"0BF", x"2EF", x"5FF", x"7FF",
  x"019", x"03C", x"06E", x"08F", x"2AF", x"4CF", x"7FF", x"9FF",
  x"00B", x"02D", x"04F", x"27F", x"49F", x"6BF", x"9DF", x"BFF",
  x"00B", x"01E", x"23F", x"45F", x"68F", x"9AF", x"BCF", x"DEF"
  );

begin

  p_rom : process(ADDR)
  begin
     DATA <= ROM(to_integer(unsigned(ADDR)));
  end process;

end RTL;

