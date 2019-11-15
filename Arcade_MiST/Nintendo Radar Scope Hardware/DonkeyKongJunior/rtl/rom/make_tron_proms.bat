copy /b 0000 + 1000 + 1800 + 2000 + 2800 + 3000 + 4000 + 4800 + 5000 + 5800 prog.bin

make_vhdl_prom prog.bin prog.vhd


make_vhdl_prom v_3na.bin vid1.vhd
make_vhdl_prom dkjr10 vid2.vhd

make_vhdl_prom v_7c.bin obj1.vhd
make_vhdl_prom v_7d.bin obj2.vhd
make_vhdl_prom v_7e.bin obj3.vhd
make_vhdl_prom v_7f.bin obj4.vhd

make_vhdl_prom c-2e.bpr col1.vhd
make_vhdl_prom c-2f.bpr col2.vhd
make_vhdl_prom v-2n.bpr col3.vhd


make_vhdl_prom c_3h.bin snd1.vhd
pause
