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

entity BALLY_RAMS is
  port (
  ADDR     : in  std_logic_vector(15 downto 0);
  DIN      : in  std_logic_vector(7  downto 0);
  DOUT     : out std_logic_vector(7  downto 0);
  DOUTX    : out std_logic_vector(7  downto 0); -- next byte
  WE       : in  std_logic;
  WE_ENA_L : in  std_logic; -- used for write enable gate only
  ENA      : in  std_logic;
  CLK      : in  std_logic
  );
end;

architecture RTL of BALLY_RAMS is
  type  array_7x8 is array (0 to 6) of std_logic_vector(7 downto 0);
  --
  signal dout_int_h       : array_7x8;
  signal dout_int_l       : array_7x8;
  signal addr_t1          : std_logic_vector(15 downto 0);
  signal int_we_h         : std_logic_vector(6 downto 0);
  signal int_we_l         : std_logic_vector(6 downto 0);

-- we can have 14 rams total
-- 4000-4FFF 4K

-- 16K screen ram 4000-7fff this is aliased to 0000-3FFF for magic
-- spare 8000-BFFF (but we are only have enough rams to go to AFFF for now)
begin
  p_we : process(ADDR, WE, WE_ENA_L)
    variable h,l : std_logic;
  begin
    int_we_h <= (others => '0');
    int_we_l <= (others => '0');
    l := (not ADDR(0)) and WE and (not WE_ENA_L);
    h :=      ADDR(0)  and WE and (not WE_ENA_L);
    --
    case ADDR(15 downto 12) is
      when x"0" => int_we_h(0) <= h; int_we_l(0) <= l;
      when x"1" => int_we_h(1) <= h; int_we_l(1) <= l;
      when x"2" => int_we_h(2) <= h; int_we_l(2) <= l;
      when x"3" => int_we_h(3) <= h; int_we_l(3) <= l;
      --
      when x"4" => int_we_h(0) <= h; int_we_l(0) <= l;
      when x"5" => int_we_h(1) <= h; int_we_l(1) <= l;
      when x"6" => int_we_h(2) <= h; int_we_l(2) <= l;
      when x"7" => int_we_h(3) <= h; int_we_l(3) <= l;
      --
      when x"8" => int_we_h(4) <= h; int_we_l(4) <= l;
      when x"9" => int_we_h(5) <= h; int_we_l(5) <= l;
      when x"A" => int_we_h(6) <= h; int_we_l(6) <= l;
      --when x"B" => int_we_h(7) <= h; int_we_l(7) <= l;
      --
      when others => null;
    end case;
  end process;
  


  rams : for i in 0 to 6 generate
  begin
		ram_u : entity work.spram
			generic map (
				init_file     => "",
				widthad_a     => 11,
				width_a     => 8
			)
			port map (
				address     => ADDR(11 downto 1),
				clock     => CLK,
				data     => DIN(7 downto 0),
				wren     => int_we_h(i),
				q     => dout_int_h(i)(7 downto 0)
			);
		ram_l : entity work.spram
			generic map (
				init_file     => "",
				widthad_a     => 11,
				width_a     => 8
			)
			port map (
				address     => ADDR(11 downto 1),
				clock     => CLK,
				data     => DIN(7 downto 0),
				wren     => int_we_l(i),
				q     => dout_int_l(i)(7 downto 0)
			);	
  end generate;

  p_addr_delay : process
  begin
    wait until rising_edge(CLK);
    addr_t1 <= ADDR;
  end process;

  p_mux : process(dout_int_l, dout_int_h, addr, addr_t1)
    variable mux_h : std_logic_vector(7 downto 0);
    variable mux_l : std_logic_vector(7 downto 0);
  begin

    mux_h := dout_int_h(0); mux_l := dout_int_l(0);
    case addr_t1(15 downto 12) is
      when x"0" => mux_h := dout_int_h(0); mux_l := dout_int_l(0);
      when x"1" => mux_h := dout_int_h(1); mux_l := dout_int_l(1);
      when x"2" => mux_h := dout_int_h(2); mux_l := dout_int_l(2);
      when x"3" => mux_h := dout_int_h(3); mux_l := dout_int_l(3);
      --
      when x"4" => mux_h := dout_int_h(0); mux_l := dout_int_l(0);
      when x"5" => mux_h := dout_int_h(1); mux_l := dout_int_l(1);
      when x"6" => mux_h := dout_int_h(2); mux_l := dout_int_l(2);
      when x"7" => mux_h := dout_int_h(3); mux_l := dout_int_l(3);
      --
      when x"8" => mux_h := dout_int_h(4); mux_l := dout_int_l(4);
      when x"9" => mux_h := dout_int_h(5); mux_l := dout_int_l(5);
      when x"A" => mux_h := dout_int_h(6); mux_l := dout_int_l(6);
      --when x"B" => mux_h := dout_int_h(7); mux_l := dout_int_l(7);
      --
      when others => null;
    end case;

    if (addr_t1(0) = '0') then
      DOUT <= mux_l;
    else
      DOUT <= mux_h;
    end if;
    DOUTX <= mux_h;

  end process;

end architecture RTL;
