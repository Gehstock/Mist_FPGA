copy /b lr-a-4e + lr-a-4d + lr-a-4b + lr-a-4a prog.bin
make_vhdl_prom.exe prog.bin prog.vhd

make_vhdl_prom.exe lr-b-5p rom_sprite_high_new.vhd


copy /b lr-a-3f + lr-a-3h snd.bin
make_vhdl_prom.exe snd.bin snd_prg.vhd

copy /b prog.bin + snd.bin LDRUNNER.ROM
pause