KC87 on MiST FPGA

Nothing is tested need Feedback






# kc87fpga

This is a recreation of a KC87 using VHDL. It is designed to run on a Terasic DE1 FPGA Board. The computer 
itself is a member of a line of home computers from former East Germany that was fairly popular. 
They were all based on the Z80 and its periperials.

See http://en.wikipedia.org/wiki/Robotron_KC_87

Most of the programs for this computer and all of its documentation is in german. That's why i'm afraid it will
not be very interesting for non germans.

For this reason i will continue in german.

---

## Beschreibung
### CPU
- T80 mit Erweiterung um RETI hinauszuführen
- Takt 50MHz oder 2.4576MHz (umschaltbar)

### RAM
- 32 kB + 32 kB für die Roms

### ROM
- 8kB/16kB Bootrom mit gepacktem Bootloader 

### CTC+PIO
- interruptfähige PIO und CTC
- einfacher Interruptcontroller mit Priorsierung (verbesserte Variante ToDo)

### Video
- 40x24 Textmodus (40x20 Modus fehlt)
- Ausgabe 640x768@60Hz (Timing entspricht 1024x768@60Hz)
- Scanlines zuschaltbar

### Keyboard
- Keyboard-Matrix wird simuliert
- Steuerung über PS/2
- Tasten werden so gemappt 

### SD Karte
- OS und Basic werden vom Bootrom eingelesen und gestartet
- von der Karte können tap-Files geladen werden

## Bedienung
Nach dem Start wird der Bootloader zunächst nach $8000 entpackt und gestartet. Anschließend sucht er auf der SD Karte 
nach dem OS und dem Basic Rom. Findet er sie dann werden sie geladen und das OS wird gestartet. Der Bootloader sucht 
nach os____f0.87b und basic_c0.87b im Verzeichnis ROMS.

Das Rom ist auch während des normalen Betriebs verfügbar. Nach Eingabe von

```
SD 
```

am OS-Prompt wird ein kleines Menu gestartet. Dort stehen ein paar Bedienhinweise.

## Schalter und Anzeigen

KEY0: Reset
KEY1-3: Anzeige Interruptvektoren
SW0: Turbo dauerhaft an
SW1: Scanlines umschalten
F1: Pause/Cont
F2: List
F3: Run
F4: Stop
F5: Color
F6: Graphic
7-Segmentanzeige: Ziel des letzten Interrupts

## Synthese/Kompilierung der Roms
Neuere Versionen von Quartuns unterstützen leider keinen Cyclone II mehr. Die letzte Version mit der dieses
Design übersetzt werden kann ist deshalb die 13.0sp1. Zur Erzeugung der Files einfach das Projekt laden und
schon kanns losgehen. 

Das Bootrom ist schon fertig übersetzt. Ein erneutes Übersetzen sollte daher nicht notwendig sein. Hier eine
Beschreibung falls das doch einmal jemand ausprobieren möchte... 

Die Software für die Roms wurde hauptsächlich mit SDCC geschrieben. Zusätzlich zu diesem Compiler wird noch folgendes
benötigt:
- make
- objcopy aus den Binutils (ihex -> bin)
- ZX7 (Packer)
- Z80asm (Z80 Assebler)
- TCL (Umwandlung bin -> VHDL)

Ein

```
make sdrom
```

im Ordner sw erzeugt dann das Rom.

Für Entwicklungszwecke bzw. für Boards ohne SD Kartenslot gibt es einen Monitor der einen Upload über die serielle
Schnittstelle beherrscht. 

Sinnvoll benutzbare Varianten:
- bootloader.vhdl (Bootloader mit OS, Basic und Monitor-Rom)
- bootloader_mon_0000.vhd (Monitor auf $0000 zur Testen von Roms auf $8000)
- bootloader_sdcard.vhd (Bootloader für SD Karte)

## ToDos
- fehlenden Videomodus (40x20) ergänzen
- der Speicherzugriff hat keine Waitstates - deswegen vermutlich etwas zu schnell
- verbesserter Interruptcontroller der laufende Interrupts unterbrechen kann
- Grafikerweiterung?
- Sound (Krach?) ausgeben
- Anpassung für Spartan 3 Startkit testen 
