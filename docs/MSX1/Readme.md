# MSX (MSX1/MSX2/MSX2+/turbo R) for [MiSTer Board](https://github.com/MiSTer-devel/Main_MiSTer/wiki)

**English** | [Česky](Readme.cs.md)

> [!CAUTION]
> **WIP Notice**: This core is currently in **WIP (Work in Progress)** status. Some components are still under development and may include debug outputs or experimental features. Certain functionalities may not yet work 100% as intended. See [Known limitations](#known-limitations).

## Core Overview
The core (MiSTer name `MSX`, folder `games/MSX`) is not a direct synthesis of a specific MSX computer model. Instead, it provides a **dynamically configurable hardware environment** that is built at run time from a selected definition (a *ROM PACK*). Each machine definition includes not only the hardware setup but also the corresponding **ROM binary content.** The core can run:

- **MSX1** machines (TMS9918 family VDP),
- **MSX2** machines (Yamaha V9938, RTC, memory mapper),
- **MSX2+** machines (Yamaha V9958 with the YJK colour modes and horizontal scrolling; Panasonic, Sanyo, Sony and the CIEL Expert Turbo; Kanji ROM, MSX-MUSIC and the 5.37 / 7.16 MHz turbo where the machine has them),
- the **MSX turbo R** Panasonic FS-A1ST and FS-A1GT (V9958, S1990, R800 mode – see [Known limitations](#known-limitations) for its speed),
- the **1chipMSX** (OCM-PLD style, MSX2+ class, V9958), which loads its BIOS from an SD card image.

For full functionality, the core also relies on an **extension module configuration** (the *FW PACK*), which includes additional ROM binaries. It is **independent of any specific MSX model**, allowing support for:
- Multiple language variants (via localized ROMs)
- Easy future expansion with new hardware extensions

The third configuration file is a **CRC32-based ROM database** (the *DB MAPPERS*), which maps known ROM checksums to their correct mapper types. This allows the core to automatically select the appropriate ROM mapper for each loaded image.

## Supported MSX Models
**[Supported MSX models](ComputersModel.md)** – 227 machine definitions from 36 manufacturers:

| Generation | Machines |
|---|---|
| MSX1 | 135 (124 with a TMS99xx VDP, 11 with a V9938 and an MSX1 BIOS) |
| MSX2 | 80 |
| MSX2+ | 9 |
| MSX turbo R | 2 (Panasonic FS-A1ST, FS-A1GT) |
| 1chipMSX / OCM (MSX2+ class) | 1 |

Seven openMSX machines are not supported yet: six need hardware the core does not have, the Aucnet NIA-2001 only lacks its definition; they are listed at the end of the model list. The ROM dumps of the machines are not part of this repository; see [Getting started](#getting-started).

## Getting Started
The core needs **at least a machine pack** (ROM PACK). Everything else depends on what you want to run. Put the files on the MiSTer SD card into `/media/fat/games/MSX/`:

| File | Needed? | Notes |
|---|---|---|
| Machine pack `<model>.msx` | **Yes** | Nothing runs without it. Built from the machine ROMs with `createComp.py`. The C-BIOS machines (MSX, MSX2) and the 1chipMSX can be built without commercial ROMs, their ROMs are part of the repository. |
| FW pack `CART_FW_EN.msx` or `CART_FW_JP.msx` | For **any cartridge** | Needed for every cartridge type, **including a plain ROM**. It holds the ROMs of the cartridges (FM-PAC BIOS, `GM2.ROM`, `VY0010.ROM`, `mfrsd.ROM`, `yrw801.rom`, ...). Built with `createDev.py`. The EN and JP packs differ only in the FM-PAC ROM. A cartridge whose ROM is missing in the pack is left out of it. |
| Mapper database `vampier.db` | Optional | Needed for ROMs larger than 64 KB and for ROMs on a special mapper. A ROM up to 64 KB runs as plain ROM without it. Ready-made file: `tools/CreateCRC/vampier.db`. |
| ROM images `.ROM`, disk images `.DSK`, tape images `.CAS` | Optional | `.DSK` must be a raw image of 720K, 640K, 360K or 320K. |
| SD card image `.VHD` | 1chipMSX: yes | FAT16 **with a partition table** and `OCM-BIOS.DAT` as the first file. Optional for the MegaFlashROM SCC+ SD cartridge. |

Then load the packs in the OSD (**Load ROM PACK**, **Load FW PACK**, **Load DB MAPPERS**). MiSTer **remembers these three files and loads them again automatically at the next core start**; ROM cartridges, disks and tapes are not remembered. Every load rebuilds the whole machine.

Coming from the core under its former name `MSX1`: move `games/MSX1` to `games/MSX` and `saves/MSX1` to `saves/MSX`, then load the three packs once more. The OSD settings start from their defaults.

How to build the packs and the database:
- [Tools overview](tools/README.md)
- [CreateMSXpack – building the ROM PACK and FW PACK](tools/CreateMSXpack/README.md)
- Developers (machine XML format, adding devices): [DEVELOPERS.md](tools/CreateMSXpack/DEVELOPERS.md)

In short: install **Python 3**, put the ROM binaries into the `ROM` directory of `tools/CreateMSXpack` or pass another folder with `--rom-dir` (files are matched by SHA1, names do not matter), then run `python3 createComp.py` (machines) and `python3 createDev.py` (cartridges); `--help` lists the options. The `.msx` files appear in `MSX/`.

### Without the SDRAM module

The core also runs **without the SDRAM add-on board**, but only for smaller configurations. It has 256 KB of memory inside the FPGA. Everything the machine needs is stored there first: its ROMs, its RAM, then the cartridges in slots A and B. Only what does not fit goes to the SDRAM.

**Works without SDRAM:**
- **189 of the 227 machines**: almost all MSX1 machines and most MSX2 machines with 64 or 128 KB of RAM (e.g. Philips VG 8020, NMS 8245/8250, VG 8235, Sony HB-F1, HB-F9P).
- Cartridges, as long as they fit into the rest of the 256 KB. The rest is about **160 KB** on a typical MSX1 (64 KB RAM) and about **64 KB** on a typical MSX2 (128 KB RAM). A cartridge takes the size of its ROM, plus its SRAM or RAM: FM-PAC 72 KB, Game Master 2 136 KB, SCC+ 128 KB.

**Needs SDRAM:**
- These 38 machines (a Kanji ROM, 256 KB or more of RAM, or large built-in software):
  - MSX1: National FS-4000, Sony HB-11, Al Alamiah AX230
  - MSX2: Daewoo CPC-400S, Hitachi MB-H70, Mitsubishi ML-G30 (both models), National FS-4500, FS-4600F, FS-4700F, FS-5000F2, FS-5500F1, FS-5500F2, Panasonic FS-A1F, Al Alamiah AX370, Sony HB-F700D/F/P/S, HB-F900, HB-G900AP, HB-T600, Yamaha AX350II, AX350IIF, AX500, YIS-805/256
  - MSX2+: Panasonic FS-A1FX, FS-A1WX, FS-A1WSX, Sanyo PHC-35J, PHC-70FD, PHC-70FD2, Sony HB-F1XDJ, HB-F1XV, CIEL Expert Turbo
  - MSX turbo R: Panasonic FS-A1ST, FS-A1GT; and the 1chipMSX
- MoonSound, MegaFlashROM SCC+ SD, ASCII16-X, Konami Ultimate Collection, Yamanooto, MegaRAM and MegaSCC.
- Any ROM cartridge bigger than the free space: most MegaROM games on an MSX2, ROMs of 256 KB and more on any machine.

**What happens when it does not fit:** loading stops with **SMALL MEMORY** in the OSD and the core stays in reset. Load a smaller machine or cartridge, or fit the SDRAM board. The core knows the SDRAM size from the MiSTer menu core, which checks the module at start. If the core is started without the menu (unusual), it does not know the size and does not check. A configuration that does not fit then reads garbage above 256 KB.

With SDRAM, a 32 MB module is enough. The largest machine (1chipMSX) needs about 8 MB, a MoonSound 4 MB, an ASCII16-X, Konami Ultimate Collection or Yamanooto 8 MB. Only two ROMs of 16 MB each would not fit (SMALL MEMORY).

## OSD Features

| OSD item | Notes |
|---|---|
| Load ROM PACK (`.MSX`) | The machine pack. Remembered and loaded at core start. |
| Load FW PACK (`.MSX`) | The cartridge/extension pack. Remembered and loaded at core start. |
| Load DB MAPPERS (`.DB`) | The CRC32 mapper database. Remembered and loaded at core start. Loading it does not reset the machine, it is used by the next ROM load. |
| Mount Drive 1 / 2 (`.DSK`) | Shown according to the number of drives of the machine (or of the FDC cartridge). Two drives only on the Philips NMS 8255. |
| Slot1 / Slot2 | Cartridge type per slot, see [Expansion cartridges](#supported-expansion-cartridges). Changing it reloads the configuration. Not shown on the 1chipMSX, which has its own options. |
| Slot1 / Slot2 ROM Load (`.ROM`) | Shown when the slot is set to ROM. Up to 16 MB. |
| Load SD card (`.VHD`) | 1chipMSX (MegaSD) or MegaFlashROM SCC+ SD in slot 1. |
| Tape Input | File or ADC (analog input of MiSTer). Not shown on the 1chipMSX. |
| Tape Monitor | On (default) / Off: the tape signal is heard in the sound output while the motor runs. Not shown on the 1chipMSX. |
| Cas File (`.CAS`) | Tape image, shown when Tape Input is File. |
| Tape Rewind | Rewinds the tape image. |
| Firmware switch | Off / On, only on machines that have one: turbo R and the Panasonic, National and Sanyo machines with the Matsushita switched I/O. |
| R800 speed | Real (speed of a real R800) / T-states (Z80 cycle counts, one per 21.5 MHz clock) / 10.7MHz (Z80 cycle counts at 10.7 MHz). Shown with the firmware switch, used by the turbo R; takes effect the next time the R800 is switched on. |
| Mouse | Port 1 (default) / Port 2: the joystick port a PS/2 mouse takes over when it moves; a joystick on that port takes it back. |
| MIDI | **User Port**: MT32-pi (default; a [MT32-pi](https://github.com/dwhinham/mt32-pi) or just MIDI OUT on pin 1), MIDI In/Out (MIDI adapter: OUT on pin 1, IN on pin 0), Off. Once a MT32-pi is found, its options appear: Use MT32-pi, Show Info (No / Yes: a message when its mode changes / LCD-On / LCD-Auto: its display in the top left corner of the picture, always or for 3 s after a change), the default Synth (Munt, FluidSynth), Munt ROM, SoundFont, and Reset Hanging Notes. |
| Video | Aspect ratio, scandoubler (None, HQ2x, CRT 25/50/75 %), Vertical Crop, Scale (Normal, V-Integer, Narrower/Wider HV-Integer, HV-Integer), Border (applies to the TMS and V99xx VDP). |
| Pause when OSD open | No (default) / Yes: the machine stops while the OSD is open (CPU held, sound muted, HDMI picture frozen). |
| Reset | Reset of the machine. |
| Reset & Detach ROM Cartridge | Clears the ROM cartridges in both slots and reloads. Not shown on the 1chipMSX. |
| Reset and close OSD | Reset and leave the menu. |
| SRAM Save / SRAM Load | Shown when a cartridge has SRAM, but **they do nothing** (see [Known limitations](#known-limitations)). |

1chipMSX has an extra block: CPU speed (Normal / Turbo, F11 toggles), CPU type (Z80 / R800 – only the R800 multiply instructions), Slot1, Slot2, Internal Mapper (2048 / 4096 KB), Joysticks Swap, Reset after Mount.

### OSD error messages
When a load fails, the OSD info line shows one of these. After any of them the machine does not start: the core stays in reset until the next load (a new pack, ROM or cartridge selection).

| Message | Meaning |
|---|---|
| BAD MSX CONF | The file loaded as ROM PACK is not a machine pack. |
| NOT SUPPORTED CONF | The pack contains an unknown record – the pack and the core versions do not match. |
| NOT SUPPORTED BLOCK | The pack contains an unknown block type – the pack and the core versions do not match. |
| BAD MSX FW CONF | The file loaded as FW PACK is not a FW pack. |
| NOT FW CONF | The FW pack is not loaded but the selected cartridge needs it (every cartridge type, plain ROM included), or a ROM the cartridge needs is missing in the FW pack (e.g. `yrw801.rom` for MoonSound). |
| DEVICE MISSING | The configuration needs more copies of a device than the core contains, e.g. FM-PAC in both slots on a machine with MSX-MUSIC, MoonSound in both slots. |
| Device not in this core build | An FDC cartridge in slot 2, or an FDC position this core build does not have. |
| No CRC32 DB | A ROM larger than 64 KB needs a mapper but no mapper database is loaded. |
| Not find CRC32 in DB | A ROM larger than 64 KB is not in the mapper database. |
| FDC already in machine | Two FDCs in the same position – an error of the machine definition. |
| SMALL MEMORY | The machine with its cartridges needs more memory than there is: without the SDRAM module more than 256 KB (see [Without the SDRAM module](#without-the-sdram-module)), with a 32 or 64 MB module more than its size. |
| ROM too big | The ROM file is larger than 16 MB. |

## Supported Hardware Components
The core includes the following hardware modules:
- `PPI` – [Programmable Peripheral Interface](https://www.msx.org/wiki/Programmable_Peripheral_Interface)
- `RTC` – [Ricoh RP-5C01 Real-Time Clock](https://www.msx.org/wiki/Ricoh_RP-5C01) (time from MiSTer; the CMOS contents are not saved)
- `PSG` – [AY-3-8910 / YM2149 Programmable Sound Generator](https://www.msx.org/wiki/General_Instrument_AY-3-8910)
- `VDP` – [Video Display Processor (TMS family)](https://www.msx.org/wiki/Texas_Instruments_TMS9918), PAL or NTSC per machine definition
- `VDP` – Yamaha [V9938](https://www.msx.org/wiki/Yamaha_V9938) / [V9958](https://www.msx.org/wiki/Yamaha_V9958), 128 KB VRAM
- `CPU` – [Z80](https://www.msx.org/wiki/Z80) at 3.58 MHz with the MSX wait state in every opcode fetch; NMOS or CMOS behaviour by the machine's [MSX-Engine](https://www.msx.org/wiki/MSX-Engine) (the T9769 also with its wait state on the VDP ports); 5.37 MHz turbo of the Panasonic FS-A1FX, FS-A1WX and FS-A1WSX, 7.16 MHz turbo of the CIEL Expert Turbo; R800 mode of the turbo R, see [Known limitations](#known-limitations)
- `MEM_MAPPER` – MSX2 memory mapper
- `KANJI` – [Kanji ROM](https://www.msx.org/wiki/Kanji_ROM) (levels 1 and 2; Hangul variants)
- `FDD` – Floppy Disk Drive emulation on raw `.DSK` images (720K, 640K, 360K, 320K; disk change supported)
- `WD2793` – [Floppy Disk Controller](https://www.msx.org/wiki/Western_Digital_WD2793), read and write including Write Track (format); a write-protected image ignores writes
- `TC8566AF` – Toshiba floppy disk controller of the Panasonic FS-A1F and FS-A1ST, read and write
- `OPLL` – [YM2413](https://www.msx.org/wiki/Yamaha_YM2413), [MSX-MUSIC](https://www.msx.org/wiki/MSX-MUSIC) / [FM-PAC](https://www.msx.org/wiki/FM-PAC)
- `OPM` – [YM2151](https://www.msx.org/wiki/Yamaha_YM2151) (SFG-01) and YM2164 (SFG-05), built into the Yamaha CX5M/CX11 and CX5MII/CX7M/AX200 machines
- `SCC` – [Konami SCC](https://www.msx.org/wiki/Konami_SCC)
- `SCC+` – [Konami 052539 Enhanced SCC](https://www.msx.org/wiki/Konami_052539)
- `OPL4` – [Yamaha YMF278B](https://www.msx.org/wiki/MoonSound) (MoonSound: OPL3 FM and 24 channel wave table synthesis)
- `DAC` – 8-bit DAC of the Konami Synthesizer and of the Konami Ultimate Collection
- `YM2148` – MIDI interface of the Yamaha SFG modules, MIDI IN and MIDI OUT via the MiSTer UART or the user port
- `MSX_MIDI` – [MSX-MIDI](https://www.msx.org/wiki/MSX-MIDI) (i8251 UART + i8254 timer, I/O ports E8h–EFh), MIDI IN and MIDI OUT via the MiSTer UART or the user port
- `SFG01` – [Yamaha SFG-01](https://www.msx.org/wiki/Yamaha_SFG-01)
- `SFG05` – [Yamaha SFG-05](https://www.msx.org/wiki/Yamaha_SFG-05)
- Matsushita switched I/O (Panasonic, National and Sanyo MSX2 / MSX2+): turbo switch, firmware switch, 2 KB firmware SRAM
- S1985 MSX-Engine switched I/O: 16-byte backup RAM, colour / pattern register
- CIEL Expert Turbo: turbo switch
- turbo R: `S1990` system controller (Z80/R800 and ROM/DRAM switch, firmware switch), PCM, Pause key with LEDs, system timer; see [MSX turbo R](https://www.msx.org/wiki/MSX_turbo_R)
- [1chipMSX](https://www.msx.org/wiki/1chipMSX): IPL ROM, switched I/O ports 40-4F, ESE-RAM, MegaSD with SD card (VHD), turbo 3.58 / 5.37 / 10.74 MHz

Not implemented: MSX-AUDIO, V9990 / GFX9000, printer, paddles, light gun, RS-232.

## Supported ROM Mappers
Cartridge ROMs are assigned to a mapper by the CRC32 database (`vampier.db`, built by [tools/CreateCRC](tools/CreateCRC/README.md) from the [romdb.vampier.net](https://romdb.vampier.net/) dump). ROMs not in the database and up to 64 KB are placed as plain ROM (see the first rows).

| Mapper (name in the DB) | Description |
|---|---|
| plain ROM (`0x0000`, `0x4000`, `0x8000`, `Page12`, `Page2`, `Normal`) | ROM placed at that address; also the fallback without a database |
| mirrored ROM (`Mirrored`, `Mirrored0000`, `Mirrored4000`, `Mirrored8000`) | plain ROM mirrored over the address space; the start address of `Mirrored` comes from the ROM header |
| `16kb`, `8kB` | generic 16 KB and generic 8 KB bank switching |
| `Konami` | standard Konami mapper (8 KB banks) |
| `KonamiSCC` | Konami mapper with SCC sound |
| `ASCII8` | ASCII 8 KB mapper |
| `ASCII8SRAM2`, `ASCII8SRAM8` | ASCII 8 KB mapper with 2 / 8 KB SRAM |
| `ASCII16` | ASCII 16 KB mapper |
| `ASCII16SRAM2`, `ASCII16SRAM8` | ASCII 16 KB mapper with 2 / 8 KB SRAM |
| `ASCII16-X` | [ASCII16-X](https://www.grauw.nl/projects/ascii-x/ascii16-x/) mapper with an 8 MB flash ROM (changes are not saved) |
| `KonamiUltimateCollection` | Konami Ultimate Collection: Konami and Konami SCC mapper with an offset register, SCC/SCC+ and a DAC on an 8 MB flash ROM (changes are not saved) |
| `YAMANOOTO` | Yamanooto (Konami Neo-Ultimate Collection): Konami SCC and Konami4 mapper with an offset register, SCC/SCC+ and a second PSG at ports 10h-11h on an 8 MB flash ROM (changes are not saved) |
| `NEO-8`, `NEO-16` | NEO-8 (six 8 KB banks) and NEO-16 (three 16 KB banks) mappers with 12-bit bank numbers, ROMs up to 16 MB |
| `R-Type` | R-Type mapper |
| `Wizardry` | Wizardry (ASCII 8 KB variant with SRAM) |
| `KoeiSRAM32` | KOEI games with 32 KB SRAM |
| `GameMaster2` | Konami Game Master 2 ROM with 8 KB SRAM |
| `CrossBlaim` | Cross Blaim specific mapper |
| `HarryFox` | Harry Fox specific mapper |
| `Zemina80in1` | Zemina 80-in-1 multicart mapper |
| `Zemina90in1` | Zemina 90-in-1 multicart mapper (uses port 77h) |
| `SuperSwangi`, `MSXWrite` | special ASCII 16 KB variants |
| `Synthesizer` | plain ROM with the Konami Synthesizer DAC |
| `MSXDOS2` | MSX-DOS2 cartridge: 16 KB bank in 4000-7FFF switched at 6000h. The online database has no MSX-DOS2 ROMs: add its CRC32 to [tools/CreateCRC/mappersOverride.txt](tools/CreateCRC/mappersOverride.txt) and rebuild the database. MSX-DOS 2.20 patched for the ASCII8 mapper is already there. Needs a disk drive: a machine with an FDC, or the FDC cartridge in slot 1 and MSX-DOS2 in slot 2 |

ROM types of the database without a configuration in the core are not written into `vampier.db` (e.g. MatraCompilation, Namco, Manbow2, the Halnote cartridge). Such a ROM up to 64 KB runs as plain ROM, a bigger one stops with *Not find CRC32 in DB*. The full list with counts is in [tools/CreateCRC/report.md](tools/CreateCRC/report.md). Also not supported: MU-PACK.

Machine-internal mappers (National FS-4600F, Yamaha SFG, Panasonic turbo R, the Halnote firmware mapper of the Sony HB-F1XDJ / HB-F1XV, memory mapper, ESE RAM) come from the machine definition and are not selectable.

## Supported Expansion Cartridges
The OSD offers the following types in **Slot1** and **Slot2**:

| Type | Slots | Requirements / notes |
|---|---|---|
| ROM | 1, 2 | Load the ROM with the item under the slot. Mapper from the database, or plain ROM. FW pack required. |
| Empty | 1, 2 | |
| FDC | 1 only | Philips VY-0010 floppy interface (WD2793, 1 drive); needs `VY0010.ROM` in the FW pack. **Only in a machine without its own FDC** – on a machine that has one, the cartridge is left out and the machine's FDC is used. |
| SCC | 1, 2 | Konami SCC sound cartridge |
| SCC+ | 1, 2 | [Konami Sound Cartridge](https://www.msx.org/wiki/Konami_Sound_Cartridge) with SCC+ and 128 KB RAM (Snatcher, SD Snatcher) |
| FM-PAC | 1, 2 | Needs the FM-PAC BIOS in the FW pack; 8 KB SRAM (not saved). On a machine that already has MSX-MUSIC only one FM-PAC fits. |
| MegaSCC+ 1MB | 1 only | ESE MegaSCC+ |
| MegaSCC+ 2MB | 2 only | ESE MegaSCC+ |
| MegaRAM ASCII-8K 1MB | 2 only | ESE [MegaRAM](https://www.msx.org/wiki/MegaRAM) |
| MegaRAM ASCII-16K 2MB | 2 only | ESE MegaRAM |
| MegaFlashROM SCC+ SD | 1 only | [MegaFlashROM SCC+ SD](https://www.msx.org/wiki/MegaFlashROM_SCC%2B_SD); needs `mfrsd.ROM` (8 MB image) in the FW pack; SD card via **Load SD card** (VHD); flash writes are not saved |
| Game Master 2 | 1 only | [Konami Game Master 2](https://www.msx.org/wiki/Konami_Game_Master_2); needs `GM2.ROM` in the FW pack; 8 KB SRAM (not saved) |
| MoonSound | 1, 2 | [MoonSound](https://www.msx.org/wiki/MoonSound) (OPL4); needs `yrw801.rom` in the FW pack; only one MoonSound at a time; 4 MB SDRAM; not available on the 1chipMSX |
| MSX-MIDI | 1, 2 | MSX-MIDI interface without a ROM (like the MIDI Interface 3), I/O ports E8h–EFh; the slot itself stays empty; only one at a time; not available on the 1chipMSX |

The 1chipMSX has its own Slot1 (Empty, MegaSCC+ 1MB) and Slot2 (Empty, MegaSCC+ 2MB, MegaRAM 1MB / 2MB) options and cannot load ROMs into the slots.

## MiSTerFPGA Platform Support
The core integrates with MiSTerFPGA and supports the following features provided by the platform:
- `Joystick input` – two MSX joystick ports (four directions and two buttons, named Fire 1 / Fire 2 in the MiSTer button mapping) from the first two MiSTer joysticks; the joystick swap option exists on the 1chipMSX only
- `Keyboard input` – PS/2 keyboard, per-machine matrix layout (`kbd_layout` in the machine definition, generated by [CreateKeyMap](tools/CreateKeyMap/README.md)); Pause key pauses the machine (CPU held, sound muted, HDMI picture frozen; on the turbo R the BIOS reads it from port A7h as on the real machine), F11 = turbo on the 1chipMSX
- `Mouse` – PS/2 mouse as MSX mouse on every machine, in joystick port 1 or 2 (OSD **Mouse**); it takes the port over when it moves, a joystick on that port takes it back
- `Cassette` – playback of `.CAS` files (the MSX motor must be on) or real tape through the MiSTer analog input (ADC); the tape is audible. There is no tape output.
- `MIDI` – MIDI IN and MIDI OUT of the YM2148 (Yamaha machines) and of the MSX-MIDI, two ways out:
  - MiSTer UART set to MIDI (31250 Bd): MidiLink sends MIDI OUT to a USB MIDI device or a software synthesizer (MUNT, FluidSynth) and brings MIDI IN from a USB MIDI device
  - user port: a [MT32-pi](https://github.com/dwhinham/mt32-pi) (MIDI OUT; its sound is mixed into the audio output and its display can be shown over the picture) or a MIDI adapter (MIDI OUT on pin 1, MIDI IN on pin 0)

  MIDI IN is taken from the user port when it is set to MIDI In/Out, from the UART otherwise. MIDI OUT goes to both; only while a MT32-pi plays and the UART is in MIDI mode, MidiLink gets nothing, so the music does not sound twice
- `Video` – native MSX timing, PAL/NTSC per machine definition (TMS) or software (V99xx), scaling and scandoubler options
- `LEDs` – SD/VHD activity, pause (machine paused or turbo R pause LED), turbo LED (R800 of the turbo R, turbo of the Panasonic MSX2+ and of the CIEL Expert Turbo)
- `SDRAM support` – optional; needed for the bigger machines and cartridges, see [Without the SDRAM module](#without-the-sdram-module)

## Known Limitations
- **Nothing is persistent:** cartridge SRAM (FM-PAC, Game Master 2, KOEI, ASCII with SRAM), flash writes (MegaFlashROM, ASCII16-X, Konami Ultimate Collection, Yamanooto), the SRAM of the machines (Panasonic and National mapper SRAM, Matsushita and S1985 SRAM) and the RTC CMOS start as FFh on every load. The **SRAM Save / SRAM Load** items do nothing.
- **Disks:** only raw `.DSK` images (720K, 640K, 360K, 320K); no 40-track, 1.44 MB, XSA, D88, HFE or DMK. The FDC cartridge works only in slot 1 and only in machines without an FDC; there is no TC8566AF cartridge.
- **Tape:** playback only, no saving.
- **R800:** the R800 of the turbo R is paced to the speed of a real one (page breaks, internal ROM and external slots, I/O, multiplication, DRAM refresh and the spacing of VDP accesses as in openMSX). Code that only works in the registers is 7 to 26 % slower than on a real R800. Its undocumented behaviour (flag bits 3 and 5, SLL, DD / FD in front of a plain instruction) is that of the Z80. No turbo R microphone.
- **ROMs:** a ROM over 64 KB needs an entry in the database, there is no mapper detection from the ROM header.
- **V99x8:** sprites in the overscan and the FH window in text modes are not done. The VDP speed and volume settings of the 1chipMSX are stored without effect.
- **1chipMSX:** no MoonSound, no special keys PrintScreen/ScrollLock (Pause is the general machine pause).
- **Pause:** only the CPU stops; a tape (CAS) and the floppy controllers keep running, so a pause during loading can end with a read error.
- No per-source volume or mute in the OSD, no V9990.

## Acknowledgements
Many thanks to the MSX community on Discord for testing on real hardware, for bug reports and for
advice; much of this core would not work as well without it. Special thanks go to:
- **Vampier** – for the [romdb.vampier.net](https://romdb.vampier.net/) ROM database the mapper
  database `vampier.db` is built from, and for testing and advice.
- **wark91** – for testing and advice.

Projects this core builds on or was checked against:
- [MSX_MiSTer](https://github.com/MiSTer-devel/MSX_MiSTer) by Sorgelig – the MiSTer port of KdL's OCM-PLD and the inspiration for this core. The 1chipMSX machine was converted from it: the IPL ROM, the system I/O ports and CPU speed logic, the ESE-RAM with the MegaSD, the MegaSCC/MegaRAM and the PS/2 mouse.
- [OCM-PLD](https://github.com/gnogni/ocm-pld-dev) by KdL and the ESE Artists' Factory (Kazuhiro Tsujikawa), with the ESE-VDP by Kunihiko Ohnaka – the origin of the T80 CPU (rewritten to SystemVerilog), the V99x8 VDP, the SCC and the MegaSD/MegaRAM code.
- [muhanpong/MSX1_MiSTer](https://github.com/muhanpong/MSX1_MiSTer) (branch `nextz80_v9990`) – a fork of this core. Its bug analyses and reports from real hardware pointed out faults in the flash emulation and the pitfalls of the ASCII16-X mapper and the MoonSound. No code was taken from it; the implementations here are independent.
- [openMSX](https://openmsx.org/) – reference for the behaviour of the ASCII16-X mapper and its flash chip, of the Konami Ultimate Collection and Yamanooto cartridges, of the NEO-8 and NEO-16 mappers, of the OPL4 (YMF278B) wave part, bus interface and timers, and of the V99x8 timing.
- [Grauw](https://www.grauw.nl/projects/ascii-x/ascii16-x/) – specification of the ASCII16-X mapper.
- [Nuked OPL3](https://github.com/nukeykt/Nuked-OPL3) by Nuke.YKT – the OPL3 model the FM part of the MoonSound is checked against, sample by sample. Its source (LGPL-2.1-or-later) is used by the test only (`rtl/peripheral/SOUND/opl4/tb/nuked`).

## License
This core is licensed under the GNU General Public License, version 3 or later
(see `LICENSE`, `SPDX-License-Identifier: GPL-3.0-or-later` in the source headers).
Parts taken from other projects keep their own licenses, as stated in their file headers
(e.g. the MiSTer framework in `sys/`, the X68000_MiSTer FDC modules under GPL-3.0, the
ESE / OCM-PLD derived files, the T80 / TV80 CPU and VDP cores).
