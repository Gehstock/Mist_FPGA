copy /b epr-5320b.129 + epr-5321a.130 + epr-5322a.131 + epr-5323.132 + epr-5324.133 + epr-5325.134 + epr-5324.133 + epr-5325.134 prg.bin
make_vhdl_prom prg.bin prg_rom.vhd

copy /b epr-5318.86 + epr-5319.93 spr.bin
make_vhdl_prom spr.bin spr_rom.vhd

make_vhdl_prom epr-5332.3 snd_rom.vhd

make_vhdl_prom pr-5317.106 clut.vhd

copy /b epr-5331.82 + epr-5330.65 + epr-5329.81 + epr-5328.64 + epr-5327.80 + epr-5326.63 tile.bin

copy /b prg.bin + epr-5332.3 + spr.bin + tile.bin STARJACK.ROM
pause


