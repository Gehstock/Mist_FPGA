Crazy Kong Port to Mist FPGA by Gehstock



-------------------------------------------------
Crazy Kong (Falcon) FPGA - (darfpga@aol.fr)
-- http://darfpga.blogspot.fr
-------------------------------------------------
-- Crazy kong releases
--
-- Release 0.0 - 2014 -Dar
--	External sram required
--
-- Release 0.1 - 06/06/2018 - Dar
--      DE10_lite board
--	No external sram required
--	478kbits internal ram
--
-------------------------------------------------
Educational use only
Do not redistribute synthetized file with roms
Do not redistribute roms whatever the form
Use at your own risk
-------------------------------------------------
make sure to use ckongpt2.zip roms 
(MAME Crazy kong part II (set 1) - Falcon)
-------------------------------------------------------------------------
-- See my previous bagman/ckong release (2014) for some more explanations
-------------------------------------------------------------------------
The original arcade hardware PCB contains 10 memory regions

 cpu addressable space
 
 - program                  rom  24Kx8, cpu only access
 - working ram              ram   3Kx8, cpu only access
 - color/sprite-data        ram   1Kx8, cpu + (2 access / 8 pixels)
 - background buffer        ram   1Kx8, cpu + (1 access / 8 pixels)
 - big sprite buffer        ram  256x8  cpu + (1 access / 8 pixels)        

 non cpu addressable region   

 - background/sprite graphics      rom 8Kx16, (1 access / 8 pixels) 
 - big sprite graphics             rom 2Kx16, (1 access / 8 pixels)
 - background/sprite color palette rom 64x8 , (1 access / pixels)
 - big sprite color palette        rom 32x8 , (1 access / pixels)
 - sound samples                   rom 8Kx8 , low rate

The pixel clock is 6MHz, the cpu clock is 3MHz.
 
Background color contains 2 high bits of tile code.
Sprite color contains horizontal and vertical invert control  
 
x/y/color big sprite are 3 sequentialy accessed during the first 3 
sprites area.
  

Big sprite color contains horizontal and vertical invert control  

Video frame is 384 pixels x 264 lines.
  
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

ckong_de10_lite.vhd     Top level for de10-lite board

max10_pll_12M.vhd       PLL 12MHz from 50MHz altera mf

ckong.vhd               Main logic

video_gen.vhd           Video scheduler, syncs (h,v and composite)
line_doubler.vhd        Line doubler 15kHz -> 31kHz

ckong_sound.vhd         Music and samples logic

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
de10_lite/ckong_de10_lite.qsf     de10_lite settings (files,pins...) 
de10_lite/ckong_de10_lite.qpf     de10_lite project

-----------------------------
Required ROMs (Not included)
-----------------------------
You need the following 17 ROMs from ckongpt2.zip 
(MAME Crazy kong part II (set 1) - Falcon)

d05-07.bin / 7.5d  CRC(b27df032) SHA1(57f9be139c610405e3c2fddd7093dfb1277e450e)
f05-08.bin / 8.5e  CRC(5dc1aaba) SHA1(42b9e5946ffce7c156d114bde68f37c2c34853c4)
h05-09.bin / 9.5h  CRC(c9054c94) SHA1(1aa08d2501ee620759fd5c111e12f6d432c25294)
k05-10.bin / 10.5k CRC(069c4797) SHA1(03be185e6914ec7f3770ce3da4eb49cdb97adc85)
l05-11.bin / 11.5l CRC(ae159192) SHA1(d467256a3a366e246243e7828ff4a45d4c146e2c)
n05-12.bin / 12.5n CRC(966bc9ab) SHA1(4434fc620169ffea1b1f227b61674e1daf79b54b)

prom.v6  CRC(b3fc1505) SHA1(5b94adde0428a26b815c7eb9b3f3716470d349c7)
prom.u6  CRC(26aada9e) SHA1(f59645e606ea4f0dd0fc4ea47dd03f526c534941)
prom.t6  CRC(676b3166) SHA1(29b9434cd34d43ea5664e436e2a24b54f8d88aac)

n11-06.bin / 6.11n CRC(2dcedd12) SHA1(dfdcfc21bcba7c8e148ee54daae511ca78c58e70)
l11-05.bin / 5.11l CRC(fa7cbd91) SHA1(0208d2ebc59f3600005476b6987472685bc99d67)
k11-04.bin / 4.11k CRC(3375b3bd) SHA1(a00b3c31cff123aab6ac0833aabfdd663302971a)
h11-03.bin / 3.11h CRC(5655cc11) SHA1(5195e9b2a60c54280b48b32ee8248090904dbc51)

c11-02.bin / 2.11c CRC(d1352c31) SHA1(da726a63a8be830d695afeddc1717749af8c9d47)
a11-01.bin / 1.11a CRC(a7a2fdbd) SHA1(529865f8bbfbdbbf34ac39c70ef17e6d5bd0f845) 

cc13j.bin / 14.5s  CRC(5f0bcdfb) SHA1(7f79bf6de117348f606696ed7ea1937bbf926612)
cc12j.bin / 13.5p  CRC(9003ffbd) SHA1(fd016056aabc23957643f37230f03842294f795e)

------
Tools 
------
You need to build vhdl ROM image files from the binary file :
 - Unzip the roms file in the tools/ckong_unzip directory
 - Double click (execute) the script tools/make_ckong_proms.bat to get the following files

ckong_program.vhd
ckong_tile_bit0.vhd
ckong_tile_bit1.vhd
ckong_big_sprite_tile_bit0.vhd
ckong_big_sprite_tile_bit1.vhd
ckong_palette.vhd
ckong_big_sprite_palette.vhd
ckong_samples.vhd

*DO NOT REDISTRIBUTE THESE FILES*

The script make_ckong_proms uses make_vhdl_prom and and duplicate_byte executables delivered both in linux and windows version. The script itself is delivered only in windows version (.bat) but should be easily ported to linux.

Source code of make_vhdl_prom.c and and duplicate_byte.c is also delivered.

---------------------------------
Compiling for de10_lite
---------------------------------
You can rebuild the project with ROM image embeded in the sof file. DO NOT REDISTRIBUTE THESE FILES.
4 steps

 - put the VHDL rom files into the project directory
 - rebuild ckong_de10_lite project
 - program ckong_de10_lite.sof into the fpga 

--------------------
Keyboard and swicth
--------------------
Use directional key to move, space to jump, F1/F2 to start player 1/2 and F3 for coins.
de10_lite sw0 allow to switch 15kHz/31kHz

------------------------
End of file
------------------------