#!/bin/sh -x

cat zippyrac.000 zippyrac.005 zippyrac.006 zippyrac.007 > travusa_cpu.bin
./make_vhdl_prom travusa_cpu.bin travusa_cpu.vhd

./make_vhdl_prom zippyrac.001 travusa_chr_bit1.vhd
./make_vhdl_prom mr8.3c travusa_chr_bit2.vhd
./make_vhdl_prom mr9.3a travusa_chr_bit3.vhd

./make_vhdl_prom mmi6349.ij travusa_chr_palette.vhd

./make_vhdl_prom zippyrac.008 travusa_spr_bit1.vhd
./make_vhdl_prom zippyrac.009 travusa_spr_bit2.vhd
./make_vhdl_prom zippyrac.010 travusa_spr_bit3.vhd

./make_vhdl_prom tbp24s10.3 travusa_spr_palette.vhd
./make_vhdl_prom tbp18s.2 travusa_spr_rgb_lut.vhd

./make_vhdl_prom mr10.1a travusa_sound.vhd

#rem zr1-0.m3     CRC(be066c0a) 
#rem zr1-5.l3     CRC(145d6b34) 
#rem zr1-6a.k3    CRC(e1b51383) 
#rem zr1-7.j3     CRC(85cd1a51)
#rem mr10.1a      CRC(a02ad8a0)
#rem zippyrac.001 CRC(aa8994dd)
#rem mr8.3c       CRC(3a046dd1)
#rem mr9.3a       CRC(1cc3d3f4)
#rem zr1-8.n3     CRC(3e2c7a6b)
#rem zr1-9.l3     CRC(13be6a14)
#rem zr1-10.k3    CRC(6fcc9fdb)
#rem mmi6349.ij   CRC(c9724350)
#rem tbp18s.2     CRC(a1130007)
#rem tbp24s10.3   CRC(76062638)
