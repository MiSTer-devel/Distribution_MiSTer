# Soyuz-Neon PK-11/16 for MiSTer

[Soyuz-Neon PK-11/16](https://ru.wikipedia.org/wiki/%D0%A1%D0%BE%D1%8E%D0%B7-%D0%9D%D0%B5%D0%BE%D0%BD_%D0%9F%D0%9A-11/16)
is a Soviet computer of 1991 on the N1806VM2, a PDP-11 compatible CPU
(the K1801VM2 family, as in the UKNC and the DVK), with up to 4 MB of RAM
behind a page dispatcher, a display-list video controller (832 x 300,
up to 8 bits a pixel from a 16-bit palette), two floppy drives, an MFM
hard disk and an 8-bit I/O block of Intel-compatible chips.  About 200
were made.  It runs RT-11 with the machine's own window system.

The core follows the [NeonBTL](https://github.com/nzeemin/neonbtl)
emulator by Nikita Zimin (its
[user manual](https://github.com/nzeemin/neonbtl/blob/master/docs/user-manual-en.md)
describes the machine and its software); the CPU is the K1801VM2 core
from [1801BM1/cpu11](https://github.com/1801BM1/cpu11); the framework is
the MiSTer [Template](https://github.com/MiSTer-devel/Template_MiSTer).

## Status

The firmware boots, RT-11 boots from a floppy image or from the hard
disk; the window system, games, music and demo programs run.

* CPU at 8 MHz, the memory dispatcher with its HR/UR registers, the
  emulated-register trap area, the 16 KB firmware ROM (built in; a
  `boot.rom` in `games/Neon` replaces it).
* RAM on the SDRAM board: 512 KB, 1, 2 or 4 MB from the OSD, with the
  2 and 4 bits-per-pixel write masking.
* Video: the display list with all the modes NeonBTL renders, 15 kHz
  output; the scaler takes it as it is, `forced_scandoubler=1` in
  `MiSTer.ini` doubles it to 31 kHz.
* Interrupt controller, the two sound timers (three-voice beeper),
  keyboard (PS/2, mapped as in NeonBTL), mouse, real-time clock from the
  MiSTer's clock.
* Two floppy drives on `.dsk` images (800 KB: 80 tracks, 2 sides, 10
  sectors of 512 bytes), read and write.
* The MFM hard disk (KM1809VG7, a WD1010) on an `.img` image, see below.
* Not yet: the serial port, the printer.  The IDE port that NeonBTL
  emulates at 161120 is not fitted; the firmware does not use it.

## Prior work

[UNEON](https://github.com/xolod79/UNEON) by xolod79 is an earlier FPGA
implementation of the Soyuz-Neon for MiST, MiSTer, Terasic DE1 and Tang
Nano 20K, published as binaries since January 2024 and built on the
1801VM2 reverse engineering and the open Soyuz-Neon replica project.  His
reports to [1801BM1/cpu11](https://github.com/1801BM1/cpu11/issues?q=is%3Aissue+vm2)
(the interrupt acknowledge timeout vector, the frozen PSW/PC copies on
user-mode interrupts) led to fixes in the K1801VM2 core this one uses.
This core is an independent, open implementation after the NeonBTL
emulator.

## Software

Put the images in `games/Neon` on the SD card.  The OSD mounts floppy
images as FD0/FD1 and a hard disk image; `boot.vhd`, `boot1.vhd` and
`boot2.vhd` in that folder are mounted automatically when the core starts,
as FD0, FD1 and the hard disk.

A ready set of images (system and demo floppies, a hard disk image with
a system and the software below on its partitions) is in
[software](https://github.com/MiSTer-devel/Neon_MiSTer/tree/master/software) folder of this
repository; unpack it into `games/Neon`.

Floppy images are 819200-byte `.dsk` files.  Sources:

* The [PK11_NEON section](https://archive.pdp-11.org.ru/vid/PK11_NEON/)
  of the pdp-11.org.ru archive: `SouzNeon_pk_11_16.rar` (system disks),
  `TheGWBV.rar` (system, demo, games, utilities, the Aspect window system
  documentation and the machine's technical description),
  `SFROLOV_neon_disk.rar` (music players, documentation, utility sources),
  `pk11_souz_neon_otherPO.rar`, `PK11system_Manwe_MonaLiza.rar`.  The
  archives are RAR; `unar` opens them.
* The [NeonBTL releases](https://github.com/nzeemin/neonbtl/releases)
  come with system and demo disks.

A system disk boots to RT-11 with the window system (`STARTS.COM` loads
the processes).  Programs of interest: `TETRIS`, `MINE`, `PICT`, `CALCUN`
(games disk), `DEMO` with its `.SND` music and `.ATR` pictures (demo
disk), `STM` and `SPLAY` music players (Frolov's disks).

## Hard disk

The firmware boots from the hard disk when no floppy is in FD0, and RT-11
reaches it through its `HD` handler as partitions `HD0:`..`HD7:`.  The core
serves an image of 4 heads by 18 sectors a cylinder laid out as the
machine's formatter (`HARD.SAV`) does it: image sector 0 is the home block
with the partition table (the sector the formatter numbers 255 on
cylinder 0), then the cylinders; the sectors of partition *p* are numbered
32*p* + 0..17.  `tools/mkhd.py` makes an empty image with a partition
table (`tools/mkhd.py neon.img`, on the `dev` branch); `neon_empty.img`
in the release archive is such an image.

To put a system on it, mount it, boot RT-11 from a floppy and copy:

    COPY/DEVICE FD0: HD0:
    COPY/BOOT HD0:RT11SJ.SYS HD0:

A floppy image may also be written straight into a partition of the image
file: partition *p* starts at byte 512 x (1 + 85 x 72 x *p*) of the default
layout.  With no floppy in FD0 the firmware then boots from `HD0:`.  The
formatter's own FORMAT commands are accepted and ignored.

The window system's games need their processes loaded first, e.g. for
TETRIS from the games disk: `PRUN KBD.PRC`, `PRUN SNC.PRC`, `INST SN`,
`RUN TETRIS` (`TETRIS.COM` does this when the disk is `SY:`).

## Keyboard

| PC              | Neon        |
|-----------------|-------------|
| F1-F5           | К1-К5       |
| F6, F7, F8      | ПОМ УСТ ИСП |
| Delete, End, Page Down | ПОМ УСТ ИСП (as well) |
| F11, Insert     | СБРОС       |
| F12, Home       | СТОП        |
| Esc             | АР2         |
| Backspace       | ЗБ          |
| Tab             | ТАБ         |
| Enter           | ВВОД        |
| Left Shift      | НР          |
| Left Ctrl       | УПР         |
| Right Shift     | АЛФ         |
| Right Ctrl      | ГРАФ        |
| '               | @           |

## Building

Quartus 17.0 or later: open `Neon.qpf` and compile; `releases/` holds
the built cores.  Building with the Verilog macro `NEON_DEBUG_OVERLAY`
draws a bus-trace overlay over the picture (see the comment in `Neon.sv`),
which a MiSTer screenshot captures for hardware debugging.

## Development

The `dev` branch adds `sim/`, a Verilator model of the core (`make` there,
then `sim/obj_dir/Vsim_top FRAMES EVERY [options]` from a directory with
an `rtl/` link runs the machine, writes frames as PPM files, mounts images
and types commands; the options are listed in `sim/sim_main.cpp` and
`sim/monitor.sv`), and `tools/mkhd.py`, which makes hard disk images.

## Licences

* The framework (`sys/`) and this core's own files: GPL v2 or later, see `LICENSE`.
* `rtl/vm2/`: K1801VM2 by 1801BM1, CC BY 3.0.
* `rtl/vm_reset.v`: from tang-uknc, MIT.
* `rtl/rom/pk11_rom.hex`: the machine's firmware, from NeonBTL.
