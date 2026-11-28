# BK0011M for [MiSTer Board](https://github.com/MiSTer-devel/Main_MiSTer/wiki)

This project of [popular USSR home computer](https://en.wikipedia.org/wiki/Electronika_BK) is based on precise [KR1801VM1](http://zx-pk.ru/showthread.php?t=23978) Verilog model by Vslav

### Features:
- Fully functional BK0011M and BK0010 with close to real CPU and Video timings (need furter corrections)
- Turbo mode (6MHz for BK0010, 8MHz for BK0011M)
- Disk controller selectable for both models: standard KNGMD (4 drives), A16M, SMK512, standard KNGMD + Samara HDD (2 drives each), or none
- Floppy controller KR1801VP1-128 with drives A-D (read, write, format), raw DSK/IMG/BKD images
- SMK-512 IDE hard disk (Disk controller = SMK512): raw SMK disk dumps (.hds/.img, data stored inverted as on the real disk) or BKEmu .hdi images. Image slot 0: `boot0.vhd` in games/BK0011M/ is mounted at start.
- Samara HDD controller (Disk controller = Samara): standard KNGMD with the Samara disk ROM and the IDE registers at 177620-177656, Samara-format images (.hdi or raw), C: and up through the ROM's disk calls
- BIN file support for BK0010 mode (only single file apps are supported)
- A16M extension (support for short and long resets)
- SMK512 extension
- YM2149 with 1.71MHz clock
- Joystick
- Mouse

No contention model is used in turbo mode, thus speed is higher more than twice.

### Installation:
Copy the *.rbf file at the root of the SD card.

There are couple disk images in [extra](https://github.com/MiSTer-devel/BK0011M_MiSTer/tree/master/extra) folder with CSIDOS OS with complete ecosystem (viewer,text editor, music editor, debugger, etc.) written by me more than 20 years ago. Image also incudes some music and utils written by different people.

*Most documents are in Russian languange.*

Press F12 to access OSD menu.

##### Keyboard map:

| PC key      |  BK Key       |
|:-----------:|:-------------:|
| ESC         | KT            |
| F1          | ПОВТ          |
| F2          | ВС            |
| F3          | ГРАФ          |
| F4          | Color/Mono    |
| F5          | -!->          |
| F6          | ИНДСУ         |
| F7          | БЛОК РЕД      |
| F8          | ШАГ           |
| F9          | СБР           |
| F10         | СТОП          |
| RCtrl+F11   | RESET         |
| F11         | Change colors |
| F12         | OSD Menu      |
| Insert      | !-->          |
| Delete      | !<--          |
| Shift+Enter | УСТ ТАБ       |
| Shift+Tab   | СБР ТАБ       |
| Alt+Tab     | ШАГ ПО ТАБ    |
| Left Win    | ЛАТ           |
| Left Ctrl   | РУС           |
| Right Ctrl  | УС (Ctrl)     |
| Alt         | АР2 (Alt)     |

### Disk images:
Floppies are raw 800 KB (or 400 KB) dumps: .dsk, .img, .bkd. A hard disk is an AltPro (SMK-512) or Samara image: a raw dump of a real disk or a BKEmu .hdi; `tools/mkbkhdd.py` makes one out of floppy images (`--samara` for the Samara layout), each becoming a logical disk from C: on:

    tools/mkbkhdd.py -o games.img --hdi ANDOS330.DSK CSIDOS_330.DSK ...

The SMK BIOS boots the boot unit (C: unless `--boot`). An OS copied from a floppy may still look for its files on A:, as its floppy configuration says: use an OS set up for the hard disk, or keep a floppy in A:. In BK0010 mode the disk ROM does not boot by itself: at the monitor's `?` prompt type `S 160000`.

Images of the old core (`bkhdutil`'s .vhd with the BKHD header) mount with Disk controller = Samara: their partitions become C:, D:, ... and the disk boots from C:.

### Additional info:
ROM contains debugger which can be launched by following commands from Monitor:
- **13;1C**
- **100000G**

if disk support in OSD is turned off, then diagnostic utility can be launched by following command from Monitor:
- **160000G**

### Download precompiled binaries:
Go to [releases](https://github.com/MiSTer-devel/BK0011M_MiSTer/tree/master/releases) folder.
