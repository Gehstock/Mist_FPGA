# Bosconian

FPGA implementation of the arcade game Bosconian - Star Destroyer, developed in
1981 by Namco and released to Western audiences by Midway.


## Credits

* Nolan Nicholson: FPGA implementation of overall Bosconian system from the
  Midway service schematics - particularly the video board.
* Dar: FPGA implementation of Galaga, from which much of this core was
  adapted - particularly the logic board.
* Wolfgang Scherr: Implementations of several LUTs and Namco customs, including
  the 05xx starfield generator, plus a hint to the operation of the 52xx voice
  chip.
* Mike Johnson: Implementations of several Namco customs, including the 07xx sync
  generator, plus a lot of legwork originally done for the FPGAArcade project.
* Daniel Wallner: T80/T80se, a Z80 compatible CPU.
* MAME: Information on memory mapping, Namco customs, and general information.
* Alexey Melnikov: MiSTer framework.


## Game Information

Bosconian is a top-down 8-directional shooter. The goal of the game is to
destroy all enemy bases in each level while fighting off enemy ships.

Bosconian is the first top-down shooter that allowed diagonal movement, and one
of the earliest arcade games with recorded voice sounds. For comparison, Pole
Position came out later in 1982, and Sinister came out in 1983.

Please note the following about Bosconian's DIP settings:
* The DIP settings differ between the Namco and Midway versions.
* The bonus DIP levels have different meanings based on the lives DIP levels. In
  particular, the bonus DIPs will mean something different for starting with 5
  lives, compared to starting with only 1, 2, or 3.


## Required files

ROMs are not included. In order to use this arcade, you need to provide the
correct ROMs.

To simplify the process .mra files are provided in the releases folder, that
specifies the required ROMs with checksums. The ROMs .zip filename refers to the
corresponding file of the M.A.M.E. project.

Please refer to
[Arcade ROMS](https://github.com/MiSTer-devel/Main_MiSTer/wiki/Arcade-Roms)
for information on how to setup and use the environment.

Quick reference for folders and file placement:

 * `/_Arcade/<game name>.mra`
 * `/_Arcade/cores/<game rbf>.rbf`
 * `/games/mame/<mame rom>.zip`
 * `/games/hbmame/<hbmame rom>.zip`


## Known Issues

* Pausing at particular moments may cause a crash.
* Shot and explosion sounds are not working perfectly:
    * Base explosion sound is not nearly loud enough.
    * Shot sound changes pitch from shot to shot.
* Continues (insert new coin after dying) may not be working properly.
