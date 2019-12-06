copy /B demo_drby_pro_0 + demo_drby_pro_1 + demo_drby_pro_2 + demo_drby_pro_3  dderby_cpu.bin
make_vhdl_prom dderby_cpu.bin dderby_cpu.vhd

##copy /B tapsnda7.bin + tapsnda8.bin + tapsnda9.bin + tapsda10.bin dderby_sound_cpu.bin
##make_vhdl_prom dderby_sound_cpu.bin dderby_sound_cpu.vhd

copy /b dderby_cpu.bin + dderby_cpu.bin DDERBY.ROM

make_vhdl_prom demo_derby_bg_06f.6f dderby_bg_bits_1.vhd
make_vhdl_prom demo_derby_bg_15f.5f dderby_bg_bits_2.vhd 

copy /B demo_derby_fg0_a4.a4 + demo_derby_fg4_a3.a3 dderby_sp_bits_1.bin
copy /B demo_derby_fg1_a6.a6 + demo_derby_fg5_a5.a5 dderby_sp_bits_2.bin
copy /B demo_derby_fg2_a8.a8 + demo_derby_fg6_a7.a7 dderby_sp_bits_3.bin
copy /B demo_derby_fg3_a10.a10 + demo_derby_fg7_a9.a9 dderby_sp_bits_4.bin

make_vhdl_prom dderby_sp_bits_1.bin dderby_sp_bits_1.vhd
make_vhdl_prom dderby_sp_bits_2.bin dderby_sp_bits_2.vhd
make_vhdl_prom dderby_sp_bits_3.bin dderby_sp_bits_3.vhd
make_vhdl_prom dderby_sp_bits_4.bin dderby_sp_bits_4.vhd


make_vhdl_prom 82s123.12d midssio_82s123.vhd

pause

