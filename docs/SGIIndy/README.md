# SGI Indy for MiSTer

An FPGA recreation of the **Silicon Graphics Indy** (IP24) workstation for the
[MiSTer](https://github.com/MiSTer-devel/Wiki_MiSTer/wiki) platform. It runs
SGI's own boot PROM and **IRIX 5.3**: the Indigo Magic desktop, X11, and IRIS GL
programs drawn by a reimplementation of the Newport (XL) graphics board.

## What works

| | |
|---|---|
| **PROM** | SGI PROM Monitor 5.3 (IP24): the graphical System Maintenance Menu, the Command Monitor, `hinv`, booting from disk and CD |
| **IRIX 5.3** | boots to multi-user and the graphical login in about 90 seconds; installs from the IRIX 5.3 CD onto a blank disk image - see [Installing IRIX](docs/installing-irix.md) |
| **Desktop** | X11 and the Indigo Magic desktop (4Dwm, the Toolchest, file manager, Console), keyboard and mouse |
| **Graphics** | Newport with REX3, VC2, two XMAP9s, two CMAPs and the Bt445 RAMDAC, 24 bitplanes (`gfxinfo`: NG1 revision 4, REX3 revision B). X drawing, the IRIS GL demos (`ep`, `bongo`) and the xlock screen savers |
| **CPU** | MIPS R4600 at 50 MHz with its FPU, 16 KB instruction and 16 KB data caches |
| **Memory** | 32, 48 or 64 MB |
| **Storage** | the WD33C93 SCSI controller with two disks (SCSI IDs 1 and 2) and a CD-ROM drive (SCSI ID 6), all as image files on the SD card |
| **Clock** | the Dallas DS1386 real-time clock, set from the MiSTer's clock at every start |

### Not there yet

- **Networking**: IRIX sees `ec0` but there is no Ethernet behind it, so it
  reports `no carrier`.
- **Sound**: the HAL2 audio processor is not implemented. The core tells the
  PROM and IRIX there is no audio hardware, and nothing reaches the MiSTer's
  audio output.
- **Saved PROM settings**: the PROM's environment (`setenv`) is not kept when
  the core is reloaded. The defaults boot from the disk at SCSI ID 1, which is
  all IRIX needs.
- **Speed**: the CPU has no second-level cache and its memory is the DE10-Nano's
  DDR3 behind the HPS bridge, so IRIX runs noticeably slower than a real Indy.
  GL animation is slow, and the display is refreshed internally at about 27 Hz
  (the MiSTer scaler converts it to your HDMI mode).
- Parallel port, ISDN, video capture (VINO) and IndyCam are not implemented.

### Known bug

**A disk read can rarely come back with two bytes wrong.** Installing IRIX from
the CD, `inst`'s checksums catch exactly one file with the last 32-bit word of a
disk block half overwritten, the same way every time; the CD image is proven
good. Until it is fixed, keep a backup copy of your disk image.

## Requirements

- A DE10-Nano (MiSTer). **No SDRAM module is needed** - the core uses only the
  board's DDR3.
- A USB keyboard and mouse.
- A disk image with IRIX 5.3 on it, or the IRIX 5.3 CD image to install one.

## Installing the core

Copy two files from [`releases/`](releases/) onto the MiSTer's SD card:

```
releases/SGIIndy_<date>.rbf   ->  /media/fat/_Computer/SGIIndy_<date>.rbf
releases/boot.rom             ->  /media/fat/games/SGIIndy/boot.rom
```

**Create `games/SGIIndy` yourself, and spell it exactly that way.** MiSTer does
not create the folder, and it finds the PROM by that name. Without `boot.rom`
the machine has no firmware and the screen stays dark, with no error anywhere.
`boot.rom` is SGI's IP24 PROM, version 5.3 (`ip24prom.070-9101-011`); the core
loads it automatically at every start, and **Load PROM** in the OSD replaces it
by hand.

Disk and CD images go in the same folder, `/media/fat/games/SGIIndy/`.

## Getting IRIX running

[docs/installing-irix.md](docs/installing-irix.md) walks through both ways:

- **Install from the CD**: an empty disk image at SCSI ID 1, the IRIX 5.3 CD
  image at SCSI ID 6, and the PROM's *Install System Software*. The guide covers
  partitioning the empty disk with `fx`, what `inst` asks, and the first boot.
- **Bring an installed disk**: any raw image of an Indy system disk with IRIX
  5.3, for example one installed under an emulator. MAME's `.chd` files have to
  be converted to a raw image first.

Then mount the system disk at **SCSI ID 1** and choose *Start System*, or just
wait: the PROM boots it on its own.

## OSD options

| Option | |
|---|---|
| **Load PROM** | load a different boot PROM image; `boot.rom` is loaded automatically at start |
| **SCSI ID1** | the system disk. A raw disk image (`.img`); IRIX boots from this ID |
| **SCSI ID2** | a second disk |
| **SCSI ID6 CD** | the CD-ROM drive: an ISO image of an SGI CD (`.iso`) |
| **Graphics board** | *Fitted* (Newport) or *None*. With *None* the PROM and IRIX use the serial console on the MiSTer's UART pins |
| **Primary caches** | *On*; *Off* runs uncached and is only useful for debugging |
| **Memory** | 48, 32 or 64 MB |
| **Video debug** | *Raw index* shows the frame buffer's colour indices without the palette |
| **UART debug** | test patterns on the UART pins, for checking a serial cable |
| **SCSI cache** | *On* caches disk blocks in the FPGA, which makes disk access much faster |
| **Aspect ratio** | how the scaler fits the picture |
| **Reset** | resets the machine. Shut IRIX down first - see below |

The SCSI slots are remembered: whatever is mounted is mounted again the next
time the core starts.

## Using IRIX

- **Shut down before you reset or leave the core.** IRIX keeps filesystem
  changes in memory; use *System > Shut Down* from the Toolchest, or type
  `init 0` as root, and wait for the PROM menu. A reset in the middle of a
  session can leave the root filesystem needing a long `fsck` on the next boot.
- **Back up your disk image.** Keep a copy of a freshly installed image; it is
  the quickest way back from a damaged filesystem.
- The display is 1280x1024; the MiSTer scaler fits it to your screen.
- The keyboard and mouse are MiSTer's USB devices, presented to IRIX as the
  Indy's PS/2 keyboard and mouse.

## Building from source

**The FPGA.** Quartus Prime Lite **17.0.2**, the standard MiSTer flow: open
`sgiindy.qpf` and compile, or run

```sh
bash scripts/build.sh
```

(Quartus is looked for in `C:\intelFPGA_lite\17.0`; set `QUARTUS_BIN` in
`scripts/local.env`, copied from `scripts/local.env.sample`, for anywhere
else.) It runs synthesis, fit, assembly and timing analysis and leaves
`output_files/sgiindy.rbf`. Quartus compiles the CPU's VHDL directly. The
project's fitter seed is the one the released bitstream met timing with. The
core's version in the MiSTer menu is the build date, and the date is part of
the logic, so a build made on another day is a new fit that has to meet
timing on its own: check `reports/summary.md`.
`SEED=1 BUILD_DATE=260918 bash scripts/build.sh` rebuilds the released
bitstream bit for bit.

**The build report.** `scripts/build.sh` finishes by writing
[`reports/`](reports/summary.md): device use, the timing slack of every clock in
every check, and the logic used by each block of the machine, for the bitstream
it just built. It is committed with each release, so the report for the
bitstream in `releases/` is always in [`reports/summary.md`](reports/summary.md).

**Simulation.** The machine and each of its blocks run under Verilator 5 - the
PROM booting to its menu, the graphics engine against a model of the real chip,
the SCSI, DMA, cache and memory paths. The CPU's VHDL is lowered to Verilog for
Verilator with GHDL's synthesis plugin (`tools/gen_r4300_verilog.sh`), and the
bare-metal tests need a big-endian MIPS cross compiler.
[`tests/README.md`](tests/README.md) lists every test and what it proves, and
[`docs/reference/simulation.md`](docs/reference/simulation.md) describes the
harness.

## Documentation

[`docs/README.md`](docs/README.md) is the index: the address map, the chipset,
the CPU, the boot PROM, the MiSTer integration, and the design notes on how each
part of the machine was built and verified.

## Credits

- The MiSTer framework and core template: the
  [MiSTer-devel](https://github.com/MiSTer-devel) project.
- The CPU: the MIPS core of the MiSTer
  [Killer Instinct](https://github.com/MiSTer-devel/Arcade-KillerInstinct_MiSTer)
  arcade core, itself derived from the [N64](https://github.com/MiSTer-devel/N64_MiSTer)
  core's R4300i. `rtl/cpu/r4300/UPSTREAM.md` records every local change.
- The SCSI target from the MiSTer MacLC core, and the SCSI block cache from the
  MacQuadra800 core.
- The DE1-based SGI reverse-engineering work this core grew out of: OzOnE.
- IRIS, the SGI Indy emulator, used throughout as the reference model and as the
  source of the bare-metal MIPS CPU test suite.
- MAME's `indy_indigo2` driver, as a further reference.

## Licence

**GPL-3.0** - see [`LICENSE`](LICENSE) and [`NOTICE.md`](NOTICE.md), which also
lists the third-party code in this repository and its origins.

`releases/boot.rom` and `roms/IP24_Indy/` hold SGI's boot PROM. It is SGI's
copyrighted firmware and is **not** covered by this repository's licence; see
[`NOTICE.md`](NOTICE.md).
