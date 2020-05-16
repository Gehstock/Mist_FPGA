copy /b epr-5679.129 + epr-5680.130 + epr-5681.131 + epr-5682.132 + epr-5520.133 + epr-5684.133 + epr-5520.133 + epr-5684.133 prg.bin
make_vhdl_prom prg.bin prg_rom.vhd

copy /b epr-5514.86 + epr-5515.93 spr.bin
make_vhdl_prom spr.bin spr_rom.vhd

make_vhdl_prom epr-5528.3 snd_rom.vhd

make_vhdl_prom pr-5317.106 clut.vhd

copy /b epr-5527.82 + epr-5526.65 + epr-5525.81 + epr-5524.64 + epr-5523.80 + epr-5522.63 tile.bin

copy /b prg.bin + epr-5528.3 + spr.bin + tile.bin UPNDOWN.ROM
pause


