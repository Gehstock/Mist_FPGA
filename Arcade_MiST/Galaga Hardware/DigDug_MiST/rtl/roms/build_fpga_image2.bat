
copy /b dd1.1 + dd1.2 + dd1.3 + dd1.4b cpu0
make_vhdl_prom.exe cpu0 cpu0_rom.vhd

copy /b dd1.5b + dd1.6b cpu1
make_vhdl_prom.exe cpu1 cpu1_rom.vhd

make_vhdl_prom.exe dd1.7 cpu2_rom.vhd

make_vhdl_prom.exe dd1.9 fgchip_rom.vhd

copy /b dd1.15 + dd1.14 + dd1.13 + dd1.12 spchip
make_vhdl_prom.exe spchip spchip_rom.vhd

make_vhdl_prom.exe dd1.11 bgchip_rom.vhd

make_vhdl_prom.exe dd1.10b bgscrn_rom.vhd

make_vhdl_prom.exe 136007.113 palette_rom.vhd
make_vhdl_prom.exe 136007.111 spclut_rom.vhd
make_vhdl_prom.exe 136007.112 bgclut_rom.vhd

make_vhdl_prom.exe 136007.110 wave_rom.vhd
pause
