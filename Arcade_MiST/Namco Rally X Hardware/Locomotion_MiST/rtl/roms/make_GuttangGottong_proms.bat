copy /B 3d_1.bin + 3e_2.bin + 3f_3.bin + 3h_4.bin + 3j_5.bin JUNGLER.ROM
make_vhdl_prom JUNGLER.ROM jng_prg_rom.vhd

copy /B 5l_c1.bin + 5m_c2.bin gfx1.bin
make_vhdl_prom gfx1.bin jng_chr_rom.vhd

make_vhdl_prom 10g.bpr jng_dot_rom.vhd

make_vhdl_prom 1b_s1.bin jng_snd_rom.vhd



make_vhdl_prom 8b.bpr jng_pal_rom.vhd
make_vhdl_prom 9d.bpr jng_col_rom.vhd

