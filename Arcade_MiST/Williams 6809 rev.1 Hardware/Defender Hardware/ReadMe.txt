---------------------------------------------------------------------------------
-- 
-- Arcade: Defender port to MiST by Gehstock
-- 11 June 2019
-- 
--
-- Usage:
-- - Create ROM and ARC files from the MRA files in the meta directory
--   using the MRA utility.
--   Example: mra -A -z /path/to/mame/roms Defender.mra
-- - Copy the ROM files to the root of the SD Card
-- - Copy the RBF and ARC files to the same folder on the SD Card
--
-- MRA utility: https://github.com/sebdel/mra-tools-c/
--
---------------------------------------------------------------------------------
-- A simulation model of Williams 6809 hardware
-- by Dar (darfpga@aol.fr)
-- http://darfpga.blogspot.fr

---------------------------------------------------------------------------------
-- 
-- Only controls and OSD are rotated on Video output.
-- 
-- 
-- Keyboard inputs :
--
-- Fire = Fire or Space
-- Thrust = Fire2 or ALT
-- Smart Bomb = Fire3 or CTRL
-- Hyperspace = Fire4 or 1
-- Change Direction = Left or Right
-- Up = Up
-- Down = Down

-- Advance = A
-- Auto up = U      
-- Score_reset = H  
--
-- Joystick support.
-- 
---------------------------------------------------------------------------------


DEFENDER.ROM is required at the root of the SD-Card.

