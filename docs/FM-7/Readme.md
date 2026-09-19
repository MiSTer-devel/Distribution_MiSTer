# Fujitsu FM-7 for MiSTer

The **FM-7** (1982) was Fujitsu's big seller in Japan — a two-CPU machine with
an MC6809 running F-BASIC and a *second* MC6809 that does nothing but drive the
display and the keyboard. It ran one of the strongest Japanese games libraries
of the early 80s, and almost none of it ever left Japan.

This core also runs the **FM77AV**, the 1985 successor with 4096 colours, a
hardware drawing engine and a YM2203.

![FM-7 keyboard map](docs/keyboard.svg)

## What works

* **F-BASIC** from ROM, and disk BASIC from a `.d77` / `.d88` floppy
* **Games** — the whole FM-7 disk collection has been checked against a
  reference emulator, 395 of 395 images
* **OS-9 Level 1** boots to its shell (Boot ROM bank 2)
* **Cassettes** — `.t77` tape images load and run
* **Two floppy drives**, and multi-disk container images
* **FM77AV mode** — 320×200 in 4096 colours, the drawing ALU, the analog
  palette, and the keyboard encoder including its make/break scan mode
* **Sound** — PSG on the FM-7, YM2203 FM on the AV
* **Joysticks**, two ports, two buttons each
* **Kanji ROM**, the full 128 KB JIS set
* **Spanish Secoinsa FM-7**, selectable at run time

## Installing

**Use the MiSTer updater and there is nothing to do** — it puts the core and
both ROM files where they belong. Then drop your `.d77`, `.d88` and `.t77`
files into `/media/fat/games/FM-7/`.

Installing by hand instead:

| copy this | to here |
|---|---|
| `releases/FM-7_<date>.rbf` | `/media/fat/_Computer/FM-7.rbf` |
| `releases/boot.rom` | `/media/fat/games/FM-7/boot.rom` |
| `releases/boot1.rom` | `/media/fat/games/FM-7/boot1.rom` *(optional)* |

> **If you place the files yourself, the ROMs go in `games/FM-7/`, not beside
> the `.rbf`.** MiSTer only looks in the core's games folder. A `boot.rom`
> sitting next to the core is silently ignored — no error, and anything that
> draws kanji shows garbage. If you have an older hand-made install, this is
> worth checking.

`boot.rom` is the 128 KB kanji ROM. `boot1.rom` holds the system ROM sets and
is only needed for the Spanish machine — see [System ROM sets](#spanish-secoinsa-fm-7).

## Getting started

Load the core with no disk and you get F-BASIC. Type `print 1+1`, press Enter.

Quotes are **Shift+2** on this keyboard, not Shift+`'` — every command below
needs them, so glance at [Keyboard](#keyboard) before typing your first one.

### A disk

1. **F12** for the OSD, then **Mount Disk 1** — that is the machine's drive 0.
2. Pick a `.d77` or `.d88`.
3. **Reset**.

Mounting alone does not reboot, deliberately: a game that asks you to swap
disks mid-play would restart otherwise. Most disks boot by themselves once you
reset. If one stops at a `Ready` prompt instead, look at what is on it and
start the program yourself:

```
FILES"0:"             list drive 0
RUN"NAME"             start a BASIC program
LOADM"NAME",,R        load and run a machine-code program
```

`FILES"1:"` lists drive 1, which the OSD calls **Mount Disk 2**. Each entry in
the listing carries its type: `B` is a BASIC program, `A` a BASIC program saved
as plain text, `M` machine code, `D` data. `B` and `A` want `RUN"NAME"`, `M`
wants `LOADM"NAME",,R`, and `D` is not something you load yourself.

A disk that does nothing at all usually wants a different **Boot ROM** —
try **2 dos-a**, which is the one OS-9 disks need.

### A disk that is really several disks

Some `.d77` and `.d88` files are **containers**: two to six complete disks in
one file, which is how many multi-disk games were dumped. Mount one the usual
way and the drive presents the first disk inside it.

When the game asks for the next disk, open the OSD and set **Disk 1 image** to
`2`, `3`, and so on. That re-scans the drive, which is exactly what swapping a
disk does — so do *not* reset afterwards, or you will restart the game.
**Disk 2 image** does the same for the second drive, and the two selectors are
independent. On an ordinary single-disk file the selector does nothing: only
`1` is there.

One limit worth knowing before you go hunting for a fault: only the disks lying
in the **first 1 MB** of the file can be reached. Past that the selector clamps
to the last one it can get to, so the later disks of a large container are out
of reach for now.

### A tape

1. **Load Tape** in the OSD, and pick a `.t77`.
2. Type `run""` and press Enter.
3. Wait: `Searching`, then `Found: NAME`, then the program starts.

Tapes load at the speed cassettes really ran — a couple of minutes for a small
title, closer to six for a big one. **Tape Audio** lets you hear it working,
and **Tape Rewind** puts you back at the start, which you need before loading
anything a second time.

Some tapes hold a machine-code program rather than a BASIC one; those want

```
LOADM"",,R
```

instead of `run""`. Dumps often say which in the file name — Gaming
Alexandria's, for instance, end in `-loadm`.

**Right Ctrl is BREAK**, which stops a running BASIC program.

## The OSD

| option | what it does |
|---|---|
| **Load Tape** | mount a `.t77` cassette image |
| **Mount Disk 1 / 2** | mount a floppy in drive 0 / drive 1 |
| **Disk 1 / 2 image** | pick which disk inside a multi-disk container file |
| **Tape Rewind** | rewind the cassette to the start |
| **Tape Audio** | hear the tape while it loads |
| **Boot ROM** | `0 disk` boots floppies, `2 dos-a` boots OS-9 |
| **Machine** | FM-7, or FM77AV |
| **System ROM** | Japanese or Spanish system ROMs — see below |
| **Aspect ratio** | original 4:3, or fill the screen |

## Keyboard

The FM-7's keyboard is **JIS**, and this core keeps the real machine's key
*positions*. That means some keys type a different character than your PC key
cap says — most of the shifted punctuation, and the brackets.

The [keyboard map](docs/keyboard.svg) above shows all of it. The ones people
hit first:

| you press | you get |
|---|---|
| `Shift`+`2` | `"` (not `@`) |
| `Shift`+`7` `8` `9` | `'` `(` `)` |
| `[` | `@` |
| `]` | `[` |
| `'` | `:` |
| `Shift`+`;` | `+` |

And the special keys:

| PC key | FM-7 key |
|---|---|
| **Left Alt** | **GRAPH** — the semigraphics character set |
| **Right Alt** | **KANA** — locking toggle for katakana |
| **Right Ctrl** | **BREAK** — stops a running BASIC program |
| Page Up / Page Down | EL (erase line) / CLS |
| F1–F10 | PF1–PF10 |

Caps Lock does nothing. The numeric keypad types the same characters as the
main keys, and keypad Enter is RETURN — which matters for games that steer on
keypad 8/4/6/2, such as Dig Dug. The FM-7 keyboard never reports a key being
released, so in games like that a tap sets the direction and the character keeps
going until you press another key.

On the FM77AV, a title can switch the keyboard encoder into **scan-code mode**
and then see key *releases* and the modifier keys themselves, which the FM-7's
own code system cannot express at all. The encoder and that mode are
implemented, which is what AV titles written around make/break scancodes need.

Held keys repeat the way the FM-7's own keyboard does: the first repeat after
0.7 s, then every 0.07 s. Function keys don't repeat, and pressing or releasing
Shift stops a repeat. **Left Ctrl + Shift + 0** turns key repeat off and
**Left Ctrl + Shift + 1** turns it back on.

## Joysticks

Two ports, mapped to MiSTer players 1 and 2, with **Button A** and **Button B**.
Plenty of FM-7 games are keyboard-only — of 301 disk images, only 25 ever read
the joystick ports at all, so if a game ignores your pad it is probably the game.

## Spanish Secoinsa FM-7

Secoinsa built and sold the FM-7 in Spain under licence, with a Latin character
set in place of katakana and a slightly different F-BASIC. Install `boot1.rom`
and set **System ROM** to **Spanish** to run it — `Ñ`, `Ç` and `¿` appear where
katakana would be.

You can build your own ROM sets for other variants; the file format is in
[docs/ROMSETS.md](docs/ROMSETS.md).

## Known limitations

* **2DD floppies are not supported** — 2D only
* Multi-disk containers can only reach disks in the **first 1 MB** of the file;
  beyond that the selector clamps to the last reachable disk
* **The FM77AV side is younger than the FM-7 side.** 68 AV titles have been
  swept against a reference emulator — 30 match it and the rest are blank on the
  reference too — against 395 disks checked on the FM-7 side. That sweep samples
  a few frames per title, so it catches a title that never draws; it does not
  catch one that plays its intro and then stops. That is how Silpheed's encoder
  fault (fixed here) went unnoticed for so long — expect more of that shape
* **Two-disk FM77AV titles need BOTH disks mounted.** Silpheed with only its
  first disk sits on the GameArts logo forever — that is the game, not the core
* **Some titles start on the joystick only.** Space Harrier draws `LOADING NOW`
  for about twenty seconds, then a `START / CONTINUE / JOYSTICK NORMAL` menu
  that answers a **pad button** — no key on the keyboard starts it. If a title
  looks stuck on a menu, try the pad before reporting it
* One tape, **Crash Ball**, reports `Device I/O Error` after finding its header
* **Xanadu Scenario II disk D** does not load
* PSG pitch is about **0.4 of a semitone flat**, from an integer clock divider
* The FM77AV's FM sound **pitch** has not been verified against a reference.
  Its **timers** have: a title driving its music off the YM2203 Timer B
  interrupt ticks at 621 Hz here against 640 Hz on the real chip — the same
  2.3 % the PSG is flat by, and nothing more

## Thanks

Based on [pcornier](https://github.com/pcornier)'s original FM-7 core.
Sound uses [jotego](https://github.com/jotego)'s jt12/jt49. Verified against
Takeda Toshiya's common source project, CaptainYS's 77AVEMU, and MAME.

## Licence

GPLv3 — see [LICENSE](LICENSE) and [LICENSE-NOTICE.md](LICENSE-NOTICE.md).
ROM images are not GPL and belong to their respective owners.

---

*Working on the core itself? [verilator/](verilator/) builds a headless
simulator that boots the same ROMs — see its README.*
