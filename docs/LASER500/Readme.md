# VTech Laser 350/500/700 for MiSTer

The VTech Laser 350/500/700 are 1985 Z80 home computers with BASIC V3.0, 80/40-column text, graphics modes, a cassette port and an optional 5.25" floppy interface (VT-DOS). All three share the same ROM and differ in RAM: **Model** picks the Laser 350 (16 KB, the screen in the same 16 KB), Laser 500 (64 KB, default) or Laser 700 (128 KB; BASIC sees 64 KB, the rest is bank-switched RAM for programs). The ROM sizes the RAM at boot: `PRINT FRE(0)` gives 5221 on a 350 and 29797 on a 500 or 700.

Based on Nippur72's MiST core and his browser emulator laser500emu, which is the timing reference for the CPU, the floppy and the tape.

# Files

Put these in `games/LASER500/`:

- **`boot.rom`** (required): the 32 KB system ROM, `27-0401-00-00.u6` from MAME's `laser500` set (CRC32 `9bed01f7`). It loads at every core start; **Load ROM** replaces it for the session.
- Programs (`.prg`, `.bin`) for **Load Program**, disks (`.nic`, `.dsk`) and tapes (`.wav`, `.cas`).
- Optionally a character ROM for **Load Char ROM**: 8 KB, laid out like `27-393-00.u10` from MAME's `laser500` set (CRC32 `d47313a2`): four 2 KB banks, English, a test pattern, German and French. The core already contains that ROM; a loaded one replaces it until the core is reloaded.

# OSD

The menu follows the MiSTer computer-core layout: the media on the top page, the settings on pages.

- **Top page:** Pri. disk 1, Disk 2 (hidden while Disk interface is Off), Tape, Load Program, Load ROM, Load Char ROM; then Machine, Video, Audio and Advanced; then **Apply and reset**.
- **Machine:** Model (Laser 500, Laser 350, Laser 700), Disk interface (Auto, Off), Tape speed (2x, Normal), Rewind tape.
- **Video:** Character set (English, German, French, Alternate), Aspect ratio, Scale, Vertical crop, Scandoubler Fx, Tape overlay.
- **Audio:** Tape audio.
- **Advanced:** Tape deck (Auto, Play), Tape pitch (Wow, Steady, +1.6%, -1.6%).

Model, Disk interface and Character set change the machine, so they wait for **Apply and reset** (the top page shows "Changes pending" until then). Everything else acts at once. Character set picks a bank of the character ROM, which holds English, German and French sets: German shows `@[\]{|}~` as `§ÄÖÜäöüß`, French as `à°ç§éùè¨`. Alternate is the MiST core's English set with Commodore 64-style letters.

- **Aspect ratio Original** is the Laser's real picture shape (1.30:1 with the border, 798 x 307 pixels at 14.78 MHz). **Scale** V-Integer gives 3x at 1080p. **Vertical crop 216p(5x)** shows 216 of the 307 lines, the whole 192-line text area with a little border, at 5x on a 1080p display. On HDMI leave Scandoubler Fx at None for the biggest integer picture: with it on, the scaler sees twice the lines and V-Integer drops to 1x.

# Keyboard

- The Laser starts in **caps mode**: letters typed without Shift are capitals, Shift gives lower case (the CAPS key toggles it). BASIC keywords work either way, but disk and tape file names must match exactly.
- **Pause** (or Num Lock) is the Laser's **Reset** key: it resets the CPU only. The ROM warm-starts and a BASIC program in memory survives. The OSD's Apply and reset (or the board's reset button) is a cold start.

# Programs

**Load Program** writes a `.prg`/`.bin` (a BASIC program image as laser500emu and z88dk make them) into memory at the BASIC program area; type `RUN` and Return. If a program doesn't start, reset from the OSD and load it again.

# Tape

Mount a `.wav` or `.cas` in the OSD **Tape** slot, type `CRUN` (load and start, BASIC or machine code) or `CLOAD` (load; machine code starts by itself, BASIC waits for `RUN`) and press Return. The Laser has no motor control, so the deck starts by itself when the BASIC ROM starts reading the tape and stops when it finishes; you never press play. The tape is not remembered between core starts, and every mount starts at the beginning ("Tape ready (rewound)"). Tapes are read-only: `CSAVE` output is not recorded.

- **Formats:** `.wav` 8-bit or 16-bit PCM or 32-bit float, mono or stereo (left channel), any sample rate; `.cas` (the raw tape byte stream, as MAME's `vtech2` cassette format: 10800 samples/s, 600 baud). Tapes stream from the SD card, so any length works.
- **Tape speed:** 2x (default) runs the CPU and the tape twice as fast while the ROM reads the tape, so a load takes half the time and the program then runs at normal speed. The ROM times the bits with CPU loops, so both must speed up together; 2x is the most the CPU clock allows (the Z80 core takes two 14.3 MHz edges per T-state, and runs at a quarter of that normally). Normal plays at real speed. WAVs that need more than 100 kB/s (for example 48 kHz stereo 16-bit) always play at 1x.
- **Tape overlay:** On (default) shows `TAPE ▶ 0:14/ 0:58 X2` and a progress bar in the bottom-left corner while the tape plays, and what to type while it is stopped: `TYPE CRUN ↵` when a tape is at its start, `TYPE RUN ↵` after a load the ROM did not start (CLOAD of BASIC, and most machine-code tapes, see below). `CRUN` is a guess the tape doesn't state: it loads and starts BASIC (type F0) and loads machine code (F1), the first file of every tape in our test set (see `docs/CASSETTE_STATUS.md`). Most tapes made with z88dk / laser500-wav are F1 files whose code sits behind a BASIC line, so the ROM comes back to `Ready` and the overlay then says `TYPE RUN ↵`. The box sits in the bottom border; with Vertical crop on it moves up into the picture's last text line.
- **Tape deck:** Auto (default) plays only while the ROM's tape routine runs (and for a moment after it calls out, to print FOUND). Play keeps the tape running whenever one is mounted, for programs with their own tape loaders (turbo loaders made with `laser500-wav --turbo-tape`); turbo still applies only while the ROM reads.
- **Tape pitch:** Wow (default) lets the tape speed wander by up to 1.6%, as a real deck's does; Steady plays at the exact rate; +1.6% and -1.6% are a fixed speed trim. The ROM syncs to each data block on a short leader (10 bytes, 0.14 s), and whether it locks on depends on timing to the microsecond. At an exact rate the core's timing is the same on every try, so a tape that misses once misses always: at Steady, half of the test tapes stop with `LOADING ERROR` right after `LOADING B:NAME`. With Wow each try is new, so 39 of 40 load first time (see `docs/CASSETTE_STATUS.md`). If one still stops with `LOADING ERROR`, Rewind tape and type `CRUN` again. The ROM accepts about ±6%, and the samples themselves are never changed.
- **Tape audio:** On mixes the tape input and the cassette output into the sound quietly.
- **Rewind tape** goes back to the start.

# Floppy disks

**Disk interface** Auto (the default) fits the floppy interface while a disk image is mounted in **Pri. disk 1** or **Disk 2** (with no disk the ROM would wait for one at power-on). A disk mounted in the first seconds after the core starts, or from an MGL, resets the machine so it boots VT-DOS from it; a disk mounted later is booted with **Apply and reset**. Off removes the interface.

- **Formats:** `.nic` (raw nibbles, 8192 bytes per track, as laser500emu; single- and double-sided) and `.dsk` (163840 bytes, 40 tracks of 16 sectors in physical order). Both are writable: `SAVE` writes back to the image on the SD card, unless the file is read-only.
- VT-DOS: `DIR`, `RUN "NAME"`, `BRUN "NAME"`, `SAVE "NAME"`, `LOAD "NAME"`. Type file names unshifted (caps mode), for example `RUN "TARZAN"`.
- How the interface and the formats work: `docs/DISK.md`.

# Sound

The built-in speaker (latch bit 0), at one level. Tape audio adds the cassette signals.

# Simulation

`verilator/` holds a headless, scriptable simulation of the machine (`make`, then `./obj_hl/Vtop --help`): ROM and program loading, typed keys, disks and tapes on a simulated SD card, PNG screenshots and WAV audio. `verilator/regression.sh` boots the machine, loads and saves programs on `.nic` and `.dsk` disks and loads tapes at 1x and 2x.

# Known limitations

- The Laser 350 lacks the TAB, ESC, BS and GRAPH keys; the core still accepts them from the PC keyboard. The 350's 64 KB RAM expansion module is not modelled (choose Laser 500 instead).
- Speaker B (latch bit 5) is not output.
- The CPU runs at the speed laser500emu uses (one wait state per memory cycle); this matches software timed on real hardware, but is not measured against a real machine.

# Credits

- Nippur72 (Antonino Porcino): the [MiST core](https://github.com/nippur72/Laser500_MiST) this port is based on, laser500emu and laser500-wav.
- Bonstra: Laser 500 documentation (ROM, I/O ports, floppy).
- MAME (vtech2 driver, Juergen Buchmueller and others).
- The MC6847 font used by the tape overlay comes from MAME's m6847 via the PC-6001 core.
