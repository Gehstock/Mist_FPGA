derive_pll_clocks
derive_clock_uncertainty

set CLK_VIDEO {*|pll|pll_inst|altera_pll_i|*[0].*|divclk}
set clk_sys {*|pll|pll_inst|altera_pll_i|*[1].*|divclk}

set_multicycle_path -to {emu|video|video_mixer|*} -setup 2
set_multicycle_path -to {emu|video|video_mixer|*} -hold 1

set_multicycle_path -to {emu|cpu|*} -setup 2
set_multicycle_path -to {emu|cpu|*} -hold 1
