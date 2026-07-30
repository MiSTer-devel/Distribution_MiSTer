# Apple IIGS for MiSTer

This repository contains a Verilog recreation of the Apple IIGS computer for the MiSTer FPGA platform. It is based on the SNES VHDL 65C816 core and has been heavily optimized for hardware simulation accuracy, compatibility, and cycle-exact timing by studying Clemens, KEGS, MAME, and real Apple IIGS hardware.

## Core Features

- **65C816 CPU & Turbo Acceleration**:
  - Emulates the 65C816 microprocessor at a cycle-exact stock speed of 2.86 MHz (includes correct RAM refresh cycle delays of ~8% in RAM, and full-speed 2.86 MHz execution from ROM).
  - Integrated **ZipGS Accelerator** emulation with support for ZipGS software register unlocks ($C058–$C05F).
  - Selectable CPU Speeds via OSD: 2.8 MHz (Stock), 3.6 MHz, 4.8 MHz, 7.2 MHz, and 14.3 MHz (hardware-validated up to 14.3 MHz with write back-pressure, cache write-forwarding, and clock_divider fast-escape gates).
  - ZipGS registers can be disabled in the OSD for a pure stock IIgs configuration while maintaining the host-only turbo option.
  - Cycle-exact memory path using the custom `sdram_burst` ch3 single-word read channel to prevent cache stalls at 2.8 MHz (fixing audio/visual timing issues in highly-optimized demos).
  - Speed-regulating IWM (Integrated Woz Machine) hold-off logic: accessing floppy registers ($C0E0–$C0EF) drops the speed to native for ~2ms, ensuring reliable floppy disk write/read operations when CPU is accelerated.
- **System Memory**:
  - 128KB fast motherboard RAM (Banks $00–$01).
  - Dynamic expansion memory support from 256KB up to 4MB/8MB fast RAM.
  - 128KB slow RAM (Banks $E0–$E1) with customizable Shadow Register ($C035) control.
- **Display & Video Graphics Controller (VGC)**:
  - Cycle-exact Video Graphics Controller (VGC) and Mega II display subsystem.
  - Emulates all Apple II/IIgs video modes:
    - Text (40 & 80 column modes).
    - Low-Res (GR) & Double Low-Res.
    - Hi-Res (HGR) & Double Hi-Res (DHR) graphics.
    - Super Hi-Res (SHR) graphics (320x200 & 640x200 modes, up to 16 colors per line from 16 customizable palettes of 256 colors).
  - Cycle-exact Floating Bus ("vaporlock") implementation for legacy software compatibility.
  - Color-accurate 16-color Double Hi-Res (DHR) decoding with AppleColor RGB decode, honoring the NEWVIDEO[5] monochrome toggle.
  - Fixed horizontal first-byte truncation for pixel-perfect Double Hi-Res rendering.
  - PAL (50Hz) and NTSC (60Hz) display standard support (PAL scanline timings selected via LANGSEL register bit 4).
  - Adjustable aspect ratio via OSD (Original 4:3 vs. Full Screen).
- **Audio Subsystem**:
  - Stereo audio output.
  - Accurate emulation of the Ensoniq ES5503 Digital Oscillator Chip (DOC) sound generator with 32 oscillators and 64KB dedicated sound RAM.
  - Implements oscillator accumulation logic to prevent channel loss or volume reduction.
  - Mixed speaker toggle support (classic click sound) scaled dynamically with master volume controls.
- **Input & Peripherals**:
  - Apple Desktop Bus (ADB) controller simulation supporting keyboard and mouse.
  - Caps Lock LED feedback to physical/host keyboard LEDs.
  - Flexible game port joystick/gamepad controller mapping (Fire 1, 2, 3 and A|P, B, Y layouts) via OSD.
  - RS-232/UART serial communication ports.
- **System Configuration**:
  - Dynamically selectable ROM versions (ROM Version 1 vs. ROM Version 3) via the OSD menu, triggering a clean automatic cold reset on change.
  - Warm Reset (F11 / Ctrl+Reset) and Cold Reset (Ctrl+OpenApple+Reset) support.

## Disk Drive Support & File Formats

The core emulates the standard Apple IIgs disk subsystem, supporting three distinct types of disk interfaces across the core's expansion slots:

### 1. Apple IIe-Style ProDOS Hard Disks (Slot 7)
* **OSD Mapping**: `S0` (HDD Unit 0 / Drive 1) and `S1` (HDD Unit 1 / Drive 2).
* **Purpose**: High-capacity mass storage for running large operating systems like GS/OS and game collections (e.g., Total Replay).
* **Supported File Formats**:
  * **`.hdv`**: Raw ProDOS hard drive images.
  * **`.po`**: ProDOS-ordered disk images.
  * **`.2mg`**: 2IMG disk images containing ProDOS filesystem data.
* **Key Features**:
  * Emulates a legacy Apple IIe-style ProDOS/AppleWin block device interface card.
  * Auto-boots on startup through the system's expansion slot boot ROM scan sequence ($C700–$C7FF).
  * Does not require a reset after mounting to boot.
  * Supports full read and write operations, executing commands (Read/Write/Status) via registers `$C0F0–$C0F8` and performing DMA block transfers directly to system memory.

### 2. 3.5" Floppy Drives (Slot 5)
* **OSD Mapping**: `S2` (3.5" Floppy Drive 1).
* **Supported File Formats**:
  * **`.woz`**: WOZ 1.x and 2.x flux-level disk images (recommended for maximum accuracy and copy-protected titles).
  * **`.po`**: ProDOS-ordered disk images.
  * **`.2mg`**: 2IMG disk images.
* **Key Features**:
  * Full read and write support.
  * Emulates the Apple 3.5" drive's internal microcontroller, supporting the SmartPort protocol over the IWM bus (using registers `$C0EC`/`$C0ED` and REQ/BSY handshaking).
  * Emulates variable track layout bit-densities across five speed groups (e.g., 75,136 bits for outer tracks down to 51,200 bits for inner tracks).
  * Supports write-protect SENSE status detection.
  * Speed-regulating IWM access throttle: accessing Slot 5 register range `$C0E0–$C0EF` automatically drops the CPU speed to native speed to prevent write timing issues even when the core is accelerated.
  * Saves modified BRAM track data back to the SD card dynamically on track seek or disk unmount.

### 3. 5.25" Floppy Drives (Slot 6)
* **OSD Mapping**: `S3` (5.25" Floppy Drive 1).
* **Supported File Formats**:
  * **`.woz`**: WOZ 1.x and 2.x flux-level disk images (supports complex copy-protection, half-tracking, and weak bits).
  * **`.dsk` / `.do`**: Sector-level disk images.
  * **`.po`**: ProDOS-ordered disk images.
  * **`.nib`**: 140KB raw track nibble images.
  * **`.2mg`**: 2IMG disk images.
* **Key Features**:
  * Full read and write support.
  * Emulates head positioning, stepper motor phase transitions, and track writes using block RAM (BRAM).
  * Hardware-level support for half-tracks (`track_id = qtrack - 2` logic) and weak bits to ensure compatibility with classic protected software (such as *Lode Runner*).
  * Saves modified track data back to the SD card on track seek or disk unmount.

## Keyboard Mappings

* **F11** / **Ctrl+F11** - Reset (Warm)
* **Ctrl+OpenApple+F11** - Cold Reset
* **Left/Right Alt** - Open Apple / Command
* **Windows/Menu** - Solid Apple / Option

## ROM Generation

Apple's ROM cannot be redistributed, so it is not included here — you must supply
your own. **This step is required before building the core or the simulator:** the
RTL reads the character ROM at elaboration time, so neither Quartus nor Verilator
will build until you have run it.

1. Obtain the `apple2gs.zip` MAME ROM package (0.286 or compatible).
2. Place it in the `roms/` directory.
3. Run:

```bash
cd roms
make
```

This produces four files, none of which are committed to the repository:

| File | Purpose |
|------|---------|
| `vsim/boot.rom` | ROM Version 3 (256K) — the default |
| `vsim/boot1.rom` | ROM Version 1 (128K) |
| `chr.mem` | Character ROM, read by `rtl/vgc.v` (Quartus resolves it from the repo root) |
| `vsim/chr.mem` | The same character ROM (Verilator resolves it from `vsim/`) |

To run on real hardware, place `boot.rom` and/or `boot1.rom` on the root of your
MiSTer SD card or in `/media/fat/games/Apple-IIgs/`. You can switch between ROM
versions dynamically using the MiSTer OSD menu.

## Installing on MiSTer

Copy from [`releases/`](releases/) to your SD card:

| File | Destination |
|------|-------------|
| `Apple-IIgs_<date>.rbf` | `/media/fat/_Computer/` |
| `Apple-IIgs.RAM` | `/media/fat/games/Apple-IIgs/` |

...along with the `boot.rom` / `boot1.rom` you generated above.

### Saving settings (PRAM / NVRAM)

The IIgs keeps its control-panel settings in battery-backed PRAM. To persist
them across reboots, mount `Apple-IIgs.RAM` via **System → PRAM NVRAM** in the
OSD; it is then remounted automatically on later runs. Use **Save NVRAM** to
write your settings and **Load NVRAM** to restore them.

MiSTer does not create this file for you, which is why a blank one ships in
`releases/`. It is 1024 bytes — two 512-byte blocks, because ROM1 and ROM3 use
incompatible PRAM layouts and each gets its own block. A zero-filled file is
expected: the ROM's PRAM checksum fails on a blank block and the firmware simply
re-defaults itself, so a fresh file cannot brick anything.

## Development & Simulation

The core can be simulated with Verilator. Build and run it from the `vsim/`
directory (the relative paths in the RTL depend on that being the working
directory), after generating the ROMs as described above:

```bash
cd vsim
make
./obj_dir/Vemu            # ROM3 (default)
./obj_dir/Vemu --rom 1    # ROM1
```

Run `./obj_dir/Vemu --help` for the full option list, including disk mounting,
screenshots, and scripted keyboard/mouse input.

`vsim/regression.sh` boots a set of known-good disk images and compares the
resulting frames against the golden screenshots in `vsim/regression_images/`.
Note that the disk images it needs are not distributed with this repository.

See `CLAUDE.md` for build commands, simulation run parameters, keyboard/mouse
input injection, and the optional `DEBUG_*` tracing macros.

## Credits & Contributors

This Apple IIGS core is the result of dedicated collaboration and builds upon excellent prior artwork, emulator codebases, and hardware simulation research.

### Core Developers & Contributors
* **Pierre Cornier** ([@pcornier](https://github.com/pcornier))
* **Steven A. Wilson** ([@steven-a-wilson](https://github.com/steven-a-wilson))
* **Alan Steremberg** ([@alanswx](https://github.com/alanswx))
* **Frank Bruno** ([@fbruno](https://github.com/fbruno))
* **Jim Gregory** ([@jimmystones](https://github.com/jimmystones)) — Debugger support and enhancements

### Reference Software Emulators
We are deeply grateful to the authors and maintainers of the following emulators, whose implementations, research, and source code served as invaluable references for achieving cycle-exact accuracy:
* **[Clemens IIGS](https://github.com/samkusin/clemens_iigs)** by Sam Kusin — Modern Apple IIgs emulator providing a robust reference backend and debugger.
* **[KEGS (Kent's Emulated GS)](http://kegs.sourceforge.net/)** by Kent Dickey — The gold standard, cycle-accurate reference for Apple IIgs emulation.
* **[GSplus](https://github.com/digarok/gsplus)** by digarok & the GSplus community — Modernized cross-platform fork of KEGS.
* **[GSSquared](https://github.com/jawaidbazyar2/gssquared)** by Jawaid Bazyar — Cross-platform emulator covering both 8-bit and 16-bit Apple II architectures.
* **[MAME](https://github.com/mamedev/mame)** by the MAMEdev team — Detailed driver reference for Apple IIGS hardware components.
* **[AppleWin](https://github.com/AppleWin/AppleWin)** by the AppleWin team — Reference implementation for legacy Apple IIe-style disk controllers.

### Test Suites & Diagnostics
* **[SingleStepTests 65816 CPU Tests](https://github.com/SingleStepTests/65816)** by Tom Harte & the SingleStepTests community — JSON-based single-step instruction tests used to verify cycle-accurate CPU behavior.
* **FloatBus Vaporlock Test** by arekkusu — A sophisticated test harness that captures the floating bus scanout state to validate cycle-exact Mega II and video synchronization.

### Demos & Vaporlock Software
We thank the authors of the classic and modern demos whose hardware-pushing tricks set the bar for this core's cycle accuracy:
* **TextFunk** (Jason Andersen "TextFunk Viewer", 2018) — A highly demanding beam-racing demo that reads video registers at precise scanline alignments.
* **FTA (Free Tools Association)** — Developers of iconic Apple IIGS demos (such as *Nucleus*) whose advanced display, timing, and audio tricks served as essential compatibility targets.

### Hardware & Core Foundations
* **[SNES VHDL 65C816 CPU Core](https://github.com/MiSTer-devel/SNES_MiSTer)** by [srg320](https://github.com/srg320) — The foundational VHDL 65C816 microprocessor implementation upon which this Apple IIGS core's CPU was adapted.

## License

This core is released under the **GNU General Public License v3.0 or later**.
See [LICENSE](LICENSE) for the full text.

It incorporates GPL-licensed work from several upstream projects, which is what
fixes the license at GPLv3:

| Component | Origin | License |
|-----------|--------|---------|
| `sys/` | MiSTer framework (Alexey Melnikov, Till Harbaum) | GPL-2.0+ / GPL-3.0+ |
| `rtl/65C816/` | [SNES_MiSTer](https://github.com/MiSTer-devel/SNES_MiSTer) 65C816 by srg320, converted to SystemVerilog | GPL-3.0+ |
| `rtl/scc8530.v` | minimigmac SCC, substantially reworked for the IIgs | GPL-3.0+ |
| `rtl/sdram*.sv` | Sorgelig | GPL-3.0+ |
| `rtl/uart/` | Gisselquist Technology | GPL-3.0 |
| `rtl/hdd.v`, `rtl/roms/hdd.a65` | AppleWin HDD controller | GPL-2.0+ |

The Verilator simulator in `vsim/` additionally bundles Dear ImGui, ImPlot,
ImGuiFileDialog and dirent (MIT), fmt (MIT), stb_image_write (public domain),
and the Verilator runtime (LGPL-3.0 / Artistic-2.0). These are simulation-only
and are not part of the FPGA core.

**No Apple ROM content is distributed with this repository.** You supply your
own; see [ROM Generation](#rom-generation).
