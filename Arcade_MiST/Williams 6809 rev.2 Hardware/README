-------------------------------------------------------------------------------
-- Turkey shoot by Dar (darfpga@aol.fr) (05 March 2022)
-- http://darfpga.blogspot.fr
-- https://sourceforge.net/projects/darfpga/files
-- github.com/darfpga
--
--  Terasic board MAX10 DE10 Lite
-------------------------------------------------------------------------------
-- gen_ram.vhd & io_ps2_keyboard
-------------------------------- 
-- Copyright 2005-2008 by Peter Wendrich (pwsoft@syntiac.com)
-- http://www.syntiac.com/fpga64.html
-------------------------------------------------------------------------------
-- cpu09l - Version : 0128
-- Synthesizable 6809 instruction compatible VHDL CPU core
-- Copyright (C) 2003 - 2010 John Kent
-------------------------------------------------------------------------------
-- cpu68 - Version 9th Jan 2004 0.8
-- 6800/01 compatible CPU core 
-- GNU public license - December 2002 : John E. Kent
-------------------------------------------------------------------------------
-- Educational use only
-- Do not redistribute synthetized file with roms
-- Do not redistribute roms whatever the form
-- Use at your own risk
-------------------------------------------------------------------------------
--  Video 15KHz is OK, 
--
--  This is not VGA, you have to use a TV set with SCART plug
--
--    SCART(TV) pin  - signal -  VGA(DE10) pin
--               15  -  red   -  1          
--               11  - green  -  2
--                7  -  blue  -  3  
--           5,9,13  -  gnd   -  5,6,7
--   (comp. sync)20  - csync  -  13 (HS)   
--  (fast commut)16  - commut -  14 (VS)
--            17,18  -  gnd   -  8,10 
--
-------------------------------------------------------------------------------
-- Version 0.0 -- 05/03/2022 -- 
--	initial version 
-------------------------------------------------------------------------------
--
-- Main features :
--  PS2 keyboard input @gpio pins 35/34 (beware voltage translation/protection)
--  Audio pwm output   @gpio pins 1/3 (beware voltage translation/protection)
--
-- Uses 1 pll for 12MHz and 120MHz generation from 50MHz
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
--   RIGHT arrow : Move gun right
--   LEFT  arrow : Move gun left
--   UP    arrow : Move gun up 
--   DOWN  arrow : Move gun down
--   CTRL        : Gobble
--   W(Z)        : Grenade
--
-- Keyboard Service inputs French(english) :
--
--   A(Q) : advance
--   U(U) : auto/up (!manual/down)
--   H(H) : high score reset
--
-- To enter service mode press 'advance' key while in game over screen
-- Enter service mode to tune game parameters (difficulty ...)
-- Tuning are lost at power OFF, for permanent tuning edit/set parameters
--   within tshoot_cmos_ram.vhd and recompile.
--
-------------------------------------------------------------------------------
-- Use make_tshoot_proms.bat to build vhd file and bin from binaries
-- Load sdram with external rom bank -> use sdram_loader_de10_lite.sof + key(0)
-------------------------------------------------------------------------------
-- Program sdram content with this turkey shoot rom bank loader before 
-- programming turkey shoot game core :
--
-- 1) program DE10_lite with tshoot sdram loader
-- 2) press key(0) at least once (digit blinks during programming)
-- 3) program DE10_lite with tshoot core without switching DE10_lite OFF
-------------------------------------------------------------------------------
-- Used ROMs by make_tshoot_proms.bat

> turkey_shoot_prog1
   rom18.ic55 CRC(effc33f1)

> turkey_shoot_prog2
   rom2.ic9"  CRC(fd982687)
   rom3.ic10" CRC(9617054d)

> turkey_shoot_bank_a
   rom17.ic26 CRC(b02d1ccd)
   rom15.ic24 CRC(11709935)

> turkey_shoot_bank_b
   rom16.ic25 CRC(69ce38f8)
   rom14.ic23 CRC(769a4ae5)
   rom13.ic21 CRC(ec016c9b)
   rom12.ic19 CRC(98ae7afa)   

> turkey_shoot_bank_c
   rom11.ic18 CRC(60d5fab8)
   rom9.ic16  CRC(a4dd4a0e)
   rom7.ic14  CRC(f25505e6)
   rom5.ic12  CRC(94a7c0ed)

> turkey_shoot_bank_d
   rom10.ic17 CRC(0f32bad8)
   rom8.ic15  CRC(e9b6cbf7)
   rom6.ic13  CRC(a49f617f)
   rom4.ic11  CRC(b026dc00)

> turkey_shoot_sound
   rom1.ic8   CRC(011a94a7)

> turkey_shoot_graph1
   rom20.ic57 CRC(c6e1d253)

> turkey_shoot_graph2
   rom21.ic58 CRC(9874e90f)

> turkey_shoot_graph3
   rom19.ic41 CRC(b9ce4d2a)

-------------------------------------------------------------------------------
-- Misc. info
-------------------------------------------------------------------------------
-- Main bus access
--  > Main address bus and data bus by CPU 6809
--  > Main address bus and data bus by DMA (blitter) while CPU is halted.
--
-- CPU and DMA can read/write anywhere from/to entire 64K address space
-- including video ram, color palette, tile map, cmos_ram, peripherals, roms,
-- switched rom banks, ...

--
-- Page register control allows to select misc. banked access (rom, ram). 
-------------------------------------------------------------------------------
-- Video ram : 3 banks of 16Kx8 (dram with ras/cas)
--  > interleaved bank access by CPU, 8bits read/write
--  > interleaved bank access by DMA, 8bits read, 2x4bits independent write
--  > simultaneous (3 banks) access by video scanner, 24bits at once
-- 
-- In original hardware, every 1us there is 1 access to video ram for CPU/DMA
-- and 1 access for video scanner. Thus DMA read/write cycle required 2us when
-- reading source is video ram. DMA read/write cycle required only 1us when
-- reading source is not video ram.
--
-- Higher part of video ram is not displayed on screen and is used as working
-- ram by CPU including stack (SP).
-------------------------------------------------------------------------------
-- Foreground (bitmap - video ram)
--  > 24 bits / 1us => 6 horizontal pixels of 4bits (16 colors)
--  > 6 bits register (64 color banks)
-------------------------------------------------------------------------------
-- Background (tile map : tile is 24x16 pixels)
--
--  > 16 horizontal tiles of 4x6 pixels, 16 vertical tiles of 16 pixels.
--  > map ram 2048x8
--      in  : 7 bits horizontal (4 bits + scroll) + 4 bits vertical
--      out : 128 possible tiles + flip control
--
--  > Graphics 3x8Kx8 roms
--      in  : 2 bits horizontal + 4 bits vertical + 7 bits tile code 
--      out : 24 bits = 6 pixels x 4 bits
--
--  > 24 bits / 1us => 6 horizontal pixels of 4bits (16 colors)
--  > 3 bits register + 3 bits from vertical video scanner (64 color banks)
-------------------------------------------------------------------------------
-- Palette 1024 colors x 16 bits
--  > in  10 bits from foreground or background data
--  > out 4 bits red, 4 bits green, 4 bits blue, 4 bits intensity 
-------------------------------------------------------------------------------
