# Atari [5200](https://en.wikipedia.org/wiki/Atari_5200) and [Atari 800/800XL/65XE/130XE](https://en.wikipedia.org/wiki/Atari_8-bit_family) for [MiSTer Platform](https://github.com/MiSTer-devel/Main_MiSTer/wiki)

### This is the port of [Atari 800XL core by Mark Watson](http://www.64kib.com/redmine/projects/eclairexl)

### Installation
* Copy the *.rbf file to the root of the system SD card.
* Copy the files to Atari800/Atari5200 folder

## Usage notes

### System ROMs (Atari800)
*Note:* With the introduction of the VBXE implementation the core no longer has built-in ROM data and ROM files have to be supplied by the user as detailed here.
This also means that there is no OS built-in HSIO functionality (as it used to be before VBXE introduction), but one is provided through the PBI BIOS (see below).

You should supply XL/XE OS ROM as games/ATARI800/boot0.rom, or load a corresponding file through OSD (this file should be 16K in size). 
Supply XL/XE Basic ROM as games/ATARI800/boot1.rom, or load it through OSD (this file should be 8K in size).
Supply the "classic" A400/A800 OS-A or OS-B ROM as games/ATARI800/boot2.rom, or load it through OSD (this file should be 10K in size). 
Then, you can provide the PBI BIOS file as games/ATARI800/boot3.rom (8K in size), here there is no OSD menu option as the only file that is usable for this is distributed with the core.
Finally, you can load the TurboFreezer ROM (which will also enable it, the activation key is then Del or Scroll-Lock) through the OSD, here there is no corresponding bootX.rom file.

All OSD ROM loads are permanent (use Backspace when loading to clear them) for the next core load(s).
There is also an OSD option to ignore bootX.rom files to prevent any confusion as to which file (bootX.rom or menu selected one) is loaded on boot.

### Disks (Atari800)
After mounting the disk, press F10 to boot.
Some games don't like the Basic ROM. Keep F8(Option) pressed while pressing F10 to skip the Basic.
You can also boot a disk directly from the D1: drive using the first menu entry, the F10 Reset and F8 Option keys are applied automatically, any mounted carts are unmounted.
For ATX disk titles that are timing sensitive, you may also want to try to change the emulated drive timing between the older 810 disk drive, and the XL line 1050 one (this does not apply at all to non-ATX titles, the option has no effect). Moreover, some ATX titles will only load on the PAL or NTSC machine only, depending on which system they were designed for.
**Note:** ATR images inside ZIP containers are not writable, software that relies on being able to write to the disk might fail (sometimes ungracefully). Writing to disks is supported for ATR images outside containers, yet this can also be forced to be read-only with a menu option that makes all mounts write-protected. Finally, all ATX images are mounted read-only, ATX writing is currently not supported.

### Executable files (Atari800)
There is an entry to directly load the Atari OS executable files (the so called XEX files) using a high-speed direct memory access loader.
If a title does not load, you may want to try to switch the loader location in Atari memory (Standard - it sits at 0x700, Stack - it is located at the bottom of the stack area at 0x100).

### Tapes (Atari800)
The core supports CAS files of all flavors, including turbo / PWM ones, the system to use for turbo is selectable in the menu (some notes here: the first option assumes the tape is connected directly to usual SIO inputs, SIO/Cmd is the common system for most Turbo 2000 and similar systems where the data is connected to SIO and the motor is controlled through the SIO command line, K.S.O. 2 is different from K.S.O. in that it does not use the joystick 2 port for motor control and otherwise accounts for very sluggish loaders that turn the motor off with a huge delay, the other systems should be self explanatory). The Boot Tape option performs the complete tape boot procedure with START/OPTION pressed and the space key to trigger loading, this is very useful for non-Basic games. For manual tape loading (for example, for turbo systems) the Load Tape option should be used. For the impatient, the F11 key temporarily splashes the tape progress (this is only responsive once meaningful progress is registered since last check), the emulated tape sounds can be turned off in the Audio sub-menu. Finally, it is the nature of the tape emulation to get an exclusive hold of the SIO lines during transmission, a suspended / interrupted loading process (including tapes that start programs before the tape is fully read) can result in an unresponsive SIO system with no access to emulated disk drives, the first line of defense is to unmount the tape image (Backspace in the tape loading menu), then a hard reset (the last one) is the next option to unlock it, and then a full core reload in the worst case. There are no provisions to move around the tape from the menu, only full tape rewind is possible by re-loading the image file.

### Video options (Atari800)
Some require a tiny bit of clarification. The PAL/NTSC setting is currently not immediate and requires an Atari reboot (Warm F9 or Cold F10) to take effect. When VBXE is enabled you can load an alternative color palette from an ACT file (Adobe Color Table, 768 bytes in size), this setting is permanent (to remove, use Backspace when loading the palette), an example file with an NTSC palette is distributed with the core. The Interlace hack option tries to discover an exploitation of a known ANTIC bug to trigger a pseudo interlaced mode (240p becomes "somewhat of a" 480i) and adjust the video output accordingly. Currently there is a handful (literally) of regular or VBXE titles that do this, three simple demos and two games. When enabled, two deinterlacing modes for the HDMI output are available, if in doubt it is better to have this option disabled (as this is really just a hack and does not even always work on the original hardware, it should be considered experimental at best, and it's meant mostly for the digital HDMI output, not the analog/CRT one). Finally, NTSC artifacting options are disabled when VBXE is in use.

### Classic Atari 400/800 mode
In the Hardware/OS menu you can select the type of the machine for the core to work in the classic Atari 800 (or 400) mode (reset required to take effect), in which case a different OS ROM file is used (see above) and different memory layouts are available / activated. Note that the 52KB memory layout is not compatible with some modded 800 OS-A/B ROMs, and it can freeze the boot process. This is not a core bug, but an Atari 800 legacy. To remedy this make sure to load the genuine OS-A/B ROM file.
Additionally, in the classic 800 mode there are 4 controllers available to the Atari (as the original hardware had it), 4 controllers are also available in the 5200 core.
Note also, that at least in this mode, the XEX loader is not really bulletproof when loading subsequent XEX files (due to the nature of OS-A/B and the construction of the XEX loader), a manual cold reset (F10) might be sometimes required in-between loading of two (different) XEX files in the classis 800 mode.

### Cartridges
With the newer version of the core the database of supported cartridge types have been extended and the ability to "stack" cartridges have been added (through the option "Second Cart"). The stacking is only working or is useful when the first cartridge is a pass-thru type, these are the different kinds of SpartaDOSX cartridges. Moreover, now the selected distributions of SDX provided by the SpartaDOSX project are supported, you can use the ROM files for Ultimate 1MB or SuperCart directly with the core. When stacking, the size of the primary cartridge is limited to 1MB (this is only partly checked) when normally cartridges up to 4MB in size are supported. This, however, is not an actual limitation as all SDX releases are under 1MB. In the classic 800 mode, see above, the second cartridge functions as the right cartridge slot of Atari 800 and the actual stacking for SDX is not supported.

### Special ROMs (Atari800)
When loading a raw cartridge image, two types of files are treated specifically to their purpose: SpartaDOSX images for Ultimate 1MB and pass-thru SIDE2 (SuperCart) are treated as described below.

### PBI BIOS (Atari800)

The PBI BIOS enables accessing ATR images in a fast DMA-based fashion (works only with "friendly" images), provides an OS independent HSIO implementation, and provides basic support for HDD image emulation for SpartaDOSX. To enable the PBI BIOS first make sure that the boot3.rom file is placed in the games/ATARI800 folder on your SD card, and then you should be able to activate it in the OSD menu. No in-depth explanations of how SDX deals with hard drives or the general mechanics of PBI are given here, plenty of resources for this out there, but just some details particular to this PBI implementation. The splash options will make the Atari OS flash the PBI information during system boot, this is a non-interactive, information only screen (good as a reminder that PBI is turned on). The boot drive option essentially tells SDX where to end up after boot (currently selected drive) and where to search for the CONFIG.SYS and AUTOEXEC.BAT files. In the drives menu you can select how each particular emulated drive should behave against PBI probing, but there are internal overriding exceptions to this, for example, PBI mode is always on for XEX files mounted as disk drives, or ATX files are always handled as Stock/OS. Moreover, regardless of the drive settings, if an HDD partition is mounted at a particular drive it is always handled with PBI/DMA (obviously). For HDD images, only raw IMG files are supported (so no true VHD, fixed size or otherwise) and there can be be only one image mounted (so only one HDD device is emulated) at the moment, even though the SDX / Atari can cater for more. Finally, the PBI driver does not support dynamic partition or FAT hosted ATR files mounting, the PBI BIOS ID is fixed to 0, and the implementation also assumes there would be no other PBI devices in the system (rather impossible on a MiSTer), this allows to speed up some "PBI decisions" as well. Really final note - some Atari titles may not like this PBI BIOS implementation.

Practically, to use an HDD image with SDX you would first turn on the PBI, set the PBI boot drive to APT, then mount the HDD image, and then load the SDX Ultimate 1MB ROM image as a cart, this should boot the Atari into SDX with the HDD. To create an empty HDD image you can get into the Linux console, find the games/ATARI800 folder, and run `dd if=/dev/zero of=sdx_hdd.img bs=1M count=X` where X is your desired image size in MB. Finally, note that if you want to use an image created earlier on a PC and mounted in Altirra and formatted with an SDX running there you may get skewed up partition geometry (due to a bug / feature in Altirra, it would be already skewed there, problem reported to the author and fixed in the recent versions of Altirra).

### Differences from original version
* Joystick/Paddle mode switched by joystick. Press **Paddle1/2** to switch to paddle mode (analog X/Y). Press **Fire** to switch to joystick mode (digital X/Y).
* Use ` key as a **Break** on reduced keyboards.
* The original core used the Win key for pausing, right Alt(Gr) does this instead.
* Cursor keys are mapped to Atari cursor keys.
* PAL/NTSC mode switch in settings menu (A800)
* Video aspect ratio switch in settings menu
* Switchable side clipping of the video output to hide the GTIA "garbage". 
* An option to turn off the hi-res Antic extension from the original core, which brakes some titles.
* Some optimizations and tweaks in file selector and settings menu navigation.
* Standard OSD menu for cartridge/disk selection.
* Mouse emulates analog joystick(Atari 5200) and paddles(Atari 800).
* Fire 2 and Fire 3 on joystick.

### Disable Basic ROM by Joystick.
Fire 2 on joystick acts as an OPTION key while reboot. It's valid only 2 seconds after reboot. After that Fire 2 doesn't affect the OPTION key.

### More info
See more info in original [instructions](https://github.com/MiSTer-devel/Atari800_MiSTer/tree/master/instructions.txt)
and original [manual](https://github.com/MiSTer-devel/Atari800_MiSTer/tree/master/manual.pdf).

## Download precompiled binaries
Go to [releases](https://github.com/MiSTer-devel/Atari800_MiSTer/tree/master/releases) folder.
