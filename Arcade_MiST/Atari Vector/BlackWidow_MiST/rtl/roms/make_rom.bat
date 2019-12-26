//copy /b 136017-101.d1 + 136017-102.ef1 + 136017-103.h1 + 136017-104.j1 + 136017-105.kl1 + 136017-106.m1 BWIDOW.ROM
//copy /b 136017-107.l7 + 136017-107.l7 + 136017-108.mn7 + 136017-109.np7 + 136017-110.r7 vec.rom
//make_vhdl_prom.exe BWIDOW.ROM bwidow_prog_rom.vhd
//make_vhdl_prom.exe vec.rom bwidow_vec_rom.vhd

make_vhdl_prom.exe 136017-101.d1 bwidow_pgm_rom1.vhd
make_vhdl_prom.exe 136017-102.ef1 bwidow_pgm_rom2.vhd
make_vhdl_prom.exe 136017-103.h1 bwidow_pgm_rom3.vhd
make_vhdl_prom.exe 136017-104.j1 bwidow_pgm_rom4.vhd
make_vhdl_prom.exe 136017-105.kl1 bwidow_pgm_rom5.vhd
make_vhdl_prom.exe 136017-106.m1 bwidow_pgm_rom6.vhd

make_vhdl_prom.exe 136017-107.l7 bwidow_vec_rom1.vhd
make_vhdl_prom.exe 136017-108.mn7 bwidow_vec_rom2.vhd
make_vhdl_prom.exe 136017-109.np7 bwidow_vec_rom3.vhd
make_vhdl_prom.exe 136017-110.r7 bwidow_vec_rom4.vhd

pause