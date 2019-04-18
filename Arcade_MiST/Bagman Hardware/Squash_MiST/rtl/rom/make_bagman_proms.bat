copy /B sq5.3.9e + sq6.4.9f + sq7.5.9j prog.bin
copy /B mmi6331.3p + mmi6331.3r bagman_palette.bin
copy /B sq2.1.1e + sq1.1c  bagman_tile0.bin
copy /B sq4.2.1j + sq3.1f bagman_tile1.bin

make_vhdl_prom prog.bin bagman_program.vhd
make_vhdl_prom bagman_tile0.bin bagman_tile_bit0.vhd
make_vhdl_prom bagman_tile1.bin bagman_tile_bit1.vhd
make_vhdl_prom bagman_palette.bin bagman_palette.vhd

del prog.bin bagman_palette.bin bagman_tile0.bin bagman_tile1.bin




