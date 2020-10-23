-- Arcade: SEGA System 1  port to MiST by Slingshot
--
-- Usage:
-- - Create ROM and ARC files from the MRA files in the meta directory
--   using the MRA utility.
--   Example: mra -A -z /path/to/mame/roms "Flicky.mra"
-- - Copy the ROM files to the root of the SD Card
-- - Copy the RBF and ARC files to the same folder on the SD Card
--
-- MRA utility: https://github.com/sebdel/mra-tools-c/
--
-- Keyboard inputs :
--
--   ESC         : Coin
--   F2          : Start 2 players
--   F1          : Start 1 player
--   UP,DOWN,LEFT,RIGHT arrows : Movements
--   Left Ctrl   : Trig1
--   Left Alt    : Trig2
--   SPACE       : Trig3
---------------------------------------------------------------------------------
-- 
-- Arcade: SEGA System 1  for MiSTer by MiSTer-X
-- 07 January 2020
-- 
---------------------------------------------------------------------------------
-- T80/T80s - Version : 0242
--------------------------------
-- Z80 compatible microprocessor core
-- Copyright (c) 2001-2002 Daniel Wallner (jesus@opencores.org)
---------------------------------------------------------------------------------
--
-- Keyboard inputs :
--
--   F2          : Coin + Start 2 players
--   F1          : Coin + Start 1 player
--   UP,DOWN,LEFT,RIGHT arrows : Movements
--   SPACE       : Trig1
--   CTRL        : Trig2
--   ALT         : Trig3
--
-- MAME/IPAC/JPAC Style Keyboard inputs:
--   5           : Coin 1
--   6           : Coin 2
--   1           : Start 1 Player
--   2           : Start 2 Players
--   R,F,D,G     : Player 2 Movements
--   A           : Player 2 Trig1
--   S           : Player 2 Trig2
--   Q           : Player 2 Trig3
--
-- Joystick support.
--
---------------------------------------------------------------------------------
-- 2020/01/08  Impl. Trigger 3  (for SEGA Ninja)
---------------------------------------------------------------------------------

                                *** Attention ***

ROM is not included. In order to use this arcade, you need to provide a correct ROM file.

Find this zip file somewhere. You need to find the file exactly as required.
Do not rename other zip files even if they also represent the same game - they are not compatible!
The name of zip is taken from M.A.M.E. project, so you can get more info about
hashes and contained files there.


How to install:
  0. Update MiSTer binary to v200106 or later
  1. copy releases/*.mra to /media/fat/_Arcade
  2. copy releases/*.rbf to /media/fat/_Arcade/cores
  3. copy ROM zip files  to /media/fat/_Arcade/mame


Be sure to use the MRA file in "releases" of this repository.
It does not guarantee the operation when using other MRA files.

