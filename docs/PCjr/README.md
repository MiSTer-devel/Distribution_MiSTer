# IBM PCjr for MiSTer FPGA

IBM PCjr core for [MiSTer FPGA](https://mister-devel.github.io/MkDocs_MiSTer/) by [@spark2k06](https://github.com/spark2k06/).

Discussion and evolution of the core in the MiSTer FPGA forum:

https://misterfpga.org/viewforum.php?f=40

![Splash](splash.jpg)

## Overview

This repository targets the IBM PCjr, not the Tandy 1000 line.

The core is built around the [MCL86 core](https://github.com/MicroCoreLabs/Projects/tree/master/MCL86) from [@MicroCoreLabs](https://github.com/MicroCoreLabs/) and [KFPC-XT](https://github.com/kitune-san/KFPC-XT) from [@kitune-san](https://github.com/kitune-san), with PCjr-specific video, memory, cartridge, keyboard and peripheral behaviour added on top.

## Current status

Implemented and relevant today:

* IBM PCjr BIOS boot flow
* PCjr/Tandy graphics modes with PCjr-specific fixes
* Configurable system RAM from 128 KB to 640 KB
* Cartridge support through two `JRC` slots
* Floppy support through BIOS-compatible disk images
* PC speaker and PCjr 3-voice audio mixing
* Composite video simulation and alternate display palettes
* PCjr keyboard and joystick support
* Cassette `SAVE` audio through the PC speaker path

Present in the OSD but not currently active for loading:

* `Cassette Tape (JRT)`
* `Tape sound`

These cassette-related OSD entries are intentionally shown as shaded/disabled. Cassette loading is pending a future PCjr-specific implementation.

## OSD features

The current OSD exposes these relevant PCjr options:

* `PCjr BIOS`
* `Cartridge 1 (JRC)`
* `Cartridge 2 (JRC)`
* `Cassette Tape (JRT)` shaded
* `RAM Size`
* `Boot Splash Screen`
* `Write Protect`
* `Speaker Volume`
* `PCjr Volume`
* `Tape sound` shaded
* `Audio Boost`
* `Stereo Mix`
* `CRT H offset`
* `CRT V offset`
* `VSync Width`
* `HSync Width`
* `Scandoubler Fx`
* `Aspect ratio`
* `Border`
* `Composite video`
* `Display`
* `Joystick 1`
* `Joystick 2`
* `Sync Joy to CPU Speed`
* `Swap Joysticks`

## Media support

### BIOS

The main PCjr BIOS is loaded from the OSD:

* `System & BIOS -> PCjr BIOS`

The BIOS file is expected as a ROM image provided by the user. Original IBM ROMs are copyrighted and are not distributed with this repository.

Alternative BIOS projects may work depending on compatibility, but the primary target is original PCjr BIOS behaviour.

### Cartridge

Two cartridge slots are available in the OSD:

* `Cartridge 1 (JRC)`
* `Cartridge 2 (JRC)`

Current cartridge handling is designed around JRC images loaded from the OSD. Each slot maps independently into the PCjr cartridge area. After changing cartridge images, a full core restart is required for the new cartridge state to take effect; a simple reset is not enough.

### Floppy

Floppy `IMG/IMA/VFD` mounting is available from the main media slot in the OSD.

Practical notes:

* BIOS compatibility still matters for accepted image formats and geometry
* Using disk images that match what the loaded BIOS expects is recommended
* Preformatted images are safest when working with unusual sizes

### Cassette

The OSD currently shows a cassette media slot using the `JRT` extension.

Current state:

* Cassette `SAVE` activity is routed to audible output through the PC speaker path
* Cassette `LOAD` is not enabled yet
* Cassette OSD entries remain visible but shaded so the intended UI path is preserved for future work

## Audio

The core currently mixes:

* PC speaker
* PCjr 3-voice sound
* Cassette `SAVE` waveform audio when save activity is present

`Tape sound` remains visible in the OSD only as a placeholder for future cassette loading support.

## Video

The core includes PCjr-oriented video behaviour rather than a generic CGA/Tandy port.

Relevant exposed options include:

* Composite video enable/disable
* Scandoubler effects
* Aspect ratio
* Border enable/disable
* Palette/display mode selection
* CRT H/V offsets
* VSync/HSync width controls

Recent video work in the repository also includes a dedicated CGA scandoubler path intended to be safer for UM6845R-sensitive software.

## Input and peripherals

* PCjr keyboard path
* Joystick 1 and 2 configuration:
  * Analog
  * Digital
  * Disabled
* Joystick swap option
* CPU-synchronised joystick timing option

The core also contains UART/serial plumbing used internally by the platform integration, but that is not currently a primary user-facing feature of this README.

## Quick start

1. Copy the core to your MiSTer setup in the usual way.
2. Launch the core from the computers section.
3. Open the OSD.
4. Load a PCjr BIOS in `System & BIOS -> PCjr BIOS`.
5. Optionally load one or two `JRC` cartridge images.
6. Optionally mount a floppy image.
7. Use `Reset & apply settings` after changing latched hardware options such as RAM size.

Suggested first-run checks:

* Confirm BIOS boots correctly
* Confirm floppy access works with a BIOS-compatible image
* Confirm cartridges mount correctly if used
* Confirm cassette-related options are visible but shaded

## Build notes

This README reflects the current production-facing state of the core:

* IBM PCjr system identity
* Cartridge and floppy support available
* Cassette `SAVE` audio available
* Cassette `LOAD` still pending

## Developers

Contributions and pull requests should be prepared against the appropriate development branch before being reviewed and merged.

