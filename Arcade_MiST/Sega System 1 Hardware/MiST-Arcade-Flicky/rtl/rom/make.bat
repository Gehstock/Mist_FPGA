copy /b epr5978a.116 + epr5979a.109 prg.bin
make_vhdl_prom prg.bin prg_rom.vhd

copy /b epr-5855.117 + epr-5856.110 spr.bin
make_vhdl_prom spr.bin spr_rom.vhd

make_vhdl_prom epr-5869.120 snd_rom.vhd


make_vhdl_prom dec_flicky.bin dec_rom.vhd

make_vhdl_prom epr-5868.62 tile1.vhd

make_vhdl_prom pr-5317.76 clut.vhd

copy /b epr-5868.62 + epr-5867.61 + epr-5866.64 + epr-5865.63 + epr-5864.66 + epr-5863.65 tile.bin

copy /b prg.bin + epr-5869.120 + spr.bin + tile.bin FLICKY.ROM
pause