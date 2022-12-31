--
-- Namco 07xx custom implementation
-- Copyright (c) MikeJ - http://www.fpgaarcade.com
--
-- Adopted by W. Scherr in 2013 to separate function and CPLD mapping.
--
-- All rights reserved
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
-- $Id$
--

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;

  use work.C07_SYNCGEN_PACK.all;

entity C07_SYNCGEN is
  generic (
    g_use_clk_en : boolean
  );
  port (
    clk        : in  std_logic;
    -- used when g_use_clken = true
    clken      : in  r_c07_syncgen_clken;
    --
    hcount_o   : out std_logic_vector(8 downto 0);
    hblank_l   : out std_logic;
    hsync_l    : out std_logic;
    hreset_l_i : in  std_logic;
    vreset_l_i : in  std_logic;
    hreset_l_o : out std_logic;
    vreset_l_o : out std_logic;
    vsync_l    : out std_logic;
    vblank_l   : out std_logic;
    vcount_o   : out std_logic_vector(7 downto 0);
    clken_posegde_o : out r_c07_syncgen_clken_out;
    clken_negegde_o : out r_c07_syncgen_clken_out
  );
end;

architecture RTL of C07_SYNCGEN is

  signal clk_rise,
         clk_fall       : boolean;
  --
  signal hreset_l_reg   : std_logic := '1'; -- power up high
  signal hreset_l_regd  : std_logic := '1'; -- power up high
  --
  signal hcount,
         hcount_s       : std_logic_vector(8 downto 0) := (others => '0');
  signal hcount_zero,
         hcount_zero_s  : std_logic;
  --
  signal vreset_l_reg   : std_logic := '1'; -- power up high
  signal vreset_l_regd  : std_logic := '1'; -- power up high
  --
  signal vcount_ena     : std_logic;
  signal vcount,
         vcount_s       : std_logic_vector(8 downto 0) := (others => '0');
  signal vcount_zero,
         vcount_zero_s  : std_logic;

  signal vblank_l_reg,
         vblank_l_s     : std_logic;

begin

  clk_rise <= clken.clk_rise = '1' when g_use_clk_en else true;
  clk_fall <= clken.clk_fall = '1';

  p_hreset_reg : process(clk, clk_fall)
  begin
    if (    g_use_clk_en and (rising_edge(clk) and clk_fall)) or
       (not g_use_clk_en and  falling_edge(clk)) then
      hreset_l_reg  <= hreset_l_i;
      hreset_l_regd <= hreset_l_reg;
    end if;
  end process;

  -- combinatorial logic separated from p_hcount process to generate the
  -- rising and falling clock enable outputs
  p_hcount_comb : process (hcount, hreset_l_reg, hreset_l_regd)
  begin
    if (hreset_l_reg = '0') and (hreset_l_regd = '1') then
      hcount_zero_s <= '0';
      hcount_s <= "000000001";
    elsif (hcount = "101111111") then -- x17f
      hcount_zero_s <= '1';
      hcount_s <= (others => '0');
    else
      hcount_zero_s <= '0';
      hcount_s <= hcount + "1";
    end if;
  end process;
  clken_posegde_o.hcount <= (hcount_s and (not hcount)) when clk_rise else (others => '0');
  clken_negegde_o.hcount <= ((not hcount_s) and hcount) when clk_rise else (others => '0');

  p_hcount : process
  begin
    wait until rising_edge(clk);
    if clk_rise then
      hcount_zero <= hcount_zero_s;
      hcount      <= hcount_s;
      if (hreset_l_reg = '0') and (hreset_l_regd = '1') then

        hblank_l <= '1';
        hsync_l <= '1';
      else

        if (hcount = "100001111") then -- x10F
          hblank_l <= '0';
        elsif (hcount = "101101111") then -- x16F
          hblank_l <= '1';
        end if;

        if (hcount = "100101111") then -- x12F
          hsync_l <= '0';
        elsif (hcount = "101001111") then -- x14F
          hsync_l <= '1';
        end if;

      end if;
   end if;
  end process;

  p_vreset_reg : process(clk, clk_fall)
  begin
    if (    g_use_clk_en and (rising_edge(clk) and clk_fall)) or
       (not g_use_clk_en and  falling_edge(clk)) then
      vreset_l_reg  <= vreset_l_i;
      vreset_l_regd <= vreset_l_reg;
    end if;
  end process;

  p_vcount_ena : process(hcount)
  begin
    if (hcount = "100101111") then -- x12F
      vcount_ena <= '1';
    else
      vcount_ena <= '0';
    end if;
  end process;

  -- combinatorial logic separated from p_vcount process to generate the
  -- rising and falling clock enable outputs
  p_vcount_comb : process (vcount, vcount_ena, vcount_zero, vblank_l_reg, vreset_l_reg, vreset_l_regd)
  begin
    -- default assignments
    vcount_zero_s <= vcount_zero;
    vcount_s      <= vcount;
    vblank_l_s    <= vblank_l_reg;

    if (vreset_l_reg = '0') and (vreset_l_regd = '1') then
      vcount_zero_s <= '0';
      vcount_s      <= (others => '0');
      vblank_l_s    <= '0';

    else
      if (vcount_ena = '1') then
        if (vcount = "100000111") then -- x107
          vcount_zero_s <= '1';
          vcount_s      <= (others => '0');
        else
          vcount_zero_s <= '0';
          vcount_s      <= vcount + "1";
        end if;

        if (vcount = "011101111") then -- x1EF
          vblank_l_s <= '0';
        elsif (vcount = "000001111") then -- x00F
          vblank_l_s <= '1';
        end if;

      else
        vcount_zero_s <= '0';
      end if;
    end if;
  end process;
  clken_posegde_o.vcount <= (     vcount_s  and (not vcount)) when clk_rise else (others => '0');
  clken_negegde_o.vcount <= ((not vcount_s) and      vcount)  when clk_rise else (others => '0');
  clken_posegde_o.vblank <= (     vblank_l_s  and (not vblank_l_reg)) when clk_rise else '0';
  clken_negegde_o.vblank <= ((not vblank_l_s) and      vblank_l_reg)  when clk_rise else '0';

  p_vcount : process
  begin
    wait until rising_edge(clk);
    if clk_rise then
      vcount_zero  <= vcount_zero_s;
      vcount       <= vcount_s;
      vblank_l_reg <= vblank_l_s;
      if (vreset_l_reg = '0') and (vreset_l_regd = '1') then

        vsync_l <= '1';
      else
        if (vcount_ena = '1') then
          if (vcount = "011110111") then -- x1F7
            vsync_l <= '0';
          elsif (vcount = "011111111") then -- x0FF
            vsync_l <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;

  hcount_o <= hcount;
  vcount_o <= vcount(7 downto 0);
  vblank_l <= vblank_l_reg;

  -- hreset_l and vreset_l are supposed to be sampled on the falling clock edge
  hreset_l_o <= '0' when hcount_zero = '1' else '1';
  vreset_l_o <= '0' when vcount_zero = '1' else '1';

end RTL;
