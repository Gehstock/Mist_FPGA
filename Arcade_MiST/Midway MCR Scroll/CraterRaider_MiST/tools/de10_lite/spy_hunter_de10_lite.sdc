create_clock -name clk1_50 -period 20 [get_ports {max10_clk1_50}]


derive_pll_clocks -create_base_clocks

derive_clock_uncertainty

