# [Apple IIe](https://en.wikipedia.org/wiki/Apple_IIe) for [MiSTer](https://github.com/MiSTer-devel/Main_MiSTer/wiki)

This is a MiSTer port of the Apple IIe core from MiST.

## Description

Reconstruction of an 1980s-era Apple //e implemented in VHDL for FPGAs.  

Originally ported from MiST: https://github.com/gyurco/apple2efpga, 
itself a port from DE2: http://www1.cs.columbia.edu/~sedwards/apple2fpga/  

## Features

* Disk loading via OSD, supports floppes in .woz, .nib, .dsk, .do, .po formats (NOTE: only .woz will persist saves to disk)
* HDD loading via osd
* Selectable 6502 or 65C02 CPU
* Save States (save/restore CPU and memory state to SD card)
* Joystick support (map it in OSD menu)
* Virtual On-Screen keyboard (press "Start" button on joypad)
* Joy-2-key support, use joystick to send key presses, load profile from disk
* Scanlines
* Color, amber, green and black&white monitor
* selection of display type: RGB Monitor (sharp pixels, VGA-like), Color TV (composite NTSC)
* selection of RGB palettes: (NTSC //e, Apple IIgs, AppleWin, Custom)
* Load Custom RGB Monitor palette from file 
* selection of Color TV presets (adjusts hue, saturation, etc.)
* Language card in slot 0
* Tape loading via the ADC-in
* Load custom video ROM (default built-in: US/UK)
* Optional display of disk state (disk spinning, disk read/write, HDD mounted, HDD read/write)
* No-Slot Clock
* Super Serial Card in slot 2
* 64K base + 64K auxilary RAM with 80 column and double hi-res support (256KB total with Saturn 128K)
* Saturn 128k RAM expansion in slot 5 (get the utility disks from here: http://apple2online.com/?page_id=3447 , under "Saturn RAMSoft")
* Mockingboard model A (two AY-3-8913 chips for six audio channels) in slot 4

## Keyboard shortcuts

* Win/Cmd Key - Closed Apple
* Alt Key - Open Apple
* F2 - RESET key
* F5 - Load State from current slot (change slot in OSD, four available)
* F6 - Save State in current slot (change slot in OSD, four available)
* F8 - cycle through color palettes (NTSC, Apple IIgs, AppleWin, Custom)
* F9 - cycle through display monitor modes (color, b&w, green, amber)
* F10 - display/hide on-screen virtual keyboard

## Apple II slot assignments

* Slot 0 - language card
* Slot 1 - free 
* Slot 2 - Super Serial Card
* Slot 3 - 80 col + 64K RAM expansion (//e)
* Slot 4 - Mockinboard model A (six audio channels)
* Slot 5 - Saturn 128kb RAM expansion (total of 256kb)
* Slot 6 - Disk Drive controller
* Slot 7 - Hard Disk Drive controller

## Disk format notes

Apple-II has a big mess in disk formats. We mainly support WOZ since it is the modern standard for A2 emulation.
Other formats are supported by doing a conversion on the fly, but they won't write back to disk.W

For HDD, only HDV images (raw ProDOS partition images) 32MB in size are supported. 
2MG images may work if the 64-byte header is removed.
```bash
dd if=diskimage.2mg of=diskimage.hdv bs=64 skip=1
```


## Instructions

* Put disk files into the `/games/Apple-II/` folder.
* Copy Palettes under the  `/games/Apple-II/Palettes` folder.
* Copy key mappings under the  `/games/Apple-II/Joy2key` folder.

On the "Apple ][" boot screen open the OSD with F12 and choose a disk. 
It will boot the disk automatically. 

If you press reset (the right button on the MiST) you'll enter Applesoft with the ] prompt.
From here you have some limited commands. See: http://www.landsnail.com/a2ref.htm

## Credits

This core is the result of the efforts of many developers over the span of years:
* **Stephen Edwards**: Original Apple II+ core for the DE2
* **Gyurco**: MiST core main maintainer, Mouse Card, etc.
* **Wsoltys**: Mockingboard, Saturn Card support, etc.
* **AlanSWX**: WOZ support, Super Serial Card, Mouse Card, etc.
* **Kitrinx**: New CPU code (high accuracy 6502 and 65c02 enabling save states), NTSC Composite Decoder video module
* **Newsdee**: Virtual Keyboard, Joy2Key, Palette and Video Presets, Save States, OSD curation.

## Using the Virtual Keyboard

Map joystick buttons to the core in order to use the virtual keyboard. 
(you will notice you are prompred for more buttons than a normal Apple II controller)

The core assumes the convention of a SNES-style controller:
- **Start**: Show/Hide Virtual Keyboard
- **Select**: Change opacity of Virtual Keyboard (100%/75%/50%/25%)
- **L**: Move Virtual Keyboard on top of the screen (and toggle back)
- **R**: Press Enter
- **D-Pad**: Select key 
- **A**: Press selected key
- **B**: Back (Apple II does not have a "Backspace", programs relied on back arrow)
- **X**: Press Space 

In addition the keyboard has a CMD button where the Apple II "Reset" key was. 
You can use this to trigger special Apple II shortcuts:
- **WARM** - Warm Reboot (Ctrl + Reset)
- **COLD** - Cold Boot, sends Ctrl + Open Apple + Reset
- **TEST** - Test Boot, sends Ctrl + Closed Apple + Reset

## Save States

The core supports save states, backing up the CPU state and 128K of RAM to SD card. You can save up to 4 slots, selectable in OSD.
**Note** that disk contents (floppy or HDD) are __not__ part of the save state - similar to how a save state would work on real hardware.



## Advanced usage

If you want to boot another disk choose a .woz, .dsk, or .nib image via the osd and type the following:

```
]PR#6
```

or

```
]CALL -151`
*C600G
```

The call command will enter the Monitor. Type the call a second time if the * prompt won't
show the first time. 
At the Monitor you can also type 6 and then Ctrl-P followed by return.
See https://web.archive.org/web/20140827184511/http://vectronicsappleworld.com:80/appleii/dos.html#bootdos

The HDD interface is in slot 7. Unlike the floppy interface, it does not stall until an image is mounted, so either reset the machine or use one of the following after mounting an image:

```
]PR#7
```

or

```
]CALL -151`
*C700G
```

## Instructions to rebuild roms

Install the acme cross-assembler: https://sourceforge.net/projects/acme-crossass/
```bash
acme -o clock.bin clock.asm
srec_cat clock.bin --binary -o clock2.hex --ascii_hex
```


### Pre-MiST ReadMe for historical purposes:

```
This is a reconstruction of an 1980s-era Apple ][+ implemented in VHDL for
FPGAs.

Stephen A. Edwards, sedwards@cs.columbia.edu
http://www1.cs.columbia.edu/~sedwards
------------------------------
The current implementation uses the Altera DE2 board and takes advantage
of its off-chip SRAM, VGA DAC, SD card, audio CODEC, and PS/2 keyboard
interface. 

It was designed to be fairly easy to port: the apple2.vhd file should
be implementation-agnostic: it only assumes the external availability
of 48K of RAM and a keyboard.

It contains a simple read-only Disk II emulator that expects
"nibblized" disk images written raw onto an SD or MMC card (i.e., it
does not use a FAT or any other type of filesystem).

The VGA controller (not part of an original Apple) doubles each line
and interprets the Apple's NTSC-compatible color signals to produce a color
640 X 480 VGA display with non-standard dot timing.
------------------------------
To compile under Altera's Quartus software, open the apple2fpga.qpf
project file and compile.
------------------------------
VHDL files, in order of elaboration:

timing_generator.vhd Timing signal generation, video counters
character_rom.vhd    The beautiful 5 X 8 uppercase-only text font
video_generator.vhd  Text, lores, and hires mode shift registers
main_roms.vhd        D000-FFFF ROMs: Applesoft and the Monitor
cpu6502.vhd          The 6502 CPU core
apple2.vhd           Top-level of the Apple: mostly address decode
disk_ii_rom.vhd      C600-C6FF ROM: Disk II bootstrap ROM
disk_ii.vhd          Read-only Disk II emulator
vga_controller.vhd   NTSC-to-VGA color interpolation, line doubler
PS2_Ctrl.vhd         Low-level PS/2 keyboard interface
keyboard.vhd         PS/2 keyboard-to-Apple interface
spi_controller.vhd   SD/MMC card controller: reads raw tracks
i2c_controller.vhd   Simple I2C bus driver; initializes the codec
wm8731_audio.vhd     Controller for the Wolfson WM8731 audio codec
DE2_TOP.vhd          Top-level entity for the Altera DE2 board
CLK28MPLL.vhd	     Altera-specific configuration for 28 MHz PLL

Other files:

dsk2nib.c            Converts a 140K .dsk image file to the raw 228K
                     .nib format used by the Disk II emulator

makenibs	     A shell (e.g., bash) script that assembles
		     collections of .dsk files into a file suitable
		     for directly writing onto an SD card		     

rom2vhdl             Script to convert raw ROM files into
		     synthesizable VHDL code.  Used to produce main_roms.vhd

apple2fpga.qpf       Project file for Altera's Quartus
DE2_TOP.qsf          Mostly pin assignments for Altera's Quartus
DE2_TOP.sof	     A compiled bitstream for the DE2 board: the
		     result of compiling all the VHDL files in
		     Quartus; suitable for programming if you have a
		     DE2 board.

dos33master.nib      Bootable disk image: Apple DOS 3.3 system master

bios.a65	     6502 assembly source for a "fake" BIOS
bios.rom	     Binary data for the "fake" BIOS

Makefile             Rules for creating the .zip, .vhd files, etc.
------------------------------
Disk images

The system expects a sequence of "nibblized" (227K) disk images on the
SD card starting at block 0.  Switches on the DE2 board selects which
image appears to be in the drive; the image number is displayed in hex
on two of the seven-segment displays.

Most Apple II disk images are in 140K .dsk files, which stores only
the disk's logical data, i.e., is not encoded.  dsk2nib.c is a small C
program that expands .dsk files to .nib files.

I used the "makenibs" script to find all the .dsk files in a tree of
directories, assemble them into an image suitable for downloading to
the SD card, and print an image number/file name cross-listing.

To write .nib images to an SD/MMC card under Linux, I use

dd if=dos33master.nib of=/dev/sdd

Of course, your card may appear as something other than /dev/sdd.
------------------------------
ROMs

This archive does NOT include a copy of the Apple ][+'s ROMs, which
are copyright Apple Computer.  Instead, it includes a very trivial
BIOS that beeps, displays a text screen, then cycles through some
lores and hires graphics patterns when keys are pressed.  This should
be enough to verify the graphics, sound, and keyboard are working (but
not the disk emulator).  Source for this BIOS is in the bios.a65 file,
which I assembled using the xa65 cross-assembler.

The system requires two ROM images: a 12K image of the system roms
(memory from 0xD000 - 0xFFFF) and a 256-byte image of the Disk II
controller bootstrap ROM (memory from 0xc600 - 0xc6ff if the card is
in the usual slot 6).

Once you obtain them, run the "rom2vhdl" script to convert the binary
files into .vhd files that hold the data.  The Makefile contains rules
for doing this.
------------------------------
Credits:

Peter Wendrich supplied the 6502 core:

-- cpu65xx_fast.vhdl, part of FPGA-64, is made available strictly for personal
-- educational purposes. Distributed with apple2fgpa with permission.
--
-- Copyright 2005-2008 by Peter Wendrich (pwsoft@syntiac.com).
-- All rights reserved.
-- http://www.syntiac.com/fpga64.html

The low-level PS/2 keyboard controller is from ALSE:

-- PS2_Ctrl.vhd
-- ------------------------------------------------
--   Simplified PS/2 Controller  (kbd, mouse...)
-- ------------------------------------------------
-- Only the Receive function is implemented !
-- (c) ALSE. http://www.alse-fr.com

I adapted the Apple ][ keyboard emulation from Alex Freed's FPGApple:
http://mirrow.com/FPGApple/
```
 
