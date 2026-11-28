
This is a MiSTer port of the core by:
https://github.com/zzemu-cn/LASER310_FPGA_DD20


# OSD

The menu follows the MiSTer computer-core layout: the media on the top page, the settings on pages.

- **Top page:** Disk 1, Disk 2 (shown while Disk drives is On), Tape, Load VZ, Load ROM; then Machine, Video, Input, Audio and Advanced; then **Apply and reset**.
- **Machine:** Disk drives (DOS) (On by default), CPU speed (Normal, 3x), SHRG, Tape speed, Rewind tape.
- **Video:** Video standard (PAL, NTSC), Aspect ratio, Scale, Scandoubler Fx, Tape overlay, Load hints.
- **Input:** Keyboard layout (VZ, PC).
- **Audio:** Tape audio.
- **Advanced:** Tape deck, Tape polarity, Tape pitch.

Disk drives, CPU speed, SHRG and Video standard change the machine, so they wait for **Apply and reset** (the top page shows "Changes pending" until then). Everything else acts at once. Settings saved by builds before 2026-11 are dropped once (config version 1), so the core starts from the defaults.

- **Load ROM** replaces the 16 KB BASIC ROM for this session (a `games/Laser/boot0.rom` is loaded at every core start instead, if present). The machine resets with it.
- **Aspect ratio Original** is the VZ's real picture shape, 8:7: the 6847 sends 256 x 192 pixels at 7.16 MHz, narrower than square pixels. **Scale** V-Integer gives 5x (960 lines) at 1080p. On HDMI leave Scandoubler Fx at None for the biggest integer picture: with it on the scaler sees 384 lines.

# Keyboard

- **VZ** (default): keys act by position, as on the VZ keyboard: `"` is Shift+2, `(` `)` are Shift+8 and Shift+9, `=` is Shift+-, `:` is the key right of `;` (PC `'`), `+` and `*` are Shift+; and Shift+:.
- **PC:** symbol keys type what is printed on a US PC keyboard (Shift+' gives `"`, Shift+; gives `:`, `=` is unshifted, `/` `?` `[` `]` `\` `^` `@` `&` `*` `(` `)` where the PC has them). `_ { } |` have no VZ key and do nothing. Letters and digits are the same in both layouts. With Ctrl held the keys stay positional, so the VZ's Ctrl functions (RUBOUT Ctrl+;, INVERSE Ctrl+:, BREAK Ctrl+-) work as printed on the VZ.
- Both: the arrow keys, Backspace and Esc (BREAK) are mapped to the VZ's Ctrl combinations.

# VZ Loader

Load VZ snapshots - there are two types, basic images and binary images. The basic images will load, and you need to type RUN&lt;enter&gt; to start. Binary ones should start automatically.

With **Load hints** On (the default), after a BASIC snapshot loads the bottom-left corner of the picture shows the program's name (from the .VZ header) and `TYPE RUN ↵`, until you press Return. Binary snapshots start by themselves and show nothing. Turn it off in the OSD with Load hints: Off.

# Tape

Mount a `.wav` or `.cas` in the OSD **Tape** slot, then type `CLOAD` (BASIC) or `CRUN` (load and start, BASIC or machine code) and press Return. The VZ has no motor control, so the deck starts by itself when the BASIC ROM starts reading the tape and stops when it finishes; you never press play. The tape is not remembered between core starts, and every mount starts at the beginning ("Tape ready (rewound)").

- **Formats:** `.wav` 8-bit or 16-bit PCM or 32-bit float, mono or stereo (left channel), any sample rate; `.cas` (the raw tape byte stream, as MAME's `vt_cas`). Tapes stream from the SD card, so any length works.
- **Tape speed:** 3x (default) runs the CPU and the tape three times faster while the ROM loads, so a load takes a third of the time and the program then runs at normal speed. Normal plays at real speed. WAVs that need more than 100 kB/s (for example 96 kHz float) always play at 1x.
- **Tape overlay:** On (default) shows `TAPE ▶ 0:14/ 0:58 x3` and a progress bar while the tape plays, and what to type while it is stopped: `TYPE CRUN ↵` when a tape is at its start, `TYPE RUN ↵` after `CLOAD` of a BASIC program. `CRUN` is a guess the tape doesn't state: it works for BASIC (type F0) and machine-code (F1) programs, which is the first file of every tape in our test set that has a readable header. The box covers the bottom text line, where the ROM prints WAITING / LOADING, while it is shown.
- **Tape deck:** Auto (default) plays only while the ROM's tape routine runs. Play keeps the tape running whenever one is mounted, for programs with their own loaders (such as the 2018AD demo's later parts); turbo still only applies while the ROM reads.
- **Tape pitch:** Auto (default) measures each tape's speed from its leader when you mount it and plays it at the speed the ROM reads best, like setting a cassette deck's speed trim per tape. The ROM's bit timing is narrow and real recordings run a few percent fast or slow: on a 60-tape sample, Normal loads 41, a fixed +6% loads 52 but breaks some fast recordings, and Auto loads 52 plus one more with Tape polarity Inverted. Normal, +6% and +12% are fixed settings. The samples themselves are never changed, only the rate they play at.
- **Tape polarity:** Inverted flips the signal, for recordings made through an inverting player or tool.
- **Tape audio:** On mixes the tape signal into the sound quietly.
- **Rewind tape** goes back to the start.
- `CSAVE` is not supported yet.

# Floppy disks

**Disk drives (DOS)** On (the default) fits the DD20 / DI-40 disk interface: VZ DOS 1.2 at 4000h and two drives. VZ DOS takes the top 311 bytes of RAM (BASIC's top of memory is FEC8h instead of FFFFh); set it Off and Apply and reset for a machine without the disk interface. Mount `.dsk` images in **Disk 1** and **Disk 2**.

## Using VZ DOS

The machine starts with `DOS BASIC V1.2` above `READY`. Nothing loads by itself: mount a disk, type `DIR` to see what is on it, then start a program by name.

1. OSD **Disk 1**: pick a `.dsk` from `games/Laser/`.
2. `DIR` ↵ lists the files: `T:` BASIC program, `B:` machine code, `D:` data file. SPACE pauses the listing, SPACE again continues.
3. `T:` files: `RUN"NAME"` ↵. `B:` files: `BRUN"NAME"` ↵.

Typing `"`: with Keyboard layout **VZ** (the default) it is Shift+2; with **PC** it is Shift+' as on a PC keyboard.

| Command | What it does |
|---|---|
| `DIR` | List the files on the current drive. |
| `RUN"NAME"` | Load a BASIC (`T:`) program and run it. Plain `RUN` still runs the program in memory. |
| `LOAD"NAME"` | Load a BASIC program (then `RUN`, `LIST`...). |
| `SAVE"NAME"` | Save the BASIC program in memory as a `T:` file. It never overwrites: an existing name gives `?FILE ALREADY EXISTS`, so `ERA` the old one first. |
| `BRUN"NAME"` | Load a machine-code (`B:`) file and jump to it. |
| `BLOAD"NAME"` | Load a `B:` file to the address it was saved from, without running it. |
| `BSAVE"NAME",SSSS,EEEE` | Save memory from SSSS to EEEE (inclusive) as a `B:` file. Addresses are exactly 4 hex digits, no `&` or `$`: `BSAVE"CODE",9000,9FFF`. |
| `ERA"NAME"` | Delete a file. |
| `REN"OLD","NEW"` | Rename a file (the type stays). |
| `DRIVE 1` / `DRIVE 2` | Choose the drive the other commands use (drive 1 at power-on). |
| `STATUS` | Free space on the disk, e.g. `624 RECORDS FREE` `78.0K BYTES FREE` (an empty disk). |
| `INIT` | Format the disk in the current drive. **Erases everything, without asking**: check `DRIVE` first. Takes 2-3 minutes. |
| `DCOPY"NAME"` | Copy one `T:` or `B:` file. Asks `SOURCE DISK(1/2)?` and `DESTINATION DISK(1/2)?`; with the same drive for both it asks you to swap disks (OSD remount, then SPACE). Direct mode only. |
| `DCOPY` | Copy a whole disk, track by track, onto an already `INIT`ed disk (fully overwritten). |
| `OPEN"NAME",0` / `OPEN"NAME",1` | In a program: open a `D:` data file for reading (0) or writing (1, appends; creates it if missing). At most two files open. |
| `PR#"NAME",A,B$...` | In a program: write one record (a line) to a file opened with 1. |
| `IN#"NAME",A,B$...` | In a program: read one record from a file opened with 0. There is no end-of-file test, so write a count or an end marker yourself. |
| `CLOSE"NAME"` | Close a data file. Always `CLOSE` in the program: a `CLOSE` typed after BREAK frees the file but loses unwritten data. |

- File names go in double quotes, up to 8 characters (longer names are cut to 8).
- `DCOPY` clears the BASIC program in memory and selects drive 1 again: save your work first.
- DOS errors: `?FILE NOT FOUND`, `?FILE ALREADY EXISTS`, `?FILE TYPE MISMATCH` (e.g. `RUN` on a `B:` file), `?DISK WRITE PROTECTED` (disk mounted read-only), `?DISK FULL`, `?DIRECTORY FULL` (120 files), `?DISK I/O ERROR` (bad sector or checksum), `?FILE NOT OPEN`, `?FILE ALREADY OPEN`, `?DISK BUFFER FULL` (third open file), `?ILLEGAL READ` / `?ILLEGAL WRITE` (wrong `OPEN` mode).
- A disk holds 40 tracks of 16 sectors of 128 bytes; track 0 is the directory and free-sector map.

## Disk emulation

- **Images:** every `.dsk` variant in circulation works (98,560, 99,184, 99,185 bytes and the odd sizes in between): the image is read at mount like MAME does, by finding each sector's header and data marks, so extra or missing gap bytes don't matter.
- **Writing:** `SAVE`, `ERA`, `INIT` etc. write to the image file on the SD card. Each written sector (128 bytes and its checksum) goes back in place, so the file keeps its own layout and size and stays readable by other emulators. A disk mounted read-only is write protected (`?DISK WRITE PROTECTED`).
- **Timing:** the controller is modelled at the flux level, like the real board and MAME: the drive delivers a bit every 115 CPU cycles and the DOS reads it by polling, so other disk software (copy programs, custom loaders) sees the same signals. With CPU speed 3x the disk speeds up with the CPU.
- VZ DOS 1.2 has two wait loops that only worked on the real machine by luck of timing; the core patches them the same way MAME does (two bytes, at 5678h and 5688h).

# Video and sound

- **Video standard:** PAL (50 Hz, the default) gives the 312-line field of the VZ300 / Laser 310 and PAL VZ200: the 6847's 262-line field padded with 25 border lines above and 25 below, as the PAL machines do. NTSC (60 Hz) is the Laser 200 / NTSC VZ200 timing. Games timed by the frame interrupt run at their intended speed only with the right standard; most VZ software was written for PAL. Lines are 228 CPU cycles (59,736 cycles per frame NTSC, 71,136 PAL). The CPU clock is 3.5795 MHz in both; a real VZ300 runs 0.9% slower (3.5469 MHz), which also slows its video by the same amount.
- **Interrupt and vblank:** the Z80 interrupt and bit 7 of the keyboard port (6800h) both follow the 6847 field-sync pin, low for the vertical blanking period, as on the real machine. Games that poll bit 7 to wait for vblank (TENNIS, 3D-MAZE, BENNY) work.
- **Colour blocks:** VRAM characters 80h-FFh are the 6847's semigraphic blocks in 8 colours (bits 6-4), as used by BASIC `SET`/`COLOR` in text mode.
- **SHRG:** the Australian SHRG graphics mod (port 20h), On by default; Off gives a stock machine.
- **Sound:** the speaker is driven push-pull by latch bits 0 and 5 (three levels), as 1-bit music engines expect. With Tape audio On the tape input and the cassette output are mixed in quietly.

# Joystick Support

The original system has a left and right joystick. It is possible you may need a second joystick to play some games.


# 08-SEP-20

Added switchable 64x32 Screen mode
Added 24K VRAM mode
Fixed error with CPU reading $7800-$7FFF range
Added 6847T1 style Lower Case, requires SHRG *ON*

# 16-SEP-20

Fixed display shakiness.
Tweaked display parameters slightly.

# TODO

* cassette save (CSAVE)
