# MiSTer port of TK2000 (Apple-II clone)

#### original TK2000 by Victor Trucco
[MC2+ Release Bitstream p/ download no Gitlab](https://gitlab.com/victor.trucco/Multicore_Bitstreams/-/tree/master/Multicore%202%20Plus/Computers/TK2000)

[MC2 Release Bitstream p/ download no Gitlab](https://gitlab.com/victor.trucco/Multicore_Bitstreams/-/tree/master/Multicore%202/Computers/TK2000)

Updated to MiSTer by alanswx


- VGA
- HDMI
- Drive Disk II 


#### Use

This can use DSK or NIB files. 

Load a disk in **Pri. drive (D1)** and the TK2000 boots it (with **Disk
interface** on Auto, a disk inserted while the machine is in BASIC reboots it
into the disk).

#### Reset

- **F2** (or OSD **Warm reset (F2)**) is the TK2000 **RESET** keys: the program
  stops and you get the BASIC `>` prompt, RAM kept, the drive is not tried.
  Like Ctrl-Reset on an Apple II, it is also the way out of an empty drive
  that is waiting for a disk.
- **Apply and reset** (and the board's reset button) is a cold start: the
  TK2000 boots the disk if the disk interface is there, otherwise BASIC.

#### OSD

```
TK2000
  Pri. drive (D1)    *.NIB/DSK/DO/PO   <- media: act at once
  Drive (D2)
  Tape               *.CT2
  Load ROM           (games/TK2000/boot0.rom by default)
  Machine  >   Disk interface Auto/On/Off, Tape speed 7x/Normal,
               Rewind tape, Tape play/stop
  Video    >   Display Color/B&W/Green/Amber, Aspect ratio, Scale,
               Scandoubler Fx, Tape overlay On/Off
  Audio    >   Tape audio Off/On
  Warm reset (F2)
   Changes pending
  Apply and reset
```

**Disk interface**: **Auto** (default) fits the disk interface only when D1
holds a disk at reset, so with just a tape the TK2000 starts in BASIC. **On**
is a machine with the interface always fitted: with D1 empty it waits on the
drive until you insert a disk or press F2. **Off** never fits it. Some tapes
refuse to run with the interface fitted (Karateka: "RETIRE SUA INTERFACE").

Aspect ratio, Scale (Normal / V-Integer / HV-Integer) and Scandoubler Fx
(None / HQ2x / CRT scanlines; the scandoubler also turns on for a VGA monitor
when the ini forces it) are the monitor and act at once. The TK2000 picture is
282 x 192 with no border, so V-Integer is 5x (960 lines) on a 1080p display.
**Original** is the TK2000's real picture shape, 1.26:1 (its 7.16 MHz pixels
are 6/7 as wide as tall), a little narrower than 4:3. On HDMI leave
Scandoubler Fx at None for the biggest integer picture: with it on, the scaler
gets 384 lines and V-Integer drops to 2x.

Display and Disk interface take effect at **Apply and reset** (the "Changes
pending" line shows while they differ from the running machine). Media, the
tape settings and the tape buttons act at once.

#### Tape (CT2)

1. Start in BASIC (`>` prompt): with Disk interface on Auto and D1 empty it
   already is. If the TK2000 is waiting on an empty drive, the hint says
   `PRESS F2 FOR BASIC`.
2. Load the `.ct2` in the **Tape** slot. A hint in the bottom-left corner says
   `TYPE LOADT ↵`.
3. Type `LOADT` and press Return. The tape starts by itself when the ROM starts
   reading it, and a status bar in the top-left corner shows elapsed/total time
   and progress.
4. Many tapes hold a BASIC program and stop at the `>` prompt after
   `NAME xx xx WAIT OK`: type `RUN` and press Return.

**Tape speed 7x** (default) runs the TK2000 seven times faster while the tape
plays, so a tape loads in a seventh of the time; the machine is back to normal
speed the moment the tape stops. **Tape play/stop** pauses the tape (Karateka:
stop it when "PLANSOFT apresenta" appears to watch the intro), **Rewind tape**
rewinds it. **Tape audio** plays the tape signal through the speaker.

##### Change log prior to official MiSTer conversion

- 003 : 09/12/2019 - HDMI and FAT32 disk support
- 002 : 09/07/2018 - initial version Multicore 2
- 001 : 16/03/2017 - initial release
