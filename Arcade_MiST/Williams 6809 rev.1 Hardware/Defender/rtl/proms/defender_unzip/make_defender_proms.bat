
copy /B defend.1 + defend.4 + defend.2 + defend.3 + defend.9 + defend.12 + defend.8 + defend.11 + defend.7 + defend.10 + defend.6 defender_prog.bin

make_vhdl_prom defender_prog.bin defender_prog.vhd
make_vhdl_prom decoder.2 defender_decoder_2.vhd
make_vhdl_prom decoder.3 defender_decoder_3.vhd
make_vhdl_prom defend.snd defender_sound.vhd