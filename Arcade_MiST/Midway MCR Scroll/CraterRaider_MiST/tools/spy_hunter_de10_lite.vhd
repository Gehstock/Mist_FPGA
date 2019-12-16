---------------------------------------------------------------------------------
-- DE10_lite Top level for Spy hunter (Midway MCR) by Dar (darfpga@aol.fr) (06/12/2019)
-- http://darfpga.blogspot.fr
---------------------------------------------------------------------------------
--
-- release rev 00 : initial release
--  (06/12/2019)
--
--   fit de10_lite OK : 
--     - use sdram loader to load sprites data first then load spy hunter core

---------------------------------------------------------------------------------
-- Educational use only
-- Do not redistribute synthetized file with roms
-- Do not redistribute roms whatever the form
-- Use at your own risk
---------------------------------------------------------------------------------
-- Use spy_hunter_de10_lite.sdc to compile (Timequest constraints)
-- /!\
-- Don't forget to set device configuration mode with memory initialization 
--  (Assignments/Device/Pin options/Configuration mode)
---------------------------------------------------------------------------------
--
-- Main features :
--  PS2 keyboard input @gpio pins 35/34 (beware voltage translation/protection) 
--  Audio pwm output   @gpio pins 1/3 (beware voltage translation/protection) 
--
--  Video         : VGA 31kHz/60Hz progressive and TV 15kHz interlaced
--  Cocktail mode : NO
--  Sound         : OK - missing Chip/cheap squeak deluxe board
-- 
-- For hardware schematic see my other project : NES
--
-- Uses 1 pll 40MHz from 50MHz to make 20MHz and 8Mhz 
--
-- Board key :
--   0 : reset game
--
-- Keyboard players inputs :
--
--   F1 : Add coin
--   F3 : toggle lamp text display on screen
--   F4 : Demo sound
--   F5 : Separate audio
--   F7 : Service mode
--   F8 : 15kHz interlaced / 31 kHz progressive

--   F2     : toggle hi/low gear shift
--   SPACE  : oil
--   f key  : missile
--   g key  : van
--   t key  : smoke
--   v key  : gun

--   RIGHT arrow : turn right side (auto center when released)
--   LEFT  arrow : tirn left side (auto center when released)
--   UP    arrow : gas increase
--   DOWN  arrow : gas decrease
--
-- Other details : see timber.vhd
-- For USB inputs and SGT5000 audio output see my other project: xevious_de10_lite
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
--use work.usb_report_pkg.all;

entity spy_hunter_de10_lite is
port(
 max10_clk1_50  : in std_logic;
-- max10_clk2_50  : in std_logic;
-- adc_clk_10     : in std_logic;
 ledr           : out std_logic_vector(9 downto 0);
 key            : in std_logic_vector(1 downto 0);
 sw             : in std_logic_vector(9 downto 0);

 dram_ba    : out std_logic_vector(1 downto 0);
 dram_ldqm  : out std_logic;
 dram_udqm  : out std_logic;
 dram_ras_n : out std_logic;
 dram_cas_n : out std_logic;
 dram_cke   : out std_logic;
 dram_clk   : out std_logic;
 dram_we_n  : out std_logic;
 dram_cs_n  : out std_logic;
 dram_dq    : inout std_logic_vector(15 downto 0);
 dram_addr  : out std_logic_vector(12 downto 0);

 hex0 : out std_logic_vector(7 downto 0);
 hex1 : out std_logic_vector(7 downto 0);
 hex2 : out std_logic_vector(7 downto 0);
 hex3 : out std_logic_vector(7 downto 0);
 hex4 : out std_logic_vector(7 downto 0);
 hex5 : out std_logic_vector(7 downto 0);

 vga_r     : out std_logic_vector(3 downto 0);
 vga_g     : out std_logic_vector(3 downto 0);
 vga_b     : out std_logic_vector(3 downto 0);
 vga_hs    : inout std_logic;
 vga_vs    : inout std_logic;
 
-- gsensor_cs_n : out   std_logic;
-- gsensor_int  : in    std_logic_vector(2 downto 0); 
-- gsensor_sdi  : inout std_logic;
-- gsensor_sdo  : inout std_logic;
-- gsensor_sclk : out   std_logic;

-- arduino_io      : inout std_logic_vector(15 downto 0); 
-- arduino_reset_n : inout std_logic;
 
 gpio          : inout std_logic_vector(35 downto 0)
);
end spy_hunter_de10_lite;

architecture struct of spy_hunter_de10_lite is

component sdram is
port (

 sd_data : inout std_logic_vector(15 downto 0);
 sd_addr : out   std_logic_vector(12 downto 0);
 sd_dqm  : out   std_logic_vector(1 downto 0);
 sd_ba   : out   std_logic_vector(1 downto 0);
 sd_cs   : out   std_logic;
 sd_we   : out   std_logic;
 sd_ras  : out   std_logic;
 sd_cas  : out   std_logic;

 init    : in std_logic;
 clk     : in std_logic;
	
 addr    : in std_logic_vector(24 downto 0);
 
 we      : in std_logic;
 di      : in std_logic_vector(7 downto 0);
 
 rd      : in std_logic;	
 sm_cycle: out std_logic_vector( 4 downto 0)
 
); end component sdram;

 signal pll_locked: std_logic;
 signal clock_40  : std_logic;
 signal clock_kbd : std_logic;
 signal reset     : std_logic;
 
 signal clock_div : std_logic_vector(3 downto 0);
 
 signal clock_120       : std_logic;
 signal clock_120_sdram : std_logic; -- (-2ns w.r.t clock_120)
 signal dram_dqm        : std_logic_vector(1 downto 0);

-- signal max3421e_clk : std_logic;
 
 signal r         : std_logic_vector(2 downto 0);
 signal g         : std_logic_vector(2 downto 0);
 signal b         : std_logic_vector(2 downto 0);
 signal hsync     : std_logic;
 signal vsync     : std_logic;
 signal csync     : std_logic;
 signal blankn    : std_logic;
 signal tv15Khz_mode : std_logic;
 
 signal audio_l           : std_logic_vector(15 downto 0);
 signal audio_r           : std_logic_vector(15 downto 0);
 signal pwm_accumulator_l : std_logic_vector(17 downto 0);
 signal pwm_accumulator_r : std_logic_vector(17 downto 0);

 alias reset_n         : std_logic is key(0);
 alias ps2_clk         : std_logic is gpio(35); --gpio(0);
 alias ps2_dat         : std_logic is gpio(34); --gpio(1);
 alias pwm_audio_out_l : std_logic is gpio(1);  --gpio(2);
 alias pwm_audio_out_r : std_logic is gpio(3);  --gpio(3);
 
 signal kbd_intr       : std_logic;
 signal kbd_scancode   : std_logic_vector(7 downto 0);
 signal joy_BBBBFRLDU  : std_logic_vector(8 downto 0);
 signal fn_pulse       : std_logic_vector(7 downto 0);
 signal fn_toggle      : std_logic_vector(7 downto 0);

 signal vsync_r        : std_logic;
 
 signal sp_rom_addr    : std_logic_vector(17 downto 0);
 signal sp_rom_rd      : std_logic;
 
 signal sp_rom_cycle : std_logic_vector( 4 downto 0);
 signal sp_rom_data  : std_logic_vector(15 downto 0);
 signal sp_graphx0   : std_logic_vector(31 downto 0);
 signal sp_graphx1   : std_logic_vector(31 downto 0);
 signal sp_graphx2   : std_logic_vector(31 downto 0);
 signal sp_graphx3   : std_logic_vector(31 downto 0);

 signal steering         : std_logic_vector(7 downto 0);
 signal steering_plus    : std_logic;
 signal steering_plus_r  : std_logic;
 signal steering_minus   : std_logic;
 signal steering_minus_r : std_logic;
 signal steering_timer   : std_logic_vector(5 downto 0);
 
 signal gas         : std_logic_vector(7 downto 0);
 signal gas_plus    : std_logic;
 signal gas_plus_r  : std_logic;
 signal gas_minus   : std_logic;
 signal gas_minus_r : std_logic;
 signal gas_timer   : std_logic_vector(5 downto 0);
 
-- signal start : std_logic := '0';
-- signal usb_report : usb_report_t;
-- signal new_usb_report : std_logic := '0';
  
signal dbg_cpu_addr : std_logic_vector(15 downto 0);

begin

reset <= not reset_n;

tv15Khz_mode <= not fn_toggle(7); -- F8

--arduino_io not used pins
--arduino_io(7) <= '1'; -- to usb host shield max3421e RESET
--arduino_io(8) <= 'Z'; -- from usb host shield max3421e GPX
--arduino_io(9) <= 'Z'; -- from usb host shield max3421e INT
--arduino_io(13) <= 'Z'; -- not used
--arduino_io(14) <= 'Z'; -- not used

-- Clock 40MHz for kick core and sound_board
--clocks : entity work.max10_pll_40M
--port map(
-- inclk0 => max10_clk1_50,
-- c0 => clock_40,
-- locked => pll_locked
--);

clocks : entity work.max10_pll_120M_sdram
port map(
 inclk0 => max10_clk1_50,
 c0 => clock_120,
 c1 => clock_120_sdram,
 c2 => clock_40,
 locked => pll_locked
);

-- Timber
spy_hunter : entity work.spy_hunter
port map(
 clock_40   => clock_40,
 reset      => reset,
 
 tv15Khz_mode => tv15Khz_mode,
 video_r      => r,
 video_g      => g,
 video_b      => b,
 video_csync  => csync,
 video_blankn => blankn,
 video_hs     => hsync,
 video_vs     => vsync,
 
 separate_audio => fn_toggle(4), -- F5
 audio_out_l    => audio_l,
 audio_out_r    => audio_r,
   
 coin1          => fn_pulse(0), -- F1
 coin2          => '0',

 shift          => fn_toggle(1),     -- F2
 oil            => joy_BBBBFRLDU(4), -- space
 missile        => joy_BBBBFRLDU(5), -- f
 van            => joy_BBBBFRLDU(6), -- g
 smoke          => joy_BBBBFRLDU(7), -- t
 gun            => joy_BBBBFRLDU(8), -- v
 
-- lamp_oil       => ledr(0),
-- lamp_missile   => ledr(1),
-- lamp_van       => ledr(2),
-- lamp_smoke     => ledr(3),
-- lamp_gun       => ledr(4),
 show_lamps     => fn_toggle(2), -- F3
 
 steering       => steering,
 gas            => gas,

 timer          => '1',
 demo_sound     => fn_toggle(3), -- F4
 service        => fn_toggle(6), -- F7 -- (allow machine settings access)
 
 -- external sprite roms
 sp_rom_addr   => sp_rom_addr, -- highest bit tell direct or reverse order
 sp_rom_rd     => sp_rom_rd,   -- read trigger should last enough for sdram.v
 
-- External (sd)ram has 4cycles @ 40MHz = 100ns to deliver sp_rom_data_0
-- then sp_rom_data_1 4 cycles later and so on.
-- Code may be adapted to slower ram with the risk of having not all sprites
-- displayed.
--
-- direct ordrer :
-- sp_graphx0, bytes# 1 of rom1 & rom2 & rom3 & rom4 
-- sp_graphx1, bytes# 2 of rom1 & rom2 & rom3 & rom4 
-- sp_graphx2, bytes# 3 of rom1 & rom2 & rom3 & rom4 
-- sp_graphx3, bytes# 4 of rom1 & rom2 & rom3 & rom4 

-- reverse ordrer :
-- sp_graphx0, bytes# 4 of rom4 & rom3 & rom2 & rom1 
-- sp_graphx1, bytes# 3 of rom4 & rom3 & rom2 & rom1 
-- sp_graphx2, bytes# 2 of rom4 & rom3 & rom2 & rom1 
-- sp_graphx3, bytes# 1 of rom4 & rom3 & rom2 & rom1 
 
 sp_graphx0 => sp_graphx0,
 sp_graphx1 => sp_graphx1,
 sp_graphx2 => sp_graphx2,
 sp_graphx3 => sp_graphx3,
   
 dbg_cpu_addr => dbg_cpu_addr
);

dram_ldqm <= dram_dqm(0); 
dram_udqm <= dram_dqm(1);
dram_cke  <= '1';
dram_clk  <= clock_120_sdram;

sdram_if : sdram
port map(
   -- sdram interface
	sd_data => dram_dq,    -- 16 bit bidirectional data bus
	sd_addr => dram_addr,  -- 13 bit multiplexed address bus
	sd_dqm  => dram_dqm,   -- two byte masks
	sd_ba   => dram_ba,    -- two banks
	sd_cs   => dram_cs_n,  -- a single chip select
	sd_we   => dram_we_n,  -- write enable
	sd_ras  => dram_ras_n, -- row address select
	sd_cas  => dram_cas_n, -- columns address select

	-- cpu/chipset interface
	init     => not pll_locked, -- init signal after FPGA config to initialize RAM
	clk      => clock_120,	    -- sdram is accessed at up to 128MHz
	
	addr     => "0000000"& sp_rom_addr, -- 25 bit byte address
	
	we       => '0',         -- requests write
	di       => x"FF",       -- data input
	
	rd       => sp_rom_rd,   -- requests data
	sm_cycle => sp_rom_cycle -- state machine cycle
);

process (clock_120)
begin
	if falling_edge(clock_120) then
		sp_rom_data <= dram_dq;		
		if sp_rom_cycle =  8 then sp_graphx0(31 downto 16) <= sp_rom_data; end if;
		if sp_rom_cycle =  9 then sp_graphx0(15 downto  0) <= sp_rom_data; end if;
		if sp_rom_cycle = 10 then sp_graphx1(31 downto 16) <= sp_rom_data; end if;
		if sp_rom_cycle = 11 then sp_graphx1(15 downto  0) <= sp_rom_data; end if;
		if sp_rom_cycle = 12 then sp_graphx2(31 downto 16) <= sp_rom_data; end if;
		if sp_rom_cycle = 13 then sp_graphx2(15 downto  0) <= sp_rom_data; end if;
		if sp_rom_cycle = 14 then sp_graphx3(31 downto 16) <= sp_rom_data; end if;
		if sp_rom_cycle = 15 then sp_graphx3(15 downto  0) <= sp_rom_data; end if;		
	end if;
end process;

-- absolute position decoder simulation
--
--  steering :
--       thresholds        median
--   F5 <  left 8   < 34    30
--   35 <  left 7   < 3C    38
--   3D <  left 6   < 44    40
--   45 <  left 5   < 4C    48     
--   4D <  left 4   < 54    50
--   45 <  left 3   < 5C    58
--   5D <  left 2   < 64    60
--   65 <  left 1   < 6C    68
--   6D < centrered < 74    70
--   75 <  right 1  < 7C    78
--   7D <  right 2  < 84    80
--   85 <  right 3  < 8C    88
--   8D <  right 4  < 94    90
--   95 <  right 5  < 9C    98
--   9D <  right 6  < A4    A0
--   A5 <  right 7  < AC    A8
--   AD <  right 8  < F4    BO

-- gas :
--         threshold          median
--    00 < gas pedal 00 < 3B   (39)  3E-5
--    3C < gas pedal 01 < 40    3E
--    41 < gas pedal 02 < 45    43
--    46 < gas pedal 03 < 4A    48      
--    4B < gas pedal 04 < 4F    4D
--    50 < gas pedal 05 < 54    52
--    55 < gas pedal 06 < 59    57
--    5A < gas pedal 07 < 5E    5C
--    5F < gas pedal 08 < 63    61
--     ...
--    FA < gas pedal 27 < FE    FC
--    FF = gas pedal 28        (FF)  FC+4


gas_plus       <= joy_BBBBFRLDU(0);
gas_minus      <= joy_BBBBFRLDU(1);
steering_plus  <= joy_BBBBFRLDU(3);
steering_minus <= joy_BBBBFRLDU(2);

process (clock_40)
begin
	if reset = '1' then 	
		gas <= x"39";
		steering <= x"70";
	else

		if rising_edge(clock_40) then
			gas_plus_r       <= gas_plus;
			gas_minus_r      <= gas_minus;
			steering_plus_r  <= steering_plus;
			steering_minus_r <= steering_minus;
			vsync_r          <= vsync;
			
			-- gas increase/decrease as long as btn is pushed
			-- keep current value when no btn is pushed
			if gas < x"39" then
				gas <= x"39";
			else 		
				if (gas_plus_r = not gas_plus)  or
					(gas_minus_r = not gas_minus) then
						gas_timer <= (others => '0');
				else
					if vsync_r ='0' and vsync = '1' then 
						if (gas_timer >= 5 and (gas_minus_r = '1' or gas_plus_r = '1')) then --tune inc/dec rate
							gas_timer <= (others => '0');
						else
							gas_timer <= gas_timer + 1;
						end if;
					end if;
				end if;
	
				if vsync_r ='0' and vsync = '1' and gas_timer = 0 then	
					if gas_plus = '1' then
						if gas >= x"FC" then gas <= x"FF"; else gas <= gas + 5; end if;
					elsif gas_minus = '1' then
						if gas <= x"3E" then gas <= x"39"; else gas <= gas - 5; end if;
					end if;
				end if;
				
			end if;
		
			-- steering increase/decrease as long as btn is pushed
			-- return to center value when no btn is pushed
			if steering < x"30" then
				steering <= x"30";
			elsif steering > x"B0" then
				steering <= x"B0"; 
			else
				if (steering_plus_r = not steering_plus)  or
					(steering_minus_r = not steering_minus) then
						steering_timer <= (others => '0');
				else
					if vsync_r ='0' and vsync = '1' then 
						if (steering_timer >= 7 and (steering_minus_r = '1' or  steering_plus_r = '1')) or   -- tune btn pushed   rate
						   (steering_timer >= 3 and (steering_minus_r = '0' and steering_plus_r = '0')) then -- tune btn released rate
							steering_timer <= (others => '0');
						else
							steering_timer <= steering_timer + 1;
						end if;
					end if;
				end if;
				
				if vsync_r ='0' and vsync = '1' and steering_timer = 0 then	
					if steering_plus = '1' then 
						if steering >= x"A8" then steering <= x"B0"; else steering <= steering + 8; end if;
					elsif steering_minus = '1' then
						if steering <= x"38" then steering <= x"30"; else steering <= steering - 8; end if;
					else
						if steering <= x"68" then steering <= steering + 8; end if;						
						if steering >= x"78" then steering <= steering - 8; end if;
						if (steering > x"68") and (steering < x"78") then steering <= x"70"; end if;						
					end if;
				end if;

			end if;
		
		end if;
		
	end if;
end process;	


-- adapt video to 4bits/color only and blank
vga_r <= r & '0' when blankn = '1' else "0000";
vga_g <= g & '0' when blankn = '1' else "0000";
vga_b <= b & '0' when blankn = '1' else "0000";

-- synchro composite/ synchro horizontale
-- vga_hs <= csync;
-- vga_hs <= hsync;
vga_hs <= csync when tv15Khz_mode = '1' else hsync;
-- commutation rapide / synchro verticale
-- vga_vs <= '1';
-- vga_vs <= vsync;
vga_vs <= '1'   when tv15Khz_mode = '1' else vsync;

--sound_string <= "00" & audio & "000" & "00" & audio & "000";

-- get scancode from keyboard
process (reset, clock_40)
begin
	if reset='1' then
		clock_div <= (others => '0');
		clock_kbd  <= '0';
	else 
		if rising_edge(clock_40) then
			if clock_div = "1001" then
				clock_div <= (others => '0');
				clock_kbd  <= not clock_kbd;
			else
				clock_div <= clock_div + '1';			
			end if;
		end if;
	end if;
end process;

keyboard : entity work.io_ps2_keyboard
port map (
  clk       => clock_kbd, -- synchrounous clock with core
  kbd_clk   => ps2_clk,
  kbd_dat   => ps2_dat,
  interrupt => kbd_intr,
  scancode  => kbd_scancode
);

-- translate scancode to joystick
joystick : entity work.kbd_joystick
port map (
  clk           => clock_kbd, -- synchrounous clock with core
  kbdint        => kbd_intr,
  kbdscancode   => std_logic_vector(kbd_scancode), 
  joy_BBBBFRLDU => joy_BBBBFRLDU,
  fn_pulse      => fn_pulse,
  fn_toggle     => fn_toggle
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
--h0 : entity work.decodeur_7_seg port map(kbd_scancode(3 downto 0), hex0);
--h1 : entity work.decodeur_7_seg port map(kbd_scancode(7 downto 4), hex1);
h0 : entity work.decodeur_7_seg port map(dbg_cpu_addr( 3 downto  0),hex0);
h1 : entity work.decodeur_7_seg port map(dbg_cpu_addr( 7 downto  4),hex1);
h2 : entity work.decodeur_7_seg port map(dbg_cpu_addr(11 downto  8),hex2);
h3 : entity work.decodeur_7_seg port map(dbg_cpu_addr(15 downto 12),hex3);

-- HI / LOW gear shift display

-- 7 segment bits:
--     --0--
--     5   1 
--     |-6-|
--     4   2
--     --3-- .7 (dot) 

hex5 <= not "01110110" when fn_toggle(1) = '1' else not "00111000";  -- H or L
hex4 <= not "00110000" when fn_toggle(1) = '1' else not "00111111";  -- I or O

--h4 : entity work.decodeur_7_seg port map(sp_rom_cycle(3 downto 0),hex4);
--h5 : entity work.decodeur_7_seg port map(dummy3,hex5);

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
process(clock_40)  -- use same clock as kick_sound_board
begin
  if rising_edge(clock_40) then
  
		if clock_div = "0000" then 
			pwm_accumulator_l  <=  ('0'&pwm_accumulator_l(16 downto 0)) + ('0'&audio_l&'0');
			pwm_accumulator_r  <=  ('0'&pwm_accumulator_r(16 downto 0)) + ('0'&audio_r&'0');
		end if;
		
  end if;
end process;

pwm_audio_out_l <= pwm_accumulator_l(17);
pwm_audio_out_r <= pwm_accumulator_r(17); 


end struct;
