# [Sharp MZ](https://en.wikipedia.org/wiki/Sharp_MZ) for MiSTer Platform

A hardware emulation of the Sharp MZ series personal and business computers, originally written by Philip Smart ([eaw.app](https://www.eaw.app/sharpmz-emulator/)), running as a standard MiSTer 8-bit computer core.

| Model  | Status | Model  | Status |
| ------ | ------ | ------ | ------ |
| MZ-80K | Working | MZ-80C | Working |
| MZ-1200 | Working (MZ-80K monitor SP-1002 and keyboard; keys fixed 2026-10-11) | MZ-80A | Working |
| MZ-700 | Working | MZ-80B | Working: IPL boots tape and floppy (BASIC, CP/M) |
| MZ-2000 | Working: IPL, tape and floppy, colour graphics, katakana | MZ-800 | Working (IPL, graphics, PSG, tape, floppy, CP/M), tested on hardware |
| MZ-1500 | New: IPL, PCG graphics, stereo PSG, Quick Disk (read and write) | | |

How it compares with the original v2 core, NibblesLab's DE0 cores, mz800emu and MAME: [docs/comparison.md](docs/comparison.md).

## Features

* Z80 CPU at the original speed (2 MHz MZ-80K/C/1200/A, 3.547 MHz MZ-700/800, 4 MHz MZ-80B/2000), with turbo steps up to about 32–35 MHz.
* Native video timing, 15.6 kHz (MZ-700/800/1500 50 Hz PAL, the others 60 Hz), scaled by the MiSTer framework for HDMI; analog output gets the native 15 kHz signal, or 31 kHz through the scandoubler (HQ2x, scanlines) for VGA monitors.
* 40x25 and 80x25, mono and colour character modes; programmable character generator (PCG): the MZ-700's HAL PCG-700 (E010-E012; programs switch it on), the MZ-1500's PCG; MZ-80B/2000 graphics RAM.
* MZ-800: IPL and 9Z-504M monitor, MZ-700 and MZ-800 modes with the MZ-800 memory map, all 320x200/640x200 graphics modes with hardware scroll, the SN76489 sound chip and the Z80 PIO.
* Floppy disk (MB8876 interface on the MZ-700, MZ-800, MZ-80B and MZ-2000): two drives from Extended DSK (`.dsk`) or D88/D77 images. The MZ-800 IPL boots CP/M 1.x, 2.3 and 4.1 disks; the MZ-80B/2000 IPL boots Disk BASIC, CP/M and TF-DOS.
* 8253 sound or the tape signal on the audio output.
* Joysticks: the MZ-800's ports and the MZ-1X03 joysticks of the MZ-700/1500.
* Cassette: MZF loading onto the virtual tape or straight into RAM, and a **Tape Image** slot that loads multi-program tapes and **saves** programs written with SAVE. MZ-80B/2000 load from the tape image under IPL control (deck commands and APSS seek). Fast tape up to 32x.
* Monitor ROMs, character generator ROMs and keymaps for every model are built in, and can be replaced from the OSD.

## Installation

Copy `SharpMZ_<date>.rbf` from `releases/` to the `_Computer` folder of your MiSTer SD card, and put your tape files (`.mzf`, `.mzt`) and disk images (`.dsk`) in `games/SharpMZ/`.

## Using the Emulator

The core boots as an MZ-80A with the SA-1510 monitor. Press F12 for the OSD.

Load Direct, the tape image, the two floppy drives and the Quick Disk are on the OSD's first page; the other settings are in the Machine, Tape, Display, Floppy and ROM and RAM pages below. MGL files can load any of the first-page entries (`<file type="f" index="2">` for Load Direct to RAM, `type="s" index="0"` for the tape image, `index="1"`/`"2"` for the drives).

### Machine

| Option | Description |
| ------ | ----------- |
| Model | MZ-80A, MZ-80K, MZ-80C, MZ-1200, MZ-700, MZ-80B, MZ-2000, MZ-800 or MZ-1500. Changing model resets the machine. |
| CPU Speed | Normal is the original speed; 2x to 16x multiply it, and Fastest is the most the core can do on that model (about 35 MHz, clk_sys/2). On the MZ-700/800/1500 16x is already the fastest. |
| MZ-80B/2000 Boot Reset | MZ-80B/2000: reset back into the IPL. |
| Keyboard Layout | PC (default): each key types what is printed on it, as on a US PC keyboard, on every model: the core presses or releases the machine's SHIFT as needed (on the MZ-80A, @ is unshifted and " is SHIFT 2). Letters, Return, the cursor keys and so on work as in the Sharp layout, so letters type capitals as on the real machines. Characters a model doesn't have do nothing. Sharp: each key is the Sharp key in its place, with the Sharp machine's own legends (for games and for typing as on the original keyboard). On the MZ-80A, MZ-700, MZ-800 and MZ-1500, Ctrl is CTRL (CTL), Esc is BREAK and Alt is GRAPH (GRPH). |
| MZ-1X03 Joysticks | MZ-700/MZ-1500: connect two Sharp MZ-1X03 joysticks (MiSTer joysticks 1 and 2, read on E008). The MZ-800's own joystick ports (F0/F1) are always connected. |
| MZ-800 Mode | The MZ-800 rear switch. In MZ-800 mode the IPL switches to MZ-800 graphics before starting a program loaded from tape; in MZ-700 mode (default) programs start in MZ-700 mode, which MZ-700 software needs. Reset after changing it. |
| Region | Europe (default) or Japan, for the MZ-700. Japan is the Japanese MZ-700: its character generator, with katakana in place of the European lower case (the MZ-1500's CG, MAME `mz700fon.jpn`), its monitor ROM 1Z-009B (Japanese software prints through it: Tiny Xevious's side panel reads correctly only with it), and 60 Hz NTSC timing instead of 50 Hz PAL, so games run at their original speed. Japanese games and adventures need it (Donkey Gorilla, Namco's MZ-700 titles). The MZ-1500 was only sold in Japan and is always Japanese (60 Hz). Changing it resets the machine. |

### Tape

A tape is either a single `.mzf` file (a 128-byte header followed by the program) or an `.mzt` file (several `.mzf` records back to back).

| Option | Description |
| ------ | ----------- |
| Load Direct to RAM | Copy the program straight into memory at its load address and start it (see Load Direct below). |
| Tape Image | The cassette itself (it replaces the old core's tape queue and Load Tape to CMT). Mount an `.mzt` (several programs back to back) or `.mzf`. The first program is ready to play; when the machine stops the tape after reading one program, the next one is loaded, so multi-part programs and loaders work. On the MZ-80B/2000 the APSS deck controls work on it: fast forward/rewind to the next/previous program, eject rewinds to the start. Programs saved with SAVE are appended to the image. |
| Rewind Tape Image | Go back to the first program on the mounted image. |
| Tape Image Start | Tape (default): the tape image plays from its first program, loaded as usual (`L`, `C` at the IPL menu, and so on). Direct: when an image is mounted, its first program goes straight into memory and starts, as Load Direct does, and the tape is left at the second program. A loader then reads the rest from the tape (Exolon, Knight Lore), and a BASIC tape starts BASIC with the program ready for `LOAD`. Not on the MZ-80B/2000. |
| Tape Messages | On (default): for three seconds after the tape image moves, a line at the bottom of the picture says where it is, for example `TAPE 2/5 EXOLON` (the program now ready to play, out of five on the tape), `TAPE 6/5 END`, `TAPE SAVED 6 MYPROG` or `TAPE FULL`. |
| Tape Buttons | Auto (play or record as the machine needs), Off, Play, Record. |
| Fast Tape | Run the CPU (and the tape) faster while the tape is moving. Fastest (default) is the most the core can do (about 35 MHz); 2x to 16x are slower steps; Off is real speed, for the few programs whose loaders count time while the tape runs. |
| Sharp ASCII Name | Convert tape file names between Sharp display codes and ASCII on save and/or load. |
| Tape Sound | Off (default); Mix: the tape signal mixed in quietly while the tape plays or records, as the machines' own tape monitor would; Only: the tape signal instead of the machine's sound. |
| Load Direct Start | Program (default): after Load Direct to RAM the machine boots for about 1.5 s, then the core puts back what the load wrote to 10F0-11FF (the boot uses that area), sets the memory map and jumps to the exec address with SP at 10F0, as after a tape load. Only machine-code files (MZF type 01) are started; BASIC programs and data just reset. Reset Only: just reset, then start it yourself with `J` and the exec address in the monitor; the MZF header is in RAM at 10F0 as after a tape load (load address at 10F0+20, exec at 10F0+22, low byte first). The MZ-80B and MZ-2000 always reset only. |

**Saving programs.** MiSTer can't grow a mounted file, so saving needs a tape image with spare room. Make a blank one with `tools/make_blank_tape.py` (default 1 MB, zero-filled), mount it as the Tape Image, and SAVE as usual (for example `S120012FF1200` then a file name in the MZ-700 monitor). Each program is appended after the last one. If the image is read-only or full, the save is skipped.

### Floppy

| Option | Description |
| ------ | ----------- |
| Floppy Drive A / B | Mount an Extended DSK or D88/D77 image (up to 2 MB: 720 KB CP/M disks and 1.44 MB HD disks). With a disk in drive A, the MZ-800 and MZ-80B IPLs boot it at reset; on the MZ-700 type `J F000` at the monitor (the interface brings its MZ-1E05 ROM). The interface is available on the MZ-700, MZ-800, MZ-80A, MZ-80B and MZ-2000. On the MZ-80A type `F` at the monitor and Return for drive 1 (the interface ROM boots, for example, SA-6510 Disk BASIC). |
| Quick Disk | Mount a Quick Disk image: a raw dump (`.qdf`) or mz800emu's `.mzq`. Built into the MZ-1500 (press `Q` at the IPL menu); on the MZ-800 it appears while an image is mounted. Writes (BASIC `INIT "QD:"`, `SAVE`) go back to the image, which must be full size: make a blank one with `tools/make_blank_qd.py`. A tape (`.mzt` or `.mzf`) can be mounted here too: each of its programs becomes a file on the disk (read only). Many MZ-1500 Quick Disk titles survive only as tapes: mount their side B (or the program) here. For a BASIC program, boot MZ-5Z001 BASIC from its disk or tape, then mount the program's tape here and `LOAD` it. The tape message starts `QD:` (instead of `TAPE`) for such a program when it is mounted as a tape on the MZ-1500. |
| Floppy Interface | Auto (present only while a disk is mounted, so the IPL doesn't stop at "Make ready FD"), On or Off. |
| Floppy CRC Errors | Ignore (default): sectors the disk image marks as read with a CRC error are read as good, which suits most dumps. Report: the drive reports CRC ERROR for them, for software that checks (copy protection). |
| Drive B Unit | Which unit the drive B slot answers as: the 2nd drive (B:), or the 3rd, where the MZ-800 CP/M 4.1 HD driver keeps its 1440 KB drive C:. Mount a 1.44 MB image there and use C:. |
| MZ-800 RAM Disk | A 64 KB RAM disk board (ports EA/EB, F8-FA), for CP/M's RAM drive. Its contents are lost at power off. |

Writes go back to the image; mount a copy if you want to keep the original.

### Display

| Option | Description |
| ------ | ----------- |
| Display Type | Default follows the model (MZ-700/800 colour 40x25, MZ-80B/2000 mono 80x25, others mono 40x25). |
| Scandoubler Fx | None (native 15 kHz), HQ2x or CRT scanlines 25/50/75%: doubles the picture to 31 kHz for VGA monitors. MiSTer.ini `forced_scandoubler=1` doubles it too. |
| MZ-800 Border | Show the MZ-800 border colour around the picture (464 x 288 instead of 320 x 200). |
| VRAM Wait | Insert the original wait states when the CPU accesses video RAM during the display (MZ-80A/1200/700). Some software relies on this timing. |
| Aspect ratio | Original, full screen, or the custom ratios from `MiSTer.ini`. |

### ROM and RAM

| Option | Description |
| ------ | ----------- |
| User ROM / FDC ROM | Map the user ROM (E800) or FDC ROM (F000) for the current model. |
| Load System ROM / RAM / CGROM | Replace the built-in combined monitor ROM, the initial RAM image or the character generator ROM. The files use the same layout as `rtl/software/roms/combined_*.rom`. The System ROM and CGROM you choose are remembered: the core loads them again every time it starts (and starts on them), until you choose another. A `boot.rom` in `games/SharpMZ` is loaded at start as well. (The keymap is built in; Keyboard Layout chooses PC or Sharp.) |

**Alternative monitor ROMs.** Load System ROM writes the file from the start of the core's 128 KB system ROM
(`rtl/software/roms/combined_mrom.rom`), through the normal MiSTer file download. The first 4 KB of that ROM is the
MZ-80K's 40-column monitor, so a 4 KB MZ-80K monitor (for example `80ktc.rom`, which starts "System Monitor") can be
loaded as it is:

1. Machine: MZ-80K, Display: 40 columns.
2. ROM and RAM > Load System ROM, pick the `.rom` file.
3. Press Reset (OSD Reset). The CPU keeps running the old monitor until the reset, so loading alone seems to do
   nothing.

The new monitor stays until the core is loaded again: the ROM is block RAM set up from the RBF, and Reset doesn't
restore it. To go back to SP-1002, reload the core (or load a copy of `combined_mrom.rom`). Loading a monitor again
after that works the same way. It only replaces the 40-column monitor: with an 80-column display the MZ-80K uses
the copy at 0x1000.

For other models, or the 80-column monitor, make a full image with the monitor at that model's offset and load it
instead: `tools/make_monitor_rom.py mz80c monitor.rom out.rom [--80col]` (MZ-80K, 80C, 1200, 80A and 700; the
offsets are listed in the script).

### Printer

| Option | Description |
| ------ | ----------- |
| Printer | None, or UART: what the machine prints goes out of the MiSTer UART (8N1, at the speed set in Main's UART menu, 9600 by default) for the printer daemon [mister_printerd](https://github.com/alanswx/printeremulation), which makes a PDF (Epson model). Set the UART connection to Printer in Main's UART menu. |
| Printer Charset | Sharp (default): bytes go out as the machine sends them, for the daemon's Sharp model (MZ-1P16 plotter-printer). ASCII: Sharp lowercase and symbols are converted to ASCII, graphics characters to spaces, and a bare CR (what BASIC's `PRINT/P` sends) gets an LF after it, for the Epson model and other ASCII printers. |

The MZ-700 printer port is I/O FE/FF and the MZ-800/1500 one the Z80 PIO (port B data, PA7 strobe, PA0 ready), with the handshake of the MZ-800 Technical Reference Manual and MZ-700 BASIC (`rtl/mz_printer.sv`). BASIC's `LIST/P` and `PRINT/P` print. The MZ-731's 4-colour plotter is driven through the same port, so its commands (`MODE GR`, `LINE`, `PCOLOR`) are sent too; the daemon's `sharpmz` model draws them (it is picked automatically for this core). With the option off the port behaves as before (no printer: the MZ-700 BASIC times out, the MZ-800 PIO reads ready).

## Known Issues

* MZ-2000: the character ROM is MAME's `font.bin`, which was rebuilt by hand from bitmaps (MAME marks it a bad dump); a few katakana glyphs may differ from the real IX0286PA ROM.
* MZ-800: checked in simulation against the mz800emu emulator, still being tested on hardware. The border colour is an option (Display > MZ-800 Border). Joysticks work in Knight Lore and Exolon in simulation; the RAM disk is new. Load Direct starts the program as mz800emu's direct load does, so programs that start in or read their MZF header at 10F0 (Exploding Fist, Jumpin' Jack, Solomon's Key) work (`docs/triage.md`).
* Floppy: the MZ-80K floppy interface isn't implemented (the MZ-80A's is). 1.44 MB images work as CP/M 4.1's HD drive C: (Drive B Unit: 3rd), read and write, on hardware. Writing works (CP/M SAVE on hardware); drive B and writes at turbo speeds are untested.
* The author's framebuffer graphics extension (bitmap graphics for the MZ-700/80A) isn't available in this version.
* The MZ-80B/2000 have had little testing beyond a handful of tapes and disks (see `TODO.md`).
* Many MZ-1500 Quick Disk titles are archived as two tape images (side A a "DATA" loader that asks for side B). Side A loads from the tape image; when it asks for side B ("SET PROGRAM QD ?"), mount side B's `.mzt` as the Quick Disk and answer `Y`. (`tools/mzf2qdf.py OUT.qdf SIDE.mzt` still makes a real Quick Disk image of a tape, the same disk the core shows.) `tools/qdinfo.py` lists a Quick Disk image's files and checks their CRCs.
* Reset: OSD Reset (or Reset and close OSD), the MiSTer's USER button and LCtrl+LAlt+RAlt reset the machine; the physical reset button reloads it from cold. Before 2026-10-09 the OSD Reset entries did nothing.
* MZ-1500 BASIC programs need MZ-5Z001 BASIC loaded first. Some tape images in the year-based collection say file type 02 (Zulpoko Daisakusen, Techno City Cars, Bacterianns): they are Quick Disk BASIC files dumped to tape, and MZ-5Z001 only loads them from a Quick Disk ("Illegal filemode" from tape). Mount the BASIC tape and then the program's tape in the Quick Disk slot (see Quick Disk above); Zulpoko runs that way.
* Tape recordings (the No-Intro "Waveform" sets, `.wav`/`.flac`) convert to MZF with `tools/wav2mzf.py RECORDING [OUTDIR]` (standard Sharp format only, not turbo loaders).

## Design Summary

* **One clock.** Everything runs on a single 70.9376 MHz clock (4x the MZ-700's 17.7344 MHz crystal) with clock enables for the CPU, video, sound and timers (`rtl/clkgen.vhd`). The MZ-700/800 rates are exact divides.
* **Standard MiSTer framework.** The `sys/` folder is stock Template_MiSTer, the OSD is a normal configuration string, and files come in through the standard ioctl and image-slot interfaces. Main_MiSTer's old Sharp MZ driver isn't used.
* **Video** is the author's v2 VideoController from the [tranZPUter](https://git.eaw.app/eaw/tranZPUter) project, moved onto the core clock (`rtl/vc/`).
* **Tape images** are handled in the FPGA by `rtl/tape_image.sv`, which moves programs between the image and the core's cassette buffer. The 64 KB tape data buffer is in the DE10-Nano's DDR3 (`rtl/tape_ddr.sv`, the MiSTer DDRAM port), which leaves block RAM for the floppy sector tables; no SDRAM board is needed.
* **Floppy** is `rtl/mz_fdc.sv`: the Sharp interface around Sorgelig's `wd1793.sv` (from the FM-7 core), reading DSK images through the image slots.
* More detail in `docs/design.md`.

## Building and Simulation

* **FPGA:** open `SharpMZ.qpf` in Quartus Prime Lite 17.0 and compile.
* **Simulation:** `verilator/` runs the core headless with GHDL and Verilator: boot any model, type at it, load and save tapes, and write screenshots. `make test` runs the regression tests. See `verilator/README.md`.
* **Status and open work:** `TODO.md`. **Design notes:** `docs/design.md`.

## Links

The Sharp MZ Series Computers were not as wide spread as Commodore, Atari or Sinclair but they had a dedicated following. Given their open design it was very easy to modify and extend applications such as the BASIC interpreters and likewise easy to add hardware extension. As such, a look round the web finds some very comprehensive User Groups with invaluable resources. If you need manuals, programs, information then please look (for starters) at the following sites:

| Site                                                 | Description |
| ----                                                 | ----------- |
| [Engineers At Work](https://www.eaw.app/)            | My personal projects site. |
| [SharpMZ.org](https://original.sharpmz.org/)         | Original SharpMZ site, excellent resource but the owner has retired now. |
| [SharpMZ.no](https://www.sharpmz.no/)                | Site to replace the Original SharpMZ site, still under development. |
| [mz-80a.com](https://mz-80a.com)                     | MZ-80A Sectors guide to the Sharp MZ-80A |
| [Sharp Users Club](http://www.sharpusersclub.org/)   | Still active, the Sharp Users Club. |
| [SharpMZ Forum](http://forum.sharpmz.org)            | Active Sharp MZ forum for all models. |
| [SCAV](http://www.scav.cz/uvod.htm)                  | Czech site for Sharp information and downloads, use chrome to auto translate Czech |

## Credits

My original intention was to port the MZ80C Emulator written by Nibbles Lab <https://github.com/NibblesLab/mz80c_de0> to the Terasic DE10 Nano. After spending some time analyzing it and trying to remove the NIOSII dependency, I discovered the MISTer project, at that point I decided upon writing my own emulation. Consequently some ideas in this code will have originated from Nibbles Lab and the i8253/Keymatrix modules were adapted to work in this implementation. Thus due credit to Nibbles Lab and his excellent work. Also credit to Sorgelig for his hard work in creating the MiSTer framework and design of some excellent hardware add-ons. The MiSTer framework makes it significantly easier to design/port emulations. Where I have used or based any component on a 3rd parties design I have included the original authors copyright notice within the headers or given due credit. All 3rd party software, to my knowledge and research, is open source and freely useable, if there is found to be any component with licensing restrictions, it will be removed from this repository and a suitable link/config provided.

## Licenses

This design, hardware and software, is licensed under the GNU Public Licence v3.

### The Gnu Public License v3

 The source and binary files in this project marked as GPL v3 are free software: you can redistribute it and-or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

 The source files are distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

 You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.
