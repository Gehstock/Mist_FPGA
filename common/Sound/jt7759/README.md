# JT7759

Verilog module compatible with NEC ADPCM decoder uPD7759

You can show your appreciation through
* [Patreon](https://patreon.com/topapate), by supporting releases
* [Paypal](https://paypal.me/topapate), with a donation

JT775x is an ADPCM sound source written in Verilog, fully compatible with NEC uPD7759.

## Architecture

NEC family of fixed phase playback devices. All use the ADPCM and PCM+waveform element method for synthesis at 5,6 or 8kHz of sampling frequency. The only one using an external memory was uPD7759. Although they all share the same architecture, only uPD7759 seems to be of interest to the classic computing community.

Device | ROM type | ROM size
-------|----------|-----------
 7755  |   mask   |   96 kbit
 7756A |   mask   |  256 kbit
 7757  |   mask   |  516 kbit
 7758  |   mask   | 1024 kbit
 7756  |   PROM   |  256 kbit
 7759  | external | 1024 kbit

### Control State Machine



## Port Description

Name     | Direction | Width | Purpose
---------|-----------|-------|--------------------------------------
rst      | input     |       | active-high asynchronous reset signal
clk      | input     |       | clock - use the same as the sound CPU
cen      | input     |       | clock enable
din      | input     | 8     | input data from CPU
dout     | output    | 8     | output data to CPU
mdn      | input     |       | Mode selection
stn      | input     |       | Start. Used only if mdn is low.
drq      | output    |       | Data request
rom_addr | output    | 18    | Memory address to be read
rom_data | input     | 8     | Data read
rom_ok   | input     | 1     | high when rom_data is valid and matches rom_addr
sound    | output    | 14    | signed sound output

## Usage

uDP7759 ROMs have the following header:

Byte  | Usage
------|------------------
 0    | Number of samples
 1    | Must be 0x5A
 2    | Must be 0xA5
 3    | Must be 0x69
 4    | Must be 0x55

If used in slave mode, tie rom_ok low.

After each reset the number of samples and the signature are read. If the signature is not correct, no samples will be played. If the verilog macro **SIMULATION** is defined, the simulation will stop if the signature is wrong.

If the simulator used supports X values, you need to define the macro **SIMULATION** to avoid X's in the divider module.

If the macro **JT7759_FIFO_DUMP** is defined, each byte read will be displayed during simulation.

### Implemented Features

Feature     |  Status
------------|------------------
Slave Mode  | Implemented
Master Mode | Partially implemented

Features of master mode:

Feature            |  Status
-------------------|------------------
Signature          | Implemented
Silence            | Implemented
Play short         | Implemented
Play long          | Implemented
Address latch port | Not implemented
Repeat silence     | Not implemented

Silence length is taken as a reasonable approximation to the 1ms quoted in MAME, which is also a reasonable approximation of the MAME author. In hardware the ~ 1ms is obtained as a 128 count at 640Hz/4, which makes sense from the point of view of implementation (rather than an exact 1ms).

### ROM interface

Port     | Direction | Meaning
---------|-----------|----------------------------
rom_cs   | output    | high when address is valid
rom_addr | output    | Addres to be read
rom_data | input     | Data read from address
rom_ok   | input     | Data read is valid

Note that rom_ok is not valid for the clock cycle immediately after rising rom_cs. Or if rom_addr is changed while rom_cs is high. rom_addr must be stable once rom_cs goes high until rom_ok is asserted.

Although this module is designed for usage in systems fully implemented inside an FPGA, it is possible to adapt it to work as a replacement for the original chip. In such a case, the ROM interface would need be changed in order to implement the original signal scheme.

## FPGA arcade cores using this module:

* [Combat School](https://github.com/jotego/jtcontra), by the same author
* [System16](https://github.com/jotego/jts16), by the same author

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
NEC uPN7759            | [JT7759](https://github.com/jotego/jt7759)
WE DSP16 (QSound)      | [JT7759](https://github.com/jotego/jtdsp16)