copy /b ss.01e + ss.02e + ss.03e cpu.rom

copy /b ss_7.b6 + ss_8.b5 tile.rom

copy /b ss_9.m5 + ss_10.m6 + ss_11.m3 + ss_12.m4 + ss_13.m1 + ss_14.m2 sprite.rom

copy /b cpu.rom + tile.rom + sprite.rom SONSON.ROM


make_vhdl_prom ss_6.c11 sound_rom.vhd