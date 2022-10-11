Common components for MiST board
================================

This repository contains common components, which should be used by almost all cores.
The modules:

- user_io.v - communicating with the IO controller.
- data_io.v - handling file uploads from the IO controller.
- mist_video.v - a video pipeline, which gives an optional scandoubler, OSD and rgb2ypbpr conversion.
- osd.v, scandoubler.v, rgb2ypbpr.v, cofi.sv - these are used in mist_video, but can be used separately, too.
- sd_card.v - gives an SPI interface with SD-Card commands towards the IO-Controller, accessing .VHD and other mounted files.
- ide.v, ide_fifo.v - a bridge between a CPU and the data_io module for IDE/ATAPI disks.
- cdda_fifo.v - a module which connects data_io with a DAC for CDDA playback.
- dac.vhd - a simple sigma-delta DAC for audio output.
- arcade_inputs.v - mostly for arcade-style games, gives access to the joysticks with MAME-style keyboard mapping.
- mist.vhd - VHDL component declarations for user_io and mist_video.
- mist_core.qip - collects the core components, which are needed in almost every case.

Usage hints
===========

All of these components should be clocked by a synchronous clock to the core. The data between the external SPI
interface and this internal clock are synchronized. However to make Quartus' job easier, you have to tell it to
don't try to optimize paths between the SPI and the system clock domain. Also you have to define the incoming
27 MHz and the SPI clocks. These lines in the .sdc file do that:

```
set sys_clk "your_system_clock"

create_clock -name {clk_27} -period 37.037 -waveform { 0.000 18.500 } [get_ports {CLOCK_27[0]}]
create_clock -name {SPI_SCK}  -period 41.666 -waveform { 20.8 41.666 } [get_ports {SPI_SCK}]
set_clock_groups -asynchronous -group [get_clocks {SPI_SCK}] -group [get_clocks $sys_clk]
```

Replace "your_system_clock" with the name of the pll clock, like "pll|altpll_component|auto_generated|pll1|clk[0]".
