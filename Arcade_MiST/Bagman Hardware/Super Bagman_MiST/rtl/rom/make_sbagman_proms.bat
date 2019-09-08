copy /B 5.9e + 6.9f + 7.9j + 8.9k + 9.9m + 10.9n SBAGMAN.ROM
make_vhdl_prom SBAGMAN.ROM sbagman_program.vhd

copy /B 13part1 + 16part2 + 14part1 + 15part2 + 14part3 + 15part1 + 14part2 + 15part3 + 16part1 + 13part2 SBAGMAN2.ROM
make_vhdl_prom.exe SBAGMAN2.ROM sbagman_program2.vhd

make_vhdl_prom 11.9r sbagman_speech1.vhd
make_vhdl_prom 12.9t sbagman_speech2.vhd

copy /B p3.bin + r3.bin bagman_palette
make_vhdl_prom bagman_palette bagman_palette.vhd

copy /B 2.1e + 1.1c sbagman_tile0
copy /B 4.1j + 3.1f sbagman_tile1
make_vhdl_prom sbagman_tile0 sbagman_tile_bit0.vhd
make_vhdl_prom sbagman_tile1 sbagman_tile_bit1.vhd

