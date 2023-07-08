
# Toaplan (Vimana) FPGA Implementation

FPGA compatible core of Toaplan Version 1 arcade hardware for [**MiSTerFPGA**](https://github.com/MiSTer-devel/Main_MiSTer/wiki) written by [**Darren Olafson**](https://twitter.com/Darren__O). Based on OutZone (TP-018) schematics and verified against Vimana (TP-019).

The intent is for this core to be a 1:1 **game play** FPGA implementation of Toaplan V1 hardware for the supported titles. Currently in beta state, this project is in active development with assistance from [**atrac17**](https://github.com/atrac17).

Rally Bike (TP-012), Tatsujin (TP-013B), Hellfire (TP-014), Zero Wing (TP-015), Demon's World (TP-016), and OutZone (TP-018) are also Toaplan V1 titles and have separate repositories located [**here**](https://github.com/va7deo?tab=repositories).

![vimana](https://github.com/va7deo/vimana/assets/32810066/0a9385b5-8224-4321-a63a-8cd3c8dec72a)

## Supported Titles

| Title                                                                               | PCB<br>Number | Status      | Released |
|-------------------------------------------------------------------------------------|---------------|-------------|----------|
| [**Same! Same! Same! / Fire Shark**](https://en.wikipedia.org/wiki/Fire_Shark)      | TP-017        | Implemented | Yes      |
| [**Vimana**](https://en.wikipedia.org/wiki/Vimana_%28video_game%29)                 | TP-019        | Implemented | Yes      |

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
- Verify irq timings on TP-017 against video timings from PCB capture  **[Issue]**  
- Address timing issues with jtframe_mixer module usage; false paths added to sdc  **[Task]**  
- Attempt usage of y80e core for HD647180X CPU if functional with Ghox  **[Task]**  

# PCB Check List

### Clock Information

| H-Sync       | V-Sync      | Source    | PCB<br>Number |
|--------------|-------------|-----------|---------------|
| 15.556938kHz | 57.612182Hz | DSLogic + | TP-019        |

### Crystal Oscillators

| Freq (MHz) | Use                                                            |
|------------|----------------------------------------------------------------|
| 10.00      | M68000 CLK (10 MHz)                                            |
| 28.000     | Z80 CLK (3.5 MHz)<br>YM3812 CLK (3.5 MHz)<br>Pixel CLK (7 MHz) |

**Pixel clock:** 7.00 MHz

**Estimated geometry:**

_(Same! Same! Same!, Vimana)_

    450 pixels/line  
  
    270 lines/frame  

### Main Components

| Chip                                                                   | Function         |
| -----------------------------------------------------------------------|------------------|
| [**Motorola 68000 CPU**](https://en.wikipedia.org/wiki/Motorola_68000) | Main CPU         |
| [**Zilog Z80 CPU**](https://en.wikipedia.org/wiki/Zilog_Z80)           | Sound CPU        |
| [**Yamaha YM3812**](https://en.wikipedia.org/wiki/Yamaha_OPL#OPL2)     | OPL2 Audio       |

### Custom Components

| Chip                                             | Function           |
| -------------------------------------------------|--------------------|
| **NEC D65081R077**                               | Custom Gate-Array  |
| **FCU-02**                                       | Sprite RAM         |
| **FDA MN53007T0A / TOAPLAN-02 M70H005 / GXL-02** | Sprite Counter     |
| **BCU-02**                                       | Tile Map Generator |

### Additional Components

| Chip                                                      | Function                 | PCB<br>Number        | Status          | Alternate Chip                                               | Note                                                                                                                                                                                                                                                       |
|-----------------------------------------------------------|--------------------------|----------------------|-----------------|--------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [**HD647180X**](https://en.wikipedia.org/wiki/Zilog_Z180) | Sound CPU & I/O Handling | **TP-017<br>TP-019** | Not Implemented | [**Zilog Z80 CPU**](https://en.wikipedia.org/wiki/Zilog_Z80) | It was discovered that the audio ROM is Z80 compatible code and the HD647180X is backwards compatible with the Z80 but has an additional 512 bytes of internal RAM. <br><br> None of the specific instructions or I/O ports of the HD647180X are utilized. |

### Screen Flip / Cocktail Support

| Title                 | Screen Flip | Cocktail Support                                                     | Implemented |
|-----------------------|-------------|----------------------------------------------------------------------|-------------|
| **Same! Same! Same!** | Dipswitch   | Same! Same! Same! (1P Set) <br> Same! Same! Same! (1P Set, New Ver.) | Yes         |
| **Vimana**            | Dipswitch   | No                                                                   | Yes         | <br>

# Core Options / Additional Features

### Scroll Debug Option

- Additional toggle to enable the third button for "Fast Scroll" in Vimana and a fourth button for the "Slow Scroll" feature in Vimana and Same! Same! Same! See the "PCB Information" section for further information.

### Refresh Rate Compatibility Option

- Additional toggle to modify video timings; only use for sync issues with an analog display or scroll jitter on a modern display. This is due to the hardware's low refresh rate, enabling the toggle alters gameplay from it's original state.

| Refresh Rate      | Timing Parameter     | HTOTAL | VTOTAL |
|-------------------|----------------------|--------|--------|
| 15.56kHz / 57.6Hz | TP-017 / TP-019      | 450    | 270    |
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

<table><tr><th>Scandoubler Fx</th><th>Scanlines 25%</th><th>Scanlines 50%</th><th>Scanlines 75%</th><th>Scanlines 100%</th><tr><td><br> <p align="center"><img width="120" height="160" src="https://github.com/va7deo/vimana/assets/32810066/d8f85a3f-fd9d-4f1b-8f33-17e4990744bb"></td><td><br> <p align="center"><img width="120" height="160" src="https://github.com/va7deo/vimana/assets/32810066/8a769580-3718-4903-9fb5-33ec4a940f1d"></td><td><br> <p align="center"><img width="120" height="160" src="https://github.com/va7deo/vimana/assets/32810066/cf27bdfc-3f3b-4992-861f-34cdd4a863f1"></td><td><br> <p align="center"><img width="120" height="160" src="https://github.com/va7deo/vimana/assets/32810066/ce28890e-ad2b-4986-9425-f1cab656fc4d"></td><td><br> <p align="center"><img width="120" height="160" src="https://github.com/va7deo/vimana/assets/32810066/a72e966a-2185-4230-aa01-65425785d235"></td></tr></table> <br>

# PCB Information / Control Layout

| Title                 | Joystick | Service Menu                                                                                              | Dip Switches                                                                                           | Shared Controls | Dip Default | PCB Information                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
|-----------------------|----------|-----------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------|-----------------|-------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Same! Same! Same!** | 8-Way    | [**Service Menu**](https://github.com/va7deo/vimana/assets/32810066/13506b80-dfdc-4602-b2c6-113d8b760e80) | [**Dip Sheet**](https://github.com/va7deo/vimana/assets/32810066/4d3947e4-ff14-44a3-9fa5-d6f7e674dc1d) | Co-Op / Single  | Upright     | The default version of Same! Same! Same! / Fire Shark is "samesame2". Featuring two players and retaining most of the balance of "samesame". There are several difference between the regional variants; for further information visit the [**Same! Same! Same!**](https://shmups.wiki/library/Same!_Same!_Same!) shmups wikipedia. <br><br> Enabling the "No Death/Stop" dipswitch enables in-game pause by pressing P2 Start; pressing P2 Start returns to game. There is a slow motion debug setting; press P1 and P2 Start simultaneously. <br><br> These are mappable inputs. For ease of use, these features are enabled when toggling "Scroll Debug" in the core settings; there is no need to toggle the dipswitch. <br><br> The "Slow Scroll" button (P1/P2 Button 3) is not on hardware; P1 and P2 Start are merged to button 3. |
| **Vimana**            | 8-Way    | [**Service Menu**](https://github.com/va7deo/vimana/assets/32810066/ad02a834-6937-424b-8dd9-bdf5d3df573e) | [**Dip Sheet**](https://github.com/va7deo/vimana/assets/32810066/8bc96aea-27bb-449c-9720-1214e4e09346) | Co-Op           | N/A         | Enabling the "No Death/Stop" dipswitch enables in-game pause by pressing P2 Start; pressing P2 Start returns to game. There is a fast and slow motion debug setting; "fast scroll" is on button 3 of the JAMMA edge. For "slow scroll", press P1 and P2 Start simultaneously. <br><br> For ease of use, these features are enabled when toggling "Scroll Debug" in the core settings; there is no need to toggle the dipswitch. The "Slow Scroll" button (P1/P2 Button 4) is not on hardware; P1 and P2 Start are merged to button 4. <br><br> There is a "kill player" button combination not documented; press and hold "Fast Scroll" and "Bomb", then press "Shot/Charging Shot" when the "No Death/Stop" dipswitch or "Scroll Debug" is toggled in "DIP Switches" or "Core Settings".                                                  |

<br>

- Push button 3 may have no function in-game, but corresponds to the hardware service menu in Vimana and is a debug button for "fast scroll". The "Scroll Debug" adds a button combination and is not tied to the keyboard handler. <br><br>

### Keyboard Handler

<br>

- Keyboard inputs mapped to mame defaults for Player 1 / Player 2.

<br>

| Services                                                                                                                                                                                           | Coin/Start                                                                                                                                                                                              |
|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| <table> <tr><th>Functions</th><th>Keymap</th></tr><tr><td>Test</td><td>F2</td></tr><tr><td>Reset</td><td>F3</td></tr><tr><td>Service</td><td>9</td></tr><tr><td>Pause</td><td>P</td></tr> </table> | <table><tr><th>Functions</th><th>Keymap</th><tr><tr><td>P1 Start</td><td>1</td></tr><tr><td>P2 Start</td><td>2</td></tr><tr><td>P1 Coin</td><td>5</td></tr><tr><td>P2 Coin</td><td>6</td></tr> </table> |

| Player 1                                                                                                                                                                                                                                                                                                                                      | Player 2                                                                                                                                                                                                                                                                                                                                                   |
|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| <table> <tr><th>Functions</th><th>Keymap</th></tr><tr><td>P1 Up</td><td>Up</td></tr><tr><td>P1 Down</td><td>Down</td></tr><tr><td>P1 Left</td><td>Left</td></tr><tr><td>P1 Right</td><td>Right</td></tr><tr><td>P1 Bttn 1</td><td>L-CTRL</td></tr><tr><td>P1 Bttn 2</td><td>L-ALT</td></tr><tr><td>P1 Bttn 3</td><td>Space</td></tr> </table> | <table> <tr><th>Functions</th><th>Keymap</th></tr><tr><td>P2 Up</td><td>R</td></tr><tr><td>P2 Down</td><td>F</td></tr><tr><td>P2 Left</td><td>D</td></tr><tr><td>P2 Right</td><td>G</td></tr><tr><td>P2 Bttn 1</td><td>A</td></tr><tr><td>P2 Bttn 2</td><td>S</td></tr><tr><td>P2 Bttn 3</td><td>Q</td></tr> </table>                                      |

# Acknowledgments

Special thanks to the following loaned hardware used during development of this project: <br>

[**@90s_cyber_thriller**](https://www.instagram.com/90s_cyber_thriller/) for loaning two different variations of Vimana (TP-019)<br>

# Support

Please consider showing support for this and future projects via [**Darren's Ko-fi**](https://ko-fi.com/darreno) and [**atrac17's Patreon**](https://www.patreon.com/atrac17). While it isn't necessary, it's greatly appreciated.<br>

# Licensing

Contact the author for special licensing needs. Otherwise follow the GPLv2 license attached.
