# Macintosh Plus for the [MiSTer Board](https://github.com/MiSTer-devel/Main_MiSTer/wiki)

This is a port of the [Plus Too core](https://github.com/mist-devel/mist-binaries/tree/master/cores/plus_too) from MiST which is the port of the [Plus Too project](http://www.bigmessowires.com/plus-too/).

I've tried to optimize the code with converting to synchronous style and fixing some glitches and instabilities.


## Usage

* Copy the [*.rbf](https://github.com/MiSTer-devel/MacPlus_MiSTer/tree/master/releases) onto the root of SD card
* Copy the [boot.rom](https://github.com/MiSTer-devel/MacPlus_MiSTer/tree/master/releases) to MacPlus folder
* Copy disk images in dsk format (e.g. Disk605.dsk) to MacPlus folder

After a few seconds the floppy disk icon should
appear. Open the on screen display using the F12 key and select the
a disk image. The upload of the disk image will take a few seconds. MacPlus will then boot into the MacOS desktop.

## Floppy disk image format

Floppy disk images need to be in raw disk format. Double sided 800k disk images have to be exactly 819200 bytes in size. Single sided 400k disk images have to be exactly 409600 bytes in size.

Both the internal as well as the external floppy disk are supported. The first entry in the OSD refers to the internal floppy disk, the second one to the external floppy disk.

Currently floppy disk images cannot be loaded while the Mac accesses a floppy disk. Thus it's recommended to wait for the desktop to appear until a second floppy can be inserted.

Before loading a different disk image it's recommended to eject the previously inserted disk image from within MacOS.

Official system disk images are available from apple at [here](https://web.archive.org/web/20141025043714/http://www.info.apple.com/support/oldersoftwarelist.html). Under Linux these can be converted into the desired dsk format using [Linux stuffit](http://web.archive.org/web/20060205025441/http://www.stuffit.com/downloads/files/stuffit520.611linux-i386.tar.gz), unar and [dc2dsk](http://www.bigmessowires.com/dc2dsk.c) in that order. A shell script has been provided for convenience at [releases/bin2dsk.sh](releases/bin2dsk.sh).

## Hard disk support

This MacPlus core implements the SCSI interface of the Macintosh Plus together with a 20MB harddisk. The core implements only a subset of the SCSI commands. This is currently sufficient to read and write the disk, to boot from it and to format it using the setup tools that come with MacOS 6.0.8.

The harddisk image to be used can be selected from the "Mount *.vhd" entry in the on-screen-display. Copy the boot.vhd to MacPlus folder and it will be automatically mounted at start. The format of the disk image is the same as being used by the SCSI2SD project which is documented [here](http://www.codesrc.com/mediawiki/index.php?title=HFSFromScratch).

Unlike the floppy the SCSI disk is writable and data can be written to the disk from within the core.

It has been tested that OS 6.0.8 can format the SCSI disk as well as doing a full installation from floppy disk to the harddisk. But keep in mind that this is an early work in progress and expect data loss when working with HDD images.

A matching harddisk image file can be found [here](https://github.com/MiSTer-devel/MacPlus_MiSTer/tree/master/releases). This is a 20MB harddisk image with correct partitioning information and a basic SCSI driver installed. The data partition itself is empty and unformatted. After booting the Mac will thus ask whether the disk is to be initialized. Saying yes and giving the disk a name will result im a usable file system. You don't need to use the Setup tool to format this disk as it is already formatted. But you can format it if you want to. This is only been tested with OS 6.0.8.

## CPU Speed

The CPU speed can be adjusted from "normal" which is roughly Mac Plus speed to "Fast" which is about 2.5 times faster. Original core couldn't boot from SCSI in turbo mode. This port has workaround to let it boot even with turbo mode.

## Memory

512KB, 1MB and 4MB memory configs are available. Cold boot with 4MB RAM selected takes some time before it start to boot from FDD/SCSI, so be patient. Warm boot won't take long time.

## Keyboard
The Alt key is mapped to the Mac's command key, and the Windows key is mapped to the Mac's option key. Core emulates keyboard with keypad.
