-- Top level file for Atari Sprint 4
-- (c) 2017 James Sweet
--
-- This is free software: you can redistribute
-- it and/or modify it under the terms of the GNU General
-- Public License as published by the Free Software
-- Foundation, either version 3 of the License, or (at your
-- option) any later version.
--
-- This is distributed in the hope that it will
-- be useful, but WITHOUT ANY WARRANTY; without even the
-- implied warranty of MERCHANTABILITY or FITNESS FOR A
-- PARTICULAR PURPOSE. See the GNU General Public License
-- for more details.

-- Targeted to EP2C5T144C8 mini board but porting to nearly any FPGA should be fairly simple
-- See Ultra Tank manual for video output details. Resistor values listed here have been scaled 
-- for 3.3V logic. 


library IEEE;
use IEEE.STD_LOGIC_1164.all;


entity sprint4 is 
port(		
			Clk_50_I		: in	std_logic;	-- 50MHz input clock
			Clk_12		: in std_logic;
			Reset_I		: in	std_logic;	-- Reset button (Active low)
			Video1_O		: out std_logic;  -- White video output (680 Ohm)
			Video2_O		: out std_logic;	-- Black video output (1.2k)
			Vsync			: out std_logic;
			Hsync			: out std_logic;
			Hblank		: out std_logic;
			Vblank		: out std_logic;
			Sync_O		: out std_logic;  -- Composite sync output (1.2k)
			Blank_O		: out std_logic;  -- Composite blank output
			VideoR_O		: out std_logic;  -- Color monitor signals, the Electrohome G02 had digital color inputs
			VideoG_O		: out std_logic;
			VideoB_O		: out std_logic;
			P1_2audio			: out std_logic_vector(6 downto 0);
			P3_4audio			: out std_logic_vector(6 downto 0);
			Coin1_I		: in  std_logic;  -- Coin switches (Active low)
			Coin2_I		: in  std_logic;
			Coin3_I		: in  std_logic;
			Coin4_I		: in  std_logic;
			Start1_I		: in  std_logic;  -- Start buttons
			Start2_I		: in  std_logic;
			Start3_I		: in  std_logic;
			Start4_I		: in  std_logic;
			Gas1_I		: in  std_logic;
			Gas2_I		: in  std_logic;
			Gas3_I		: in  std_logic;
			Gas4_I		: in  std_logic;
			Gear1_1_I	: in  std_logic;  -- Gear shifters, 4th gear = no other gear selected
			Gear2_1_I	: in  std_logic;
			Gear3_1_I	: in  std_logic;
			Gear1_2_I	: in  std_logic;
			Gear2_2_I	: in  std_logic;
			Gear3_2_I	: in  std_logic;
			Gear1_3_I	: in  std_logic;
			Gear2_3_I	: in  std_logic;
			Gear3_3_I	: in  std_logic;
			Gear1_4_I	: in  std_logic;
			Gear2_4_I	: in  std_logic;
			Gear3_4_I	: in  std_logic;
			Steer_1A_I	: in  std_logic;	-- Steering wheel inputs, these are quadrature encoders
			Steer_1B_I	: in	std_logic;
			Steer_2A_I	: in  std_logic;	
			Steer_2B_I	: in	std_logic;
			Steer_3A_I	: in  std_logic;	
			Steer_3B_I	: in	std_logic;
			Steer_4A_I	: in  std_logic;	
			Steer_4B_I	: in	std_logic;
			TrackSel_I	: in  std_logic;
			Test_I		: in  std_logic;  -- Self-test switch
			StartLamp_O	: out std_logic_vector(4 downto 1)	-- Player start button LEDs
			);
end sprint4;

architecture rtl of sprint4 is


signal Clk_6				: std_logic;
signal Phi1 				: std_logic;
signal Phi2					: std_logic;
signal Reset_n				: std_logic;

signal Hcount		   	: std_logic_vector(8 downto 0);
signal Vcount  			: std_logic_vector(7 downto 0) := (others => '0');
signal H256_s				: std_logic;
signal Vblank_s			: std_logic;
signal Vblank_n_s			: std_logic;
signal HBlank_s			: std_logic;
signal VSync_s				: std_logic;
signal HSync_s				: std_logic;
signal CompBlank			: std_logic;
signal CompBlank_s		: std_logic;
signal CompSync_n_s		: std_logic;
signal WhiteVid 			: std_logic;
signal PeachVid 			: std_logic;
signal VioletVid 			: std_logic;
signal GreenVid 			: std_logic;
signal BlueVid 			: std_logic;

signal DMA					: std_logic_vector(7 downto 0);
signal DMA_n				: std_logic_vector(7 downto 0);
signal PRAM					: std_logic_vector(7 downto 0);
signal Load_n				: std_logic_vector(8 downto 1);
signal Car					: std_logic_vector(4 downto 1);
signal Car_n				: std_logic_vector(4 downto 1);
signal Playfield_n		: std_logic;

signal CPU_Din				: std_logic_vector(7 downto 0);
signal CPU_Dout			: std_logic_vector(7 downto 0);
signal DBus_n				: std_logic_vector(7 downto 0);
signal BA					: std_logic_vector(15 downto 0);

signal Trac_Sel_Read_n	: std_logic;
signal Gas_Read_n			: std_logic;
signal Coin_Read_n		: std_logic;
signal Collision_Read_n	: std_logic;
signal Collision_n		: std_logic_vector(4 downto 1);
signal CollisionReset_n	: std_logic_vector(4 downto 1);
signal Options_Read_n	: std_logic;
signal AD_Read_n			: std_logic;
signal Wr_DA_Latch_n 	: std_logic;
signal Wr_CrashWord_n	: std_logic;
signal Skid					: std_logic_vector(4 downto 1);
signal Attract				: std_logic;
signal Attract_n			: std_logic;	


signal SW1					: std_logic_vector(7 downto 0);


begin
-- Configuration DIP switches, these can be brought out to external switches if desired
-- See Sprint 4 manual page 6 for complete information. Active low (0 = On, 1 = Off)
--    1 	2	3	4							Game Length		(0111 - 60sec, 1011 - 90sec, 1101 - 120sec, 1110 - 150sec, 1111 - 150sec)
--   					5						Late Entry		(0 - Permitted, 1 - Not Permitted)
--							6					Game Cost		(0 - 2 Coins/Player, 1 - 1 Coin/Player) 
--								7	8			Language			(11 - English, 01 - French, 10 - Spanish, 00 - German)
SW1 <= "00000000"; -- Config dip switches



		
		
Vid_sync: entity work.synchronizer
port map(
		Clk_12 => Clk_12,
		Clk_6 => Clk_6,
		HCount => HCount,
		VCount => VCount,
		HSync => Hsync_s,
		HBlank => HBlank_s,
		VBlank_n_s => VBlank_n_s,
		VBlank => VBlank_s,
		VSync => VSync_s
		);
		
Color_mixer: entity work.colormix
port map(
		Clk6 => Clk_6,
		CompBlank => CompBlank,
		WhiteVid => WhiteVid,
		PeachVid => PeachVid,
		VioletVid => VioletVid,
		GreenVid => GreenVid,
		BlueVid => BlueVid,
		video_r => VideoR_O,
		video_g => VideoG_O,
		video_b => VideoB_O
		);

Background: entity work.playfield
port map( 
		Clk6 => Clk_6,
		DMA => DMA,
		PRAM => PRAM,
		Load_n => Load_n,
		Car => Car,
		HCount => HCount,
		VCount => VCount,
		HBlank => HBlank_s,
		VBlank => VBlank_s,
		VBlank_n_s => VBlank_n_s,
		HSync => Hsync_s,
		VSync => VSync_s,
		H256_s => H256_s,
		Playfield_n => Playfield_n,
		WhiteVid => WhiteVid,
		PeachVid => PeachVid,
		VioletVid => VioletVid,
		GreenVid => GreenVid,
		BlueVid => BlueVid,
		Video1 => Video1_O,
		Video2 => Video2_O
		);
			
		
Cars: entity work.motion
port map(
		CLK6 => Clk_6,
		PHI2 => Phi2,
		DMA_n => DMA_n,
      PRAM => PRAM,
		H256_s => H256_s,
		VCount => VCount,
		HCount => HCount,
		Load_n => Load_n,
		Car => Car,
		Car_n => Car_n
		);

	
	
CPU: entity work.cpu_mem
port map(
		Clk12 => clk_12,
		Clk6 => clk_6,
		Reset_I => Reset_I,
		Reset_n => reset_n,
		VCount => VCount,
		HCount => HCount,
		Vblank_n_s => Vblank_n_s,
		Test_n => Test_I,
		DB_in => CPU_Din,
		DBus => CPU_Dout,
		DBus_n => DBus_n,
		PRAM => PRAM,
		ABus => BA,
		Attract => Attract,
		Attract_n => Attract_n,
		CollReset_n => CollisionReset_n,
		Trac_Sel_Read_n => Trac_Sel_Read_n,
		AD_Read_n => AD_Read_n,
		Gas_Read_n => Gas_Read_n,
		Coin_Read_n => Coin_Read_n,
		Options_Read_n => Options_Read_n,
		Wr_DA_Latch_n => Wr_DA_Latch_n,
		Wr_CrashWord_n => Wr_CrashWord_n,
		StartLamp => StartLamp_O,
		Skid => Skid,
		Phi1_o => Phi1,
		Phi2_o => Phi2,
		DMA => DMA,
		DMA_n => DMA_n,
		ADR => open
		);
		
		
Input: entity work.Control_Inputs
port map(
		Clk6 => Clk_6,
		DipSw => SW1, -- DIP switches
		Trac_Sel_n => TrackSel_I,
		Coin1 => not Coin1_I, -- Coin switches are active-high in real hardware, active-low is easier here
		Coin2 => not Coin2_I,
		Coin3 => not Coin3_I,
		Coin4 => not Coin4_I,
		Start1_n => Start1_I,
		Start2_n => Start2_I,
		Start3_n => Start3_I,
		Start4_n => Start4_I,
		Gas1_n => Gas1_I,
		Gas2_n => Gas2_I,
		Gas3_n => Gas3_I,
		Gas4_n => Gas4_I,		
		Gear1_1_n => Gear1_1_I,
		Gear2_1_n => Gear2_1_I,
		Gear3_1_n => Gear3_1_I,		
		Gear1_2_n => Gear1_2_I,
		Gear2_2_n => Gear2_2_I,
		Gear3_2_n => Gear3_2_I,
		Gear1_3_n => Gear1_3_I,
		Gear2_3_n => Gear2_3_I,
		Gear3_3_n => Gear3_3_I,
		Gear1_4_n => Gear1_4_I,
		Gear2_4_n => Gear2_4_I,
		Gear3_4_n => Gear3_4_I,
		Steering1A_n => Steer_1A_I,
		Steering1B_n => Steer_1B_I,
		Steering2A_n => Steer_2A_I,
		Steering2B_n => Steer_2B_I,
		Steering3A_n => Steer_3A_I,
		Steering3B_n => Steer_3B_I,
		Steering4A_n => Steer_4A_I,
		Steering4B_n => Steer_4B_I,
		Collision_n => Collision_n,	
	   Gas_Read_n => Gas_Read_n,
		AD_Read_n => AD_Read_n,
		Coin_Read_n => Coin_Read_n,
		Options_Read_n => Options_Read_n,
		Trac_Sel_Read_n => Trac_Sel_Read_n,
		Wr_DA_Latch_n => Wr_DA_Latch_n,
		Adr => BA(2 downto 0),
		DBus => CPU_Dout(3 downto 0),
		Dout => CPU_Din
	);	
		
		
--PF_Comparator: entity work.collision_detect
--port map(	
--		Clk6 => Clk_6,
--		Car_n	=> Car_n,
--		Playfield_n => Playfield_n,
--		CollisionReset_n => CollisionReset_n,
--		Collision_n	=> Collision_n
--		);

	
Sound: entity work.audio
port map( 
		Clk_50 => Clk_50_I,
		Clk_6 => Clk_6,
		Reset_n => Reset_n,
		Load_n => Load_n,
		Skid => Skid,
		Wr_CrashWord_n => Wr_CrashWord_n,
		Attract => Attract,
		Attract_n => Attract_n,
		PRAM => PRAM,
		DBus_n => DBus_n,
		HCount => HCount,
		VCount => VCount,
		P1_2audio => P1_2audio,
		P3_4audio => P3_4audio
		);

Sync_O <= Hsync_s nor VSync_s;
Hsync <= Hsync_s;
VSync <= VSync_s;
Blank_O <= HBlank_s nor VBlank_s;
HBlank <= HBlank_s;
VBlank <= VBlank_s;


end rtl;