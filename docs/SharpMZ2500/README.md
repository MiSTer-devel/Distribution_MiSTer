# Sharp MZ-2500 / MZ-2520 for MiSTer

A MiSTer FPGA core for the Sharp MZ-2500 ("Super MZ", 1985) and the budget MZ-2520: Z80B at 6 MHz, 128-256 KB RAM, a text
+ graphics video controller with 640 x 400 and 320 x 200 modes and up to 256 colours, YM2203 sound, 3.5" 2DD floppies,
kanji ROM, and an MZ-80B / MZ-2000 compatible mode.

Sister project of [SharpMZ_MiSTer](https://github.com/alanswx/SharpMZ_MiSTer) (MZ-80K to MZ-2000), with which it
shares the floppy and tape RTL.

## Getting started

1. **Core**: copy the newest `releases/SharpMZ2500_<date>.rbf` to `/media/fat/_Computer/` (what changed:
   [RELEASES.md](RELEASES.md)).
2. **ROMs**: the core needs your own dumps in one file, `/media/fat/games/SharpMZ2500/boot.rom` (Sharp's copyright;
   not included). It is loaded when the core starts. Names and CRCs are those of MAME's `mz2500` set:

   | File | Size | CRC32 | Needed for |
   |---|---|---|---|
   | `ipl.rom` | 32 KB | 7a659f20 | everything |
   | `kanji.rom` | 256 KB | dd426767 | everything (all text fonts are in it) |
   | `ipl2520.rom` (mz2520 set) | 32 KB | 0a126eb2 | the MZ-2520 model only |
   | `dict.rom` | 256 KB | aa957c2b | optional: dictionary (Japanese input) |
   | `phone.rom` | 16 KB | 8e49e4dc | optional: MZ-1E26 phone unit |
   | `kanji2.rom` | 128 KB | eaaf20c9 | optional: MZ-1R13 kanji board |

   Build it with `tools/make_bootrom.sh ipl.rom kanji.rom boot.rom [ipl2520.rom [dict.rom [phone.rom [kanji2.rom]]]]`
   (checks the CRCs; leave out or pass `''` for ones you don't have). The short version (IPL and kanji only, 320 KB)
   can be made by hand: `cat ipl.rom ipl.rom kanji.rom > boot.rom` (Windows: `copy /b ipl.rom + ipl.rom + kanji.rom
   boot.rom`; the second 32 KB is the MZ-2520 IPL slot). Missing optional ROMs read FFh, as in the emulators.
3. **Disks** (`.d88`): Drive 1 and Drive 2 in the OSD, then reset (OSD Reset). The IPL boots drive 1. Writes go back
   to the image. Games that ask for a user or data disk (Ys III, Moon Child, ...) want one in the other drive: make a
   blank formatted one with `tools/blank_d88.py user.d88`. MAME's `.dsk` and `.mfi` images: convert with
   `tools/dsk2d88.py` / `tools/mfm2d88.py`.
4. **Tapes** (`.mzt`, MZ-2000 / MZ-80B software): set Boot mode to MZ-2000 or MZ-80B, Load tape, reset, press C at
   the IPL menu. Tapes play at real speed (BASIC takes a few minutes). WAV recordings: `tools/wav2mzt.py`.
5. **RAM images** (MAME `mz2000_snap` `.bin`): Load RAM image starts them at once in MZ-2000 mode, whatever the Boot
   mode; a reset goes back to the IPL.
6. **Launchers**: `tools/make_mgls.py OUTDIR GAMESDIR` writes an MGL per disk (both drives for `X_Program.d88` +
   `X_User.d88` pairs), tape and RAM image, for `_Computer/_SharpMZ2500/`.

The tools need Python 3 (`make_bootrom.sh`: a POSIX shell and Python 3); the usage is in the comment at the top of
each file.

### OSD

| Item | |
|---|---|
| Drive 1, Drive 2 | D88 images |
| Load tape / Load RAM image | MZT tape for the data recorder / mz2000_snap image, run at once |
| Lines (reset) | 400 (24 kHz monitor, the default) or 200 (15 kHz): the machine's front switch. Takes effect at the next Reset, since games read it when they start |
| Boot mode | MZ-2500, MZ-2000 or MZ-80B: the mode switch, read at reset |
| Keyboard | Japanese (positional: a Japanese MZ keyboard on PC keys, as in the emulators) or US (the symbols printed on a US keyboard) |
| Model | MZ-2500 or MZ-2520 (its IPL boots only from floppy), at reset |
| Scandoubler Fx, Aspect ratio | the usual MiSTer options |

### Keys

F11 = HELP, Print Screen = COPY (F12 is the MiSTer menu), End or Pause = BREAK, Home = CLR/HOME, Insert/Delete =
INST/DEL, Alt = GRAPH, Caps Lock = LOCK, the keypad = the ten-key (many games move menus with ten-key 2/4/6/8, not
the cursor keys). The mouse (PS/2 through the Z80 SIO) and joystick 1 (two triggers) work.

## Compatibility

Tested on a MiSTer (DE10-Nano with SDRAM) against the BubiZ-2500 emulator (Takeda's EmuZ-2500 core), with MAME as a
second opinion, on the MAME software lists:

- **MZ-2500 disks**: all 62 MAME 0.228 + 0.289 `mz2500_flop` titles that boot in the emulator boot and match it,
  including the copy-protected Laydock, Macadam, Märchen Veil and Mugen II. Play-tested into the game: Arion, Back to
  the Future, Balloon Fight, Black Onyx, Druaga, Eiyuu Densetsu, Excite Bike, Fire Crystal, Galaga, Harley Fox, Hover
  Attack, King Flappy, Lizard, Mappy, Märchen Veil, Marvelous, Moon Child, Nobo, Penguin-kun Wars, Re-Birth, Relics,
  Sangokushi, Nobunaga no Yabou, Triton, Xevious, Ys III (with saving) and more; the Hoshikuzu-bako / Dust Box disk
  magazine (all issues).
- **MZ-2000 / MZ-2200 tapes**: all MAME `mz2000_cass` / `mz2200_cass` tapes load, except Jelda and Jelda 2 (bad dumps).
  `mz2000_snap`: all 14 images run. `mz2000_flop`: the C-DOS disks boot.
- **MZ-80B**: SB-5510/5520 BASIC, Disk BASIC SB-6510/6610/6511 and Vosque from tape, the games disk.
- Same as in the emulators: F-2 Grand Prix (bad dump: Disk Error), SP-5025 BASIC (never finishes loading), Brave
  (blank after RETURN), Sound Gal (asks for its master disk), Laydock (menus and saved players work, then it waits at
  "SCENE 01").

Not supported yet: tape recording (SAVE to tape), drives 3-4, RS-232C, the printer, the SASI hard disk and memory
expansions. Mugen II's user disk hasn't been made to work (no way found to create one, also in the emulator).

## What is in the core

Z80 (T80 v350) with the original wait states; the MMU and its reset maps; 256 KB main RAM and the ROMs in SDRAM (the
text raster fetches kanji glyphs two cells ahead); text CRTC and graphics controller (16- and 256-colour modes, RMW
window, clear, scroll, palette and priority, the 4096-colour board, 64-colour text); the interrupt block, 8253, 8255,
Z80 PIO and keyboard; the MB8876 floppy controller with D88 drives and the reference emulator's rotation timing; the
YM2203 (jotego jt03) and the beeper; the RP5C15 clock (from MiSTer's RTC); joysticks; a minimal Z80 SIO with the
mouse; the data recorder (MZT, MZ-2500 and MZ-80B/2000 formats, APSS); the MZ-2000 / MZ-80B compatibility mode; the
RAM-image loader. The core prints a machine snapshot every 0.1 s on its UART (`cat /dev/ttyS1` at 115200 on the
MiSTer), for debugging.

| Path | Content |
|---|---|
| `SharpMZ2500.sv` | MiSTer `emu` top: OSD, hps_io, PLL, video mixer |
| `SharpMZ2500.qsf`, `.qpf`, `.sdc`, `.srf` | Template_MiSTer's `Template.*` files, unmodified (`.qpf`: only the revision name) |
| `files.qip` | The core's source list |
| `rtl/mz2500.sv` | The machine: CPU, waits, MMU, memories, I/O decode, small devices |
| `rtl/mz2500_video.sv` | Raster, text CRTC, graphics controller, VRAMs, mixer |
| `rtl/mz2500_int.sv`, `mz_pit8253.sv`, `mz2500_kbd.sv`, `mz2500_sio.sv`, `rp5c15.sv` | Interrupt block, 8253, keyboard matrix, SIO (mouse), clock |
| `rtl/mz2500_fdc.sv`, `rtl/wd1793.sv`, `rtl/wd1793_mem.v` | Floppy: MB8876 wrapper, Sorgelig's WD1793 with FM-7_MiSTer's D77/D88 support |
| `rtl/mz2500_cmt.sv`, `rtl/mz2500_snapboot.sv` | Data recorder, RAM-image boot stub |
| `rtl/T80_v350` | Z80: Sorgelig's MiSTer T80 v350 |
| `rtl/jt12/` | jotego jt12/jt49 (YM2203 = jt03), GPL-3 |
| `rtl/sdram.sv` | Sorgelig's SDRAM controller, refresh set for 85.9 MHz |
| `rtl/pll*` | 50 MHz to 85.909091 MHz |
| `sys/` | Template_MiSTer framework (not edited) |
| `tools/` | `boot.rom` builder, blank user disks, image converters, MGL launchers |

## Building

Quartus 17.0 Lite, as for all MiSTer cores:

```
quartus_sh --flow compile SharpMZ2500        # -> output_files/SharpMZ2500.rbf
```

`build_id.v` is generated by `sys/build_id.tcl` (pre-flow script) and is not committed. Quartus writes the
assignments from `sys/*.tcl` into the `.qsf` during a build; don't commit that (`git checkout SharpMZ2500.qsf`). The
`.qsf`, `.sdc`, `.srf` and `sys/` are Template_MiSTer master as of commit e901a9f (2026-11-03), byte for byte: update
them from the template rather than editing them.

Release build 20261104: 20,334 ALMs (49 %), 2.35 Mbit block RAM (42 %), timing met with the default seed (clk_sys
85.90909 MHz).

## Licence

GPL-3.0-or-later (see `LICENSE`). Third-party RTL keeps its own licence (T80: BSD-style; jt12/jt49: GPL-3, see
`rtl/jt12/LICENSE-*`; `sys/`: GPL; see the file headers). MAME and EmuZ-2500 were used as behavioural references only.
