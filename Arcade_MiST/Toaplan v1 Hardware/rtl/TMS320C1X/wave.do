onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /TMS320C1X_tb/core/CE_F
add wave -noupdate /TMS320C1X_tb/core/CE_R
add wave -noupdate /TMS320C1X_tb/core/A
add wave -noupdate /TMS320C1X_tb/core/DI
add wave -noupdate /TMS320C1X_tb/core/DO
add wave -noupdate /TMS320C1X_tb/core/WE
add wave -noupdate /TMS320C1X_tb/core/DEN
add wave -noupdate /TMS320C1X_tb/core/MEN
add wave -noupdate /TMS320C1X_tb/core/PC
add wave -noupdate /TMS320C1X_tb/core/ACC
add wave -noupdate -expand /TMS320C1X_tb/core/AR
add wave -noupdate /TMS320C1X_tb/core/T
add wave -noupdate /TMS320C1X_tb/core/P
add wave -noupdate /TMS320C1X_tb/core/ST
add wave -noupdate /TMS320C1X_tb/core/IC
add wave -noupdate /TMS320C1X_tb/core/IW
add wave -noupdate /TMS320C1X_tb/core/STATE
add wave -noupdate /TMS320C1X_tb/core/DECI
add wave -noupdate /TMS320C1X_tb/core/ALU_R
add wave -noupdate /TMS320C1X_tb/core/STACK
add wave -noupdate /TMS320C1X_tb/core/RAM/WADDR
add wave -noupdate /TMS320C1X_tb/core/RAM/DATA
add wave -noupdate /TMS320C1X_tb/core/RAM/WREN
add wave -noupdate /TMS320C1X_tb/core/RAM/RADDR
add wave -noupdate /TMS320C1X_tb/core/RAM/Q
add wave -noupdate /TMS320C1X_tb/OUT0
add wave -noupdate /TMS320C1X_tb/OUT1
add wave -noupdate /TMS320C1X_tb/OUT2
add wave -noupdate /TMS320C1X_tb/OUT3
add wave -noupdate /TMS320C1X_tb/OUT7
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 2} {4857 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits us
update
WaveRestoreZoom {0 ns} {582 ns}
