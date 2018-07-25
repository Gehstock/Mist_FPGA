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

entity BALLY_ADDR is
  port (
    I_MXA             : in    std_logic_vector(15 downto  0);
    I_MXD             : in    std_logic_vector( 7 downto  0);
    O_MXD             : out   std_logic_vector( 7 downto  0);
    O_MXD_OE_L        : out   std_logic;

    -- cpu control signals
    I_RFSH_L          : in    std_logic;
    I_M1_L            : in    std_logic;
    I_RD_L            : in    std_logic;
    I_MREQ_L          : in    std_logic;
    I_IORQ_L          : in    std_logic;
    O_WAIT_L          : out   std_logic;
    O_INT_L           : out   std_logic;

    -- custom
    I_HORIZ_DR        : in    std_logic;
    I_VERT_DR         : in    std_logic;
    O_WRCTL_L         : out   std_logic; -- present ram write data
    O_LTCHDO          : out   std_logic; -- latch ram read data

    -- dram address (sram now)
    O_MA              : out   std_logic_vector(15 downto 0);
    O_RAS             : out   std_logic; -- for simulation

    -- misc
    I_LIGHT_PEN_L     : in    std_logic;

    -- clks
    I_CPU_ENA         : in    std_logic;
    ENA               : in    std_logic;
    CLK               : in    std_logic
    );
end;

architecture RTL of BALLY_ADDR is
  --  Signals
  signal mxa_t1               : std_logic_vector(15 downto 0);
  signal page_03              : std_logic;
  signal page_47              : std_logic;
  signal page_8B              : std_logic;
  signal ports_10_17          : std_logic;
  signal vector_read          : std_logic;
  signal rw                   : std_logic;
  signal iorw                 : std_logic;
  signal mreq_l_e1            : std_logic;
  signal iorq_l_e1            : std_logic;
  signal start_cpu_cyc        : std_logic;
  signal delay_cpu_cyc        : std_logic;
  signal start_cpu_cyc_late   : std_logic;
  signal cpu_cyc              : std_logic;
  signal cpu_cyc_t1           : std_logic;
  signal start_io_cyc         : std_logic;
  signal start_io_cyc_e1      : std_logic;
  signal start_io_cyc_e2      : std_logic;
  signal video_cyc            : std_logic;
  signal video_cyc_ras        : std_logic;
  signal video_cyc_ras_t1     : std_logic;

  signal m1_wait              : std_logic;
  signal io_wait              : std_logic;
  signal io_wait_t1           : std_logic;
  signal io_wait_t2           : std_logic;
  signal ras_int              : std_logic;
  signal ras_int_t1           : std_logic;
  signal wrctl_int            : std_logic;
  signal wrctl_int_t1         : std_logic;
  signal ltchdo_int           : std_logic;
  signal ltchdo_int_t1        : std_logic;
  --
  signal cs                   : std_logic;
  signal r_hi_res             : std_logic;
  signal r_vert_blank         : std_logic_vector(7 downto 0) := x"10"; -- line 8 (7..1)
  signal r_int_fb             : std_logic_vector(7 downto 0);
  signal r_int_ena_mode       : std_logic_vector(7 downto 0);
  signal r_int_line           : std_logic_vector(7 downto 0);

  --
  signal horiz_dr_t1          : std_logic;
  signal h_start              : boolean;
  signal horiz_pos            : std_logic_vector(7 downto 0) := (others => '0');
  signal vert_pos             : std_logic_vector(7 downto 0) := (others => '0');
  signal horiz_eol            : boolean;
  signal hactv                : std_logic;
  signal vactv                : std_logic;
  -- addr gen
  signal vert_addr_gen        : std_logic_vector(15 downto 0);
  signal vert_line_sel        : std_logic;
  signal addr_gen             : std_logic_vector(15 downto 0);
  signal addr_gen_t1          : std_logic_vector(15 downto 0);
  --
  signal lightpen_int         : std_logic := '0';
  signal screen_int           : std_logic := '0';
  signal int_out              : std_logic;
  signal int_auto_clear       : std_logic;
  signal int_auto_clear_e1    : std_logic;
begin

  p_chip_sel             : process(I_CPU_ENA, I_MXA)
  begin
    cs <= '0';
    if (I_CPU_ENA = '1') then -- cpu access
      if (I_MXA(7 downto 4) = "0000") then
        cs <= '1';
      end if;
    end if;
  end process;

  p_reg_write            : process
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then
      if (I_RD_L = '1') and (I_IORQ_L = '0') and (I_M1_L = '1') and (cs = '1') then
        case I_MXA(3 downto 0) is
          when x"8" => r_hi_res              <= I_MXD(0);
          when x"A" => r_vert_blank          <= I_MXD;
          when x"D" => r_int_fb              <= I_MXD; -- D int vec. 3..0 set to zero for lightpen
          when x"E" => r_int_ena_mode        <= I_MXD; -- E
          when x"F" => r_int_line            <= I_MXD; -- F
          when others => null;
        end case;
      end if;
    end if;
  end process;

  p_decode_cpu           : process(I_MXA, I_RFSH_L, I_M1_L, I_MREQ_L, I_IORQ_L)
  begin
    page_03 <= '0';
    page_47 <= '0';
    page_8B <= '0';
    ports_10_17 <= '0';

    if (I_MXA(15 downto 14) = "00") then -- 0x0000 - 0x3FFF
    --if (I_MXA(14) = '0') then -- I think magic writes alias (not in high res)
      page_03 <= '1';
    end if;

    if (I_MXA(15 downto 14) = "01") then -- 0x4000 - 0x7FFF
      page_47 <= '1';
    end if;

    if (I_MXA(15 downto 14) = "10") then -- 0x8000 - 0xBFFF
      page_8B <= '1';
    end if;

    if (I_MXA(7 downto 5) = "000") and (I_MXA(3) = '0') then
      ports_10_17 <= '1';
    end if;

    vector_read <= not I_IORQ_L and not I_M1_L; -- interrupt ack
    iorw        <= not I_IORQ_L and     I_M1_L;
    rw          <= not I_MREQ_L and     I_RFSH_L;


  end process;

  -- if start ram cyc and video cyc, assert wait for a clock then kick off
  -- start ram cyc a clock later
  p_cyc_start            : process(page_03, page_47, page_8B, rw, mreq_l_e1, iorw, iorq_l_e1, i_RD_L)
  begin
    start_cpu_cyc <= (page_8B and rw and mreq_l_e1) or
                     (page_47 and rw and mreq_l_e1) or
                     (page_03 and rw and mreq_l_e1 and I_RD_L); -- magic write

    start_io_cyc <=  iorw and iorq_l_e1;
  end process;

  p_cpu_cyc              : process(start_cpu_cyc, start_cpu_cyc_late, video_cyc)
  begin
    cpu_cyc <= (start_cpu_cyc and not video_cyc) or start_cpu_cyc_late;
    delay_cpu_cyc <= start_cpu_cyc and video_cyc;
  end process;

  p_ram_control_cpu_ena  : process
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then
      if (I_CPU_ENA = '1') then
        start_cpu_cyc_late <= delay_cpu_cyc;

        mreq_l_e1 <= I_MREQ_L;
        iorq_l_e1 <= I_IORQ_L;

        ras_int <= cpu_cyc;
        wrctl_int <= cpu_cyc and I_RD_L;
        ltchdo_int <= cpu_cyc and not I_RD_L;

        m1_wait <= cpu_cyc and not I_M1_L; -- extra wait for instruction fetch

        start_io_cyc_e1 <= start_io_cyc;
        start_io_cyc_e2 <= start_io_cyc_e1;

        if (I_RD_L = '0') and (ports_10_17 = '1') then
          io_wait <= start_io_cyc or start_io_cyc_e1 or start_io_cyc_e2;
        else
          io_wait <= start_io_cyc;
        end if;

      end if;
    end if;
  end process;

  p_ram_address          : process
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then
      mxa_t1 <= I_MXA;
      if (video_cyc_ras_t1 = '1') then
        -- video addr
        if (r_hi_res = '1') then
          O_MA <= addr_gen_t1(14 downto 0) & '0';
        else
          O_MA <= x"0" & addr_gen_t1(11 downto 0);
        end if;
      else
        O_MA <= mxa_t1(15 downto 0);
      end if;
    end if;
  end process;

  p_ram_control          : process
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then

      -- wrctl same timing as RAS for write
      -- in real chip I think it's backedge clocked off cpu clk. We will clock it out on clk_7

      -- ras 0 - 3 would be decoded from top 2 addr bits
      -- driven for simluation.
      cpu_cyc_t1 <= cpu_cyc;
      ras_int_t1 <= ras_int;

      if (video_cyc_ras_t1 = '1') then
        O_RAS <= '1';
      else
        if (I_RD_L = '0') then
          O_RAS <= cpu_cyc_t1; -- clock early for read
        else
          O_RAS <= ras_int_t1;
        end if;
      end if;

      wrctl_int_t1 <= wrctl_int;
      O_WRCTL_L <= not wrctl_int_t1;

      ltchdo_int_t1 <= ltchdo_int;
      O_LTCHDO <= ltchdo_int_t1;
    end if;
  end process;

  p_mxd_oe               : process(vector_read, r_int_fb)
  begin
    O_MXD <= x"00";
    O_MXD_OE_L <= '1';
    if (vector_read = '1') then
      -- if light pen then set bottom 4 bits to 0 (not imp)
      O_MXD <= r_int_fb;
      O_MXD_OE_L <= '0';
    end if;
  end process;

  -- ** our wait is 1/2 cpu cycle late as our cpu drops mreq later than a real one **
  -- two wait states if opcode fetch from ram
  -- two wait states for io r/w except reads from addr 10-17 which have four wait states
  -- real z80's insert one wait state automatically
  O_WAIT_L <= not (cpu_cyc or delay_cpu_cyc or m1_wait or start_io_cyc or io_wait);

  -- video timing
  p_start_of_line        : process(I_HORIZ_DR, horiz_dr_t1)
  begin
    h_start <= (I_HORIZ_DR = '1') and (horiz_dr_t1 = '0'); -- rising edge
  end process;

  p_active_picture       : process
    variable vcomp : std_logic_vector(7 downto 0);
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then

      if (I_HORIZ_DR = '1') then
        horiz_pos <= (others => '0');
      elsif (I_CPU_ENA = '1') then -- clk phi
        horiz_pos <= horiz_pos + "1";
      end if;

      horiz_dr_t1 <= I_HORIZ_DR;
      if (I_VERT_DR = '1') then
        vert_pos <= (others => '0');
      elsif h_start then
        if (vert_pos = x"ff") then
          null;
        else
          vert_pos <= vert_pos + "1";
        end if;
      end if;

      -- bit of guesswork here
      horiz_eol <=  false;
      if (I_CPU_ENA = '1') then
        if (horiz_pos = x"01") then
          hactv <= '1';
        elsif (horiz_pos = x"51") then
          horiz_eol <= true;
          hactv <= '0';
        end if;
      end if;
      vcomp := r_vert_blank(7 downto 0);
      -- ADDR chip does video fetch for all lines - 191 lines for boot menu, 190 displayed
      --if (r_hi_res = '0') then
        --vcomp(0) := '0';
      --end if;

      -- vert_pos gets reset with vert_drv and then must not wrap until the next one.
      vactv <= '0';
      if (vert_pos < vcomp) then -- vcomp is x2 as bits 7..1 used
        vactv <= '1';
      end if;
    end if;
  end process;

  p_video_cyc            : process
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then
      if (I_CPU_ENA = '1') then
        video_cyc <= '0';
        if (hactv = '1') and (vactv = '1') and (horiz_pos(0) = '0') then
          video_cyc <= '1';
        end if;
        video_cyc_ras <= video_cyc;
      end if;
      video_cyc_ras_t1 <= video_cyc_ras;
    end if;
  end process;

  p_video_addr_gen       : process
    variable eol : boolean;
  begin
    wait until rising_edge(CLK);
    eol := (horiz_pos = x"60") and (I_CPU_ENA = '1'); -- not critical as long as before h_start
    if (ENA = '1') then
      if (I_VERT_DR = '1') then
        vert_addr_gen <= (others => '0');
        vert_line_sel <= '0';
      elsif eol then
        vert_line_sel <= not vert_line_sel;
        if (vert_line_sel = '1') or (r_hi_res = '1') then
          -- inc line early
          vert_addr_gen <= vert_addr_gen + x"0028"; -- 40 decimal
        end if;
      end if;

      if (I_VERT_DR = '1') then
        addr_gen <= (others => '0');
      elsif h_start then
        addr_gen <= vert_addr_gen; -- load
      elsif (video_cyc_ras = '1') and (I_CPU_ENA = '1') then
        addr_gen <= addr_gen + "1"; -- inc
      end if;

      addr_gen_t1 <= addr_gen;
    end if;
  end process;
  --
  -- interrupt
  --
  p_interrupt            : process
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then
      -- r_int_ena_mode
      -- bit 0 light pen mode (0 continue interrupt, 1 auto int clear at next inst)
      -- bit 1 light pen interrupt enable
      -- bit 2 screen mode (as 0)
      -- bit 3 screen interrupt enable

      -- r_int_fb interrupt vector, set lower 4 bits to 0 for light pen interrupt
      -- r_int_line interrupt on line number (7..1) low res - when completes scanning
      -- int ack by iorq_l and mreq_l active together

      -- guess where the interrupt happens, lets use the clock right after active video
      -- also assuming first 2 lines are line 0 ?? so writing 4 will interrupt after
      -- the sixth scan line (3rd whole line)
      --screen_int <= '0';
      if horiz_eol then
        if (vert_pos(7 downto 0) = (r_int_line(7 downto 1) & '1')) then -- low res
          screen_int <= '1';
        end if;
      end if;

      if (vector_read = '1') or ((int_auto_clear_e1 = '1') and (r_int_ena_mode(2) = '1')) then
        screen_int <= '0';
      end if;

      lightpen_int <= '0';

      -- auto clear
      if (I_CPU_ENA = '1') and (I_M1_L = '0') then
        int_auto_clear <= int_out;
        int_auto_clear_e1 <= int_auto_clear;
      end if;
    end if;
  end process;

  p_combine_interrupts   : process
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then
      int_out <= '0';
      if (r_int_ena_mode(1) = '1') then
        if (lightpen_int = '1') then int_out <= '1'; end if;
      end if;

      if (r_int_ena_mode(3) = '1') then
        if (screen_int = '1') then int_out <= '1'; end if;
      end if;
    end if;
  end process;
  O_INT_L <= not int_out;

end architecture RTL;

