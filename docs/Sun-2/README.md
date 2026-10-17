# Sun-2 for MiSTer

A replica of a Sun-2 workstation in an FPGA: MC68010, the Sun-2 MMU, the AMD
9513 timer and Zilog 8530 SCCs for the serial console and keyboard, booting the
real boot PROMs.

This repository is the **MiSTer** port. It builds one machine, a **Sun-2/160**:
the VME CPU board with its Rev Q boot PROM, the Sun VME SCSI board, the
on-board 1152×900 mono frame buffer, keyboard, mouse and 82586, the Sun-2
colour board (`cgtwo`, 1152×900×8), and the RD68011 CPU core at 20 MHz. The
machine is fixed in
`Sun-2.qsf`'s macro block. The replica it is ported from also ran on a QMTech
Wukong and an Arrow DECA; those board flows have been removed from this tree
and remain in its git history. Most of what follows describes that work, and
still describes the machine.

## MiSTer

**Status: SunOS 4.0 installs from tape and runs, SunView included, and 4.0.3
upgrades it.** On a MiSTer the core boots the PROM, installs SunOS 4.0 from the
release tapes onto a disk image (both volumes, every package), boots that disk
multi-user to a login and `suntools`, and takes the 4.0.3 upgrade tapes over it
to a 4.0.3 login -- on disks up to the Sun-2's 1 GiB limit, with the mouse
and the clock taken from the MiSTer, the keyboard's bell on its audio, and
Ethernet onto the MiSTer's network (with a Main_MiSTer that has Sun-2 support;
see below), and **colour**: the Sun-2 colour board, which SunOS attaches as
`cgtwo0` and SunView draws on (see *Colour*, below).

What a user needs:

* **The core**, from [`releases/`](releases/): `Sun-2_20261004.rbf`, for
  `_Computer/` (or `_Unstable/`). Beside it are `boot0.rom` (below) and
  `MiSTer`, a Main_MiSTer with Sun support for the network and the ID PROM:
  upstream Main_MiSTer `c97c052` with the `sun-family` branch (`de5e963`) of
  [danifunker/Main_MiSTer](https://github.com/danifunker/Main_MiSTer/tree/sun-family)
  on it, GPL-3.0 like Main_MiSTer itself. It replaces `/media/fat/MiSTer`. A
  running Main cannot be overwritten in place, so keep the old one, copy the new
  one to `/media/fat/MiSTer.new`, `mv` it over `/media/fat/MiSTer`, and reboot
  the MiSTer. Without it the core runs, but its Ethernet goes nowhere.
* **A MiSTer with an SDRAM board** (32 MB or more). Main memory, the mono
  frame buffer and the colour board's megabyte live there.
* **The boot PROM**, as `games/Sun-2/boot0.rom`: the 32 KiB Sun-2/50 / 2/160
  Rev Q PROM image (sha256 `8560ef68…4a3f`, the same image as
  `releases/boot0.rom` and `Inputs/boot0.rom`). It is not in the bitstream.
  Main_MiSTer loads it at start-up, and the machine stays in reset until it
  has.
* **A disk image** for the OSD's *SCSI disk (sd0)* entry, and to install onto
  it, **a tape image** for *Tape (st0)* -- both described below.

### Disks and tapes

**File names are yours to choose.** *SCSI disk (sd0)* and *Tape (st0)* in the
OSD open MiSTer's file browser in `games/Sun-2/`; the names in brackets are
SunOS's devices, not files. A disk must end in `.img` or `.vhd`, a tape in
`.qic`, and several of each can sit side by side to be swapped from the OSD.

**Tapes.** A `.qic` is a QIC cartridge as blocks: 512-byte blocks in files, and
a table in block 0 of where each file of each volume starts. `tools/mktape`
(Python 3, nothing else) builds one from a SunOS release -- a folder per volume
of the numbered tape files (`tape1/01`, `02`, ...), the `.rar` or `.zip` that
folder came in (`unrar` or 7-Zip needed for a `.rar`; on Windows WinRAR's own is
found), or SIMH `.tap` files:

    tools/mktape -o sunos-4.0-sun2.qic   sunos_4.0_sun2/
    tools/mktape -o sunos-4.0.3-sun2.qic sunos_4.0.3_sun2.rar

One image holds every volume, and *Tape volume* in the OSD is the cartridge in
the drive: changing it is changing tapes. `-v` lists every file. The drive is
an Emulex MT-02 QIC controller at SCSI target 4
(`rtl/sun2-common/sun2_mt02.sv`), SunOS's `st0`, read only; the PROM boots it
with `b st()`.

**Which tapes.** A full install needs SunOS **4.0** for Sun-2. The common
**4.0.3** set (700-2157-10) is the *upgrade* release: its miniroot runs only
`sunupgrade`, so install 4.0 first and upgrade it.

**Disks.** `tools/mktape --disk` writes an empty disk, already labelled, with a
boot block that says how to install until SunOS replaces it:

    tools/mktape --disk sd0.img                            # Micropolis 1558, 329 MB: / 16, swap 32, /usr 278
    tools/mktape --disk sd0-1g.img --size 1024 --root 32   # 1 GiB: / 31.5, swap 31.5, /usr 960
    tools/mktape --disk sd0-1g.img --size 1024             # 1 GiB: / 991.5 and swap 31.5 (--swap MB)

`--size` takes 16 to 1024 MB. **1 GiB is the most a Sun-2 can use**: every
Sun-2 SCSI driver -- the PROM's, the standalone one, the kernel's -- sends the
six-byte READ and WRITE, whose block address is 21 bits. The 1 GiB disk with
`--root` has been installed from the 4.0 tapes and upgraded to 4.0.3 on a
MiSTer; without `--root` there is no separate `/usr`, and 4.0.3's
`sunupgrade` takes such a disk for a dataless client. Swap and root come out at
31.5 MB rather than 32 because the standalone disk driver -- the copy program,
`tpboot`, `boot` -- keeps a partition's size in 16 bits, and a 32 MB partition
is 65536 blocks, which it reads as nothing at all.

A `--size` disk is not in SunOS 4.0's `/etc/format.dat`, and suninstall labels
the disk with `format`, so `mktape` patches every `format.dat` on a tape it
builds -- the miniroot's, MUNIX's and the ones in the root and Install tars --
to know the 128, 256, 512 and 1024 MB disks, as Adaptec ACB4000 types, which is
what SunOS takes this machine's SCSI disk for. Nothing else on the tape changes,
and no tape file changes size; `--no-patch` builds it as it came, and
`tools/mktape --patch old.qic` updates a tape built earlier, in place. For
other sizes `mktape` prints the two lines to add by hand.

[doc/install-sunos.md](doc/install-sunos.md) is the whole install, step by step,
as done on a MiSTer, with the 1 GiB variant at the end.

The serial console is the MiSTer UART at 9600 baud. With the frame buffer
fitted the PROM puts its console on the screen and keyboard, as a real Sun
does.

### The picture

The Sun's screen is 1152×900, and the core sends it as 1160×904: the screen
and a thin black border. **Give the Sun-2 a 1080p (or 1280×1024) output.**
MiSTer's default, 1280×720, has fewer lines than the Sun's screen, so the
scaler has to shrink it, and a shrunk one-pixel font cannot look right: strokes
come out uneven, SunView's grey background turns into stripes, and the scaler
leaves a dotted column down the right-hand edge. At 1080p the default *Scale*,
V-Integer, shows each Sun pixel as exactly one screen pixel, in a border. In
`MiSTer.ini`:

    [Sun-2]
    video_mode=8        ; 1920x1080@60

`video_mode=4` (1280×1024@60) suits a 5:4 monitor, with the picture 1:1 and a
narrow border.

### Colour

The machine has the **Sun-2 colour board** (`cgtwo`): 1152×900, 256 colours
from a palette of 16.7 million, and the raster-op chips SunView draws with.
The OSD's *Colour board* (**On** by default) fits it and makes it the console:
the PROM's banner then says `Model Sun-2/160`, its text appears on the colour
screen, and that is the screen shown. The mono frame buffer is still in the
machine, as in a real 2/160, but is not displayed. *Off* is the machine without
the board: the mono screen, and the banner's `Sun-2/50 or Sun-2/160`. Change
it, then reset.

SunOS needs a kernel with the colour driver to use it. **GENERIC** has one,
and it says so at boot:

    cgtwo0 at vme24 0x400000 vec 0xa8
    cgtwo0: Sun-2 color board

GENERIC_SMALL, the kernel the 4.0.3 upgrade installs as `/vmunix`, has none.
It still boots on the colour console (the PROM draws its messages), but it
reports `No default frame buffer found` and SunView will not start. The upgrade
keeps the GENERIC kernel as `/vmunix.orig`, so boot that one from the PROM's
`>` prompt with

    b sd()vmunix.orig

or copy it over `/vmunix`. Then `suntools` runs on the colour screen, and
`/usr/demo` has colour to show it, `spheresdemo` for one.

How the board was worked out, with no manual to work from, and how it is
built and tested, is in [`doc/cgtwo.md`](doc/cgtwo.md). What its picture costs
the rest of the machine -- about 1% of the CPU, measured, and more of the
board's own drawing -- and what could be made faster are in
[`doc/futureenhancements.md`](doc/futureenhancements.md).

### Logging in, and SunView

An installed disk boots by itself. The OSD remembers the image you last chose
for *SCSI disk (sd0)* and mounts it again whenever the core starts, and the
PROM auto-boots `sd(0,0,0)vmunix` from whatever disk it finds there -- so once
SunOS is installed, loading the core is all it takes. A reset does the same,
and so does `b sd()` at the monitor's `>` prompt. It ends at

    sun2 login:

**Log in as `root`. There is no password**: SunOS 4.0 installs that way, and
`suninstall` creates no other accounts. Set one with `passwd`. The other names in
`/etc/passwd` are Sun's system accounts, locked with a `*`, except `sync`, which
has no password either and does nothing but run `/bin/sync` and log out -- the
way to flush the disks from the login prompt. To add a user of your own, add a
line with `vipw`, make the home directory and `chown` it to them, and give them
a password with `passwd name`; 4.0 has no `adduser`.

**SunView, the GUI, is `suntools`**, typed at the shell prompt on the screen
(not on the serial port -- it needs the frame buffer):

    sun2# suntools

It takes over the screen and opens its default windows: a console window, a
shell, a clock and the mail icon.

**A USB mouse on the MiSTer is the Sun's mouse.** The core sends it to the Sun
as a Mouse Systems mouse on the keyboard SCC's second channel, at 1200 baud,
which is what SunOS's `ms` driver reads. 1200 baud carries about 24 reports a
second, so the core accumulates motion between them as a real mouse does: none
is lost at an ordinary pace, a very fast flick is cut short rather than leaving
the pointer coasting, and every button press and release arrives in order.

Typing goes to the window under the pointer, and holding the **right** button
over the grey background brings up the root menu -- more shells and tools, and
**Exit Suntools**, which asks for a click to confirm and returns you to the
plain console. To start SunView at every login on the screen, but not on the
serial port, add this to root's `/.login`:

    if ( "`tty`" == "/dev/console" ) suntools

**Shut down before you reset, leave the core or switch off** -- `/etc/halt`
syncs the disks and stops at the monitor's `>`. Right Alt + F1 then A (the
Sun's L1-A, below) also stops the machine at the monitor, but without syncing
anything; `c` there carries on where it left off. Stop it any other way and the
next boot may find `/usr` damaged and stop in single user with `Reboot
failed...help!`; [doc/install-sunos.md](doc/install-sunos.md) has the three
commands that put it right -- and not `/etc/halt`, which undoes the repair.

### The clock

The Sun's clock is set from MiSTer's local time when the core loads, and then
runs on its own, as a battery-backed one would. SunOS keeps no year in that
chip: it takes the year nearest the last time the root file system was
written. So a disk stays in the year it was installed in and moves on with
real time, while the month, day and time come from MiSTer.

They match MiSTer's exactly when the Sun's year is **1990**, which is what the
core is built around: 36 years behind MiSTer, after every file on the 4.0 and
4.0.3 tapes, and ten years short of 2000, which SunOS 4.0.3 was never tested
against. Two things to do once on a disk, as root:

    rm /usr/share/lib/zoneinfo/localtime
    ln /usr/share/lib/zoneinfo/GMT /usr/share/lib/zoneinfo/localtime
    date 9010031400.00      # yymmddhhmm.ss: today's month, day and time, in 1990
    touch /.y; rm /.y; sync

The first two make SunOS show the time as it is given, MiSTer's local time --
SunOS keeps UTC and adds its own time zone, and Main_MiSTer gives this core
local time. `date` puts the disk in 1990, and the last line makes sure the
root file system is written in 1990, since that write is where the next boot
takes its year from. After that every start, warm or cold, comes up with the
right date and time -- on the board, a cold start read `Wed Oct 3 13:39:03 GMT
1990` with MiSTer's clock at 13:39:03. A disk not started for more than six
months comes back a year out, and the same `date` puts it right.

**`SUMMARY INFORMATION BAD (SALVAGED)` means the clock went backwards**, not
that the disk is damaged: SunOS's `fsck` corrects any timestamp later than
"now" and reports it so -- with `Mounted FS fixed - rebooting` on `/`, and on
`/usr` with `Reboot failed...help!`, which wants the three commands in
[doc/install-sunos.md](doc/install-sunos.md). It happens
once on a disk the first time this core starts it, if the disk was last used
with an older core (whose clock always started in December 1988).

### The keyboard

A PC keyboard stands in for the Sun's (`rtl/sun2_mister_kbd_mouse.sv`). The
main block is where you would expect it; the Sun's extra keys are here. The
left block's names are the legends Sun printed on its later keyboards; a Sun-2
keyboard calls them L1..L10.

**L1 is on the Right Alt key.** A Sun keyboard has a block of ten function
keys down its left-hand side, L1 to L10, that a PC keyboard has no room for --
and L1, *Stop*, is the one that matters most, because L1-A is how you stop
the machine and get to the monitor. The core puts that whole block under
**Right Alt**: hold Right Alt and the F-keys stop being the Sun's top row and
become the left block instead, so Right Alt + F1 is L1, Right Alt + F2 is L2,
and so on to F10. Right Alt on its own sends nothing to the Sun -- it is only
the switch. So the Sun's **L1-A** is:

1. hold **Right Alt**,
2. hold **F1** as well (that is L1 going down),
3. press **A**.

F1 has to still be held when A goes down. It stays L1 until it is released,
even if Right Alt is let go first, so only letting go of F1 early turns the
chord into a plain `a`. L1-A drops to the monitor's `>` prompt without syncing
the disks, and `c` there resumes where the machine left off.

| PC | Sun |
|---|---|
| **Right Alt + F1** | **L1 Stop** -- Right Alt+F1, then A, is the abort to the monitor |
| Right Alt + F2 .. F10 | L2 Again, L3 Props, L4 Undo, L5 Front, L6 Copy, L7 Open, L8 Paste, L9 Find, L10 Cut |
| F1 .. F9 | the top row, T1 .. T9 |
| arrows | R8, R10, R12, R14 |
| Home, PgUp, End, PgDn | R7, R9, R13, R15 |
| numeric keypad 1 .. 9 | the right keypad, R13 .. R9 by position |
| Num Lock, keypad / * - + | R1, R2, R3, R4, R5 |
| Insert / keypad 0, Delete / keypad . | Insert, Delete |
| keypad Enter | Line Feed |
| Windows keys | Meta, the Sun-2's "Left" and "Right" |
| Left Alt, Caps Lock | Alt, Caps Lock |

Right Alt sends nothing itself. An F-key keeps the meaning it went down with,
so releasing Right Alt first cannot leave an L-key held. Scroll Lock and F12
are MiSTer's own (keyboard emulation and the OSD) and are not passed on.

### The bell

A Sun keyboard has a beeper, and it comes out of MiSTer's audio, HDMI and
analogue alike (`rtl/sun2_mister_bell.sv`). It sounds for two things, as on
the real keyboard:

* **the bell**, for as long as the machine rings it: once at power-up, when
  the PROM finds the keyboard; for `^G` on the console; and from SunView,
  which flashes the window as well;
* **the key click**, 5 ms on every key going down, once `click -y` has turned
  it on. `click -n` turns it off again, and every reset does too.

It is the keyboard's own pitch -- a 480 us period, about 2083 Hz -- as a square
wave with its edges rounded off a little. **Keyboard bell** in the OSD sets the
level: Normal, Loud, Quiet or Off.

### The network, and the machine's identity

A Sun-2 takes its Ethernet address and its serial number -- and from those,
SunOS's `hostid` -- from a 32-byte ID PROM on the CPU board. The core's
built-in one says `Serial #3442, Ethernet address 8:0:20:1:6:E0`, which is
fine for one machine and wrong for two on the same network. Two ways to give a
machine its own:

* **`games/Sun-2/boot1.rom`**, a 32-byte ID PROM image, replaces the built-in
  one at start-up: format 1, machine type 2, the six bytes of the Ethernet
  address, four of date, three of serial number, a checksum that makes the XOR
  of the first sixteen bytes zero, and sixteen bytes of `0xFF`. A dump of a
  real 2/50 or 2/160's PROM works as it is.
* **Main_MiSTer with Sun support** (below) makes one by itself when there is
  no `boot1.rom`: Sun's prefix `08:00:20` and the last three bytes of the
  MiSTer's own Ethernet address, which are the serial number as well. It is
  made afresh at every core load and never written to the SD card, so the
  Sun's identity follows the MiSTer: another MiSTer or another network adapter
  gives it another Ethernet address and `hostid`.

**`releases/Sun-2_mkidprom.py`** writes a `boot1.rom`, on the MiSTer or
anywhere with Python 3. With no arguments it writes exactly the ID PROM Main
makes for that MiSTer, which pins the identity it has now; `--mac` and
`--serial` choose others, and `--show` decodes an existing one and checks its
checksum:

    python3 Sun-2_mkidprom.py
    python3 Sun-2_mkidprom.py --mac 08:00:20:12:34:56 --serial 1234567
    python3 Sun-2_mkidprom.py --show

It writes `/media/fat/games/Sun-2/boot1.rom` (`-o` for elsewhere) and will not
replace one without `--force`; load the core again for it to take effect.

**The network** is the CPU board's own Intel 82586, whole in the FPGA. The core
plays the transceiver behind it and passes its frames through DDR3 to
Main_MiSTer, which puts them on a host interface -- the same arrangement the
NeXT and Minimig A2065 cores use, and the same mailbox and daemon as the
SPARCstation core. **It needs a Main_MiSTer with Sun support**
(`support/sun/`, Main_MiSTer branch `sun-family`; `releases/MiSTer` is one); without it the 82586 is on
a cable to nowhere, and SunOS attaches `ie0` all the same. *Network* in the OSD
picks the host side, in the SPARCstation core's order:

| Network | what it is |
|---|---|
| eth0 (the default) | MiSTer's own Ethernet port, shared: the Sun is a second machine on the LAN, with its own address |
| Off | no cable |
| eth1 | a second port (a USB adapter), the Sun's alone |
| macvlan | a virtual port on eth0 with the Sun's address |
| tap0 | a tap interface on the MiSTer, for routing it yourself |

With *eth0* the Sun can reach and be reached by every machine on the LAN except
the MiSTer it runs on. It runs at 10 Mb/s, the 82586's own speed. SunOS 4.0 has
no DHCP, and a disk installed standalone names the machine `127.0.0.1` in
`/etc/hosts`, so `ie0` comes up on the loopback address. To try it by hand:

    ifconfig ie0 192.168.1.50 netmask 255.255.255.0 broadcast 192.168.1.255 up
    /usr/etc/ping 192.168.1.1

and to keep it, give the machine its address in `/etc/hosts` (the line with its
name) and add a default route to `/etc/rc.local`: `route add default
192.168.1.1 1`. On the board a Sun-2 on *eth0* answered ping from the LAN
(full-size frames too), pinged out, and its FTP and telnet servers answered.

Building: open `Sun-2.qpf` in Quartus Prime Lite 17.0 (the version MiSTer's
framework supports) and compile. Nothing else is needed: no submodules, no
generated sources.

| path | what |
|---|---|
| `Sun-2.sv` | the MiSTer `emu` top: clocks, `hps_io`, the bridges, the machine |
| `rtl/sun2-common/`, `rtl/sun2-vme/` | the machine |
| `rtl/vendor/` | third-party cores, copied in unmodified; see its README |
| `rtl/sun2_mister_*.sv`, `rtl/sdram.sv`, `rtl/pll*.v` | the MiSTer glue |
| `sys/` | Template_MiSTer's framework, verbatim |
| `releases/` | the core, the boot PROM, a Main_MiSTer with Sun support and `Sun-2_mkidprom.py` (an ID PROM writer), ready to copy to a MiSTer |
| `doc/prom/` | an annotated disassembly of the boot PROM |
| `tb/verilator/` | unit tests for the MiSTer glue and the tape drive: `make -C tb/verilator` (Verilator 5); `make -C tb/verilator tb_emu` runs the whole core, `TAPE=`/`DISK=`/`KEYS=` to feed it |
| `tools/mktape` | tape images (`.qic`) from a SunOS release, their `format.dat` taught the disks it makes, and an empty labelled disk to install onto |

## What it does

On real hardware, with the RD68011 core (`CPU=rd68011`):

* **SunOS 4.0.3 boots to a multi-user login prompt**, from a disk or over the
  network, on both machines and both boards. It runs `/bin/sh`, forks, pipes,
  compiles C with its own `cc`, and writes files back to disk or NFS.
* **NetBSD 2.0** reaches userland on the MultiBus machine.
* **Disks:** a Xylogics 450 (MultiBus) or Sun's own SCSI host adapter (either
  machine), each with an SD card standing in for the drive.
* **Network:** the 2/50's on-board Intel 82586, the Sun MultiBus Ethernet card,
  or a 3Com 3C400, all on a real 10BASE-T link.
* **A display:** the Sun-2's 1152×900 monochrome frame buffer, on an HDMI
  monitor at 1280×1024.
* A time-of-day clock, so SunOS knows what day it is.

About 1870 dhrystones per second on a Wukong at 19.6 MHz, against the roughly
700 of a real 10 MHz Sun 2/120. A 16 MiB file written to disk and read back
compares clean, word for word.

In simulation both machines pass the PROM's self test and reach the monitor
prompt on both CPU cores, and that boot is the regression test for everything
shared.

What has been run on a board:

| Board | Machine | Storage | Network | Display |
|---|---|---|---|---|
| Wukong V1 | 2/120 | — | Sun MultiBus Ethernet: NFS root, login | 1280×1024 |
| Wukong V1 | 2/50 | — | on-board 82586: NFS root, login | — |
| Wukong V3 | 2/120 | Xylogics 450 on micro-SD: boot, `fsck`, login | Sun MultiBus Ethernet | — |
| Wukong V3 | 2/50 | SCSI on micro-SD: boot, login | on-board 82586 | — |
| DECA | 2/50 | SCSI on micro-SD: boot, login | on-board 82586: NFS root, login | 1280×1024 |
| DECA | 2/120 | Xylogics 450 or SCSI on micro-SD: boot, login | 3Com 3C400 (see its section) | 1280×1024 |

`CLAUDE.md` is the project's working notebook: every measurement behind these
claims, and every trap that cost time on the way. `BRINGUP.md` is the procedure
for a board — what to check, in what order, and what each silent failure looks
like.

## Layout

| Path | What |
|---|---|
| `rtl/sun2-common/` | the Sun-2 gateware shared by both machines: bus, MMU, PROM, timer, SCCs' wiring, TOD clock, memory bridges, frame buffer scan-out, the SCSI core |
| `rtl/sun2-multibus/` | what only a 2/120 has — the Sun and 3Com Ethernet cards, the Xylogics 450, the MultiBus SCSI card |
| `rtl/sun2-vme/` | what only a 2/50 has — on-board Ethernet, the DVMA bridge (which the Xylogics reuses), the PHY status register, the VME SCSI/RTC board |
| `boards/Wukong/` | the Wukong board layer, V1 and V3: clocks, reset, the DDR3 adapters and arbiter, PHY bring-up, HDMI clocks |
| `boards/DECA/` | the DECA board layer: clocks, the DDR3 adapters, the JTAG console, PHY bring-up, the ADV7513 HDMI transmitter |
| `tb/` | testbenches and simulation models |
| `sim/` | simulation flows |
| `syn/` | FPGA builds for both vendors: constraints, MIG configuration, Vivado and Quartus scripts |
| `test/` | small standalone designs that prove one board block at a time — HDMI, the DECA's console, DDR3, SD card |
| `tools/` | boot PROM preparation, disk images, boot-block probes, board scripts, `ufsread` and `pcsym` |
| `patches/` | changes to third-party sources, applied to copies under `build/inputs/` |
| `doc/` | long-form write-ups, such as the disk corruption hunt |
| `Inputs/` | third-party and reference material — **immutable** |
| `Old/` | the previous working implementation, kept for reference — not in git, never modified |

`Inputs/` holds git submodules, so a fresh clone needs:

```sh
git submodule update --init
```

Nothing under `Inputs/` is ever edited in place. If a change to that material
becomes necessary, it lives as a patch in `patches/<name>/`, which
`tools/patch_inputs.sh` applies to a copy under `build/inputs/` whenever a
flow runs — the same principle as the boot PROM, which is patched into
`build/rom/` rather than modified where it sits. A patch is meant to be
temporary: once it is accepted upstream, it is dropped and the submodule moves
forward.

The sources under `Inputs/`:

* `Suska_Configware` — Wolfgang Förster's Suska cores; `68K10/` is the MC68010.
  This is the `MelkhiorVintageComputing` fork on branch `sun_emu_support`,
  which already carries the three fixes the Sun-2 needs (exception-handler
  `BUSY_EXH` timing, `MOVES` function-code selection, and FC = supervisor data
  during the reset vector fetch); `patches/Suska_Configware/` adds two more.
  Suska reaches the monitor prompt and is what the simulation fingerprints are
  measured against, but it cannot run SunOS: the bus error frame it pushes
  does not describe the faulted cycle, so instruction restart fails.
* `RD68011` — [MelkhiorVintageComputing/RD68011](https://github.com/MelkhiorVintageComputing/RD68011),
  a SystemVerilog MC68010 written alongside this project and the second core
  the machine can be built with. `top_fpga.v` instantiates it as the
  alternative to Suska under `` `ifdef SUN2_CPU_RD68011 ``, which `CPU=rd68011`
  sets on any of `make -C sim xsim`, `make -C sim board` and
  `make -C syn bitstream`; nothing else about the machine changes, and each
  core builds into its own directory. **RD68011 is the core that runs SunOS**,
  and every hardware result above was taken with it. Neither core is a
  reference for the other, so short experiments are run with both and both
  results reported.
* `z8530_scc` — [vz50938/z8530_scc](https://github.com/vz50938/z8530_scc), the
  SCC used for the serial console. Its bus clock and serial clock are separate,
  so the CPU clock is free — the Suska SCC constrains it far too tightly. Feed
  its serial clock 4.9152 MHz and the PROM's own register table gives a correct
  9600 baud console. Three interrupt defects found here (WR9 written through
  channel B, IP bits not gated by their enables, a transmit write not clearing
  the transmit IP) are fixed upstream.
* `Wish82586` — the Intel 82586 Ethernet controller, used as the VME machine's
  on-board Ethernet and on the Sun MultiBus Ethernet card; the 3C400 reuses its
  MII and CRC blocks. Its `src/wb_csr_sun2.sv` is the same control register
  `rtl/sun2-vme/sun2_ether_ctl.v` implements natively; we use ours, because it sits in
  device space with the rest of the decode, and the two should be kept
  reconcilable.
* `sunos-34-src` — [calmsacibis995/sunos-34-src](https://github.com/calmsacibis995/sunos-34-src).
  Contains `sun/prom_monitor/`, which is **the source of the boot PROMs
  themselves**. `msun/` and `rsun/` are Rev Q and Rev R of one tree, not two
  machines: the machine is chosen by `-DVME` in each build directory's
  Makefile (`msun/mon/RevQs` is the VME Rev Q monitor, `rsun/mon/RevR2` the
  MultiBus Rev R one). It is the single most useful reference
  here — `sys/mon/s2map.h` names every I/O page numerically, `mon/kernel/sunmon.c`
  has both machines' page-map setup side by side, and `mon/h/buserr.h` documents
  register semantics no manual spells out. Reach for it before guessing at
  what a PROM is doing.
* `Wish5380` — an NCR 5380 SCSI controller. The 5380 itself is not used, since
  Sun's SCSI boards are not built around one. What this design takes from it is
  `src/blk_sd.sv` and `src/sd_spi.sv`, a tested SD-card block back end with a
  documented seam (`doc/block.md`) that every disk here keeps its sectors on,
  and `scsi_targ`, the SCSI disk on the far side of Sun's host adapter.
* `BrianHG-DDR3` — Brian Guralnick's soft DDR3 controller, hardware-verified on
  the DECA, which has no hard memory controller. It carries no formal licence
  ("Written by Brian Guralnick. For public use."), which is worth knowing
  before anyone packages this.
* `hdmi` — [hdl-util/hdmi](https://github.com/hdl-util/hdmi), the HDMI
  transmitter behind the Wukong's frame buffer: TMDS encoding, the 10:1
  serialisers and the video timing, with `DVI_OUTPUT` so there is no audio
  island to feed. `patches/hdmi/0001` adds the 1280×1024 mode the full design
  can actually clock. The DECA has a transmitter chip and does not use it.
* `sun2-multi-rev-R.bin` — Rev R boot PROM of a MultiBus Sun 2/120.
* `Inputs/boot0.rom` — boot PROM of a VME Sun 2/50, used by
  `MACHINE=vme` (see [Which machine](#which-machine)).
* `doc/` — the Sun-2 Architecture Manual, the Sun 2/50 schematic and
  engineering manual, the 2/120 video board engineering manual, the Xylogics
  450 user's manual and schematic, Sun's SCSI boards' theory of operation, the
  MC68000 user manual, and the QMTech Wukong and Arrow DECA board documents
  (`QM_XC7A100T_WUKONG_BOARD/` and `DECA_board/` are submodules). The
  engineering manual is the one with an OCR text layer, and it carries the
  U214/U215 PAL listings — the DVMA arbiter's actual equations.

## Running the simulation

```sh
make sim          # or: make -C sim xsim
```

That builds the boot PROM images, compiles the design and runs it, printing the
front-panel LED codes as the PROM walks its self-test and decoding the serial
console to `build/sim/xsim-multibus/console.log`, which ends up looking like:

```
Self Test completed successfully.

Sun Workstation, Model Sun-2/120 or Sun-2/170, Sun-2 keyboard
ROM Rev R, 1MB memory installed
Serial #3442, Ethernet address 8:0:20:1:6:E0

Probing Multibus:
Using RS232 A input.
Auto-boot in progress...
No default boot devices
>
```

The serial number and Ethernet address come from `rtl/sun2-common/idprom.v`, and the memory
size is whatever `MEM_MIB` was set to — the PROM finds it by probing. With no
cards in the cage there is nothing to boot from, so auto-boot fails and drops
to the monitor prompt; the run stops there on its own, because `STOP_ON`
defaults to `>`.

This boot is the regression reference for the whole machine: **22 bus errors
and a byte-identical 274-character console** on the MultiBus machine at
`MEM_MIB=1 ROM=fast`, and **10 bus errors and 312 characters** on the VME one
at `MEM_MIB=1`, on both cores. Every one of those bus errors is a device probe
timing out, which is how the PROM finds empty slots; fitting a card removes its
probe. `CLAUDE.md` has the per-card decomposition.

`make -C sim check` turns that into a pass/fail: it asserts the self test
completed, the machine identified itself, and the prompt appeared.

Useful knobs:

```sh
make -C sim xsim MEM_MIB=1              # a 1 MiB machine: much faster to boot
make -C sim xsim ROM=fast               # skip most of the RAM init pass too
make -C sim xsim TIMEOUT_MS=8000        # simulated milliseconds before giving up
make -C sim xsim MEM=sim_only           # 512 KiB in-core SRAM instead of Wishbone
make -C sim xsim ROM=pristine           # this machine's unmodified PROM (very slow)
make -C sim xsim MACHINE=vme            # be a Sun 2/50 (VME) instead of a 2/120
make -C sim xsim CPU=rd68011            # the other MC68010 core
make -C sim xsim FB=1                   # fit the frame buffer (either machine)
make -C sim xsim MB_ETHER=1             # the Sun MultiBus Ethernet card
make -C sim xsim MB_3C400=1             # ... or the 3Com one instead
make -C sim xsim XY450=1                # fit the Xylogics 450 disk (MultiBus only)
make -C sim xsim VME_SCSI=1             # the VME SCSI/RTC board (VME only)
make -C sim xsim MB_SCSI=1              # the MultiBus SCSI card (MultiBus only)
make -C sim xsim WB_CACHE=0             # the memory bridge without its read cache
make -C sim xsim WB_FIFO=0              # ... or the old synchronous bridge
make -C sim xychain                     # drive chained IOPBs from inside the machine
make -C sim xsim MEM_LATENCY=7          # memory as slow as the real DDR3 path
make -C sim xsim XSIMARGS="-testplusarg trace_dvma=16"   # Ethernet bus mastering
make -C sim xsim XSIMARGS="-testplusarg trace_irq=20"     # timer/interrupt activity
make -C sim xsim XSIMARGS="-testplusarg heartbeat_ms=100"
SUN2_VCD=1 make -C sim xsim XSIMARGS="-testplusarg vcd_full"
make -C sim check                       # assert the console reached the prompt
```

`MEM_LATENCY` is worth knowing about. It defaults to 0 — a memory that
answers the next cycle — which is what every simulation here used until the
real path was measured. `make -C sim migddr3cached` reports what it actually
costs through the real MIG and a Micron DDR3 model: MIG returns read data 21
`ui_clk` after accepting the command, a read that misses the bridge's cache is
**7 CPU clocks**, and one that hits is 1. With the FIFO bridge `MEM_LATENCY`
counts wait states of the memory model's own 83 MHz clock, not of cpu_clk.

Each configuration gets its own directory under `build/sim/`, named after the
machine, the core and every card fitted (`xsim-multibus-xy450-rd68011`, say),
so different configurations can run at the same time. Two runs of the *same*
one cannot — they share a snapshot directory, and the second recompiles it
while the first is executing. `MEM_LATENCY` is not part of the name.

`MEM_MIB` is the one to reach for first. The PROM writes every installed byte
during its setup pass, so a 7 MiB machine spends over three simulated seconds
there while a 1 MiB one spends under half of one. 7 MiB is the architectural
maximum and most real Sun-2s had 2 or 4. The PROM reaches its prompt in as
little as 32 KiB, but booting anything needs more: a disk boot needs at least
1 MiB, because the PROM puts the DVMA window at physical `0xC0000`. Unless
memory size is what you are testing, use a small machine.

Expect it to take a while — roughly 0.5 s of wall clock per simulated
millisecond. Where the simulated time goes, on a 1 MiB machine:

| Simulated time | Phase |
|---|---|
| 0 – 0.16 ms | reset, LED walk, watchdog, context register |
| 0.16 – 0.31 s | segment map diagnostics (`L_SM_CONST/DATA/ADDR`) |
| 0.31 – 0.37 s | page map diagnostics (`L_PM_CONST/DATA/ADDR`) |
| 0.37 – 0.61 s | boot PROM checksum (`L_PROM`) |
| 0.61 s | `L_M_MAP` — main memory mapped, Wishbone bridge enabled |
| 0.66 – 1.12 s | `L_SETUP_MEM` — the PROM writes every installed byte |
| 1.12 – 1.5 s | map, framebuffer and keyboard setup |
| ~1.5 – 1.7 s | console banner, MultiBus probe, auto-boot, prompt |

That `L_SETUP_MEM` figure scales with `MEM_MIB`: 0.46 s at 1 MiB, 3.2 s at
7 MiB, and 7 ms with `ROM=fast`. Reaching the prompt takes about 1.7 simulated
seconds at `MEM_MIB=1 ROM=fast`, and about 4.5 at the 7 MiB default.

### Boot PROM variants

`tools/` turns the PROM images into the Verilog `case` body that `rtl/sun2-common/bootrom.v`
includes. For the MultiBus `sun2-multi-rev-R.bin`, in three flavours:

* **patched** (default) — three words changed, per `tools/sim_speedup.txt`: a
  diagnostic delay loop shortened from 50000 iterations to 2, and the
  destructive main-memory test jumped over. Without these, simulating to the
  monitor prompt is not practical.

  The old design's image carried a fourth change, at `ef70e8`: WR12 in the
  SCC's initialisation table, the baud rate time constant, bumped from 14 to
  30. That was a workaround for the Suska SCC the old design used; with
  `z8530_scc` fed a 4.9152 MHz clock it is not needed, and applying it would
  only halve the console from 9600 to 4800. It lives in
  `tools/legacy_baud.txt`, which is not part of any ROM the simulation runs —
  `make -C tools check` applies it solely to rebuild the old image and assert
  we reproduce it bit for bit.
* **fastboot** (`ROM=fast`) — the above plus `tools/sim_fastboot.txt`, which
  turns the `asrl #2,%d1` that scales the RAM-init count at `ef01ea` into
  `asrl #8`. The initialisation loop and its 32-bit wraparound still run, and
  low memory — where the monitor keeps its own data — is still initialised,
  but 64 times less of RAM is written. Not the known-good image, so don't use
  it for full-system or memory-related validation.
* **pristine** (`ROM=pristine`) — the PROM exactly as dumped.

The VME `Inputs/boot0.rom` gets the same treatment minus fastboot:
patched by default per `tools/sim_speedup_sun250.txt`, or pristine with
`ROM=pristine`. The two shared patch sites are at different addresses, and the
delay loop needed care — `movel #50000,%d0` appears twice with byte-identical
context, and the first occurrence is on an error path that never runs. It also
carries a third patch of its own, shortening the 100000-iteration poll in
`iereset()` that auto-boot always runs into; see the file for why that is a
speedup rather than a fix.

### Simulators

**Vivado xsim** is the flow that works. The design is mixed-language — the
MC68010 is VHDL, everything else Verilog and SystemVerilog — so the simulator
has to handle both. Notes for anyone reproducing it:

* the Suska VHDL needs `-2008`; it connects `buffer` formals to `out` actuals,
  which VHDL-93 forbids;
* the Sun-2 gateware must be compiled in Verilog mode, not SystemVerilog mode;
* `xelab` links the snapshot with Vivado's bundled gcc, which cannot find
  `crt1.o` on a Debian multiarch system unless `LIBRARY_PATH` points at
  `/usr/lib/x86_64-linux-gnu`. `sim/run_xsim.sh` sets this when needed.

**GHDL + Icarus** (`make -C sim iverilog`) is written but does not work:
`ghdl --synth` rejects a 16-bit concatenation in `wf68k10_bus_interface.vhd`
that is in fact correctly sized, and that both xsim and Vivado accept. See the
comment at the top of `sim/run_iverilog.sh`.

## Configuration

`rtl/sun2-common/sun2_config.vh` holds the compile-time options; each is `ifndef`-guarded
so it can be forced from the command line.

### Which machine

The Architecture Manual describes two Sun-2s, and the design can be built as
either. One define picks it, and everything machine-dependent follows:

| | `SUN2_MULTIBUS` (default) | `SUN2_VME` |
|---|---|---|
| Model | 2/120, 2/170 | 2/50, 2/160 |
| "Machine Type" | 1 | 2 |
| System bus | MultiBus / IEEE-796 | VME |
| Boot PROM | `Inputs/sun2-multi-rev-R.bin` | `Inputs/boot0.rom` |
| `DEV_PAGE_BASE` | 0 (page 0x000) | 4064 (page 0xFE0) |
| `MEM_SPACE_PAGES` | 3584 (7 MiB) | 4096 (8 MiB) |
| `IDPROM_MACHINE_TYPE` | 1 | 2 |
| In simulation | boots to the monitor prompt | boots to the monitor prompt |
| On a board | SunOS 4.0.3 and NetBSD 2.0 | SunOS 4.0.3 |

`make -C sim xsim MACHINE=vme` is the whole of it. The three parameters are
individually overridable if an experiment wants a combination that is not
either real machine; `sun2_fpga` prints the resulting configuration at time 0
so the combination in force is never in doubt.

The VME machine reaches the prompt too:

```
Self Test completed successfully.

Sun Workstation, Model Sun-2/50 or Sun-2/160, Sun-2 keyboard
ROM Rev Q, 1MB memory installed
Serial #3442, Ethernet address 8:0:20:1:6:E0

Probing I/O bus: ie
Using RS232 A input.
Auto-boot in progress...
Boot: ie(0,0,0)vmunix
???nd: no file server, giving up.
>
```

The `?`s are real: each is one ND boot request that went out on the wire and
got no answer. `ieprobe()` on a VME machine reports Ethernet present from the
ID PROM's machine-type byte alone, without issuing a bus cycle, so `ie` always
joins the boot device list and auto-boot always tries it — and here it works,
finds nothing, and gives up cleanly.

Two device pages differ from MultiBus and are instantiated only for VME
(`VIOPG_*` in the monitor's `sys/mon/s2map.h`):

| Page | VME | MultiBus |
|---|---|---|
| 0xFE1 | Intel 82586 Ethernet — control register (`rtl/sun2-vme/sun2_ether_ctl.v`) plus the controller itself (`rtl/sun2-vme/sun2_ethernet.sv`) | 80287 socket, not implemented |
| 0xFE3 | keyboard/mouse Z8530, a second instance of the serial SCC | parallel port, not implemented — the 2/120's keyboard SCC is on its video board instead, in type 0 space |
| 0xFE7 | Ethernet PHY status (`rtl/sun2-vme/sun2_phy_status.v`) — not a Sun-2 device at all, see below | National MM58167 time-of-day clock (`rtl/sun2-common/mm58167.v`) |

Nothing is attached to the keyboard SCC, so the monitor's keyboard hunt times
out and the console stays on serial A — which is what we want. The frame
buffer and video control (type 1 pages 0x000 and 0x040) are outside the
decoded device window unless `SUN2_FB` is defined; without it `s2fbthere()`
fails and the console has nowhere else to go. The same is true of the 2/120,
at quite different addresses — see [the frame buffer](#the-frame-buffer-and-hdmi).

Getting there also needed three things that had never worked in this design
and are shared with MultiBus, all of them latent because no unprotected bus
error and no interrupt had ever occurred on the way to the MultiBus prompt:

* **the bus error register was not writable.** It is read-to-inspect,
  write-to-clear; the default handler in `trap.s` acknowledges by writing it,
  and that write was not acked, so the handler bus-errored inside itself and
  nested until the stack ran off the bottom of memory. Any unprotected bus
  error anywhere was an unrecoverable double fault.
* **interrupts could not be acknowledged.** A 68010 has one VPA pin serving
  both 6800-style cycles and autovectoring; the Suska core splits it into
  `VPAn` and `AVECn`, and the Sun-2's VPA was wired to the former. The core
  took its vector off the data bus instead, picking up `0xAD` from the read
  mux's `16'hDEAD` fall-through.
* **the timer never counted.** `ttl_am9513` drove its OUT pins from a register
  nothing assigned, ignored the count-source field, and wrote counter
  registers a byte at a time even in the 16-bit mode the monitor selects — so
  the NMI timer's mode word `0x0C22` was stored as `0x2200`, selecting an
  unconnected input pin. Counter 1 is the NMI clock the monitor measures wall
  time with, and the 2/50 waits on it with no way around.

### Ethernet, and DVMA — the VME machine

The VME machine's on-board Ethernet is an Intel 82586 (`Inputs/Wish82586`),
and the interesting part is not the controller but how it reaches memory. Its
DMA addresses are **virtual**: on the real board they are latched straight onto
the CPU's address bus and translated by the same MMU. Sun calls it DVMA, and
Architecture Manual §7 is explicit that it exists to avoid *"the dual mapping
problems of DMA in a virtual memory environment"*.

So the controller is a bus master on the 68010 bus, not a client of the
physical-memory Wishbone that main memory uses. `rtl/sun2-vme/sun2_dvma.v` is that
bridge: Wishbone slave in, 68010 cycles out. What makes it small is that a DVMA
cycle is byte-for-byte a supervisor-data CPU cycle at the pins (schematic sheet
A03) — so the MMU, the protection check, the bus timing chain, DTACK and the
bus error register are all reused unchanged, and `rtl/sun2-common/top_fpga.v` only has to
mux who drives the address, function code, strobes and write data.

Three details are worth knowing before touching it:

* **Two-wire arbitration.** The 2/50 ties BGACK high and a master simply holds
  BR for as long as it wants the bus (MC68000UM §5.2). The Suska core supports
  this properly and already exported `BUS_EN` for the wrapper to mux on.
* **The byte lanes are crossed.** The driver byte-swaps every scalar in
  software, so memory holds Intel little-endian data at matching byte
  addresses; all the hardware must guarantee is that the 82586's byte address
  N reaches the byte the 68010 calls N. A 68010 puts the even byte on D[15:8]
  and an Intel part puts it on D[7:0], so crossing the lanes *cancels* the
  mismatch rather than adding a second swap. This is the real board's
  "permanently byte-reversed mode" (§6.13). Get it backwards and the chip reads
  its configuration pointer one byte off, decides the host bus is 8 bits wide,
  and looks exactly like a chip that is not there.
* **Read data is latched a clock after DTACK**, as a 68010 does at the end of
  S6 — the machine's memory path presents data behind its acknowledge.
  Sampling on the DTACK edge silently returns the *previous* cycle's data.

`make -C sim dvma` is the unit test, and it is written to fail loudly on all
three: it drives a byte-addressed memory model that stores what a 68010 would
store, so a lane crossing error shows up as bytes in the wrong order rather
than as a machine that does not boot.

`+trace_dvma=N` on a simulation run reports the first N cycles the controller
takes as bus master, with the physical page each translated to. The sequence to
look for is three reads around `0xFFFFF6` (the SCP address the part has
hard-wired), reads at `0x0A0400` (the ISCP), then a write of zero to
`0x0A0400` — that last one is what the boot PROM spins on, and the difference
between a working controller and a dead one.

On the board the MII goes to the RTL8211EG in bank 34, whose pins, clock
constraints and MII I/O delays are in `syn/wukong_v1.xdc`, with a reset
sequencer in `boards/Wukong/wukong_top.sv` holding PHYRSTB low for 20 ms and
waiting 50 ms more before MDIO is allowed — the datasheet asks for 10 and 30.
Seven of those balls are also PHY configuration straps, latched when its reset
releases; they are inputs and must stay inputs, with no pull property, or the
PHY comes up at the wrong address or in RGMII mode.

`boards/Wukong/phy_rtl8211_init.sv` brings it down to something a Sun-2 can talk
to, over `wb_mdio` at 125 kHz. Read the identifier as a smoke test, write
GBCR = 0 to withdraw the gigabit advertisement the straps make, advertise
10BASE-T only in ANAR, clear PHYCR bit 11 — "Assert CRS on Transmit", which
comes up **set** in GMII mode and would make the MAC defer on its own frames —
and only then restart negotiation. That order is forced: writes to registers 0,
4 and 9 latch on a reset or a restart and nothing else, and there is no
software reset in the sequence because it would undo them.

Advertising 10 rather than *forcing* it is deliberate. A forced link sends no
advertisement, so the partner parallel-detects and falls back to half duplex,
giving a duplex mismatch that looks exactly like a MAC bug.

On the DECA the PHY is a TI DP83620, brought up the same way by
`boards/DECA/phy_dp83620_init.sv`; the values it writes are quoted from
`Inputs/doc/dp83620.pdf`.

### Asking the machine what the PHY did

The board cannot be probed interactively, and the three ways this fails
silently — MDIO never answered, the link came up at gigabit, or carrier sense
is stuck — are indistinguishable from a dead controller at the console. So all
of it is readable from the monitor prompt, in device page **0xFE7**, which a
real 2/50 leaves unused (`s2map.h` comments 0xFE6 and 0xFE7 as such and the
PROM never maps either). Read-only; a write takes the bus-error timeout, as
writing the ID PROM does.

| | |
|---|---|
| +0 | PHYID1 as read back over MDIO — `001C` is the Realtek OUI |
| +2 bit 15 | the bring-up sequence finished |
| +2 bit 14 | ... and the identifier matched (address 0 is a broadcast, so an answer alone proves nothing) |
| +2 bit 13 | link |
| +2 bit 12 | full duplex |
| +2 bits 11:10 | speed: 00 = 10, 01 = 100, 10 = 1000 Mb/s |
| +2 bit 9 | carrier sense stuck now |
| +2 bit 8 | ... or at any point since reset (sticky) |

The PROM does not map the page, so point one at it first. `0xEE0800` is
`ROP_BASE`, the RasterOp processor a VME machine does not have, which
`sunmon.c` maps valid-but-inaccessible precisely because nothing uses it:

```
>pee0800 fe400fe7             valid, all permissions, type 1, page 0xFE7
>eee0800
EE0800: 001C?                 a Realtek part answered MDIO
EE0802: F000?                 configured, matched, link up, full duplex, 10 Mb/s
q
```

`make -C sim board-phy` does exactly that in simulation and
`sim/check_console.sh` asserts both answers — `tb/uart_console.sv` types at the
prompt and `tb/mdio_phy_model.sv` is the PHY. It boots the whole machine first,
so it costs an hour of wall clock; the bring-up sequencer on its own is
`make -C sim phy`, which takes seconds.

In simulation the MII side goes to `tb/mii_peer.sv`, which supplies clocks and a
quiet line.
That is not optional: the PROM's driver waits on the controller with no timeout
anywhere, so a transmit that never completes for want of a PHY clock hangs the
machine solid with nothing printed.

### The frame buffer, and HDMI

Either machine could have a display, and with `SUN2_FB` this one does:
1152×900 monochrome on an HDMI monitor, centred 1:1 inside 1280×1024 on both
boards. It is off by default, because it is not needed to bring a board up and
because it changes what a working machine looks like. It works on hardware:
the PROM's banner, the boot loader and a booting SunOS on a real monitor, with
autoconfig reporting `bwtwo0`.

```sh
make -C sim xsim MACHINE=vme FB=1 MEM_MIB=1
make -C sim xsim MACHINE=multibus FB=1 MEM_MIB=1 ROM=fast
make -C syn bitstream MACHINE=multibus FB=1 BOARD=v1s1 CPU=rd68011
make -C syn quartus MACHINE=vme FB=1 CPU_DIV=60
```

**A machine with a display has no serial console.** When `s2fbthere()`
succeeds the monitor sets `g_outsink = OUTSCREEN` (`sunmon.c:396`) and offers
no way to ask for both, so the serial port goes silent. On the DECA, whose
keyboard SCC has nothing connected, that makes an `FB=1` machine one you can
look at and not talk to.

**It is the same screen on both machines, and largely the same hardware in
quite different places.** Both boot PROMs reach it at the same *virtual*
addresses; all of the difference is one page-map entry each:

| | 2/50 | 2/120 |
|---|---|---|
| Aperture, virtual `0xEC0000` | type 1, pages 0–63 | **type 0**, pages 0xE00–0xE3F → `0x700000` |
| Control register, virtual `0xEE3800` | type 1 page 0x40 | **type 0** page 0xF03 → `0x781800` |
| Keyboard/mouse SCC, virtual `0xEEC000` | type 1 page 0xFE3, on board | **type 0** page 0xF00 → `0x780000`, *on the video board* |

On a 2/120 it is a card in the cage — but a **P2-bus** card, not a MultiBus
one, so it decodes in memory space alongside RAM rather than in the type 2
system-bus space where the Ethernet card lives. Chapter 4 of its manual
decodes nothing but `P2.*`; the P1 connector carries interrupts and power.
`MEM_SPACE_PAGES` is 3584 = 0xE00 on that machine, so the aperture begins
exactly one page past the end of memory space — which is why nothing answered
before, and why the PROM's own memory sizing stops in the same place
(`mon/diag/diag.s:607`, *"Meg 7 is reserved for framebuf"*).

Above `0x700000` the video board decodes A19, A12 and A11 and nothing else, so
the aperture repeats every 128 KiB to `0x77FFFE` and the register and SCC
repeat to `0x7FFFFE`. `MATCH_FB` matches that rather than decoding tightly —
Figure 2-1 of the board manual says so outright, "DO NOT USE, will map to
Video Memory".

1152 × 900 at one bit per pixel is a 144-byte stride and 129,600 of those
131,072 bytes; **a 1 bit is black**, the opposite of a Sun-1. The control
register's DISPEN (bit 15) is the only bit the monitor writes, but SunOS's
`bwtwoprobe` also wants `copybase` to read back what it wrote, wants the
register aliased at `+0` and `+2` across its whole page, and wants the four
jumper bits to read **zero** — a 1 there would ask for 1024×1024, or send the
driver looking for a colour board that is not here. Copy mode and the
retrace interrupt exist as bits and do nothing, which is all any software in
the tree ever needs.

`rtl/sun2-common/sun2_fb_ctl.v` serves both machines without a conditional in
it. Two notes, both worth having written down. The Architecture Manual §6.3
describes bits 11:8 for Machine Type 1 as three reserved bits plus an audio
enable for a sound generator at `0x780800` — but that is the device-layer
abstraction, not this board: Table 2-1 of the board's own manual gives 11:8 as
the J1600 configuration jumpers and marks `0x780800` *NOT USED*. There is no
sound generator on it, and `bw2reg.h` — the driver that has to work on both
machines — agrees with the board. And bits 7 and 0 of the copy base read back
zero, which the board manual states and `bw2reg.h` flags as *"aberrant bits.
Don't depend on 'em!"*; both of `bwtwoprobe`'s test values have them clear, so
no software in the tree can tell.

The pixels live in DDR3, in the top 8 MiB, reached the same way the CPU
reaches memory: `MATCH_FB` is a second aperture on the memory bridge, remapped
to `FB_WB_BASE`, and never cached. So there is no second path to get wrong —
the byte lanes, the read-back and the DTACK are the ones that already carry
every memory cycle. What is new is a second *master*:
`rtl/sun2-common/fb_scanout.sv`, which on the Wukong shares MIG with the CPU
through `boards/Wukong/mig_arb.sv` and on the DECA has a port of BrianHG's
controller to itself.

Scanout reads a line at a time into a ping-pong buffer in `ui_clk` and shifts
it out in the pixel clock. A line is 9 beats of 16 bytes and an HDMI line is
14.8 µs, so the fetch has roughly six times the time it needs; the whole
screen at 60 Hz is 7.8 MB/s against a bus that does over a thousand. The cost
to the CPU is small and measured rather than argued — `make -C sim migddr3`
reports a mean read of 7.0 CPU clocks alone, 7.5 with realistic scanout
traffic and 9.1 with the scanout saturated deliberately.

**On the Wukong** the FPGA makes HDMI itself: `Inputs/hdmi` (hdl-util/hdmi)
does the TMDS encoding and the 10:1 serialising, with `DVI_OUTPUT` so there is
no audio to feed, from a third MMCM in `boards/Wukong/hdmi_clkgen.sv`.
`HDMI_MODE` picks the raster, and **1280×1024 is the default because it is the
mode the full design can clock**: 108.125 MHz pixels and a 540.625 MHz serial
clock, inside both the BUFG's 628 MHz rating and the OSERDESE2's 680. 1080p60's
742 MHz breaks both; `test/hdmi`, the same output with nothing else in the die,
shows 1080p60 fine, and the whole machine does not. `syn/build.tcl` refuses to
write a bitstream with a pulse-width violation unless `ALLOW_PW=1` — which a V3
needs even for 1280×1024, because its −1 part's BUFG is rated lower; whether
the picture is then sound on a V3 has not been measured.

**On the DECA** an Analog Devices ADV7513 does the HDMI, taking parallel
24-bit RGB with sync and data enable. `rtl/sun2-common/video_timing.sv` makes
the raster and `boards/DECA/deca_adv7513_init.sv` configures the chip over I2C;
`test/deca_hdmi` is the output path with no Sun-2 in it at all.

Because the serial port goes silent with a display fitted, the end-to-end
simulation test cannot read a banner off the console; it searches the RAM model
for the Sun logo instead, a known 128-word bitmap from `mon/dpy/sunlogo.c`, and finds it at
row 128 of the frame buffer. That one assertion covers the aperture decode, the
address remap, the byte lanes and the PROM's own drawing code.

It finds it at offset `0x04808` on **both** machines, which is the strongest
available statement that the drawing code really is the same code: `mon/dpy/`
has no `VME` conditionals anywhere in it.

On a 2/120 the display drags one more thing in with it. `sunmon.c:601` is *"On
Multibus, keyboard can't be there if there's no frame buffer"* — with no
display the monitor points `g_keybzscc` at a fake UART inside the PROM and
never touches `0xEEC000`, and with one it calls `reset_uart()` there with no
bus-error catcher in reach. So on that machine `SUN2_FB` also builds the
keyboard/mouse SCC, because the SCC is physically on the video board. Without
it the boot draws its banner and then loops at `L_SETUP_KEYB`, printing
`Timeout` on the screen it just found.

`make -C sim scanout` is the unit test for the display side: it checks every
pixel of a full frame against a positional hash, the window edges, the bit
order, the polarity, and that a line costs exactly nine beats.

And there is a way to actually **look** at what the machine drew:

```sh
make -C sim xsim MACHINE=vme FB=1 MEM_MIB=1   # boot; writes fb.mem at the end
make -C sim screenshot MACHINE=vme            # render it
```

The boot writes the 128 KiB aperture to `build/sim/xsim-<machine>-fb/fb.mem` as raw
32-bit Wishbone words — what is in DDR3, not an unscrambled bitmap. The second
step replays that through the **real `fb_scanout`** at 1920×1080 and writes
`build/sim/unit-scanout/screen.ppm`. That distinction is the point: the logo
search proves the CPU wrote the right bits, and nothing more, because at
`sim/xsim` level the scan-out does not exist. The picture is the first thing
that exercises the line addressing, the bit order inside a beat, the polarity
and the windowbox against real content rather than a hash — and it comes out
of the RTL's opinion of all four, not the testbench's.

Two steps rather than one because a boot is three quarters of an hour and a
render is seconds, so the image can be looked at, the RTL changed and the image
redrawn without booting again. `screenshot` also asserts what it should not
need eyes for: the logo's first two pixels, at screen (448, 218), must come out
white then black — which pins the offset, the beat reassembly, the bit order
and the polarity down in one line.

### Ethernet — the MultiBus machine, which shares none of that

A 2/120 has no on-board Ethernet. It has a card in the MultiBus cage, and the
card is a computer in its own right: the 82586 DMAs into **the board's own
dual-ported memory** through **the board's own page map**, and never becomes a
bus master on the CPU bus at all. There is no DVMA, no MMU involvement, no
arbitration — on the schematic the card passes `P1.BPRN` straight to
`P1.BPRO`. It is a MultiBus slave and nothing more.

`rtl/sun2-multibus/sun2_mb_ether.sv` is the card; `make -C sim xsim MB_ETHER=1` fits it. It
is optional because a 2/120 with an empty cage is equally a real machine, and
it is the one the 22-bus-error fingerprint describes.

Two windows in MultiBus memory space, both jumpered on the real card:

| | |
|---|---|
| `0x88000 +0x000..0x7FE` | page map, 1024 entries of 16 bits, 1 KiB pages |
| `0x88000 +0x800..0x83E` | the board's own ID PROM, low byte of each word |
| `0x88000 +0x840` | status (read) / control (write) |
| `0x88000 +0x844..0x847` | parity error address |
| `0x40000 +0..256K` | the local memory, translated and byte-swapped per page |

The register base is not ours to choose: `iestd[] = { 0x88000, 0x8C000, 0 }` is
in the shipped Rev R image at `0xEF7D58`, next to the strings `ie: cannot
initialize` and `ie: Ethernet cable problem`. The memory base *is* ours,
because the driver reads it back out of `mies_mbmhi` rather than assuming it —
but it has to dodge the SCSI at `0x80000`, the card's own second controller at
`0x8C000`, and the 3Com at `0xE0000`, whose probe is nothing but *did it
answer?*. Naturally aligned at 256 KiB, that leaves `0x40000`.

Which is also why **page-map TYPE 2 is decoded as a space, not a device**.
Nothing decoded it before — a system-bus cycle simply ran out the twelve-clock
timeout — and that was load-bearing, because it is how every one of the PROM's
probes discovers it has nothing to talk to. `sun2_fpga` now emits a bus address
and a select, and DTACK comes from the card; with an empty cage the timeout
still fires and the bus-error count does not move.

Two details worth knowing before touching it, both of which cost time:

* **`mp_swab = 1`, "68000 byte order", is the identity mapping** — not the
  exchanging one, whatever the interface spec's prose suggests. The driver
  byte-reverses every multi-byte field in software (`to_ieaddr`, `to_ieoff`)
  and uses the same conversions unchanged on the VME machine, which has no
  swapper at all. Get it backwards and the chip reads plausible rubbish.
* **The memory window must be naturally aligned.** The card compares `A19:A18`
  for a 256 KiB window, so a base that is merely 64 KiB-aligned spreads it over
  four times its size and swallows whatever else lives there. The module
  `$fatal`s rather than mis-decode quietly.

`make -C sim mbether` is the unit test. It replays the boot PROM's own
sequences rather than a paraphrase of them — `ieprobe()`'s three bus cycles,
`ieinit()`'s page-map programming, and then the chip's SCP handshake, which is
the only check that pins the byte order down.

### Ethernet — the 3Com 3C400, the other MultiBus card

`MB_3C400=1` fits `rtl/sun2-multibus/sun2_mb_3c400.sv` instead: three 2 KiB
packet buffers and two registers in an 8 KiB window at `0xE0000`, which is what
SunOS attaches as `ec0`. It exists because the Sun card's 256 KiB of on-card
memory is 256 of the MAX 10's 182 block RAMs, so a DECA cannot have that card at
any clock; this one costs six. One cage, one MII port, so the two cards are
mutually exclusive and `sun2_fpga` `$fatal`s on the pair.

On a DECA it netboots — RARP, the boot loader over TFTP, an NFS root and a
604 KB kernel, all through the card — and with a disk fitted SunOS attaches
`ec0` beside `xy0`. **What stops it short of a network login is IP
fragmentation**, and it is the card, not the replica: a 4096-byte NFS read reply
is three Ethernet frames, the card has two receive buffers, and the third frame
has nowhere to go. Sun documented exactly this in *Installing the SunOS 4.0.3
Release* — 3Com-equipped Sun-2s "will have trouble booting from fast servers" —
with the same two remedies found here independently: smaller NFS `rsize` and
`wsize`, or the Sun card. `make -C sim mb3c400` is its unit test.

### A disk: the Xylogics 450, on an SD card

`XY450=1` fits a Xylogics 450 SMD disk controller in the MultiBus cage, with a
micro-SD card where four fourteen-inch platters used to be. MultiBus only: a
2/50 takes a Xylogics 451 on the VME bus, which is a different card in a
different address space.

The machine boots from it:

```
Probing Multibus: xy
Auto-boot in progress...
Boot: xy(0,0,0)vmunix
Xylogics 450 boot block running.
```

```sh
tools/mkxydisk -o build/disk/xy0.img            # a labelled, bootable disk
make -C sim xsim XY450=1 MEM_MIB=1 ROM=fast STOP_ON="running." \
     XSIMARGS="-testplusarg blk_image=$PWD/build/disk/xy0.img"
```

`xy` is the *first* entry in the PROM's `boottab[]`, so a `b` with no argument
tries a Xylogics before anything else, and `showconfig()` probes for one every
time the machine starts. Without the card that probe times out and the machine
reports no boot devices, which is what it did until now.

**The registers are in MultiBus I/O space, page-map TYPE 3**, which nothing in
this design decoded before. Six bytes at `0xEE40` — the PROM knows `0xEE40` and
`0xEE48` and probes both, and only controller 0 is fitted, so the second probe
still has to time out. `sun2_fpga` gains an `mbio_*` port beside `mb_*` on
exactly the same terms: a *space*, not a device, where a card answers or the
cycle takes the usual timeout.

**It is the first bus master a MultiBus build has ever had.** The controller
fetches its 24-byte command block and moves every sector itself, and on a Sun-2
that means DVMA: MultiBus address X is virtual `0xF00000 + X`, supervisor data,
through the MMU. `rtl/sun2-vme/sun2_dvma.v` already did that for the 2/50's
Ethernet and needed no change — only `top_fpga.v` stops tying it off.

Three things about this were not obvious and cost real time to establish.

* **The PROM remaps before every boot.** Its steady-state map has virtual
  `0xF00000` as a megabyte of TYPE 2, which would send the controller's DVMA
  cycle straight back out to the bus. But `commands.c:5` is *"Always define it
  until we finger out what to do with DVMA"*, so `FAKES1BOOT` is unconditional,
  and both the `b` command and auto-boot run `setupmap(fakemapinit2)` before
  `boot()` — putting virtual `0xF00000`–`0xF3FFFF`, exactly the 256 KiB DVMA
  window, on physical page `0x180` as ordinary memory. That table is in the Rev
  R image at `0xEF6F04`. **A machine with less than 1 MiB installed therefore
  cannot boot from disk**, because the window lands on physical `0xC0000`;
  `sun2_fpga` `$fatal`s rather than let it read zeroes.
* **The byte numbering is inverted, but only for the IOPB.** MultiBus is
  little-endian and a 68000 is not, so with the data bus wired straight through
  the two byte numberings disagree by one: `xyaddr->xy_csr` is CPU offset 5 and
  hardware register `0x44`, and IOPB byte *N* is at offset *N*^1. SunOS's own
  `struct xydevice` and `struct xyiopb` carry the controller's numbers as
  comments and declare their fields in swapped pairs. Sector data is *not*
  inverted: the manual says the IOPB moves in byte mode while data moves in
  word mode, and no driver in the tree ever sets the byte-mode bit.
* **The image is a memory image.** Sector byte *K* lands at data address *K*,
  so `build/disk/xy0.img` is a byte-for-byte copy of what the Sun sees. That is
  the convention any image anyone can actually produce already has, because the
  only way to read a Sun-2 disk is through a controller — `dd if=/dev/rxy0a`
  yields the bytes the controller put in memory, not the bits on the platter.

Geometry is software-defined. The controller keeps four drive-size slots that
Set Drive Size fills in, and turns cylinder/head/sector into a block number
with `((cyl * heads) + head) * sectors + sector`. Power-up defaults are the
manual's Table 2-8, which matters because the PROM reads block 0 with each
drive type in turn before it has told the controller anything.

`tools/mkxydisk` writes a `dk_label` — magic `0xDABE`, the XOR-of-shorts
checksum `chklabel()` insists on, geometry and one partition — and a boot
program in blocks 1 to 15 that prints through the PROM's own `putchar` and
stops. That is the whole of what `xyboot()` reads before handing over control,
so it is enough to prove the path end to end without anyone having to find a
genuine SunOS image first.

On hardware the media is the V3's micro-SD slot (J9) or the DECA's, through
`blk_sd` and `sd_spi` taken unchanged from `Inputs/Wish5380`, and a real SunOS
4.0.3 disk image boots from it on both boards to a multi-user login, with
`fsck` reading and writing the card on the way. `DISK_OFF_MIB` says where on
the card the disk starts, so one card can hold several images. **A Wukong V1
has no card slot at all**, so that build puts the four SPI lines on PMOD J11 in the order an
off-the-shelf micro-SD PMOD expects — a convention, not a measurement; see
`syn/wukong_sd_v1.xdc`. In simulation the same block seam has `tb/blk_file.sv`
and an ordinary file behind it, which is what makes the whole controller
testable without simulating a card at all.

**It chains.** The 450 executes a linked list of IOPBs from one Go: each
command byte's CHEN bit says whether to follow that IOPB's Next IOPB Address,
relocated by the same registers as the head, so a chain lives inside one 64 KiB
block. SunOS builds one per interrupt — at most one IOPB per drive plus the
controller's own, so five — and expects **one interrupt at the end**, not one
per IOPB: `xyasynch()` sets `xy_ie` and clears `xy_intrall` (`xy.c:709-716`),
and a second interrupt would be read as the *next* chain completing.

Two details of the chain walk are load-bearing and neither is obvious.

* **`xy_nxtoff` is only valid when CHEN is set.** `xychain()` clears
  `xy_chain` on the tail of every chain and never clears the offset beside it
  (`xy.c:744-745`), so the tail carries a live-looking pointer left over from
  whichever chain that IOPB was in the middle of last time. Following it is a
  DMA into the previous transfer's buffer.
* **A hard error stops the chain where it happened.** Everything behind the
  failure must come back untouched, `xy_complete` still clear, because
  `xyintr()` skips those and `xychain()` re-issues them verbatim — *"If the
  done bit isn't set, we just ignore the iopb; it will get chained up and
  executed again"* (`xy.c:1798-1801`).

That last sentence is also why the single-IOPB controller this replaced worked
at all: SunOS handles a card that runs only the head. Chaining buys fidelity,
throughput and fairness rather than correctness, and with one drive fitted a
chain is at most two IOPBs long.

**SunOS 3.4 never uses the Attention protocol.** `XY_ATTN` and `XY_ACK` are
declared in `sundev/xycreg.h` and referenced by no C file in the tree; the
driver only ever touches the controller between chains. It is implemented here
anyway, because AACK means "the chain is standing still and you may edit it"
and granting it mid-transfer — which is what this did before there was a chain
to protect — invites a driver that does use it, such as 4.x's, to rewrite a
link the controller is about to follow.

`make -C sim xy450` is the unit test: 120 checks, all replays of real code —
`xyprobe()` from both drivers, the controller reset, a NOP that has to report
controller type 1, a read of block 0 checked with `chklabel()`'s own checksum,
Set Drive Size, write-then-read, a two-sector transfer across the head
boundary, every completion code a driver in the tree tests for by name, and
the chain cases — one interrupt for a chain of five, a stale tail pointer that
must not be followed, an error that stops the chain dead, a chain that points
at itself, and the Attention handshake.

`make -C sim xychain` is the other half, and the only thing in this design that
has ever taken an interrupt from a MultiBus card. `tools/xychain` is a 68010
program built with an m68k cross-compiler, written on to the disk by
`mkxydisk --boot` and loaded by the boot PROM like any other boot block. It
builds chains in the DVMA window, drives them through the real MMU while the
CPU competes for the bus, installs a level-2 autovector handler at `0x68` and
counts the interrupts. Among other things it reads back the sector that
contains its own first page and compares it against the copy it is executing.

What is deliberately not there: formatting (Write Format, the track-header
commands and the defect map all need real per-sector headers, which an SD card
has no room for), ECC, overlapped seeking (EEF is accepted and ignored — with
one drive there is nothing to overlap and completing in chain order is
explicitly legal), a second controller at `0xEE48`, and 24-bit addressing.

### A disk for either machine: Sun's SCSI host adapter

Sun built one SCSI interface twice — a VME board for a 2/50, with the
machine's real-time clock on it, and a MultiBus card for a 2/120 — and its own
theory of operation says the two are the same design. So here they are one
core, `rtl/sun2-common/sun2_scsi_core.sv`, and two thin cards around it:
`VME_SCSI=1` (`rtl/sun2-vme/sun2_vme_scsi.sv`) and `MB_SCSI=1`
(`rtl/sun2-multibus/sun2_mb_scsi.sv`). The target on the far side is
`Inputs/Wish5380`'s `scsi_targ`, a disk on the same SD-card back end the
Xylogics uses, and SunOS sees it as `sd0`. Both boot SunOS from the card on hardware. `MB_SCSI`
and `XY450` are mutually exclusive — there is one card slot — and
`make -C sim vmescsi` and `make -C sim mbscsi` are the unit tests.

**Which image goes where** matters, because a SunOS root's `fstab` names its
disk: an image built for `xy0` boots on a SCSI machine and then cannot mount
its root read-write. The convention on the cards used here is `xy0` images at
even multiples of 512 MiB and `sd0` images at odd ones, selected with
`DISK_OFF_MIB`.

**Halt the machine before you reprogram the FPGA.** Programming is a power
cut: whatever the kernel had buffered is lost, and the damage appears as
`fsck` failures on the *next* boot. `sync` and `/etc/halt` first, every time.
`BRINGUP.md` has the repair procedure for when it happens anyway.

### The time of day

`rtl/sun2-common/mm58167.v` is a software-compatible National MM58167, the
2/120's time-of-day chip at on-board I/O page 7 (a 2/50's is on the SCSI
board). With it SunOS stops warning `no TOD clock`, `rc` stops dropping to
single user over a nonsense date, and NetBSD gets past `inittodr`. "Software-
compatible" was decided by the two drivers, which disagree: NetBSD's
`mm58167_gettime` waits for the status bit to read *one*, SunOS's `todget`
retries while it does, and both are satisfied by a bit that sets on each 1 kHz
tick and clears when read. The chip has no year register, so the date a board
comes up with is wrong by decades — which can make `cron` spin and eat the
machine; check `ps -aux` before trusting any timing on a board.
`make -C sim mm58167` replays both drivers' sequences over the Sun-2's own bus.

### Everything else

| Define | Effect |
|---|---|
| *(default)* | main memory external, behind the memory bridge — DTACK from the bridge (see [Memory](#memory)). This is what the FPGA build uses, with DDR3 behind it. |
| `MEM_SIM_ONLY` | 512 KiB synchronous SRAM inside `sun2_fpga`, DTACK from fixed bus timing. |
| `MEM_PAGES` | installed memory in 2 KiB pages; default 3584 (7 MiB). Only affects what the PROM finds installed — the bus still answers over the whole of `MEM_SPACE_PAGES` so the PROM's sizing probe works. |
| `ROM_FASTBOOT` | boot PROM with the RAM initialisation pass shortened 64-fold. MultiBus only. |
| `ROM_PRISTINE` | use this machine's unmodified boot PROM. |

`ttl_am9513` additionally takes a `TRACE` parameter (default 0) that turns on a
per-access register trace. It is off because it prints on every timer access
and dominates run time; instantiate the timer as `ttl_am9513 #(.TRACE(1))` in
`rtl/sun2-common/sun2_fpga.v` to get it back.

## Building for hardware

Two boards, one tree. Both flows are driven from `syn/Makefile`, both land
under `build/syn/` — `vivado/` for the Wukong, `quartus/` for the DECA — and
every knob that means the same thing on both boards (`MACHINE`, `CPU`,
`CPU_HZ`/`CPU_DIV`, the cards) is spelled the same way. Nothing generated is
committed, and neither build writes a bitstream that fails timing.

**For SunOS, build with `CPU=rd68011`.** The default core is still Suska,
because that is what the simulation fingerprints are measured against, and
Suska cannot run SunOS.

### The Wukong

Target: QMTech Wukong, **V1** (XC7A100T-2FGG676) or **V3** (XC7A100T-1FGG676),
either with one MT41K128M16JT-125 DDR3L and a 50 MHz oscillator. The board
layer is plain SystemVerilog plus Xilinx's MIG, and no LiteX at all.

```sh
make -C syn ip BOARD=v3             # the MIG DDR3 controller, once per board
make -C syn bitstream BOARD=v3 CPU=rd68011 CPU_DIV=51 \
        MACHINE=multibus MB_ETHER=1 XY450=1          # a 2/120 with network and disk
make -C syn bitstream BOARD=v3 CPU=rd68011 CPU_DIV=51 \
        MACHINE=vme VME_SCSI=1                       # a 2/50 with a SCSI disk
make -C syn program [same knobs]    # JTAG, through a local hw_server
make -C syn flash [same knobs]      # ... or into the SPI flash, for power-on
```

| Knob | Values | |
|---|---|---|
| `BOARD` | `v1` (default), `v1s1`, `v3` | `v3` is what can still be bought. `v1s1` is a V1 built for the slower −1 speed grade, which is the one to use on a V1: a 2/50 built for −2 met timing and stalled on the bench, and the same RTL built for −1 boots. Timing met on a −1 is met on a −2, never the reverse |
| `MACHINE` | `multibus` (default), `vme` | which Sun-2 |
| `CPU` | `suska` (default), `rd68011` | which MC68010 — see above |
| `CPU_DIV` / `CPU_HZ` | 12.5 MHz by default | the CPU clock. `CPU_DIV` names the divider of the 1 GHz VCO directly: `CPU_DIV=51` is 19.6 MHz, what RD68011 builds use. `CPU_HZ` must divide the VCO exactly, and `CPU_DIV` wins if both are given |
| `MB_ETHER`, `MB_3C400` | `0`/`1` | the Sun or 3Com MultiBus Ethernet card |
| `XY450`, `MB_SCSI`, `VME_SCSI` | `0`/`1` | a disk: the Xylogics 450 or the MultiBus SCSI card (MultiBus), the SCSI/RTC board (VME) |
| `DISK_OFF_MIB` | `0` | where on the SD card the disk image starts |
| `FB`, `HDMI_MODE` | `0`, `1280x1024` | the frame buffer, and its video mode |
| `WB_CACHE`, `WB_FIFO` | `1`, `1` | the memory bridge — see [Memory](#memory) |

Every build writes two files: `sun2_wukong_<board>.bit` for JTAG, and beside it
`sun2_wukong_<board>.bin`, the same bitstream without the `.bit` header, which
is the image for the board's SPI configuration flash at address 0.
`make -C syn flash` writes it there through Vivado, verifies it and
reconfigures the board from it; openFPGALoader or a flash programmer can write
it too. The flash is a Micron N25Q064A on a V3 (Vivado part
`n25q64-3.3v-spi-x1_x2_x4`) and an MT25QL128 on a V1
(`mt25ql128-spi-x1_x2_x4`), from `syn/boards.tcl`. Like `make program`, it
replaces whatever the FPGA is running, so halt the Sun-2 first. The bitstream is compressed and
asks for a x4 bus at 33 MHz (`syn/wukong_common.xdc`), so a board configures
from flash in a fraction of a second rather than the ten or so the defaults
would take.

Each combination gets its own output directory under `build/syn/vivado/`,
named from the board, the machine, the cards, the clock and the core — for
instance `v3-multibus-mbether-xy450-cpu19.6-rd68011-div51-off2048m/`. Knobs at
their defaults do not appear in the name.

**RD68011 does not clock anywhere near 40 MHz on this part.** Its critical path
is a half-period one inside the core — rising edge to falling edge — so the
real requirement is half the period asked for. A full 2/120 meets 20 MHz only
inside placement noise and 19.6 MHz (`CPU_DIV=51`) with a few hundred
picoseconds to spare, which is why that is the clock every recent build uses:

| V3, 2/120, Sun Ethernet + Xylogics, RD68011, 19.6 MHz | |
|---|---|
| worst setup / hold slack | 0.463 / 0.050 ns (0.094 / 0.051 on a rebuild: placement) |
| LUTs | 17,237 of 63,400 (27%) |
| block RAM tiles | 90 of 135 |

Suska clocks at 40 MHz (`CPU_HZ=40000000`) but cannot run SunOS, so that is a
monitor-prompt machine. `make -C syn both` builds Suska at 12.5 and 40 MHz.

`BOARD` reaches the MIG too: both boards want identical DDR3 and differ only in
the target part, so `generate_ip.tcl` substitutes it into a per-board copy of
the one committed `.prj`, and `build/ip/<board>/` keeps them from overwriting
each other. `syn/mig/sun2_mig.prj` is the source of truth for the memory
controller (see `syn/mig/README.md` for its provenance and the four fields we
changed).

Two build-time gates exist because each failure they catch once reached a board
silently: an implicit net (Vivado's warning `Synth 8-6901`, which makes an
undeclared identifier an undriven wire) is promoted to an error, and a clock
beyond the rating of the resource carrying it — which `report_timing_summary`
does not show — fails the build unless `ALLOW_PW=1`.

The console is the board's serial port, 9600 8N1. The LED ladder driven from
`sun2_fpga.v` says why a machine stopped when the console cannot; `BRINGUP.md`
says how to read it.

### Clocks

Two MMCMs in `boards/Wukong/wukong_clkgen.sv`, and a third in
`boards/Wukong/hdmi_clkgen.sv` when the frame buffer is built — all
instantiated directly rather than through the clocking wizard, so the files
read and simulate like any other source.

| Clock | Derivation | Result |
|---|---|---|
| MIG `sys_clk` 166.667 MHz | MMCM A, VCO 1000 MHz, ÷6 | exact |
| `cpu_clk` 12.5, 19.6 or 40 MHz | MMCM A, ÷80, ÷51 (`CPU_DIV=51`) or ÷25 | exact |
| IDELAYCTRL 200 MHz | MMCM A, ÷5 | exact |
| SCC `serial_clk` 4.9152 MHz | MMCM B, ÷2 ×24.625 ÷125.25 | 4.915170 MHz, +0.0006% |
| HDMI `clk_pixel`, 1280×1024 | MMCM C | 108.125 MHz, VESA's 108 + 0.12% |
| HDMI `clk_pixel_x5`, 1280×1024 | MMCM C | 540.625 MHz, exactly 5× |

4.9152 MHz is not a rational multiple of 50 MHz with small terms, so it gets an
MMCM to itself — where the fractional CLKOUT0 divider brings it within
0.0006%, and where changing `CPU_CLK_HZ` cannot perturb it. That matters
because the PROM derives the 9600 baud console straight from this clock. The
200 MHz output is needed because MIG only allows its "use the system clock"
IDELAYCTRL option when the input clock *is* 200 MHz.

The pixel clock gets a third MMCM because neither of the others can make it:
A's spare outputs are integer dividers off a 1 GHz VCO, and B's one fractional
output is the serial clock, which must not be perturbed. 1080p60's
148.4375 MHz (QMTech's own recipe for this board) is still there for
`HDMI_MODE=1080p60`, and its 742 MHz serial clock is the one this design cannot
carry — see [the frame buffer](#the-frame-buffer-and-hdmi).

`tb_clkgen` measures all six in simulation rather than trusting the
arithmetic — which is how the step-1 baud rate bug would have been caught. It
also checks the one relationship the TMDS serialisers depend on, that
`clk_pixel_x5` is *exactly* five times `clk_pixel`: OSERDESE2 in 10:1 DDR does
not work otherwise, and a behavioural model that generates the two clocks
independently is not five to one no matter how close each is on its own.

### Memory

Main memory is the board's DDR3, and between the Sun-2's bus and it sits a
**memory bridge** in `rtl/sun2-common/` — shared by both boards — with a
synchronous adapter per board beyond it. There are three bridges, selected by
two knobs that mean the same thing in every flow:

| | Bridge | What it does |
|---|---|---|
| default | `sun2_cached_fifo_bridge` | the FIFO bridge below, with a direct-mapped read cache of 16-byte lines in front of it: 8 KiB by default (`WB_CACHE_IDX=9`, log2 of the lines), write-through and no-allocate. A read that hits answers in its first clock; a miss brings back the whole 128-bit DDR3 beat and keeps it |
| `WB_CACHE=0` | `sun2_fifo_bridge` | requests out and read answers back through two asynchronous FIFOs, with the memory side on the controller's own clock. A write is acknowledged the clock after it is queued; a read waits for the answer carrying its own tag and drops any other |
| `WB_FIFO=0` | `sun2_wishbone_bridge` | the original: every access waits for the controller's acknowledgement, which comes back through the adapter's own clock crossing (`boards/Wukong/wb_to_mig_ui.sv`, `boards/DECA/deca_wb_to_ddr3.sv`) |

What the two newer ones are worth, measured on the boards with everything else
equal — the dhrystone and memory-loop columns are `user` seconds, the others
wall-clock, and every `patwr` pass read back 0 wrong words out of 8,388,608:

| Wukong V3, 2/120 + Xylogics, 19.6 MHz | dhrystone | memory loop | 16 MiB `dd` | 16 MiB `patwr` |
|---|---|---|---|---|
| `WB_FIFO=0` | 69.8 s | 86.4 s | 188.1 s | 1716.0 s |
| `WB_CACHE=0` | 63.4 s | 78.7 s | 168.5 s | 1562.2 s |
| default | **26.7 s** | **31.2 s** | **74.4 s** | **608.8 s** |

The DECA follows the same shape — 64.7, 58.4 and 30.4 s of dhrystone at
16.667 MHz. The cache costs 4.5 block RAM tiles on a Wukong and 72,176 memory
bits on the DECA; `WB_CACHE=0` is for a board that cannot spare them.

It is coherent without trying: DVMA drives the same 68010 wires as the CPU, so
every master's writes pass the cache, and the only other client of DDR3, the
frame buffer's scan-out, only reads. The frame-buffer aperture is not cached.

On the Wukong, `boards/Wukong/mig_arb.sv` owns MIG's `app_*` port and
round-robins between the CPU's adapter (`wb_mig_sync.sv` behind the FIFO
bridges) and the frame buffer's scan-out. One transaction in flight on the
whole interface, because what MIG's `ORDERING = "NORM"` guarantees about
read-data return order is not established here and the read path carries no
tag. `app_wdf_mask` masks per byte, so sub-word writes need no
read-modify-write.

### Board-level simulation

```sh
make -C sim board                    # behavioural RAM, boots to the prompt
make -C sim board BOARD_MEM=ddr3     # real MIG + Micron's DDR3 model
```

The fast configuration leaves MIG out and hangs `wb_ram_model` on the Wishbone
port, and generates the clocks behaviourally: the MMCME2 model simulates a
1 GHz VCO and costs more events than the rest of the machine put together,
about 6× overall. Use `BOARD_CLKGEN=real` to simulate the actual MMCMs.

The `ddr3` configuration is for bring-up, not booting: MIG calibrates against
the Micron model at 125 µs and the reset chain releases the Sun-2 190 ns later,
but the boot PROM does not touch main memory until `L_M_MAP` around 600 ms,
which is far past what a full DDR3 model can simulate in reasonable time.

**The board testbench does not build with `FB=1`** — `sim/run_xsim_board.sh`
compiles `hdmi_clkgen.sv` but none of
`Inputs/hdmi/src/*.sv`, so `hdmi` is unresolved. Adding them is not quite free:
without `SYNTHESIS`, `MODEL_TECH` or `ALTERA_RESERVED_QIS`, `serializer.sv`
takes its generic IP-less branch, and both that branch and the `MODEL_TECH` one
drive `tmds[i]` from a posedge *and* a negedge `always_ff` — the DDR trick,
which xsim will not accept. The generic branch also assigns the 3-bit
`tmds_shift_negedge_temp` to the 1-bit `tmds_clock`, where it means
`tmds_clock_negedge_temp`. Both are one small `patches/hdmi/` away if the TMDS
stream is ever worth simulating. As it stands the frame buffer is simulated at
`sim/xsim` level, the display side by `make -C sim scanout` and `make -C sim
screenshot`, and the TMDS output itself only by the bitstream and, eventually,
a monitor.

That leaves one join the two board configurations do not cover — the adapter
talking to the *actual* controller rather than a model of it — so there is a
third test for exactly that:

```sh
make -C sim migddr3cached  # the default bridge + real MIG + Micron model, minutes
make -C sim migddr3        # the same for the synchronous bridge and wb_to_mig_ui
make -C sim adapter    # wb_to_mig_ui vs the reference, randomised, seconds
make -C sim cachedbridge   # the read cache against a bus-level shadow
make -C sim orphan     # a refused cycle must not leave a request behind (also orphancached)
make -C sim dvma       # sun2_dvma: Wishbone master -> 68010 bus cycles
make -C sim clkgen     # measure the generated clocks
make -C sim phy        # phy_rtl8211_init vs an independent clause-22 PHY model
make -C sim scanout    # fb_scanout: a whole frame, pixel by pixel
```

`migddr3` also stands in for the frame buffer's share of the bus:
`XSIMARGS="-testplusarg fb_traffic"` runs a scan-out-shaped second client
alongside the CPU, and `+fb_saturate` runs one that never stops asking. The
mean CPU read goes 7.0 → 7.5 → 9.1 clocks across the three.

Micron's DDR3 model comes from the *generated* example design, not the copy in
the Vivado install — that one is an unsubstituted template full of
`%MEM_DENSITY` placeholders. Either way it is referenced, never committed: it
carries Micron's AS-IS licence, not an open one.

### Things about the Wukong worth knowing

* **The V1 50 MHz input (M22) is not on a clock-capable pin**, so the XDC needs
  `CLOCK_DEDICATED_ROUTE FALSE` on it. V2/V3 moved the oscillator to M21.
* **`clk50` has an explicit `BUFG`, and needs one.** It is not only the MMCMs'
  reference — the reset assembly and the PHY reset sequencer are clocked by it
  directly. Vivado infers the buffer, but not reliably: it inferred one for a
  MultiBus build and not the VME build of the same commit, with 13 of 32 BUFGs
  used either way. Left on general routing it measured 0.93 ns of skew and lost
  a same-clock hold path by 270 ps.
* **`if` is not supported in an XDC file.** Vivado's constraint parser accepts
  the file, emits `CRITICAL WARNING: [Designutils 20-1307]` among thousands of
  lines, and skips the block — which is how a `set_clock_groups` went missing
  and turned an asynchronous crossing into a 5 ns timing failure. Conditional
  constraints belong in `build.tcl`, choosing which XDC to read.
* **DDR3 `CS#` must not be driven.** Sheet 3 of the V1 schematic shows it tied
  low through R35 and not routed to the FPGA; E22 is a free I/O. MIG's
  configuration has the chip-select pin disabled, which is correct. The old
  LiteX XDC constrains `ddram_cs_n` to E22 and is wrong.
* **Bank 16 needs `INTERNAL_VREF 0.675`** — MIG emits this itself.
* Two Vivado non-project traps, both handled in `syn/build.tcl`: the part must
  be set *before* `read_ip`, or the IP silently locks against a default Kintex
  device; and `read_ip` alone is not enough — the IP needs `synth_ip`, or the
  top fails with a misleading "module not found".

### The DECA

Target: Arrow DECA, an Intel MAX 10 (10M50DAF484C6GES) with DDR3, built with
Quartus (`QUARTUS_ROOTDIR`, `/opt/Altera/quartus` by default; developed on
25.1). There is no hard memory controller, so DDR3 comes from
`Inputs/BrianHG-DDR3`, run at 250 MHz — its own 400 MHz project is refused by
current Quartus — with its read and write caches switched off, because a cache
whose freshness is a timeout counted in clocks returned stale data to the CPU.

```sh
make -C syn quartus MACHINE=multibus CPU_DIV=60 XY450=1 DISK_OFF_MIB=1024
make -C syn quartus MACHINE=vme CPU_DIV=60 VME_SCSI=1 DISK_OFF_MIB=1536
make -C syn quartus MACHINE=vme CPU_DIV=60           # netboot only
make -C syn lint-quartus                             # read the RTL, no fit
syn/altera.sh quartus_pgm -m JTAG -o "p;build/syn/quartus/<dir>/sun2.sof"
```

`quartus` always builds RD68011. The knobs are the Wukong's, plus `CPU_DUTY`,
below; output lands in `build/syn/quartus/deca-<machine>-rd68011-cpu<MHz>-...`.
Every build diffs the board top's port list against `top_fpga.v` with
`tools/portcheck.sh` and fails on an implicit net, for the same reasons as the
Vivado gates.

**The clock is 16.667 MHz (`CPU_DIV=60`).** The limit is the same half-period
path inside the CPU core that caps the Wukong, and its two halves want the
period split unevenly: `CPU_DUTY=53` takes the machine to 17.857 MHz
(`CPU_DIV=56`) and a login prompt, which a 50/50 clock at that frequency does
not reach. A 2/120 with the Xylogics and the default memory bridge is 26,625
logic elements (54%) and 732,816 memory bits (44%), Fmax 17.69 MHz.

**What fits:** a 2/50 with its on-board Ethernet and a SCSI disk, or a 2/120
with the Xylogics or the SCSI card, the 3Com Ethernet card and the frame
buffer. **Not the Sun MultiBus Ethernet card**, whose 256 KiB of on-card memory
is 256 block RAMs on a device that has 182.

**The console is a JTAG UART** over the board's USB-Blaster II, because the
DECA has no serial port. `tools/deca_console_pty.sh` presents it as an ordinary
terminal at `/tmp/deca-console`; it holds the JTAG chain while it runs, so stop
it before programming or probing. The machine's raw 9600-baud transmit line is
also on `GPIO0_D[0]` (P8 pin 3) for a 3.3 V USB-serial cable, which leaves the
chain free. `quartus_stp -t tools/deca_reset.tcl` reads the machine's panels
over JTAG — the front-panel LEDs, the debug ladder, DDR3 calibration, PHY link
and the SD card's state — and with `reset` pulses the machine's reset.

A few things about the board, each of which cost time:

* **Initialised memory becomes logic unless told otherwise.** Without
  `INTERNAL_FLASH_UPDATE_MODE "SINGLE COMP IMAGE WITH ERAM"` Quartus builds
  every initialised ROM — the boot PROM, RD68011's microcode — out of gates,
  silently, and the design does not fit. `syn/quartus.tcl` sets it.
* **The SD card is behind a level translator**, U22 on the 1.5 V DDR3 rail,
  and four of its eight pins steer the translator rather than carrying data.
  **There is no card-detect line**, so an empty slot and a card that never
  initialised look the same; `deca_reset.tcl` reports whether `blk_sd` came
  ready and the capacity it read from the card, which is true of a blank card
  and so proves the whole path before any image exists.
* **The eight LEDs are active low, and `LED[7]` is the leftmost.**
* **The JTAG UART's clock must be well above TCK** (10 MHz here). Below it
  the host read each byte twice and out of order; at 1.7 times it, typed input
  still arrived with adjacent bytes swapped. The console bridge runs on the
  board's 50 MHz oscillator, and holds 2 KiB so a slow host loses nothing.

`test/` holds a standalone design for each block that could be doubted on its
own — `deca_console`, `deca_ddr3`, `deca_hdmi`, `deca_sdtest` and
`deca_bridge` — each about a minute to build, so a failing block can be
separated from the machine around it.
