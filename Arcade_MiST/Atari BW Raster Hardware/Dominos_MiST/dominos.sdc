## Generated SDC file "dominos.sdc"

## Copyright (C) 1991-2013 Altera Corporation
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, Altera MegaCore Function License 
## Agreement, or other applicable license agreement, including, 
## without limitation, that your use is for the sole purpose of 
## programming logic devices manufactured by Altera and sold by 
## Altera or its authorized distributors.  Please refer to the 
## applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus II"
## VERSION "Version 13.0.1 Build 232 06/12/2013 Service Pack 1 SJ Full Version"

## DATE    "Wed Sep 12 21:23:53 2018"

##
## DEVICE  "EP3C25E144C8"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {CLOCK_27} -period 37.037 -waveform { 0.000 18.518 } [get_ports {CLOCK_27}]
create_clock -name {dominos:dominos|synchronizer:Vid_sync|h_counter[4]} -period 1.000 -waveform { 0.000 0.500 } [get_registers {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}]
create_clock -name {dominos:dominos|synchronizer:Vid_sync|h_counter[6]} -period 1.000 -waveform { 0.000 0.500 } [get_registers {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}]
create_clock -name {SPI_SCK} -period 1.000 -waveform { 0.000 0.500 } [get_ports {SPI_SCK}]
create_clock -name {dominos:dominos|synchronizer:Vid_sync|hsync_int} -period 1.000 -waveform { 0.000 0.500 } [get_registers {dominos:dominos|synchronizer:Vid_sync|hsync_int}]
create_clock -name {dominos:dominos|synchronizer:Vid_sync|h_counter[0]} -period 1.000 -waveform { 0.000 0.500 } [get_registers {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}]
create_clock -name {dominos:dominos|CPU_mem:CPU|Q5} -period 1.000 -waveform { 0.000 0.500 } [get_registers {dominos:dominos|CPU_mem:CPU|Q5}]
create_clock -name {dominos:dominos|synchronizer:Vid_sync|v_counter[7]} -period 1.000 -waveform { 0.000 0.500 } [get_registers {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}]
create_clock -name {dominos:dominos|audio:Sound|Oscillator:Tone_pulse|Osc_Clk} -period 1.000 -waveform { 0.000 0.500 } [get_registers {dominos:dominos|audio:Sound|Oscillator:Tone_pulse|Osc_Clk}]


#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name {pll|altpll_component|auto_generated|pll1|clk[0]} -source [get_pins {pll|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50.000 -multiply_by 112 -divide_by 125 -master_clock {CLOCK_27} [get_pins {pll|altpll_component|auto_generated|pll1|clk[0]}] 
create_generated_clock -name {pll|altpll_component|auto_generated|pll1|clk[1]} -source [get_pins {pll|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50.000 -multiply_by 56 -divide_by 125 -master_clock {CLOCK_27} [get_pins {pll|altpll_component|auto_generated|pll1|clk[1]}] 
create_generated_clock -name {pll|altpll_component|auto_generated|pll1|clk[2]} -source [get_pins {pll|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50.000 -multiply_by 28 -divide_by 125 -master_clock {CLOCK_27} [get_pins {pll|altpll_component|auto_generated|pll1|clk[2]}] 


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {CLOCK_27}]  0.010  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {CLOCK_27}]  0.010  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {CLOCK_27}]  0.010  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {CLOCK_27}]  0.010  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {CLOCK_27}] -rise_to [get_clocks {SPI_SCK}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {CLOCK_27}] -rise_to [get_clocks {SPI_SCK}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {CLOCK_27}] -fall_to [get_clocks {SPI_SCK}] -setup 0.100  
set_clock_uncertainty -rise_from [get_clocks {CLOCK_27}] -fall_to [get_clocks {SPI_SCK}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {CLOCK_27}] -rise_to [get_clocks {SPI_SCK}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {CLOCK_27}] -rise_to [get_clocks {SPI_SCK}] -hold 0.070  
set_clock_uncertainty -fall_from [get_clocks {CLOCK_27}] -fall_to [get_clocks {SPI_SCK}] -setup 0.100  
set_clock_uncertainty -fall_from [get_clocks {CLOCK_27}] -fall_to [get_clocks {SPI_SCK}] -hold 0.070  
set_clock_uncertainty -rise_from [get_clocks {SPI_SCK}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {SPI_SCK}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {SPI_SCK}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {SPI_SCK}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {SPI_SCK}] -rise_to [get_clocks {CLOCK_27}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {SPI_SCK}] -rise_to [get_clocks {CLOCK_27}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {SPI_SCK}] -fall_to [get_clocks {CLOCK_27}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {SPI_SCK}] -fall_to [get_clocks {CLOCK_27}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {SPI_SCK}] -rise_to [get_clocks {SPI_SCK}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {SPI_SCK}] -fall_to [get_clocks {SPI_SCK}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {SPI_SCK}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {SPI_SCK}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {SPI_SCK}] -rise_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {SPI_SCK}] -fall_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {SPI_SCK}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {SPI_SCK}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {SPI_SCK}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {SPI_SCK}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {SPI_SCK}] -rise_to [get_clocks {CLOCK_27}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {SPI_SCK}] -rise_to [get_clocks {CLOCK_27}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {SPI_SCK}] -fall_to [get_clocks {CLOCK_27}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {SPI_SCK}] -fall_to [get_clocks {CLOCK_27}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {SPI_SCK}] -rise_to [get_clocks {SPI_SCK}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {SPI_SCK}] -fall_to [get_clocks {SPI_SCK}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {SPI_SCK}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {SPI_SCK}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {SPI_SCK}] -rise_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {SPI_SCK}] -fall_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -rise_to [get_clocks {CLOCK_27}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -rise_to [get_clocks {CLOCK_27}] -hold 0.090  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -fall_to [get_clocks {CLOCK_27}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -fall_to [get_clocks {CLOCK_27}] -hold 0.090  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -rise_to [get_clocks {CLOCK_27}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -rise_to [get_clocks {CLOCK_27}] -hold 0.090  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -fall_to [get_clocks {CLOCK_27}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -fall_to [get_clocks {CLOCK_27}] -hold 0.090  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}]  0.010  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}]  0.010  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}]  0.010  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}]  0.010  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -rise_to [get_clocks {CLOCK_27}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -rise_to [get_clocks {CLOCK_27}] -hold 0.090  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -fall_to [get_clocks {CLOCK_27}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -fall_to [get_clocks {CLOCK_27}] -hold 0.090  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -rise_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -fall_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -rise_to [get_clocks {CLOCK_27}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -rise_to [get_clocks {CLOCK_27}] -hold 0.090  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -fall_to [get_clocks {CLOCK_27}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -fall_to [get_clocks {CLOCK_27}] -hold 0.090  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -rise_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}] -fall_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}] -rise_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}] -fall_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|hsync_int}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}] -rise_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}] -fall_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|audio:Sound|Oscillator:Tone_pulse|Osc_Clk}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}]  0.010  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|audio:Sound|Oscillator:Tone_pulse|Osc_Clk}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}]  0.010  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|audio:Sound|Oscillator:Tone_pulse|Osc_Clk}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}]  0.010  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|audio:Sound|Oscillator:Tone_pulse|Osc_Clk}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}]  0.010  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -rise_to [get_clocks {CLOCK_27}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -rise_to [get_clocks {CLOCK_27}] -hold 0.090  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -fall_to [get_clocks {CLOCK_27}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -fall_to [get_clocks {CLOCK_27}] -hold 0.090  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -rise_to [get_clocks {dominos:dominos|audio:Sound|Oscillator:Tone_pulse|Osc_Clk}]  0.010  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -fall_to [get_clocks {dominos:dominos|audio:Sound|Oscillator:Tone_pulse|Osc_Clk}]  0.010  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -rise_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -fall_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -rise_to [get_clocks {CLOCK_27}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -rise_to [get_clocks {CLOCK_27}] -hold 0.090  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -fall_to [get_clocks {CLOCK_27}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -fall_to [get_clocks {CLOCK_27}] -hold 0.090  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -rise_to [get_clocks {dominos:dominos|audio:Sound|Oscillator:Tone_pulse|Osc_Clk}]  0.010  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -fall_to [get_clocks {dominos:dominos|audio:Sound|Oscillator:Tone_pulse|Osc_Clk}]  0.010  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -rise_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}] -fall_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.100  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -rise_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -fall_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.100  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[6]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[4]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|v_counter[7]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -rise_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -fall_to [get_clocks {dominos:dominos|synchronizer:Vid_sync|h_counter[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -rise_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}] -fall_to [get_clocks {dominos:dominos|CPU_mem:CPU|Q5}]  0.020  


#**************************************************************
# Set Input Delay
#**************************************************************

set_input_delay -add_delay  -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {CLOCK_27}]
set_input_delay -add_delay  -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {CONF_DATA0}]
set_input_delay -add_delay  -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {SPI_DI}]
set_input_delay -add_delay  -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {SPI_SCK}]
set_input_delay -add_delay  -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {SPI_SS2}]
set_input_delay -add_delay  -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {SPI_SS3}]


#**************************************************************
# Set Output Delay
#**************************************************************

set_output_delay -add_delay  -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {AUDIO_L}]
set_output_delay -add_delay  -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {AUDIO_R}]
set_output_delay -add_delay  -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {LED}]
set_output_delay -add_delay  -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {SPI_DO}]
set_output_delay -add_delay  -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_B[0]}]
set_output_delay -add_delay  -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_B[1]}]
set_output_delay -add_delay  -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_B[2]}]
set_output_delay -add_delay  -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_B[3]}]
set_output_delay -add_delay  -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_B[4]}]
set_output_delay -add_delay  -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_B[5]}]
set_output_delay -add_delay  -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_G[0]}]
set_output_delay -add_delay  -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_G[1]}]
set_output_delay -add_delay  -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_G[2]}]
set_output_delay -add_delay  -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_G[3]}]
set_output_delay -add_delay  -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_G[4]}]
set_output_delay -add_delay  -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_G[5]}]
set_output_delay -add_delay  -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_HS}]
set_output_delay -add_delay  -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_R[0]}]
set_output_delay -add_delay  -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_R[1]}]
set_output_delay -add_delay  -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_R[2]}]
set_output_delay -add_delay  -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_R[3]}]
set_output_delay -add_delay  -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_R[4]}]
set_output_delay -add_delay  -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_R[5]}]
set_output_delay -add_delay  -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_VS}]


#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

