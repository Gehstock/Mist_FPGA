
copy /B p1 + p2 + p3 power_surge_prog.bin
make_vhdl_prom power_surge_prog.bin power_surge_prog.vhd
copy /B p6 + p7 power_surge_sound.bin
make_vhdl_prom power_surge_sound.bin power_surge_sound_prog.vhd
make_vhdl_prom p4 power_surge_char_grphx.vhd
copy /B p5 + tm5 power_surge_sprite_grphx.bin
make_vhdl_prom power_surge_sprite_grphx.bin power_surge_sprite_grphx.vhd



make_vhdl_prom timeplt.b4  power_surge_palette_blue_green.vhd
make_vhdl_prom timeplt.b5  power_surge_palette_green_red.vhd
make_vhdl_prom timeplt.e9  power_surge_sprite_color_lut.vhd
make_vhdl_prom timeplt.e12 power_surge_char_color_lut.vhd



pause