
copy /B 1pose5.bin + 2posf5.bin + 3posh5.bin + 4posk5.bin prog.bin
copy /B cposv6.bin + bposu6.bin ckong_palette.bin

copy /B bposn11part1.bin + emty2k.bin + bposn11part2.bin  + emty2k.bin ckong_tile0.bin
copy /B bposk11part1.bin + emty2k.bin + bposk11part2.bin  + emty2k.bin  ckong_tile1.bin

#copy /B tile0.bin ckong_tile0.bin
#copy /B tile1.bin ckong_tile1.bin
copy /B ck14poss5.bin + ck13posr5.bin ckong_samples.bin

make_vhdl_prom prog.bin ckong_program.vhd
make_vhdl_prom ckong_tile0.bin ckong_tile_bit0.vhd
make_vhdl_prom ckong_tile1.bin ckong_tile_bit1.vhd

make_vhdl_prom ck2posc11.bin ckong_big_sprite_tile_bit0.vhd
make_vhdl_prom ck1posa11.bin ckong_big_sprite_tile_bit1.vhd

make_vhdl_prom ckong_palette.bin ckong_palette.vhd
make_vhdl_prom apost6.bin ckong_big_sprite_palette.vhd
make_vhdl_prom ckong_samples.bin ckong_samples.vhd






