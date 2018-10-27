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
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

entity BALLY_PS2_IF is
  port (

    I_PS2_CLK         : in    std_logic;
    I_PS2_DATA        : in    std_logic;

    I_COL             : in    std_logic_vector(7 downto 0);
    O_ROW             : out   std_logic_vector(7 downto 0);

    I_RESET_L         : in    std_logic;
    I_1MHZ_ENA        : in    std_logic;
    CLK               : in    std_logic
    );
end;

architecture RTL of BALLY_PS2_IF is

  signal tick_1us       : std_logic;
  signal kbd_press      : std_logic;
  signal kbd_release    : std_logic;
  signal kbd_reset      : std_logic;
  signal kbd_press_s    : std_logic;
  signal kbd_release_s  : std_logic;
  signal kbd_scancode   : std_logic_vector(7 downto 0);
  signal kbd_scanE0     : std_logic;

  signal col_addr       : std_logic_vector(3 downto 0);
  signal rowcol         : std_logic_vector(7 downto 0);
  signal row_mask       : std_logic_vector(7 downto 0);

  signal ram_w_addr     : std_logic_vector(3 downto 0);
  signal ram_r_addr     : std_logic_vector(3 downto 0);
  signal ram_we         : std_ulogic;
  signal ram_din        : std_logic_vector(7 downto 0);
  signal ram_dout       : std_logic_vector(7 downto 0);

  signal reset_cnt      : std_logic_vector(4 downto 0);
  signal io_ena         : std_logic;
  -- non-xilinx ram
  type slv_array8 is array (natural range <>) of std_logic_vector(7 downto 0);
  shared variable  ram  : slv_array8(7 downto 0) := (others => (others => '0'));

begin

  -- port 7  6  5  4  3  2  1  0
  -- x10           tg rt lt dn up | player 1
  -- x11           tg rt lt dn up | player 2
  -- x12           tg rt lt dn up | player 3
  -- x13           tg rt lt dn up | player 4


  -- bit x17 x16 x15 x14    maps to pc key
  --
  -- 0    c   ^   v  %      z  a  q  1
  -- 1    mr  ms  ch /      x  s  w  2
  -- 2    7   8   9  x      c  d  e  3
  -- 3    4   5   6  -      v  f  r  4
  -- 4    1   2   3  +      b  g  t  5
  -- 5    ce  0   .  =      n  h  y  6

  tick_1us <= I_1MHZ_ENA;

  -- Keyboard decoder
  u_kbd : entity work.ps2kbd
        port map(
            Rst_n    => I_RESET_L,
            Clk      => CLK,
            Tick1us  => tick_1us,
            PS2_Clk  => I_PS2_CLK,
            PS2_Data => I_PS2_DATA,
            Press    => kbd_press,
            Release  => kbd_release,
            Reset    => kbd_reset,
            ScanE0   => kbd_scanE0,
            ScanCode => kbd_scancode
            );

  p_decode_scancode : process
  begin
    -- hopefully the tools will build a rom for this
    wait until rising_edge(CLK);
    -- rowcol is valid for lots of clocks, but kbd_press_t1 / release are single
    -- clock strobes. must sync these to io_ena
    if (kbd_press = '1') then
      kbd_press_s <= '1';
    elsif (io_ena = '0') then
      kbd_press_s <= '0';
    end if;

    if (kbd_release = '1') then
      kbd_release_s <= '1';
    elsif (io_ena = '0') then
      kbd_release_s <= '0';
    end if;

    -- top bit low for keypress
    if (kbd_scanE0 = '0') then
      rowcol <= x"ff";
      case kbd_scancode is
        -- player 1 col 0
        when x"29" => rowcol <= x"40";-- space
        -- player 2 col 1
        when x"75" => rowcol <= x"01";-- keypad8
        when x"72" => rowcol <= x"11";-- keypad2
        when x"6B" => rowcol <= x"21";-- keypad4
        when x"74" => rowcol <= x"31";-- keypad6
        when x"70" => rowcol <= x"41";-- keypad0
        -- player 3 col 2 not mapped
        -- player 4 col 3 not mapped

        -- keypad col 4
        when x"16" => rowcol <= x"04";-- 1
        when x"1E" => rowcol <= x"14";-- 2
        when x"26" => rowcol <= x"24";-- 3
        when x"25" => rowcol <= x"34";-- 4
        when x"2E" => rowcol <= x"44";-- 5
        when x"36" => rowcol <= x"54";-- 6
        -- keypad col 5
        when x"15" => rowcol <= x"05";-- q
        when x"1D" => rowcol <= x"15";-- w
        when x"24" => rowcol <= x"25";-- e
        when x"2D" => rowcol <= x"35";-- r
        when x"2C" => rowcol <= x"45";-- t
        when x"35" => rowcol <= x"55";-- y
        -- keypad col 6
        when x"1C" => rowcol <= x"06";-- a
        when x"1B" => rowcol <= x"16";-- s
        when x"23" => rowcol <= x"26";-- d
        when x"2B" => rowcol <= x"36";-- f
        when x"34" => rowcol <= x"46";-- g
        when x"33" => rowcol <= x"56";-- h
        -- keypad col 7
        when x"1A" => rowcol <= x"07";-- z
        when x"22" => rowcol <= x"17";-- x
        when x"21" => rowcol <= x"27";-- c
        when x"2A" => rowcol <= x"37";-- v
        when x"32" => rowcol <= x"47";-- b
        when x"31" => rowcol <= x"57";-- n

        when others => rowcol <= x"FF";
      end case;
    else
      rowcol <= x"ff";
      case kbd_scancode is
        when x"75" => rowcol <= x"00";-- curs up
        when x"72" => rowcol <= x"10";-- curs dn
        when x"6B" => rowcol <= x"20";-- curs left
        when x"74" => rowcol <= x"30";-- curs right
        when others => rowcol <= x"FF";
      end case;
    end if;
  end process;

  p_expand_row : process(rowcol)
  begin
    row_mask <= x"01";
    case rowcol(6 downto 4) is
      when "000" => row_mask <= x"01";
      when "001" => row_mask <= x"02";
      when "010" => row_mask <= x"04";
      when "011" => row_mask <= x"08";
      when "100" => row_mask <= x"10";
      when "101" => row_mask <= x"20";
      when "110" => row_mask <= x"40";
      when "111" => row_mask <= x"80";
      when others => null;
    end case;
  end process;

  p_reset_cnt : process(I_RESET_L, CLK)
  begin
    if (I_RESET_L = '0') then
      reset_cnt <= "00000";
      io_ena <= '0';
    elsif rising_edge(CLK) then
    -- counter used to reset ram
      if (kbd_reset = '1') then
        reset_cnt <= "10000";
      elsif (reset_cnt(4) = '1') then
        reset_cnt <= reset_cnt + "1";
      end if;
      io_ena <= not io_ena;
    end if;
  end process;

  p_keybd_write : process(kbd_press_s, kbd_release_s, rowcol,
                          kbd_reset, reset_cnt, ram_dout, row_mask, io_ena)
    variable we : boolean;
  begin
    -- valid key ?
    we := ((kbd_press_s = '1') or (kbd_release_s = '1')) and (rowcol(7) = '0');

    if (reset_cnt(4) = '1') then
      ram_w_addr <= reset_cnt(3 downto 0);
      ram_din    <= x"00";
      ram_we     <= '1';
    else
      ram_w_addr <= rowcol(3 downto 0);

      if (kbd_press_s = '1') then
        ram_din  <= ram_dout or      row_mask; -- pressed
      else
        ram_din  <= ram_dout and not row_mask; -- released
      end if;

      ram_we <= '0';
      if we and  (io_ena = '0')then
        ram_we <= '1';
      end if;
    end if;

  end process;


  p_ram_w : process
    variable ram_addr : integer := 0;
  begin
    wait until rising_edge(CLK);
    if (ram_we = '1') then
      ram_addr := to_integer(unsigned(ram_w_addr(2 downto 0)));
      ram(ram_addr) := ram_din;
    end if;
  end process;

  p_ram_r : process(CLK, ram_r_addr)
    variable ram_addr : integer := 0;
  begin
    ram_addr := to_integer(unsigned(ram_r_addr(2 downto 0)));
    ram_dout <= ram(ram_addr);
  end process;

  -- the io chip can access the ram when io_ena = '1'
  p_ram_read_mux : process(io_ena, col_addr, rowcol)
  begin
    if (io_ena = '1') then
      ram_r_addr <= col_addr;
    else
      ram_r_addr <= rowcol(3 downto 0); -- write r/m/w
    end if;
  end process;

  p_via_out_reg : process
  begin
    wait until rising_edge(CLK);
    if (io_ena = '1') then
      if (col_addr = x"f") then -- none
        O_ROW <= x"00";
      else
        O_ROW <= ram_dout; -- switches are active high
      end if;
    end if;
  end process;

  p_col_decode : process(I_COL)
  begin
    col_addr <= x"F";
    case I_COL is
      when x"01" => col_addr <= x"0";
      when x"02" => col_addr <= x"1";
      when x"04" => col_addr <= x"2";
      when x"08" => col_addr <= x"3";
      when x"10" => col_addr <= x"4";
      when x"20" => col_addr <= x"5";
      when x"40" => col_addr <= x"6";
      when x"80" => col_addr <= x"7";
      when others => null;
    end case;
  end process;

end architecture RTL;

