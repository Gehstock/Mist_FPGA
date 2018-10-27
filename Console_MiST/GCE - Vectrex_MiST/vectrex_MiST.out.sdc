## Generated SDC file "vectrex_MiST.out.sdc"

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
## VERSION "Version 13.1.0 Build 162 10/23/2013 SJ Web Edition"

## DATE    "Sun Jun 24 12:53:00 2018"

##
## DEVICE  "EP3C25E144C8"
##

# Clock constraints

# Automatically constrain PLL and other generated clocks
derive_pll_clocks -create_base_clocks

# Automatically calculate clock uncertainty to jitter and other effects.
derive_clock_uncertainty

# tsu/th constraints

# tco constraints

# tpd constraints

#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {CLOCK_27} -period 37.037 -waveform { 0.000 18.518 } [get_ports {CLOCK_27}]


#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name {pll|altpll_component|auto_generated|pll1|clk[0]} -source [get_pins {pll|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50.000 -multiply_by 8 -divide_by 9 -master_clock {CLOCK_27} [get_pins {pll|altpll_component|auto_generated|pll1|clk[0]}] 
create_generated_clock -name {pll|altpll_component|auto_generated|pll1|clk[1]} -source [get_pins {pll|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50.000 -multiply_by 4 -divide_by 9 -master_clock {CLOCK_27} [get_pins {pll|altpll_component|auto_generated|pll1|clk[1]}] 


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {CLOCK_27}] -setup 0.090  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {CLOCK_27}] -hold 0.060  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {CLOCK_27}] -setup 0.090  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {CLOCK_27}] -hold 0.060  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {CLOCK_27}] -setup 0.090  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {CLOCK_27}] -hold 0.060  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {CLOCK_27}] -setup 0.090  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {CLOCK_27}] -hold 0.060  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}]  0.020  


#**************************************************************
# Set Input Delay
#**************************************************************

set_input_delay -add_delay  -clock_fall -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {CLOCK_27}]
set_input_delay -add_delay  -clock_fall -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {CONF_DATA0}]
set_input_delay -add_delay  -clock_fall -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {SPI_DI}]
set_input_delay -add_delay  -clock_fall -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {SPI_SCK}]
set_input_delay -add_delay  -clock_fall -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {SPI_SS2}]
set_input_delay -add_delay  -clock_fall -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {SPI_SS3}]


#**************************************************************
# Set Output Delay
#**************************************************************

set_output_delay -add_delay  -clock_fall -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {AUDIO_L}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {AUDIO_R}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {LED}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {SPI_DO}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_B[0]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_B[1]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_B[2]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_B[3]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_B[4]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_B[5]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_G[0]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_G[1]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_G[2]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_G[3]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_G[4]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_G[5]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_HS}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_R[0]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_R[1]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_R[2]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_R[3]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_R[4]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_R[5]}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {VGA_VS}]


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

