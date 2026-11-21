# Spectravideo SVI-328 / SVI-318

Core by fpganoob on misterfpga.org.

Place the BASIC ROM in `games/SVI328/boot.rom` (SV Extended BASIC 1.1 for the
SVI-328; another ROM can be picked for one session with **Load ROM**). For the
SV-806 80-column card, place its 4 KB character ROM (`svi806.rom`, MAME
`sv806.ic27`) in `games/SVI328/boot1.rom`; without it the card is left out.

## OSD

| Row | Page | |
|---|---|---|
| Cartridge | top | a cartridge image (`.bin` / `.rom`, up to 64 KB) |
| Tape | top | a `.cas` tape image (hidden when Tape input = ADC) |
| Tape save | top | a `.cas` file that CSAVE / BSAVE"CAS:" / SAVE"CAS:" record into (see Saving to tape) |
| Disk A, Disk B | top | `.dsk` disk images for the SV-801's two drives (shown when SV-801 disk = On) |
| Load ROM | top | another BASIC ROM for this session |
| Memory | top | `SV-807 (160K)` (default): banks 21, 22, 31 and 32 present, as with the SV-807 RAM expansion; `Standard`: the machine alone |
| Model | Machine | `SVI-328` (64 KB) or `SVI-318` (16 KB at C000-FFFF) |
| SV-801 disk | Machine | `On` (default) / `Off`: the disk controller |
| SV-806 80-column | Machine | `On` (default) / `Off`: the 80-column card (needs `boot1.rom`) |
| Tape input | Machine | `File` (the Tape slot) or `ADC` (a real cassette player on the ADC input) |
| Tape speed | Machine | `4x` (default) or `Normal`; see below |
| Rewind tape, Eject cartridge | Machine | buttons |
| Display | Video | `Auto` (default), `80-column` or `VDP` (with the SV-806 on): which of the machine's two video outputs to show |
| Video standard | Video | `PAL` (default, 50 Hz, TMS9929A) or `NTSC` (60 Hz, TMS9928A) |
| Border | Video | `No` (default) / `Yes`: the VDP's border around the picture |
| Aspect ratio | Video | `Original` (default, the real picture shape, see below), `Full Screen`, `[ARC1]`, `[ARC2]` |
| Scale | Video | `Normal` (default), `V-Integer`, `Narrower HV-Integer`, `Wider HV-Integer` |
| Scandoubler Fx | Video | `None` (default), `HQ2x`, `CRT 25%`, `CRT 50%`, `CRT 75%` |
| Tape overlay | Video | `On` (default) / `Off` |
| Joysticks swap | Input | |
| Tape audio | Audio | `Off` (default) / `On`: hear the tape while it loads |

Settings take effect at **Apply and reset** ("Changes pending" shows while
they differ from what the machine runs); media, buttons, Display, Aspect
ratio, Scale, Scandoubler Fx, Tape speed, Tape overlay, Tape audio and
Joysticks swap act at once. Settings saved by builds before 2026-11-16 are
not carried over (the disk and 80-column defaults changed).

## Picture

The scaler receives 256 x 192 from the VDP (284 x 292 PAL / 284 x 241 NTSC
with Border = Yes, at 5.37 MHz) and 560 x 192 from the SV-806 (12 MHz, 50 Hz).
The VDP's size is the same in every screen mode: 40-column text (240 pixels)
sits centred in it with the backdrop colour either side, as on a TV, and a
blanked screen shows the backdrop instead of no picture, so the scaler never
changes size. `Original` is the shape these had on a TV, from the pixel clock:

| Output | Size | Shape |
|---|---|---|
| VDP, PAL | 256 x 192 | 1.83 : 1 |
| VDP, PAL, Border | 284 x 292 | 1.34 : 1 |
| VDP, NTSC | 256 x 192 | 1.52 : 1 (32:21, as the MSX) |
| VDP, NTSC, Border | 284 x 241 | 1.35 : 1 |
| SV-806 | 560 x 192 | 1.79 : 1 |

A PAL picture is wider than an NTSC one because its 192 lines fill less of
the 288-line PAL screen. On HDMI, leave Scandoubler Fx at `None` for the
biggest integer picture (V-Integer gives 5x at 1080p; with the scandoubler on,
the scaler sees 384 lines and can only do 2x).

## Tapes

Load a `.cas` file in the **Tape** slot, then type the command the tape needs
(the tape status box at the bottom left shows it: `TYPE CLOAD ↵`):

| First file on the tape | Command |
|---|---|
| tokenized BASIC (header type D3h) | `CLOAD`, then `RUN` when it says `Ok` (the box shows `TYPE RUN ↵`) |
| machine code (D0h) | `BLOAD"CAS:",R` |
| ASCII BASIC (EAh) | `RUN"CAS:"` |

The hint is read from the tape's first header only, never from the file name.
It matches the load command named in 199 of the 200 TOSEC tapes that name one.

While the tape plays the box shows elapsed / total time (at the real tape
speed), `x4` while turbo is on, and a progress bar.

**Tape speed 4x** runs the Z80 and the tape 4 times faster, only while the
deck plays: the motor is on and the tape has not reached its end. The machine
runs at normal speed as soon as the BIOS stops the motor or the tape runs out
(Mr. Do! and Kung Fu Master leave the motor on), so games never run fast. The
BIOS times the tape with CPU loops, so it reads the same bits at either speed.
While turbo is on, the Z80 waits on a VDP access until the VDP has stored the
previous one, so a game that draws while it loads (Kung Fu Master's menu)
draws correctly. The setting is taken each time the motor starts.

Mounting a tape rewinds it; a reset also rewinds it.

## Saving to tape

Mount a `.cas` file in **Tape save** and the deck is ready to record:
`CSAVE"NAME"`, `BSAVE"CAS:NAME",start,end` and `SAVE"CAS:NAME"` write into it
from the start of the file, one block after another as on a real tape, until
the file is full. The recorder reads the tape output (PPI C5), measures every
half cycle in Z80 clocks (so 4x turbo makes no difference), and writes the
blocks as CAS (16 x 55h + 7Fh, then the bytes): the same file plays back in
the **Tape** slot with CLOAD / BLOAD / RUN.

MiSTer can't make a mounted file bigger, so the file has to be big enough
already: `releases/blank_tape_64k.cas` (64 KB of zeros, copy and rename it
for each tape). What the recording doesn't reach stays zeros. The user LED is
on while a block is being written and blinks when the file is full. Mounting
the file again starts from the beginning.

## Keyboard

The keys map by position, except where noted:

| SVI key | PC key |
|---|---|
| `:` / `;` | `;` key: `;` unshifted, `:` with Shift (as printed on a PC; the SVI key is the other way round) |
| STOP | F8 or F6 |
| SELECT | F7 |
| PRINT | F9 |
| CLS | Home |
| INS | Insert |
| DEL | Delete |
| left / right GRAPH | left Alt or left Win / right Alt or right Win |
| keypad (SVI-328) | PC keypad (the SVI-318 has no keypad: those rows read as no key) |

## Cartridges

Load a cartridge in the **Cartridge** slot; the machine resets into it.
**Eject cartridge** takes it out and resets into BASIC. Cartridge space
that the image doesn't fill reads FF.

Images over 64 KB (up to 1 MB) are megaROMs as in teiram's Calypso port of
this core: the cartridge bank shows one 16 KB page of the image (mirrored
over the whole bank), and a timer moves it to the next page 8 times a second,
whatever the program does, wrapping after the last page of the image (the
Calypso port always cycles 64 pages; the same for a 1 MB image). The image is
kept in SDRAM and the page being shown in block RAM, so the CPU never waits.

## Disks (SV-801)

**SV-801 disk** is `On` by default: mount a `.dsk` in **Disk** and reset
(Apply and reset), and the BASIC ROM boots Disk BASIC or CP/M from it. With no
disk, BASIC starts about 1.4 s later than with the controller `Off`, while the
BIOS looks for a disk. Images are the raw
format MAME uses (`svi_dsk`): 172032 bytes single-sided or 346112 bytes
double-sided, 40 tracks, track 0 side 0 with 18 x 128-byte sectors and every
other track 17 x 256. Two drives, A: (**Disk A**) and B: (**Disk B**), each with
its own FD1793 replica; the CPU talks to the one selected at port 34h, as the
card's single FD1793 talks to the selected drive. `.imd` images have to be
converted first.

The controller is an FD1793 at ports 30h-34h and 38h, as the SV-801. Its
FD1793 is Sorgelig's wd1793 with the SVI geometry added in teiram's Calypso
port of this core.

## 80 columns (SV-806)

**SV-806 80-column** is `On` by default when `boot1.rom` is present (without
it the card is left out and the Display row is hidden); CP/M and Disk BASIC
then use 80 columns (in Disk BASIC, `WIDTH 40` goes back to the VDP screen and
`WIDTH 80` to the card). The card has its own monochrome monitor output on the
real machine, so **Display** chooses which output the MiSTer shows: `Auto`
shows the screen the software writes to (it changes 0.2 s after the software
moves to the other screen), `80-column` always the card's (green), `VDP`
always the normal picture. Without the card the VDP is always shown. The
card's 6845 runs from its own 12 MHz dot clock: 80 x 24 characters, 50 Hz.

## CPU

The Z80 is t80sv (`rtl/t80sv`), a SystemVerilog translation of the T80 core,
with fixes that make it pass all 1,604,000 SingleStepTests/z80 cases
(undocumented flags, MEMPTR and bus timing included) and ZEXDOC/ZEXALL; see
`rtl/t80sv/README.md` and `verilator/cpu_tests/`.

## I/O ports

As on the STM-A schematic (sheet 2, IC21 LS138): A7 = 1 and A6 = 0 select the
VDP, PSG and PPI, A4-A2 pick one; A5, A1 and A0 are not decoded, so each port
also answers 20h higher (VDP write 80-83/A0-A3, VDP read 84-87/A4-A7, PSG latch
88-8B/A8-AB, PSG write 8C-8F/AC-AF, PSG read 90-93/B0-B3, PPI write 94-97/B4-B7,
PPI read 98-9B/B8-BB).

## Memory map

PSG port B selects the banks as on the real machine: ROMEN0 and ROMEN1 map
the cartridge's upper 32 KB in two independent 16 KB halves and only while
the cartridge bank is selected (STM-A schematic, as MAME). Port B reads FF
until the BIOS makes it an output, as the AY's pull-ups do.

## Simulator

`verilator/` holds a Verilator simulator of the core for development; see
`verilator/README.md`.

## Credits

Second drive, tape saving and megaROM support by Shaeon (Carlos Palmero),
developed with the help of Claude (Anthropic).
