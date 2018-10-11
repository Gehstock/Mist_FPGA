---------------------------------------------------------------------------------
-- 
-- Gameboy Core for MiST by Till Harbaum
-- Changed by Gehstock
-- 19 December 2017
-- 
---------------------------------------------------------------------------------

-- This is source code of a gameboy implementation for the MIST. 



-- It's based on the [t80](http://opencores.com/project,t80) CPU core. 

-- A minor
fix was needed for the "LD ($FF00+C)" instruction.



-- The audio implementation has been taken from the PACE framework. 

-- The 
original file is available in the [pacedev svn]
-- (https://svn.pacedev.net/repos/pace/sw/src/component/sound/gb/gbc_snd.vhd).


---------------------------------------------------------------------------------
-- 
-- 
-- Keyboard inputs :
--
--   ESC:       : Start
--   TAB:	: Select
--   SPACE      : Button A
--   LALT 	: Button B
--   ARROW KEYS : Movements
--
-- Joystick support.
-- 
---------------------------------------------------------------------------------

ToDo: Mappers

