---------------------------------------------------------------------------------
-- 
-- Arcade: Mayday port to MiST by Gehstock
-- 11 June 2019
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
--   ESC         : Coin
--   F2          : Start 2 players
--   F1          : Start 1 player
--   UP,DOWN,LEFT,RIGHT arrows : Movements
--
-- Joystick support.
-- 
---------------------------------------------------------------------------------

MAYDAY.ROM is required at the root of the SD-Card.