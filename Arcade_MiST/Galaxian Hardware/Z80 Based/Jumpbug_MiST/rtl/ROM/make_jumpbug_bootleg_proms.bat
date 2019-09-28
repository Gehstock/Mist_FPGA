copy /B jb1 + jb2 + jb3 + jb4 prog1.bin
copy /B jb5 + jb6 + jb7 prog2.bin
make_vhdl_prom prog1.bin program0.vhd
make_vhdl_prom prog2.bin program1.vhd

copy /B jb1 + jb2 + jb3b + jb4 prog1x.bin
copy /B jb5b + jb6b + jb7b prog2x.bin
make_vhdl_prom prog1x.bin program0x.vhd
make_vhdl_prom prog2x.bin program1x.vhd

copy /B jbl + jbm + jbn gfx1.bin
copy /B jbi + jbj + jbk gfx2.bin

make_vhdl_prom gfx1.bin gfx1.vhd
make_vhdl_prom gfx2.bin gfx2.vhd

make_vhdl_prom l06_prom.bin col.vhd




