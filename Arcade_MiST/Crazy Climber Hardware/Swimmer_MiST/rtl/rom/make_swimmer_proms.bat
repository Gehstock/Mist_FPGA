copy /B sw1 + sw2 + sw3 + sw4 + sw5 + sw6 + sw7 + sw8 SWIMMER.ROM

copy /B sw23.6c + sw23.6c swimmer_big_sprite_tile_bit0
copy /B sw22.5c + sw22.5c swimmer_big_sprite_tile_bit1
copy /B sw21.4c + sw21.4c swimmer_big_sprite_tile_bit2
make_vhdl_prom swimmer_big_sprite_tile_bit0 swimmer_big_sprite_tile_bit0.vhd
make_vhdl_prom swimmer_big_sprite_tile_bit1 swimmer_big_sprite_tile_bit1.vhd
make_vhdl_prom swimmer_big_sprite_tile_bit2 swimmer_big_sprite_tile_bit2.vhd

make_vhdl_prom sw15.18k swimmer_tile_bit0.vhd
make_vhdl_prom sw14.18l swimmer_tile_bit1.vhd
make_vhdl_prom sw13.18m swimmer_tile_bit2.vhd

make_vhdl_prom 24s10.13b swimmer_palette2.vhd
make_vhdl_prom 24s10.13a swimmer_palette1.vhd
make_vhdl_prom 18s030.12c swimmer_big_sprite_palette.vhd

make_vhdl_prom sw12.4k swimmer_sound_rom.vhd




