


make_vhdl_prom crcpu.10g crater_ch_bits.vhd

copy /B crcpu.3a + crcpu.4a crater_bg_bits_1.bin
copy /B crcpu.5a + crcpu.6a crater_bg_bits_2.bin
make_vhdl_prom crater_bg_bits_1.bin  crater_bg_bits_1.vhd
make_vhdl_prom crater_bg_bits_2.bin  crater_bg_bits_2.vhd


copy /B crcpu.6d + crcpu.7d + crcpu.8d + crcpu.9d + crcpu.10d crater_cpu.bin
copy /B crsnd4.a7 + crsnd1.a8 + crsnd2.a9 + crsnd3.a10 crater_sound_cpu.bin


make_vhdl_prom 82s123.12d midssio_82s123.vhd

copy /B crvid.a4 + crvid.a3 crater_sp_bits_1.bin
copy /B crvid.a6 + crvid.a5 crater_sp_bits_2.bin
copy /B crvid.a8 + crvid.a7 crater_sp_bits_3.bin
copy /B crvid.a10 + crvid.a9 crater_sp_bits_4.bin

copy /B crater_cpu.bin + crater_sound_cpu.bin + crater_sp_bits_1.bin + crater_sp_bits_2.bin + crater_sp_bits_3.bin + crater_sp_bits_4.bin CRATER.ROM

pause
