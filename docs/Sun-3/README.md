# Sun-3 for MiSTer

A Sun-3/60C workstation for the MiSTer FPGA platform. This is a 68020 Sun with
Sun's own MMU, an MC68881, 24 MiB of memory, the on-board bw2 and the P4 cg4
colour frame buffer. It also has the LANCE Ethernet, the on-board SCSI with
disk and QIC tape, the Sun keyboard and mouse, and the ICM7170 clock. It runs
Sun's own boot PROM and SunOS.

**Status: early, but it boots SunOS.** On a MiSTer (2026-10-04) the Rev 1.9
PROM comes up on the colour board's console, takes the keyboard, and keeps
its settings in an EEPROM file. SunOS 4.1.1 installs from QIC tape images onto
a 1 GB disk image and boots from it multi-user, and takes 4.1.1_U1, the Y2K
patch and Sun's later patches
([docs/install-sunos.md](docs/install-sunos.md)). A second disk works,
SunView and OpenWindows 2.0 run in mono and in colour with the mouse, the
Ethernet works (see *The network*), and the CPU runs at 20, 25 or 33 MHz
(see *The CPU clock*).

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

* **the core**, from [`releases/`](releases/): `Sun-3_20261005.rbf`, for
  `_Computer/` (or `_Unstable/`). Beside it are `boot0.rom` (below) and
  `MiSTer`, a Main_MiSTer with Sun support, for the network and the ID PROM
  (see *The network*): upstream Main_MiSTer `c97c052` with the
  `sun-family` branch (`de5e963`) of
  [danifunker/Main_MiSTer](https://github.com/danifunker/Main_MiSTer/tree/sun-family)
  on it, GPL-3.0 like Main_MiSTer itself. It replaces `/media/fat/MiSTer`.
  A running Main cannot be overwritten in place, so keep the old one, copy
  the new one to `/media/fat/MiSTer.new`, `mv` it over `/media/fat/MiSTer`,
  and reboot the MiSTer;
* a DE10-Nano with an **SDRAM board of 32 MB or more**;
* the boot PROM, Sun's Rev 1.9 for the 3/60, patched for this machine,
  at `games/Sun-3/boot0.rom`: `releases/boot0.rom` (see *The boot PROM*);
* SunOS for sun3 on a QIC tape image: `python3 tools/mktape -o
  sunos-4.1.1-sun3.qic <the distribution's sun3 directory>`. Mount it as
  *Tape (st0)* in the OSD. To install onto a disk, see
  [docs/install-sunos.md](docs/install-sunos.md).

## The boot PROM

The core runs Sun's own 3/60 boot PROM, Rev 1.9. It is not in the
bitstream: Main_MiSTer sends `games/Sun-3/boot0.rom` when the core starts,
and the machine stays in reset until it has arrived. `releases/boot0.rom`
is the stock image with seven patches, each listed with its reason in
[`tools/sun3_60_v1.9_noparity.txt`](tools/sun3_60_v1.9_noparity.txt):

* six take out the parity memory this machine does not have (Sun-3_FPGA's
  verified "noparity" set): the PROM no longer turns parity checking on,
  skips its two parity self-tests (0x0E and 0x0F, which force parity
  errors), and no longer touches the memory error register, in its NMI
  handler, after its memory test, or in the monitor's `k` command;
* one, this core's own, makes the power-on memory fill zeros instead of
  0xffffffff: SunOS 4.1.1's tape boot reads leftover boot arguments as
  string pointers, and 0xffffffff made it overwrite itself.

To make the same file yourself, `make -C tools` fetches the stock image
from sun3arc.org, checks its SHA-256, and writes
`build/rom/sun3_60_v1.9_noparity.bin` (sha256 `31688f6f…63de`, the same
as `releases/boot0.rom`). `tools/rompatch` checks every word it changes
before changing it, and keeps the PROM's checksum right. `make -C tools
all-roms` also patches Rev 3.0.1 the same way
([`tools/sun3_60_v3.0.1_noparity.txt`](tools/sun3_60_v3.0.1_noparity.txt)),
but only 1.9 has been run on the MiSTer.

## Booting from tape

With no disk mounted, the PROM tries the disk, prints `sd: error` lines and
then "Waiting for disk to spin up ... press any key to quit". Press a key,
and at the `>` prompt type

    b st()

SunOS 4.1.1's tape boots its miniroot and asks whether to install it.
The PROM's own tape open waits ten seconds for the drive, as on a real 3/60.
L1-A (hold Right Alt + F1, the Sun's L1, and press A) stops SunOS and returns
to the PROM.

## The EEPROM

A Sun-3 keeps its settings in a 2 KiB EEPROM: the boot device, the console,
the serial ports' speeds and more. The core keeps it in a 2048-byte file on
the SD card. Create one once, for example on the MiSTer:

    dd if=/dev/zero of=/media/fat/games/Sun-3/Sun-3.nvr bs=2048 count=1

and pick it in the OSD under **EEPROM**. MiSTer remembers it, and the core
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
change it, then halt SunOS and choose *Reset* (a change made while SunOS
runs waits for the next reset). To keep it for the next start, use *Save
settings* on the OSD's System page.

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
It has been run with the colour board On; with it Off it is untested.

## The network

The machine's Ethernet is its own AMD LANCE, whole in the FPGA. The core
plays the transceiver behind it and passes its frames through DDR3 to
Main_MiSTer, which puts them on a host interface: the same arrangement as
the Sun-2, NeXT and Minimig A2065 cores. **It needs a Main_MiSTer with Sun
support** (`support/sun/`, the `sun-family` branch of
[danifunker/Main_MiSTer](https://github.com/danifunker/Main_MiSTer/tree/sun-family));
without it the LANCE is on a cable to nowhere, and SunOS attaches `le0` all
the same. *Network* in the OSD picks the host side:

| Network | what it is |
|---|---|
| eth0 (the default) | MiSTer's own Ethernet port, shared: the Sun is a second machine on the LAN, with its own address |
| Off | no cable |
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
* **With *Network* eth0 the Sun cannot reach the MiSTer it runs on** (see
  *The network*); every other machine on the LAN can.
* **The CPU clock, the colour board and the diag switch change only in a
  reset**, and the OSD keeps them for the next start only after *Save
  settings*.
* **Not tried yet**: NFS, telnet and FTP from the Sun to another machine,
  and NetBSD. Parts of the cg4 that SunOS never uses are not modelled: the
  P4 register's first-half-of-retrace bit, its interrupt-pending bit
  latching while its enable is off, and the Bt458's blink and command bit 6.

## Licence

GPL-3.0 (see [LICENSE](LICENSE)). Third-party cores keep their own licences.
They will be recorded in `rtl/vendor/README.md` as they are added. The open
questions are listed in the design plan.
