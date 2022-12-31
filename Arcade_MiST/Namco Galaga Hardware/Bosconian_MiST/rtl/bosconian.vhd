-- TODO - MAME runs the 50xx, 51xx, and 54xx at MASTER_CLOCK/12, or 1.536 MHz. I run them at 3 MHz?
-- TODO - Investigate what the 51xx does on vblank
-- TODO - Unlike the Galaga 54xx, the Bosco 54xx has its IRQ duration manually set.
-- 		n54xx.set_irq_duration(attotime::from_usec(200));
--		Check out Xevious too, and implement if needed.
-- TODO - The 06xx in MAME runs at MASTER_CLOCK/6/64, which is very slow compared to what I have?
-- TODO - The RW flags for the 06xx daughter chips should be independently?

---------------------------------------------------------------------------------
-- Galaga Midway by Dar (darfpga@aol.fr)
-- http://darfpga.blogspot.fr
---------------------------------------------------------------------------------
-- gen_ram.vhd
--------------
-- Copyright 2005-2008 by Peter Wendrich (pwsoft@syntiac.com)
-- http://www.syntiac.com/fpga64.html
---------------------------------------------------------------------------------
-- T80/T80se - Version : 0247
-----------------------------
-- Z80 compatible microprocessor core
-- Copyright (c) 2001-2002 Daniel Wallner (jesus@opencores.org)
---------------------------------------------------------------------------------
-- Educational use only
-- Do not redistribute synthetized file with roms
-- Do not redistribute roms whatever the form
-- Use at your own risk
---------------------------------------------------------------------------------
-- Galaga releases: see MiSTer GitHub page
---------------------------------------------------------------------------------
--  Features :
--   TV 15KHz mode only (atm)
--   Coctail mode ok
--   Sound ok
--   Starfield from MAME information

--  Galaga Hardware characteristics :
--
--    3xZ80 CPU accessing each own program rom and shared ram/devices
--
--    One char tile map 32x28 (called background/bg although being front of other layers)
--      3 colors/64sets among 16 colors
--      1Ko ram, 4Ko rom graphics, 4pixels of 2bits/byte
--      full emulation in vhdl
--
--    64 sprites with priorities, flip H/V, 2x size H/V,
--      3 colors/64sets among 16 colors (different of char colors).
--      8Ko rom graphics, 4pixels of 2bits/byte
--      full emulation in vhdl (improved capabilities : more sprites/scanline)
--
--    Namco 05XX Starfield
--      4 sets, 63 stars/set, 2 set displayed at one time for blinking
--      6bits colors: 2red/2green/2blue
--      full emulation in vhdl (from MAME information)
--
--    Char/sprites color palette 2x16 colors among 256 colors
--      8bits 3red/3green/2blue
--      full emulation in vhdl
--
--    Namco 06XX for 51/54XX control
--      simplified emulation in vhdl
--
--    Namco 51XX for input/coin/credit management
--      emulated using mb88
--
--    Namco 54XX for sound effects
--      emulated using mb88
--
--    Namco sound waveform and frequency synthetizer
--      full original emulation in vhdl
--
--    Namco 00XX,04XX,02XX,07XX,08XX address generator, H/V counters and shift registers
--      full emulation in vhdl from what I think they should do.
--
--    Working ram : 3x1Kx8bits shared
--    Sprites ram : 1 scan line delay flip/flop 512x4bits
--    Sound registers ram : 2x16x4bits
--    Sound sequencer rom : 256x4bits (3 sequential 4 bits adders)
--    Sound wavetable rom : 256x4bits 8 waveform of 32 samples of 4bits/level
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity bosconian is
port(
	clock_18       : in std_logic;
	reset          : in std_logic;
	video_r        : out std_logic_vector(2 downto 0);
	video_g        : out std_logic_vector(2 downto 0);
	video_b        : out std_logic_vector(1 downto 0);
	video_csync_n  : out std_logic;
	video_ce       : out std_logic;
	video_hsync_n  : out std_logic;
	video_vsync_n  : out std_logic;

	video_hblank_n : out std_logic;
	video_vblank_n : out std_logic;

	audio          : out std_logic_vector(15 downto 0);

	service        : in std_logic;
	self_test      : in std_logic;

	coin1          : in std_logic;
	start1         : in std_logic;
	up1            : in std_logic;
	down1          : in std_logic;
	left1          : in std_logic;
	right1         : in std_logic;
	fire1          : in std_logic;

	coin2          : in std_logic;
	start2         : in std_logic;
	up2            : in std_logic;
	down2          : in std_logic;
	left2          : in std_logic;
	right2         : in std_logic;
	fire2          : in std_logic;

	dip_switch_a   : in std_logic_vector (7 downto 0);
	dip_switch_b   : in std_logic_vector (7 downto 0);

--	dn_addr        : in  std_logic_vector(15 downto 0);
--	dn_data        : in  std_logic_vector(7 downto 0);
--	dn_wr          : in  std_logic;
	cpu1_rom_addr: out std_logic_vector(13 downto 0);
	cpu1_rom_do : in  std_logic_vector( 7 downto 0);
	cpu2_rom_addr: out std_logic_vector(12 downto 0);
	cpu2_rom_do : in  std_logic_vector( 7 downto 0);
	cpu3_rom_addr: out std_logic_vector(11 downto 0);
	cpu3_rom_do : in  std_logic_vector( 7 downto 0);

	h_offset       : in  signed(3 downto 0);
	v_offset       : in  signed(3 downto 0);

	pause          : in  std_logic
);
end bosconian;

use work.C07_SYNCGEN_PACK.all;

architecture struct of bosconian is

 signal reset_n: std_logic;
 signal clock_18n : std_logic;
 signal pause_n : std_logic;

 -- c07 clock enables
 signal c07_clken_s : r_c07_syncgen_clken;
 signal c07_clken_posedge_s : r_c07_syncgen_clken_out;
 signal c07_clken_negedge_s : r_c07_syncgen_clken_out;

 -- clocking/timing
 signal hcnt     : std_logic_vector(8 downto 0);
 signal vcnt     : std_logic_vector(7 downto 0);
 signal vblank_n : std_logic;

 signal video_6M_ena    : std_logic;
 signal video_6Mn_ena   : std_logic;
 signal ena_snd_machine : std_logic;
 signal cpu1_ena        : std_logic;
 signal cpu2_ena        : std_logic;
 signal cpu3_ena        : std_logic;

 signal cpu1_addr   : std_logic_vector(15 downto 0);
 signal cpu1_di     : std_logic_vector( 7 downto 0);
 signal cpu1_do     : std_logic_vector( 7 downto 0);
 signal cpu1_wr_n   : std_logic;
 signal cpu1_mreq_n : std_logic;
 signal cpu1_irq_n  : std_logic;
 signal cpu1_nmi_n  : std_logic;
 signal cpu1_m1_n   : std_logic;

 signal cpu2_addr   : std_logic_vector(15 downto 0);
 signal cpu2_di     : std_logic_vector( 7 downto 0);
 signal cpu2_do     : std_logic_vector( 7 downto 0);
 signal cpu2_wr_n   : std_logic;
 signal cpu2_mreq_n : std_logic;
 signal cpu2_irq_n  : std_logic;
 signal cpu2_nmi_n  : std_logic;
 signal cpu2_m1_n   : std_logic;

 signal cpu3_addr   : std_logic_vector(15 downto 0);
 signal cpu3_di     : std_logic_vector( 7 downto 0);
 signal cpu3_do     : std_logic_vector( 7 downto 0);
 signal cpu3_wr_n   : std_logic;
 signal cpu3_mreq_n : std_logic;
 signal cpu3_nmi_n  : std_logic;
 signal cpu3_m1_n   : std_logic;

 signal video_ram_addr : std_ulogic_vector(10 downto 0);

 signal bgram1_do  : std_logic_vector( 7 downto 0);
 signal bgram1_we  : std_logic;
 signal bgram2_do  : std_logic_vector( 7 downto 0);
 signal bgram2_we  : std_logic;
 signal soram_do   : std_logic_vector( 3 downto 0);
 signal soram_do_n : std_ulogic_vector( 3 downto 0);
 signal soram_we   : std_logic;
 signal wram_do    : std_logic_vector( 7 downto 0);
 signal wram_we    : std_logic;
 signal port_we    : std_logic;

 signal playfield_posix : std_logic_vector(7 downto 0);
 signal playfield_posiy : std_logic_vector(7 downto 0);

 signal slot       : std_logic_vector(2 downto 0) := (others => '0');
 signal mux_addr   : std_logic_vector(15 downto 0);
 signal mux_cpu_do : std_logic_vector( 7 downto 0);
 signal mux_cpu_we : std_logic;
 signal mux_cpu_mreq : std_logic;
 signal latch_we   : std_logic;
 signal io_we      : std_logic;
 signal excs_we    : std_logic;

 signal cs06xx_0_cs : std_logic;
 signal cs06xx_0_rw : std_logic;
 signal cs06xx_0_do : std_logic_vector( 7 downto 0);

 signal cs06xx_1_cs : std_logic;
 signal cs06xx_1_rw : std_logic;
 signal cs06xx_1_do : std_logic_vector( 7 downto 0);

 signal cs51xx_control    : std_logic_vector( 7 downto 0);
 signal cs51xx_r0_port_in : std_logic_vector( 3 downto 0);
 signal cs51xx_r1_port_in : std_logic_vector( 3 downto 0);
 signal cs51xx_r2_port_in : std_logic_vector( 3 downto 0);
 signal cs51xx_r3_port_in : std_logic_vector( 3 downto 0);
 signal cs51xx_irq_n      : std_logic := '1';
 signal cs51xx_rom_addr   : std_logic_vector(10 downto 0);
 signal cs51xx_rom_do     : std_logic_vector( 7 downto 0);
 signal cs51xx_k_port_in  : std_logic_vector( 3 downto 0);
 signal cs51xx_ol_port_out: std_logic_vector( 3 downto 0);
 signal cs51xx_oh_port_out: std_logic_vector( 3 downto 0);
 signal cs51xx_do         : std_logic_vector( 7 downto 0);

 signal cs50xx_0_control     : std_logic_vector( 7 downto 0);
 signal cs50xx_0_irq_n       : std_logic := '1';
 signal cs50xx_0_rom_addr    : std_logic_vector(10 downto 0);
 signal cs50xx_0_rom_do      : std_logic_vector( 7 downto 0);
 signal cs50xx_0_k_port_in   : std_logic_vector( 3 downto 0);
 signal cs50xx_0_r0_port_in  : std_logic_vector( 3 downto 0);
 signal cs50xx_0_r2_port_in  : std_logic_vector( 3 downto 0);
 signal cs50xx_0_ol_port_out : std_logic_vector( 3 downto 0);
 signal cs50xx_0_oh_port_out : std_logic_vector( 3 downto 0);
 signal cs50xx_0_do          : std_logic_vector( 7 downto 0);

 signal cs50xx_1_control     : std_logic_vector( 7 downto 0);
 signal cs50xx_1_irq_n       : std_logic := '1';
 signal cs50xx_1_rom_addr    : std_logic_vector(10 downto 0);
 signal cs50xx_1_rom_do      : std_logic_vector( 7 downto 0);
 signal cs50xx_1_k_port_in   : std_logic_vector( 3 downto 0);
 signal cs50xx_1_r0_port_in  : std_logic_vector( 3 downto 0);
 signal cs50xx_1_r2_port_in  : std_logic_vector( 3 downto 0);
 signal cs50xx_1_ol_port_out : std_logic_vector( 3 downto 0);
 signal cs50xx_1_oh_port_out : std_logic_vector( 3 downto 0);
 signal cs50xx_1_do          : std_logic_vector( 7 downto 0);

 signal cs52xx_control     : std_logic_vector( 7 downto 0);
 signal cs52xx_irq_n       : std_logic := '1';
 signal cs52xx_rom_addr    : std_logic_vector(10 downto 0);
 signal cs52xx_rom_do      : std_logic_vector( 7 downto 0);
 signal cs52xx_k_port_in   : std_logic_vector( 3 downto 0);
 signal cs52xx_r2_port_out : std_logic_vector( 3 downto 0);
 signal cs52xx_r3_port_out : std_logic_vector( 3 downto 0);
 signal cs52xx_ol_port_out : std_logic_vector( 3 downto 0);
 signal cs52xx_oh_port_out : std_logic_vector( 3 downto 0);
 signal cs52xx_audio       : std_logic_vector( 3 downto 0);

 signal cs52xx_555         : std_logic;
 signal cs52xx_555_cnt     : unsigned(11 downto 0);

 signal romvoice0_cs_n     : std_logic;
 signal romvoice1_cs_n     : std_logic;
 signal romvoice2_cs_n     : std_logic;
 signal romvoice_addr      : std_logic_vector(11 downto 0);
 signal romvoice0_do       : std_logic_vector( 7 downto 0);
 signal romvoice1_do       : std_logic_vector( 7 downto 0);
 signal romvoice2_do       : std_logic_vector( 7 downto 0);
 signal romvoice_do        : std_logic_vector( 7 downto 0);

 signal cs54xx_ena      : std_logic;
 signal cs54xx_ena_div  : std_logic_vector(3 downto 0) := "0000";

 signal cs5Xxx_0_ena      : std_logic;
 signal cs5Xxx_0_ena_div  : std_logic_vector(3 downto 0) := "0000";

 signal cs5Xxx_1_ena      : std_logic;
 signal cs5Xxx_1_ena_div  : std_logic_vector(5 downto 0) := "000000";

 signal cs52xx_ena      : std_logic;
 signal cs52xx_ena_div  : std_logic_vector(3 downto 0) := "0000";
 
 signal cs52xx_timer_ena     : std_logic;
 signal cs52xx_timer_ena_div : std_logic_vector(4 downto 0) := "00000";

 signal cs54xx_rom_addr : std_logic_vector(10 downto 0);
 signal cs54xx_rom_do   : std_logic_vector( 7 downto 0);

 signal cs54xx_control    : std_logic_vector( 7 downto 0);
 signal cs54xx_irq_n      : std_logic := '1';
 signal cs54xx_k_port_in  : std_logic_vector( 3 downto 0);
 signal cs54xx_r0_port_in : std_logic_vector( 3 downto 0);
 signal cs54xx_audio_1    : std_logic_vector( 3 downto 0);
 signal cs54xx_audio_2    : std_logic_vector( 3 downto 0);
 signal cs54xx_audio_3    : std_logic_vector( 3 downto 0);

 signal cs54xx_lpf1_audio_in : std_logic_vector(9 downto 0);
 signal cs54xx_lpf2_audio_in : std_logic_vector(9 downto 0);
 signal cs54xx_lpf3_audio_in : std_logic_vector(9 downto 0);

 signal cs54xx_audio_1_lpf: std_logic_vector(15 downto 0);
 signal cs54xx_audio_2_lpf: std_logic_vector(15 downto 0);
 signal cs54xx_audio_3_lpf: std_logic_vector(15 downto 0);

 signal sf_x_s          : std_logic_vector(2 downto 0); -- starfield X scroll speed
 signal sf_y_s          : std_logic_vector(2 downto 0); -- starfield Y scroll speed
 signal sf_blk_s        : std_logic_vector(1 downto 0); -- starfield active subset
 signal sf_starclr_s    : std_logic;                    -- starfield reset (active low)

 signal dip_switch_do : std_logic_vector (7 downto 0);

 signal flip_n_s         : std_logic;

 signal irq1_clr_n  : std_logic;
 signal irq2_clr_n  : std_logic;
 signal nmion_n     : std_logic;
 signal reset_cpu_n : std_logic; -- reset sub and sound CPU, and 5Xxx chips on main board
 signal reset_video_5Xxx_n : std_logic; -- reset 5Xxx chips on video board

 signal snd_ram_0_we : std_logic;
 signal snd_ram_1_we : std_logic;
 signal snd_audio    : std_logic_vector(9 downto 0);

 signal coin_r   : std_logic;
 signal start1_r : std_logic;
 signal start2_r : std_logic;

 signal fire1_r   : std_logic;
 signal fire2_r   : std_logic;
 signal fire1_mem : std_logic;
 signal fire2_mem : std_logic;

 signal rom1_wren      : std_logic;
 signal rom2_wren      : std_logic;
 signal rom3_wren      : std_logic;
 signal romsprite_wren : std_logic;
 signal romchar_wren   : std_logic;
 signal romvoice0_wren : std_logic;
 signal romvoice1_wren : std_logic;
 signal romvoice2_wren : std_logic;
 signal romcolor_wren  : std_logic;
 signal romradar_wren  : std_logic;
 signal rom50_wren     : std_logic;
 signal rom51_wren     : std_logic;
 signal rom52_wren     : std_logic;
 signal rom54_wren     : std_logic;
begin

clock_18n <= not clock_18;
reset_n   <= not reset;
pause_n   <= not pause;


dip_switch_do <= "000000" &
                 dip_switch_a(to_integer(unsigned(mux_addr(2 downto 0)))) &
                 dip_switch_b(to_integer(unsigned(mux_addr(2 downto 0))));

-- simplified audio signal mixing
audio <= ("00" & cs54xx_audio_1_lpf(15 downto 2))
       + ("00" & cs54xx_audio_2_lpf(15 downto 2))
       + ("00" & cs54xx_audio_3_lpf(15 downto 2))
       + ("00" & cs52xx_audio & "0000000000")
       + ("0" & snd_audio & "00000");

-- make access slots from 18MHz
-- 6MHz for pixel clock and sound machine
-- 3MHz for cpu, background and sprite machine

--         slots  |   0  |   1  |    2   |    3   |   4   |    5   |
--   bgram access | cpu1 | cpu2 |   gfx  |  cpu3  |       |   gfx  |
--   sound access | cpu1 | cpu2 | sndram |  cpu3  | n.u.  | sndram |
-- video clk rise |   X  |      |        |    X   |       |        |
-- video clk fall |      |      |    X   |        |       |    X   |

-- enable signals are one slot early

process (clock_18)
begin
	if rising_edge(clock_18) then
		cpu1_ena        <= '0';
		cpu2_ena        <= '0';
		cpu3_ena        <= '0';
		video_6M_ena    <= '0';
		video_6Mn_ena   <= '0';
		ena_snd_machine <= '0';
		cs54xx_ena      <= '0';
		cs52xx_ena      <= '0';
		cs5Xxx_0_ena    <= '0';
		cs5Xxx_1_ena    <= '0';

		if slot = "101" then
			slot <= (others => '0');
			cs54xx_ena_div   <= cs54xx_ena_div   + '1';
			cs52xx_ena_div   <= cs52xx_ena_div   + '1';
			cs5Xxx_0_ena_div <= cs5Xxx_0_ena_div + '1';
			cs5Xxx_1_ena_div <= cs5Xxx_1_ena_div + '1';
		else
			slot <= std_logic_vector(unsigned(slot) + 1);
		end if;

		-- NOTE: If ena_snd_machine is set outside this process the same way
		-- the cpuX_ena flags are set, sound becomes mildly corrupted. Why?
		if slot = "001" or slot = "100" then video_6M_ena <= '1';	end if;
		if slot = "011" or slot = "000" then video_6Mn_ena  <= '1';	end if;
		if slot = "101" then cpu1_ena <= '1';	end if;
		if slot = "000" then cpu2_ena <= '1';	end if;
		if slot = "010" then cpu3_ena <= '1';	end if;

		if pause = '0' then
			if slot = "001" or slot = "100" then ena_snd_machine <= '1';	end if;
		end if;

		if slot = "000" then
      -- TODO: The div value is 1100 in the Galaga and Xevious cores, and
      -- I think that would be the most appropriate value here as well
      -- (based on 1011 producing a slightly high pitch.) However, using
      -- 1100 results in the sounds becoming corrupted over the course of
      -- gameplay. Not sure why yet - may be related to the shot sound
      -- regression they saw in MAME (and fixed by manually extending the
      -- 54xx IRQ duration.)
			if cs54xx_ena_div = "1011" then
				cs54xx_ena_div <= "0000";
				cs54xx_ena <= '1';
			end if;
			if cs52xx_ena_div = "1100" then
				cs52xx_ena_div <= "0000";
				cs52xx_ena <= '1';
				cs52xx_timer_ena_div <= cs52xx_timer_ena_div + "00001";
			end if;
			if cs5Xxx_0_ena_div = "1100" then
				cs5Xxx_0_ena_div <= "0000";
				cs5Xxx_0_ena <= '1';
			end if;
			if cs5Xxx_1_ena_div = "110000" then
				cs5Xxx_1_ena_div <= "000000";
				cs5Xxx_1_ena <= '1';
			end if;
		end if;
	end if;
end process;

video_ce <= '1' when slot = "000" or slot = "011" else '0';

--- VIDEO SYSTEM ---
--------------------

-- REWORK
bosconian_video : entity work.bosconian_video
port map (
  -- inputs: clock/reset
  clk_i => clock_18,
  clkn_i => clock_18n,
  clk_en_i => video_6M_ena,
  clkn_en_i => video_6Mn_ena,
  resn_i => reset_n,

  -- inputs: user controls (not on original hardware)
  pause => pause,
  h_offset => h_offset,
  v_offset => v_offset,

  -- inputs: control
  flip_n_s => flip_n_s,
	playfield_posix => playfield_posix,
	playfield_posiy => playfield_posiy,
  sf_x_s => sf_x_s,
  sf_y_s => sf_y_s,
  sf_blk_s => sf_blk_s,
  sf_starclr_s => sf_starclr_s,

  -- inputs: RAM data out
  db_a2_s => bgram1_do,
  db_a3_s => bgram2_do,
  ram_2E_do_n => soram_do_n,

  -- inputs: ROM setup bus
--  a_i => dn_addr,
--  d_i => dn_data,
	romchar_wren => romchar_wren,
	romsprite_wren => romsprite_wren,
	romradar_wren => romradar_wren,

  -- output: address for video RAMs
  video_ram_addr_o => video_ram_addr,

  -- outputs: video
  hblankn_o => video_hblank_n,
  vblankn_o => video_vblank_n,
  syncn_o  => video_csync_n,
  hsyncn_o => video_hsync_n,
  vsyncn_o => video_vsync_n,
  r_o => video_r,
  g_o => video_g,
  b_o => video_b
);


--- SOUND MACHINE ---
---------------------

sound_machine : entity work.sound_machine
port map(
	clock_18  => clock_18,
	ena       => ena_snd_machine,
	hcnt      => hcnt(5 downto 0),
	cpu_addr  => mux_addr(3 downto 0),
	cpu_do    => mux_cpu_do(3 downto 0),
	ram_0_we  => snd_ram_0_we,
	ram_1_we  => snd_ram_1_we,
	audio     => snd_audio
);

--- CPUS -------------
----------------------

with slot select
mux_addr <=
	cpu1_addr   when "000",
	cpu2_addr   when "001",
  "00000" & std_logic_vector(video_ram_addr) when "010",
	cpu3_addr   when "011",
  "00000" & std_logic_vector(video_ram_addr) when "101",
  X"5555"     when others;

with slot select
mux_cpu_do <= 
	cpu1_do when "000",
	cpu2_do when "001",
	cpu3_do when "011",
	X"00"   when others;

mux_cpu_we <=
	(not cpu1_wr_n and cpu1_ena) or
	(not cpu2_wr_n and cpu2_ena) or
	(not cpu3_wr_n and cpu3_ena);

mux_cpu_mreq <= 
	(not cpu1_mreq_n and cpu1_ena) or
	(not cpu2_mreq_n and cpu2_ena) or
	(not cpu3_mreq_n and cpu3_ena);

latch_we  <= '1' when mux_cpu_we = '1' and mux_addr(15 downto 11) = "01101" else '0';
io_we     <= '1' when mux_cpu_we = '1' and mux_addr(15 downto 11) = "01110" else '0';
wram_we   <= '1' when mux_cpu_we = '1' and mux_addr(15 downto 11) = "01111" else '0';
bgram1_we <= '1' when mux_cpu_we = '1' and mux_addr(15 downto 11) = "10000" else '0';
bgram2_we <= '1' when mux_cpu_we = '1' and mux_addr(15 downto 11) = "10001" else '0';
excs_we   <= '1' when mux_cpu_we = '1' and mux_addr(15 downto 11) = "10010" else '0';
port_we   <= '1' when mux_cpu_we = '1' and mux_addr(15 downto 11) = "10011" else '0';

cs06xx_0_cs <= '1' when mux_cpu_mreq = '1' and mux_cpu_we = '0' and mux_addr(15 downto 11) = "01110" else '0';
cs06xx_1_cs <= '1' when mux_cpu_mreq = '1' and mux_cpu_we = '0' and mux_addr(15 downto 11) = "10010" else '0';

snd_ram_0_we <= '1' when mux_cpu_we = '1' and mux_addr(15 downto 11) = "01101" and mux_addr(5 downto 4) = "00" else '0';
snd_ram_1_we <= '1' when mux_cpu_we = '1' and mux_addr(15 downto 11) = "01101" and mux_addr(5 downto 4) = "01" else '0';

soram_we <= '1' when port_we = '1' and mux_addr(6 downto 4) = "000" else '0';

process (reset, clock_18n, io_we)
begin
	if reset='1' then
		irq1_clr_n  <= '0';
		irq2_clr_n  <= '0';
		nmion_n     <= '0';
		reset_cpu_n <= '0';
		reset_video_5Xxx_n <= '0';
		cpu1_irq_n  <= '1';
		cpu2_irq_n  <= '1';
		flip_n_s <= '1';
    -- starfield control
    sf_starclr_s <= '1';
    sf_blk_s <= "11";
    sf_x_s <= "000";
    sf_y_s <= "000";

	else
		if rising_edge(clock_18n) then
			if latch_we ='1' and mux_addr(5 downto 4) = "10" then
				if mux_addr(2 downto 0) = "000" then irq1_clr_n  <= mux_cpu_do(0); end if;
				if mux_addr(2 downto 0) = "001" then irq2_clr_n  <= mux_cpu_do(0); end if;
				if mux_addr(2 downto 0) = "010" then nmion_n     <= mux_cpu_do(0); end if;
				if mux_addr(2 downto 0) = "011" then reset_cpu_n <= mux_cpu_do(0); end if;
			end if;

			if port_we ='1' then
				-- 10011----000xxxx   W ----xxxx SOWR      bullets shape and X pos msb
        -- handled with soram_we signal above

				-- 10011----001----   W xxxxxxxx POSI X    playfield X scroll
        if mux_addr(6 downto 4) = "001" then
					playfield_posix <= mux_cpu_do;

				-- 10011----010----   W xxxxxxxx POSI Y    playfield Y scroll
				elsif mux_addr(6 downto 4) = "010" then
					playfield_posiy <= mux_cpu_do;

				-- 10011----011----   W -----xxx STAR      to 05XX: starfield X scroll speed
				-- 10011----011----   W --xxx--- STAR      to 05XX: starfield Y scroll speed
				elsif mux_addr(6 downto 4) = "011" then
          sf_y_s <= mux_cpu_do(5 downto 3);
          sf_x_s <= mux_cpu_do(2 downto 0);

				-- 10011----100----   W -------- STARCLR   to 05XX: starfield enable(?)
				elsif mux_addr(6 downto 4) = "100" then
					sf_starclr_s <= '1'; -- Bosconian forces all STARCLR writes to 1.

				elsif mux_addr(6 downto 4) = "111" then
					-- 10011----111-000   W -------x FLIP      flip screen
					if mux_addr(2 downto 0) = "000" then
						flip_n_s <= mux_cpu_do(0);

					-- 10011----111-100   W -------x BLK 0     \ to 05XX: starfield blink
					-- 10011----111-101   W -------x BLK 1     /          (select active subset)
					elsif mux_addr(2 downto 0) = "100" then
            sf_blk_s(1) <= mux_cpu_do(0);
					elsif mux_addr(2 downto 0) = "101" then
            sf_blk_s(0) <= mux_cpu_do(0);

					-- 10011----111-111   W -------x RESET     reset 5xXX chips on video board
					elsif mux_addr(2 downto 0) = "111" then
						reset_video_5Xxx_n <= mux_cpu_do(0);
					end if;
				end if;
			end if;

			if irq1_clr_n = '0' then cpu1_irq_n <= '1';
			elsif vcnt = std_logic_vector(to_unsigned(240,9)) then cpu1_irq_n <= '0';
			end if;

			if irq2_clr_n = '0' then cpu2_irq_n <= '1';
			elsif vcnt = std_logic_vector(to_unsigned(240,9)) then cpu2_irq_n <= '0';
			end if;

		end if; -- rising_edge(clock_18n)
	end if; -- reset /= '1'

end process;



process (clock_18, nmion_n)
begin
 if nmion_n = '1' then
 elsif rising_edge(clock_18) then
	if video_6M_ena = '1' then
		if hcnt = "100000000" then
			if vcnt = "01000000" or vcnt = "11000000" then cpu3_nmi_n <= '0'; end if;
			if vcnt = "01000001" or vcnt = "11000001" then cpu3_nmi_n <= '1'; end if;
		end if;
	end if;
 end if;
end process;

with cpu1_addr(15 downto 11) select
cpu1_di <=  cpu1_rom_do   when "00000",
            cpu1_rom_do   when "00001",
            cpu1_rom_do   when "00010",
            cpu1_rom_do   when "00011",
            cpu1_rom_do   when "00100",
            cpu1_rom_do   when "00101",
            cpu1_rom_do   when "00110",
            cpu1_rom_do   when "00111",
            dip_switch_do when "01101",
            cs06xx_0_do   when "01110",
            wram_do       when "01111",
            bgram1_do     when "10000",
            bgram2_do     when "10001",
	          cs06xx_1_do   when "10010",
            X"00"         when others;

with cpu2_addr(15 downto 11) select
cpu2_di <=  cpu2_rom_do   when "00000",
            cpu2_rom_do   when "00001",
            cpu2_rom_do   when "00010",
            cpu2_rom_do   when "00011",
            dip_switch_do when "01101",
            cs06xx_0_do   when "01110",
            wram_do       when "01111",
            bgram1_do     when "10000",
            bgram2_do     when "10001",
	          cs06xx_1_do   when "10010",
            X"00"         when others;

with cpu3_addr(15 downto 11) select
cpu3_di <=  cpu3_rom_do   when "00000",
            cpu3_rom_do   when "00001",
            dip_switch_do when "01101",
            cs06xx_0_do   when "01110",
            wram_do       when "01111",
            bgram1_do     when "10000",
            bgram2_do     when "10001",
	          cs06xx_1_do   when "10010",
            X"00"         when others;

-- 4D: Namco 07xx Clock Divider / Sync Generator
-- There are two synchronized 07xx devices - one on the CPU board, one on the video board.
-- The one on the CPU board may actually be what generates the VBLANK signal used by the CRT?
-- But it shouldn't make a difference, since the two produce synchronized VBLANK signals.
-- Extracted and simplified from Mike Johnson: "C07_SYNCGEN.VHD".
c07_clken_s <= (clk_rise => video_6M_ena,
                clk_fall => video_6Mn_ena);
i_4D : entity work.C07_SYNCGEN
  generic map (
    g_use_clk_en => true
  )
  port map (
    clk     => clock_18,
    clken   => c07_clken_s,
    hcount_o => hcnt,
    hblank_l => open,
    hsync_l => open,
    hreset_l_i => reset_n,
    vreset_l_i => reset_n,
    vsync_l => open,
    vblank_l => vblank_n,
    vcount_o => vcnt,
    clken_posegde_o => open,
    --clken_negegde_o => open
    clken_posegde_o => c07_clken_posedge_s,
    clken_negegde_o => c07_clken_negedge_s
  );

-- microprocessor Z80 - 1
cpu1 : entity work.T80se
generic map(Mode => 0, T2Write => 1, IOWait => 1)
port map(
  RESET_n => reset_n,
  CLK_n   => clock_18,
	CLKEN   => cpu1_ena,
  WAIT_n  => pause_n,
  INT_n   => cpu1_irq_n,
  NMI_n   => cpu1_nmi_n,
  BUSRQ_n => '1',
  --M1_n    => cpu1_m1_n,
  MREQ_n  => cpu1_mreq_n,
  IORQ_n  => open,
  RD_n    => open,
  WR_n    => cpu1_wr_n,
  RFSH_n  => open,
  HALT_n  => open,
  BUSAK_n => open,
  A       => cpu1_addr,
  DI      => cpu1_di,
  DO      => cpu1_do
);

-- microprocessor Z80 - 2
cpu2 : entity work.T80se
generic map(Mode => 0, T2Write => 1, IOWait => 1)
port map(
--  RESET_n => reset_n,
  RESET_n => reset_cpu_n,
  CLK_n   => clock_18,
	CLKEN   => cpu2_ena,
  WAIT_n  => pause_n,
  INT_n   => cpu2_irq_n,
  NMI_n   => cpu2_nmi_n,
  BUSRQ_n => '1',
  --M1_n    => cpu2_m1_n,
  MREQ_n  => cpu2_mreq_n,
  IORQ_n  => open,
  RD_n    => open,
  WR_n    => cpu2_wr_n,
  RFSH_n  => open,
  HALT_n  => open,
  BUSAK_n => open,
  A       => cpu2_addr,
  DI      => cpu2_di,
  DO      => cpu2_do
);

-- microprocessor Z80 - 3
cpu3 : entity work.T80se
generic map(Mode => 0, T2Write => 1, IOWait => 1)
port map(
--  RESET_n => reset_n,
  RESET_n => reset_cpu_n,
  CLK_n   => clock_18,
	CLKEN   => cpu3_ena,
  WAIT_n  => pause_n,
  INT_n   => '1',
  NMI_n   => cpu3_nmi_n,
  BUSRQ_n => '1',
  --M1_n    => cpu3_m1_n,
  MREQ_n  => cpu3_mreq_n,
  IORQ_n  => open,
  RD_n    => open,
  WR_n    => cpu3_wr_n,
  RFSH_n  => open,
  HALT_n  => open,
  BUSAK_n => open,
  A       => cpu3_addr,
  DI      => cpu3_di,
  DO      => cpu3_do
);

--------------------------------------------------------------------------------
-- Namco 06xx (interface for 5xXX chips)
--------------------------------------------------------------------------------

-- 06xx #0 (main board)
---- Chip 0 is 51xx
---- No chip 1
---- Chip 2 is 50xx #0
---- Chip 3 is 54xx
namco_06xx_0 : entity work.namco_06xx
port map(
	-- inputs
	clock_18n => clock_18n,
	reset => reset,
	read_write => io_we,
	sel => mux_addr(8),

	di_cpu => mux_cpu_do,
	clk_fall_ena => c07_clken_negedge_s.hcount(6),

	chip_select => cs06xx_0_cs,

	di_chip0 => cs51xx_do,
	di_chip1 => X"00", -- no chip, no data
	di_chip2 => cs50xx_0_do,
	di_chip3 => X"00", -- no data from 54xx

	-- outputs
	do_cpu => cs06xx_0_do,

	do_chip0 => cs51xx_control,
	do_chip1 => open,
	do_chip2 => cs50xx_0_control,
	do_chip3 => cs54xx_control,

	chip0_irq_n => cs51xx_irq_n,
	chip1_irq_n => open,
	chip2_irq_n => cs50xx_0_irq_n,
	chip3_irq_n => cs54xx_irq_n,

	rw_out => cs06xx_0_rw,

	cpu_nmi_n => cpu1_nmi_n
);

-- 06xx #1 (video board)
---- Chip 0 is 50xx #1
---- Chip 1 is 52xx
---- No chip 2
---- No chip 3
namco_06xx_1 : entity work.namco_06xx
port map(
	-- inputs
	clock_18n => clock_18n,
	reset => reset,
	read_write => excs_we,
	sel => mux_addr(8),

	di_cpu => mux_cpu_do,
	clk_fall_ena => c07_clken_negedge_s.hcount(6), -- TODO: falling edge of /HBLANK*

	chip_select => cs06xx_1_cs,

	di_chip0 => cs50xx_1_do,
	di_chip1 => X"00", -- no data from 52xx
	di_chip2 => X"00", -- no chip, no data
	di_chip3 => X"00", -- no chip, no data

	-- outputs
	do_cpu => cs06xx_1_do,

	do_chip0 => cs50xx_1_control,
	do_chip1 => cs52xx_control,
	do_chip2 => open,
	do_chip3 => open,

	chip0_irq_n => cs50xx_1_irq_n,
	chip1_irq_n => cs52xx_irq_n,
	chip2_irq_n => open,
	chip3_irq_n => open,

	rw_out => cs06xx_1_rw,

	cpu_nmi_n => cpu2_nmi_n
);


--------------------------------------------------------------------------------
-- mb88 - cs51xx (42 pins IC, 1024 bytes rom)
--------------------------------------------------------------------------------

cs51xx_do <= cs51xx_oh_port_out & cs51xx_ol_port_out;
cs51xx_r0_port_in <= not (left1 & down1 & right1 & up1); -- pin 22,23,24,25
cs51xx_r1_port_in <= not (left2 & down2 & right2 & up2); -- pin 26,27,28,29
cs51xx_r2_port_in <= not (start2 & start1 & fire2 & fire1); -- pin 30,31,32,33
cs51xx_r3_port_in <= not (self_test & service & coin2 & coin1); -- pin 34,35,36,37
cs51xx_k_port_in <= cs06xx_0_rw & cs51xx_control(2 downto 0); -- pin 38,39,40,41

mb88_51xx : entity work.mb88
port map(
 reset_n    => reset_cpu_n, --reset_n,
 clock      => clock_18,
 ena        => cs5Xxx_0_ena,
 ena_timer  => '1', -- not strictly accurate

 r0_port_in  => cs51xx_r0_port_in,
 r1_port_in  => cs51xx_r1_port_in,
 r2_port_in  => cs51xx_r2_port_in,
 r3_port_in  => cs51xx_r3_port_in,
 r0_port_out => open,
 r1_port_out => open,
 r2_port_out => open,
 r3_port_out => open,
 k_port_in   => cs51xx_k_port_in,
 ol_port_out => cs51xx_ol_port_out, -- pin 13,14,15,16
 oh_port_out => cs51xx_oh_port_out, -- pin 17,18,19,20
 p_port_out  => open, -- pin 9,10,11,12

 stby_n    => '0',
 tc_n      => vblank_n,
 irq_n     => cs51xx_irq_n, -- pin 4
 sc_in_n   => '0', -- pin 7
 si_n      => '0', -- pin 6
 sc_out_n  => open, -- pin 7
 so_n      => open, -- pin 5
 to_n      => open, -- pin 7

 rom_addr  => cs51xx_rom_addr,
 rom_data  => cs51xx_rom_do
);

-- cs51xx program ROM
--cs51xx_prog : entity work.dpram generic map (10,8)
--port map
--(
--	clock_a   => clock_18,
--	wren_a    => rom51_wren,
--	address_a => dn_addr(9 downto 0),
--	data_a    => dn_data,
--
--	clock_b   => clock_18n,
--	address_b => cs51xx_rom_addr(9 downto 0),
--	q_b       => cs51xx_rom_do
--);

cs51xx_prog : entity work.n51xx
	port map(
		clk   => clock_18n,
		addr => cs51xx_rom_addr(9 downto 0),
		data       => cs51xx_rom_do
);


--------------------------------------------------------------------------------
-- mb88 - cs50xx (28 pins IC, 2048 bytes rom)
--------------------------------------------------------------------------------

-- This pin assignment into the 50xx is from Dar's FPGA Xevious.
cs50xx_0_k_port_in <= cs50xx_0_control(7 downto 4);
cs50xx_0_r0_port_in <= cs50xx_0_control(3 downto 0);
cs50xx_0_r2_port_in <= "000" & cs06xx_0_rw; -- pin 21 (read '1', write '0')

cs50xx_0_do <= cs50XX_0_oh_port_out & cs50XX_0_ol_port_out;

-- cs50xx #0 - part of the main board
-- MAME sources says that Bosconian is the only game to use the 50xx "to its full potential".
-- I am not yet sure how coin/credit/score/lives management is split between the 50xx and 51xx.

mb88_50xx_0 : entity work.mb88
port map(
	reset_n    => reset_cpu_n, --reset_n,
	clock      => clock_18,
	ena        => cs5Xxx_0_ena,
	ena_timer  => '1', -- not strictly accurate

	r0_port_in  => cs50xx_0_r0_port_in, -- pin 12,13,15,16 (data in 0-3)
	r1_port_in  => X"0",
	r2_port_in  => cs50xx_0_r2_port_in,   -- pin 21 (read '1', write '0')
	r3_port_in  => X"0",
	r0_port_out => open,
	r1_port_out => open,
	r2_port_out => open,
	r3_port_out => open,
	k_port_in   => cs50xx_0_k_port_in,   -- pin 24,25,26,27 (data in 4-7)
	ol_port_out => cs50xx_0_ol_port_out, -- pin  4, 5, 6, 7 (data out 0-3)
	oh_port_out => cs50xx_0_oh_port_out, -- pin  8, 9,10,11 (data out 4-7)
	p_port_out  => open,

	stby_n    => '0',
	tc_n      => '0',
	irq_n     => cs50xx_0_irq_n,
	sc_in_n   => '0',
	si_n      => '0',
	sc_out_n  => open,
	so_n      => open,
	to_n      => open,

	rom_addr  => cs50xx_0_rom_addr,
	rom_data  => cs50xx_0_rom_do
);

-- cs50xx #0 program ROM
--cs50xx_0_prog : entity work.dpram generic map (11,8)
--port map(
--	clock_a   => clock_18,
--	wren_a    => rom50_wren,
--	address_a => dn_addr(10 downto 0),
--	data_a    => dn_data,
--
--	clock_b   => clock_18n,
--	address_b => cs50xx_0_rom_addr(10 downto 0),
--	q_b       => cs50xx_0_rom_do
--);

cs50xx_0_prog : entity work.n50xx
	port map(
		clk   => clock_18n,
		addr => cs50xx_0_rom_addr(10 downto 0),
		data       => cs50xx_0_rom_do
);

-- cs50xx #1 - part of video board. Just used as a protection check.

cs50xx_1_k_port_in <= cs50xx_1_control(7 downto 4);
cs50xx_1_r0_port_in <= cs50xx_1_control(3 downto 0);
cs50xx_1_r2_port_in <= "000" & cs06xx_1_rw; -- pin 21 (read '1', write '0')

cs50xx_1_do <= cs50XX_1_oh_port_out & cs50XX_1_ol_port_out;

mb88_50xx_1 : entity work.mb88
port map(
	reset_n    => reset_video_5Xxx_n,
	clock      => clock_18,
	ena        => cs5Xxx_1_ena,
	ena_timer  => '1', -- not strictly accurate

	r0_port_in  => cs50xx_1_r0_port_in, -- pin 12,13,15,16 (data in 0-3)
	r1_port_in  => X"0",
	r2_port_in  => cs50xx_1_r2_port_in,
	r3_port_in  => X"0",
	r0_port_out => open,
	r1_port_out => open,
	r2_port_out => open,
	r3_port_out => open,
	k_port_in   => cs50xx_1_k_port_in,   -- pin 24,25,26,27 (data in 4-7)
	ol_port_out => cs50xx_1_ol_port_out, -- pin  4, 5, 6, 7 (data out 0-3)
	oh_port_out => cs50xx_1_oh_port_out, -- pin  8, 9,10,11 (data out 4-7)
	p_port_out  => open,

	stby_n    => '0',
	tc_n      => '0',
	irq_n     => cs50xx_1_irq_n,
	sc_in_n   => '0',
	si_n      => '0',
	sc_out_n  => open,
	so_n      => open,
	to_n      => open,

	rom_addr  => cs50xx_1_rom_addr,
	rom_data  => cs50xx_1_rom_do
);

-- cs50xx #1 program ROM
--cs50xx_1_prog : entity work.dpram generic map (11,8)
--port map
--(
--	clock_a   => clock_18,
--	wren_a    => rom50_wren,
--	address_a => dn_addr(10 downto 0),
--	data_a    => dn_data,
--
--	clock_b   => clock_18n,
--	address_b => cs50xx_1_rom_addr(10 downto 0),
--	q_b       => cs50xx_1_rom_do
--);

cs50xx_1_prog : entity work.n50xx
	port map(
		clk   => clock_18n,
		addr 	=> cs50xx_1_rom_addr(10 downto 0),
		data  => cs50xx_1_rom_do
);
--------------------------------------------------------------------------------
-- mb88 - cs54xx (28 pins IC, 1024 bytes rom)
--------------------------------------------------------------------------------

cs54xx_k_port_in <= cs54xx_control(7 downto 4);
cs54xx_r0_port_in <= cs54xx_control(3 downto 0);

mb88_54xx : entity work.mb88
port map(
 reset_n    => reset_cpu_n, --reset_n,
 clock      => clock_18,
 ena        => cs54xx_ena,
 ena_timer  => '1', -- not strictly accurate

 r0_port_in  => cs54xx_r0_port_in, -- pin 12,13,15,16
 r1_port_in  => X"0",
 r2_port_in  => X"0",
 r3_port_in  => X"0",
 r0_port_out => open,
 r1_port_out => cs54xx_audio_3,   -- pin 17,18,19,20
 r2_port_out => open,
 r3_port_out => open,
 k_port_in   => cs54xx_k_port_in, -- pin 24,25,26,27
 ol_port_out => cs54xx_audio_1,   -- pin  4, 5, 6, 7
 oh_port_out => cs54xx_audio_2,   -- pin  8, 9,10,11
 p_port_out  => open,

 stby_n    => '0',
 tc_n      => '0',
 irq_n     => cs54xx_irq_n,
 sc_in_n   => '0',
 si_n      => '0',
 sc_out_n  => open, -- pin 7
 so_n      => open, -- pin 5
 to_n      => open, -- pin 7


 rom_addr  => cs54xx_rom_addr,
 rom_data  => cs54xx_rom_do
);

-- cs54xx program ROM
--cs54xx_prog : entity work.dpram generic map (10,8)
--port map
--(
--	clock_a   => clock_18,
--	wren_a    => rom54_wren,
--	address_a => dn_addr(9 downto 0),
--	data_a    => dn_data,
--
--	clock_b   => clock_18n,
--	address_b => cs54xx_rom_addr(9 downto 0),
--	q_b       => cs54xx_rom_do
--);

cs54xx_prog : entity work.n54xx
port map(
	clk   => clock_18n,
	addr => cs54xx_rom_addr(9 downto 0),
	data       => cs54xx_rom_do
);
--------------------------------------------------------------------------------
-- mb88 - cs52xx (42 pins IC, 1024 bytes rom)
--------------------------------------------------------------------------------

-- TODO: Not sure whether this clocking is accurate.
-- The division by 32 for the timer is a guess, originally made by MAME
cs52xx_timer_ena <= '1' when cs52xx_timer_ena_div = "00000" else '0';

cs52xx_k_port_in <= cs52xx_control(3 downto 0);

mb88_52xx : entity work.mb88
port map(
 reset_n    => reset_video_5Xxx_n,
 clock      => clock_18,
 ena        => cs52xx_ena,
 ena_timer  => cs52xx_timer_ena,

 r0_port_in  => romvoice_do(3 downto 0), -- pin 22,23,24,25 (r) - sample ROM data in, bits 0-3
 r1_port_in  => romvoice_do(7 downto 4), -- pin 26,27,28,29 (r) -                  ", bits 4-7
 r2_port_in  => X"0", -- not used        -- pin 30,31,32,33 (r)
 r3_port_in  => X"0", -- not used        -- pin 34,35,36,37 (r)

 r0_port_out => open, -- not used        -- pin 22,23,24,25 (w)
 r1_port_out => open, -- not used        -- pin 26,27,28,29 (w)
 r2_port_out => cs52xx_r2_port_out,      -- pin 30,31,32,33 (w) - sample ROM addr out, bits 0-3
 r3_port_out => cs52xx_r3_port_out,      -- pin 34,35,36,37 (w)                     ", bits 4-7

 k_port_in   => cs52xx_k_port_in,        -- pin 38,39,40,41 - command from CPU via 06xx_1
 ol_port_out => cs52xx_ol_port_out,      -- pin 13,14,15,16 - sample rom addr out, bits  8-11
 oh_port_out => cs52xx_oh_port_out,      -- pin 17,18,19,20 - sample rom addr out, bits 12-15
 p_port_out  => cs52xx_audio,

 stby_n    => '0',
 tc_n      => cs52xx_555,   -- pin 8 - in Bosconian, the output of a 555 timer; in Pole Position, '0'
 irq_n     => cs52xx_irq_n, -- pin 4
 sc_in_n   => '0',          -- pin 7
 si_n      => '0',          -- pin 6 - '0' in Bosconian, '1' in Pole Position
 sc_out_n  => open,         -- pin 7
 so_n      => open,         -- pin 5
 to_n      => open,         -- pin 7

 rom_addr  => cs52xx_rom_addr,
 rom_data  => cs52xx_rom_do
);

-- In Bosconian, 52xx's tc_n is given the output of the following 555 timer:
-- R1 = 33 kohm   R2 = 10 kohm   C = 0.0047 uF
-- This corresponds to 140.055 usec on, 32.571 usec off.
-- We can approximate this with a clock divider.
-- However! It appears that the MB88 inside Bosconian's 52xx is actually just using
-- a pio flag set of 0xA2, which corresponds to using ONLY the internal timer. If that
-- is correct, this timer is here on the board, oscillating, but not actually used!
process (clock_18)
begin
	if rising_edge(clock_18) then
		cs52xx_555_cnt <= cs52xx_555_cnt + 1;
		if cs52xx_555_cnt = 600 then
			cs52xx_555 <= '1';
		elsif cs52xx_555_cnt = 3181 then
			cs52xx_555 <= '0';
			cs52xx_555_cnt <= to_unsigned(0,12);
		end if;
	end if;
end process;

-- cs52xx program ROM
--cs52xx_prog : entity work.dpram generic map (10,8)
--port map
--(
--	clock_a   => clock_18,
--	wren_a    => rom52_wren,
--	address_a => dn_addr(9 downto 0),
--	data_a    => dn_data,
--
--	clock_b   => clock_18n,
--	address_b => cs52xx_rom_addr(9 downto 0),
--	q_b       => cs52xx_rom_do
--);

cs52xx_prog : entity work.n52xx
port map(
	clk   => clock_18n,
	addr => cs52xx_rom_addr(9 downto 0),
	data  => cs52xx_rom_do
);

-- cs52xx data (digitized speech) ROMs
--romvoice0 : entity work.dpram generic map (12,8)
--port map
--(
--	clock_a   => clock_18,
--	wren_a    => romvoice0_wren,
--	address_a => dn_addr(11 downto 0),
--	data_a    => dn_data,
--
--	clock_b   => clock_18n,
--	address_b => romvoice_addr(11 downto 0),
--	q_b       => romvoice0_do
--);
--romvoice1 : entity work.dpram generic map (12,8)
--port map
--(
--	clock_a   => clock_18,
--	wren_a    => romvoice1_wren,
--	address_a => dn_addr(11 downto 0),
--	data_a    => dn_data,
--
--	clock_b   => clock_18n,
--	address_b => romvoice_addr(11 downto 0),
--	q_b       => romvoice1_do
--);
--romvoice2 : entity work.dpram generic map (12,8)
--port map
--(
--	clock_a   => clock_18,
--	wren_a    => romvoice2_wren,
--	address_a => dn_addr(11 downto 0),
--	data_a    => dn_data,
--
--	clock_b   => clock_18n,
--	address_b => romvoice_addr(11 downto 0),
--	q_b       => romvoice2_do
--);

romvoice_addr <= cs52xx_ol_port_out & cs52xx_r3_port_out & cs52xx_r2_port_out;

-- In Bosconian, address lines 15-12 (52xx pins 17-20) are direct active-low chip enables.
-- (In Pole Position, they are the upper bits of the address instead.)
romvoice0_cs_n <= cs52xx_oh_port_out(0);
romvoice1_cs_n <= cs52xx_oh_port_out(1);
romvoice2_cs_n <= cs52xx_oh_port_out(2);

romvoice_do <=
    romvoice0_do when romvoice0_cs_n = '0' else
    romvoice1_do when romvoice1_cs_n = '0' else
    romvoice2_do when romvoice2_cs_n = '0' else
    X"00";

-- Audio low pass filters. Sample rate of 46 875 Mhz has enough resolution for 0.001 MF capacitance

-- cs54xx audio1 low pass filter
cs54xx_lpf1_audio_in <= "00" & cs54xx_audio_1 & "0000";
cs54xx_lpf1 : entity work.lpf
port map(
	clock      => clock_18,
	reset      => reset,
	div        => 384, -- 18 MHz/384 = 46875 Hz
	audio_in   => cs54xx_lpf1_audio_in,
	gain_in    => 1,
	r1         => 150000,
	r2         => 22000,
	dt_over_c3 => 2133, -- 1/46875Hz/0.01e-6F
	dt_over_c4 => 2133, -- 1/46875Hz/0.01e-6F
	r5         => 470000,
	audio_out  => cs54xx_audio_1_lpf
);

-- cs54xx audio2 low pass filter
cs54xx_lpf2_audio_in <= "00" & cs54xx_audio_2 & "0000";
cs54xx_lpf2 : entity work.lpf
port map(
	clock      => clock_18,
	reset      => reset,
	div        => 384,
	audio_in   => cs54xx_lpf2_audio_in,
	gain_in    => 1,
	r1         => 47000,
	r2         => 10000,
	dt_over_c3 => 2133, -- 1/46875Hz/0.01e-6F
	dt_over_c4 => 2133, -- 1/46875Hz/0.01e-6F
	r5         => 150000,
	audio_out  => cs54xx_audio_2_lpf
);

-- cs54xx audio3 low pass filter
cs54xx_lpf3_audio_in <= "00" & cs54xx_audio_3 & "0000";
cs54xx_lpf3 : entity work.lpf
port map(
	clock      => clock_18,
	reset      => reset,
	div        => 384,
	audio_in   => cs54xx_lpf3_audio_in,
	gain_in    => 1,
	r1         => 100000,
	r2         => 22000,
	dt_over_c3 => 21333, -- 1/46875Hz/0.001e-6F
	dt_over_c4 => 21333, -- 1/46875Hz/0.001e-6F
	r5         => 220000,
	audio_out  => cs54xx_audio_3_lpf
);

-- CPU Program ROMs
--rom1_wren      <= '1' when dn_wr = '1' and dn_addr(15 downto 14) = "00"       else '0';
--rom2_wren      <= '1' when dn_wr = '1' and dn_addr(15 downto 13) = "010"      else '0';
--rom3_wren      <= '1' when dn_wr = '1' and dn_addr(15 downto 12) = "0110"     else '0';
---- Namco Character/Sprite Layout ROMs
--romchar_wren   <= '1' when dn_wr = '1' and dn_addr(15 downto 12) = "0111"     else '0';
--romsprite_wren <= '1' when dn_wr = '1' and dn_addr(15 downto 12) = "1000"     else '0';
---- ROMs for digitized speech; used by 52xx
--romvoice0_wren <= '1' when dn_wr = '1' and dn_addr(15 downto 12) = "1010"     else '0';
--romvoice1_wren <= '1' when dn_wr = '1' and dn_addr(15 downto 12) = "1011"     else '0';
--romvoice2_wren <= '1' when dn_wr = '1' and dn_addr(15 downto 12) = "1100"     else '0';
---- Namco custom MCU ROMs
--rom50_wren     <= '1' when dn_wr = '1' and dn_addr(15 downto 11) = "11010"    else '0';
--rom51_wren     <= '1' when dn_wr = '1' and dn_addr(15 downto 10) = "110110"   else '0';
--rom52_wren     <= '1' when dn_wr = '1' and dn_addr(15 downto 10) = "110111"   else '0';
--rom54_wren     <= '1' when dn_wr = '1' and dn_addr(15 downto 10) = "111000"   else '0';
---- Color lookup table PROM
--romcolor_wren  <= '1' when dn_wr = '1' and dn_addr(15 downto  8) = "11100100" else '0';
---- Radar layout ROM
--romradar_wren  <= '1' when dn_wr = '1' and dn_addr(15 downto  8) = "11100101" else '0';

-- cpu1 program ROM
--rom_cpu1 : entity work.dpram generic map (14,8)
--port map
--(
--	clock_a   => clock_18,
--	wren_a    => rom1_wren,
--	address_a => dn_addr(13 downto 0),
--	data_a    => dn_data,
--
--	clock_b   => clock_18n,
--	address_b => mux_addr(13 downto 0),
--	q_b       => cpu1_rom_do
--);

cpu1_rom_addr <= mux_addr(13 downto 0);

-- cpu2 program ROM
--rom_cpu2 : entity work.dpram generic map (13,8)
--port map
--(
--	clock_a   => clock_18,
--	wren_a    => rom2_wren,
--	address_a => dn_addr(12 downto 0),
--	data_a    => dn_data,
--
--	clock_b   => clock_18n,
--	address_b => mux_addr(12 downto 0),
--	q_b       => cpu2_rom_do
--);

cpu2_rom_addr <= mux_addr(12 downto 0);

-- cpu3 program ROM
--rom_cpu3 : entity work.dpram generic map (12,8)
--port map
--(
--	clock_a   => clock_18,
--	wren_a    => rom3_wren,
--	address_a => dn_addr(11 downto 0),
--	data_a    => dn_data,
--
--	clock_b   => clock_18n,
--	address_b => mux_addr(11 downto 0),
--	q_b       => cpu3_rom_do
--);

cpu3_rom_addr <= mux_addr(11 downto 0);

-- Tilemap RAM 1: tile code (1st half is radar + sprite registers; 2nd half is scrolling playfield)
bgram1 : entity work.gen_ram
generic map(aWidth => 11, dWidth => 8)
port map(
	clk  => clock_18n,
	we   => bgram1_we,
	addr => mux_addr(10 downto 0),
	d    => mux_cpu_do,
	q    => bgram1_do
);

-- Tilemap RAM 2: tile attribute (1st half is radar + sprite registers; 2nd half is scrolling playfield)
bgram2 : entity work.gen_ram
generic map(aWidth => 11, dWidth => 8)
port map(
	clk  => clock_18n,
	we   => bgram2_we,
	addr => mux_addr(10 downto 0),
	d    => mux_cpu_do,
	q    => bgram2_do
);

---------------------------------------------------------------------------
-- Small Object Registers
---------------------------------------------------------------------------

-- "Small objects" = bullets and radar dots.

-- 2E: 7489 RAM - 4-bit address, 4-bit data
-- Stores small-object shape (top 3 bits) and X pos msb.
-- On original hardware, this RAM has inverted outputs.
soram : entity work.gen_ram
generic map(aWidth => 4, dWidth => 4)
port map(
	clk  => clock_18n,
	we   => soram_we,
	addr => mux_addr(3 downto 0),
	d    => mux_cpu_do(3 downto 0),
	q    => soram_do
);
soram_do_n <= std_ulogic_vector(not soram_do);


-- shared work RAM 1 - 0x7800-0x7FFF - called "share1" in MAME implementation
wram : entity work.gen_ram
generic map(aWidth => 11, dWidth => 8)
port map(
	clk  => clock_18n,
	we   => wram_we,
	addr => mux_addr(10 downto 0),
	d    => mux_cpu_do,
	q    => wram_do
);

end struct;
