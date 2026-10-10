# [CBM-II](https://github.com/MiSTer-devel/CBM-II_MiSTer/) for [MiSTer](https://github.com/MiSTer-devel/Main_MiSTer/wiki)

MiSTer FPGA core for the [Commodore CBM-II line of 8-bit computers](http://cbmsteve.ca/cbm2/index.html)
(aka. PET-II, P128, B128, B256, P500/B600/B700 series)

![CBM-II Family photo](https://github.com/MiSTer-devel/CBM-II_MiSTer/blob/master/b3.jpg?raw=true)

## Core Features

* Business (80-column monochrome) and Professional (40 column colour with VIC-II) models
* 128kB, 256kB or full memory (~1MB) options
* VIC-II (P500 model) or 6545 CRTC (B600/B700 models) video
* SID audio
* Predefined and custom model configurations
* Direct file injection (*.PRG)
* Joystick/paddle/mouse support (P500 model)
* 4040/8250 IEEE disk drives (supporting D64, D80 and D82 disk images)
* Loadable system and drive ROMs
* Optional external RAM in segment 15.
* Optional external ROM at location $2000, $4000 and $6000 in segment 15.
* External IEC through USER_IO port (requires modified kernal or external ROM)

### Disk support

Core supports D64, D80 and D82 disk images through two 4040 and 8250 IEEE dual-disk drives. 
When using a D80 disk image, the first disk access will result in an error. 
This is normal behaviour of the 8250 drive.

## Keyboard

![keyboard-mapping](https://github.com/MiSTer-devel/CBM-II_MiSTer/blob/master/keyboard.png?raw=true)

The following PC keys are mapped to the special CBM-II keys:

* <kbd>Home</kbd> &rArr; <kbd>CLR/HOME</kbd>
* <kbd>End</kbd> &rArr; <kbd>RUN/STOP</kbd>
* <kbd>PgUp</kbd> &rArr; <kbd>OFF/RVS</kbd>
* <kbd>PgDn</kbd> &rArr; <kbd>NORM/GRAPH</kbd>
* <kbd>Delete</kbd> &rArr; <kbd>CE</kbd>
* <kbd>F11</kbd> &rArr; <kbd>C=</kbd>
* <kbd>Alt</kbd>+Numpad <kbd>0</kbd> &rArr; <kbd>00</kbd>
* <kbd>Alt</kbd>+Numpad <kbd>/</kbd> &rArr; <kbd>?</kbd>

## Loadable ROM

The core needs three boot ROMs with the Basic, Kernal and character set ROM for each machine type.

`boot0.rom` contains the ROMs for the Professional model (P500),
`boot1.rom` contains the ROMs for the Low Profile Business model (B6x0), and
`boot2.rom` contains the ROMs for the High Profile Business model (B7x0).

The layout of these three ROM files is identical:

* `0000`-`3FFF` Basic 128 *(16 KiB)*
* `4000`-`7FFF` Basic 256 *(16 KiB)*
* `8000`-`9FFF` Kernal *(8 KiB)*
* `A000`-`AFFF` Character set *(4 KiB)*

For the Professional model, only Basic 128 exists. In that case, the Basic 256 is replaced with a copy
of Basic 128.

From the "ROM/RAM Configuration" menu custom system ROMs can be loaded, these have the same layout as
the boot ROMs described above.

## External Cartridge ROM

A CBM-II can have up to 3 external cartridge ROMs installed. In the core, this is configured from the
"ROM/RAM Configuration" menu.

An external ROM is installed in segment 15 on address `$2000`, `$4000` or `$6000`.
External ROMs are generally designed to load into a specific slot. Refer to the ROM's
documentation to find out to which address the ROM should be loaded.
Most external ROMs will only work on either the P500 or B6xx/B7xx models, not both,
so select the proper model before loading the ROM.

To load an external ROM, go to the "ROM/RAM Configuration" menu, set the correct slot to "ROM",
and select "Load" for that slot to load the file.

## Segment 15 RAM

Besides loading external ROM into the slots in segment 15, the core also supports
adding RAM in these slots. This external RAM can be used by some programs.

External RAM can be activated in slots `$0800-$1FFF`, `$2000-$3FFF`, `$4000-$5FFF` and 
`$6000-$7FFF`.
To activate external RAM in a specific slot, set the slot to 'RAM' in the "ROM/RAM Configuration"
menu.

## Acknowlegements

This core could not exist without the following projects:

* The MiSTer project
* T65, (c) 2002-2015 Daniel Wallner, Mike Johnson, Wolfgang Scherr, Morten Leikvoll
* VIC-II, from FPGA64 by Peter Wendrich (pwsoft@syntiac.com)
* MC6845, from BBC Micro for Altera DE1 (c) 2011 Mike Stirling
* SID, from C64_MiSTer by Sorgelig
* VIA6522, (C) 2011, Thomas Skibo
* MOS6526, by Rayne
* M6532, from k7800 (c) by Jamie Blanks
* MOS6551, from CoCo3FPGA (c) 2008 Gary Becker (gary_l_becker@yahoo.com)
* C1351 Mouse, from C64_MiSTer by Sorgelig

Most of these projects include changes contributed by other authors.
See the source code for the full copyright notices.
