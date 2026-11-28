# Camputers Lynx for MiSTer

The Camputers Lynx 48K, 96K (standard and Scorpion ROM) and 128K, a British Z80 home computer from 1983,
on MiSTer. It runs from block RAM, so no SDRAM module is needed.

## The Camputers Lynx

The Lynx was first released in early 1983 as a 48 KB model, designed by John Shireff; 96 KB and
128 KB models followed. A Z80A ran at 4 MHz (6 MHz on the 128K) with a Motorola 6845 as video
controller. The machine is always in an 8-colour bitmap mode (256 x 252 pixels on the 48K / 96K,
512 x 252 on the 128K) and draws its 6 x 10 pixel text itself, so text and graphics are slow but
look good. BASIC is large and pre-compiled, with graphics commands and inline machine code. Sound is
a 6-bit DAC. About 30,000 were sold.

## OSD

| Row | Page | |
|---|---|---|
| Disk | top | `.LDF` floppy image for the WD1793 disk interface (type `XROM` to start the disk system) |
| Tape | top | `.TAP` (Lynx), `.TZX` or `.WAV` tape image, played as a real tape signal |
| Load ROM | top | Another `boot.rom` (see ROMs) for this session |
| Model | Machine | Lynx 48K, Lynx 96K, 96K Scorpion, Lynx 128K |
| CAS blanking | Machine | On (default): a colour plane is blanked while its /CASEN bit switches it off; Level 9 adventures need it (whether a real Lynx shows black there isn't confirmed). Off: never blank (48K / 96K only) |
| Tape speed | Machine | 4x (default): the CPU and the tape run 4 times faster while the tape motor is on; Normal |
| Rewind tape | Machine | Back to the start of the tape |
| Aspect ratio, Scale, Scandoubler Fx | Video | Original is the Lynx's real picture shape |
| Tape overlay | Video | On (default) / Off: the tape status bar and the tape / disk next-step hint |
| Swap joysticks | Input | |
| Tape audio | Audio | Hear the tape while it plays |
| Invert tape in | Audio | Polarity of a `.WAV` or a real cassette on the line-in (ADC) input |

Model and CAS blanking take effect at **Apply and reset** ("Changes pending" shows that something
is waiting). F9 resets the Lynx.

## Loading software

The Lynx loads by name and has no wildcard, so you have to type the name that is on the tape:

    LOAD "NAME"        BASIC program, then RUN
    MLOAD "NAME"       machine code (most start by themselves)

The name on the tape is often not the file name (`Logichess` is `ECHECS`, `Demo 3` is `CODE`).
While the tape is stopped, the bottom-left corner shows what to type, read from the tape itself:
`TYPE LOAD "SNAKE"↵`, then `TYPE RUN↵` after a BASIC program has loaded. While the tape plays it
shows `TAPE ▶ 0:43/ 2:03 x4` and a progress bar. Multi-file tapes, Level 9 adventures (data files
without names) and custom loaders (e.g. Mazeman) work, because the tape is played as a signal the
Lynx's own ROM reads. A tape starts rewound every time it is mounted.

Tape formats:

- `.TAP` (the Jynx / PALE format, most of the software): the core rebuilds the tape signal from the
  bytes, at the speed the Lynx asks for: the 128K reads tapes twice as fast as the 48K, and
  `TAPE 1` to `TAPE 5` (900 to 2100 baud, set before LOAD) are followed on the 48K / 96K, which
  together with 4x turbo makes `TAPE 5` loads very quick.
- `.TZX` (made from recordings, e.g. with rcmolina's CamputersLYNX tools for Kyp's cores): played
  as recorded; type the `TAPE n` the file name says before loading. PgUp / PgDn start and stop a
  TZX by hand (it also starts and stops with the motor).
- `.WAV` (8- or 16-bit PCM, any rate, e.g. real tape captures or lynx2wav output): played as
  recorded, like the line-in; type the `TAPE n` it was recorded at.

The Lynx has no `LOAD ""` wildcard (MAME: "there's no wildcard; you must specify the name"), so
the name is always needed; the on-screen hint shows it.

ESC stops a `LOAD` that is waiting (wrong name, or the tape has ended), as on the real Lynx.

Keyboard: the PC keys sit where the Lynx keys are, so `"` is Shift+2, `:` is the key right of `;`,
and the letters give capitals without Shift.

Real cassettes can be loaded through the MiSTer's audio line-in.

Joysticks: the two Lynx joystick ports (up / down / left / right / fire); Swap joysticks exchanges them.

### Disk

On a 96K or 128K with a `.LDF` image mounted: `XROM`, then `EXT DIR`, `EXT LOAD "NAME"`,
`EXT MLOAD "NAME"`; CP/M disks start with `EXT BOOT`. The bottom-left corner shows the next step:
`TYPE XROM↵`, then `TYPE EXT DIR↵` (or `TYPE EXT BOOT↵` for a CP/M boot disk, recognised from its
first sector) until the disk is read; on a 48K it says `DISK: MODEL 96K / 128K`, as the 48K has no
disk interface.

Both LDF sizes from MAME's `camplynx_flop` list work: 200K (40 tracks, single sided) and 800K
(80 tracks, double sided). All 28 disks in the list have been tested; the Lynx Revival Group disk
menu needs the 128K, as on MAME.

## ROMs

The core has the Lynx ROMs built in (the MAME sets `lynx48k`, `lynx96k`, `lynx128k` and the
LynxDOS ROM, `roms/src`). `games/Lynx48/boot.rom` (64 KB, 48K / 96K) and `boot1.rom` (32 KB, 128K)
replace them if present; `python3 tools/make_roms.py` shows the layout.

## Credits

- **Kyp** ([Kyp069](https://github.com/Kyp069)): the FPGA Lynx itself, first for ZX-Uno and SiDi
  and now [lynx](https://github.com/Kyp069/lynx) (48K / 96K) and
  [lynx128](https://github.com/Kyp069/lynx128), whose machines this core runs (`rtl/lynx_48k.v`,
  `rtl/lynx_128k.v`, `rtl/matrix.v`).
- **Shaeon** (Carlos Palmero, [shaeon/Lynx_MiSTer](https://github.com/shaeon/Lynx_MiSTer)): the
  MiSTer merge of Kyp's two machines this core builds on, the ROM set and `tools/make_roms.py`,
  `rtl/tape_ddr.sv` and the extended `rtl/tzxplayer.vhd`, the video blanking, `rtl/vram.v`.
- **rampa069**, **Yo_Me** and the RetroWiki FPGA team
  ([RW-FPGA-devel-Team](https://github.com/RW-FPGA-devel-Team)): the first MiSTer port and
  [lynx2wav](https://github.com/RW-FPGA-devel-Team/lynx2wav).
- **JasonA** (JasonCoombes-hr): the first tape loader through the OSD and the 128K start.
- **JimmyStones** and **alanswx**: simulation; alanswx: maintenance, this version (with Claude).
- **Fernando Mosquera**: the tape input through the line-in (ADC).
- **Brendan Saricks**, **jackyangantelope**: framework updates and releases.
- **Rodimus**: t80sv, the SystemVerilog Z80 (`rtl/t80sv`), from T80 by **Daniel Wallner**,
  **MikeJ**, **TobiFlex**, **Sean Riddle**, **Sorgelig**, **Fabio Belavenuto** and **Charlie Ingley**.
- **Sorgelig**: UM6845R and the WD1793 (with **Viacheslav Slavinsky** and **Stan Hodge**), the
  MiSTer framework.
- **György Szombathelyi**: tzxplayer.
- **Jonathan Markland** ([Jynx](https://github.com/jonathan-markland/Jynx)): the tape waveform
  the TAP player reproduces, and the cassette-port details.
- **MAME** (camplynx driver: **Robbbert**, **Nigel Barnes**), **PALE** (Peter Todd), the
  Camputers Lynx documentation collected by **ukscone** and the redrawn schematics of
  **Board-Folk**: the hardware reference.

## License

The core is GPL v3 (`LICENSE`), as Kyp's and Shaeon's code it is built from. `sys/` is the
MiSTer framework (GPL v2 or later, compatible); `rtl/t80sv` keeps T80's BSD-style license. The ROMs
are the property of their authors and are included for preservation.
