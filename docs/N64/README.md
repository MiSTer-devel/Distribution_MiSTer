# [Nintendo 64](https://en.wikipedia.org/wiki/Nintendo_64) for [MiSTer Platform](https://github.com/MiSTer-devel/Main_MiSTer/wiki)

## Hardware Requirements

SDRAM of any size is required.

32 Mbyte SDRAM can only be used for cartridge games up to 16 Mbyte in size.

## Features

  * Nintendo 64 cartridge support (`.z64`, `.n64`, `.v64`)
  * Standalone 64DD games and cartridge expansion disks (`.ndd`)
  * Cartridge and Disk saving
  * 64DD and Dobutsu no Mori/Animal Forest RTC
  * Automatic cartridge region, CIC, save type and accessory detection
  * Controller Pak, Rumble Pak, Transfer Pak, SNAC, Randnet keyboard and Mouse support
  * Game cheats
  * Original VI and Clean HDMI video paths
  * Configurable VI processing, texture filtering, dithering and aspect ratio

## BIOS

Five ROMs are required: the Nintendo 64 PIF ROMs and Nintendo 64DD IPL ROMs. BIOS files are not included with the core.

Place the files in the N64 game directory:

    /media/fat/games/N64/boot.rom  => NTSC Nintendo 64 PIF ROM
    /media/fat/games/N64/boot1.rom => PAL Nintendo 64 PIF ROM
    /media/fat/games/N64/boot3.rom => Japan Retail Nintendo 64DD IPL ROM
    /media/fat/games/N64/boot4.rom => DEV Nintendo 64DD IPL ROM
    /media/fat/games/N64/boot5.rom => US Retail Nintendo 64DD IPL ROM

`boot3.rom` is loaded automatically when the core starts.

You can also place an IPL named `dd_bios.rom` in the same folder as an NDD image:

    /media/fat/games/N64/Game Name/Game Name.ndd
    /media/fat/games/N64/Game Name/dd_bios.rom

When that disk is selected, `dd_bios.rom` replaces the startup IPL for that disk. If it is not present, the core keeps using `boot3.rom`, `boot4.rom` or `boot5.rom`.

The OSD also provides **Load 64DD IPL** for manually selecting an IPL ROM.

## Disk Images

Select **Load 64DD Disk** in the OSD to mount an image with an `.ndd` extension.

The following layouts are supported:

  * Compact NDD: 64,931,840 bytes

The disk type, system data, bad tracks and retail/development format are detected automatically. The source NDD image is not modified when a game writes to disk.

## Loading Disk Games

For a standalone 64DD game:

  1. Start the N64DD core.
  2. Select **Load 64DD Disk** and choose the NDD image.
  3. The core loads `dd_bios.rom` from the disk folder when present, otherwise it uses the `boot3.rom`, `boot4.rom` or `boot5.rom`.


You may also wait for the IPL to display its insert-disk message before loading the NDD image.

## Cartridge Expansion Disks

For a cartridge expansion such as the F-Zero X Expansion Kit:

  1. Select **Load 64DD Disk** and load the expansion disk.
  2. Select **Load** and load the matching Nintendo 64 cartridge.

The core detects an expansion disk from its disk ID, keeps it mounted while the matching cartridge is loaded and boots from the cartridge instead of the IPL.

The cartridge can also be loaded automatically by giving it the same base name as the NDD image with a `.rom` extension:

    /media/fat/games/N64/Game Name/Game Name.ndd
    /media/fat/games/N64/Game Name/Game Name.rom

Main_MiSTer loads the disk first, preloads a local `dd_bios.rom` when present, then loads the matching `.rom` file. The cartridge is loaded last and initiates the core reset.

## Disk Saving

64DD writes are stored separately from the original NDD image. The preferred save is the writable RAM area of the disk, stored under the core save directory with the same base name as the NDD image:

    /media/fat/saves/N64/Game Name.ram

The `.ram` file is compatible with 64DD MFS Manager. Its size depends on the disk type. If no `.ram` file exists, the initial writable RAM contents come from the selected NDD image. On later loads, the matching `.ram` file is restored over that writable area.

With **Autosave** enabled, opening the OSD saves changed disk data. You can also use **Save Backup RAM** to save manually. Keep the system powered on while the saving message is displayed.

Before changing disks, the current disk is saved automatically.

## Cartridge Saving

Cartridge EEPROM, SRAM and Flash RAM saves use the normal MiSTer N64 save handling. Controller Pak data is also stored through the normal backup RAM interface.

When **Auto Detect** is enabled, Main_MiSTer selects the cartridge region, CIC, Expansion Pak size, save memory and preferred controller accessory from the N64 database and ROM header.

## RTC

The 64DD real-time clock is initialized from the MiSTer system clock when the core starts. Date and time changes made in the IPL are retained while the core remains active, and the emulated clock continues to tick.

## Pad Options

The following pad types can be assigned through the OSD:

  * N64Pad
  * None
  * ControllerPak
  * RumblePak
  * TransferPak
  * SNAC
  * Keyboard
  * Mouse

Mouse buttons can also be mapped to the Pad 1 A, B and Z buttons.

## Video Output

The core supports HDMI and analog video output.

The **Original (VI)** path exposes options for color depth, bilinear filtering, deblur, gamma, dedither, antialiasing, divot filtering and noise dithering. **Clean HDMI** provides the alternative digital output path.

Texture filtering, dithering and LOD texture processing can also be disabled independently. These options may change the appearance of effects that depend on the original Nintendo 64 rendering pipeline.

## Debug Options

The debug menu is intended for developers. Leave these options at their defaults for normal use, as changing cache, DDR3 or timing settings may cause games to hang or behave incorrectly.

## Error Messages

If the core recognizes an internal problem, the error overlay displays a hexadecimal bit field. More than one error may be reported at the same time.

List of error bits:

  * Bit 0 - Memory access to an unmapped area
  * Bit 1 - CPU instruction not implemented, currently used for cache commands only
  * Bit 2 - CPU stall timeout
  * Bit 3 - DDR3 timeout
  * Bit 4 - FPU internal exception
  * Bit 5 - PI error
  * Bit 6 - Critical exception occurred; this is heuristic and may be a false positive
  * Bit 7 - PIF used all 64 bytes for external communication, or an EEPROM command has an unusual length
  * Bit 8 - RSP instruction not implemented
  * Bit 9 - RSP stall timeout
  * Bit 10 - RDP command not implemented
  * Bit 11 - RDP combine mode not implemented
  * Bit 12 - RDP combine alpha function not implemented
  * Bit 13 - SDRAM mux timeout
  * Bit 14 - Texture mode not implemented
  * Bit 15 - Render mode not implemented (two-pass or copy)
  * Bit 16 - RSP read FIFO overflow
  * Bit 17 - DDR3/RSP write FIFO overflow
  * Bit 18 - RSP IMEM/DMEM write/read address collision detected
  * Bit 19 - A DDR3 requester attempted to read or write outside RDRAM
  * Bit 20 - RSP DMA attempted to write outside RDRAM
  * Bit 21 - RDP pixel writeback attempted to write outside RDRAM
  * Bit 22 - RDP Z writeback attempted to write outside RDRAM
  * Bit 23 - RSP PC modified by register access while the RSP is running
  * Bit 24 - VI line processing did not complete in time
  * Bit 25 - RDP mux missed a request
  * Bit 26 - CPU write FIFO full; this indicates an internal CPU logic error
  * Bit 27 - Simultaneous TLB access from multiple sources
  * Bit 28 - PI DMA attempted to write outside RDRAM

## References

64DD behavior and disk handling were developed with reference to [SummerCart64](https://github.com/Polprzewodnikowy/SummerCart64) and [ares](https://github.com/ares-emulator/ares).
