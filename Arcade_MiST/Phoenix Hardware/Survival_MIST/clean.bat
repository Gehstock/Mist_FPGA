@echo off
del /s *.bak
del /s *.orig
del /s *.rej
rmdir /s /q db
rmdir /s /q incremental_db
rmdir /s /q output_files
rmdir /s /q simulation
rmdir /s /q greybox_tmp
del PLLJ_PLLSPE_INFO.txt
del /s /q build_id.v
del *.qws
del *.ppf
del *.qip
del *.ddb
pause
