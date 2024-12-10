# [TRS-80](https://en.wikipedia.org/wiki/TRS-80) for MiSTer Platform
## Model I Support ##
This is a port of [HT1080Z MiST core](https://github.com/mist-devel/ht1080z) by Jozsef Laszlo to the MiSTer

To learn how to use the TRS-80, this is a quick tutorial:
https://www.classic-computers.org.nz/system-80/driving_instructions.htm

The TRS-80 with Disk Drives attached will boot to a screen of '@' symbols and will then only continue booting once you place a disk in the drive.  To bypass this and boot directly to BASIC to load a cassette game, press Escape immediately after selecting Reset in the OSD menu.

### To load a cassette game:
```
  return
  system
  <Then go to the OSD and load a cassette>
  [type the first letter of the file you want to load (e or g for the disk images provided)]
  / (to start once loaded)
```

### To load a CMD file:
Just select it in the OSD. Some CMD files won't work if they access disk rom routines and there is no disk in the drive. Sometimes a clean reboot is necessary before loading a CMD.

### To load a BAS file:
Only basic Level II programs can be loaded. Load Basic (with or without a DOS) and once at the prompt ">" select a \*.bas file from the OSD. Use "LIST" or "RUN" to see and start the program as usual. 

### To load files from DSK images:
There are three main TRS-80 image formats, which are JV1, JV3 and DMK and they all usually share the same DSK extension.  This MiSTer Core only supports the JV1 image format with upto 240 tracks, all tracks must currently hold 10 x 256 byte sectors.  To check what format a disk is in, and if it is compatible with the core, use the TRSTOOLS utility from Matthew Reed, available from: http://www.trs-80emulators.com/trstools/

The Disk emulation supports reading and writing to JV1 formatted disks, but disks cannot be formatted in the core because there is no Write Track support for JV1 images.  There are many different DOS versions for the TRS-80 with popular ones including TRSDOS, NEWDOS/80, LDOS and MULTIDOS.  For beginners it is recommended you use TRSDOS which is the original DOS produced by Radio Shack.  Instructions for using TRSDOS can be found in the following Wikipedia article: https://en.wikipedia.org/wiki/TRSDOS

## Features:
 * TRS-80 Model I with 48KB installed
 * Expansion interface with quad disk drives
 * Real Time Clock (RTC)
 * RS232-C Interface (IO ports $E8 to $EA)
 * SavedStates
 * White, Green and Amber Phosphor screen emulation
 * Sound output is supported (however cassette saving sound is suppressed)
 * Cassette loading is many times faster than the original 500 baud
 * Ctrl Key simulates shift-DownArrow

## How to use the Saved States
 * You must first create "rom_names" each virtually containing 4 saved states numbered from 1 to 4 and selected in the OSD
 * To create these slots just put a non-empty file with a .SAV extension anywhere, but preferably in games/TRS-80
 * An easy linux/MiSTer command to do this is : echo "A">/media/fat/games/TRS-80/MySave001.SAV
 * You can create as many save "rom_names" as you want, they are just needed to define the "rom_name" under which the savestates are done, this aside they are not used.
 * Use the OSD to select a slot with the "Snapshot "\*.SAV" OSD entry, and a state number from the "Savestate slot" OSD entry 
 * the physical saves are stored in /media/fat/savestates/TRS-80
 * the UI is a bit primitive for the moment, this will be updated in the future probably.
 * The SaveStates mecanism saves the video memory, the main memory and the processor's internal registers and states. It doesn't save any other peripheral, notably not the disk controller. That should be ok though, but don't do bizarre things like making a snapshot right in the middle of a writing sectors sequence, it's not gonna end well.
 * The details of the format of the savestate file are as follow :
   - 0000-000f : Mister header, serial number of the save and file size in 32bits words
   - 0010-002f : Z80 registers
   - 0030-042F : Video Screen 
   - 0430-c42f : Main Memory (4000-ffff) 

## Notes:
 * The included BOOT.ROM has been modified to take advantage of a special interface for loading cassettes; original BASIC ROMs are also supported
 * Simulates Percom Doubler and TRS-80DD, but the upcoming JV3 decoding will be required to use DD disk images (disabled for now)
 * Even though sector write operations are supported, formatting of disks is not.
 * Prefer keyboard "TRS80" mapping for games, and reserve "PC" mapping for desktop apps. The latter may misbehave when several keys are pushed at the same time.

## System80 improved keyin routine
 * The included ROM contains Dick Smith System80 improved keyin routine at /12288 but it doesn't seem to work well (key repeat is too fast)
 * Refer to the System80 manual for details about this.

## System80 Debugger in the ROM 
 * The debugger can be loaded with "SYSTEM" then "/12710" at the prompt;
 * Refer to the System80 manual for details about this. 

## Technical:
Debug status line
 * The Debug Status line will only be visible in Partial or Full overscan modes
   * For monitoring Floppy Disk Controller (FDC)
   * Usess the following format: Ddddd,Ccc,Ttt,Sss,dnn,sSS,Xxxxx \* where:
     * dddd - Drive select latch (1-4).  Only 2 drives are currently supported
     * cc   - FDC Command Register
     * tt   - FDC Track Register
     * ss   - FDC Sector Register
     * nn   - FDC Data Register
     * SS   - FDC Status Register
     * xxxx - Spare debug flags, depends upon the release. 
     * \*   - RTC Second Timer


Special ports (i.e. Z-80 "OUT"/"IN" commands) have been added as follows:
 * VIDEO:
   * OUT 0, n (where n=(0-7)) -> change foreground color
   * OUT 1, n (where n=(0-7)) -> change bacgronund color
   * OUT 2, n (where n=(0-7)) -> change overscan color

 * Memory-mapped cassette:
   * OUT 6, n (where n=(0-255)) -> set address bits 23-16 of virtual memory pointer
   * OUT 5, n (where n=(0-255)) -> set address bits 15- 8 of virtual memory pointer
   * OUT 4, n (where n=(0-255)) -> set address bits  7- 0 of virtual memory pointer
   * A = INP(4)  -> read virtual memory at current virtual memory pointer and increment pointer
   * Note that cassette image is loaded at 0x010000, and no memory exists beyond 0x01ffff

 * Holmes Sprinter Interface
   * OUT 254, n - Even number = Override Turbo.  Odd number = Enable Turbo

Special memory mapped ports have been added as follows:

* TRS-80 DD Interface - Memory mapped interface
    * 0x37ec = 0x80 - Enable Double Density Mode  (disabled for now)
    * 0x37ec = 0xa0 - Disable Double Density Mode
