copy /b epr-5950.129 + epr-5951.130 + epr-5952.131 + epr-5953.132 + epr-5644.133 + epr-5955.134 + epr-5644.133 + epr-5955.134 prg.bin
make_vhdl_prom prg.bin prg_rom.vhd

copy /b epr-5638.86 + epr-5639.93 spr.bin
make_vhdl_prom spr.bin spr_rom.vhd

make_vhdl_prom epr-5652.3 snd_rom.vhd

make_vhdl_prom pr-5317.106 clut.vhd

copy /b epr-5651.82 + epr-5650.65 + epr-5649.81 + epr-5648.64 + epr-5647.80 + epr-5646.63 tile.bin

copy /b prg.bin + epr-5652.3 + spr.bin + tile.bin REGULUS.ROM
pause


