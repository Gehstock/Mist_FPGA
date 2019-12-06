copy /B jungr1 + jungr2 + jungr3 + jungr4 JUNGLER.ROM
make_vhdl_prom JUNGLER.ROM jng_prg_rom.vhd

copy /B 5k + 5m gfx1.bin
make_vhdl_prom gfx1.bin jng_chr_rom.vhd

make_vhdl_prom 82s129.10g jng_dot_rom.vhd

make_vhdl_prom 1b jng_snd_rom.vhd



make_vhdl_prom 18s030.8b jng_pal_rom.vhd
make_vhdl_prom tbp24s10.9d jng_col_rom.vhd

