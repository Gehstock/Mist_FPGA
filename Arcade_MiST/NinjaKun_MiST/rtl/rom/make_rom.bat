copy /b ninja-1.7a + ninja-2.7b + ninja-3.7d + ninja-4.7e cpu1_rom.bin
copy /b ninja-5.7h + ninja-2.7b + ninja-3.7d + ninja-4.7e cpu2_rom.bin
copy /b ninja-10.2c + ninja-11.2d + ninja-12.4c + ninja-13.4d bg.bin
copy /b cpu1_rom.bin + cpu2_rom.bin + bg.bin NINJAKUN.ROM


make_vhdl_prom.exe ninja-10.2c fg1_rom.vhd
make_vhdl_prom.exe ninja-11.2d fg2_rom.vhd
make_vhdl_prom.exe ninja-12.4c fg3_rom.vhd
make_vhdl_prom.exe ninja-13.4d fg4_rom.vhd

pause