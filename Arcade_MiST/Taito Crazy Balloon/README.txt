---------------------------------------------------------------------------------
-- 
-- Arcade version of Astrocade for MiSTer - Mike Coates
--
-- V 1.0 15/06/2020 - Mike Coates
---------------------------------------------------------------------------------
-- Support screen and controls rotation on HDMI output.
-- Only controls are rotated on VGA output.
-- 
-- MAME/IPAC/JPAC Style Keyboard inputs:
--   5           : Coin 1
--   1           : Start 1 Player
--   2           : Start 2 Players
--   R,F,D,G     : Player 2 Movements
--
--   UP,DOWN,LEFT,RIGHT arrows : Movements
--
-- Joystick support.
-- 
---------------------------------------------------------------------------------

                                *** Attention ***

ROMs are not included. In order to use this arcade, you need to provide the
correct ROMs.

To simplify the process .mra files are provided in the releases folder, that
specifies the required ROMs with checksums. The ROMs .zip filename refers to the
corresponding file of the M.A.M.E. project.

Please refer to https://github.com/MiSTer-devel/Main_MiSTer/wiki/Arcade-Roms for
information on how to setup and use the environment.

Quickreference for folders and file placement:

/_Arcade/<game name>.mra
/_Arcade/cores/<game rbf>.rbf
/_Arcade/mame/<mame rom>.zip
/_Arcade/hbmame/<hbmame rom>.zip
