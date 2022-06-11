
Crazy Climber hardware by DarFpga
Yamato, Swimmer, Guzzler added by Slingshot

Crazy Climber can be controller with two joysticks, or one gamepad with two sticks.
(MAME keymappings can be used as the second controller.)

BUGS/TODO:
 - figure out Yamato's background ROM usage (black background now).
 - cocktail mode

Other games that should work on this hardware:

Top Roller
 - twice the size of the big sprite ROMs
 - has a 3rd tilemap layer
 - CPU bank switching

-------------------------------------------------
Crazy climber FPGA by Dar - (darfpga@aol.fr)
-- http://darfpga.blogspot.fr
-------------------------------------------------
-- Crazy climber releases
--
-- Release 0.0 - 03/06/2018 - Dar
-------------------------------------------------
Educational use only
Do not redistribute synthetized file with roms
Do not redistribute roms whatever the form
Use at your own risk

--------------------------------------------------------------------
make sure to use cclimber.zip roms 
--------------------------------------------------------------------
See my previous ckong release (2014) for som more explanation
--------------------------------------------------------------------
The original arcade hardware PCB contains 10 memory regions

 cpu addressable space
 
 - program                  rom  20Kx8, cpu only access
 - working ram              ram   1Kx8, cpu only access
 - color/sprite-data        ram   1Kx8, cpu + (2 access / 8 pixels)
 - background buffer        ram   1Kx8, cpu + (1 access / 8 pixels)
 - big sprite buffer        ram  256x8  cpu + (1 access / 8 pixels)        

 non cpu addressable region   

 - background/sprite graphics      rom 4Kx16, (1 access / 8 pixels) 
 - big sprite graphics             rom 2Kx16, (1 access / 8 pixels)
 - background/sprite color palette rom 64x8 , (1 access / pixels)
 - big sprite color palette        rom 32x8 , (1 access / pixels)
 - sound samples                   rom 8Kx8 , low rate

The pixel clock is 6MHz, the cpu clock is 3MHz.
  
Video display is 256 pixels x 240 lines.
Each lines contains 8 sprites and 32 background tiles. 
Each frames contains 28 background tiles height.

Each tile is 8x8 pixels
Each sprite is 16x16 pixels

Big sprite is a 8x8 tile graphic

Sound is composed of AY-3-8910 music and sound samples. 
--------------------------------------------------------------------

---------------
VHDL File list 
---------------

crazy_climber_de10_lite.vhd  Top level for de10-lite board

max10_pll_12M.vhd       Pll 12MHz from 50MHz altera mf

crazy_climber.vhd       Main logic

video_gen.vhd           Video scheduler, syncs (h,v and composite)
line_doubler.vhd        Line doubler 15kHz -> 31kHz

crazy_climber_sound.vhd Music and samples logic

kbd_joystick.vhd        Keyboard key to player/coin input

rtl_T80/T80s.vhd        T80 Copyright (c) 2001-2002 Daniel Wallner (jesus@opencores.org)
rtl_T80/T80_Reg.vhd
rtl_T80/T80_Pack.vhd
rtl_T80/T80_MCode.vhd
rtl_T80/T80_ALU.vhd
rtl_T80/T80.vhd

io_ps2_keyboard.vhd      Copyright 2005-2008 by Peter Wendrich (pwsoft@syntiac.com)

ym_2149_linmix.vhd       Copyright (c) MikeJ - Jan 2005

----------------------
Quartus project files
----------------------
de10_lite/crazy_climber_de10_lite.qsf   de10_lite settings (files,pins,...)
de10_lite/crazy_climber_de10_lite.qpf   de10_lite project

-----------------------------
Required ROMs (Not included)
-----------------------------
You need the following 16 ROMs from cclimber.zip 

cc11 CRC(217ec4ff) SHA1(334604c3a051d57440a9d0bfc34b809418ef1d2d)
cc10 CRC(b3c26cef) SHA1(f52cb5482c12a9c5fb56e2e2aec7cab0ed23e5a5)
cc09 CRC(6db0879c) SHA1(c0ba1976c1dcd6edadd78073173a26851ae8dd4f)
cc08 CRC(f48c5fe3) SHA1(79072bbbf37387998ffd031afe8eb569a16fa9bd)
cc07 CRC(3e873baf) SHA1(8870dc5948cdd3c8d2fe9e54a20cf6c311c94e53)

cc06 CRC(481b64cc) SHA1(3f35c545fc784ed4f969aba2d7be6e13a5ae32b7)
cc05 CRC(2c33b760) SHA1(2edea8fe13376fbd51a5586d97aba3b30d78e94b)
cc04 CRC(332347cb) SHA1(4115ca32af73f1791635b7d9e093bf77088a8222)
cc03 CRC(4e4b3658) SHA1(0d39a8cb5cd6cf06008be60707f9b277a8a32a2d)

cc02 CRC(14f3ecc9) SHA1(a1b5121abfbe8f07580eb3fa6384352d239a3d75)
cc01 CRC(21c0f9fb) SHA1(44fad56d302a439257216ddac9fd62b3666589f1)

cclimber.pr1 CRC(751c3325) SHA1(edce2bc883996c1d72dc6c1c9f62799b162d415a)
cclimber.pr2 CRC(ab1940fa) SHA1(8d98e05cbaa6f55770c12e0a9a8ed9c73cc54423)
cclimber.pr3 CRC(71317756) SHA1(1195f0a037e379cc1a3c0314cb746f5cd2bffe50)

cc13 CRC(e0042f75) SHA1(86cb31b110742a0f7ae33052c88f42d00deb5468)
cc12 CRC(5da13aaa) SHA1(b2d41e69435d09c456648a10e33f5e1fbb0bc64c)

------
Tools 
------
You need to build vhdl ROM image files from the binary file :
 - Unzip the roms file in the tools/cclimber_unzip directory
 - Double click (execute) the script tools/cclimber_unzip/make_crazy_climber_proms.bat to get the following files

cclimber_program.vhd
cclimber_tile_bit0.vhd
cclimber_tile_bit1.vhd
cclimber_big_sprite_tile_bit0.vhd
cclimber_big_sprite_tile_bit1.vhd
cclimber_palette.vhd
cclimber_big_sprite_palette.vhd
cclimber_samples.vhd

*DO NOT REDISTRIBUTE THESE FILES*

The script make_crazy_climber_proms uses make_vhdl_prom and and duplicate_byte executables delivered both in linux and windows version. The script itself is delivered only in windows version (.bat) but should be easily ported to linux.

Source code of make_vhdl_prom.c and and duplicate_byte.c is also delivered.

---------------------------------
Compiling for de10_lite
---------------------------------
You can rebuild the project with ROM image embeded in the sof file. DO NOT REDISTRIBUTE THESE FILES.
4 steps

 - put the VHDL rom files into the project directory
 - rebuild crazy_climber_de10_lite
 - program crazy_climber_de10_lite.sof into the fpga 

--------------------
Keyboard and swicth
--------------------
Use directional key to move, space to change movement, F1/F2 to start 1/2 players and F3 for coins.
de10_lie sw0 allow to switch 15kHz/31kHz

------------------------
End of file
------------------------