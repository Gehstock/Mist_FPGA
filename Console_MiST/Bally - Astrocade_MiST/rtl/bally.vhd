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

entity BALLY is
  port (
    O_AUDIO            : out   std_logic_vector(7 downto 0);

    O_VIDEO_R          : out   std_logic_vector(3 downto 0);
    O_VIDEO_G          : out   std_logic_vector(3 downto 0);
    O_VIDEO_B          : out   std_logic_vector(3 downto 0);

    O_HSYNC            : out   std_logic;
    O_VSYNC            : out   std_logic;
    O_COMP_SYNC_L      : out   std_logic;
    O_FPSYNC           : out   std_logic;

    -- cart slot
    O_CAS_ADDR         : out   std_logic_vector(12 downto 0);
    O_CAS_DATA         : out   std_logic_vector( 7 downto 0);
    I_CAS_DATA         : in    std_logic_vector( 7 downto 0);
    O_CAS_CS_L         : out   std_logic;

    -- exp slot (subset for now)
    O_EXP_ADDR         : out   std_logic_vector(15 downto 0);
    O_EXP_DATA         : out   std_logic_vector( 7 downto 0);
    I_EXP_DATA         : in    std_logic_vector( 7 downto 0);
    I_EXP_OE_L         : in    std_logic; -- expansion slot driving data bus

    O_EXP_M1_L         : out   std_logic;
    O_EXP_MREQ_L       : out   std_logic;
    O_EXP_IORQ_L       : out   std_logic;
    O_EXP_WR_L         : out   std_logic;
    O_EXP_RD_L         : out   std_logic;
    --
    O_SWITCH_COL       : out   std_logic_vector(7 downto 0);
    I_SWITCH_ROW       : in    std_logic_vector(7 downto 0);
    --
    I_RESET_L          : in    std_logic;
    ENA                : in    std_logic;
	 pix_ena            : out   std_logic;
    CLK                : in    std_logic;
	 CLK7               : in    std_logic
    );
end;

architecture RTL of BALLY is

  --  signals
  signal cpu_ena          : std_logic;
  signal cpu_ena_gated    : std_logic;
  --
  signal cpu_m1_l         : std_logic;
  signal cpu_mreq_l       : std_logic;
  signal cpu_iorq_l       : std_logic;
  signal cpu_rd_l         : std_logic;
  signal cpu_wr_l         : std_logic;
  signal cpu_rfsh_l       : std_logic;
  signal cpu_halt_l       : std_logic;
  signal cpu_wait_l       : std_logic;
  signal cpu_int_l        : std_logic;
  signal cpu_nmi_l        : std_logic;
  signal cpu_busrq_l      : std_logic;
  signal cpu_busak_l      : std_logic;
  signal cpu_addr         : std_logic_vector(15 downto 0);
  signal cpu_data_out     : std_logic_vector(7 downto 0);
  signal cpu_data_in      : std_logic_vector(7 downto 0);

  signal mc1              : std_logic;
  signal mc0              : std_logic;
  --signal mx_bus           : std_logic_vector(7 downto 0); -- cpu to customs
  signal mx_addr          : std_logic_vector(7 downto 0); -- customs to cpu
  signal mx_addr_oe_l     : std_logic;
  signal mx_data          : std_logic_vector(7 downto 0); -- customs to cpu
  signal mx_data_oe_l     : std_logic;
  signal mx_io            : std_logic_vector(7 downto 0); -- customs to cpu
  signal mx_io_oe_l       : std_logic;

  signal ma_bus           : std_logic_vector(15 downto 0);
  signal md_bus_out       : std_logic_vector(7 downto 0);
  signal md_bus_in        : std_logic_vector(7 downto 0);
  signal md_bus_in_x      : std_logic_vector(7 downto 0);
  signal daten_l          : std_logic;
  signal datwr            : std_logic;

  signal horiz_dr         : std_logic;
  signal vert_dr          : std_logic;
  signal wrctl_l          : std_logic;
  signal ltchdo           : std_logic;
  --
  -- expansion
  signal exp_buzoff_l     : std_logic;
  signal exp_sysen        : std_logic;
  signal exp_casen        : std_logic;

  signal sys_cs_l         : std_logic;
  signal rom0_dout        : std_logic_vector(7 downto 0);
  signal rom1_dout        : std_logic_vector(7 downto 0);
  signal rom_dout         : std_logic_vector(7 downto 0);
  signal cas_cs_l         : std_logic;

  signal video_r          : std_logic_vector(3 downto 0);
  signal video_g          : std_logic_vector(3 downto 0);
  signal video_b          : std_logic_vector(3 downto 0);
  signal hsync            : std_logic;
  signal vsync            : std_logic;
  signal fpsync           : std_logic;
begin
  --
  -- cpu
  --
  --  doc
  -- memory map
  -- 0000 - 0fff os rom / magic ram
  -- 1000 - 1fff os rom
  -- 2000 - 3fff cas rom
  -- 4000 - 4fff screen ram

  -- in hi res screen ram from 4000 - 7fff
  -- magic ram 0000 - 3fff

  -- screen
  -- low res 40 bytes / line (160 pixels, 2 bits per pixel)
  -- vert res 102 lines

  -- high res 80 bytes (320 pixels) and 204 lines.
  -- addr 0 top left. lsb 2 bits describe right hand pixel

  -- expansion sigs
  exp_buzoff_l <= '1'; -- pull up
  exp_sysen    <= '1'; -- pull up
  exp_casen    <= '1'; -- pull up

  -- other cpu signals
  cpu_busrq_l <= '1';
  cpu_nmi_l   <= '1';

  cpu_ena_gated <= ENA and cpu_ena;
  u_cpu : entity work.T80sed
          port map (
              RESET_n => I_RESET_L,
              CLK_n   => CLK7,
              CLKEN   => cpu_ena_gated,
              WAIT_n  => cpu_wait_l,
              INT_n   => cpu_int_l,
              NMI_n   => cpu_nmi_l,
              BUSRQ_n => cpu_busrq_l,
              M1_n    => cpu_m1_l,
              MREQ_n  => cpu_mreq_l,
              IORQ_n  => cpu_iorq_l,
              RD_n    => cpu_rd_l,
              WR_n    => cpu_wr_l,
              RFSH_n  => cpu_rfsh_l,
              HALT_n  => cpu_halt_l,
              BUSAK_n => cpu_busak_l,
              A       => cpu_addr,
              DI      => cpu_data_in,
              DO      => cpu_data_out
              );
  --
  -- primary addr decode
  --
  p_mem_decode_comb : process(cpu_rfsh_l, cpu_rd_l, cpu_mreq_l, cpu_addr, exp_sysen, exp_casen)
    variable decode : std_logic;
  begin

    sys_cs_l <= '1'; -- system rom
    cas_cs_l <= '1'; -- game rom

    decode := '0';
    if (cpu_rd_l = '0') and (cpu_mreq_l = '0') and (cpu_addr(15 downto 14) = "00") then
      decode := '1';
    end if;

    sys_cs_l <= not (decode and (not cpu_addr(13)) and exp_sysen);
    cas_cs_l <= not (decode and (    cpu_addr(13)) and exp_casen);
  end process;

  --p_microcycler : process(cpu_rfsh_l, mc0, mc1)
    --variable sel : std_logic_vector(1 downto 0);
  --begin
    --sel := mc0 & mc1;

    --if (cpu_rfsh_l = '0') then
      --mx_bus <= cpu_addr(7 downto 0);
    --else
      --mx_bus <= x"00";
      --case sel is
        --when "00" => mx_bus <= cpu_addr( 7 downto 0);
        --when "01" => mx_bus <= cpu_addr(15 downto 8);
        --when "10" => mx_bus <= cpu_data_out(7 downto 0);
        --when "11" => mx_bus <= x"00"; -- to cpu
        --when others => null;
      --end case;
      ---- to cpu data drive when
      ----rfsh_l = '1' and mc1 = '1', mc0 direction
    --end if;
  --end process;
  
	u_rom0 : entity work.sprom
	generic map (
		init_file         => ".\roms\bios3159_0.hex",
		widthad_a         => 12,
		width_a         	=> 8
	)
	port map (
		address         	=> cpu_addr(11 downto 0),
		clock	         	=> CLK7, 
		q		        	 	=> rom0_dout
	);
	
	u_rom1 : entity work.sprom
	generic map (
		init_file         => ".\roms\bios3159_1.hex",
		widthad_a         => 12,
		width_a         	=> 8
	)
	port map (
		address         	=> cpu_addr(11 downto 0),
		clock	         	=> CLK7, 
		q		        	 	=> rom1_dout
	);

  p_rom_mux : process(cpu_addr, rom0_dout, rom1_dout)
  begin
    if (cpu_addr(12) = '0') then
      rom_dout <= rom0_dout;
    else
      rom_dout <= rom1_dout;
    end if;

  end process;

  p_cpu_src_data_mux : process(rom_dout, sys_cs_l, I_CAS_DATA, cas_cs_l, I_EXP_OE_L, I_EXP_DATA, exp_buzoff_l,
                               mx_addr_oe_l, mx_addr, mx_data_oe_l, mx_data, mx_io_oe_l, mx_io)
  begin
    -- nasty mux
    if (I_EXP_OE_L = '0') or (exp_buzoff_l = '0') then
      cpu_data_in <= I_EXP_DATA;
    elsif (sys_cs_l = '0') then
      cpu_data_in <= rom_dout;
    elsif (cas_cs_l = '0') then
      cpu_data_in <= I_CAS_DATA;
    elsif (mx_addr_oe_l = '0') then
      cpu_data_in <= mx_addr;
    elsif (mx_data_oe_l = '0') then
      cpu_data_in <= mx_data;
    elsif (mx_io_oe_l = '0') then
      cpu_data_in <= mx_io;
    else
      cpu_data_in <= x"FF";
    end if;
  end process;

  u_addr : entity work.BALLY_ADDR
    port map (
      I_MXA             => cpu_addr,
      I_MXD             => cpu_data_out,
      O_MXD             => mx_addr,
      O_MXD_OE_L        => mx_addr_oe_l,

      -- cpu control signals
      I_RFSH_L          => cpu_rfsh_l,
      I_M1_L            => cpu_m1_l,
      I_RD_L            => cpu_rd_l,
      I_MREQ_L          => cpu_mreq_l,
      I_IORQ_L          => cpu_iorq_l,
      O_WAIT_L          => cpu_wait_l,
      O_INT_L           => cpu_int_l,

      -- custom
      I_HORIZ_DR        => horiz_dr,
      I_VERT_DR         => vert_dr,
      O_WRCTL_L         => wrctl_l,
      O_LTCHDO          => ltchdo,

      -- dram address
      O_MA              => ma_bus,
      O_RAS             => open,
      -- misc
      I_LIGHT_PEN_L     => '1',

      -- clks
      I_CPU_ENA         => cpu_ena,
      ENA               => ENA,
      CLK               => CLK7
      );

  u_data : entity work.BALLY_DATA
    port map (
      I_MXA             => cpu_addr,
      I_MXD             => cpu_data_out,
      O_MXD             => mx_data,
      O_MXD_OE_L        => mx_data_oe_l,

      -- cpu control signals
      I_M1_L            => cpu_m1_l,
      I_RD_L            => cpu_rd_l,
      I_MREQ_L          => cpu_mreq_l,
      I_IORQ_L          => cpu_iorq_l,

      -- memory
      O_DATEN_L         => daten_l,
      O_DATWR           => datwr, -- makes dp ram timing easier
      I_MDX             => md_bus_in_x,
      I_MD              => md_bus_in,
      O_MD              => md_bus_out,
      O_MD_OE_L         => open,
      -- custom
      O_MC1             => mc1,
      O_MC0             => mc0,

      O_HORIZ_DR        => horiz_dr,
      O_VERT_DR         => vert_dr,
      I_WRCTL_L         => wrctl_l,
      I_LTCHDO          => ltchdo,

      I_SERIAL1         => '0',
      I_SERIAL0         => '0',

      O_VIDEO_R         => video_r,
      O_VIDEO_G         => video_g,
      O_VIDEO_B         => video_b,
      O_HSYNC           => hsync,
      O_VSYNC           => vsync,
      O_FPSYNC          => fpsync,
      -- clks
      O_CPU_ENA         => cpu_ena, -- cpu clock ena
      O_PIX_ENA         => pix_ena, -- pixel clock ena
      ENA               => ENA,
      CLK               => CLK7
--		CLK7              => CLK7
      );

  u_io   : entity work.BALLY_IO
    port map (
      I_MXA             => cpu_addr,
      I_MXD             => cpu_data_out,
      O_MXD             => mx_io,
      O_MXD_OE_L        => mx_io_oe_l,

      -- cpu control signals
      I_M1_L            => cpu_m1_l,
      I_RD_L            => cpu_rd_l,
      I_IORQ_L          => cpu_iorq_l,
      I_RESET_L         => I_RESET_L,

      -- no pots - student project ? :)

      -- switches
      O_SWITCH          => O_SWITCH_COL,
      I_SWITCH          => I_SWITCH_ROW,
      -- audio
      O_AUDIO           => O_AUDIO,

      -- clks
      I_CPU_ENA         => cpu_ena,
      ENA               => ENA,
      CLK               => CLK7
      );

  p_video_out : process
  begin
    wait until rising_edge(CLK7);
    if (ENA = '1') then
      O_HSYNC <= hsync;
      O_VSYNC <= vsync;
      O_COMP_SYNC_L <= (not vsync) and (not hsync);

      O_VIDEO_R <= video_r;
      O_VIDEO_G <= video_g;
      O_VIDEO_B <= video_b;
      O_FPSYNC  <= fpsync;
    end if;
  end process;

  u_rams : entity work.BALLY_RAMS
    port map (
    ADDR     => ma_bus,
    DIN      => md_bus_out,
    DOUT     => md_bus_in,
    DOUTX    => md_bus_in_x,
    WE       => datwr,
    WE_ENA_L => daten_l, -- only used for write
    ENA      => ENA,
    CLK      => CLK7
    );

  -- drive cas
  O_CAS_ADDR         <= cpu_addr(12 downto 0);
  O_CAS_DATA         <= cpu_data_out;
  O_CAS_CS_L         <= cas_cs_l;

  -- drive exp
  -- all sigs should be bi-dir as exp slot devices can take control of the bus
  -- this will be ok for the test cart
  O_EXP_ADDR         <= cpu_addr;
  O_EXP_DATA         <= cpu_data_out; -- not quite right, should be resolved data bus so exp slot can read customs / ram
  O_EXP_M1_L         <= cpu_m1_l;
  O_EXP_MREQ_L       <= cpu_mreq_l;
  O_EXP_IORQ_L       <= cpu_iorq_l;
  O_EXP_WR_L         <= cpu_wr_l;
  O_EXP_RD_L         <= cpu_rd_l;


end RTL;
