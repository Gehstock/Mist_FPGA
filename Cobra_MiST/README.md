cobra-fpga
==========

Cobra computer in FPGA

Cobra is DIY home computer published around 1985 in Audio-Video magazine.

Z80 processor clocked at 3.25MHz
16KB RAM + 1KB video RAM
2KB ROM with monitor (no build-in Basic)

Pin UART_RX is cassette player input. Use simple comparator to convert analogue signal to digital (3.3V level!).

Command "L" will Start Tape Loading (not tested)

FPGA Board: Mist FPGA
