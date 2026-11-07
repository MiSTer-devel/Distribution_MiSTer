# Sharp X1 for MiSTer

A Sharp X1 / X1 Turbo / X1 Turbo Z core for [MiSTer](https://github.com/MiSTer-devel/Main_MiSTer/wiki).

**Status: experimental.** Many disk and tape titles boot and play, but
compatibility is incomplete and some hardware is provisional (see
[Limitations](#limitations)).

## Features

- **Models** (OSD *Machine > Model*): X1 Turbo Z (default), X1, X1 Turbo.
  X1 mode turns the Turbo-only hardware off and boots the X1 IPL. Turbo
  software runs unchanged on the Turbo Z model.
- Z80 at 4 MHz, 80C49 sub-CPU (keyboard, timer, tape deck control), Z80 CTC,
  Z80 DMA, 8255 PPI, AY-3-8910 PSG and the YM2151 FM board (with its CTC).
- Video: 40/80-column text, PCG, 640x200 graphics, 15 kHz and 24 kHz
  (640x400) modes, Kanji ROM, Turbo Z palette, 4096/64-colour and
  two-screen modes.
- Two floppy drives: D88 and raw X1 2D images, read/write (writes are off
  unless enabled in the OSD).
- Cassette: TAP images (4-192 kHz) streamed from SD, with play, fast
  forward, rewind and APSS (skip to next program). Tape speed 5x, quick
  start (boots a tape's first machine-code program at once) and a tape
  position overlay. Recording is not implemented.
- Joysticks: two X1 joystick ports with Trigger A/B.

## Installation

Copy the core RBF (`SharpX1_YYYYMMDD.rbf`) to `_Computer/` on the SD card.
Keep only one `SharpX1_*.rbf` there.

No ROMs are embedded. Put these in `games/SharpX1/`; they load at every core
start:

| File | Contents | Size |
|---|---|---|
| `boot.rom` | X1 Turbo IPL (`IPLROM.x1t` / MAME `ipl.x1t`), optionally followed by the 16-row ANK font (`FNT0816.x1`) | 32 or 36 KiB |
| `boot1.rom` | Cassette controller firmware (build it, see below) | 8 KiB |
| `boot2.rom` | X1 IPL (`IPLROM.x1`), used by Model: X1 | 4 KiB |
| `boot3.rom` | Kanji font (see below) | 256 KiB |

- Make `boot.rom` with `cat IPLROM.x1t FNT0816.x1 > boot.rom`. Without the
  16-row ANK font, 24 kHz text draws half-width characters with the 8x8 font
  doubled. The font can also be loaded with *Load 16-row ANK*.
- Without `boot2.rom`, Model: X1 boots the first 4 KiB of the Turbo IPL.
- Without `boot1.rom` the sub-CPU runs its built-in firmware and tapes don't
  load. Build it with Python 3:
  `python3 scripts/build_mr16_cassette_firmware.py --receive-only --joystick-off --caps-off --output-dir /tmp/x1ctrl`
  and copy `/tmp/x1ctrl/cassette-controller.bin` to `boot1.rom`
  (SHA-256 `79442263d70cc0648601eefbdbd90ca63feed4b7f1a35e0a456b69f00493eb4b`).
- `boot3.rom`: `python3 scripts/prepare_z_kanji.py --output-dir /tmp/x1kanji ARCHIVE`
  builds it from the X1 Turbo model 40 (CZ-862C) Kanji ROM archive
  (`kanji1.rom`-`kanji4.rom`; needs `7z`). Copy `z-kanji-physical.bin` to
  `boot3.rom`. Only level-1 Kanji are present.

Each ROM can also be loaded from the OSD (*Advanced* page) or from an MGL.

## Usage

The top OSD page has *Pri. Drive A*, *Drive B*, *Tape*, *Load 16-row ANK* and
*Load ROM*. Drives and tape start empty at every core load.

| Page | Setting | Notes |
|---|---|---|
| Machine | Model | X1 Turbo Z (default) / X1 / X1 Turbo |
| Machine | Tape speed | 5x + quick start (default) / 5x / Normal |
| Machine | Rewind tape | |
| Video | Monitor | Standard (15 kHz, default) / High-res (24 kHz). Hidden in Model: X1 |
| Video | Aspect ratio | Original / Full Screen / custom |
| Video | Tape overlay | On / Off |
| Advanced | Boot device | 2D / 2DD / 2HD / SASI (Turbo DIP switch) |
| Advanced | Disk writes | Protected (default) / Enabled. Enabled changes your image |
| Advanced | Load X1 IPL / Kanji font / tape ctrl. | Same as `boot2.rom` / `boot3.rom` / `boot1.rom` |

Settings take effect at **Apply and reset** ("Changes pending" shows until
then). Use *Save settings* on the MiSTer system page to keep them.

- **Monitor** is the X1 Turbo monitor DIP switch; games read it at start.
  Most software is 15 kHz: with High-res it is shown at about 24 kHz / 93 Hz,
  which many displays reject. Use High-res only for 24 kHz software (for
  example "hi-res" disks).
- **Drive A / B** are drives 0 and 1 to the machine; games often call them
  drive 1 and 2. Multi-disk games usually want both disks inserted before
  starting.
- **Tapes**: mount a TAP and the IPL boots it (it tries the floppy first, so
  keep Drive A empty). BASIC tapes need Hu-BASIC: boot it from disk, then
  `LOAD` and `RUN`.
- **Keyboard**: Caps Lock starts off. Some games and S-OS only accept upper
  case.

MGL example (mounts a tape on index 2 and resets):

```xml
<mistergamedescription>
  <rbf>_Computer/SharpX1</rbf>
  <setname>SharpX1</setname>
  <file delay="2" type="s" index="2" path="game.tap"/>
  <reset delay="1"/>
</mistergamedescription>
```

Disks use `type="s"` with index 0 (Drive A) or 1 (Drive B).

## Limitations

- No tape recording, printer, serial (RS-232C) or SASI hard disk. The
  sub-CPU clock starts at 00:00:00 at power-on (no real date).
- Turbo Z video modes are provisional and only partly checked against real
  hardware; Kanji level 2 is blank.
- 2HD disks and native floppy timing are not supported.

## Building

Quartus Prime Lite 17.0:

```sh
quartus_sh --flow compile sharpx1
```

The RBF is written to `output_files/sharpx1.rbf`. `sys/` is the unmodified
[MiSTer template](https://github.com/MiSTer-devel/Template_MiSTer) framework.

Development history, simulation (Verilator) and test notes live in
[alanswx/SharpX1_Mister](https://github.com/alanswx/SharpX1_Mister).

## Credits and licenses

- Machine core based on **Nise X1** by Tatsuyuki Satoh (X1 video, sub-CPU,
  MR16 core and firmware), with the HD6845 CRTC by Katsumi Degawa and
  Tatsuyuki Satoh.
- TV80 Z80 by Guy Hutchison; WD1793 by Viacheslav Slavinsky and Sorgelig;
  i8255 by Sorgelig; JT49 and JT51 by Jose Tejada (jotego, GPL-3.0, see
  `rtl/jt49/LICENSE` and `rtl/jt51/LICENSE`).
- MiSTer framework (`sys/`) by Sorgelig and contributors.
- MiSTer port, Turbo/Turbo Z hardware, cassette and FM integration by
  Alan Steremberg.
- Original MiSTer port setup (2022) by JasonA: project skeleton, Nise X1
  import, TV80 and MR16 sub-CPU integration and the first Verilator
  simulator.

The root [LICENSE](LICENSE) is GPL-2.0. Inherited files keep their own
notices, and some Nise X1 files carry non-commercial and redistribution
terms of their own; check each file's header before reusing it.
Sharp ROMs and software are not included.
