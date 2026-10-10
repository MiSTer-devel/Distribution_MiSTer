# [National JR-100](https://en.wikipedia.org/wiki/Matsushita_JR_series) for [MiSTer Platform](https://github.com/MiSTer-devel/Main_MiSTer/wiki)

FPGA re-implementation of the National (Matsushita) JR-100 personal computer (1981).

*日本語版は [README.ja.md](README.ja.md) をご覧ください。*

## Features

- MB8861H CPU (MC6800 compatible + NIM/OIM/XIM/TMM/ADX extensions), cycle counts verified by instruction-boundary lockstep against the [pyjr100emu](https://github.com/zabaglione/pyjr100emu) reference emulator
- R6522 VIA (timers, shift register, PB7 sound, keyboard matrix scan) verified per-cycle against the reference
- 32x24 character display (256x192 mono), user-defined characters including the real-hardware shared-VRAM glyphs
- Real-hardware video timing: 7.15909 MHz dot clock, 15.980 kHz / 62.4 Hz sync (the JR-100's custom non-NTSC format), handled by the MiSTer scaler
- Display colour selection (OSD): White, Green (the JR-100's optional TR-120MIC was a green monitor), Amber, Cyan, Orange, Blue, Paper, Mint
- PS/2 keyboard (full 9x5 matrix), joystick on `$CC02` (active high)
- BEEP audio with output band limiting (VIA internals never stop)
- OSD loading of PROG containers (`.prg` v1/v2) and BASIC text files (`.bas`), with optional autostart; OSD saving of the BASIC program to a mounted file
- Virtual cassette deck: the ROM's real `SAVE`/`LOAD` commands work against a mounted `.cmt` tape (600-baud FSK through the VIA, as on hardware)
- Optional 16 KiB extended RAM at `4000-7FFF` (OSD, applied at reset)

Tested on SuperStation One (keyboard: ELECOM TK-FCM077PBK, controller: Xbox One).

## ROM

This repository contains **no ROM images**. Place a JR-100 BASIC ROM you legally own as an 8 KiB raw image (character ROM first 1 KiB, BASIC from offset `0400`) at:

```
/media/fat/games/JR100/boot.rom
```

If your ROM is a PROG container (`jr100rom.prg`), convert it once with:

```bash
python3 tools/prog2rom.py jr100rom.prg boot.rom
```

The core auto-loads `boot.rom` at start; the OSD "Load BASIC ROM" entry does the same manually. Never commit ROM images to this repository (`./scripts/setup-hooks.sh` installs a pre-commit guard).

## Console Mode on SuperStation One

SuperStation One firmware 1.2 with Console Mode 1.1.1 has a platform-specific setup. A verified MGL wrapper launches the core, transfers a program through the proper `F1`/`F2` slot, and can autostart it from **Load Game**. The active game root may be USB storage rather than `/media/fat/games`, so file placement matters.

See [SuperStation One firmware 1.2 and Console Mode setup](docs/SS1_FW12_CONSOLE_MODE.md). The guide includes an all-machine-code STAR FIRE example and a BASIC-only example.

## Loading programs

- `.prg` (PROG v1/v2 containers): OSD → "Load PRG". Binary sections load to their addresses; BASIC sections load at `0246` with workspace pointers set, ready for `LIST`/`RUN`.
- `.bas` (BASIC text): OSD → "Load BAS". Lines are tokenised as plain ASCII text (uppercased, `\xx` hex escapes supported) and loaded at `0246` with workspace pointers set, ready for `LIST`/`RUN`. `tools/bas2prg.py` remains available for offline conversion.
- Hybrid BASIC + machine-code programs: build one PROG v2 with `python3 tools/bas2prg.py game.bas game.prg --bin 1000:routine.bin` (repeatable `--bin ADDR:FILE`), load it via "Load PRG", and call the code with `USR($1000)`.
- Autostart (OSD option, default off): with "Autostart loaded program" on, the core types `RUN` after a BASIC load, or `A=USR($hhhh)` when the container carries the hint. The PROG format itself has no entry-point field, so the hint is a `USR=$hhhh` marker in the v2 comment: add it with `bas2prg.py --autostart 1000` or retrofit any existing `.prg` with `python3 tools/prg_autostart.py game.prg game_auto.prg 300` (also converts v1 to v2). Files without a hint and no BASIC section are left untouched.

## Saving programs

The cassette `SAVE` command has no tape to write to; instead the OSD saves the current BASIC program to a file:

1. Create a blank save file once: `python3 tools/make_save_file.py mywork.prg` (16 KiB; any multiple of 512 bytes works) and put it in `games/JR100/`.
2. OSD → "Mount Save File" → pick it.
3. OSD → "Save BASIC to file" whenever you want to save. The file becomes a normal PROG v2 container, so it reloads through "Load PRG" (and in emulators).

## Cassette tape (real SAVE/LOAD commands)

The core also has a virtual cassette deck wired to the VIA exactly like the real recorder (output on CB2, input on CA1+CB1), so the ROM's own `SAVE`/`LOAD`/`MSAVE`/`MLOAD`/`VERIFY` commands work at the real 600 baud:

1. Create a blank tape once: `python3 tools/make_tape.py mytape.cmt`, put it in `games/JR100/`, and OSD → "Mount Tape".
2. `SAVE` in BASIC just works: the deck is always recording-armed and rewrites the tape from the start (about 20 seconds for a small program — leader tone included, as on hardware).
3. To load: type `LOAD`, then OSD → "Tape Play". The deck regenerates the leader and FSK waveform and the ROM does the actual decoding.

A `.cmt` file holds the raw tape bytes (33-byte header + data + checksums); the FSK modulation and leader tones are (re)generated by the deck.

## Build

The official build runs on GitHub Actions (`.github/workflows/build-core.yml`, Quartus 17.0 in a container). The identical local path is:

```bash
CONTAINER_RUNTIME=docker tools/compile_rbf.sh JR100
```

(Any OCI runtime works; on Apple Silicon the toolchain runs but is impractically slow under Rosetta — use CI.)

## Development & verification

Based on [Template_MiSTer](https://github.com/MiSTer-devel/Template_MiSTer); the `sys/` framework directory is unmodified. The behavioural reference is pyjr100emu, expected as a sibling checkout at `../jr100emu`. Development documents are written in Japanese:

- [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) — plan, environment, verification suites
- [docs/TRACE_FORMAT.md](docs/TRACE_FORMAT.md) — lockstep trace format
- [docs/BOOT_LOCKSTEP.md](docs/BOOT_LOCKSTEP.md) — boot comparison convention and M1 result
- [AGENTS.md](AGENTS.md) — requirements

Simulation (Verilator) covers CPU lockstep, VIA per-cycle vectors, boot-to-READY, frame rendering, joystick/PRG/audio acceptance: see the `tools/run_*` scripts.

## License

GPL-2.0 (see [LICENSE](LICENSE)), following the MiSTer framework. New HDL written for this core is GPL-2.0-or-later. Portions derived from the MIT-licensed pyjr100emu / [jr100-emulator-v2](https://github.com/kemusiro/jr100-emulator-v2) keep their attribution in file headers.
