@echo off




copy /b ic13_1t.bin + ic14_2t.bin + ic15_3t.bin + ic16_4t.bin + ic17_5t.bin + ic18_6t.bin CPU1.bin
romgen.exe CPU1.bin ROM_PGM_0 14 a r > rom0.vhd

copy /b ic56_1.bin ROM_SND_0.bin
romgen.exe ROM_SND_0.bin ROM_SND_0 11 a r > ROM_SND_0.vhd

copy /b ic55_2.bin ROM_SND_1.bin
romgen.exe ROM_SND_1.bin ROM_SND_1 11 a r > ROM_SND_1.vhd


copy /b ic30_2c.bin ROM_OBJ_0.bin
romgen.exe ROM_OBJ_0.bin ROM_OBJ_0 11 a r > ROM_OBJ_0.vhd

copy /b ic31_1c.bin ROM_OBJ_1.bin
romgen.exe ROM_OBJ_1.bin ROM_OBJ_1 11 a r > ROM_OBJ_1.vhd


pause
