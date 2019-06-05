---------------------------------------------------------------------------------
-- DE10_lite Top level for Traverse USA by Dar (darfpga@aol.fr) (16/03/2019)
-- http://darfpga.blogspot.fr
---------------------------------------------------------------------------------
-- Educational use only
-- Do not redistribute synthetized file with roms
-- Do not redistribute roms whatever the form
-- Use at your own risk
---------------------------------------------------------------------------------
-- Use traverse_usa_de10_lite.sdc to compile (Timequest constraints)
-- /!\
-- Don't forget to set device configuration mode with memory initialization 
--  (Assignments/Device/Pin options/Configuration mode)
---------------------------------------------------------------------------------
--
-- Main features :
--  PS2 keyboard input @gpio pins 35/34 (beware voltage translation/protection) 
--  Audio pwm output   @gpio pins 1/3 (beware voltage translation/protection) 
--
--  Video         : 15Khz only atm
--  Cocktail mode : OK
--  Sound         : OK
-- 
-- For hardware schematic see my other project : NES.
--
-- Uses 1 pll for 36MHz and 3.58MHz generation from 50MHz
--
--
-- Board key :
--   0 : reset game
--
-- Keyboard players inputs :
--
--   F3 : Add coin
--   F2 : Start 2 players
--   F1 : Start 1 player
--   SPACE       : Fire  
--   RIGHT arrow : turn right
--   LEFT  arrow : turn left
--   UP    arrow : speed up 
--   DOWN  arrow : speed down
--
-- Other details : see traverse_usa.vhd
-- For USB inputs and SGT5000 audio output see my other project: xevious_de10_lite
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
--use work.usb_report_pkg.all;

entity traverse_usa_de10_lite is
port(
 max10_clk1_50  : in std_logic;
-- max10_clk2_50  : in std_logic;
-- adc_clk_10     : in std_logic;
 ledr           : out std_logic_vector(9 downto 0);
 key            : in std_logic_vector(1 downto 0);
 sw             : in std_logic_vector(9 downto 0);

-- dram_ba    : out std_logic_vector(1 downto 0);
-- dram_ldqm  : out std_logic;
-- dram_udqm  : out std_logic;
-- dram_ras_n : out std_logic;
-- dram_cas_n : out std_logic;
-- dram_cke   : out std_logic;
-- dram_clk   : out std_logic;
-- dram_we_n  : out std_logic;
-- dram_cs_n  : out std_logic;
-- dram_dq    : inout std_logic_vector(15 downto 0);
-- dram_addr  : out std_logic_vector(12 downto 0);

 hex0 : out std_logic_vector(7 downto 0);
 hex1 : out std_logic_vector(7 downto 0);
 hex2 : out std_logic_vector(7 downto 0);
 hex3 : out std_logic_vector(7 downto 0);
-- hex4 : out std_logic_vector(7 downto 0);
-- hex5 : out std_logic_vector(7 downto 0);

 vga_r     : out std_logic_vector(3 downto 0);
 vga_g     : out std_logic_vector(3 downto 0);
 vga_b     : out std_logic_vector(3 downto 0);
 vga_hs    : out std_logic;
 vga_vs    : out std_logic;
 
-- gsensor_cs_n : out   std_logic;
-- gsensor_int  : in    std_logic_vector(2 downto 0); 
-- gsensor_sdi  : inout std_logic;
-- gsensor_sdo  : inout std_logic;
-- gsensor_sclk : out   std_logic;

-- arduino_io      : inout std_logic_vector(15 downto 0); 
-- arduino_reset_n : inout std_logic;
 
 gpio          : inout std_logic_vector(35 downto 0)
);
end traverse_usa_de10_lite;

architecture struct of traverse_usa_de10_lite is

 signal clock_36  : std_logic;
 signal clock_6   : std_logic;
 signal clock_3p58: std_logic;
 signal reset     : std_logic;
 
 signal clock_div : std_logic_vector(2 downto 0);
 
-- signal max3421e_clk : std_logic;
 
 signal r         : std_logic_vector(1 downto 0);
 signal g         : std_logic_vector(2 downto 0);
 signal b         : std_logic_vector(2 downto 0);
 signal csync     : std_logic;
 signal blankn    : std_logic;
 
 signal audio           : std_logic_vector(10 downto 0);
 signal pwm_accumulator : std_logic_vector(12 downto 0);

 alias reset_n         : std_logic is key(0);
 alias ps2_clk         : std_logic is gpio(35); --gpio(0);
 alias ps2_dat         : std_logic is gpio(34); --gpio(1);
 alias pwm_audio_out_l : std_logic is gpio(1);  --gpio(2);
 alias pwm_audio_out_r : std_logic is gpio(3);  --gpio(3);
 
 signal kbd_intr      : std_logic;
 signal kbd_scancode  : std_logic_vector(7 downto 0);
 signal joyPCFRLDU : std_logic_vector(7 downto 0);
-- signal keys_HUA      : std_logic_vector(2 downto 0);

-- signal start : std_logic := '0';
-- signal usb_report : usb_report_t;
-- signal new_usb_report : std_logic := '0';
  
signal dbg_cpu_addr : std_logic_vector(15 downto 0);

begin

reset <= not reset_n;

-- tv15Khz_mode <= sw();

--arduino_io not used pins
--arduino_io(7) <= '1'; -- to usb host shield max3421e RESET
--arduino_io(8) <= 'Z'; -- from usb host shield max3421e GPX
--arduino_io(9) <= 'Z'; -- from usb host shield max3421e INT
--arduino_io(13) <= 'Z'; -- not used
--arduino_io(14) <= 'Z'; -- not used

-- Clock 36MHz for traverse_usa core, 3.58MHz for sound_board
clocks : entity work.max10_pll_36p86M_3p58M
port map(
 inclk0 => max10_clk1_50,
 c0 => clock_36,
 c1 => clock_3p58,
 locked => open --pll_locked
);

-- Traverse_usa
traverse_usa : entity work.traverse_usa
port map(
 clock_36   => clock_36,
 clock_3p58 => clock_3p58,
 reset      => reset,
 
-- tv15Khz_mode => tv15Khz_mode,
 video_r      => r,
 video_g      => g,
 video_b      => b,
 video_csync  => csync,
 video_blankn => blankn,
 video_hs     => open, --hsync, -- not tested
 video_vs     => open, --vsync, -- not tested
 audio_out    => audio,
 
 dip_switch_1  => x"FF",  -- Coinage_B(7-4) / Cont. play(3) / Fuel consumption(2) / Fuel lost when collision (1-0)
 dip_switch_2  => x"FE",  -- Diag(7) / Demo(6) / Zippy(5) / Freeze (4) / M-Km(3) / Coin mode (2) / Cocktail(1) / Flip(0)
 
 start2      => joyPCFRLDU(7),
 start1      => joyPCFRLDU(6),
 coin1       => joyPCFRLDU(5),
 
-- fire1       => joyPCFRLDU(4),
 right1      => joyPCFRLDU(3),
 left1       => joyPCFRLDU(2),
 brake1      => joyPCFRLDU(1),
 accel1      => joyPCFRLDU(0),

-- fire2       => joyPCFRLDU(4),
 right2      => joyPCFRLDU(3),
 left2       => joyPCFRLDU(2),
 brake2      => joyPCFRLDU(1),
 accel2      => joyPCFRLDU(0),

 dbg_cpu_addr => dbg_cpu_addr
);

-- adapt video to 4bits/color only
vga_r <= r&"00" when blankn = '1' else "0000";
vga_g <= g&'0'  when blankn = '1' else "0000";
vga_b <= b&'0'  when blankn = '1' else "0000";

-- synchro composite/ synchro horizontale
vga_hs <= csync;
-- vga_hs <= csync when tv15Khz_mode = '1' else hsync;
-- commutation rapide / synchro verticale
vga_vs <= '1';
-- vga_vs <= '1'   when tv15Khz_mode = '1' else vsync;

--sound_string <= "00" & audio & "000" & "00" & audio & "000";

-- get scancode from keyboard
process (reset, clock_36)
begin
	if reset='1' then
		clock_div <= "000";
		clock_6  <= '0';
	else 
		if rising_edge(clock_36) then
			if clock_div = "101" then
				clock_div <= "000";
				clock_6  <= not clock_6;
			else
				clock_div <= clock_div + '1';			
			end if;
		end if;
	end if;
end process;

keyboard : entity work.io_ps2_keyboard
port map (
  clk       => clock_6, -- synchrounous clock with core
  kbd_clk   => ps2_clk,
  kbd_dat   => ps2_dat,
  interrupt => kbd_intr,
  scancode  => kbd_scancode
);

-- translate scancode to joystick
joystick : entity work.kbd_joystick
port map (
  clk           => clock_6, -- synchrounous clock with core
  kbdint        => kbd_intr,
  kbdscancode   => std_logic_vector(kbd_scancode), 
  joyPCFRLDU => joyPCFRLDU
);

-- usb host for max3421e arduino shield (modified)

--max3421e_clk <= clock_11;
--usb_host : entity work.usb_host_max3421e
--port map(
-- clk     => max3421e_clk,
-- reset   => reset,
-- start   => start,
-- 
-- usb_report => usb_report,
-- new_usb_report => new_usb_report,
-- 
-- spi_cs_n  => arduino_io(10), 
-- spi_clk   => arduino_io(13),
-- spi_mosi  => arduino_io(11),
-- spi_miso  => arduino_io(12)
--);

-- usb keyboard report decoder

--keyboard_decoder : entity work.usb_keyboard_decoder
--port map(
-- clk     => max3421e_clk,
-- 
-- usb_report => usb_report,
-- new_usb_report => new_usb_report,
-- 
-- joyBCPPFRLDU  => joyBCPPFRLDU
--);

-- usb joystick decoder (konix drakkar wireless)

--joystick_decoder : entity work.usb_joystick_decoder
--port map(
-- clk     => max3421e_clk,
-- 
-- usb_report => usb_report,
-- new_usb_report => new_usb_report,
-- 
-- joyBCPPFRLDU  => open --joyBCPPFRLDU
--);

-- debug display

--ledr(8 downto 0) <= joyBCPPFRLDU;
--
h0 : entity work.decodeur_7_seg port map(dbg_cpu_addr( 3 downto  0),hex0);
h1 : entity work.decodeur_7_seg port map(dbg_cpu_addr( 7 downto  4),hex1);
h2 : entity work.decodeur_7_seg port map(dbg_cpu_addr(11 downto  8),hex2);
h3 : entity work.decodeur_7_seg port map(dbg_cpu_addr(15 downto 12),hex3);
--h4 : entity work.decodeur_7_seg port map(usb_report(to_integer(unsigned(sw))+0)(3 downto 0),hex4);
--h5 : entity work.decodeur_7_seg port map(usb_report(to_integer(unsigned(sw))+0)(7 downto 4),hex5);

-- audio for sgtl5000 

--sample_data <= "00" & audio & "000" & "00" & audio & "000";				

-- Clock 1us for ym_8910

--p_clk_1us_p : process(max10_clk1_50)
--begin
--	if rising_edge(max10_clk1_50) then
--		if cnt_1us = 0 then
--			cnt_1us  <= 49;
--			clk_1us  <= '1'; 
--		else
--			cnt_1us  <= cnt_1us - 1;
--			clk_1us <= '0'; 
--		end if;
--	end if;	
--end process;	 

-- sgtl5000 (teensy audio shield on top of usb host shield)

--e_sgtl5000 : entity work.sgtl5000_dac
--port map(
-- clock_18   => clock_18,
-- reset      => reset,
-- i2c_clock  => clk_1us,  
--
-- sample_data  => sample_data,
-- 
-- i2c_sda   => arduino_io(0), -- i2c_sda, 
-- i2c_scl   => arduino_io(1), -- i2c_scl, 
--
-- tx_data   => arduino_io(2), -- sgtl5000 tx
-- mclk      => arduino_io(4), -- sgtl5000 mclk 
-- 
-- lrclk     => arduino_io(3), -- sgtl5000 lrclk
-- bclk      => arduino_io(6), -- sgtl5000 bclk   
-- 
-- -- debug
-- hex0_di   => open, -- hex0_di,
-- hex1_di   => open, -- hex1_di,
-- hex2_di   => open, -- hex2_di,
-- hex3_di   => open, -- hex3_di,
-- 
-- sw => sw(7 downto 0)
--);

-- pwm sound output

process(clock_3p58)  -- use same clock as pooyan_sound_board
begin
  if rising_edge(clock_3p58) then
    pwm_accumulator  <=  std_logic_vector(unsigned('0' & pwm_accumulator(11 downto 0)) + unsigned(audio & "00"));
  end if;
end process;

pwm_audio_out_l <= pwm_accumulator(12);
pwm_audio_out_r <= pwm_accumulator(12); 


end struct;
