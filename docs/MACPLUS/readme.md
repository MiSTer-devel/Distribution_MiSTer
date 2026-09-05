# Macintosh Plus for the [MiSTer Board](https://github.com/MiSTer-devel/Main_MiSTer/wiki)

This is a port of the [Plus Too core](https://github.com/mist-devel/mist-binaries/tree/master/cores/plus_too) from MiST which is the port of the [Plus Too project](http://www.bigmessowires.com/plus-too/).

I've tried to optimize the code by converting to synchronous style and fixing some glitches and instabilities.

## Usage

* Copy the [*.rbf](https://github.com/MiSTer-devel/MacPlus_MiSTer/tree/master/releases) onto the root of SD card
* Copy [boot0.rom & boot1.rom](https://github.com/MiSTer-devel/MacPlus_MiSTer/tree/master/releases) (Plus and SE ROM files) to MacPlus folder
* Copy disk images in dsk format (e.g. Disk605.dsk) to MacPlus folder

After a few seconds, the floppy disk icon should appear. Open the on-screen display using the F12 key and select the a disk image. The disk image mounts as a block device and is available to the Mac almost immediately. If a bootable system is found on disk, a smiling Mac icon will appear. MacPlus will then begin booting into the desktop.

## Floppy disk support

Internal and external floppy disk drives are both supported. The first and second entries in the OSD correspond to the internal and external floppy disk drives, respectively.

Floppy disk images need to be in raw disk format (a.k.a. DiskDup format) with a .dsk extension. Single-sided 400k disk images must be exactly 409,600 bytes in size. Double-sided 800k disk images must be exactly 819,200 bytes in size.  Disk Copy 4.2 files are not currently supported. They are largely the same as raw disk format, but include an additional 84-byte header. A tool to convert DC42 format to dsk is available [here](https://www.bigmessowires.com/2013/12/16/macintosh-diskcopy-4-2-floppy-image-converter/).

Floppy disk images are writable, gated by the "Floppy Write" entry in the on-screen display (defaults to Off/protected - writes must be explicitly enabled). A disk image that is itself marked read-only on the SD card is always honoured as write-protected, regardless of this setting. Writes commit back to the exact .dsk file on the SD card and survive eject/remount and a full power cycle.

Floppy disk images cannot be loaded while the Mac accesses a floppy disk. Thus, it's recommended to wait for the desktop to appear until a second floppy can be inserted. Before loading a different disk image, it's recommended to eject the previously inserted disk image from within the OS - this now matters for data integrity, not just stability, since an image can be actively written to.

Floppy disks are readable at both 8 MHz and 16 MHz CPU speeds. (Earlier versions could not read a floppy at 16 MHz: the IWM's read-data latch was cleared on a fixed wall-clock interval while the driver's polling loop scaled with the CPU, so at 16 MHz the driver polled faster than the latch cleared and read every disk byte twice. The clear interval now scales with the selected CPU speed.)

Official system disk images are available from an archived Apple support page [here](https://web.archive.org/web/20141025043714/http://www.info.apple.com/support/oldersoftwarelist.html). Under Linux these can be converted into the desired dsk format using [Linux StuffIt](http://web.archive.org/web/20060205025441/http://www.stuffit.com/downloads/files/stuffit520.611linux-i386.tar.gz), unar, and [dc2dsk](http://www.bigmessowires.com/dc2dsk.c), in that order. A shell script has been provided for convenience at [releases/bin2dsk.sh](releases/bin2dsk.sh). 

## Hard disk support

The MacPlus core supports SCSI hard drive images up to 2GB (HFS) in size, with a .vhd or .img extension. The core currently implements only a subset of the SCSI commands. This is sufficient to read and write the disk, to boot from it, and to format it using the setup tools that come with System 6.0.8.

Two SCSI hard disks are supported, at SCSI IDs 6 and 5. The images to be used are selected from the "Mount SCSI-6" and "Mount SCSI-5" entries in the on-screen display (.img or .vhd). Copy the boot.vhd to MacPlus folder and it will be automatically mounted at start. The format of the disk image is the same as the one used by the SCSI2SD project, documented [here](http://www.codesrc.com/mediawiki/index.php?title=HFSFromScratch).

The SCSI disks are writable, and unlike the floppy they need no OSD option to make them so.

It has been tested that System 6.0.8 can format the SCSI disk, as well as doing a full installation from floppy disk to the harddisk. However, keep in mind the core is an early work in progress and expect data loss when working with HDD images.

A matching harddisk image file can be found [here](https://github.com/MiSTer-devel/MacPlus_MiSTer/tree/master/releases). This is a 20MB harddisk image with correct partitioning information and a basic SCSI driver installed. The data partition itself is empty and unformatted. After booting the Mac will thus ask whether the disk is to be initialized. Saying yes and giving the disk a name will result in a usable file system. You don't need to use the Setup tool to format this disk as it is already formatted, but you can format it if you want to. This has only been tested with System 6.0.8.

A tool to create harddisk images (with working SCSI driver and partition table) is available [here](https://diskjockey.onegeekarmy.eu/).

## CD-ROM support

A SCSI CD-ROM drive is emulated at SCSI ID 3, selected from the "Mount CD-ROM" entry in the on-screen display. ISO, TOAST, CUE/BIN and CHD images are accepted. The drive presents the disc as a single data track of 2048-byte blocks, which is what an AppleCD SC returned and what the Mac's CD-ROM driver expects.

**This needs a Main_MiSTer that knows about the MacPlus CD-ROM slot.** Without it the image appears to mount and then reads as garbage, with no TOC and no audio. The change is merged into Main_MiSTer and reaches users with the next MiSTer binary release.

A Mac Plus cannot boot from CD - no ROM of that era could - so the disc is mounted by the operating system after it has started. System 6 and System 7 need Apple's CD-ROM driver installed on a hard disk before a disc will appear on the desktop; without it the drive is present on the bus but nothing mounts. As on real hardware, the disc is ejected on shutdown.

Setting "CD-ROM Drive" to Disabled removes the drive from the SCSI bus entirely, leaving a bus identical to a disks-only machine.

### CD audio

Audio tracks play through the core's audio output, mixed with the Mac's own sound. This needs an image format that carries the audio tracks - CUE/BIN or CHD.

"CD Volume" sets the drive's own output level (Full, 3/4, 1/2, Off). It is deliberately independent of the Mac's volume control: on real hardware the Mac's setting had no effect on the drive, which had its own knob.

## CPU

The CPU speed can be adjusted to 8 MHz (original speed) or 16 MHz. This port implements a workaround to allow booting from SCSI when using the 16 MHz configuration.

The CPU model can be set to 68000, 68010 or 68020. Note that this also swaps the CPU core: 68000 is the cycle-accurate fx68k, while 68010 and 68020 use TG68K, which is not. Timing-sensitive software can behave differently in those modes for that reason as much as for the CPU model itself. Changing the model takes effect on "Reset & Apply CPU+Memory".

## Memory

1MB and 4MB memory configurations are available. Cold boot with 4MB RAM selected takes some time before it starts to boot from FDD/SCSI, so be patient. Warm boot won't take as long.

## Keyboard

The Alt key is mapped to the Mac's Command (⌘) key, and the Windows key is mapped to the Mac's Option (⌥) key. Core emulates keyboard with numeric keypad.
