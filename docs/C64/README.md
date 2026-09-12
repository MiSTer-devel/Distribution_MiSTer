# C64 for [MiSTer](https://github.com/MiSTer-devel/Main_MiSTer/wiki)

Based on FPGA64 by Peter Wendrich with heavy later modifications by different people.

## Features
- C64 and C64GS modes
- C1541 read/write/format support in raw GCR mode (*.D64, *.G64)
- C1581 read/write support (*.D81)
- Parallel C1541 port for faster (~20x) loading time using DolphinDOS
- External IEC through USER_IO port
- Almost all cartridge formats (*.CRT)
- Direct file injection (*.PRG)
- Dual SID with several degrees of mixing 6581/8580 from stereo to mono
- Similar to 6581 and 8580 SID filters
- REU 16MB and GeoRAM 4MB memory expanders
- OPL2 sound expander
- Pause option when OSD is opened
- 4 joysticks mode
- Snac DB9 joysticks support (via UserIO) 
- RS232 with VIC-1011 and UP9600 modes either internal or through USER_IO
- Loadable Kernal/C1541 ROMs
- Special reduced border mode for 16:9 display
- C128/Smart Turbo mode up to 4x
- Real-time clock
- Drive OSD showing mount status, read/write activity and current track
- Complete C1530 Datasette implementation with on screen Counter and shortcuts keys

## Installation
Copy the *.rbf to the root of the SD card. Copy disks/carts to C64 folder.

## Usage

### Keyboard
Note: F2, F4, F6, F8, Left/Up keys automatically activate Shift key.

| Key                   | Function                                     |
|:---------------------:|----------------------------------------------|
| F9                    | Arrow-up key                                 |
| F10                   | = key                                        |
| F11                   | Restore key. Also special key in AR/FC carts |
| Alt, Tab              | C= key                                       |
| WIN + Cursor Up       | Tape Play / Stop                             |
| WIN + Cursor Down     | Tape Stop                                    |
| WIN + Cursor Left     | Tape Rewind                                  |
| WIN + Cursor Right    | Tape Fast Forward                            |
| WIN + Canc (or Del)   | Tape Counter Reset                           |
<br>

![keyboard-mapping](https://github.com/mister-devel/C64_MiSTer/blob/master/keymap.gif)

### Using without keyboard
If your controller has more than four buttons then you can map a couple of buttons to **Mod1** and **Mod2** to add twelve frequently used keys; for example, to skip the intros and start the game.

|                       | →           | ↓           | ←           | ↑           | Fire1    | Fire2   | Fire3   | Paddle                      |
|:---------------------:|:-----------:|:-----------:|:-----------:|:-----------:|:--------:|:-------:|:-------:|:---------------------------:|
| **Mod1**              | Cursor<br>→ | Cursor<br>↓ | Cursor<br>← | Cursor<br>↑ | Enter    | Space   | Esc     | Alt+ESC (LOAD"*" then RUN)  |
| **Mod2**              | 1           | 2           | 3           | 4           | 5        | 0       | Y       | N                           |
| **Mod1 + Mod2**       | F1          | F2          | F3          | F4          | F5       | F6      | F7      | F8                          |

With maps above and using Dolphin DOS you can issue **F7** to list the files on disk, then move cursor to required file, then issue **Alt+ESC** to load it and run.

### Loadable ROM
Alternative ROM can be loaded from OSD: Hardware->Load System ROM.
Format is simple concatenation of BASIC + Kernal.rom + C1541.rom

To create the ROM in DOS or Windows, gather your files in one place and use the following command from the DOS prompt. 
The easiest place to acquire the ROM files is from the VICE distribution. BASIC and KERNAL are in the C64 directory,
and dos1541 is in the Drives directory.

`COPY BASIC + KERNAL + dos1541 MYOWN.ROM /B`

To use JiffyDOS or another alternative kernel, replace the filenames with the name of your ROM or BIN file. (Note, you must use the 1541-II ROM. The ROM for the original 1541 only covers half the drive ROM and does not work with emulators.)

`COPY /B BASIC.bin +JiffyDOS_C64.bin +JiffyDOS_1541-II.bin MYOWN.ROM`

To confirm you have the correct image, the BOOT.ROM created must be exactly 32768 or 49152 (in case of 32KB C1541 ROM) bytes long. 

Two loadable ROM sets are provided: **DolphinDOS v2.0** and **SpeedDOS v2.7**. Both ROMs support the parallel Disk Port (more info below). DolphinDOS is the faster of the two.

For **C1581** you can use separate ROM with size up to 32768 bytes.

### Autoload the cartridge
In OSD->Hardware page you can choose Boot Cartridge, so every time a core is loaded, this cartridge will be loaded too.

### C1530 and tape support
In OSD->Load *.TAP and choose a TAP file. When a TAP is mounted, on OSD all the commands for managing the C1530 will appear and the keyboard shortcuts will also be enabled. For show counter on display (HDMI and CRT), enable Tape Counter on OSD and save settings. 

### Parallel port
Are you tired of long loading times and fast loaders aren't really fast when comparing to other systems? 

In OSD->Hardware set **System ROM: Loadable**. Then load the provided [DolphinDOS_2.0.rom](releases/DolphinDOS_2.0.rom) via OSD->Hardware->**System ROM: C64+C1541**. Also make sure that OSD-Drives->**Parallel Port: Enabled**. You will get about **20x times faster** loading from disks!

The C64 User Port is a historical bottleneck because the Parallel Disk cable, RS232 modems, and 4-Player Joystick adapters all require exclusive access to it. The MiSTer tries to be smart about this:
* If the core detects activity on the disk serial lines, it assumes a fast loader is engaging and instantly grants the User Port to the Parallel Disk drive.
* Once disk activity stops for exactly 0.5 seconds, the User Port is automatically handed back to the RS232 module or the 4-Player Joystick adapter. 

Caution: The parallel port for disk drives is only enabled if you load a C64+Drive ROM where the Drive ROM portion is exactly **32KB** (like with the provided Dolphin DOS or Speed DOS). The standard kernal and e.g. JiffyDOS do not have special Drive ROMs (16KB), and thus the parallel port will be disabled (regardless of setting in drives).

JiffyDOS is a fast-serial replacement for standard kernal and achieves fast loading without the parallel port.
### Turbo modes

**C128 mode:** this is C128 compatible turbo mode available in C64 mode on Commodore 128 and can be controlled from software, so games written with this turbo mode support will take advantage of this.

**Smart mode:** In this mode any access to disk will disable turbo mode for short time enough to finish disk operations, thus you will have turbo mode without losing disk operations.

### RS232

Primary function of RS232 is emulated dial-up connection to old-fashioned BBS. **CCGMS Ultimate** is recommended (Don't use CCGMS 2021 - it's buggy version). It supports both standard 2400 VIC-1011 and more advanced UP9600 modes.

**Note:** DolphinDOS and SpeedDOS kernals have no RS232 routines so most RS232 software doesn't work with these kernals!

### GeoRAM
Supported up to 4MB of memory. GeoRAM is connected if no other cart is loaded. It's automatically disabled when cart is loaded, then enabled when cart unloaded.

### REU
Supported standard 512KB, expanded 2MB with wrapping inside 512KB blocks (for compatibility) and linear 16MB size with full 16MB counter wrap.
Support for REU files.

GeoRAM and REU don't conflict each other and can be both enabled.

### USER_IO pins

| USER_IO | USB 3.0 name | Signal name |
|:-------:|:-------------|:------------|
|   0     |    D+        | RS232 RX    |
|   1     |    D-        | RS232 TX    |
|   2     |    TX-       | IEC /CLK    |
|   3     |    GND_d     | IEC /RESET  |
|   4     |    RX+       | IEC /DATA   |
|   5     |    RX-       | IEC /ATN    |

All signals are 3.3V LVTTL and must be properly converted to required levels!
With a level converter this allows connecting the MisterFPGA for example to a real 1541 or printer!

### Real-time clock

RTC is PCF8583 connected to tape port.
To get real time in GEOS, copy CP-CLOCK64-1.3 from supplied [disk](https://github.com/mister-devel/C64_MiSTer/blob/master/releases/CP-ClockF83_1.3.D64) to GEOS system disk.

### 1541 Drive

The C64 core supports both C1541 and C1581 drives with D64, T64, G64 and D81 disk images. Up to two drives #8 and #9 can be enabled and used simultaneously. A simulated C1541 drive is auto-enabled for D64, T64 and G64 images, while the C1581 is enabled for D81 images.

Advanced C1541 features:
* Accurate low-level read logic based on original schematics
* Physical disk rotation simulation
* AGC flux events (weak bits)
* Drive Overlay: an optional OSD showing current track and read/write activity

Images mounted from inside zip files are strictly read only. For regular files, you can force write protection via the menu or by changing the file's read-only attribute. Caution: Changing the write-protect option for a drive only takes effect the next time you mount an image. Use the supplied empty disks for saving or copying to. Saving to a mounted (and writeable) image is done seamlessly in the background, there is no need to open the F12 Menu to force a save. You can monitor drive activity directly on-screen for both disk drives. The available modes are configurable via the drives menu: **Activity Only** (pops up only on activity), **If Mounted** (always visible if a disk is inserted),  and **Off**. The overlay shows the current track number and uses color coding to indicate reads (yellow), writes (red) and no activity (green).

The G64 format can accurately represent over 90% of original copy-protected software. However, getting protected software to load can sometimes be tricky. Always mount write protected, as some devious protections try to format your disk if they detect a copy and others even require being write protected to load. If a game fails to load, try the following steps:
* Use the standard C64 kernal (disable fast loaders).
* Toggle between PAL and NTSC modes via menu.
* Try alternate dumps of the disk (alts).
* Be patient! Some titles take a very long time to load.
* Try multiple times (some protections are unreliable even on original hardware).
* If all else fails, experiment with the drive speed and drive wobble settings.

Note: In some cases protected disk will not work yet, or fall outside the scope of what the G64 format can accurately capture.
