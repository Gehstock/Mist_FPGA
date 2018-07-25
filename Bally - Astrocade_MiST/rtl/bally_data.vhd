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
-- microcycler not used
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;

entity BALLY_DATA is
  port (
    I_MXA             : in    std_logic_vector(15 downto  0);
    I_MXD             : in    std_logic_vector( 7 downto  0);
    O_MXD             : out   std_logic_vector( 7 downto  0);
    O_MXD_OE_L        : out   std_logic;

    -- cpu control signals
    I_M1_L            : in    std_logic;
    I_RD_L            : in    std_logic;
    I_MREQ_L          : in    std_logic;
    I_IORQ_L          : in    std_logic;

    -- memory
    O_DATEN_L         : out   std_logic;  -- looks like the real chip
    O_DATWR           : out   std_logic;  -- ram ena to fake up write at rising edge of DATEN_L
    I_MDX             : in    std_logic_vector( 7 downto 0); -- upper 8 bits for high res
    I_MD              : in    std_logic_vector( 7 downto 0);
    O_MD              : out   std_logic_vector( 7 downto 0);
    O_MD_OE_L         : out   std_logic;
    -- custom
    O_MC1             : out   std_logic;
    O_MC0             : out   std_logic;

    O_HORIZ_DR        : out   std_logic;
    O_VERT_DR         : out   std_logic;
    I_WRCTL_L         : in    std_logic;
    I_LTCHDO          : in    std_logic;

    I_SERIAL1         : in    std_logic;
    I_SERIAL0         : in    std_logic;

    O_VIDEO_R         : out   std_logic_vector(3 downto 0);
    O_VIDEO_G         : out   std_logic_vector(3 downto 0);
    O_VIDEO_B         : out   std_logic_vector(3 downto 0);
    O_HSYNC           : out   std_logic;
    O_VSYNC           : out   std_logic;
    O_FPSYNC          : out   std_logic; -- first active pixel

    -- clks
    O_CPU_ENA         : out   std_logic; -- cpu clock ena
    O_PIX_ENA         : out   std_logic; -- pixel clock ena
    ENA               : in    std_logic;
    CLK               : in    std_logic
    );
end;

architecture RTL of BALLY_DATA is

  --  const
  -- horizontal timing constants
  -- approx 78 clocks blanking,34 for sync

  -- original 7.159 Mhz clock
  constant H_LINE_SYNCS         : std_logic_vector(8 downto 0) := conv_std_logic_vector(  0,9);
  constant H_LINE_SYNCR         : std_logic_vector(8 downto 0) := conv_std_logic_vector( 33,9);
  constant H_BLANK_N1S          : std_logic_vector(8 downto 0) := conv_std_logic_vector(  0,9); -- first eq
  constant H_BLANK_N1R          : std_logic_vector(8 downto 0) := conv_std_logic_vector( 16,9);
  constant H_BLANK_N2S          : std_logic_vector(8 downto 0) := conv_std_logic_vector(227,9); -- second eq
  constant H_BLANK_N2R          : std_logic_vector(8 downto 0) := conv_std_logic_vector(243,9);
  constant H_BLANK_B1S          : std_logic_vector(8 downto 0) := conv_std_logic_vector(  0,9); -- first broad
  constant H_BLANK_B1R          : std_logic_vector(8 downto 0) := conv_std_logic_vector(193,9);
  constant H_BLANK_B2S          : std_logic_vector(8 downto 0) := conv_std_logic_vector(227,9); -- second broad
  constant H_BLANK_B2R          : std_logic_vector(8 downto 0) := conv_std_logic_vector(421,9);
  constant H_BLANK_S            : std_logic_vector(8 downto 0) := conv_std_logic_vector(444,9); -- horiz blanking
  constant H_BLANK_R            : std_logic_vector(8 downto 0) := conv_std_logic_vector( 67,9); -- 78 clocks, starting 12 before sync

  constant H_BLANK_LR           : std_logic_vector(8 downto 0) := conv_std_logic_vector(245,9); -- half line left reset
  constant H_BLANK_RS           : std_logic_vector(8 downto 0) := conv_std_logic_vector(225,9); -- half line right set

  --constant H_DRIVE_S            : std_logic_vector(8 downto 0) := conv_std_logic_vector( 60,9); -- hdrive pulse
  --constant H_DRIVE_R            : std_logic_vector(8 downto 0) := conv_std_logic_vector( 63,9);
  --constant H_VDRIVE_R           : std_logic_vector(8 downto 0) := conv_std_logic_vector( 71,9);
  -- frig to get screen centered, above numbers are measured
  constant H_DRIVE_S            : std_logic_vector(8 downto 0) := conv_std_logic_vector( 60+8,9); -- hdrive pulse
  constant H_DRIVE_R            : std_logic_vector(8 downto 0) := conv_std_logic_vector( 63+8,9);
  constant H_VDRIVE_R           : std_logic_vector(8 downto 0) := conv_std_logic_vector( 71+8,9);

  constant H_LEN                : std_logic_vector(8 downto 0) := conv_std_logic_vector(454,9); -- line length (455 clocks)
  constant V_LEN                : std_logic_vector(10 downto 0) := conv_std_logic_vector(525,11); -- frame length

  component BALLY_COL_PAL
    port (
      ADDR        : in    std_logic_vector(7 downto 0);
      DATA        : out   std_logic_vector(11 downto 0)
      );
  end component;

  --  Signals
  type  array_8x8             is array (0 to 7) of std_logic_vector(7 downto 0);
  type  array_bool8           is array (0 to 7) of boolean;

  signal ena_cnt              : std_logic_vector(1 downto 0) := "00";
  signal cpu_ena              : std_logic;
  signal cpu_ena_t1           : std_logic;
  signal pix_ena              : std_logic;
  signal pix_load             : std_logic;
  signal cs_w                 : std_logic;
  signal cs_r                 : std_logic;
  -- cpu if
  signal col_ld               : array_bool8;
  signal magic_ld             : boolean;
  signal r_col                : array_8x8 := (x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00");
  signal r_hi_res             : std_logic;
  signal r_backgnd_col        : std_logic_vector(1 downto 0) := "00";
  signal r_horiz_pos          : std_logic_vector(5 downto 0) := "010100"; -- 20
  signal r_vert_blank         : std_logic_vector(7 downto 0) := x"10"; -- line 8 (7..1)
  --signal r_vert_blank         : std_logic_vector(7 downto 0) := x"BF"; -- line 191 (7..1)
  signal r_magic              : std_logic_vector(7 downto 0) := x"00";
  signal r_expand             : std_logic_vector(7 downto 0) := x"00";
  signal r_intercept          : std_logic_vector(7 downto 0) := x"00";
  -- timing
  signal do_horiz_dr          : std_logic;
  signal do_horiz_dr_t1       : std_logic;
  signal do_vert_dr           : std_logic;
  signal do_vert_dr_int       : std_logic;
  signal hsync                : std_logic;
  signal vsync                : std_logic := '0';
  signal vsync_t1             : std_logic;
  signal v_1st_actv           : std_logic;

  signal h_count              : std_logic_vector ( 8 downto 0) := (others => '0');
  signal v_count              : std_logic_vector (10 downto 0) := "00000000001";
  signal sg_line_sync         : std_logic;
  signal sg_blank_n1          : std_logic;
  signal sg_blank_n2          : std_logic;
  signal sg_blank_b1          : std_logic;
  signal sg_blank_b2          : std_logic;
  signal sg_hstart            : std_logic;
  signal sg_hstart_t1         : std_logic;
  signal sg_hblank            : std_logic;
  signal sg_hblank_l          : std_logic;
  signal sg_hblank_r          : std_logic;
  signal sg_vblank            : std_logic;
  signal sg_vstart            : std_logic;
  --
  signal sg_blanking_EQ       : std_logic;
  signal sg_blanking_BRD      : std_logic;
  signal sg_line263           : std_logic;
  signal sg_line266           : std_logic;
  signal sg_line269           : std_logic;
  signal sg_line272           : std_logic;
  signal sg_line283           : std_logic;
  signal sg_sync              : std_logic;
  signal sg_blank             : std_logic;
  signal sg_neg_sync          : std_logic;

  --
  signal horiz_pos            : std_logic_vector(7 downto 0);
  signal vert_pos             : std_logic_vector(7 downto 0);
  signal hactv                : std_logic;
  signal vactv                : std_logic;

  -- data
  signal ram_write_reg        : std_logic_vector(7 downto 0);
  signal datwr                : std_logic;
  signal ltchdo_t1            : std_logic;
  signal mxd_out_ena          : std_logic;
  signal mxd_out_intercept    : std_logic;
  signal mxd_out_intercept_e1 : std_logic;
  -- video
  signal video_cyc            : std_logic;
  signal video_cyc_ras        : std_logic;
  signal video_cyc_ras_t1     : std_logic;
  signal video_cyc_ras_t2     : std_logic;
  signal video_shifter        : std_logic_vector(15 downto 0);
  signal video_shifter_lflag  : std_logic;
  signal video_shifter_actv   : std_logic;

  signal lflag                : std_logic; -- left flag
  signal lflag_inhib          : std_logic;
  signal lflag_e              : std_logic_vector(2 downto 0);
  signal hactv_e              : std_logic_vector(2 downto 0);
  signal col_in               : std_logic_vector(7 downto 0);
  signal col_out              : std_logic_vector(11 downto 0);
  -- datapath
  signal done_magic_write     : std_ulogic;
  signal done_magic_write_t1  : std_ulogic;
  signal expand_lower_sel     : std_logic;

  signal expand_out           : std_logic_vector(7 downto 0);
  signal flopper_out          : std_logic_vector(7 downto 0);
  signal pixel_collide        : std_logic_vector(3 downto 0);

  signal shifter_out          : std_logic_vector(13 downto 0);
  signal shifter_out_reg      : std_logic_vector(5 downto 0);

  signal rotate_cnt           : std_logic_vector(2 downto 0);
  signal rotate_inhibit_write : std_logic;
  signal rotate_pixa          : std_logic_vector(7 downto 0) := (others => '0');
  signal rotate_pixb          : std_logic_vector(7 downto 0) := (others => '0');
  signal rotate_pixc          : std_logic_vector(7 downto 0) := (others => '0');
  signal rotate_pixd          : std_logic_vector(7 downto 0) := (others => '0');
  signal rotate_out           : std_logic_vector(7 downto 0);
  signal magic_final          : std_logic_vector(7 downto 0);
  signal ram_ip_reg           : std_logic_vector(7 downto 0);
  signal ram_op_reg           : std_logic_vector(7 downto 0);

begin

  p_chip_sel             : process(cpu_ena, I_MXA)
  begin
    cs_w <= '0';
    cs_r <= '0';
    if (cpu_ena = '1') then -- cpu access
      if (I_MXA(7 downto 5) = "000") then
        cs_w <= '1';
      end if;
    end if;
    if (I_MXA(7 downto 4) = "0000") then
      cs_r <= '1';
    end if;

  end process;

  --
  -- registers
  --
  p_reg_write            : process
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then
      if (I_RD_L = '1') and (I_IORQ_L = '0') and (I_M1_L = '1') and (cs_w = '1') then
        case I_MXA(4 downto 0) is
          when "01000" => r_hi_res              <= I_MXD(0);          -- 8
          when "01001" => r_backgnd_col         <= I_MXD(7 downto 6); -- 9
                          r_horiz_pos           <= I_MXD(5 downto 0);
          when "01010" => r_vert_blank          <= I_MXD;             -- A
          -- B
          when "01100" => r_magic               <= I_MXD; -- C
          when "11001" => r_expand              <= I_MXD; -- 19

          when others => null;
        end case;
      end if;
    end if;
  end process;

  p_reg_write_blk_decode : process(I_RD_L, I_M1_L, I_IORQ_L, cs_w, I_MXA)
  begin
    -- these writes will last for several cpu_ena cycles, so you
    -- will get several load pulses
    col_ld <= (others => false);
    magic_ld <= false;
    if (I_RD_L = '1') and (I_IORQ_L = '0') and (I_M1_L = '1') and (cs_w = '1') and (I_MXA(4) = '0') then
      col_ld(0) <= ( I_MXA( 3 downto 0) = x"0") or
                   ((I_MXA(10 downto 8) = "000") and (I_MXA(3 downto 0) = x"B"));

      col_ld(1) <= ( I_MXA( 3 downto 0) = x"1") or
                   ((I_MXA(10 downto 8) = "001") and (I_MXA(3 downto 0) = x"B"));

      col_ld(2) <= ( I_MXA( 3 downto 0) = x"2") or
                   ((I_MXA(10 downto 8) = "010") and (I_MXA(3 downto 0) = x"B"));

      col_ld(3) <= ( I_MXA( 3 downto 0) = x"3") or
                   ((I_MXA(10 downto 8) = "011") and (I_MXA(3 downto 0) = x"B"));

      col_ld(4) <= ( I_MXA( 3 downto 0) = x"4") or
                   ((I_MXA(10 downto 8) = "100") and (I_MXA(3 downto 0) = x"B"));

      col_ld(5) <= ( I_MXA( 3 downto 0) = x"5") or
                   ((I_MXA(10 downto 8) = "101") and (I_MXA(3 downto 0) = x"B"));

      col_ld(6) <= ( I_MXA( 3 downto 0) = x"6") or
                   ((I_MXA(10 downto 8) = "110") and (I_MXA(3 downto 0) = x"B"));

      col_ld(7) <= ( I_MXA( 3 downto 0) = x"7") or
                   ((I_MXA(10 downto 8) = "111") and (I_MXA(3 downto 0) = x"B"));

      magic_ld  <= ( I_MXA( 3 downto 0) = x"C");
    end if;
  end process;

  p_reg_write_blk        : process
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then
      for i in 0 to 7 loop
        if col_ld(i) then r_col(i) <= I_MXD; end if;
      end loop;
    end if;
  end process;

  p_cpu_ena              : process
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then
      if (do_horiz_dr = '1') then -- 3 clocks long
        ena_cnt <= "00";
      else
        ena_cnt <= ena_cnt + "1";
      end if;

      cpu_ena <= '0';
      if (ena_cnt = "10") then
        cpu_ena <= '1';
      end if;

      if (r_hi_res = '1') then
        pix_ena <= '1';
      else
        pix_ena <= ena_cnt(0);
      end if;
      pix_load <= cpu_ena;
    end if;
  end process;
  O_CPU_ENA <= cpu_ena;
  O_PIX_ENA <= pix_ena;

  p_micro_gen            : process
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then
    -- not used
      O_MC1 <= '0';
      O_MC0 <= '0';
    end if;
  end process;
  --
  -- sync generation
  --
  p_hv_count             : process
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then
      if (h_count = H_LEN) then
        h_count <= (others => '0');
        if (v_count = V_LEN) then
          v_count <= "00000000001";
        else
          v_count <= v_count + "1";
        end if;
      else
        h_count <= h_count + "1";
      end if;
    end if;
  end process;

  p_window_h             : process
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then
      -- hblank
      sg_hstart <= '0';
      if (h_count = H_BLANK_S) then
        sg_hblank <= '1';
      elsif h_count = H_BLANK_R then
        sg_hstart <= '1';
        sg_hblank <= '0';
      end if;

      if (h_count = H_BLANK_S) then
        sg_hblank_l <= '1';
      elsif h_count = H_BLANK_LR then
        sg_hblank_l <= '0';
      end if;

      if (h_count = H_BLANK_RS) then
        sg_hblank_r <= '1';
      elsif h_count = H_BLANK_R then
        sg_hblank_r <= '0';
      end if;

      if (h_count = H_DRIVE_S) then
        do_horiz_dr <= '1';
      elsif h_count = H_DRIVE_R then
        do_horiz_dr <= '0';
      end if;

      if (h_count = H_DRIVE_S) then
        do_vert_dr <= '1';
      elsif h_count = H_VDRIVE_R then
        do_vert_dr <= '0';
      end if;

      -- low res 40 bytes / line (160 pixels, 2 bits per pixel)
      -- vert res 102 lines
      -- two clocks / pixel
    end if;
  end process;

  p_sync_h               : process
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then
      -- negative sync pulse
      if (h_count = H_LINE_SYNCS) then
        sg_line_sync <= '1';
      elsif h_count = H_LINE_SYNCR then
        sg_line_sync <= '0';
      end if;

      -- blanking narrow1
      if (h_count = H_BLANK_N1S) then
        sg_blank_n1 <= '1';
      elsif h_count = H_BLANK_N1R then
        sg_blank_n1 <= '0';
      end if;

      -- blanking narrow2
      if (h_count = H_BLANK_N2S) then
        sg_blank_n2 <= '1';
      elsif (h_count = H_BLANK_N2R) then
        sg_blank_n2 <= '0';
      end if;

      -- blanking broad1
      if (h_count = H_BLANK_B1S) then
        sg_blank_b1 <= '1';
      elsif (h_count = H_BLANK_B1R) then
        sg_blank_b1 <= '0';
      end if;

      -- blanking broad2
      if h_count = H_BLANK_B2S then
        sg_blank_b2 <= '1';
      elsif (h_count = H_BLANK_B2R) then
        sg_blank_b2 <= '0';
      end if;
    end if;
  end process;

  p_window_v             : process
  begin
    wait until rising_edge(CLK);
    -- line  21 first f1 nonblanked video line ** bally chip starts at 20 with a half line
    -- line  44 first f1 video line
    -- line 234 last f1 video line (power up menu)
    -- line 263 last f1 nonblanked video line (half line)

    -- line 283 first f2 nonblanked video line (half line)
    -- line 307 first f2 video line (power up menu)
    -- line 497 last f2 video line
    -- line 525 last f2 nonblanked video line

    -- (vblank reg is written as 191 for boot menu)
    -- there are 191 active video lines read from the video store per field (when displaying menu)
    -- The bally data chip seems to get the half lines wrong however (283 whole line)
    -- and it puts a half line on 20. Or, I've missread the field sync pulses.
    -- doesn't really matter as we are driving a vga screen for now ..

    -- 14.2857MHz (7.1428)
    -- line / 455 = 15.698 K = 29.9 frames
    if (ENA = '1') then

      sg_vstart <= '0';
      if    (v_count = conv_std_logic_vector(  21,11)) then
        sg_vblank <= '0';
        sg_vstart <= '1'; -- field one sync to scan converter
      elsif (v_count = conv_std_logic_vector( 264,11)) then
        sg_vblank <= '1';
      elsif (v_count = conv_std_logic_vector( 283,11)) then
        sg_vblank <= '0';
      elsif (v_count = conv_std_logic_vector(   1,11)) then
        sg_vblank <= '1';
      end if;

      if    (v_count = conv_std_logic_vector(   4,11)) then
        vsync <= '1';
      elsif (v_count = conv_std_logic_vector(   7,11)) then
        vsync <= '0';
      elsif (v_count = conv_std_logic_vector( 267,11)) then
        vsync <= '1';
      elsif (v_count = conv_std_logic_vector( 270,11)) then
        vsync <= '0';
      end if;

      v_1st_actv <= '0';
      if (v_count = conv_std_logic_vector(  44,11)) or
         (v_count = conv_std_logic_vector( 307,11)) then
        v_1st_actv <= '1';
      end if;
      -- timing from rising edge of v_sync
      -- 4    21   263
      -- 1    18   260

      -- 267  283  525
      -- 1    17   259

      -- so field 2 is displayed above field 1 - this is the same as ntsc and seems
      -- to be necessary to get a correct picture on my monitor taking it's sync from vsync
    end if;
  end process;

  p_sync_v               : process
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then
      sg_blanking_eq <= '0';
      if ( (v_count = conv_std_logic_vector(  1,11)) or
           (v_count = conv_std_logic_vector(  2,11)) or
           (v_count = conv_std_logic_vector(  3,11)) or
           (v_count = conv_std_logic_vector(  7,11)) or
           (v_count = conv_std_logic_vector(  8,11)) or
           (v_count = conv_std_logic_vector(  9,11)) or
           (v_count = conv_std_logic_vector(264,11)) or
           (v_count = conv_std_logic_vector(265,11)) or
           (v_count = conv_std_logic_vector(270,11)) or
           (v_count = conv_std_logic_vector(271,11)) ) then
        sg_blanking_eq <= '1';
      end if;

      sg_blanking_brd <= '0';
      if ( (v_count = conv_std_logic_vector(  4,11)) or
           (v_count = conv_std_logic_vector(  5,11)) or
           (v_count = conv_std_logic_vector(  6,11)) or
           (v_count = conv_std_logic_vector(267,11)) or
           (v_count = conv_std_logic_vector(268,11)) ) then
         sg_blanking_brd <= '1';
      end if;

      sg_line263 <= '0';
      if (v_count = (conv_std_logic_vector(263,11))) then
        sg_line263 <= '1';
      end if;

      sg_line266 <= '0';
      if (v_count = (conv_std_logic_vector(266,11))) then
        sg_line266 <= '1';
      end if;

      sg_line269 <= '0';
      if (v_count = (conv_std_logic_vector(269,11))) then
        sg_line269 <= '1';
      end if;

      sg_line272 <= '0';
      if (v_count = (conv_std_logic_vector(272,11))) then
        sg_line272 <= '1';
      end if;

      sg_line283 <= '0';
      if (v_count = (conv_std_logic_vector(283,11))) then
        sg_line283 <= '1';
      end if;
    end if;
  end process;

  p_syncgen              : process
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then
      sg_sync <= '0';

      if (sg_blanking_eq = '1') then
        sg_sync <= sg_blank_n1 or sg_blank_n2;

      elsif (sg_blanking_brd = '1') then
        sg_sync <= sg_blank_b1 or sg_blank_b2;

      elsif (sg_line263 = '1') then
        sg_sync <= sg_blank_n2 or sg_line_sync;

      elsif (sg_line266 = '1') then
        sg_sync <= sg_blank_n1 or sg_blank_b2;

      elsif (sg_line269 = '1') then
        sg_sync <= sg_blank_b1 or sg_blank_n2;

      elsif (sg_line272 = '1') then
        sg_sync <= sg_blank_n1;

      else
        sg_sync <= sg_line_sync; -- normal line.
      end if;

      sg_blank <= sg_hblank or sg_vblank;
      if (sg_line263 = '1') then
        sg_blank <= sg_hblank_r; -- left half line
      elsif (sg_line283 = '1') then
        sg_blank <= sg_hblank_l; -- right half line
      end if;

      hsync <= sg_line_sync;
      vsync_t1 <= vsync;
    end if;
  end process;

  -- code duplicated in addr chip
  p_active_picture       : process
    variable vcomp : std_logic_vector(7 downto 0);
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then
      if (do_horiz_dr = '1') then
        horiz_pos <= (others => '0');
      elsif (cpu_ena = '1') then -- clk phi
        horiz_pos <= horiz_pos + "1";
      end if;

      do_horiz_dr_t1 <= do_horiz_dr;
      if (do_vert_dr_int = '1') then
        vert_pos <= (others => '0');
      elsif (do_horiz_dr = '1') and (do_horiz_dr_t1 = '0') then -- rising edge
        if (vert_pos = x"ff") then
          null;
        else
          vert_pos <= vert_pos + "1";
        end if;
      end if;

      -- bit of guesswork here
      if (cpu_ena = '1') then
        if (horiz_pos = x"01") then
          hactv <= '1';
        elsif (horiz_pos = x"51") then
          hactv <= '0';
        end if;
      end if;
      vcomp := r_vert_blank(7 downto 0);
      -- DATA chip does line pairs only in low res mode
      if (r_hi_res = '0') then
        vcomp(0) := '0';
      end if;

      vactv <= '0';
      if (vert_pos < vcomp) then
        vactv <= '1';
      end if;
    end if;
  end process;

  p_video_cyc            : process
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then
      if (cpu_ena = '1') then
        video_cyc <= '0';
        if (hactv = '1') and (vactv = '1') and (horiz_pos(0) = '0') then
          video_cyc <= '1';
        end if;
        video_cyc_ras <= video_cyc;
      end if;
      video_cyc_ras_t1 <= video_cyc_ras;
      video_cyc_ras_t2 <= video_cyc_ras_t1; -- match delay to rams
    end if;
  end process;

  p_left_flag            : process
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then
      -- apparently horiz_pos 40 or above do not have any effect
      if (do_horiz_dr = '1') then
        lflag_inhib <= '0';
      elsif (cpu_ena = '1') and (horiz_pos(6 downto 0) = ("1001111")) then
        lflag_inhib <= '1';
      end if;

      if (do_horiz_dr = '1') then
        lflag <= '1';
      elsif (cpu_ena = '1') and (horiz_pos(6 downto 0) = (r_horiz_pos & '1')) and (lflag_inhib = '0') then
        lflag <= '0';
      end if;

      -- pipeline delay
      if (do_horiz_dr = '1') then
        lflag_e <= "111";
        hactv_e <= "000";

      elsif (cpu_ena = '1') then
        lflag_e(0) <= lflag;
        lflag_e(2 downto 1) <= lflag_e(1 downto 0);
        hactv_e(0) <= hactv;
        hactv_e(2 downto 1) <= hactv_e(1 downto 0);
      end if;
    end if;
  end process;

  p_video_shifter        : process
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then
      -- video cyc, grab from ram
      if (pix_ena = '1') then
        if (pix_load = '1') and (video_cyc_ras_t2 = '1') then
          video_shifter <= I_MD(7 downto 0) & I_MDX(7 downto 0);
        else
         -- top left pixel is bits 7,6
          video_shifter <= video_shifter(13 downto 0) & "00";
        end if;

      end if;

      if (do_horiz_dr = '1') then
        video_shifter_lflag <= '1';
        video_shifter_actv <= '0'; -- background col
      elsif (pix_ena = '1') and (pix_load = '1') then
        video_shifter_lflag <= lflag_e(2);
        video_shifter_actv <= hactv_e(2) and vactv;
      end if;
    end if;
  end process;

  p_col_sel              : process(video_shifter, video_shifter_lflag, video_shifter_actv,
                                   r_col, r_backgnd_col)
    variable sel : std_logic_vector(2 downto 0);
  begin
    if (video_shifter_actv = '0') then
      sel := video_shifter_lflag & r_backgnd_col;
    else
      sel := video_shifter_lflag & video_shifter(7+8 downto 6+8);
    end if;

    col_in <= (others => '0');
    case sel is
      when "000" => col_in <= r_col(0);
      when "001" => col_in <= r_col(1);
      when "010" => col_in <= r_col(2);
      when "011" => col_in <= r_col(3);
      when "100" => col_in <= r_col(4);
      when "101" => col_in <= r_col(5);
      when "110" => col_in <= r_col(6);
      when "111" => col_in <= r_col(7);
      when others => null;
    end case;
  end process;

  u_col                  : entity work.BALLY_COL_PAL
    port map (
      ADDR        => col_in,
      DATA        => col_out
      );

  p_video_out            : process
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then
      sg_neg_sync <= not sg_sync;
      O_HSYNC <= hsync;
      O_VSYNC <= vsync_t1;

      if (sg_blank = '1') then
        O_VIDEO_R <= "0000";
        O_VIDEO_G <= "0000";
        O_VIDEO_B <= "0000";
      else
        O_VIDEO_R <= col_out(11 downto 8);
        O_VIDEO_G <= col_out( 7 downto 4);
        O_VIDEO_B <= col_out( 3 downto 0);
      end if;
      do_vert_dr_int <= v_1st_actv and do_vert_dr;
      sg_hstart_t1 <= sg_hstart;
      O_FPSYNC <= sg_hstart_t1 and sg_vstart;
    end if;
  end process;
  O_VERT_DR  <= do_vert_dr_int;
  O_HORIZ_DR <= do_horiz_dr;
  --
  -- data path
  --
  p_ramin                : process
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then
      ram_write_reg <= I_MXD;

      done_magic_write <= '0';
      if (I_WRCTL_L = '0') and (I_MXA(15 downto 14) = "00") and (cpu_ena = '1') then
        done_magic_write <= '1';
      end if;
      done_magic_write_t1 <= done_magic_write; -- make sure we have finished ram write
    end if;
  end process;

  p_expand               : process(ram_write_reg, r_magic, r_expand, expand_lower_sel)
    variable expand_sel : std_logic_vector(3 downto 0);
  begin
    if (expand_lower_sel = '1') then -- reg cleared by magic, upper when 0
      expand_sel := ram_write_reg(3 downto 0);
    else
      expand_sel := ram_write_reg(7 downto 4);
    end if;

    if (r_magic(3) = '0') then -- bypass
      expand_out <= ram_write_reg;
    else
      for i in 0 to 3 loop
        if (expand_sel(i) = '0') then
          expand_out((i*2)+1 downto i*2) <= r_expand(1 downto 0);
        else
          expand_out((i*2)+1 downto i*2) <= r_expand(3 downto 2);
        end if;
      end loop;
    end if;
  end process;

  p_rotate_reg           : process
    variable shift : std_logic;
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then
      if magic_ld then
        rotate_cnt <= "000";
        expand_lower_sel <= '0';
        shifter_out_reg <= (others => '0');
      elsif (done_magic_write_t1 = '1') then
        rotate_cnt <= rotate_cnt + "1";
        expand_lower_sel <= not expand_lower_sel;
        shifter_out_reg <= shifter_out(5 downto 0);
      end if;

      rotate_inhibit_write <= '0';
      shift := '0';
      if (I_MXA(15 downto 14) = "00") then
        if (rotate_cnt(2) = '0') then
          rotate_inhibit_write <= r_magic(2); -- only if using rotate
          if (cpu_ena = '1') and (I_WRCTL_L = '0') then
            shift := '1';
          end if;
        end if;
      end if;

      if (shift = '1') then
        rotate_pixa <= expand_out(7 downto 6) & rotate_pixa(7 downto 2); -- top
        rotate_pixb <= expand_out(5 downto 4) & rotate_pixb(7 downto 2);
        rotate_pixc <= expand_out(3 downto 2) & rotate_pixc(7 downto 2);
        rotate_pixd <= expand_out(1 downto 0) & rotate_pixd(7 downto 2);
      end if;
    end if;
  end process;

  p_rotate_shifter       : process(expand_out, shifter_out_reg, r_magic,
                                   rotate_cnt, rotate_pixa, rotate_pixb, rotate_pixc, rotate_pixd)
  begin
    -- r_magic bits 1,0
    shifter_out <= (others => '0'); -- default
    case r_magic(1 downto 0) is
      when "00" => shifter_out <=                               expand_out(7 downto 0) & "000000";
      when "01" => shifter_out <= shifter_out_reg(5 downto 4) & expand_out(7 downto 0) & "0000" ;
      when "10" => shifter_out <= shifter_out_reg(5 downto 2) & expand_out(7 downto 0) & "00" ;
      when "11" => shifter_out <= shifter_out_reg(5 downto 0) & expand_out(7 downto 0);
      when others => null;
    end case;

    rotate_out <= (others => '0'); -- default
    case rotate_cnt(1 downto 0) is
      when "00" => rotate_out <= rotate_pixa;
      when "01" => rotate_out <= rotate_pixb;
      when "10" => rotate_out <= rotate_pixc;
      when "11" => rotate_out <= rotate_pixd;
      when others => null;
    end case;
  end process;

  p_flopper              : process(shifter_out, rotate_out, r_magic)
   variable flopper_src : std_logic_vector(7 downto 0);
  begin
    if (r_magic(2) = '0') then  -- rotate bypass
      flopper_src := shifter_out(13 downto 6);
    else
      flopper_src := rotate_out;
    end if;

    if (r_magic(6) = '0') then  -- flopper bypass
      flopper_out <= flopper_src;
    else
      flopper_out(7 downto 6) <= flopper_src(1 downto 0);
      flopper_out(5 downto 4) <= flopper_src(3 downto 2);
      flopper_out(3 downto 2) <= flopper_src(5 downto 4);
      flopper_out(1 downto 0) <= flopper_src(7 downto 6);
    end if;
  end process;

  p_or_xor               : process(flopper_out, ram_ip_reg, r_magic)
    variable result_or : std_logic_vector(7 downto 0);
    variable result_xor : std_logic_vector(7 downto 0);
  begin
    result_or := flopper_out or ram_ip_reg;
    result_xor := flopper_out xor ram_ip_reg;

    magic_final <= (others => '0');
    case r_magic(5 downto 4) is
      when "00" => magic_final <= flopper_out; -- none
      when "01" => magic_final <= result_or;   -- or
      when "10" => magic_final <= result_xor;  -- xor
      when "11" => magic_final <= result_xor;  -- xor and or
      when others => null;
    end case;
  end process;

  p_intercept            : process(flopper_out, ram_ip_reg)
  begin
    pixel_collide <= (others => '0');
    for i in 0 to 3 loop
      if (flopper_out((i*2)+1 downto (i*2)) /= "00") and
          (ram_ip_reg((i*2)+1 downto (i*2)) /= "00") then
        pixel_collide(i) <= '1';
      end if;
    end loop;

  end process;

  p_intercept_reg        : process
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then
      if (cpu_ena = '1') then
        mxd_out_intercept_e1 <= mxd_out_intercept;
      end if;

      -- reset
      if (mxd_out_intercept = '0') and (mxd_out_intercept_e1 = '1') and (cpu_ena = '1') then -- end of read
          r_intercept(3 downto 0) <= "0000";
      elsif (datwr = '1') and (I_MXA(15 downto 14) = "00") and (rotate_inhibit_write = '0') then
      -- write
        if (r_magic(5) = '1') or (r_magic(4) = '1') then -- or/xor write only
          r_intercept(0) <= r_intercept(0) or pixel_collide(3);
          r_intercept(1) <= r_intercept(1) or pixel_collide(2);
          r_intercept(2) <= r_intercept(2) or pixel_collide(1);
          r_intercept(3) <= r_intercept(3) or pixel_collide(0);

          r_intercept(4) <= pixel_collide(3);
          r_intercept(5) <= pixel_collide(2);
          r_intercept(6) <= pixel_collide(1);
          r_intercept(7) <= pixel_collide(0);
        end if;
      end if;
    end if;
  end process;

  p_output_reg           : process
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then
      if (cpu_ena = '1') then
        ltchdo_t1 <= I_LTCHDO;
        ram_ip_reg <= I_MD(7 downto 0); -- used for or / xor
      end if;

      if (I_MXA(15 downto 14) = "00") then -- magic write
        ram_op_reg <= magic_final;
      else
        ram_op_reg <= ram_write_reg;
      end if;

      cpu_ena_t1 <= cpu_ena;
      datwr <= cpu_ena_t1 and (not I_WRCTL_L);
    end if;
  end process;
  O_DATWR <= datwr;
  -- ram out

  p_ramout               : process(I_WRCTL_L, ram_op_reg, rotate_inhibit_write)
  begin
    O_MD_OE_L <= '1';
    O_DATEN_L <= '1';
    O_MD <= (others => 'X'); -- debug
    if (I_WRCTL_L = '0') and (rotate_inhibit_write = '0') then
      O_MD <= ram_op_reg;
      O_MD_OE_L <= '0';
      O_DATEN_L <= '0';
    end if;
  end process;

  p_mxd_out_ena          : process(I_LTCHDO, ltchdo_t1, I_RD_L, I_IORQ_L, cs_r, I_MXA)
  begin

    mxd_out_ena <= '0';
    mxd_out_intercept <= '0';

    if (I_LTCHDO = '1') or (ltchdo_t1 = '1') then
      mxd_out_ena <= '1';
    else
      if (I_RD_L = '0') and (I_IORQ_L = '0') and (cs_r = '1') then
        if (I_MXA(3 downto 0) = x"8") then -- intercept
          mxd_out_ena <= '1';
          mxd_out_intercept <= '1';
        end if;
      end if;
    end if;
  end process;

  p_mxout                : process(mxd_out_ena, mxd_out_intercept, I_MD, r_intercept)
  begin
    O_MXD <= (others => 'X');
    O_MXD_OE_L <= '1';
    if (mxd_out_ena = '1') then
      O_MXD_OE_L <= '0';
      if (mxd_out_intercept = '1') then
        O_MXD <= r_intercept;
      else
        O_MXD <= I_MD(7 downto 0);
      end if;
    end if;
  end process;

end architecture RTL;

