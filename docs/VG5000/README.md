# Philips VG5000µ for MiSTer

The Philips VG5000µ is a French home computer from 1984, also sold as the
Radiola VG5000 and the Schneider VG5000. It has a Z80A at 4 MHz, 16 KB of RAM,
Microsoft-derived BASIC in ROM and the Thomson EF9345 video chip: 40 or 80
columns of text, 8 colours, double-height and double-width characters,
semigraphics and redefinable characters. Programs come on cassette.

**Working:** BASIC 1.1 and 1.0, the keyboard (US PC or French AZERTY layout),
40- and 80-column video, sound, tape loading from `.k7` and `.wav` files with
a 4x turbo, tape saving to `.k7`, memory expansion to 32 KB or 48 KB and the
Δ key.
**Not tested yet:** joysticks, the line-in cassette input, saving at 2400 baud.
**Not implemented:** printer, light pen, the EF9345's interlaced and 60 Hz
modes (the VG5000 doesn't use them).

## Installation

* Copy `releases/VG5000_*.rbf` to `/media/fat/_Computer/`.
* Put the BASIC 1.1 ROM in `/media/fat/games/VG5000/boot.rom`. This is
  `vg5k11.bin` from MAME's `vg5k` set: 16384 bytes, CRC32 `a6f4a0ea`. The
  core can't start without it. The ROM isn't included here for copyright
  reasons.
* Put tape images (`.k7` or `.wav`) in `/media/fat/games/VG5000/`.

The character set of the EF9345 is built into the core, so you don't need
MAME's `charset.rom`.

## Loading a tape

1. Press F12, choose **Tape** and pick a `.k7` or `.wav` file.
2. Type `CLOAD` and press Return. The bottom-left corner of the screen shows
   what to type.
3. Machine-code programs start by themselves. For a BASIC program, type `RUN`
   and Return when the load is done. The corner tells you when.

While the tape plays, the corner shows the time and a progress bar. With
**Tape speed** at 4x (the default) loading is four times faster; Normal is
the real speed. Mounting a tape always starts it from the beginning, so for a
multi-part program just type `CLOAD` again for the next part.

Some programs need more memory than the 16 KB of the basic machine. They
reboot or ask for a memory extension ("Extension mémoire ... nécessaire"). Set **Memory** to 48 KB in the
OSD and choose **Apply and reset**, then load the tape again.

## Saving a tape

`CSAVE "NAME"` records to the file mounted as **Tape save**. The file must
already exist and be big enough, because MiSTer can't make a file grow. An
empty file of 256 KB is plenty, for example made with
`dd if=/dev/zero of=/media/fat/games/VG5000/save.k7 bs=1k count=256`.
The result is an ordinary `.k7` file that loads in this core and in MAME.
Each mount starts at the beginning of the file, and several `CSAVE`s in a row
are added one after the other.

## OSD

| Option | Values | |
|---|---|---|
| Tape | `.k7` `.wav` | Mount a tape to play |
| Tape save | `.k7` | Mount a file to record into |
| Load ROM | `.rom` `.bin` | Use another BASIC ROM, e.g. 1.0 (`vg5k10.bin`), until the core is reloaded |
| Memory | **16 KB**, 32 KB, 48 KB | Applied at reset |
| Apply and reset | | |
| **Machine** | | |
| Tape speed | **4x**, Normal | 4x speeds up the CPU and the tape together, only while the tape runs |
| Rewind tape | | |
| Delta key (NMI) | | The same as pressing Δ |
| **Video** | | |
| Aspect ratio | Original, Full Screen, ARC1, ARC2 | |
| Scale | Normal, V-Integer, Narrower / Wider HV-Integer | |
| Scandoubler Fx | None, HQ2x, CRT 25/50/75% | |
| Tape overlay | **On**, Off | The tape status and the what-to-type hint |
| **Input** | | |
| Keyboard | **PC (US)**, AZERTY | See below |
| Swap joysticks | **No**, Yes | |
| **Audio** | | |
| Tape audio | **Off**, On | Hear the tape while it loads |

## Keyboard

The VG5000 has an AZERTY keyboard. With **Keyboard** set to **PC (US)**, keys
type what is printed on a US keyboard: letters go to the same letter and
symbols are moved to wherever the VG5000 has them. `\ { } ` ~` don't exist on
the VG5000. With **AZERTY**, keys are mapped by position, which suits a French
keyboard.

| PC key | VG5000 key |
|---|---|
| End | Δ (NMI). **Ctrl + End** is the VG5000's warm reset |
| Home or F1 | LIST |
| Esc or F2 | RUN / STOP (break) |
| Insert | INS |
| Backspace or Delete | EFFC |
| Page Down | PRT |
| Caps Lock | LCK |
| Tab | ÷ |
| Ctrl | CTRL |

Pasting text into the core (from the MiSTer's own paste function) works.

## Joysticks

Two joysticks, with the direction and two buttons each, on the VG5000's
joystick ports (I/O ports 07 and 08). This hasn't been tested with a game yet.
Only games written for joysticks use
them; most VG5000 games use the keyboard.

## Video

The core outputs the EF9345's own PAL picture: 15.625 kHz, 50 Hz. On a 15 kHz
CRT, set Scandoubler Fx to None and don't force the scandoubler in
`MiSTer.ini`. On HDMI, Scandoubler Fx None gives the sharpest picture.

## Credits

* Philips VG5000µ machine, tape and top level: this repository.
* Z80: t80sv by Rodimus, a SystemVerilog translation of T80 (Daniel Wallner
  and others), see `rtl/t80sv/`.
* EF9345: translated to SystemVerilog from D. Laurens' VHDL EF9345 in
  orpigame's FPGA-Emulator, then fixed against MAME and against captures of
  real chips from fabio-d's EF9345 test suite. See `rtl/ef9345/`.
* Behaviour checked against MAME's `vg5k` driver and EF9345 device
  (Sandro Ronco, Daniel Coulom), Daniel Coulom's dcvg5k emulator and the
  Philips technical manuals.

## Licences

* The core is GPL-2.0, see `LICENSE`.
* `rtl/ef9345/` is CERN-OHL-S-2.0, see `rtl/ef9345/LICENSE`.
* `rtl/t80sv/` uses T80's BSD-style licence, see `rtl/t80sv/LICENSE`.

## Simulation

`verilator/` has a Verilator 5 simulation of the whole machine. Put
`vg5k11.bin` (and for the tests `vg5k10.bin`, `charset.rom` and the tapes named
in `tests/regress.tsv`) in `verilator/files/`, then run `make` and
`make test`. `./obj_dir/Vvg5000_sim --help` lists the options.
