---------------------------------------------------------------------------------
-- 
-- Arcade: Tutankham port to MiSTer by Rodimus
-- 09 February 2026
-- 
---------------------------------------------------------------------------------
-- A simulation model of Tutankham hardware
-- Copyright (c) Rodimus - February 2026
-- Based on the Time Pilot Core (Same exact Sound Board)
---------------------------------------------------------------------------------
-- 
-- Support screen and controls rotation on HDMI output.
-- Only controls are rotated on VGA output.
-- 
-- 
-- Joystick support : A - fire right, B - fire left, X - flash bomb, select - coin up, start - 1 player start, left shoulder - pause, right shoulder - 2 player start
-- 
----------------------------------------------

Hiscore save/load:

Highscore saving is untested.

To save your hiscores manually, press the 'Save Settings' option in the OSD.  Hiscores will be automatically loaded when the core is started.

To enable automatic saving of hiscores, turn on the 'Autosave Hiscores' option and press the 'Save Settings' option in the OSD.  Hiscores will then be automatically saved (if they have changed) any time the OSD is opened.

Hiscore data is stored in /media/fat/config/nvram/ as ```<mra filename>.nvm```

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