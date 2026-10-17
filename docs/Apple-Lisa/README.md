# Apple Lisa for MiSTer

A hardware-accurate **Apple Lisa** (Lisa 1 / Lisa 2/5) core for the
[MiSTer FPGA](https://github.com/MiSTer-devel/Main_MiSTer/wiki) platform
(DE10‑Nano / Cyclone V).

This is a port of **[alexthecat123's LisaFPGA](https://github.com/alexthecat123/LisaFPGA)**
— an incredible chip‑for‑chip Lisa recreation originally built for a custom
Xilinx Artix‑7 board — to the MiSTer framework. **All of the credit for the Lisa
core itself goes to Alex**; this repository adapts that work to run on MiSTer
hardware (Quartus / Cyclone V, MiSTer video/audio/HPS I/O, and SDRAM). For the
original standalone board and its detailed documentation, see
[alexthecat123's LisaFPGA repo](https://github.com/alexthecat123/LisaFPGA).

The core simulates the real Lisa hardware: the Motorola 68000 (fx68k), the
6504 + COP421 I/O and keyboard microcontrollers, the 6522 VIAs, the Z8530 SCC,
the AM9512 FPU, the MMU, and the video state machine.

---

## Quick start

1. Copy `Apple-Lisa.rbf` to `/media/fat/_Computer/` (or wherever you keep cores)
   on your MiSTer SD card.
2. Put ProFile hard‑disk images under `/media/fat/games/Apple-Lisa/`.
3. Launch the core. It powers on automatically and boots from the mounted
   ProFile.

### Powering on and off — please read

The Lisa has a **soft power button**, and so does this core:

- **Press `F11` to turn the Lisa on or off.**
- When you're done, **always power the Lisa off with `F11` before you quit the
  core or switch away.** This performs the Lisa's normal orderly shutdown, which
  flushes and parks the ProFile. If you just yank the core (reset / hard
  power‑off) while the OS is running, **you risk corrupting your disk image**,
  exactly like pulling the plug on a real Lisa.

A clean `F11` shutdown also means you won't get the "the startup disk was in use
when the Lisa failed" disk‑check dialog on the next boot.

### Mounting a ProFile disk

ProFile images live in `/media/fat/games/Apple-Lisa/` and are
**532‑byte‑per‑block** raw images (e.g. `profile.img` = 9728 × 532 bytes). Mount
one from the OSD (`Mount Hard Disk`), or auto‑mount at launch with an `.mgl` file:

```xml
<mistergamedescription>
	<rbf>Apple-Lisa</rbf>
	<file delay="2" type="s" index="0" path="games/Apple-Lisa/Lisa Office System 3.0.img"/>
</mistergamedescription>
```

### Mounting a floppy disk (Sony 400K)

The core emulates the Lisa's internal **Sony 400K 3.5″ floppy drive** (slot `S1`,
`Mount Floppy` in the OSD). **Both reading and writing work** — you can boot from
a floppy and save documents to one from the Office System desktop; writes are
flushed back to the disk image on the SD card.

Floppy images are standard **DiskCopy 4.2** (`.dc42`) 400 KB images. **Important —
rename `.dc42` to `.dc4`:** MiSTer's file browser matches three‑character
extensions, so a `.dc42` file will *not* appear in the `Mount Floppy` list.
Rename (or copy) it to `.dc4` and it shows up; `.dsk` and `.img` floppy images
also work. (Auto‑mounting a `.dc42` by explicit path in an `.mgl` file still
works — the extension filter only affects the OSD browser.)

To save to a floppy from the desktop it must already be in Lisa Office System
format — **formatting/initializing a blank floppy in the core does not work yet**
(see `FLOPPY_HANDOFF.md`). Mount an already‑formatted disk and drag documents
onto it. As with the ProFile, let the drive settle after a save and power down
cleanly with `F11`: a sector written immediately before an abrupt eject may not
be flushed.

### OSD options

- **RAM Size** — 512 KB / 1 MB / 1.5 MB / 2 MB. **Note:** the Lisa needs at least
  1 MB for the Office System; 512 KB is only useful for the boot ROM diagnostics.
- **CPU Speed** — 1× (the real ~5 MHz Lisa), 2×, or 3×. The Lisa was famously
  under‑powered, so 2×/3× make the Office System far more pleasant. (4× was
  removed — the memory cycle is one clock too short to be reliable.)
- **Aspect Ratio / Scale** — standard MiSTer scaler options for the Lisa's
  720×364 display.
- **CPU ROM / I/O ROM** — select ROM revisions.
- **Screen Color** — paper‑white, green, or amber CRT emulation.

### Keyboard & mouse

- USB keyboard and mouse work directly through MiSTer's HPS.
- The host **Alt** key maps to the Lisa **Apple/⌘** key.
- **Caps Lock** lights the Caps Lock LED on your USB keyboard when it's engaged
  on the Lisa.
- `F11` = power button (see above). `F12` = MiSTer OSD.

### Serial ports & terminal software

Both of the Lisa's serial ports (Serial A and Serial B, driven by the Z8530 SCC)
are bridged to the MiSTer **UART**, so terminal programs such as **LisaTerminal**,
and serial tools under the Workshop, can talk to the outside world.

- **Baud** is selectable in the OSD (**Serial speed**): 19200 / 9600 / 4800 /
  2400 / 1200 / 300. **It must match the baud you set in the Lisa software** — if
  the two differ you get garbage or repeated characters. On the Lisa itself,
  19200 is only available on **Serial B** (Serial A's baud clock tops out lower);
  LisaTerminal will point this out, so Serial B is the usual choice.
- The MiSTer **UART mode** selects what the host side is connected to — a login
  console, a modem/telnet bridge, MIDI, etc. — the standard MiSTer UART options.
- Both Lisa ports share the single MiSTer UART, so you can't actively transmit on
  Serial A and Serial B at the same time (fine for normal single‑terminal use).

### Video output

HDMI always shows the scaled, standard‑timing picture. The **analog VGA** output
mirrors that same scaled signal (the Lisa's native ~22.75 kHz horizontal rate is
below what a VGA monitor can lock to, so the raw raster can't be sent directly).

### Clock / calendar

The core seeds the Lisa's COP real‑time clock from your MiSTer's clock at
power‑on. Because the Lisa's clock format only spans 16 years (1980–1995), the
**year reads 1994 for 2026**, etc. — this is inherent to the Lisa hardware; the
month, day and time are correct.

---

## Status

Working: boots the Lisa Office System to the desktop with clean, stable 720×364
video on **HDMI and analog VGA**; keyboard and mouse; ProFile hard‑disk
emulation; **Sony 400K floppy read and write**; **Z8530 serial ports (LisaTerminal
etc.)**; SDRAM; 1×/2×/3× CPU speeds; auto power‑on and `F11` soft power‑off.

Not yet working: **formatting / initializing a blank floppy** inside the core
(mount an already‑formatted disk to read or write it).

See `progress_quartus_handover.md`, `FLOPPY_HANDOFF.md`, and `todo.md` for the
detailed engineering log and open items.

---

## Credits

- **[alexthecat123](https://github.com/alexthecat123/LisaFPGA)** — the entire
  Apple Lisa FPGA core, ROM handling, ProFile /
  [ESProFile](https://github.com/alexthecat123/ESProFile) emulation, and the
  original hardware design. This project would not exist without that work.
- **[fx68k](https://github.com/ijor/fx68k)** by Jorge Cwik — cycle‑accurate 68000.
- The **T400 / COP421** and **6502** cores, and the **6522**, **Z8530**, and
  **AM9512** implementations used by the Lisa core.
- The **[MiSTer](https://github.com/MiSTer-devel/Main_MiSTer)** project and its
  framework (`sys/`, hps_io, ascal scaler) by Sorgelig and contributors, plus
  Sorgelig's SDRAM controller.

## License

Follows the licensing of the upstream LisaFPGA project and the individual cores
it incorporates (see their repositories). Apple Lisa ROMs and disk images are
the property of their respective owners and are not included here.
