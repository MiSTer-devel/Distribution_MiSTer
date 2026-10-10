# Apple /// for MiSTer

__Warning: This core is vibe coded.__

A complete [Apple ///](https://en.wikipedia.org/wiki/Apple_III) core, and a very
usable one: most software tried so far runs well.

## Features

- Apple /// or Apple /// Plus, with the Plus's DELETE key and 560 × 384
  interlaced text
- 256 or 128 KiB of RAM, mapped as on Apple's two memory boards, or 512 KiB
  as on ON THREE's board, using the SDRAM module
  ([details](docs/MEMORY_MAP.md))
- Every native video mode, and the Apple II modes for Apple II emulation
- Character-set changes and mid-screen updates display as on real hardware
- RGB, color composite with Apple II artifact color, or monochrome composite
- Monitor presets: clean RGB, Monitor /// green, amber or a color TV
- NTSC or PAL, Apple's 50 Hz "Euro system"
- MiSTer's aspect ratios, integer scaling and scandoubler effects, with weave
  or bob deinterlacing for interlaced text
- Four floppy drives, each with its own write protection
  ([details](docs/FOUR_DRIVES.md))
- WOZ, DSK, DO, PO, NIB and 2MG images, writable and formattable
- Copy-protected originals boot from plain sector dumps
- Two hard-disk drives for your own images, bootable with the built-in
  soshdboot ROM ([details](docs/BLOCK_STORAGE.md))
- Apple's ProFile interface card, for the stock `.PROFILE` driver and its
  pseudo-DMA ([details](docs/PROFILE.md))
- Apple's mouse card, driven by the MiSTer's mouse
- Your choice of card in each of the four slots ([details](docs/SLOTS.md))
- The real keyboard's auto-repeat and Solid Apple speed-up
- Two joysticks, each with its button and latching switch
- Speaker and 6-bit DAC sound
- Clock set from the MiSTer's time
- Serial port on the MiSTer's UART, which can [call a BBS or host a
  mailbox](docs/BBS.md)
- Apple's boot ROM built in, or load another from the OSD

For something to play, [apple-iii-games](https://github.com/jakesjews/apple-iii-games)
has native Apple /// games as ready-to-mount disk images.

## Setup

1. Update MiSTer, so its Main has the Apple III disk support.
2. Copy the core's latest `.rbf` file in `releases/` to `/media/fat/_Computer/`.
3. Put disk images in `/media/fat/games/Apple-III/`, launch the core, and pick
   a boot disk with **Mount Drive 1**. **Mount Drive 2–4** are the external
   drives. The hard-disk cards' disks show in the OSD while a slot holds the
   card.
4. If SOS lists only two drives, raise its drive count to four with the System
   Configuration Program ([how](docs/FOUR_DRIVES.md)).

## Disk images

- **Floppies:** WOZ, DSK, DO, PO, NIB and 2MG, writable. Flux WOZ,
  write-protected WOZ and zipped images are read-only.
- **Hard disks:** PO, HDV and ProDOS-order 2MG, written in place.
- Copy-protected originals boot from plain sector dumps.
- A2R flux captures: export them to WOZ with the free
  [Applesauce client](https://applesaucefdc.com/software/), which needs no
  Applesauce hardware.

[Details](docs/MAIN_STORAGE.md).

### Running BOS

Put the Washington Apple Pi disks `bos-01a` in **Drive 1** and `bos-01b` in
**Drive 2**, and a `/BOS` hard disk on **ProFile Disk 1**. To make one from
[apple3rtr](https://github.com/datajerk/apple3rtr)'s `apple3.hd`, run MAME's
`chdman` (`.\chdman` in PowerShell on Windows):

```sh
chdman extracthd -i apple3.hd -o bos.hdv -isb 512 -ib 16776704
```

The two options keep only its first partition, /BOS, and skip the block of
IDE drive data in front of it.

apple3rtr's `bosboot.dsk` won't boot here; it is for a CFFA2 card.

## Controls

| Key | Action |
|---|---|
| F2 | Apple /// RESET key (NMI) |
| Ctrl + F2 | CONTROL-RESET (hardware reset) |
| Windows / Command | Open Apple |
| Alt | Solid Apple |
| Caps Lock | Alpha Lock |
| Del | Keypad period, or DELETE with the /// Plus keymap |

Keys repeat as on the real keyboard, Solid Apple speed-up included
([details](docs/DESIGN.md#keyboard)). Controller 1 is joystick 0 and
controller 2 the other port. Button 1 is the pushbutton, and button 2 flips
the latching switch ([details](docs/DESIGN.md#joysticks-and-ad-converter)).

## Options

The OSD's first page has the drives, the hard disks, **Model** and **Video**.
**System & ROM**, **Scaling & Filters** and **Hardware** hold the rest.

| Option | |
|---|---|
| **Model** | Apple /// or /// Plus, with DELETE and **Text Interlace** ([details](docs/INTERLACE.md)) |
| **Video**, **Display** | RGB, color or mono composite, and the monitor on a composite output ([details](docs/VIDEO_SOURCES.md)) |
| **Memory** | 256K, 128K, or ON THREE's 512K with an SDRAM module; `releases/SOS512K.po` updates a disk for 512K ([details](docs/EXTERNAL_MEMORY.md)) |
| **Video Standard** | NTSC or PAL, Apple's 50 Hz Euro system ([details](docs/PAL.md)) |
| **Boot ROM** | Apple's, or soshdboot to boot **Block Disk 1** ([details](docs/BLOCK_STORAGE.md)) |
| **Slot 1–4** | The card in each slot; the block card in 1 and a ProFile in 4 as shipped ([details](docs/SLOTS.md)) |
| **Mouse Speed** | How far the MiSTer's mouse moves the mouse card's ([details](docs/MOUSE.md)) |
| **Joystick 1 on** | Moves controller 1 from port B to port A |
| **Serial CTS**, **DSR**, **DCD** | Leave at the defaults unless the host does flow control ([details](docs/DEVELOPMENT.md#serial-port)) |
| **Aspect ratio**, **Scale** | MiSTer's usual ratios and integer scaling |

Memory, Boot ROM and the slots take effect at the next reset.

## Building and simulation

Apple's ROMs are not included: put MAME's `apple3.rom`, `341-0270-c.4b` and
`341-0269.2b` (or `apple3.zip` and `a2mouse.zip`) in `roms/` and run
`make roms` ([details](docs/DEVELOPMENT.md#building)). Then open
`Apple-III.qpf` in Quartus Prime 17.0 and compile, or run
`./build.sh compile` on a Mac with Quartus under CrossOver. The simulation needs
Icarus Verilog, Verilator 5, GHDL and cc65:

```sh
make check-tools                  # lists what is missing and how to install it
make test                         # every test that needs no disk image, about ten minutes
make boot DISK=system.woz ARGS=--to-menu   # boot SOS in the simulator
```

Booting SOS needs a WOZ disk image.
[Details](docs/DEVELOPMENT.md#testing).

## Todo

Existing partial implementations are noted where they provide a starting point.

- [ ] **Microsoft SoftCard III.**

- [ ] **Titan III+IIe.** Add support for this expansion.

- [ ] **Save States**

[Development](docs/DEVELOPMENT.md) · [Hardware design](docs/DESIGN.md) ·
[Disk validation](docs/DISK_FIDELITY_2026-09-16.md) · [License](LICENSE)

## Credits

This core stands on work from the MiSTer and Apple /// communities:

- **sorgelig** for the MiSTer framework and Main, the floppy track cache and
  the Apple II MiSTer core the disk integration follows.
- **alanswx** for the WOZ drive and media implementation from Apple-II_MiSTer
  (see its [provenance and license](rtl/disk/woz/README.md)), and for the
  Apple-family disk codec and DSK support in Main that the Apple III support
  extends.
- **Newsdee** for Main's Apple II WOZ support and floppy fixes, which the
  Apple III support builds on.
- **Stephen A. Edwards** for the Disk II drive model from his Apple II FPGA and
  for his article on the Apple II clock generator.
- **gyurco** for the 6551 UART core, Disk II write support, his T65 fixes and
  the Apple II core's mouse card, whose wiring this one follows.
- **jotego** for the jt6805 microcontroller core and **John E. Kent** for the
  6821 PIA (see their [provenance and license](rtl/cards/mouse/README.md)).
- **GideonZ** for the 6522 VIA.
- **Daniel Wallner, MikeJ, WoS and Morten Leikvoll** for the T65 6502 core.
- **harbaum** for the HPS I/O interface the MiSTer framework grew from.
- **robjustice** for the ca65 transcription of the boot ROM listing, the
  Problock3 driver and soshdboot ROM the block card runs, A3Driverutil and his
  Apple /// write-ups.
- **steven-a-wilson** and the **AppleWin** team for the ProDOS hard-disk
  interface the block card's registers follow.
- **paulhagstrom** for `diskhero`, whose commented source documents the display
  modes, character download and extended addressing on real hardware.
- **ThorstenBr** for the Apple /// custom ROM and Disk II interface
  documentation.
- **BBCNewBrain** for the Apple /// keyboard encoder replacement project, which
  documents the key matrix.
- **Patrick Schaefer** for decoding the motherboard logic PROMs.
- **John Jeppson** for his 1982 and 1983 Softalk articles on the Apple ///
  memory system.
- **npwoods, rb6502 and the MAME team** for the `apple3` driver, MOS 6551,
  CFFA and mouse card models used as cross-checks.
- **Klaus2m5** for the 6502 functional test suite.
- **Applesauce** for the WOZ format reference.
- The **AppleCommander** team for the disk-image tool behind the block-card
  test media.
- **wizzomafizzo** for Zaparoo, which drives the keystrokes and screenshots in
  the hardware tests.
- **david-schmidt** for apple3.org, and the bitsavers, Asimov and
  vintagecomputer.ca archives for the manuals, schematics and PROM dumps.

Imported components retain their own license notices, including the
GPL-3.0-or-later [WOZ implementation](rtl/disk/woz/README.md) and
[mouse card parts](rtl/cards/mouse/README.md), and the GPL-3.0
[soshdboot ROM](rtl/soshdboot/README.md).
