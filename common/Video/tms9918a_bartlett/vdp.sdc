set_time_format -unit ns -decimal_places 3

create_clock -name {clk50m_17} -period 20.000 -waveform { 0.000 10.000 } [get_ports {clk50m_17}]
create_generated_clock -name {clkgen|altpll_component|pll|clk[0]} -source [get_pins {clkgen|altpll_component|pll|inclk[0]}] -duty_cycle 50.000 -multiply_by 4 -divide_by 5 -master_clock {clk50m_17} [get_pins {clkgen|altpll_component|pll|clk[0]}] 

set_false_path -from [get_ports {cpu_a[*] cpu_d[*] cpu_in_n cpu_out_n cpu_rst_n por_73_n push_144_n}] \
	-to [get_clocks {clkgen|altpll_component|pll|clk[0]}]

set_false_path -from [get_ports {cpu_a[*]}] -to [get_ports {cpu_d[*]}]

set_false_path -from [get_registers {vdp_cpu:cpu|spr_mag vdp_cpu:cpu|spr_size}] \
	-to [get_registers {vdp_fsm:fsm|spr_color[*] vdp_fsm:fsm|spr_pattern vdp_fsm:fsm|spr_collide \
	                    vdp_fsm:fsm|spr_pat[*][*] vdp_fsm:fsm|spr_xvld[*] vdp_fsm:fsm|spr_odd[*]}]

set_false_path -to [get_ports {led1_3_n led2_7_n led3_9_n}]
set_false_path -from [get_ports {push_144_n por_73_n cpu_rst_n}]

set_multicycle_path -setup -end -from [get_registers {vdp_fsm:fsm|spr_hcount[*] vdp_fsm:fsm|spr_col[*][*]}] \
	-to [get_registers {vdp_fsm:fsm|spr_color[*] vdp_fsm:fsm|spr_pattern vdp_fsm:fsm|spr_collide vdp_fsm:fsm|spr_pat[*][*]}] 3
set_multicycle_path -hold -end -from [get_registers {vdp_fsm:fsm|spr_hcount[*] vdp_fsm:fsm|spr_col[*][*]}] \
	-to [get_registers {vdp_fsm:fsm|spr_color[*] vdp_fsm:fsm|spr_pattern vdp_fsm:fsm|spr_collide vdp_fsm:fsm|spr_pat[*][*]}] 3
set_multicycle_path -setup -end -from [get_registers {vdp_fsm:fsm|spr_dly[*][*] vdp_fsm:fsm|spr_pat[*][*] vdp_fsm:fsm|spr_vld[*]}] \
	-to [get_registers {vdp_fsm:fsm|spr_color[*] vdp_fsm:fsm|spr_pattern vdp_fsm:fsm|spr_collide vdp_fsm:fsm|spr_pat[*][*]}] 3
set_multicycle_path -hold -end -from [get_registers {vdp_fsm:fsm|spr_dly[*][*] vdp_fsm:fsm|spr_pat[*][*] vdp_fsm:fsm|spr_vld[*]}] \
	-to [get_registers {vdp_fsm:fsm|spr_color[*] vdp_fsm:fsm|spr_pattern vdp_fsm:fsm|spr_collide vdp_fsm:fsm|spr_pat[*][*]}] 3

set_max_delay -from [get_clocks {clkgen|altpll_component|pll|clk[0]}] -to [get_ports {b[*] g[*] r[*] hsync vsync}] 5.000
set_max_delay -from [get_clocks {clkgen|altpll_component|pll|clk[0]}] -to [get_ports {sram_a[*] sram_d[*] sram_oe_n sram_we_n}] 5.000
set_max_delay -from [get_clocks {clkgen|altpll_component|pll|clk[0]}] -to [get_ports {cpu_int_n}] 8.000
set_max_delay -from [get_ports {sram_d[*]}] -to [get_clocks {clkgen|altpll_component|pll|clk[0]}] 3.000
