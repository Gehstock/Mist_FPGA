copy /B 1a.cpu + 2a.cpu + 3.cpu + 4.cpu + 5.cpu LOCOMOTION.ROM
make_vhdl_prom LOCOMOTION.ROM loc_prg_rom.vhd

copy /B 5l_c1.bin + c2.cpu gfx1.bin
make_vhdl_prom gfx1.bin loc_chr_rom.vhd

make_vhdl_prom 10g.bpr loc_dot_rom.vhd

make_vhdl_prom 1b_s1.bin loc_snd_rom.vhd



make_vhdl_prom 8b.bpr loc_pal_rom.vhd
make_vhdl_prom 9d.bpr loc_col_rom.vhd

pause

