# Acorn Electron

Port by David Wood - oldgit




## Introduction

This is a port of [ElctronFPGA](https://github.com/hoglet67/ElectronFpga) by David Banks, Mike Sterling. They have a good
description of the project here:   [Acorn Electron FPGA Project](https://www.mups.co.uk/post/2017/07/acorn-electron-fpga-project/)

## MMC Operation

Look for the ELK version of the beeb.mb and put it on the sdcard as boot.vhd

## Cassette Operation

The core starts in the MMC game menu (OSD Advanced: Autoboot). Press F10
(f0, the menu's EXIT) for the BASIC prompt, or set Autoboot Off. Load a
`.uef` or `.cas` file with the OSD Tape row, then type:

```
*TAPE
CHAIN""
```

Most games load with `CHAIN""`; a few say `*RUN` on their inlay.

- **Tape speed** (Machine page): `8x` (default) or `Normal`. While the
  cassette motor runs, the tape and the machine run 8 times faster, so the
  loader sees exactly what it expects; the moment the motor stops, the
  machine is back at normal speed.
- **Tape status bar** (Video page: Tape overlay): while the motor runs, the
  bottom-left corner shows `TAPE > elapsed/ total x8` and a progress bar.
  Times are tape time (1200 baud), so a 3:42 tape loads in under 30 s at 8x.
- **Rewind tape** (Machine page) goes back to the start; loading a new
  tape always starts at the start.
- Gzipped UEFs (as in the Stairway to Hell archive) load as they are.


## Mode 7

The core includes the JAFA Mode 7 board (a 6845 at &FC1C-&FC1F and an
SAA5050 teletext chip) with its ROM in slot 15. Switch it on once with
`*MODE7ON` (or `*M7ON`) and press BREAK; after that `MODE 7` is the BBC's
teletext mode: 40 x 25 characters, colour codes, graphics and double height.
`*MODE7OFF` and BREAK switch it off again. The picture is 480 x 250 at
12 MHz pixels, interlaced as on a BBC.

The JAFA ROM 1.91 here is patched: it added the byte at &0290 (`*TV`'s
vertical offset on a BBC) to the 6845's vsync position, but this MMFS uses
&0290 as workspace, so with an SD card the screen lost its vsync and went
black. Patched at &8A00 / &AA00: `ADC &0290` -> `ADC #0` (as `*TV 0`).


## Plus 3 (ADFS floppy drives)

Machine page: **Plus 3 (ADFS floppy)** On, then Apply and reset. Two rows
appear on the top page, Floppy 0 and Floppy 1 (Plus 3), for ADFS disc images:
`.adf` (ADFS S 160 KB / M 320 KB, one side) and `.adl` (ADFS L 640 KB, two
sides). Writes go back to the image. ADFS becomes the filing system:
SHIFT-BREAK (or Autoboot) boots drive 0, `*MOUNT` / `*CAT` / `*DIR` as usual;
`*CARD` (or Plus 3 Off) brings MMFS back. The Plus 3's control register
shares &FCC0 with the First Byte joystick, so First Byte reads there are off
while the Plus 3 is on.

The ADFS ROM, PRES ADFS 1.15 ("Advanced Plus 3", `roms/pres_adfs_1_15.rom`),
is built in as ROM 13 (slot 4 of the ROM image) and only answers while the
Plus 3 is on. To use a different ADFS ROM, build it in:

```
python3 roms/add_rom.py roms/ELK.mif <your ADFS rom> 4    # then compile
```

or, without rebuilding, make a 112 KB ROM image with it and use Load ROM
(or put it in games/AcornElectron as boot.rom):

```
python3 roms/add_rom.py roms/rom_image.bin <your ADFS rom> 4 boot.rom
```


## Cartridges

The OSD rows Cartridge 1 and Cartridge 2 are the Plus 1's two cartridge
sockets (ROMs 2/3 and 0/1). A `.rom` / `.bin` file of 16 KB fills the first
ROM of the socket; a 32 KB file fills both. Loading one resets the machine
so the MOS finds it. Most Acornsoft cartridges are ROM filing system
cartridges: type `*ROM`, then `*CAT` to see the files and
`CHAIN"name"` to run one (loading from ROM takes a few seconds).


## Notes from David Wood:


I used the front end for the BBC Micro by Sorgelig and adapted it for this port.

On start up you will need to ctrl-Break to clear the garbage on the screen. -- fix me

Put the Electron version of beeb.mb in games as boot.vhd (Acorn Electron Games & Magazines BEEB.MMB)


I cannot get used to the Func Number for Function Keys. -- Func = Caps Lock


I never had an Electron and the only time I saw one was when it was being used as a door stop
in the 'One Step Beyond' shop in Norwich.

