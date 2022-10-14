# [IBM PC/XT](https://en.wikipedia.org/wiki/IBM_Personal_Computer_XT) for [MiSTer FPGA](https://mister-devel.github.io/MkDocs_MiSTer/)

PCXT port for MiSTer by [@spark2k06](https://github.com/spark2k06/).

Discussion and evolution of the core in the following misterfpga forum thread:

https://misterfpga.org/viewtopic.php?t=4680&start=1020

## Description

The purpose of this core is to implement a PCXT as reliable as possible. For this purpose, the [MCL86 core](https://github.com/MicroCoreLabs/Projects/tree/master/MCL86) from [@MicroCoreLabs](https://github.com/MicroCoreLabs/) and [KFPC-XT](https://github.com/kitune-san/KFPC-XT) from [@kitune-san](https://github.com/kitune-san) are used.

The [Graphics Gremlin project](https://github.com/schlae/graphics-gremlin) from TubeTimeUS ([@schlae](https://github.com/schlae)) has also been integrated in this first stage.

[JTOPL](https://github.com/jotego/jtopl) by Jose Tejada (@topapate) was integrated for AdLib sound.

An SN76489AN Compatible Implementation (Tandy Sound) written in VHDL was also integrated - Copyright (c) 2005, 2006, [Arnim Laeuger](https://github.com/devsaurus) (arnim.laeuger@gmx.net)

## Key features

* CPU Speed 4.77 MHz and turbo modes 7.16 MHz / 14.318 MHz
* BIOS selectable (Tandy 1000 / PCXT)
* Support for IBM Tandy 1000
* Support for IBM PCXT 5160 and clones (CGA graphics)
* Main memory 640Kb + 384Kb UMB memory
* Simultaneous video MDA
* EMS memory up to 2Mb
* Tandy 320x200x16 graphics with 128Kb of shared RAM + CGA graphics
* Audio: Adlib, Tandy, speaker
* Joystick support
* Mouse support into COM2 serial port, this works like any Microsoft mouse... you just need a driver to configure it, like CTMOUSE 1.9 (available into hdd folder), with the command CTMOUSE /s2 

## Quick Start

* Copy the contents of games/PCTXT to your Mister SD Card and uncompress hd_image.zip. It contains a freedos image ( http://www.freedos.org/ )
* Select the core from Computers/PCXT.
* Press WinKey + F12 on your keyboard.
*  Model: IBM PCXT.
*  CPU Speed: 14.318MHz.
*  FDD & HDD -> HDD Image: FreeDOS_HD.img
*  FDD & HDD -> Speed: 921600. NOTE: This speed can only be selected if CPU speed is 14.318 MHz.
*  BIOS -> PCXT BIOS: pcxt_micro8088.rom
* Choose Reset & apply model.

## ROM Instructions

ROMs should be provided initially from the BIOS section of the OSD menu, then it is only necessary to indicate the computer model and reset, on subsequent boot of the core, it is no longer necessary to provide them, unless we want to use others. Original and copyrighted ROMs can be generated on the fly using the python scripts available in the SW folder of this repository:

* `make_rom_with_ibm5160.py`: A valid ROM is created for the PCXT model (pcxt.rom) based on the original IBM 5160 ROM, requires the XTIDE BIOS at address EC00h to work with HD images.
* `make_rom_with_jukost.py`: A valid ROM is created for the PCXT model (pcxt.rom) based on the original Juko ST ROM, and with the XTIDE BIOS embedded at address F000h.
* `make_rom_with_tandy.py`: A valid ROM is created for the Tandy model (tandy.rom) based on the original Tandy 1000 ROM, requires the XTIDE BIOS at address EC00h to work with HD images.

From the same BIOS section of the OSD it is possible to specify an XTIDE ROM of up to 16Kb to work at address EC00h. It is also provided in this repository.

Other Open Source ROMs are available in the same folder:

* `pcxt_pcxt31.rom`: This ROM already has the XTIDE BIOS embedded at address F000h. ([Source Code](https://github.com/virtualxt/pcxtbios))
* `pcxt_micro8088.rom`: This ROM already has the XTIDE BIOS embedded at address F000h. ([Source Code](https://github.com/skiselev/8088_bios))
* `ide_xtl.rom`: This ROM corresponds to the XTIDE BIOS, it must be maintained for some scripts to work, it can also be upgraded to a newer version. ([Source Code](https://www.xtideuniversalbios.org/))

## Mounting the FDD image

The floppy disk image size must be compatible with the BIOS, for example:

* On IBM 5160 or Tandy 1000 only 360Kb images work well.
* On Micro8088 only 720Kb and 1.44Mb images work properly.
* Other BIOS may not be compatible, such as OpenXT by Ja'akov Miles and Jon Petroski.

It is possible to use images smaller than the size supported by the BIOS, but only pre-formatted images, as it will not be possible to format them from MS-Dos.

## Mounting the HDD image

Initially, and until an 8-bit IDE module compatible with XTIDE is available, HDD mounting will be done through the serial port available in the core via the OSD menu. The available transfer speeds are as follows:

* 115200 Kbps
* 230400 Kbps
* 460800 Kbps
* 921600 Kbps (Only works with CPU speed at 14.318MHz)

By default it is set to 115200, but the most suitable speed is 460800. It is also possible to use 921600, but only with the CPU speed at 14.318MHz.

The serial port speed change becomes effective after a BIOS reset, it is not possible to use the HDD drive after a speed change, the BIOS must always be reset after that.

## To-do list and challenges

* 8-bit IDE module implementation

## Developers

Any contribution and pull request, please carry it out on the prerelease branch. Periodically they will be reviewed, moved and merged into the main branch, together with the corresponding release.

Thank you!
