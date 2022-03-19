make_vhdl_prom.exe 7649.ic60 turkey_shoot_decoder.vhd

copy /B rom17.ic26 + rom15.ic24 turkey_shoot_bank_a.bin
copy /B rom16.ic25 + rom14.ic23 + rom13.ic21 + rom12.ic19 turkey_shoot_bank_b.bin
copy /B rom11.ic18 + rom9.ic16 + rom7.ic14 + rom5.ic12 turkey_shoot_bank_c.bin
copy /B rom10.ic17 + rom8.ic15 + rom6.ic13 + rom4.ic11 turkey_shoot_bank_d.bin
copy /B rom20.ic57 + rom21.ic58 + rom19.ic41 gfx.bin

copy /b rom18.ic55 + rom2.ic9 + rom3.ic10 + rom3.ic10 + turkey_shoot_bank_a.bin + turkey_shoot_bank_b.bin + turkey_shoot_bank_c.bin + turkey_shoot_bank_d.bin + rom1.ic8 + gfx.bin turkeys.rom

pause