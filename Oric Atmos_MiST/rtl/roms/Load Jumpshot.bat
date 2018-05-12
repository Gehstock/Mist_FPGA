@echo off

cls

echo Generating intermediate file from : basic11b : rom.vhd
romgen.exe basic11b.rom rom 14 a \n e > rom.vhd


pause
