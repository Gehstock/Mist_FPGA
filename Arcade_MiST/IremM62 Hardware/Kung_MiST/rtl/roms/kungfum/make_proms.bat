copy /b a-4e-c.bin + a-4d-c.bin prog.bin
make_vhdl_prom.exe prog.bin prog.vhd


copy /b a-3e-.bin + a-3f-.bin + a-3h-.bin snd.bin
make_vhdl_prom.exe snd.bin snd_prg.vhd

copy /b prog.bin + snd.bin KUNGFUM.ROM



copy /b b-4k-.bin + b-4f-.bin + b-4l-.bin + b-4h-.bin spr1.bin
copy /b b-3n-.bin + b-4n-.bin + b-4m-.bin + b-3m-.bin spr2.bin
copy /b b-4c-.bin + b-4e-.bin + b-4d-.bin + b-4a-.bin spr3.bin
pause