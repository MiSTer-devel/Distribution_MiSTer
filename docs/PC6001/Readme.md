# NEC PC-6001 for MiSTer

A core for NEC's PC-6001 family of Japanese home computers:

| Model | Year | State |
|---|---|---|
| PC-6001 | 1981 | complete except the printer and RS-232C ports |
| PC-6001mkII | 1983 | beta |
| PC-6601 (mkII with a built-in floppy drive) | 1983 | beta |
| PC-6001mkIISR | 1984 | beta |

Pick the model in **Machine > Model**, then **Apply and reset**.

## Setup

1. Copy the newest `releases/PC6001_*.rbf` to `_Computer/` on the SD card.
2. Put the ROMs in `games/PC6001/`. No ROMs come with the core: make them from your own machine's ROM files (the
   names are those used by PC6001VX and MAME).

| File | Model | Contents |
|---|---|---|
| `boot.rom` | PC-6001 (required) | `cat BASICROM.60 CGROM60.60 DISK.ROM > boot.rom` |
| `boot1.rom` | PC-6001mkII | `cat BASICROM.62 VOICEROM.62 CGROM60.62 CGROM60m.62 KANJIROM.62 > boot1.rom` |
| `boot2.rom` | PC-6601 | `cat BASICROM.66 VOICEROM.66 CGROM60.66 CGROM66.66 KANJIROM.66 > boot2.rom` |
| `boot3.rom` | PC-6001mkIISR | `cat SYSTEMROM1.64 SYSTEMROM2.64 CGROM68.64 > boot3.rom` |

`DISK.ROM` (2 KB, CRC32 2158d307) is the PC-6031 disk unit's firmware. It is optional: leave it off (a 20 KB
boot.rom) for a PC-6001 with no disk unit. The sub CPU's ROM is not needed.

## Using it

The PC-6001 starts at **How Many Pages?** Press Return (or a number of graphics pages, 1-4). The mkII models
start at a **mode menu**: 1-4 are the PC-6001's BASIC, 5 is the model's own (N60m-BASIC, or N66-BASIC on the
PC-6601), and 6 is N66SR-BASIC on the SR.

**Tapes** (.cas, .p6, .p6t): mount one under **Tape**. With **Tape auto-start** On (the default) the core
resets, answers the mode and page questions, types `CLOAD` and then `RUN` for you. A box at the bottom says
what it is doing, or what to type when it cannot tell. The tape plays at 7x while the motor runs (Machine > Tape
speed sets Normal).

To load by hand, type `CLOAD` and Return, then `RUN` when it says Ok. Many tape names give the setup: `{m2p3}`
means mode 2 at the menu and 3 pages. **A wrong page count often makes a game fail with no error.** Machine-code
tapes on the mkII (Hudson Soft's games and others) load with `MON` then `R0`. The box tells you when a tape
needs this.

The core knows about 570 tapes by their contents: for those it uses the right mode, page count and commands
(some need `CLEAR` first, or `MON`), and with Tape auto-start it switches to the model the tape was made for when
that model's ROMs are on the SD card. When a program uses hardware the running model lacks, the box says which
model it was made for.

**Cartridges** (.rom, .bin, .60, up to 16 KB): mount one under **Cartridge** and the machine resets into it. Use
**Remove cartridge** to go back to BASIC.

**Disks** (.d88): mount under **Disk 1** and **Disk 2**. The PC-6001 and the mkII use the PC-6031 disk unit,
which needs DISK.ROM in boot.rom (on the PC-6001 also the N60 Extended BASIC cartridge); the PC-6601 uses its
built-in drive. On the mkIISR the unit is a PC-6031SR and takes 1DD disks (80 tracks), as SR software comes on.
mkII disks that start with a `SYS` program boot by themselves. Writes are saved back to the image on the SD card.

The core can't make an image file larger, so to format a new disk, start from a full-size blank:
`python3 tools/blank_d88.py new.d88` (1D) or `--1dd` (1DD, for the SR).

## Keyboard

| PC-6001 key | PC key |
|---|---|
| GRAPH | Alt |
| KANA | F7, or the kana key of a Japanese keyboard |
| MODE | F8 |
| STOP | F9 or End |
| PAGE | Page Up / Page Down |
| HOME, INS, DEL | Home, Insert, Delete / Backspace |
| F1-F5 (Shift: F6-F10) | F1-F5 |

**Input > Keyboard** sets the layout:
- **JP** (the default) puts the keys at the positions of the Japanese keyboard. For example `'` types `:` and
  `[` types `@`.
- **US** types the symbols printed on a US keyboard.

Letters without Shift are lower case, as on the real machine.

## OSD

| Option | |
|---|---|
| Memory | 16 or 32 KB for the PC-6001 (32 KB is a PC-6006 RAM cartridge) |
| Tape speed / Tape auto-start / Rewind tape | as above |
| Tape overlay | the tape counter, a progress bar and the next-step hint |
| Video | RGB, or Composite (TV) on every model: the NTSC artifact colours that mode 4 (`SCREEN 4`) games were drawn for |
| B/W colours | which colours mode 4's black/white set gives (TVs differed); in RGB, None keeps black and white |
| Port 2 | Joystick, or Touch panel: the mouse works NEC's Touch Panel cartridge (hold the left button to draw) |

Joysticks are on ports 1 and 2, with two buttons each. **Swap Alt/Win keys** makes the Win keys GRAPH.

## Not done yet

- Printer and RS-232C. CSAVE, and loading tapes from WAV or the audio input.
- 2D disks, and the PC-6601's disk formatting.
- The banked Senshi no Cartridge.
- The mkII voice chip's built-in phrases. `TALK` with text works.
- The SR's serial port and voice interrupt. The PC-6601SR can't be done, because its ROMs have not been dumped.

Reports of software that works or doesn't are welcome, especially for the mkII, 6601 and SR.

## Simulation

`verilator/` holds a headless simulator: `make`, then `./run_tests.sh`, or for example
`./obj_dir_headless/Vtop --rom-dir ../rom --tape game.cas --tape-turbo --stop-at-frame 1500`
(`--help` lists the options). It needs Verilator 5, GHDL 5 and Python 3, and the ROM files in `../rom`.

## Credits

- Z80: T80 (Daniel Wallner and others).
- AY-3-8910 and YM2203: jt49 and jt12 by Jose Tejada.
- Composite decoder: from Jamie Blanks' NES core (MIT).
- The core follows MAME's pc6001 driver, PC6001VX, PC6001V and the Common Source Code Project.
- The simulator harness comes from SMC777_MiSTer.

There is no public good dump of the sub CPU (8049) ROM, so the core implements its behaviour, as the emulators do.
