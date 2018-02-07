@echo off


copy /b/y warofbug.1j + warofbug.1k gfx1.bin > NUL
copy /b/y warofbug.u + warofbug.v + warofbug.w + warofbug.y + warofbug.z main.bin > NUL



romgen warofbug.cla    GALAXIAN_6L  5 a r e     > GALAXIAN_6L.vhd


romgen gfx1.bin        GFX1      12 a r e > GFX1.vhd
romgen main.bin        ROM_PGM_0 14 a r e > ROM_PGM_0.vhd

romgen warofbug.1j    GALAXIAN_1H 11 a r e > GALAXIAN_1H.vhd
romgen warofbug.1k    GALAXIAN_1K 11 a r e > GALAXIAN_1K.vhd


echo done
pause
