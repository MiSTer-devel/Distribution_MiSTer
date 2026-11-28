# Toshiba Pasopia 7 for MiSTer

A MiSTer core for the Toshiba Pasopia 7 (PA7007, 1983), a Japanese Z80 home computer. One core covers three models:

- **Pasopia 7**: Z80A at 3.99 MHz, 64 KiB RAM, 640 x 200 graphics in 8 colours (27 by dot tiling), two SN76489
  sound chips, T-BASIC7 in ROM, cassette, floppy and the PAC2 cartridge slot.
- **Pasopia 7 LCD** (PA7170): the same machine with a 320 x 64 liquid crystal panel.
- **Pasopia** (PA7010, 1981): the original model, with T-BASIC 1.1 and a beeper.

Tapes (CAS and WAV) load at normal speed or 5x, floppies (D88) boot CP/M and games, BASIC programs are saved to RAM PAC
files on the SD card, and the Kanji ROM PAC works.

## Installation

1. Copy `releases/Pasopia7_YYYYMMDD.rbf` to `_Computer/` on the SD card.
2. Put the ROMs in `games/Pasopia7/`. They are not included; they come from MAME's sets:

| file | needed for | MAME set | contents |
|---|---|---|---|
| `boot.rom` (52 KiB) | **required**: Pasopia 7 and Pasopia 7 LCD | `pasopia7.zip` | `bios.rom` + `basic.rom` + `2732.ic146`, in that order |
| `boot1.rom` (34 KiB) | Model: Pasopia | `pasopia.zip` | `tbasic.rom` + `5t_2716.ic79` |
| `boot2.rom` (128 KiB) | Kanji ROM PAC (optional) | `pa7246.zip` | `kanji.rom` |

`tools/make_boot_rom.py` builds them from the MAME zips and checks the CRCs:

```
python3 tools/make_boot_rom.py pasopia7.zip boot.rom
python3 tools/make_boot_rom.py pasopia.zip  boot1.rom
python3 tools/make_boot_rom.py pa7246.zip   boot2.rom
```

3. Optional: copy `releases/RAMPAC_blank.bin` to `games/Pasopia7/RAMPAC1.bin` so BASIC programs are kept (see
   [RAM PAC](#ram-pac-saving-basic-programs)).

## Starting up

The Pasopia 7 BIOS asks **How many disk drives(0-4)?** and **How many files(0-15)?**. With no floppy, answer `0` and
`0`; T-BASIC7 starts with `Ok`. With a bootable floppy in FDD 1 the core boots from it instead. The original Pasopia
asks only **How many files**.

Model and Display take effect after **Apply and reset**.

## OSD

| page | option | |
|---|---|---|
| top | Pri. FDD 1, FDD 2 | `.d88` floppy images |
| top | Tape | a `.cas` or `.wav` tape; rewound at every mount |
| top | RAM PAC 1, RAM PAC 2 | 32 KiB files behind the two RAM PACs; remembered, written back as BASIC changes them |
| top | Load ROM, Load Pasopia ROM, Load Kanji ROM | another `boot.rom` / `boot1.rom` / `boot2.rom` for this session |
| Machine | Model | Pasopia 7, Pasopia 7 LCD, Pasopia |
| Machine | Tape speed | 5x (default) or Normal |
| Machine | Tape shaper | Off (default); On for some badly recorded WAVs (see [Cassette](#cassette)) |
| Machine | Rewind tape | back to the start of the tape |
| Video | Display | Color, B&W, Green, Amber |
| Video | Aspect ratio, Scale, Scandoubler Fx | the usual MiSTer video options |
| Video | Tape overlay | the tape position, length and a progress bar while it plays |
| Input | Keyboard symbols | US (default) or By position (JP) (see [Keyboard](#keyboard)) |
| Input | Swap Alt/Win keys | |
| Audio | Tape audio | hear the tape while it loads |

## Cassette

Mount a tape with **Tape**. The core plays it while the computer's tape motor is on.

| tape | type |
|---|---|
| BASIC programs and most games (a BASIC loader followed by machine code) | `CLOAD`, wait for `Ok`, then `RUN` |
| a machine code file, e.g. Fire Dragon (its file is `F`) | `BLOAD#-1,"F"` |

Some games ask a question or say "press Return" before they load the rest.

- **CAS**: the Common Source Code Project's format (the TOSEC Pasopia 7 set).
- **WAV**: 8 or 16 bit, mono or stereo, any sample rate.

**Tape speed 5x** (default) runs the computer and the tape 5 times faster while the motor runs, so a 5-minute tape
loads in a minute. CAS files and mono WAVs up to 48 kHz play at 5x; a stereo 44.1 kHz WAV plays at normal speed (the
overlay then shows no `x5`). A `!` in the tape overlay means the SD card could not keep up.

A game that comes as two WAVs (a loader and the game, e.g. inufuto's homebrew `NAME01.wav` and `NAME02.wav`) loads
in one go once joined: `python3 tools/join_wav.py GAME.wav NAME01.wav NAME02.wav`.

**Tape shaper**: if a WAV stops with `?TP Error`, set Tape shaper to On, rewind and try again. It redraws each cycle of
the recording as a clean square wave, which some dumps need (Akarui Noen, Ame no Hi wa Oisogashi and Field Wars from
archive.org). Leave it Off otherwise: tapes that load as they are can fail with it. `tools/shape_wav.py IN.wav
OUT.wav` does the same to a file.

Without a mounted tape the cassette input is the MiSTer's line-in, so a real tape deck can be used.

## RAM PAC (saving BASIC programs)

T-BASIC's `SAVE "NAME"`, `LOAD "NAME"` and `FILES` use the RAM PAC in the PAC2 slot. Select a 32 KiB file on
**RAM PAC 1** (e.g. `RAMPAC1.bin`, a copy of `releases/RAMPAC_blank.bin`); the core writes every change back to the SD
card and mounts it again at the next start. Without a file the RAM PAC works but is lost at power off.
`tools/make_rampac_bin.py OUT.bin` makes a new blank one.

RAM PAC files from the Common Source Code Project (`RAMPAC1.BIN`) and the Gaming Alexandria Pasopia dumps
(`[CT].bin`, Model Pasopia: mount, `FILES`, `LOAD "NAME"`, `RUN`) work as they are.

The ROM BASIC saves only to the RAM PAC, not to tape or floppy.

## Floppy

Two 2D drives. Images are `.d88`; a bootable disk in **Pri. FDD 1** boots at power-on. Writes go back to the image.

- `tools/raw2d88.py IN.2d OUT.d88` converts a raw `.2d` image; `tools/make_blank_d88.py OUT.d88` makes a blank
  formatted disk.
- Known to work: CP/M 2.2 for both models (github.com/beijingduckx/pasopia7_cpm22), S-OS SWORD (Pasopia), inufuto's
  homebrew games (inufuto.web.fc2.com/8bit), and Prism - A Story Disk (the T100 version: Model Pasopia, Keyboard
  symbols By position, `RUN"PRISM"`).

## Models

- **Pasopia 7 LCD**: BASIC and its graphics appear on the 320 x 64 panel (40 x 8 characters), dark dots on a grey
  panel. The Display option does not apply.
- **Pasopia** (needs `boot1.rom`): T-BASIC 1.1. Its tapes load the same way (`CLOAD`, then `RUN`); RAM PAC 1 is its
  PAC2 slot.

## Kanji ROM PAC

With `boot2.rom` present, the Pasopia 7's Kanji ROM PAC holds the 16 x 16 kanji patterns for software that uses them.

## Keyboard

The Pasopia has a Japanese keyboard.

- **Keyboard symbols: US** (default): symbols are typed as printed on a US keyboard (`"` is Shift+', `@` is Shift+2,
  `:` is Shift+;, `\` gives the yen sign).
- **By position (JP)**: keys by position, for a Japanese keyboard, for games that expect the Japanese layout, and for
  T100 (US Pasopia) software.

| PC key | Pasopia key |
|---|---|
| Backspace | DEL |
| Insert | INS (SHIFT+DEL) |
| Home | HOME/CLS |
| F1-F10 | function keys |
| F11 | LABEL |
| F12 | KANJI |
| left Alt / right Alt | GRAPH / KANA (Swap Alt/Win keys swaps them with the Win keys) |

## Known limitations

- No tape saving: `CSAVE` runs but is not recorded; save to the RAM PAC.
- The system tape's FORMAT program cannot format a disk; use `tools/make_blank_d88.py`.
- The original Pasopia's OA-BASIC and Mini Pascal ROMs are not supported.
- Joy PAC (MiSTer joysticks in slot 1) is implemented but untested with software.
- The LCD's real panel proportions are unknown; it is drawn with square dots.
- Part-Timer no Kyuuyo Keisan's tape stops with `?OM Error` (also in other emulators); its RAM PAC image works.

## Credits

Machine behaviour from Takeda Toshiya's Common Source Code Project (EmuPIA7) and MAME's pasopia7 driver. Reused RTL:
T80 (Daniel Wallner, MiSTer version by Sorgelig), mc6845 and the tape deck from SMC777_MiSTer, SN76496, the Z80 CTC
from SharpX1_Mister, the 8255, uPD765 and D88 handling from PC-8001_MiSTer, the PLL from TK2000_MiSTer.
