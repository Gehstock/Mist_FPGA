--
-- A simulation model of VIC20 hardware
-- Copyright (c) MikeJ - March 2003
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
-- SUBSTITUTE GOODS OR SERoricES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- You are responsible for any legal issues arising from your use of this code.
--
-- The latest version of this file can be found at: www.fpgaarcade.com
--
-- Email vic20@fpgaarcade.com
--
--
-- Revision list
--
-- version 001 initial release
-- version 002 Modify for oric atmos project

-- ps2 interface returns keyboard press/release scan codes
-- these are mapped into a small ram which is harassed by the
-- VIA chip in the same way as the original keyboard.
--
-- Restore key mapped to PgUp
--
-- all cursor keys are directly mapped
--
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;
  LIBRARY WORK;
  use work.pack_oric_xilinx_prims.all;
  LIBRARY WORK;
  use work.pkg_oric.all;

entity oric_PS2_IF is
  port (
    PS2_CLK        : in    std_logic;
    PS2_DATA       : in    std_logic;

    COL_IN         : in    std_logic_vector(7 downto 0);
    ROW_IN         : in    std_logic_vector(7 downto 0);
    RESTORE        : out   std_logic;

    RESET_L        : in    std_logic;
    ENA_1MHZ       : in    std_logic;
    P2_H           : in    std_logic; -- high for phase 2 clock  ____----__
    CLK_4          : in    std_logic  -- 4x system clock (4MHZ)  _-_-_-_-_-
    );
end;

architecture RTL of oric_PS2_IF is

  component ps2kbd
      port(
          Rst_n     : in  std_logic;
          Clk       : in  std_logic;
          Tick1us   : in  std_logic;
          PS2_Clk   : in  std_logic;
          PS2_Data  : in  std_logic;
          Press     : out std_logic;
          Release   : out std_logic;
          Reset     : out std_logic;
          ScanE0    : out std_logic;
          ScanCode  : out std_logic_vector(7 downto 0));
  end component;

  signal tick_1us       : std_logic;
  signal kbd_press      : std_logic;
  signal kbd_release    : std_logic;
  signal kbd_reset      : std_logic;
  signal kbd_press_s    : std_logic;
  signal kbd_release_s  : std_logic;
  signal kbd_scancode   : std_logic_vector(7 downto 0);
  signal kbd_scanE0     : std_logic;
  
  signal rowcol         : std_logic_vector(5 downto 0);  

  signal ram_w_addr     : std_logic_vector(5 downto 0);
  signal ram_r_addr     : std_logic_vector(5 downto 0);
  signal ram_we         : std_ulogic;
  signal ram_din        : std_logic;
  signal ram_dout       : std_logic;

  signal reset_cnt      : std_logic_vector(6 downto 0);
  
begin

 -- oric standard:
 --
 -- |      1!  2@  3#  4$  5%  6^  7&  8*  9(  0)   -£   =+  \| |
 -- | ESC    q   w   e   r   t   y   u   i   o   p   [{  ]} DEL |
 -- |  CTRL   a   s   d   f   g   h   j   k   l   ;:  '" RETURN |
 -- |  SHIFT   z   x   c   v   b   n   m   ,<  .>  /? SHIFT     |
 -- |    LFT DWN  |___________SPACE___________| UP RGT FUNCT    |
 ----------------------------------------------------------------

  tick_1us <= ENA_1MHZ;

-- Keyboard decoder
u_kbd : ps2kbd
      port map(
          Rst_n    => RESET_L,
          Clk      => CLK_4,
          Tick1us  => tick_1us,
          PS2_Clk  => PS2_CLK,
          PS2_Data => PS2_DATA,
          Press    => kbd_press,
          Release  => kbd_release,
          Reset    => kbd_reset,
          ScanE0   => kbd_scanE0,
          ScanCode => kbd_scancode
          );

-- Generate ram for scancode translation
--kbd_ram : RAM64X1D
--    port map (
 --     a0    => ram_w_addr(0),
 --     a1    => ram_w_addr(1),
 --     a2    => ram_w_addr(2),
 --     a3    => ram_w_addr(3),
 --     a4    => ram_w_addr(4),
  --    a5    => ram_w_addr(5),
  --   dpra0 => ram_r_addr(0),
   --   dpra1 => ram_r_addr(1),
   --   dpra2 => ram_r_addr(2),
   --   dpra3 => ram_r_addr(3),
    --  dpra4 => ram_r_addr(4),
   --   dpra5 => ram_r_addr(5),        
   --   wclk  => CLK_4,
   --   we    => ram_we,
   --   d     => ram_din,
   --   dpo   => ram_dout,
   --   );

-- Translate scancode from PS2 to scancode for oric 
kbd_decode_scancode : process
begin
  wait until rising_edge(CLK_4);
  
  -- rowcol is valid for lots of clocks, but kbd_press / release are single
  -- clock strobes. must sync these to p2_h
  if (kbd_press = '1') then
     kbd_press_s <= '1';
  elsif (P2_H = '0') then
     kbd_press_s <= '0';
  end if;

  if (kbd_release = '1') then
     kbd_release_s <= '1';
  elsif (P2_H = '0') then
     kbd_release_s <= '0';
  end if;

  -- top bit low for keypress
  if (kbd_scanE0 = '0') then
    rowcol <= "111111";
    case kbd_scancode is
      --                     row/col       oric             ps2
      when x"3D"  => rowcol <= "000000";--  7               7
      when x"31"  => rowcol <= "000001";--  n               n
      when x"2E"  => rowcol <= "000010";--  5               5
      when x"2A"  => rowcol <= "000011";--  v               v
      when x"16"  => rowcol <= "000101";--  1               1
      when x"22"  => rowcol <= "000110";--  x               x
      when x"26"  => rowcol <= "000111";--  3               3

      when x"3B"  => rowcol <= "001000";--  j               j
      when x"2C"  => rowcol <= "001001";--  t               t
      when x"2D"  => rowcol <= "001010";--  r               r
      when x"2B"  => rowcol <= "001011";--  f               f
      when x"76"  => rowcol <= "001101";--  esc             esc
      when x"15"  => rowcol <= "001110";--  q               q
      when x"23"  => rowcol <= "001111";--  d               d

      when x"3A"  => rowcol <= "010000";--  m               m
      when x"36"  => rowcol <= "010001";--  6               6
      when x"32"  => rowcol <= "010010";--  b               b
      when x"25"  => rowcol <= "010011";--  4               4
      when x"14"  => rowcol <= "010100";--  ctrl            left_ctrl
      when x"1A"  => rowcol <= "010101";--  z               z
      when x"1E"  => rowcol <= "010110";--  2               2
      when x"21"  => rowcol <= "010111";--  c               c

      when x"42"  => rowcol <= "011000";--  k               k
      when x"46"  => rowcol <= "011001";--  9               9
      when x"4C"  => rowcol <= "011010";--  ;               ;
      when x"4E"  => rowcol <= "011011";--  -               -
      when x"5D"  => rowcol <= "011110";--  \               \
      when x"52"  => rowcol <= "011111";--  '               '

      when x"29"  => rowcol <= "100000";--  space           space
      when x"41"  => rowcol <= "100001";--  ,               ,
      when x"49"  => rowcol <= "100010";--  .               .
      when x"12"  => rowcol <= "100100";--  left_shift      left_shift

      when x"3C"  => rowcol <= "101000";--  u               u
      when x"43"  => rowcol <= "101001";--  i               i
      when x"44"  => rowcol <= "101010";--  o               o
      when x"4D"  => rowcol <= "101011";--  p               p
      when x"66"  => rowcol <= "101101";--  del             backspace
      when x"5B"  => rowcol <= "101110";--  ]               ]
      when x"54"  => rowcol <= "101111";--  [               [


      when x"35"  => rowcol <= "110000";--  y               y
      when x"33"  => rowcol <= "110001";--  h               h
      when x"34"  => rowcol <= "110010";--  g               g
      when x"24"  => rowcol <= "110011";--  e               e
      when x"1C"  => rowcol <= "110101";--  a               a
      when x"1B"  => rowcol <= "110110";--  s               s
      when x"1D"  => rowcol <= "110111";--  w               w

      when x"3E"  => rowcol <= "111000";--  8               8
      when x"4B"  => rowcol <= "111001";--  l               l
      when x"45"  => rowcol <= "111010";--  0               0
      when x"4A"  => rowcol <= "111011";--  /               /
      when x"59"  => rowcol <= "111100";--  right_shift     right_shift
      when x"5A"  => rowcol <= "111101";--  return          return
      when x"55"  => rowcol <= "111111";--  =               =
      when others => rowcol <= "ZZZZZZ";
    end case;
  else
    rowcol <= "111111";
    case kbd_scancode is
      when x"75"  => rowcol <= "100011";--  up              up_cursor
      when x"6B"  => rowcol <= "100101";--  left            left_cursor
      when x"72"  => rowcol <= "100110";--  down            down_cursor
      when x"74"  => rowcol <= "100111";--  right           right_cursor
      when x"11"  => rowcol <= "101100";--  fct             right_alt
      when others => rowcol <= "111111";
    end case;
  end if;
end process;


-- counter used to reset ram
kbd_reset_cnt : process(RESET_L, CLK_4)
begin
  if (RESET_L = '0') then
    reset_cnt <= "1000000";
  elsif rising_edge(CLK_4) then    
        if (kbd_reset = '1') then
           reset_cnt <= "1000000";
        elsif (reset_cnt(6) = '1') then
           reset_cnt <= reset_cnt + "1";
        end if;
  end if;
end process;

-- write scancode is pressed
kbd_write : process(kbd_press_s, kbd_release_s, rowcol, kbd_reset, reset_cnt, P2_H)
  variable we : boolean;
begin

  -- valid key ?
  we := ((kbd_press_s = '1') or (kbd_release_s = '1'));

  if (reset_cnt(6) = '1') then
    ram_w_addr <= reset_cnt(5 downto 0);
    ram_din    <= '0';
    ram_we     <= '1';
  else
    ram_w_addr <= rowcol;

    if (kbd_press_s = '1') then
      ram_din <= '1'; -- pressed
    else
      ram_din <= '0'; -- released
    end if;

    ram_we <= '0';
    if we and (P2_H = '0')then
      ram_we <= '1';
    end if;
  end if;

end process;
 
-- Manage
RESTORE <= '1'; -- To modify
--ram_r_addr   <= ROW_IN & COL_IN;

end architecture RTL;

