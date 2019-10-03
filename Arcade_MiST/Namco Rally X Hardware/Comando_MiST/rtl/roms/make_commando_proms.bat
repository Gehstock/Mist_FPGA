copy /B csega1 + csega2 + csega3 + csega4 + csega5 JUNGLER.ROM
make_vhdl_prom COMMANDO.ROM cmd_prg_rom.vhd

copy /B csega7 + csega6 gfx1.bin
make_vhdl_prom gfx1.bin cmd_chr_rom.vhd

make_vhdl_prom gg3.bpr cmd_dot_rom.vhd

make_vhdl_prom csega8 cmd_snd_rom.vhd



make_vhdl_prom gg1.bpr cmd_pal_rom.vhd
make_vhdl_prom gg2.bpr cmd_col_rom.vhd

