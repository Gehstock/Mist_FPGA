
copy /B cb1.bin + cb2.bin + cb3.bin + cb4.bin prog.bin
copy /B v6.bin + u6.bin ckong_palette.bin

copy /B cb10part1.bin + emty2k.bin + cb10part2.bin  + emty2k.bin ckong_tile0.bin
copy /B cb9part1.bin + emty2k.bin + cb9part2.bin  + emty2k.bin ckong_tile1.bin

#copy /B tile0.bin ckong_tile0.bin
#copy /B tile1.bin ckong_tile1.bin
copy /B cb6.bin + cb5.bin ckong_samples.bin

make_vhdl_prom prog.bin ckong_program.vhd
make_vhdl_prom ckong_tile0.bin ckong_tile_bit0.vhd
make_vhdl_prom ckong_tile1.bin ckong_tile_bit1.vhd

make_vhdl_prom cb7.bin ckong_big_sprite_tile_bit0.vhd
make_vhdl_prom cb8.bin ckong_big_sprite_tile_bit1.vhd

make_vhdl_prom ckong_palette.bin ckong_palette.vhd
make_vhdl_prom t6.bin ckong_big_sprite_palette.vhd
make_vhdl_prom ckong_samples.bin ckong_samples.vhd






