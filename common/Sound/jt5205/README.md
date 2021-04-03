# jt5205 hardware by Jose Tejada (@topapate)

You can show your appreciation through
* [Patreon](https://patreon.com/topapate), by supporting releases
* [Paypal](https://paypal.me/topapate), with a donation

JT5205 is an ADPCM sound source written in Verilog, fully compatible with OKI MSM5205.

## Port Description

Name     | Direction | Width | Purpose
---------|-----------|-------|--------------------------------------
rst      | input     |       | active-high asynchronous reset signal
clk      | input     |       | clock
cen      | input     |       | clock enable.
sel      | input     | 2     | selects the data rate
din      | input     | 4     | input data
sound    | output    | 12    | signed sound output

## Usage

This is a pin-to-pin compatible module with OKI MSM5205. If you are just going to use it on a retro core you don't need to know the internals of it just hook it up and be sure that the effective clock rate, i.e. clk&cen signal, is the intended 384kHz (or whatever your system needs).

If you hear a periodic noise when there should be no output, check whether your target system was leaving the MSM5205 halted at reset when no output was needed. If The part is not reset it will keep processing the output and a constant 0 input will produce a repetitive noise.

## FPGA arcade cores using this module:

* [Double Dragon](https://github.com/jotego/jtdd), by the same author
* [Tora e no michi](https://github.com/jotego/jt_gng), by the same author

## Related Projects

Other sound chips from the same author

Chip                   | Repository
-----------------------|------------
YM2203, YM2612, YM2610 | [JT12](https://github.com/jotego/jt12)
YM2151                 | [JT51](https://github.com/jotego/jt51)
YM3526                 | [JTOPL](https://github.com/jotego/jtopl)
YM2149                 | [JT49](https://github.com/jotego/jt49)
sn76489an              | [JT89](https://github.com/jotego/jt89)
OKI 6295               | [JT6295](https://github.com/jotego/jt6295)
OKI MSM5205            | [JT5205](https://github.com/jotego/jt5205)