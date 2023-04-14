#************************************************************
# THIS IS A WIZARD-GENERATED FILE.                           
#
# Version 13.1.4 Build 182 03/12/2014 SJ Full Version
#
#************************************************************

# Copyright (C) 1991-2014 Altera Corporation
# Your use of Altera Corporation's design tools, logic functions 
# and other software and tools, and its AMPP partner logic 
# functions, and any output files from any of the foregoing 
# (including device programming or simulation files), and any 
# associated documentation or information are expressly subject 
# to the terms and conditions of the Altera Program License 
# Subscription Agreement, Altera MegaCore Function License 
# Agreement, or other applicable license agreement, including, 
# without limitation, that your use is for the sole purpose of 
# programming logic devices manufactured by Altera and sold by 
# Altera or its authorized distributors.  Please refer to the 
# applicable agreement for further details.



# Clock constraints

create_clock -name {SPI_SCK}  -period 41.666 -waveform { 20.8 41.666 } [get_ports {SPI_SCK}]

# Automatically constrain PLL and other generated clocks
derive_pll_clocks -create_base_clocks

# Automatically calculate clock uncertainty to jitter and other effects.
derive_clock_uncertainty

set_clock_groups -asynchronous -group [get_clocks {SPI_SCK}] -group [get_clocks {pll|altpll_component|auto_generated|pll1|clk[*]}]

set_output_delay -add_delay  -clock_fall -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}]  1.000 [get_ports {AUDIO_L}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}]  1.000 [get_ports {AUDIO_R}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}]  1.000 [get_ports {LED}]
set_output_delay -add_delay  -clock_fall -clock [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}]  1.000 [get_ports {VGA_*}]

set_multicycle_path -to {VGA_*[*]} -setup 2
set_multicycle_path -to {VGA_*[*]} -hold 1
