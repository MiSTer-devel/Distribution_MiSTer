# Memotech MTX512 for [MiSTer](https://github.com/MiSTer-devel/Main_MiSTer/wiki)

A Memotech MTX500/512 core for MiSTer. It boots straight to MTX BASIC using ROM images you supply yourself, and has the Memotech disc system and the 80 column board with CP/M as options.

It is based on [REMEMOTECH](http://www.nyangau.org/rememotech/rememotech.htm) by Andy Key and its MiSTer port [Rememotech-Mister](https://github.com/RW-FPGA-devel-Team/Rememotech-Mister) by the RW FPGA devel Team.

**No ROM images are included in this repository or in the core.** The Memotech ROMs, a CP/M system disc and the 80 column character ROM are yours to supply; `tools/` has scripts that put your own ROM files together.

## Features
- Z80 CPU (T80), exact 4 MHz stock speed, or 5, 6.25 and 8.33 MHz
- VDP video over HDMI and VGA, 4:3 or 16:9, 50 or 60 Hz, normal or Marat palette
- SN76489 sound chip model, checked against the data sheet
- Tapes: `.mtx` (instant load) and `.wav` (played in real time); SAVE to a `.mtx` file on the SD card
- The SDX disc system: SDX FDC 05 controller (WD1793) with discs as image files, ROM 3 or ROM 5
- 64K, or 320K of RAM (the 256KB expansion is kept in the MiSTer SDRAM module)
- ROM 2 (for example a Pascal ROM, loaded from the OSD) and a longer `boot.rom`
- The Communications board: Z80 DART serial port on the MiSTer UART
- The 80 column board (6845 CRTC, colour attributes, graphics characters), written from its schematic and the MTX-FDX technical manual, and **CP/M 2.2** from the SDX controller with the CP/M bootstrap PROM
- Joysticks wired into the keyboard matrix, as on the real MTX

## Installation
1. Copy `releases/MTX512_*_menu.rbf` to the `_Computer` folder of the SD card.
2. Put your ROMs in `games/MTX512/` on the card: `boot.rom` (OS), `boot1.rom` (BASIC), `boot2.rom` (ASSEM, optional), `boot3.rom` (SDX ROM, optional). Each is 8192 bytes.
3. Optional: `blank/BLANK.mtx` is a blank tape for SAVE (65536 bytes). The release package also has blank SDX disc images; they are not in this repository because an SDX disc carries the SDX system area (CP/M BDOS and BIOS, other people's software). `tools/make_blank_disc.py` makes an empty disc from your own system disc.

`docs/GUIDE.txt` is the full user guide. It covers tapes, SAVE and VERIFY, the SDX, RAM, ROM 2, the serial port and, step by step, **CP/M and FDXB (Disc BASIC)**, with the keyboard, the MD5 checksums of the ROMs that were used for testing, and what to do when something does not work. `docs/CHANGES.txt` lists the changes and `docs/README.txt` is a short version.

## CP/M in short
`tools/make_boot3_rom.py` (or `make_boot3_rom.bat`, or the script in `scripts/`) makes a `boot3.rom` of 24576 bytes from your SDX ROM, the 80 column board's character ROM and the CP/M bootstrap PROM. Mount a CP/M system disc as SDX Disc A, choose OSD -> `CP/M: Disc ROM` -> `CP/M`, then OSD -> Reset. See section 6.5 and 6.6 of the guide.

## Building
Quartus Prime Lite 17.0.2, from the top folder:

    quartus_sh --flow compile MTX512

The output is `output_files/MTX512.rbf`. The ModelSim test benches and the Python models that were used are in `sim/` (`docs/SOURCE_README.txt` says what each is).

## Status
Parts of this were checked only in logic simulation and in software models; the guide says which. BASIC, tapes, the SDX and CP/M with FDXB have been run on a MiSTer. Reports are welcome.

## Credits
- Andy Key: REMEMOTECH and MEMU (the `.mtx` tape format and the INOUT replacement come from MEMU)
- RW FPGA devel Team: Rememotech-Mister
- Memotech Ltd: the MTX, its manuals and ROMs
- Dave Stevenson: the redrawn 80 column board schematic; Primrosebank (primrosebank.net) for the Memotech documents and ROM pages
- Daniel Wallner, Mike J and the T80 authors: the Z80 core
- MiSTer-devel: Template_MiSTer, the `sys/` framework, and the SDRAM controller from the ZX-Spectrum_MiSTer core (by Sorgelig)

## Licence
GNU General Public License version 2, as REMEMOTECH and the MiSTer template. The Memotech ROMs are not covered by it and are not here.
