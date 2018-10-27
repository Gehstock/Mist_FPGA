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

entity BALLY_IO is
  port (
    I_MXA             : in    std_logic_vector(15 downto  0);
    I_MXD             : in    std_logic_vector( 7 downto  0);
    O_MXD             : out   std_logic_vector( 7 downto  0);
    O_MXD_OE_L        : out   std_logic;

    -- cpu control signals
    I_M1_L            : in    std_logic; -- not on real chip
    I_RD_L            : in    std_logic;
    I_IORQ_L          : in    std_logic;
    I_RESET_L         : in    std_logic;

--    I_HANDLE1         : in    std_logic_vector( 8 downto  0);
--	 I_HANDLE2         : in    std_logic_vector( 8 downto  0);
--	 I_HANDLE3         : in    std_logic_vector( 8 downto  0);
--	 I_HANDLE4         : in    std_logic_vector( 8 downto  0);

    -- switches
    O_SWITCH          : out   std_logic_vector( 7 downto 0);
    I_SWITCH          : in    std_logic_vector( 7 downto 0);
    -- audio
    O_AUDIO           : out   std_logic_vector( 7 downto 0);
    -- clks
    I_CPU_ENA         : in    std_logic;
    ENA               : in    std_logic;
    CLK               : in    std_logic
    );
end;

architecture RTL of BALLY_IO is
  --  Signals
  type  array_8x8             is array (0 to 7) of std_logic_vector(7 downto 0);
  type  array_4x8             is array (0 to 3) of std_logic_vector(7 downto 0);
  type  array_3x8             is array (0 to 2) of std_logic_vector(7 downto 0);
  type  array_4x4             is array (0 to 3) of std_logic_vector(3 downto 0);

  type  array_bool8           is array (0 to 7) of boolean;

  signal cs                   : std_logic;
  signal snd_ld               : array_bool8;
  signal r_snd                : array_8x8 := (x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00");
  signal r_pot                : array_4x8 := (x"00",x"00",x"00",x"00");
  signal mxd_out_reg          : std_logic_vector(7 downto 0);

  signal io_read              : std_logic;
  signal switch_read          : std_logic;
  -- audio
  signal master_ena           : std_logic;
  signal master_cnt           : std_logic_vector(7 downto 0);
  signal master_freq          : std_logic_vector(7 downto 0);

  signal vibrato_cnt          : std_logic_vector(18 downto 0);
  signal vibrato_ena          : std_logic;

  signal poly17               : std_logic_vector(16 downto 0);
  signal noise_gen            : std_logic_vector(7 downto 0);

  signal tone_gen             : array_3x8 := (others => (others => '0'));
  signal tone_gen_op          : std_logic_vector(2 downto 0);
begin

  p_chip_sel             : process(I_CPU_ENA, I_MXA)
  begin
    cs <= '0';
    if (I_CPU_ENA = '1') then -- cpu access
      if (I_MXA(7 downto 4) = "0001") then
        cs <= '1';
      end if;
    end if;
  end process;
  --
  -- registers
  --
  p_reg_write_blk_decode : process(I_CPU_ENA, I_RD_L, I_M1_L, I_IORQ_L, cs, I_MXA) -- no m1 gating on real chip ?
  begin
    -- these writes will last for several cpu_ena cycles, so you
    -- will get several load pulses
    snd_ld <= (others => false);
    if (I_CPU_ENA = '1') then
      if (I_RD_L = '1') and (I_IORQ_L = '0') and (I_M1_L = '1') and (cs = '1') then
        snd_ld(0) <= ( I_MXA( 3 downto 0) = x"0") or
                     ((I_MXA(10 downto 8) = "000") and (I_MXA(3 downto 0) = x"8"));

        snd_ld(1) <= ( I_MXA( 3 downto 0) = x"1") or
                     ((I_MXA(10 downto 8) = "001") and (I_MXA(3 downto 0) = x"8"));

        snd_ld(2) <= ( I_MXA( 3 downto 0) = x"2") or
                     ((I_MXA(10 downto 8) = "010") and (I_MXA(3 downto 0) = x"8"));

        snd_ld(3) <= ( I_MXA( 3 downto 0) = x"3") or
                     ((I_MXA(10 downto 8) = "011") and (I_MXA(3 downto 0) = x"8"));

        snd_ld(4) <= ( I_MXA( 3 downto 0) = x"4") or
                     ((I_MXA(10 downto 8) = "100") and (I_MXA(3 downto 0) = x"8"));

        snd_ld(5) <= ( I_MXA( 3 downto 0) = x"5") or
                     ((I_MXA(10 downto 8) = "101") and (I_MXA(3 downto 0) = x"8"));

        snd_ld(6) <= ( I_MXA( 3 downto 0) = x"6") or
                     ((I_MXA(10 downto 8) = "110") and (I_MXA(3 downto 0) = x"8"));

        snd_ld(7) <= ( I_MXA( 3 downto 0) = x"7") or
                     ((I_MXA(10 downto 8) = "111") and (I_MXA(3 downto 0) = x"8"));

      end if;
    end if;
  end process;

  p_reg_write_blk        : process
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then
      if (I_RESET_L = '0') then -- don't know if reset does reset the sound
        r_snd <= (others => (others => '0'));
      else
        for i in 0 to 7 loop
          if snd_ld(i) then r_snd(i) <= I_MXD; end if;
        end loop;
      end if;
    end if;
  end process;

  p_reg_read             : process
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then
      if (I_MXA(3) = '0') then
        mxd_out_reg <= I_SWITCH(7 downto 0);
      else
        mxd_out_reg <= x"00";
        case I_MXA(2 downto 0) is
          when "100" => mxd_out_reg <= r_pot(0); --x1C
          when "101" => mxd_out_reg <= r_pot(1); --x1D
          when "110" => mxd_out_reg <= r_pot(2); --x1E
          when "111" => mxd_out_reg <= r_pot(3); --x1F
          when others => null;
        end case;
      end if;
    end if;
  end process;

  p_decode_read          : process(I_MXA, I_IORQ_L, I_RD_L)
  begin
    -- we will return 0 for x18-1b
    io_read <= '0';
    switch_read <= '0';
    if (I_MXA(7 downto 4) = "0001") then
      if (I_IORQ_L = '0') and (I_RD_L = '0') then
        io_read <= '1';
        if (I_MXA(3) = '0') then
          switch_read <= '1';
        end if;
      end if;
    end if;
  end process;

  p_switch_out           : process
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then
      O_SWITCH <= x"00";
      if (switch_read = '1') then
        case I_MXA(2 downto 0) is
          when "000" => O_SWITCH <= "00000001";
          when "001" => O_SWITCH <= "00000010";
          when "010" => O_SWITCH <= "00000100";
          when "011" => O_SWITCH <= "00001000";
          when "100" => O_SWITCH <= "00010000";
          when "101" => O_SWITCH <= "00100000";
          when "110" => O_SWITCH <= "01000000";
          when "111" => O_SWITCH <= "10000000";
          when others => null;
        end case;
      end if;
    end if;
  end process;

  p_mxd_oe               : process(mxd_out_reg, io_read)
  begin
    O_MXD <= x"00";
    O_MXD_OE_L <= '1';
    if (io_read = '1') then
      O_MXD <= mxd_out_reg;
      O_MXD_OE_L <= '0';
    end if;
  end process;
  --

  p_pots                 : process
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then
      -- return FF when not plugged in
      r_pot(0) <= x"FF";
      r_pot(1) <= x"FF";
      r_pot(2) <= x"FF";
      r_pot(3) <= x"FF";
    end if;
  end process;
  -- read switches 10-17, pots 1c - 1f
  -- port 7  6  5  4  3  2  1  0
  -- x10           tg rt lt dn up | player 1
  -- x11           tg rt lt dn up | player 2
  -- x12           tg rt lt dn up | player 3
  -- x13           tg rt lt dn up | player 4
  -- x14        =  +  -  x  /  %  | keypad (right most col, bit 0 top)
  -- x15        .  3  6  9  ch v  | keypad
  -- x16        0  2  5  8  ms ^  | keypad
  -- x17        ce 1  4  7  mr c  | keypad (left most col)

  -- write
  -- x10 master osc
  -- x11 tone a freq
  -- x12 tone b freq
  -- x13 tone c freq
  -- x14 vibrato (7..2 value, 1..0 freq)
  -- x15 noise control, tone c volume
  --       bit 5 high to enable noise into mix
  --       bit 4 high for noise mod, low for vibrato
  --       bit 3..0 tone c vol
  -- x16 tone b volume, tone a volume (7..4 b vol, 3..0 a vol)
  -- x17 noise volume (vol 7..4), 7..0 for master osc modulation

  p_noise_gen            : process
    variable poly17_zero : std_logic;
  begin
    -- most probably not correct polynomial
    wait until rising_edge(CLK);
    if (ENA = '1') then
      if (I_CPU_ENA = '1') then
        poly17_zero := '0';
        if (poly17 = "00000000000000000") then poly17_zero := '1'; end if;
        poly17 <= poly17(15 downto 0) & (poly17(16) xor poly17(2) xor poly17_zero);
      end if;
    end if;
  end process;
  noise_gen <= poly17(7 downto 0);

  p_vibrato_osc          : process
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then
      -- cpu clock period 0.558730s us

      -- 00 toggle output every  18.5 mS bet its 32768 clocks
      -- 01 toggle output every  37   mS
      -- 10 toggle output every  74   mS
      -- 11 toggle output every 148   mS

      -- bit 15 every 32768 clocks
      if (I_CPU_ENA = '1') then
        vibrato_cnt <= vibrato_cnt + "1";
        vibrato_ena <= '0';
        case r_snd(4)(1 downto 0) is
          when "00" => vibrato_ena <= vibrato_cnt(15);
          when "01" => vibrato_ena <= vibrato_cnt(16);
          when "10" => vibrato_ena <= vibrato_cnt(17);
          when "11" => vibrato_ena <= vibrato_cnt(18);
          when others => null;
        end case;
      end if;
    end if;
  end process;

  p_master_freq          : process(vibrato_ena, r_snd, noise_gen)
    variable mux : std_logic_vector(7 downto 0);
  begin
    mux := (others => '0'); -- default
    if (r_snd(5)(4) = '1') then -- use noise
      mux := noise_gen and r_snd(7);
    else
      if (vibrato_ena = '1') then
        mux := r_snd(4)(7 downto 2) & "00";
      else
        mux := (others => '0');
      end if;
    end if;
    -- add modulation to master osc freq
    master_freq <= r_snd(0) + mux;
    -- Arcadian mag claims that the counter is preset to the modulation value
    -- when the counter hits the master osc reg value.
    -- The patent / system descriptions describes an adder ....
  end process;

  p_master_osc           : process
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then
      if (I_CPU_ENA = '1') then -- 1.789 Mhz base clock
        master_ena <= '0';
        if (master_cnt = "00000000") then
          master_cnt <= master_freq;
          master_ena <= '1';
        else
          master_cnt <= master_cnt - "1";
        end if;
      end if;
    end if;
  end process;

  p_tone_gen             : process
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then
      if (I_CPU_ENA = '1') then -- 1.789 Mhz base clock

        for i in 0 to 2 loop
          if (master_ena = '1') then
            if (tone_gen(i) = "00000000") then
              tone_gen(i) <= r_snd(i + 1); -- load
              tone_gen_op(i) <= not tone_gen_op(i);
            else
              tone_gen(i) <= tone_gen(i) - '1';
            end if;
          end if;
        end loop;
      end if;
    end if;
  end process;

  p_op_mixer             : process
    variable vol : array_4x4;
    variable sum01 : std_logic_vector(4 downto 0);
    variable sum23 : std_logic_vector(4 downto 0);
    variable sum : std_logic_vector(5 downto 0);
  begin
    wait until rising_edge(CLK);
    if (ENA = '1') then
      if (I_CPU_ENA = '1') then
        vol(0) := "0000";
        vol(1) := "0000";
        vol(2) := "0000";
        vol(3) := "0000";

        if (tone_gen_op(0) = '1') then vol(0) := r_snd(6)(3 downto 0); end if; -- A
        if (tone_gen_op(1) = '1') then vol(1) := r_snd(6)(7 downto 4); end if; -- B
        if (tone_gen_op(2) = '1') then vol(2) := r_snd(5)(3 downto 0); end if; -- C
        if (r_snd(5)(5) = '1') then -- noise enable
          if (noise_gen(0) = '1') then vol(3) := r_snd(5)(7 downto 4); end if; -- noise
        end if;

        sum01 := ('0' & vol(0)) + ('0' & vol(1));
        sum23 := ('0' & vol(2)) + ('0' & vol(3));
        sum := ('0' & sum01) + ('0' & sum23);

        if (I_RESET_L = '0') then
          O_AUDIO <= "00000000";
        else
          O_AUDIO <= (sum & "00");
        end if;
      end if;
    end if;
  end process;

end architecture RTL;

