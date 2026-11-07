# Hitachi Basic Master Level 3 / MB-S1 for MiSTer

A MiSTer core for the **Hitachi Basic Master Level 3** family (MB-6890 Level 3, MB-6891
Mark II, MB-6892 Mark 5) and the **Hitachi MB-S1**, in one core. The OSD "Model" option
picks Mark 5, Level 3 or MB-S1.

* MC6809 at 1.008 MHz (2 MHz on the MB-S1), HD46505 CRTC, 32.256 MHz master clock.
* 40/80-column text with a colour RAM, 320×200 and 640×200 graphics, Mark 5 IG
  (programmable characters).
* MB-S1 in S1 mode (S1 BASIC, memory mapper, S1 display with palette, 64-colour and 640×400
  modes, built-in PSG) and in Level 3 mode (the S1 SYSTEM switch).
* Cassette: `.l3` images streamed from the SD card, at real speed or 16x, with an on-screen
  tape counter.
* MP-1802 5" floppy card (`.d88` disks, two drives).
* 6-voice PSG card (two AY-3-8910), with a joystick on PSG 0.

## Installation

1. Copy the RBF to `_Computer/` on the SD card.
2. Make `boot0.rom` (below) and put it in `games/BasicMasterL3/`.
3. Put tapes (`.l3`) and disks (`.d88`) anywhere under `games/BasicMasterL3/`.

### boot0.rom

ROMs are not included. `tools/make_boot0.py` builds `boot0.rom` from the MAME ROM sets
**bml3**, **mbs1** and **bml3mp1802** (and optionally **bml3mp1805**). It accepts merged
or non-merged zips, or directories, and finds each ROM by CRC:

```
python3 tools/make_boot0.py bml3.zip mbs1.zip bml3mp1802.zip bml3mp1805.zip
```

With all four sets the result is 163840 bytes, SHA-1
`49fbfae9f4f459bb79d01d6063df0f8f799f63d0`. The layout is described at the top of the
script. A different `boot0.rom` can be loaded for one session with "Load ROM".

## Using it

BASIC comes up a second or two after reset.

* **Tapes:** mount a `.l3` image as "Tape", then type `LOADM"",,R` for machine code or
  `LOAD` and then `RUN` for BASIC programs. The wrong one gives "Bad file mode". The
  machine's motor relay starts and stops the tape. "Tape speed" is 16x by default, and
  "Tape overlay" shows the time and a progress bar while the tape runs. Tapes in the
  `.l3b`/`.l3c` formats used by some emulators need converting to `.l3` (one byte per
  serial frame).
* **Disks:** mount a `.d88` as "Pri. disk 0", then choose "Apply and reset". With "Floppy
  card" on Auto, the MP-1802 card is fitted only when disk 0 has an image, so the machine
  boots DISK BASIC from it. An MB-S1 in S1 mode with the card fitted and no disk waits at
  "Insert Program Diskette", as the real machine does.
* **MB-S1:** set Model to MB-S1. S1 SYSTEM A boots S1 BASIC; B boots Level 3 BASIC.
  640×400 mode needs Interlace set to On to show all 400 lines.

### OSD

The menu follows the MiSTer computer-core OSD standard: settings that change the machine
take effect at "Apply and reset", and the menu shows "Changes pending" until then. Disks
are remembered across core loads; the tape is not.

| Menu | Options |
|---|---|
| Top | Pri. disk 0, Disk 1, Tape, Load ROM, Memory (64K / 32K stock) |
| Machine | Model, S1 SYSTEM, Floppy card (Auto / MP-1802 / None), PSG card, Tape speed, Rewind tape |
| Video | Interlace (Even field / On), Border, Scandoubler Fx, Aspect ratio, Tape overlay |
| Input | Keyboard (US symbols / JIS layout) |

### Keyboard

"US symbols" lets you type the symbols printed on a PC keyboard; "JIS layout" maps keys by
position. Keys with no PC equivalent:

| PC key | Machine key |
|---|---|
| Tab | KANA (MB-S1: TAB) |
| F7 or Caps Lock | CAPS |
| F8 | GRAPH |
| F9 | BREAK |
| F1-F5 | PF1-PF5 |
| Home | HOME / CLS |
| Backspace | INS / DEL |
| End | keypad `?` |
| MB-S1 only: Insert, Delete, F6, F10, right Alt | INS, DEL, convert (変換), COPY, KANA |

Typing is paced at about 9 characters per second so the ROM sees every key.

## Not implemented

* Cassette SAVE.
* MP-1805 3" floppy card, 9-voice PSG, kanji ROM card.
* MB-S1 user mode (only used by OS-9 style software).

## Development

`vsim/` is a Verilator simulator of the core, with a headless mode for scripted tests (see
`vsim/README.md`). Development happens at <https://github.com/alanswx/BasicMasterL3_MiSTer>,
which also has the hardware notes and the research behind the core.

Behaviour follows Sasaji's EmuB-6892 and EmuB-S1 emulators. The 6809 is the
Vectrex-development `mc6809is`, the floppy controller is `wd1793.sv` from the FM-7 core, and
the PSG is jotego's `jt49`.

Licence: GPL v2 (see `LICENSE`; `rtl/jt49` has its own licence file).
