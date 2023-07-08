
# Toaplan (Demon's World) FPGA Implementation

FPGA compatible core of Toaplan Version 1 arcade hardware for [**MiSTerFPGA**](https://github.com/MiSTer-devel/Main_MiSTer/wiki) written by [**Darren Olafson**](https://twitter.com/Darren__O). Based on OutZone schematics and verified against OutZone (TP-015 Conversion / TP-018).

The intent is for this core to be a 1:1 **game play** FPGA implementation of Toaplan V1 hardware. Currently in beta state, this core is in active development with assistance from [**atrac17**](https://github.com/atrac17).

Rally Bike (TP-012), Tatsujin (TP-013B), Hellfire (TP-014), Zero Wing (TP-015), OutZone (TP-018), Vimana (TP-019), and Fire Shark (TP-017) are also Toaplan V1 titles and have separate repositories located [**here**](https://github.com/va7deo?tab=repositories).

![demonwld](https://github.com/va7deo/demonswld/assets/32810066/bab39c32-54f9-482e-9b27-dd8a779f9273)

## Supported Titles

| Title                                                                                   | PCB<br>Number | Status      | Released |
|-----------------------------------------------------------------------------------------|---------------|-------------|----------|
| [**Demon's World / Horror Story**](https://en.wikipedia.org/wiki/Demon%27s_World)       | TP-016        | Implemented | Yes      |

## External Modules

| Module                                                                                | Function                                                                    | Author                                         |
|---------------------------------------------------------------------------------------|-----------------------------------------------------------------------------|------------------------------------------------|
| [**fx68k**](https://github.com/ijor/fx68k)                                            | [**Motorola 68000 CPU**](https://en.wikipedia.org/wiki/Motorola_68000)      | Jorge Cwik                                     |
| [**t80**](https://opencores.org/projects/t80)                                         | [**Zilog Z80 CPU**](https://en.wikipedia.org/wiki/Zilog_Z80)                | Daniel Wallner                                 |
| [**jtopl2**](https://github.com/jotego/jtopl)                                         | [**Yamaha OPL2**](https://en.wikipedia.org/wiki/Yamaha_OPL#OPL2)            | Jose Tejada                                    |
| [**yc_out**](https://github.com/MikeS11/MiSTerFPGA_YC_Encoder)                        | [**Y/C Video Module**](https://en.wikipedia.org/wiki/S-Video)               | Mike Simone                                    |
| [**mem**](https://github.com/MiSTer-devel/Arcade-Rygar_MiSTer/tree/master/src/mem)    | SDRAM Controller / Rom Downloader                                           | Josh Bassett; modified by Darren Olafson       |
| [**core_template**](https://github.com/MiSTer-devel/Template_MiSTer)                  | MiSTer Framework Template                                                   | sorgelig; modified by Darren Olafson / atrac17 |

# Known Issues / Tasks

- [**OPL2 Audio**](https://github.com/jotego/jtopl/issues/11)  **[Issue]**  
- Address timing issues with jtframe_mixer module usage; false paths added to sdc  **[Task]**  

# PCB Check List

### Clock Information

| H-Sync       | V-Sync      | Source    | PCB<br>Number |
|--------------|-------------|-----------|---------------|
| 15.556938kHz | 55.161153Hz | DSLogic + | TP-018        |

### Crystal Oscillators

| Freq (MHz) | Use                                                                                 |
|------------|-------------------------------------------------------------------------------------|
| 10.00      | M68000 CLK (10 MHz)                                                                 |
| 28.000     | Z80 CLK (3.5 MHz)<br>YM3812 CLK (3.5 MHz)<br>Pixel CLK (7 MHz)<br> DSP CLK (14 MHz) |

**Pixel clock:** 7.00 MHz

**Estimated geometry:**

_(Demon's World / Horror Story)_

    450 pixels/line  
  
    282 lines/frame  

### Main Components

| Chip                                                                   | Function   |
| -----------------------------------------------------------------------|------------|
| [**Motorola 68000 CPU**](https://en.wikipedia.org/wiki/Motorola_68000) | Main CPU   |
| [**Zilog Z80 CPU**](https://en.wikipedia.org/wiki/Zilog_Z80)           | Sound CPU  |
| [**Yamaha YM3812**](https://en.wikipedia.org/wiki/Yamaha_OPL#OPL2)     | OPL2 Audio |

### Custom Components

| Chip                                             | Function           |
| -------------------------------------------------|--------------------|
| **NEC D65081R077**                               | Custom Gate-Array  |
| **FCU-02**                                       | Sprite RAM         |
| **FDA MN53007T0A / TOAPLAN-02 M70H005 / GXL-02** | Sprite Counter     |
| **BCU-02**                                       | Tile Map Generator | <br>

### Additional Components

| Chip                                                                   | Function         | PCB<br>Number | Status          | Notes                                                                                                                                                                                       |
|------------------------------------------------------------------------|------------------|---------------|-----------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [**TMS32010**](https://en.wikipedia.org/wiki/Texas_Instruments_TMS320) | DSP & Protection | **TP-016**    | Not Implemented | Reviewing the MAME .36b10 Toaplan1 driver it was discovered that the DPS served as protection; currently ROM 10 and post checks are patched in the MRA files until a TMS32010 is available. |

### Screen Flip / Cocktail Support

| Title                            | Screen Flip | Cocktail Support | Implemented |
|----------------------------------|-------------|------------------|-------------|
| **Demon's World / Horror Story** | Dipswitch   | No               | Yes         | <br>

# Core Options / Additional Features

### Scroll Debug Option

- Additional toggle to enable a fourth button for the "Slow Scroll" feature. See the "PCB Information" section for further information.

### Refresh Rate Compatibility Option

- Additional toggle to modify video timings; only use for sync issues with an analog display or scroll jitter on a modern display. This is due to the hardware's low refresh rate, enabling the toggle alters gameplay from it's original state.

| Refresh Rate      | Timing Parameter     | HTOTAL | VTOTAL |
|-------------------|----------------------|--------|--------|
| 15.56kHz / 55.2Hz | TP-016               | 450    | 282    |
| 15.73kHz / 59.8Hz | NTSC                 | 445    | 264    |

### P1/P2 Input Swap Options

- Additional toggle to swap inputs from Player 1 to Player 2. This swaps inputs for the joystick and keyboard assignments.

### Audio Options

- Additional toggle to adjust the volume gain or disable playback of OPL2 audio.

### Overclock Options

- Additional toggle to increase the M68000 frequency from 10MHz to 17.5MHz; this will alter gameplay from it's original state and address any undesired native slow down.

### Native Y/C Output ( 15kHz Displays )

- Native Y/C ouput is possible with the [**analog I/O rev 6.1 pcb**](https://github.com/MiSTer-devel/Main_MiSTer/wiki/IO-Board). Using the following cables, [**HD-15 to BNC cable**](https://www.amazon.com/StarTech-com-Coax-RGBHV-Monitor-Cable/dp/B0033AF5Y0/) will transmit Y/C over the green and red lines. Choose an appropriate adapter to feed [**Y/C (S-Video)**](https://www.amazon.com/MEIRIYFA-Splitter-Extension-Monitors-Transmission/dp/B09N19XZJQ) to your display.

### H/V Adjustments ( 15kHz Displays )

- Additional toggle for horizontal and vertical centering; the "H/V-Sync Pos Adj" toggles move the image to assist in screen centering if you choose not to adjust your displays settings.

- Additional toggle for horizontal and vertical sync width adjust; the "H/V-Sync Width Adj" toggles address "rolling sync" and "flagging" on certain displays.

### Scandoubler Options ( 31kHz Displays )

- Additional toggle to enable the scandoubler (31kHz) without changing ini settings and a new scanline option for 100% is available; the new scanline setting draws a black line every other frame. Scandoubler options pass over HDMI as well.

<table><tr><th>Scandoubler Fx</th><th>Scanlines 25%</th><th>Scanlines 50%</th><th>Scanlines 75%</th><th>Scanlines 100%</th><tr><td><br> <p align="center"><img width="160" height="120" src="https://github.com/va7deo/demonswld/assets/32810066/70fbfd59-c6e9-492f-9705-5452dc724335"></td><td><br> <p align="center"><img width="160" height="120" src="https://github.com/va7deo/demonswld/assets/32810066/d0f7269b-bb21-4a88-ad03-49940d9e09b7"></td><td><br> <p align="center"><img width="160" height="120" src="https://github.com/va7deo/demonswld/assets/32810066/1fefd4eb-c13a-4592-9471-99a4a5edd6ef"></td><td><br> <p align="center"><img width="160" height="120" src="https://github.com/va7deo/demonswld/assets/32810066/114a1a85-ee16-4a9d-84c7-66a0bc380fa1"></td><td><br> <p align="center"><img width="160" height="120" src="https://github.com/va7deo/demonswld/assets/32810066/c50a43ad-1545-413e-b9d0-36b165f59e77"></td></tr></table> <br>

# PCB Information / Control Layout

| Title                            | Joystick | Service Menu                                                                                                 | Dip Switches                                                                                              | Shared Controls | Dip Default | PCB Information                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
|----------------------------------|----------|--------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------|-----------------|-------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Demon's World / Horror Story** | 8-Way    | [**Service Menu**](https://github.com/va7deo/demonswld/assets/32810066/f7de88ca-ea44-443a-ba6e-251cf99c3735) | [**Dip Sheet**](https://github.com/va7deo/demonswld/assets/32810066/d2a8547d-6663-4b10-ae7f-eb5e307bf127) | Co-Op           | N/A         | There are **significant** differences between the five sets and **minimal** differences between regional variants; Set 3 is the polished version and chosen to be the primary. Other than difficulty, enemies available in all sets are present and the stage order is different. <br><br> Set 1 and 2 feature the same stage order and different enemy sprites. Set 3, Set 4, and Set 5 feature the same stage order and different enemy patterns / sprites. <br><br> For in-game pause, press P2 Start, press P1 Start to resume. There is a slow motion debug setting; press P1 and P2 Start simultaneously. <br><br> These are mappable inputs. For ease of use, these features are enabled when toggling "Scroll Debug" in the core settings; there is no need to toggle the dipswitch. <br><br> The third button is "Rapid Shot"; this is not documented in the manual or service menu, button 3 is marked as unused. The "Slow Scroll" button (P1/P2 Button 4) is not on hardware; P1 and P2 Start are merged to button 4. |

### Keyboard Handler

<br>

- Keyboard inputs mapped to mame defaults for Player 1 / Player 2.

<br>

| Services                                                                                                                                                                                           | Coin/Start                                                                                                                                                                                              |
|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| <table> <tr><th>Functions</th><th>Keymap</th></tr><tr><td>Test</td><td>F2</td></tr><tr><td>Reset</td><td>F3</td></tr><tr><td>Service</td><td>9</td></tr><tr><td>Pause</td><td>P</td></tr> </table> | <table><tr><th>Functions</th><th>Keymap</th><tr><tr><td>P1 Start</td><td>1</td></tr><tr><td>P2 Start</td><td>2</td></tr><tr><td>P1 Coin</td><td>5</td></tr><tr><td>P2 Coin</td><td>6</td></tr> </table> |

| Player 1                                                                                                                                                                                                                                                                                                                                      | Player 2                                                                                                                                                                                                                                                                                                              |
|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| <table> <tr><th>Functions</th><th>Keymap</th></tr><tr><td>P1 Up</td><td>Up</td></tr><tr><td>P1 Down</td><td>Down</td></tr><tr><td>P1 Left</td><td>Left</td></tr><tr><td>P1 Right</td><td>Right</td></tr><tr><td>P1 Bttn 1</td><td>L-CTRL</td></tr><tr><td>P1 Bttn 2</td><td>L-ALT</td></tr><tr><td>P1 Bttn 3</td><td>Space</td></tr> </table> | <table> <tr><th>Functions</th><th>Keymap</th></tr><tr><td>P2 Up</td><td>R</td></tr><tr><td>P2 Down</td><td>F</td></tr><tr><td>P2 Left</td><td>D</td></tr><tr><td>P2 Right</td><td>G</td></tr><tr><td>P2 Bttn 1</td><td>A</td></tr><tr><td>P2 Bttn 2</td><td>S</td></tr><tr><td>P2 Bttn 3</td><td>Q</td></tr> </table> |

# Support

Please consider showing support for this and future projects via [**Darren's Ko-fi**](https://ko-fi.com/darreno) and [**atrac17's Patreon**](https://www.patreon.com/atrac17). While it isn't necessary, it's greatly appreciated.<br>

# Licensing

Contact the author for special licensing needs. Otherwise follow the GPLv2 license attached.
