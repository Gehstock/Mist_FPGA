copy /b epr-6623.116 + epr6624a.109 + epr-6625.96 + epr-6625.96 prg.bin
make_vhdl_prom prg.bin prg_rom.vhd

copy /b epr6454a.117 + epr-6455.05 spr.bin
make_vhdl_prom spr.bin spr_rom.vhd

make_vhdl_prom epr-6462.120 snd_rom.vhd

make_vhdl_prom pr-5317.76 clut.vhd

copy /b epr6474a.62 + epr6473a.61 + epr6472a.64 + epr6471a.63 + epr6470a.66 + epr6469a.65 tile.bin

copy /b prg.bin + epr-6462.120 + spr.bin + tile.bin PITFALL.ROM
pause


