# NEC PC-8000 series for MiSTer

A MiSTer core for NEC's PC-8000 series: the PC-8001 (1979), PC-8001mkII (1983) and PC-8001mkIISR (1985).
The PC-8001 runs (see Status). This directory holds the plan ([PLAN.md](PLAN.md)) and the references gathered for it
(2026-11-03).

MiSTer already has a PC-8801mkIISR core (MiSTer-devel/PC88_MiSTer). Its N mode runs much PC-8001 software, but
it is a PC-8801: no PCG-8100, the 8801's N-BASIC and video, and no PC-8001 or mkII model. PLAN.md explains why
this is a separate core and what it takes from PC88_MiSTer.

## The machines

| | PC-8001 | PC-8001mkII | PC-8001mkIISR |
|---|---|---|---|
| CPU | uPD780C-1 (Z80) 4 MHz | same | same |
| RAM | 16 KB (32 KB on board, 64 KB with PC-8012) | 64 KB | 64 KB |
| ROM | N-BASIC 24 KB | N-BASIC 1.3 + N80-BASIC (32 KB) | + N80SR-BASIC (40 KB) |
| Text | uPD3301 CRTC + uPD8257 DMA: 80/40 x 25/20, attributes, 8 colours, 160x100 semigraphics | same | same |
| Graphics | none (PCG-8100 option: programmable characters) | 16 KB GVRAM: 640x200 mono, 320x200 4 colours | 48 KB, 3 planes: 640x200 8 colours |
| Sound | beeper | beeper | beeper + YM2203 |
| Storage | cassette (8251, 600 baud); PC-8031/80S31 disk unit | + internal disk interface | same |

Sources and uncertain points: [refs/docs/HARDWARE_NOTES.md](refs/docs/HARDWARE_NOTES.md).

## What is here

| Dir | What | Index |
|---|---|---|
| refs/docs/ (225 MB) | manuals (mkII kaiseki I/II, the English PC-8001B manual, N80-BASIC refs), datasheets (uPD3301, uPD8257, uPD8251, uPD765), web pages, MAME driver sources, **HARDWARE_NOTES.md** | refs/docs/README.md |
| refs/emulators/ (145 MB) | emulator sources: X88000, X88000M, QUASI88, M88, M88M, xm8m, PC8001FabGL, n80FabGL, pc8031fabgl; MAME ROM dirs (mame_roms/) and boot screenshots (runs/) | refs/emulators/README.md |
| refs/hdl/ (33 MB) | PC88_MiSTer (the MiSTer PC-8801 core), radiojunkbox/pc8001m and chiqlappe/PC-8001_FPGA (the only PC-8001 HDL) | refs/hdl/README.md |
| refs/software/ (383 MB) | Year-Based Collection (PC-8001 line), Neo Kobe PC-8001 (800 titles), TOSEC, MAME pc8001_flop, homebrew sources from GitHub; 44 curated test titles | refs/software/README.md |

## Reference emulators

- **MAME 0.283** (`/Users/alans/Downloads/mame0283-arm64/mame`), drivers pc8001, pc8001mk2, pc8001mk2sr. With
  `-rompath refs/emulators/mame_roms`, pc8001 and pc8001mk2 verify and boot to "NEC PC-8001 BASIC Ver 1.1" / "Ver
  1.3"; pc8001mk2sr boots to "Ver 1.6" (refs/emulators/runs/snap_*). The MAME ROM zips came from ~/Downloads
  (pc8001.zip, pc8001mk2.zip, pc8001mk2sr.zip, 2026-11-03), all SHA1s match.
- **Common Source Code Project** (`/Users/alans/dev2/common_source_code`): CMake targets pc8001, pc8001mk2,
  pc8001mk2sr (src/vm/pc8801), all with `--headless` (CLI.md). All three boot (2026-11-03) from
  refs/emulators/cscp_roms/<model> (CSCP file names, below); frames are 640x400 (lines doubled). The SR starts in
  N80 mode (N-80 BASIC 1.2), where MAME's SR starts in N mode (Ver 1.6). Example:
  `build/pc8001.app/Contents/MacOS/pc8001 --headless --rom-dir refs/emulators/cscp_roms/pc8001 --out NEWDIR
  --stop-at-frame 1200 --final-screenshot` (from ~/dev2/common_source_code; output in refs/emulators/runs/cscp).

| CSCP name | pc8001 | pc8001mk2 | pc8001mk2sr |
|---|---|---|---|
| N80_1.ROM / N80_2.ROM | n80v110.rom | n80_2.rom | n80_2sr.rom |
| N80_3.ROM | | | n80_3.rom |
| FONT.ROM / KANJI1.ROM | font.rom | kanji1.rom | kanji1.rom |
| 80SRCG.ROM (font + hiragana at D00h) | | | font80sr.rom |
| DISK.ROM | disk.rom | disk.rom | disk.rom |
- Source to read for details: X88000 and QUASI88 (Japanese, long-lived PC-8001/8801 emulators).

## ROMs

These are not in a MAME-named set, but are inside the downloaded software sets (archive_org/yearbased_pc8001_unpacked/ROMs/):

| MAME name | Where | SHA1 |
|---|---|---|
| n80v101.rom / n80v102.rom / n80v110.rom | ROMs/PC-8001/N80_101, N80_102, N80_1 | 6d2d838d / b34a9894 / 4603cdb7 |
| font.rom (also SR fontkata.rom) | ROMs/PC-8001/font.rom | 84b90f69 |
| n80_2.rom (mkII) | ROMs/PC-8001mkII/N80_2.rom | c12d34e4 |
| n80_2sr.rom, n80_3.rom, font80sr.rom (SR) | ROMs/PC-8001mkIISR/N80_2, N80_3, 80SRCG | e8db5dc5, 9bfa5009, 565dc8e5 |
| kanji1.rom | ROMs/*/kanji1.rom | 82e11a17 |
| disk.rom (PC-80S31) | ROMs/*/disk.rom | bb7103a0 |
| mk2fr_disk.rom | /Users/alans/dev2/PC-6001_MiSTer/rom/ | 80da2dee |
| fonthira.rom (SR) | ~/Downloads/pc8001mk2sr.zip (now in refs/emulators/mame_roms/) | 10c5f85a |

## Status

2026-11-05 (TODO.md): phases 0-6. Text screen (uPD3301 + uPD8257), keyboard (JIS positions or US
symbols), cassette (.cmt/.t88, turbo), the PC-80S31 disk unit (two drives, .d88 on S0/S1), PCG-8100
(programmable characters and its 8253 sound), the uPD1990A clock (time from the MiSTer) and an expansion ROM
at 6000h. The printer port takes every byte (BUSY never set) and drops it; the sim can save it (--printer).
PC-8001mkII (OSD Model): N80-BASIC or N-BASIC (OSD mkII mode), 64 KB RAM, 16 KB graphics (640x200 in the text's
colours, 640x200 mono, 320x200 4 colours, background colour), mode 2 interrupts, the kanji ROM.
PC-8001mkIISR (phase 6): N80 / N / N80SR-BASIC modes, three 16 KB GVRAM planes with the ALU, 8 colours from a
palette, the N80SR video modes, hiragana, the YM2203 (jt03) and its interrupt. Every compared screen is
pixel-identical to CSCP (tools/cscp_suite.sh). Not yet tried on a MiSTer.

OSD (~/dev2/osd-standard.md): Drive 1 / Drive 2 (.d88, remembered), Tape (.cmt/.t88), Memory Image (.n80), Expansion
ROM (8 KB at 6000h, resets), Load ROM (boot.rom); Memory 32/16 KB (the PC-8001 only); Machine: Model PC-8001 / PC-8001mkII /
PC-8001mkIISR, Mode N80 / N / N80SR (mkII, SR), PCG-8100, Tape speed, Rewind; Video: Aspect ratio, Scale,
Scandoubler Fx, Tape overlay; Input: Keyboard JP/US, Swap Alt/Win keys. Model, Mode, Memory and PCG-8100 apply at
Apply and reset; the rest at once.

Keys (rtl/pc8001_kbd.sv): GRPH = left Alt; KANA (a lock) = right Alt, Caps Lock or the JP kana key; STOP = F9 or
End; F6-F8 and F10 = SHIFT + F1-F3 and F5; Down / Left / Insert = SHIFT + Up / Right / DEL.
On the SR its extra row (port 0Ah) also: Tab, Down, Left, HELP = F11, COPY = Print Screen, keypad - and /, CAPS
(a lock) = SHIFT + Caps Lock.

Video (~/dev2/video-standard.md): 640 x 200 at 14.318 MHz dots, 15.7 kHz, in every model. Original aspect is the
real shape, 48:35 (1.37:1): pixel aspect 3/7 (6.136 / 14.318 MHz), 640*3 : 200*7. No vertical crop (200 lines are
already 5x at 1080p). On HDMI, leave Scandoubler Fx at None for the biggest integer picture (the scandoubled
400 lines only fit 2x); a VGA monitor needs forced_scandoubler=1 in MiSTer.ini or a Scandoubler Fx.

Tape overlay (~/dev2/tape-standard.md): while the deck plays, `TAPE ▶ m:ss/ m:ss x5` and a progress bar; while it
is stopped, what to type next, read from the tape itself as it loads (rtl/tape_hint.sv): a BASIC tape (CSAVE
header) shows `TYPE CLOAD"name" ↵` at its start and `TYPE RUN ↵` once the program has loaded, until Return (not when a
machine-code block follows it: some such programs load it themselves, others need MON and L first); a
machine-code tape (monitor W records) shows `TYPE MON ↵ L ↵`. The start address after L is not on the tape, so
it is not shown (the game's instructions give it). Nothing is shown once the program has been started, for a tape
whose first block is in neither format (Pac Land's sides B-D), or with Tape overlay Off. The hint is drawn with
the machine's own font, so names keep their case (`cload"river"`). Model and Mode are not hinted (Pac Land wants
the SR in N80SR mode: the tape gives no sign of it).

Memory Image (.n80): a snapshot of the RAM from 8000h taken on a running machine, loaded once BASIC is up and
started at once (no reset) as CSCP does: SP from FF3Eh, then the RET at FF3Dh. The whole file is loaded (CSCP stops
at FF3Fh; most images run on to FF63h, where that RET goes: a stub that restores the registers). Many were saved at
a prompt, so the screen shows what was typed then, and the next step is the one the game's notes give (RUN at
`Ok`, RETURN after `*GC100`). The image holds BASIC's work area, so it wants the BASIC it was saved under: one whose
screen shows `Ver 1.1` runs on the PC-8001, a later one on the mkII in Mode N (sim: Crazy Climber, Missile
Commander).

- boot.rom: `tools/make_boot_rom.sh refs/emulators/mame_roms/pc8001 rom/boot.rom` (= `cat n80v110.rom font.rom
  disk.rom`; leave disk.rom out for a machine without the disk unit).
- boot1.rom (the mkII, beside boot.rom): `tools/make_boot1_rom.sh refs/emulators/mame_roms/pc8001mk2 rom/boot1.rom`
  (= `cat n80_2.rom kanji1.rom`). Main loads it at the core's start; it is kept in DDR3 and copied in at a reset
  when the model changes (rtl/rom_store.sv).
- boot2.rom (the SR): `tools/make_boot2_rom.sh refs/emulators/mame_roms/pc8001mk2sr rom/boot2.rom` (n80_2sr.rom,
  n80_3.rom, font80sr.rom, kanji1.rom; 256 KB, checked by SHA1).
- Compare with CSCP: `tools/cscp_cmp.sh NAME FRAMES 'TEXT'` (DISK=, DISK2=, SWAP=, SWAP2=, TAPE=, TEXT2=, MODEL=mk2 / sr,
  NMODE=1, V2=1 options), all cases:
  `tools/cscp_suite.sh`.
- Sim: `cd verilator && make && ./obj_dir_headless/Vtop --stop-at-frame 250 --screenshot 250`; `./run_tests.sh`.
- MAME frames: `tools/mame_ref.sh pc8001 runs/mame/boot 100,300 ['300:PRINT 1\n']`.
