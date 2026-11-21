# FPGA SuperChip #

This is a Verilog implementation of the SuperChip virtual machine. The implementation can execute Chip-8 and SuperChip programs. Hybrids, the Chip-8X and MegaChip extensions are not supported.

This core has been ported from MiST to MiSTer by Paul Sajna.
Original core is by Carsten Elton Sørensen.

For an introduction to Chip-8 and SuperChip, please see [the Chip-8 article on Wikipedia](https://en.wikipedia.org/wiki/CHIP-8). 

SuperChip has traditionally been implemented as a virtual machine, but this is a pure Verilog implementation of the CPU, display and blitter. The CPU runs at a user selectable speed of a whopping 5 kHz or 12.5 kHz. An instruction usually takes 5 cycles, some a bit longer. The blitter runs at a much faster clock rate than the CPU, 50 MHz on the MiSTer, so sprite and scroll instructions only add a couple of CPU cycles.

# Instructions #

Press F12 to bring up the OSD. From here you can select a .CH8-file to load.

Video output timings match COSMAC VIP (original CHIP-8 target). 15.7kHz support (60Hz SD CRT).

The menu also allows the CPU speed to be selected. Some games are better played on slow, some on fast.

Palettes are supported via [.gbp](https://www.nortakales.com/page/gbpEditor). For examples see the [Palettes](https://github.com/MiSTer-devel/Gameboy_MiSTer/tree/master/Palette) folder in the Gameboy_MiSTer repository.

The Chip-8 machine has a hex keypad for input. This has been mapped to the PC keyboard as follows:

    Chip-8:   PS/2:
    1 2 3 C   1 2 3 4
    4 5 6 D   Q W E R
    7 8 9 E   A S D F
    A 0 B F   Z X C V

There are also several joystick automapping profiles that correspond with many games. Try a few for a given game and you'll often find one that works pretty well.

                    U D L R   A B Y X   L R Se St   UL UR DL DR
    0 8-way         2 8 4 6   5 0 A B   C D E  F    1  3  7  9
    1 SNES          2 8 4 6   A 5 0 B   C D E  F    1  3  7  9
    2 CHIP-8        5 8 7 9   6 4 2 0   C D E  F    1  3  A  B
    3 SCHIP 3-C     E F 3 C   A 0 5 B   4 6 2  1    7  9  8  D
    4 SCHIP 7-8     3 6 7 8   1 4 A 0   C D E  F    -  -  -  -
    5 Paddle        1 4      (U=C & D=D for pad 2)

# Download #
Downloads can be found in the [releases folder](https://github.com/MiSTer-devel/Chip8_MiSTer/tree/master/releases)