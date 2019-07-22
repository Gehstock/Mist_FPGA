This is a preliminary Verilog implemenation of a replacement for the TMS9918A
VDP.  It outputs 800x600 VGA @ 60Hz, with each of the colors (R/G/B) having 4-bit
resolution.  It is (insofar as I know how to make it) compatible with the
original VDP.  It has a software selectable mode that allows all 32 sprites on
one line, however.

The only FPGA-specific module at this time is "vdp_clkgen" that uses an embedded
PLL to convert the 50MHz clock on my development board to 40MHz.  Either replace
it with your FPGA's equivalent or simply use an external 40MHz oscillator.

At the current resolution and clock frequency, I'm using this with an external
Alliance 512KB SRAM with 55ns access time.  The design has been pre-planned to
work with 25ns SRAMs at 65 MHz or more for 1024x768 SVGA resolution.

There are a number of major changes planned.  For example the non-working copy of
all the sprite data, some 960 flip-flops, will be replaced by an embedded RAM. 
The pattern shift registers will be greatly simplified as well.

This Verilog was written from scratch in a 2-week period, so it's not well
commented.  On the bright side, it's free.

Externally, I went with a "poor man's DAC" to convert the 4-bit R/G/B signals
into 1.4V for VGA.  I used an AD813 triple video op-amp in an inverting
configuration with resistors (20K, 10K, 5K, 2.5K, a clever young lad can
imagine how to do that with few parts) on the minus input, a 1K
potentiometer on the feedback path, and a 75 ohm series resistor on the
output.  Works perfectly.

---

Update: all planned TMS9918 emulation changes are in.  The internal RAM is 256
x 8-bit words, synchronous inputs and outputs. Making this change reduced
utilization of the (rather small) Cyclone II FPGA I'm using from 76% to 46%.

In order to enable "unlimited sprites per line" mode, set bit 0 of register 31.

I'll probably be going forward with adding features of the V9938 VDP to the
design such as 512 pixel width and 80-column text modes (using 1024x768 XVGA),
but I won't be posting any of that here since it goes beyond the scope of
recreating a historical TRS-80 peripheral device--the Mikrokolor.

Pete.

---

By the way, I don't like the way the tabs in the Verilog files got converted; they were originally 3 spaces each.

p.
