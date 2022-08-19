# PCXT_MiSTer
PCXT port for MiSTer by spark2k06.

The purpose of this core is to implement a PCXT as reliable as possible. For this purpose, the MCL86 core from @MicroCoreLabs and KTPC-XT from @kitune-san are used.

The Graphics Gremlin project from TubeTimeUS (@schlae) has also been integrated in this first stage.

JTOPL by Jose Tejada (@topapate)

SN76489AN Compatible Implementation in VHDL Copyright (c) 2005, 2006, Arnim Laeuger (arnim.laeuger@gmx.net)

Place pcxt.rom and tandy.rom (in SW folder) inside games/PCXT folder at root of SD card. Original and copyrighted ROMs can be generated on the fly using the python scripts available in the SW folder of this repository:

* make_rom_with_ibm5160.py: A valid ROM is created for the PCXT model (pcxt.rom) based on the original IBM 5160 ROM, and with the XTIDE BIOS embedded at address EC00h.
* make_rom_with_jukost.py: A valid ROM is created for the PCXT model (pcxt.rom) based on the original Juko ST ROM, and with the XTIDE BIOS embedded at address F000h.
* make_rom_with_tandy.py: A valid ROM is created for the Tandy model (tandy.rom) based on the original Tandy 1000 ROM, and with the XTIDE BIOS embedded at address EC00h.

Other OpenSource ROMs are available in the same folder:

* pcxt_pcxt31.rom

https://github.com/virtualxt/pcxtbios

This ROM should be renamed to pcxt.rom.

* pcxt_micro8088.rom: 

https://github.com/skiselev/8088_bios

This ROM should be renamed to pcxt.rom.

* ide_xtl.rom:

https://www.xtideuniversalbios.org/

This ROM corresponds to the XTIDE BIOS, it must be maintained for the scripts to work, it can also be upgraded to a newer version.

Discussion and evolution of the core in the following misterfpga forum thread:

https://misterfpga.org/viewtopic.php?t=4680&start=1020

# Mounting the disk image

Initially, and until an 8-bit IDE module compatible with XTIDE is available, floppy and hdd mounting will be done through the serial port available in the core via the OSD menu. The available transfer speeds are as follows:

* 115200 Kbps
* 230400 Kbps
* 460800 Kbps
* 921600 Kbps

By default it is set to 115200, but this speed does not work, as XTIDE does not identify it... The most suitable speed is 460800, although 921600 is possible to use only with the CPU speed at 14.318MHz.

The FDD image is recognised by XTIDE as B:, so to boot from floppy disk when booting, the 'B' key must be pressed when the XTIDE boot screen appears.

# To-do list and challenges

* Refactor Graphics Gremlin module, the new KFPC-XT system will make this refactor possible.
* 8-bit IDE module implementation
* Floppy implementation
* Addition of other modules

# Developers

Any contribution and pull request, please carry it out on the prerelease branch. Periodically they will be reviewed, moved and merged into the main branch, together with the corresponding release.

Thank you!
