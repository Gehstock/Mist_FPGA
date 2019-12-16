copy /B ttprog0.bin + ttprog1.bin + ttprog2.bin + ttprog3.bin + ttprog4.bin + ttprog5.bin + ttprog5.bin ttag_cpu.bin
copy /B ttu7.bin + ttu17.bin + ttu8.bin + ttu18.bin ttag_sound_cpu.bin

make_vhdl_prom ttan.bin ttag_ch_bits.vhd

copy /B ttbg0.bin + ttbg1.bin ttag_bg_bits_1.bin
copy /B ttbg2.bin + ttbg3.bin ttag_bg_bits_2.bin
make_vhdl_prom ttag_bg_bits_1.bin  ttag_bg_bits_1.vhd
make_vhdl_prom ttag_bg_bits_2.bin  ttag_bg_bits_2.vhd



make_vhdl_prom 82s123.12d midssio_82s123.vhd

copy /B ttfg1.bin + ttfg0.bin ttag_sp_bits_1.bin
copy /B ttfg3.bin + ttfg2.bin ttag_sp_bits_2.bin
copy /B ttfg5.bin + ttfg4.bin ttag_sp_bits_3.bin
copy /B ttfg7.bin + ttfg6.bin ttag_sp_bits_4.bin


copy /b ttag_cpu.bin + ttag_sound_cpu.bin +  ttag_sp_bits_1.bin + ttag_sp_bits_2.bin + ttag_sp_bits_3.bin + ttag_sp_bits_4.bin TURBOTAG.ROM

pause

