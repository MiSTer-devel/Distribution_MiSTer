# Hitachi Basic Master Jr. (MB-6885) for MiSTer

The Basic Master Jr. is a 1981 Japanese home computer: a 6800 CPU at 750 kHz,
32×24 text, 256×192 graphics, 5-bit sound and a 300-baud cassette. This core
also has the MP-1710 colour adapter.

The BASIC, monitor and character ROMs are built in, so you don't need any BIOS
files. Power on and you are at the BASIC prompt.

**Working:** BASIC and the monitor, keyboard (JIS or US layout), gamepad
(as keys; the machine had no joystick port),
sound, timer and BREAK interrupts, the graphics modes, MP-1710 colour and
border, and tape loading and saving.
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
| Keyboard layout | **JIS**, US | JIS: keys by position. US: keys type their legend (see below) |
| Swap Alt/Win keys | **No**, Yes | Moves カナ記号 from Alt to Win |
| Gamepad to keys | **On**, Off | Gamepad buttons type keys (see below). Off ignores the gamepad |
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
* **Changing tapes:** mounting a tape doesn't reset the machine, as swapping
  a cassette wouldn't. What you typed or loaded before stays, so `CALL $E37E`
  can come before the mount, and a program can load from more than one tape.

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
# NAME  LOAD  START  [END]  [| NOTE  [| PAD MAP]]
CAR     2000  2500          | S GO NM STEER CTRL GAS  | START=S LEFT=N RIGHT=M A=CTRL
GORILA  -     -             | S START                 | START=S
```

* `NAME` is the name in the tape header, as `L` or `LOAD` prints it.
* `LOAD` is the address of the first block, or `-` to match any address.
* `START` is the address for `G`, or `-` to keep the load address.
* `END` is optional: the last address the file loads, to match one
  version only.
* The note can be up to 22 characters, upper case.
* The pad map is optional (see [Gamepad](#gamepad)). For a map without a
  note, leave the note empty: `NAME - - | | A=Z`.

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

**Keyboard layout** in the OSD picks how PC keys map to the machine's keys.

* **JIS** (default): by position, as on a Japanese keyboard, which is also
  the machine's own layout: `@` `[` `]` `^` `¥` and `ろ` (`_` with Shift)
  are where a JIS keyboard has them. Type in lower case (Shift+letter isn't
  a capital). On a US keyboard the punctuation is in the wrong places and
  `¥` and `_` are missing, so use US.
* **US**: each key types what is printed on it. Shift+2 is `@`, `'` is `'`,
  Shift+letter is the same letter (the machine only has capitals), `\` is
  `¥`. `` ` `` `~` `{` `}` `|` have no key on the machine and type nothing.

In both layouts the arrows move the cursor (on the machine they are Shift
with `@` `[` `^` `¥`) and the keypad types digits.

| PC | Basic Master Jr. (both layouts) |
|---|---|
| Caps Lock (hold) | カナ |
| Alt (hold) | カナ記号 (Win with Swap Alt/Win) |
| Left Ctrl | 英数 |
| Esc | BREAK |

The ROM and most games scan the keyboard slowly, so hold keys a moment
instead of tapping them.

## Gamepad

The real machine had no joystick port, so gamepad buttons type keys. OSD
*Gamepad to keys* turns this off. By default the d-pad is the cursor keys, A is
Space and B is Return. If the tape list's line for the mounted program has a
pad map, its buttons type what it says instead:

```
UP=I DOWN=M LEFT=J RIGHT=K A=Z START=S
```

* Buttons: `UP` `DOWN` `LEFT` `RIGHT` `A` `B` `X` `Y` `L` `R` `SELECT`
  `START`. A button the map doesn't name keeps its default.
* Keys: a single character, as typed on the JIS layout (`!` to `?` add
  Shift), or `SPACE` `RETURN` `BS` `UP` `DOWN` `LEFT` `RIGHT` `CTRL` `SHIFT`
  `ALT` `CAPS` `ESC` `NONE`, named as on the PC keyboard (`CTRL` is 英数,
  `ALT` カナ記号, `CAPS` カナ, `ESC` BREAK). `UP` `DOWN` `LEFT` `RIGHT` move
  the cursor (Shift with `@` `[` `^` `¥`). `NONE` turns a button off.

The map is for the program the start hint is about, so it applies from the
time the tape is mounted. The supplied list maps every game we have: the
inufuto games, zu2's programs and the magazine type-ins. In it, START is
the key that starts a game and SELECT the one that answers Y to play again.
The keys were taken from each program's own code (its `INKEY$` tests, or the
keyboard reads in its machine code), not just from the instructions.

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
