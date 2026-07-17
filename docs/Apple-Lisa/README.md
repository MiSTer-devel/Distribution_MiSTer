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

1. Copy `Lisa.rbf` to `/media/fat/_Computer/` (or wherever you keep cores) on
   your MiSTer SD card.
2. Put ProFile hard‑disk images under `/media/fat/games/LISA/`.
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

ProFile images live in `/media/fat/games/LISA/` and are **532‑byte‑per‑block**
raw images (e.g. `profile.img` = 9728 × 532 bytes). Mount one from the OSD
(`Hard Disk` menu item), or auto‑mount at launch with an `.mgl` file:

```xml
<mistergamedescription>
	<rbf>Lisa</rbf>
	<file delay="2" type="s" index="0" path="games/LISA/Lisa Office System 3.0.img"/>
</mistergamedescription>
```

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

### Clock / calendar

The core seeds the Lisa's COP real‑time clock from your MiSTer's clock at
power‑on. Because the Lisa's clock format only spans 16 years (1980–1995), the
**year reads 1994 for 2026**, etc. — this is inherent to the Lisa hardware; the
month, day and time are correct.

---

## Status

Working: boots the Lisa Office System to the desktop with clean, stable 720×364
video; keyboard and mouse; ProFile hard‑disk emulation; SDRAM; 1×/2×/3× CPU
speeds; auto power‑on and `F11` soft power‑off.

See `progress_quartus_handover.md` and `todo.md` for the detailed engineering
log and open items.

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
