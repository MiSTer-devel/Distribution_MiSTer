# [Colecovision](https://en.wikipedia.org/wiki/ColecoVision) and [Sega SG-1000](https://en.wikipedia.org/wiki/SG-1000) for [MiSTer Platform](https://github.com/MiSTer-devel/Main_MiSTer/wiki)

### Installation
* Copy the *.rbf file to the root of the system SD card.
* Place ROMs into Coleco folder

### Supported Filetypes
 * .col/.bin/.rom files for Coleco system
 * .sg files for SG-1000 system

### Save states (8 slots)

You can freeze the game exactly where it is and pick it up later, at eight
different points. It works for SG-1000 games as well as ColecoVision ones.

**Setting it up, once per game:**

1. Put an empty state file in your `Coleco` folder, named after the game - for
   example `Zaxxon.sst`. It is simply **512 KB of nothing**: the eight slots sit
   side by side inside it, so it has to be that size from the start because the
   last slot lives at the end of it. Any of these makes one:

   * on the MiSTer itself, from a terminal or over SSH:
     `dd if=/dev/zero of=/media/fat/games/Coleco/Zaxxon.sst bs=1K count=512`
   * on Windows: `fsutil file createnew Zaxxon.sst 524288`
   * on Linux or macOS: `truncate -s 512K Zaxxon.sst`

   `Coleco_savestates.sst` in this repository is exactly that file, ready to
   copy and rename if you would rather not use a command line.

   **Use one file per game**, and you get **eight slots for that game**. A
   state does not contain the cartridge, only the machine, so a file is only
   useful with the game its states were taken on - and one file each is what
   keeps all eight slots available to every game.
2. Start the game, open the OSD and choose **Savestate file**, then pick that
   `.sst`. It stays mounted until you pick another one. A brand new file is all
   empty slots, and an empty slot simply refuses to load.

**From the keyboard - one key per slot, no menu needed:**

| | |
|---|---|
| **F1 ... F8** | load the state from slot 1 ... 8 |
| **Shift+F1 ... Shift+F8** | save the state into slot 1 ... 8 |

The function key carries the slot number, so all eight states are one key press
away each.

> **Shift, not Alt.** The MiSTer firmware keeps `Alt+Fn` and `Ctrl+Fn` for
> itself and hands the core the bare function key, so those two combinations
> arrive as an ordinary load. This was measured on the hardware, not guessed.

**From a pad, all eight slots too.** Map **Savestates** - the last entry in the
controller mapping list - to a spare button, then hold it down:

| | |
|---|---|
| **LEFT / RIGHT** | pick the slot, 1 to 8 |
| **DOWN** | save into it |
| **UP** | load from it |

While that button is held the console sees nothing at all from that pad, so you
cannot nudge the game while picking a slot. Hold it on its own for a moment and
the controls are spelled out on screen.

**You are told what happened.** Every save, load and slot change prints a line
on screen - *Saved to slot 3*, *Loaded slot 3*, *Slot 4* - so eight slots do not
have to be kept in your head. The **Savestate slot** entry in the menu follows
along, and setting it there works too.

Nothing fires while the OSD is open, so browsing the menu cannot save or load by
accident.

The picture holds still for a moment while the state is written or read, and the
user LED lights up - that is the machine standing still, not a crash.

**Things worth knowing:**

* Each slot carries a signature of the cartridge it was taken on, and the
  system it was running as. Load a state from a different game and it is
  refused after the very first block, with the running game left completely
  untouched - not one byte of it is written.
* Because the check is per slot and not per file, a file shared between two
  games does work: each slot simply refuses to load unless its own game is
  running. It is still the wrong way round - you lose slots and have to
  remember which slot belongs to what - which is why one file per game is the
  arrangement to use.
* Sound may click once when a state is loaded, and the top line of sprites can
  be drawn one scanline late. Both are gone within a frame.

### Credits

Original core https://github.com/wsoltys/mist-cores/tree/master/fpga_colecovision

ColecoVision port to MiSTer by Sorgelig.

Save state support was designed, written and bench tested with
[Claude Code](https://claude.com/claude-code), Anthropic's AI coding agent,
working from the existing core - the T80 CPU snapshot ports Sorgelig had already
built into the CPU are what made it a small job. It was verified in simulation
(a state is saved on one run and restored on another, and the two machines then
execute identically, byte for byte) and compiled with Quartus 17.0.2.
