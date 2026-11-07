# Sun-3 for MiSTer

A Sun-3/60C workstation for the MiSTer FPGA platform. This is a 68020 Sun with
Sun's own MMU, an MC68881, 24 MiB of memory, the on-board bw2 and a P4 colour
board: the cg4, or the accelerated GX (cg6). It also has the LANCE Ethernet,
the on-board SCSI with two disks, a QIC tape and a CD-ROM drive, the Sun
keyboard and mouse, and the ICM7170 clock. It runs Sun's own boot PROM,
SunOS and NetBSD.

**Status: early, but it boots SunOS.** On a MiSTer the boot PROM (Rev
3.0.1; Rev 1.9 runs too) comes up on the colour board's console or the mono
one, takes the keyboard, and keeps its settings in an EEPROM file. SunOS 4.1.1 installs from QIC tape images onto
a 1 GB disk image and boots from it multi-user, and takes 4.1.1_U1, the Y2K
patch and Sun's later patches
([docs/install-sunos.md](docs/install-sunos.md)). A second disk works,
SunView and OpenWindows 2.0 run in mono and in colour with the mouse, on
the cg4 or the GX, the Ethernet works (see *The network*), and the CPU runs
at 20, 25 or 33 MHz (see *The CPU clock*). SunOS reads CD-ROM images, and
NetBSD 11.0 installs from its CD image and runs (see *NetBSD*).

New in `Sun-3_20261024.rbf`:
* the **GX** (cg6), Sun's accelerated colour board, as a choice for the P4
  slot (see *Colour*);
* a **CD-ROM drive** at SCSI ID 6 (see *The CD-ROM*);
* the tape drive now works under NetBSD as well as SunOS.

* [docs/hardware.md](docs/hardware.md): the machine, as locked with the
  owner. It covers the inventory, the address map and the media.
* [docs/design-plan.md](docs/design-plan.md): how it is built. It covers where
  each piece comes from, the clocks, memory and OSD, the phases with their
  acceptance tests, the budget and the risks.
* [docs/references/](docs/references/): an index of the manuals,
  schematics and [sun3arc.org](https://www.sun3arc.org/) pages the design
  relies on, with the text ones (a partial mirror of sun3arc.org) here.

## Lineage

The machine comes from
[MelkhiorVintageComputing/Sun-3_FPGA](https://github.com/MelkhiorVintageComputing/Sun-3_FPGA)
by Romain Dolbeau. It is a Sun-3/60 that boots SunOS 4.1.1 and NetBSD on
Artix-7 and MAX 10 boards, with:
* [RD68021](https://github.com/MelkhiorVintageComputing/RD68021) (68020);
* [RD68884](https://github.com/MelkhiorVintageComputing/RD68884) (68881);
* [Wish7990](https://github.com/MelkhiorVintageComputing/Wish7990) (LANCE);
* [Wish5380](https://github.com/MelkhiorVintageComputing/Wish5380) (NCR 5380).

The MiSTer side follows [Sun-2_MiSTer](https://github.com/danifunker/Sun-2_MiSTer),
whose SDRAM, disk/tape, keyboard/mouse, bell, clock and network glue is reused.
The network and the ID PROM are served by Main_MiSTer's Sun family support
(`support/sun`, branch `sun-family`).

## What you will need

* **the core**, from [`releases/`](releases/): `Sun-3_20261024.rbf`, for
  `_Computer/` (or `_Unstable/`). The previous core, `Sun-3_20261022.rbf`,
  is kept there too; it has no GX and no CD-ROM;
* a DE10-Nano with an **SDRAM board of 32 MB or more**;
* the boot PROM, Sun's Rev 3.0.1 for the 3/60, patched for this machine,
  at `games/Sun-3/boot0.rom`: `releases/boot0.rom` (see *The boot PROM*);
* SunOS for sun3 on a QIC tape image: `python3 tools/mktape -o
  sunos-4.1.1-sun3.qic <the distribution's sun3 directory>`. Mount it as
  *Tape (ID 4)* in the OSD. To install onto a disk, see
  [docs/install-sunos.md](docs/install-sunos.md).

## The boot PROM

The core runs Sun's own 3/60 boot PROM, Rev 3.0.1. It is not in the
bitstream: Main_MiSTer sends `games/Sun-3/boot0.rom` when the core starts,
and the machine stays in reset until it has arrived. `releases/boot0.rom`
is the stock image with seven patches, each listed with its reason in
[`tools/sun3_60_v3.0.1_noparity.txt`](tools/sun3_60_v3.0.1_noparity.txt)
(and, at their places in Rev 1.9, in
[`tools/sun3_60_v1.9_noparity.txt`](tools/sun3_60_v1.9_noparity.txt)):

* six take out the parity memory this machine does not have (Sun-3_FPGA's
  verified "noparity" set): the PROM no longer turns parity checking on,
  skips its two parity self-tests (0x0E and 0x0F, which force parity
  errors), and no longer touches the memory error register, in its NMI
  handler, after its memory test, or in the monitor's `k` command;
* one, this core's own, makes the power-on memory fill zeros instead of
  0xffffffff: SunOS 4.1.1's tape boot reads leftover boot arguments as
  string pointers, and 0xffffffff made it overwrite itself.

To make the same file yourself, `make -C tools` fetches the stock image
from sun3arc.org (or takes one dropped into `build/rom/` as
`sun3_60_v3.0.1.bin`), checks its SHA-256, and writes
`build/rom/sun3_60_v3.0.1_noparity.bin` (sha256 `9162b135…2e21`, the same
as `releases/boot0.rom`). `tools/rompatch` checks every word it changes
before changing it, and keeps the PROM's checksum right.

Rev 3.0.1 prints the Host ID in its banner, and its SCSI unit numbers are
target × 8 + LUN: the second disk (ID 1) is `b sd(0,8,0)`.

### Rev 1.9

Rev 1.9, the PROM this core first ran, still runs: `make -C tools
all-roms` writes `build/rom/sun3_60_v1.9_noparity.bin` (sha256
`31688f6f…63de`). Put it in `games/Sun-3/` under any name ending `.rom`
and pick it with *Load ROM*: the machine resets into it for that session,
and the next start loads `boot0.rom` again. Its disk unit numbers are
target × 4 + LUN, so its second disk is `b sd(0,4,0)`; it has the fuller
diagnostic menus (video, colour map, SCSI and memory tests) that 3.0.1
dropped.

## Booting from tape

With no disk mounted, the PROM tries the disk, prints `sd: error` lines and
then "Waiting for disk to spin up ... press any key to quit". Press a key,
and at the `>` prompt type

    b st()

SunOS 4.1.1's tape boots its miniroot and asks whether to install it.
The PROM's own tape open waits ten seconds for the drive, as on a real 3/60.
L1-A (see *The keyboard*), or *Stop-A (abort)* on the OSD's *Machine* page,
stops SunOS and returns to the PROM; `c` continues it.

## The keyboard

The PC keyboard is a Sun Type 3, and the mouse a three-button Mouse Systems
one. Most keys are where they are on the PC. The Sun keys a PC lacks:

| Sun | PC |
|---|---|
| L1..L10 (Stop, Again, Props, Undo, Front, Copy, Open, Paste, Find, Cut) | **hold Right Alt** and press F1..F10 |
| L1-A, the abort to the PROM | Right Alt + F1, and A while F1 is held (or *Stop-A* in the OSD) |
| T1..T9, the top row | F1..F9 |
| Meta (the diamond keys) | the Windows keys |
| Alt | Left Alt |
| R1..R15, the right keypad | the numeric keypad and the navigation keys: Num Lock R1, / R2, * R3, - R4, + R5; the arrows R8, R10, R12, R14; Home R7, PgUp R9, End R13, PgDn R15 |
| Line Feed | keypad Enter |
| Delete | Delete |

Right Alt sends nothing by itself. MiSTer keeps Scroll Lock, F12 (the OSD)
and F13 up, so they never reach the Sun.

*Swap Alt/Win keys* on the *Input* page swaps each Alt with the Windows key
beside it: the key next to the space bar is then Meta, the Windows keys are
the Alts, and the L-keys are held with the **Right Windows** key instead of
Right Alt. It acts at once.

## The OSD

The menu follows the layout of the other MiSTer workstation cores. On the top
page:

* *Pri. disk (ID 0)*, *Disk (ID 1)*, *Tape (ID 4)*, *Tape volume* and
  *CD-ROM (ID 6)*: the media, which change at once. The disks, the CD-ROM
  image and the EEPROM image are remembered and mounted again at the next
  start; the tape is not;
* *Load ROM*: another boot PROM for this session (see *The boot PROM*);
* *Network interface* (see *The network*);
* the pages below, and *Apply and reset*.

| page | rows |
|---|---|
| Machine | *CPU clock* (20, 25, 33 MHz), *Colour board* (On, Off), *Colour board type* (cg4, GX; shown while the board is On), *Stop-A (abort)* |
| Video | *Aspect ratio*, *Scale* |
| Input | *Swap Alt/Win keys* |
| Audio | *Keyboard bell* (Normal, Loud, Quiet, Off) |
| Advanced | *Diag switch*, *Clock* (MiSTer's time, or 28 years back: the same day, weekday and time in 1998, for a SunOS without the Y2K patch), *EEPROM image* |

Media, *Network interface*, *Input* and *Stop-A* act at once. Every other
change waits for a reset, as a board's jumpers would: *Changes pending*
shows above *Apply and reset* until then. To keep settings for the next
start, use *Save settings* on the OSD's System page.

## The EEPROM

A Sun-3 keeps its settings in a 2 KiB EEPROM: the boot device, the console,
the serial ports' speeds and more. The core keeps it in a 2048-byte file on
the SD card. Create one once, for example on the MiSTer:

    dd if=/dev/zero of=/media/fat/games/Sun-3/Sun-3.nvr bs=2048 count=1

and pick it in the OSD under **EEPROM image** (the *Advanced* page). MiSTer remembers it, and the core
reads it at every start, before the PROM runs. Changes are written back to
it half a second after the machine makes them, from the PROM's `q` command
or from SunOS's `eeprom`. A file picked while the machine runs is read at
once, and the PROM looks at it at the next reset. Without a file the EEPROM
starts from the core's built-in settings at every load, and changes last
until the core is loaded again.

A new, all-zero file is given the built-in settings the first time it is
loaded. The built-in settings are: 24 MiB, boot from `sd`, the console on
the screen and keyboard, ttya and ttyb at 9600. A read-only file is read but
never written.

At the PROM's `>` prompt, `q` and an offset open the EEPROM at that byte,
and the PROM shows its value. Type a new value in hex and Return to change
it; Return alone goes on to the next byte, and `q` and Return end. The boot
device is the two letters at 0x19 and 0x1A, `sd` (73 64). To make it `st`,
the tape:

    >q 1a
    EEPROM 01A: 64? 74
    EEPROM 01B: 00? q

From the next load on, the machine boots its tape by itself; L1-A stops it
at the PROM. The offsets are NetBSD's `dev/sun/eeprom.h`.

The console byte (0x1F) follows the OSD's *Colour board* at every reset: the
P4 board (0x20) with it, the bw2 (0x00) without. A serial console (0x10 for
ttya, 0x11 for ttyb) is left as it is.

## The picture

The Sun's screen is 1152×900, and the core sends it as 1160×904: the screen
and a thin black border. **Give the Sun-3 a 1080p (or 1280×1024) output.**
MiSTer's default, 1280×720, has fewer lines than the Sun's screen, so the
scaler has to shrink it, and a shrunk one-pixel font cannot look right. At
1080p the default *Scale*, V-Integer, shows each Sun pixel as exactly one
screen pixel, in a border. In `MiSTer.ini`:

    [Sun-3]
    video_mode=8        ; 1920x1080@60

`video_mode=4` (1280×1024@60) suits a 5:4 monitor, with the picture 1:1 and a
narrow border.

## Colour

The machine has a **cg4** in its P4 slot, as a 3/60C does: 1152×900 in 256
colours from 16.7 million, with an overlay plane. The OSD's *Colour board*
(**On** by default) fits it, and the PROM's banner then says
`Model Sun-3/60C/G` and draws its console in the overlay. *Off* is a 3/60 with
only the on-board mono bw2 (`Model Sun-3/60M`). Change it, then reset. The
colour board costs the CPU no measurable speed.

*Colour board type* **GX** puts Sun's accelerated colour board, the cg6,
in the slot instead: 1152×900 in 256 colours, with a drawing engine that
fills, copies, draws lines, polygons and text by itself, a transform engine
for OpenWindows, and a hardware cursor. SunOS 4.1.1 finds it as `cgsix0`.
SunView and OpenWindows 2.0 both run on it, and colour SunView scrolls text
faster on the GX than mono SunView does on the bw2. The PROM's banner still
says `Sun-3/60C/G`. The GX needs the Rev 3.0.1 PROM: Rev 1.9 has no console
on it. docs/cg6.md describes the board.

## The CPU clock

A 3/60's 68020 and 68881 run at 20 MHz. The OSD's *CPU clock* also offers
**25 MHz**, which owners reached by overclocking real 3/60s, and
**33 MHz** (33.33), beyond any 3/60: the clock of the fastest Sun-3x, the
3/470. Everything that keeps time has its own clock, so the time of day, SunOS's
clock, the serial ports, the keyboard, the network and the picture stay
right; programs simply run faster. Dhrystone 2.1 on the MiSTer:

| CPU clock | Dhrystones a second |
|---|---|
| 20 MHz | 3,250 |
| 25 MHz | 4,076 |
| 33 MHz | 5,450 |

As with a crystal on a real board, the clock changes only in a reset:
change it, then halt SunOS and choose *Apply and reset* (a change made
while SunOS runs waits for the next reset, and the OSD shows *Changes
pending* until then). To keep it for the next start, use *Save settings* on
the OSD's System page.

## NetBSD

NetBSD 11.0 for sun3 installs onto a disk image and boots from it. Its
11.0 boot programs have a bug that panics the kernel on a 3/60 ("radix
already initialized"), fixed by NetBSD after the release;
[`tools/netbsd/fixdvma.py`](tools/netbsd/fixdvma.py) makes the same fix in
the 11.0 files. In outline (the design plan, Phase 7, has the details):

1. From the NetBSD 11.0 ISO, build a boot tape as its `MakeBootTape` does
   (tapeboot, the RAMDISK kernels, the miniroot), with every file run
   through `fixdvma.py`, and `tools/mktape` it into a `.qic`.
2. `python3 tools/mktape --disk netbsd.img --size 1024` for the disk, at
   *Disk (ID 1)*; the ISO at *CD-ROM (ID 6)*; the tape at *Tape (ID 4)*.
3. `b st()`, then put the mended miniroot into the disk's swap partition
   and boot it with `b sd(0,8,1) -s`.
4. `install`: root disk `sd1`, sets from the CD-ROM (`cd0`, ISO 9660,
   `sun3/binary/sets`). It takes about two hours at 33 MHz.
5. `b sd(0,8,0)` boots it (Rev 3.0.1 numbers the disk at ID 1 as 8).

The installed disk boots with no patch. A netbsd-11 build from after
2026-08-22 would not need `fixdvma.py` at all.

## Window systems

SunOS 4.1.1 has two, both on its tapes: **SunView 1**, Sun's own (SunOS
keeps its programs in `/usr/bin/sunview1`), and **OpenWindows 2.0**, X11
and NeWS with the OPEN LOOK look (the only OpenWindows on the tapes). Both
start from the shell prompt on the Sun's own screen (log in
on the console, not on a serial line or by telnet), one at a time, and each
gives the console back when it exits.

| | SunView 1 | OpenWindows 2.0 |
|---|---|---|
| start | `sunview` (see below for the planes) | `/usr/openwin/bin/openwin` |
| up in | about 10 s (mono) | about 2 minutes at 20 MHz |
| on the colour board | colour, mono overlay, or both | colour (8-bit) |
| exit | right button on the background, *Exit SunView* | right button on the background, *Exit...* |
| programs | `shelltool`, `cmdtool`, `/usr/demo/sunview1` | `/usr/openwin/bin`, `/usr/openwin/demo` |

SunView starts in seconds, and draws fastest in mono; OpenWindows takes two
minutes to start, and runs X11 and NeWS programs.

## SunView

SunView 1 starts from the shell prompt on the screen (not on a serial
port). With the colour board it has two planes to choose from:

    sunview -8bit_color_only     # the colour plane: 256 colours
    sunview -overlay_only        # the overlay: black and white
    sunview                      # both: mono windows, colour where a program asks

**A USB mouse on the MiSTer is the Sun's mouse.** Typing goes to the window
under the pointer. Holding the **right** button over the grey background
opens the root menu (shells, tools, and *Exit SunView*, which asks for a
click to confirm). In an emergency, Ctrl-D then Ctrl-Q over the background
quits at once. `/usr/demo/sunview1/spheresdemo`, run in a shelltool, draws
colour spheres. Colour SunView is about 3.4 times slower than mono: the cg4
has no raster-op hardware, so the CPU moves 8 bits a pixel instead of 1, as
on a real 3/60C.

The two planes can also hold a desktop each, with the pointer moving from
one to the other across the screen's edge (sunview(1), "Multiple Desktops on
the Same Screen"). On this machine the overlay is `/dev/bwtwo1`, which has to
be made once:

    mknod /dev/bwtwo1 c 27 1
    sunview -8bit_color_only -toggle_enable
    # then, in a shelltool of that desktop:
    sunview -d /dev/bwtwo1 -toggle_enable -n &
    adjacentscreens -c /dev/fb -l /dev/bwtwo1

## OpenWindows

OpenWindows 2.0 (X11 and NeWS in one server, `xnews`, with the OPEN LOOK
window manager `olwm`) is on the 4.1.1 tapes, under `/usr/openwin`. Start it
from the shell prompt on the screen:

    /usr/openwin/bin/openwin

It takes about 2 minutes to come up, in colour, with a console window and
the File Manager. Click in a window to type into it. The **right** button
over the background opens the Workspace menu; its *Exit...* asks to confirm
and returns to the console. X demos are in `/usr/openwin/demo`; the NeWS ones
there (`colorwheel`, `fish`) run with `psh`, from a shell inside OpenWindows.
It runs on the cg4, on the GX, and in black and white with the colour board
Off.

`psh monaeyes` stops the server: the sun3 `xnews` has a bug in its image
scaling that crashes it whenever a NeWS image is drawn scaled, on any
frame buffer. `ico2` is the older ico and takes its size as
`=300x300+800+500`, not `-geometry`.

## The CD-ROM

*CD-ROM (ID 6)* in the OSD takes an `.iso` image (2048-byte sectors). The
drive is a Sony CDU-8012, one of the drives SunOS 4.1 knows, read only.
Under SunOS it is `sr0`:

    mkdir /cdrom
    mount -r -t hsfs /dev/sr0 /cdrom

The PROM boots a Sun CD through its disk driver, as `b sd(0,30,N)` with N
the partition (sun3arc's install guide gives `b sd(0,30,4)` for the SunOS
4.1.1 CD). NetBSD finds the drive as `cd0` and installs from it (see
*NetBSD*). BIN, CUE and CHD images are not taken.

## The network

The machine's Ethernet is its own AMD LANCE, whole in the FPGA. The core
plays the transceiver behind it and passes its frames through DDR3 to
Main_MiSTer, which puts them on a host interface: the same arrangement as
the Sun-2, NeXT and Minimig A2065 cores. **It needs a Main_MiSTer with Sun
support** (`support/sun/`, the `sun-family` branch of
[danifunker/Main_MiSTer](https://github.com/danifunker/Main_MiSTer/tree/sun-family));
without it the LANCE is on a cable to nowhere, and SunOS attaches `le0` all
the same. *Network interface* in the OSD picks the host side:

| Network interface | what it is |
|---|---|
| eth0 (the default) | MiSTer's own Ethernet port, shared: the Sun is a second machine on the LAN, with its own address |
| None | no cable |
| eth1 | a second port (a USB adapter), the Sun's alone |
| macvlan | a virtual port on eth0 with the Sun's address |
| tap0 | a tap interface on the MiSTer, for routing it yourself |

With *eth0* the Sun can reach and be reached by every machine on the LAN
except the MiSTer it runs on. It runs at 10 Mb/s, the LANCE's own speed.
Main makes the Sun's Ethernet address (and its `hostid`) from the MiSTer's
own, unless `games/Sun-3/boot1.rom` holds an ID PROM. SunOS 4.1.1 has no
DHCP, and a system installed without a network names the machine
`127.0.0.1` in `/etc/hosts`. To try it by hand:

    ifconfig le0 192.168.1.50 netmask 255.255.255.0 broadcast 192.168.1.255 up
    /usr/etc/ping 192.168.1.1

and to keep it: rename `/etc/hostname.xx0` to `/etc/hostname.le0`, give
the machine's name its address in `/etc/hosts`, and add a default route to
`/etc/rc.local`: `route add default 192.168.1.1 1`, and with it
`ifconfig le0 broadcast 192.168.1.255` (SunOS 4 otherwise broadcasts to
the old all-zeros address). FTP needs an account with a password: SunOS's
`ftpd` refuses one without, root included. On the MiSTer the Sun answered
pings up to 16,000 bytes with no loss, took telnet logins, moved files by
FTP both ways with equal sums, and had no errors on `le0` under load.

## Known issues

* **Every command starts about 40 ms later after the Y2K patch** (24 ms at
  33 MHz). sun3arc's `y2kpatch-04` brings its own shared libc,
  `libc.so.0.15.3`, built on the libc jumbo patch 100267-09, and the
  dynamic linker takes that much longer to load it at each program start
  than U1's `libc.so.0.15.2`. Programs run no slower once started, but
  scripts that start many commands feel it: 300 starts of `expr` take 83 s,
  against 65 s without the patch. It is not fixed: a fast libc with the
  Y2K fixes would have to be rebuilt from U1's library objects.
  `LD_LIBRARY_PATH` pointed at a directory holding only a copy of
  `libc.so.0.15.2` gives the commands a shell starts the old speed,
  without the Y2K fixes.
  ([docs/design-plan.md](docs/design-plan.md), Phase 4, has the
  measurements.)
* **OpenWindows leaves its last pointer on the screen** after *Exit*, until
  the console scrolls or `clear` runs: `xnews` leaves the colour board's
  overlay as it was.
* **A lot of text pasted into a telnet session is partly lost**: the Sun's
  pseudo-terminal input queue overflows, and it beeps and drops the rest.
  Move files by FTP.
* **With *Network interface* eth0 the Sun cannot reach the MiSTer it runs on** (see
  *The network*); every other machine on the LAN can.
* **Every setting but the media, *Network interface* and *Input* changes
  only in a reset** (*Apply and reset*), and the OSD keeps them for the next start only after *Save
  settings*.
* **On the GX, OpenWindows can leave part of a closed window on the
  screen** until something is drawn over it.
* **Not tried yet**: NFS, telnet and FTP from the Sun to another machine. Parts of the cg4 that SunOS never uses are not modelled: the
  P4 register's first-half-of-retrace bit, its interrupt-pending bit
  latching while its enable is off, and the Bt458's blink and command bit 6.

## Licence

GPL-3.0 (see [LICENSE](LICENSE)). Third-party cores keep their own licences.
They will be recorded in `rtl/vendor/README.md` as they are added. The open
questions are listed in the design plan.
