# Hitachi Basic Master Jr. (MB-6885) for MiSTer

The Basic Master Jr. is a 1981 Japanese home computer: a 6800 CPU at 750 kHz,
32×24 text, 256×192 graphics, 5-bit sound and a 300-baud cassette. This core
also has the MP-1710 colour adapter.

The BASIC, monitor and character ROMs are built in, so you don't need any BIOS
files. Power on and you are at the BASIC prompt.

**Working:** BASIC and the monitor, keyboard, sound, timer and BREAK
interrupts, the graphics modes, MP-1710 colour and border, and tape loading
and saving.
**Not implemented:** printer, expansion cards (MP-9730, MP-1803 floppy).

## Installation

The MiSTer updater installs the core and the tape list. To install by hand:

* Copy `releases/BasicMasterJr_*.rbf` to `/media/fat/_Computer/`.
* Copy `releases/boot1.rom` (the tape list, below) to
  `/media/fat/games/BasicMasterJr/`.
* Put tape images in `/media/fat/games/BasicMasterJr/`.

## OSD

| Option | Values | |
|---|---|---|
| Tape | `.bin` `.bmt` `.sav` | Mount a tape. Mounting rewinds it. |
| Tape speed | **32x**, Normal | 32x speeds up the CPU and the tape together while the motor runs |
| Rewind tape | | |
| New tape recording | | Clear the tape and start recording (see below) |
| Scandoubler Fx | None, HQ2x, CRT 25/50/75% | |
| Aspect ratio | Original, Full Screen, ARC1, ARC2 | |
| Tape overlay | **On**, Off | Tape status and a what-to-type hint |
| Swap Alt/Win keys | **No**, Yes | Moves カナ記号 from Alt to Win |
| Reset and close OSD | | |

## Loading tapes

A mounted tape doesn't load by itself. You type the load command, as on the
real machine, and the core shows what to type in the bottom-left corner,
read from the tape's headers:

```
TYPE MON ↵ L MAZY ␣         before loading a machine-code program
TYPE G 1000 ␣               once it has loaded
TYPE LOAD GORILA ↵          a BASIC program; then RUN ↵
```

* **Machine code:** `MON` Return, then `L NAME` **Space**, then
  `G addr` **Space**. The monitor ends commands with Space, not Return.
  Most programs start at `2200`, MAZY at `1000`.
* **BASIC:** `LOAD NAME` Return, then `RUN` Return.
* **Graphics programs:** BASIC programs that draw graphics need
  `CALL $E37E` before `LOAD`. It moves the program out of the graphics
  memory. Going back from the monitor to BASIC (`E` Return) undoes it,
  so type it after `E`. The hint shows this when it applies.

While the tape plays, the corner shows elapsed time, total time and a progress
bar. At 32x a 15 KB game loads in about 10 seconds. Normal is the real
300 baud, about 10 minutes for the same game.

Tape images are the demodulated byte stream the CPU reads from `$EE80`
(`.bmt`, or the same bytes as `.bin`), up to 64 KiB. They are not audio.
maruhiro's [bmtape2](https://ver0.sakura.ne.jp/pc/#bm2) converts WAV
recordings to this format and back.

Software: [inufuto](http://inufuto.web.fc2.com/8bit/)'s games (take the `bm`
build's `.s.bin`), [zu2](https://github.com/zu2/BASICMASTER)'s programs (their
`.cmt` files load as-is) and magazine type-ins.

### Tape list

The tape format doesn't record where a program starts, so the hint assumes
it starts where it loads. That's right for almost everything. If the first
byte there isn't a usual opening instruction, the hint says
`G ????` / `START ADDR UNKNOWN` instead of guessing.

`boot1.rom` is a plain-text list that corrects the start address and adds a
note under the start hint. MiSTer loads it when the core starts. One line
per program, and `#` starts a comment:

```
# NAME  LOAD  START  [END]  [| NOTE]
CAR     2000  2500          | S GO NM STEER CTRL GAS
GORILA  -     -             | S START
```

* `NAME` is the name in the tape header, as `L` or `LOAD` prints it.
* `LOAD` is the address of the first block, or `-` to match any address.
* `START` is the address for `G`, or `-` to keep the load address.
* `END` is optional: the last address the file loads, to match one
  version only.
* The note can be up to 22 characters, upper case.

For a tape with machine code followed by BASIC, the line is for the BASIC
program. The file's own comments explain the format, so you can add your
own tapes to it.

## Saving tapes

1. Put an empty file such as `mytape.bmt` in `games/BasicMasterJr/` and
   mount it. MiSTer creates `/media/fat/saves/BasicMasterJr/<name>.sav`.
2. Choose **New tape recording**.
3. `SAVE NAME` in BASIC. Wait for the tape to stop before you reset.

The `.sav` is a normal tape image. Mount it to load the program back. Use a new
name for each recording, because a shorter recording doesn't shrink an existing `.sav`.

## Keyboard

| PC | Basic Master Jr. |
|---|---|
| Letters, digits, punctuation | JIS layout. Type in lower case (Shift+letter isn't a capital) |
| ↑ ↓ → | `@` `[` `^` (cursor keys) |
| ← / ¥ | `¥` (left) |
| Caps Lock (hold) | カナ |
| Alt (hold) | カナ記号 (Win with Swap Alt/Win) |
| Left Ctrl | 英数 |
| Esc | BREAK |

The ROM and most games scan the keyboard slowly, so hold keys a moment
instead of tapping them.

## Building

Quartus 17.0.x: `quartus_sh --flow compile BasicMasterJr`.

`vsim/` has a Verilator simulation with screenshots, key injection, tracing and
a regression script. Run it from `vsim/`:

```bash
cd vsim && make && ./obj_dir/Vemu --help
./regression.sh         # screenshot checks; also tape-load checks if vsim/tapes/ has mazy.s.bin and ascend.s.bin
cd cputest && make && ./obj_dir/Vcputb --pad   # 6800 cycle timing vs MAME
```

The CPU is a 6801 core padded to 6800 cycle timing (`rtl/m6800_pad.v`).
Cassette loading depends on this, because the monitor times tape bits with
delay loops.

## Credits

* Original core by [pcornier](https://github.com/pcornier/BasicMasterJr_MiSTer)
* CPU derived from John Kent's 6800/6801 core
* maruhiro's `bm2` emulator and `bmtape2`, the reference for the tape format and I/O
* MB-6885 schematics published by [旧コン研](http://kyucom.sblo.jp/article/190792009.html)
* Takeda's [Common Source Code Project](https://takeda-toshiya.my.coocan.jp/), used as a reference emulator
* Test software by inufuto and zu2
