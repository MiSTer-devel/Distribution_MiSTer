# SunSparcStation20_MiSTer

A Sun **SPARCstation 20** (sun4m) for the MiSTer FPGA, written from
scratch in SystemVerilog: SuperSPARC-compatible CPUs, the sun4m chipset,
SCSI disks and CD-ROM, Ethernet, the TCX frame buffer, Sun keyboard and
mouse, and CS4231 audio. Licensed GPL-2.0-or-later.

**Requires the MiSTer SDRAM module.**

> **Please test the video.** The frame buffer has just moved from the
> DDR3 to the SDRAM module. Report anything wrong on screen: garbage,
> wrong colours, a black screen, slow drawing. Say which PROM and OS
> you used (console text, CDE/X, NeXTSTEP) and which SDRAM module you
> have.

## Features

- Two SuperSPARC (TMS390Z50) CPU modules at 55 MHz, SMP: integer unit,
  IEEE single/double FPU, SRMMU, 20 KB I-cache and 16 KB D-cache with
  bus snooping.
- 64, 128, 256 or 464 MB of memory.
- Boots OpenBIOS (a matching `boot.rom` is in `releases/`) or Sun's own
  OBP 2.25 (not included), as `boot.rom` or through Load ROM.
- SCSI (ESP + DMA2): two hard disks and a CD-ROM, with CD audio.
- Ethernet (LANCE) through the MiSTer's network.
- TCX frame buffer: 1024x768, 8-bit, hardware cursor, blit and stipple
  acceleration. Or the console on the serial port.
- Sun Type 5 keyboard (layouts, Alt/Win swap) with bell and click; Sun
  mouse.
- CS4231 audio.
- Serial port A on the MiSTer's UART.
- NVRAM and clock (M48T08), saved to an image file; the IDPROM
  (Ethernet address, hostid) from the MiSTer's ID. Without an image the
  Sun PROM starts with its defaults and boots the disk, with no full POST.
- OSD in the computer cores' layout.

## Tested

- NetBSD 11: disk, install CD, network, audio; the MP kernel on both
  CPUs under the Sun PROM.
- Solaris 8: disk, CDE, both CPUs, network, audio; under both PROMs.
- NeXTSTEP 3.3: installs and runs the Workspace; under both PROMs.
- Sun OBP 2.25: the POST on both CPUs, the network, audio and CD tests.
- CD audio.
- The CPU and chipset test suite (`tests/cpu`): 84 pass, 0 fail, 5 skip.
- 30-minute stress runs under Solaris, both PROMs.

## Limitations

- At most 464 MB of memory.
- CPUs at 55 MHz with no external cache (no SuperCache/MXCC).
- One frame buffer: the TCX, 8-bit only (no 24-bit TCX, cgsix or SX).
- No floppy drive, no parallel port device, no ISDN (DBRI) audio.
- Sun's OBP is not included: the default boot rom is openbios, or supply your own SS20 PROM image.
- The network and CD audio need a current Main_MiSTer (Sun support
  merged 2026-10-06/07).

## Known issues

- The clock does not take the MiSTer's time.
- Under OpenBIOS, white shows pale yellow; Solaris's text console after
  X exits is white on white.
- `psrinfo` reports 40 MHz under the Sun PROM (its own estimate).
- Under OpenBIOS, NetBSD's MP kernel does not start the second CPU.
- NeXTSTEP's GUI needs the console on the screen and keyboard.

What is next: [docs/VERILOG-PLAN.md](docs/VERILOG-PLAN.md).

## Install

1. Copy the rbf from `releases/` (`SunSparcStation20_20261019.rbf`) to
   the SD card's `_Unstable/` (or `_Computer/`).
2. Copy `releases/boot.rom` (OpenBIOS) to
   `games/SunSparcStation/boot.rom`, or use Sun's own PROM there instead.
   The core needs this OpenBIOS (built from `bios/`): older ones list all
   memory in one `/memory` entry, and Solaris 8 panics early.
3. Put disk images in `games/SunSparcStation/` and mount them from the
   OSD: Pri. disk is SCSI target 3, CD-ROM target 6.
   [docs/disk-images.md](docs/disk-images.md) says how to make them.
4. Give the core its own video mode in `MiSTer.ini` (a 720p output
   shrinks 1024x768 and drops pixel columns from Sun's fonts):

   ```ini
   [SunSparcStation]
   video_mode=1        ; 1024x768@60: the picture 1:1
   ```

   (or, on a 1080p TV, `video_mode=8` with `vscale_mode=1`: integer
   scaling, 1024x768 with borders).

## The OSD

The menu follows the computer cores' OSD standard (hp9000-715_MiSTer
`docs/osd-standard.md`). Disks, the CD, Load ROM and the Input page act
at once; every other setting waits for **Apply and reset** (or any other
reset), and "Changes pending" shows until then.

```
SunSparcStation
  Pri. disk (ID 3)     <- the disk the PROM boots by default
  Disk (ID 1)
  CD-ROM (ID 6)
  Load ROM             <- this session only; a normal start loads boot.rom
  Memory               464MB, 256MB, 128MB, 64MB
  Network interface    eth0, None, eth1, macvlan, tap0
  Video     (P2)       Display (Graphics / Serial console), Aspect ratio, Scale
  Input     (P3)       Keyboard layout, Swap Alt/Win keys
  Advanced  (P5)       Autoboot, NVRAM image
   Changes pending
  Apply and reset
```

`Pri.` names the default: the PROM's `boot-device` (NVRAM) can boot
another disk, the CD or the network. Load ROM is not remembered, so an
MGL can start the core with another ROM (Sun's OBP, the CPU suite) without
changing the default:

```xml
<mistergamedescription>
  <rbf>_Unstable/SunSparcStation20</rbf>
  <file delay="1" type="f" index="0" path="../../../../games/SunSparcStation/obp225.rom"/>
</mistergamedescription>
```

To make another ROM the default, copy it to
`games/SunSparcStation/boot.rom`.

### The NVRAM image (P5)

The NVRAM holds the PROM's settings (`printenv`/`setenv`), the IDPROM
(the Ethernet address and hostid) and the clock. Without an image in the
NVRAM slot it lives only until the core is loaded again; with an 8 KB
image file (any name, `.nvr`) the core loads it at start-up and writes
every change back, so `setenv` sticks.

- **No image, or a new blank file**: the core gives it an IDPROM (from
  the MiSTer's ID, or 08:00:20:12:34:56) and the Sun OBP 2.25's defaults
  (`auto-boot? true`, `boot-device disk`, `diag-switch? false`, the
  console on the keyboard and screen), so the Sun PROM starts at once:
  it tests 1 MB of memory (`selftest-#megs`) and boots the disk. A blank
  file is filled in and saved at its first load. Make one with
  `dd if=/dev/zero of=sun.nvr bs=8192 count=1`, or with the options
  already set: `tools/obp_nvram.py --new sun.nvr output-device=ttya`.
- **The two PROMs keep different formats.** OpenBIOS reads the Sun
  format as unformatted ("nvram error detected"), uses its own defaults
  and overwrites the image only at its first `setenv`. The Sun OBP reads
  an OpenBIOS image (`tools/mknvram.py`) as a bad checksum: it then sets
  its defaults with `diag-switch? true`, which runs the full POST and a
  test of all of memory (minutes at 464 MB) and boots the network, at
  every start until `setenv diag-switch? false`. Keep one image per PROM.

## What is here

| Path | What |
|---|---|
| `rtl/cpu/` | the CPU module: `iu` (pipeline) and its parts, `fpu` (`fp_unpack`, `fp_round`, `fp_divsqrt`), `srmmu`, `l1cache`, `cpu_module` (+ benches in `tb/`) |
| `rtl/machine/` | the machine: `ss20_machine` (NCPU modules, default 2), `ss20_mbus`, `ss20_memctl`, `ss20_iobridge`, `ss20_loader`, `ss20_uart`, `ss20_osd`, `vram_sdram` |
| `rtl/obio/` | the sun4m system devices: `slavio_timer`, `slavio_intctl`, `slavio_misc`, `m48t08`, `escc` |
| `rtl/sun4m/` | the SBus and on-board devices: `ss20_msi` (IOMMU), `emc`, `dma2`, `esp` + `scsi_targets`, `lance`, `tcx`, `cs4231` (+ APC), `fdc82077`, `sun_kbd`, `sun_mouse`, `kbd_beep`; the FCode PROMs `tcx_fcode`, `cs4231_fcode`, `slote_fcode` |
| `rtl/mister/` | the MiSTer side: `ddram_arb`, `sdram64`, `eth_hps`, `nvram_sd` |
| `rtl/pkg/`, `rtl/lib/`, `rtl/video/` | packages, RAM templates, the hang reporter, video timing |
| `rtl/tb/` | `run.sh`: lint every module and run every block bench under Verilator |
| `sim/` | Verilator harnesses: the whole machine (`build.sh`, `sim_main.cpp`, `run-*.sh`), the CPU module (`sim/cpu/`), the IU (`sim/iu/`) |
| `tests/cpu/`, `tests/fpu/` | the bare-metal SPARC V8 / sun4m suite that runs as the boot PROM, with QEMU references; FPU vectors |
| `syn/` | a Quartus fit of the CPU module alone, for timing work |
| `scripts/` | build, deploy, board regression (`hwtest.sh`, `board/`) |
| `tools/` | ROM analysis (`romdis/`), FCode, NVRAM, CD-audio, UFS, NeXTSTEP, UnixBench and MiSTer tools |
| `docs/` | the plan ([VERILOG-PLAN.md](docs/VERILOG-PLAN.md)), the architecture (`arch/`), our analysis of the SS20 and SS5 PROMs (`rom-disassembly/`, no Sun code), benchmarks, the reference index |
| `bios/` | OpenBIOS and fcode-utils; `scripts/build-bios.sh` builds the boot ROM |
| `sys/` | the Template_MiSTer framework, unchanged |
| `releases/` | the release: the rbf and the OpenBIOS `boot.rom` it needs |

Not here, on purpose: Sun PROM images and anything reproduced from them.

## Building

- The core: Quartus 17.0.2 Lite, `scripts/build.sh 20` (output in
  `output_files/`).
- OpenBIOS: `scripts/build-bios.sh` (a SPARC cross GCC and `xsltproc`).
- Benches: `rtl/tb/run.sh` (Verilator 5); the CPU suite in simulation:
  `sim/cpu/run.sh`; the whole machine: `sim/build.sh` and
  [sim/README.md](sim/README.md).

## Thank you

A big thank you to **Grabulosaure**, whose SPARCstation work on FPGA
inspired us to write this core.

## Credits

- **OpenBIOS** (`bios/openbios/`) and **fcode-utils** (`bios/fcode-utils/`):
  the OpenBIOS project, with the sparc32 port for FPGA SPARCstations
  (`CONFIG_TACUS`) by Grabulosaure, which we extend for this machine.
- **The TCX FCode PROM** (`rtl/sun4m/tcx_fcode.sv`): the image QEMU ships
  (`pc-bios/QEMU,tcx.bin`), built from OpenBIOS's `drivers/tcx.fs`.
- **Template_MiSTer** (`sys/`): the MiSTer project (Sorgelig and
  contributors).
- **Wish7990** (`rtl/sun4m/wish7990_*.sv`, `rtl/pkg/wish7990_pkg.sv`):
  MelkhiorVintageComputing, the Am7990 LANCE core.

## License

GPL version 2 ([LICENSE](LICENSE)); our own files are GPL-2.0-or-later.

The one exception is **Wish7990**, under the MIT license
([rtl/sun4m/LICENSE.wish7990](rtl/sun4m/LICENSE.wish7990)), which is
compatible with the GPL.

Sun's PROM images are Sun/Oracle copyright and are never committed.
