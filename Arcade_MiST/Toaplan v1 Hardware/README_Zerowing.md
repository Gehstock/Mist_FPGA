
# Toaplan (Zero Wing) FPGA Implementation

FPGA compatible core of Toaplan Version 1 arcade hardware for [**MiSTerFPGA**](https://github.com/MiSTer-devel/Main_MiSTer/wiki) written by [**Darren Olafson**](https://twitter.com/Darren__O). Based on OutZone (TP-018) schematics and verified against OutZone (TP-015 Conversion / TP-018) and Tatsujin (TP-013B).

The intent is for this core to be a 1:1 **game play** FPGA implementation of Toaplan V1 hardware for the supported titles. This project was developed with assistance from [**atrac17**](https://github.com/atrac17) and [**𝕓𝕝𝕒𝕔𝕜𝕨𝕚𝕟𝕖**](https://github.com/blackwine).

Rally Bike (TP-012), Demon's World (TP-016), Fireshark (TP-017), and Vimana (TP-019) are also Toaplan V1 titles and have separate repositories located [**here**](https://github.com/va7deo?tab=repositories).

![zwcore_github](https://github.com/va7deo/zerowing/assets/32810066/db31670a-dc4e-4ff6-a803-2738e2ef9a86)

## Supported Titles

| Title                                                                            | PCB<br>Number | Status      | Released |
|----------------------------------------------------------------------------------|---------------|-------------|----------|
| [**Tatsujin / Truxton**](https://en.wikipedia.org/wiki/Truxton_%28video_game%29) | TP-013B       | Implemented | Yes      |
| [**Hellfire**](https://en.wikipedia.org/wiki/Hellfire_%28video_game%29)          | B90 (TP-014)  | Implemented | Yes      |
| [**Zero Wing**](https://en.wikipedia.org/wiki/Zero_Wing)                         | TP-015        | Implemented | Yes      |
| [**OutZone**](https://en.wikipedia.org/wiki/Out_Zone)                            | TP-018        | Implemented | Yes      |

## External Modules

| Module                                                                                | Function                                                               | Author                                         |
|---------------------------------------------------------------------------------------|------------------------------------------------------------------------|------------------------------------------------|
| [**fx68k**](https://github.com/ijor/fx68k)                                            | [**Motorola 68000 CPU**](https://en.wikipedia.org/wiki/Motorola_68000) | Jorge Cwik                                     |
| [**t80**](https://opencores.org/projects/t80)                                         | [**Zilog Z80 CPU**](https://en.wikipedia.org/wiki/Zilog_Z80)           | Daniel Wallner                                 |
| [**jtopl2**](https://github.com/jotego/jtopl)                                         | [**Yamaha OPL2**](https://en.wikipedia.org/wiki/Yamaha_OPL#OPL2)       | Jose Tejada                                    |
| [**yc_out**](https://github.com/MikeS11/MiSTerFPGA_YC_Encoder)                        | [**Y/C Video Module**](https://en.wikipedia.org/wiki/S-Video)          | Mike Simone                                    |
| [**mem**](https://github.com/MiSTer-devel/Arcade-Rygar_MiSTer/tree/master/src/mem)    | SDRAM Controller / Rom Downloader                                      | Josh Bassett; modified by Darren Olafson       |
| [**core_template**](https://github.com/MiSTer-devel/Template_MiSTer)                  | MiSTer Framework Template                                              | sorgelig; modified by Darren Olafson / atrac17 |

# Known Issues / Tasks

- [**OPL2 Audio**](https://github.com/jotego/jtopl/issues/11)  **[Issue]**  
- Address timing issues with jtframe_mixer module usage; false paths added to sdc  **[Task]**  

# PCB Check List

### Clock Information

| H-Sync       | V-Sync      | Source    | PCB<br>Number               |
|--------------|-------------|-----------|-----------------------------|
| 15.556938kHz | 55.161153Hz | DSLogic + | TP-018                      |
| 15.556938kHz | 57.612182Hz | DSLogic + | TP-013B<br>TP-014<br>TP-015 |

### Crystal Oscillators

| Freq (MHz) | Use                                                            |
|------------|----------------------------------------------------------------|
| 10.00      | M68000 CLK (10 MHz)                                            |
| 28.000     | Z80 CLK (3.5 MHz)<br>YM3812 CLK (3.5 MHz)<br>Pixel CLK (7 MHz) |

**Pixel clock:** 7.00 MHz

**Estimated geometry:**

_**(OutZone)**_

    450 pixels/line  
  
    282 lines/frame  

_**(Tatsujin, Hellfire, Zero Wing)**_

    450 pixels/line  
  
    270 lines/frame  

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
| **BCU-02**                                       | Tile Map Generator |

### Screen Flip / Cocktail Support

| Title         | Screen Flip | Cocktail Support                                | Implemented |
|---------------|-------------|-------------------------------------------------|-------------|
| **Tatsujin**  | Dipswitch   | Yes                                             | Yes         |
| **Hellfire**  | Dipswitch   | Hellfire (1P Set) <br> Hellfire (1P Set, Older) | Yes         |
| **Zero Wing** | Dipswitch   | Zero Wing (1P Set)                              | Yes         |
| **OutZone**   | Dipswitch   | No                                              | Yes         | <br>

# Core Options / Additional Features

### Scroll Debug Options

- Additional toggle that enables slow scrolling or separate debug feature in Tatsujin, Hellfire, Zero Wing, and OutZone. These features are present on hardware; for further details view the "PCB Information" section.

### Refresh Rate Compatibility Options

- Additional toggle to modify video timings; only use for sync issues with an analog display or scroll jitter on a modern display. This is due to the hardware's low refresh rate, enabling the toggle alters gameplay from it's original state.

| Refresh Rate      | Timing Parameter     | HTOTAL | VTOTAL |
|-------------------|----------------------|--------|--------|
| 15.56kHz / 55.2Hz | TP-018               | 450    | 282    |
| 15.56kHz / 57.6Hz | TP-013B, B90, TP-015 | 450    | 270    |
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

<table><tr><th>Scandoubler Fx</th><th>Scanlines 25%</th><th>Scanlines 50%</th><th>Scanlines 75%</th><th>Scanlines 100%</th><tr><td><br> <p align="center"><img width="160" height="120" src="https://github.com/va7deo/zerowing/assets/32810066/05d03e41-7550-4103-b19e-e67b8d56f2ea"></td><td><br> <p align="center"><img width="160" height="120" src="https://github.com/va7deo/zerowing/assets/32810066/9d435d61-82b6-49d4-a1b7-642fc3ca0b66"></td><td><br> <p align="center"><img width="160" height="120" src="https://github.com/va7deo/zerowing/assets/32810066/6dd54cdd-34d4-4d1e-b9e9-4d8b95954bdd"></td><td><br> <p align="center"><img width="160" height="120" src="https://github.com/va7deo/zerowing/assets/32810066/0b7f8f89-f35d-40ac-afde-16abc633bf01"></td><td><br> <p align="center"><img width="160" height="120" src="https://github.com/va7deo/zerowing/assets/32810066/d0d46729-f19a-4883-a89b-9a302d405b6c"></td></tr></table> <br>

# PCB Information / Control Layout

| Title         | Joystick | Service Menu                                                                                                | Dip Switches                                                                                             | Shared Controls | Dip Default | PCB Information                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
|---------------|----------|-------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------|-----------------|-------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Tatsujin**  | 8-Way    | [**Service Menu**](https://github.com/va7deo/zerowing/assets/32810066/3cf757be-6514-4700-a2de-9e42723c703e) | [**Dip Sheet**](https://github.com/va7deo/zerowing/assets/32810066/f4745145-a31f-4152-98e1-a6fa315051a4) | Yes             | **Upright** | There are **no known** differences between regional the variants; toggling the "Game Title" to "Table" enables turn based two player gameplay versus co-operative gameplay. For further information visit the [Tatsujin](https://shmups.wiki/library/Tatsujin) shmups wikipedia. <br><br> To access the service menu, toggle the "Test Mode" dipswitch; press P1 Start when the grid is displayed. To access sound test, press P2 Start when the grid is displayed. <br><br> Toggle the "Test Mode" dipswitch to on **in-game** for "No Death". For **in-game** pause, toggle the "Dip Switch Display" dipswitch on. <br><br> When the "Game Title" dipswitch is set to "Upright", controls for both players are accessible.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| **Hellfire**  | 8-Way    | [**Service Menu**](https://github.com/va7deo/zerowing/assets/32810066/e262e14f-6224-487d-9fd8-c6cffdca7ffe) | [**Dip Sheet**](https://github.com/va7deo/zerowing/assets/32810066/58c7dd68-05cc-419a-a62e-258a95754679) | No              | **Upright** | There are differences between regional variants; the 1P Set features **higher difficulty** and **turn-based two player** gameplay versus co-operative gameplay. <br><br> **In-game**, toggle the "No Hit" dipswitch for invulnerability. For **in-game pause**, press P2 Start, press P1 Start to resume. There is a slow motion debug setting; press P1 and P2 Start simultaneously. <br><br> These are mappable inputs. For ease of use, these features are enabled when toggling "Scroll Debug" in the core settings; there is no need to toggle the dipswitch. <br><br> The "Slow Scroll" button (P1/P2 Button 3) is not on hardware; P1 and P2 Start are merged to button 3.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| **Zero Wing** | 8-Way    | [**Service Menu**](https://github.com/va7deo/zerowing/assets/32810066/f3e6d951-cd02-40fd-a6a9-17db64bf0e94) | [**Dip Sheet**](https://github.com/va7deo/zerowing/assets/32810066/6e9e51fa-c695-480f-9f60-9bc828492f26) | No              | **Upright** | There are differences between regional variants; the 1P Set features **higher difficulty** and **turn-based two player** gameplay versus co-operative gameplay. For further information visit the [Zero Wing](https://shmups.wiki/library/Zero_Wing) shmups wikipedia. <br><br> **In-game**, toggle the "No Hit" dipswitch for invulnerability. For **in-game pause**, press P2 Start, press P1 Start to resume. There is a slow motion debug setting; press P1 and P2 Start simultaneously. <br><br> These are mappable inputs. For ease of use, these features are enabled when toggling "Scroll Debug" in the core settings; there is no need to toggle the dipswitch. <br><br> The "Slow Scroll" button (P1/P2 Button 3) is not on hardware; P1 and P2 Start are merged to button 3.                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| **OutZone**   | 8-Way    | [**Service Menu**](https://github.com/va7deo/zerowing/assets/32810066/8383054b-e7d4-470a-aaef-d6bd6f9dd71c) | [**Dip Sheet**](https://github.com/va7deo/zerowing/assets/32810066/4eec59fe-fc59-42ef-9d47-f55f5428c374) | No              | **Upright** | There are **minimal** differences between regional variants; other than difficulty, there is additional text in the Japanese variants. For further information visit the [OutZone](https://shmups.wiki/library/OutZone) shmups wikipedia. <br><br> For in-game pause, press P2 Start, press P1 Start to resume. There is a slow motion debug setting; press P1 and P2 Start simultaneously. <br><br> These are mappable inputs. For ease of use, these features are enabled when toggling "Scroll Debug" in the core settings; there is no need to toggle the dipswitch. <br><br> The "Slow Scroll" button (P1/P2 Button 4) is not on hardware; P1 and P2 Start are merged to button 4. <br><br> The OutZone (Older Set) [outzoneb] has a unique feature; set both "Debug" dipswitches to on and reset in the OSD. Hold P2 Down during the boot sequence. Easiest to replicate with a keyboard. <br><br> The CRTC registers are programmed for a smaller VTOTAL, enabling a higher framerate by reducing the edges of the screen. <br><br> This changes the native refresh rate of OutZone from 55.2Hz to 58.5Hz and the resolution from 240p to 224p. Apart from the PCB, this is the only known **emulation** where this is possible. |

<br>

- Upright cabinets use a **2L3B** control panel layout. Cocktail cabinets use a **2L3B** control panel layout on opposite sides of the cabinet. <br><br>
- If the cabinet type is set to table, the screen inverts for cocktail mode with turned based two player gameplay. <br><br>
- Push button 3 may have no function in-game, but corresponds to the hardware service menu in OutZone. The "Scroll Debug" adds a button combination and is not tied to the keyboard handler. <br><br>

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

# Acknowledgments

Special thanks to the following loaned hardware used during development of this project: <br>

[**@owlnonymous**](https://twitter.com/owlnonymous) for loaning OutZone (TP-015 Conversion) <br>
[**@cathoderaze**](https://twitter.com/cathoderaze) for loaning Tatsujin (TP-013B) <br>
[**@90s_cyber_thriller**](https://www.instagram.com/90s_cyber_thriller/) for loaning Outzone (TP-018) <br>

# Support

Please consider showing support for this and future projects via [**Darren's Ko-fi**](https://ko-fi.com/darreno) and [**atrac17's Patreon**](https://www.patreon.com/atrac17). While it isn't necessary, it's greatly appreciated. <br>

# Licensing

Contact the author for special licensing needs. Otherwise follow the GPLv2 license attached.
