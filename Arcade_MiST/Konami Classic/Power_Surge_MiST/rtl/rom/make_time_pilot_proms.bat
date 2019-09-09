
copy /B p1 + p2 + p3 time_pilot_prog.bin
make_vhdl_prom time_pilot_prog.bin time_pilot_prog.vhd
copy /B p6 + p7 time_pilot_sound.bin
make_vhdl_prom time_pilot_sound.bin time_pilot_sound_prog.vhd
make_vhdl_prom p4 time_pilot_char_grphx.vhd
copy /B p5 + tm5 time_pilot_sprite_grphx.bin
make_vhdl_prom time_pilot_sprite_grphx.bin time_pilot_sprite_grphx.vhd



make_vhdl_prom timeplt.b4  time_pilot_palette_blue_green.vhd
make_vhdl_prom timeplt.b5  time_pilot_palette_green_red.vhd
make_vhdl_prom timeplt.e9  time_pilot_sprite_color_lut.vhd
make_vhdl_prom timeplt.e12 time_pilot_char_color_lut.vhd



