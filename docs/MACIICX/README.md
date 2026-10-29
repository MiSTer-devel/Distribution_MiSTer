# Macintosh SE/30 and IIcx for the [MiSTer Board](https://github.com/MiSTer-devel/Main_MiSTer/wiki)

Emulation cores for the **Apple Macintosh SE/30** and the **Macintosh IIcx** running on MiSTer FPGA.
The IIcx is the SE/30's machine in a desktop case, with NuBus slots in place of the built-in
screen; both cores are built from this one source tree.

The core is built from the SE/30's documentation (the *Guide to the Macintosh Family
Hardware*, Apple's schematic and the chips' manuals), with MAME and WinUAE used as
cross-checks. The CPU is the TG68K core with a 68030 PMMU, extended here to the full 68030
bus and caches; the SCSI targets (hard disks and CD-ROM) are a rewrite of the MacPlus core's.
The IIcx's NuBus interface and video card follow Apple's *Designing Cards and Drivers for the
Macintosh Family* and the card's own declaration ROM.
See [Credits](#credits) for the people whose work this builds on.

## Status

### Working

- Boots **System 6.0.5, 6.0.8, 7.1 and 7.5.5** from floppy or SCSI, in 24-bit or 32-bit mode
- Runs **A/UX 3.1**, Apple's Unix, with its X11 clients (see [A/UX](#aux))
- **68030 CPU with PMMU and caches** at the SE/30's 15.67 MHz, timed to match a real machine
- **68882 FPU**
- **Memory:** 8 MB or 16 MB
- **Display:** the SE/30's built-in 512×342 black-and-white screen; on the IIcx, Apple's
  Macintosh II Video Card: 640×480 in black and white, or 4, 16 or 256 colours or greys
- **Sound** (Apple Sound Chip)
- **Floppy disks (read/write):** 400K/800K GCR and 720K/1.44 MB MFM, raw or DiskCopy 4.2
- **SCSI hard disks** on IDs 0 and 1 (read/write, boot)
- **CD-ROM drive** on SCSI ID 3 (data discs)
- **ADB keyboard and mouse**
- **PRAM:** saved to an image file, loaded at core start, and wipeable from the OSD

### Not included

- Serial ports / LocalTalk
- CD audio
- External floppy drive
- Expansion cards (the SE/30's PDS slot; the IIcx's slots beyond the video card)
- The programmer's switch (NMI)

## Usage

1. Copy the newest `MacSE30_<date>.rbf` from [releases](releases) to the `_Computer` folder of
   your MiSTer SD card (any folder works; update_all puts it in `_Computer` and fetches each
   new version).
2. Copy `boot0.rom`, `boot1.rom` and `boot2.rom` from [releases](releases) to the `games/MACSE30` folder.
3. Place a bootable SCSI hard-disk image (`.vhd` / `.img`) or floppy image in the `games/MACSE30` folder.

Open the on-screen display with **F12** to mount images and change options. **Aspect ratio**
and **Scale** set the picture's shape and integer scaling; **Mouse speed** slows a modern
mouse (/2, /4, /8) toward the feel of Apple's.

For the IIcx, use the newest `MacIIcx_<date>.rbf` and the `games/MACIICX` folder, with
`boot0.rom`, `boot2.rom` and `boot3.rom` (see [Macintosh IIcx](#macintosh-iicx) below).

## ROMs

| file | contents |
|---|---|
| `boot0.rom` | the 256 KB SE/30 ROM (checksum `$97221136`) |
| `boot1.rom` | the 8 KB video declaration ROM |
| `boot2.rom` | the 1 KB ADB transceiver firmware (342S0440-B); without it the keyboard and mouse do not work |
| `boot3.rom` | the IIcx only: the 4 KB declaration ROM of the Macintosh II Video Card (342-0008-A) |

The SE/30 and the IIcx share `boot0.rom` and `boot2.rom`.

## Floppy disks

The internal drive takes raw (`.dsk` / `.img`) or DiskCopy 4.2 images. Writes go back to
the image on the SD card. Eject a disk from within the Mac before mounting another one.
A disk mounted while another is still in the drive waits until the Mac ejects the old
one (or restarts). Meanwhile the old disk is read-only: anything written to it fails
with a disk error, and the Mac may then eject it by itself.

## Hard disks and CD-ROM

`Mount SCSI-0` and `Mount SCSI-1` are hard disks at IDs 0 and 1. `Mount CD-ROM` takes ISO
or Toast images at ID 3; the System needs Apple's CD-ROM extension to read them. Start up
from a hard disk or a floppy: a hard-disk image needs an Apple partition map and driver (prepare
a blank image with Apple HD SC Setup); the CD-ROM is for data discs.

**Never mount the same image file in both SCSI slots.** The Mac then sees two disks sharing
every block, and each one's writes overwrite the other's directory: the image is quickly
destroyed. The core cannot detect it.

The drive is an AppleCD SC. Use Apple CD-ROM 5.1.7 or later (System 7.5.3 onward ships it,
and it runs on 7.1), or keep a disc mounted: versions 4.0.x and 5.0.1 poll an empty drive
and slow the Mac to a crawl, as on a real Mac.

## Memory and 32-bit mode

Select 8 MB or 16 MB in the OSD and use **Reset & Apply Memory**. In 24-bit mode the Mac
uses at most 8 MB. The SE/30 ROM is not 32-bit clean: for 32-bit addressing install
Apple's **MODE32** extension (with its installer) and turn 32-Bit Addressing on in the
Memory control panel. Older software often fails in 32-bit mode, as on a real SE/30.

## A/UX

A/UX 3.1 runs from a hard-disk image with A/UX installed, mounted as SCSI-0 or SCSI-1, on
either core.

- Select **16 MB**.
- Shut A/UX down from the Finder before resetting the core or copying the image off the SD
  card: A/UX keeps recent writes in memory, and a reset loses them.
- When a Mac program crashes, A/UX restarts its Mac environment; Unix runs on.
- QuarkXPress 3.32 reports "Unable to access network" and quits. Turn AppleTalk off (Chooser:
  Inactive, and `/etc/appletalk -d` as root) and it runs.

## PRAM

Copy the blank `MacSE30.nvr` from [releases](releases) to `games/MACSE30` (on the IIcx,
`MacIIcx.nvr` to `games/MACIICX`) and mount it with `Mount PRAM` to keep the Mac's settings.
It is loaded at core start, and changes are saved automatically. `Mount PRAM` and
`Wipe PRAM` restart the Mac. The clock is set from MiSTer's time.

## Macintosh IIcx

The IIcx core is the same machine as the SE/30 core, with Apple's Macintosh II Video Card in
NuBus slot 9 in place of the built-in screen. Choose the colours or greys in the Monitors
control panel; the Mac keeps the setting in PRAM. The card's picture is 640×480 at 66.6 Hz;
with `vsync_adjust` 1 or 2 the HDMI output follows it.

Shut Down turns the IIcx off, leaving a dark screen. The keyboard's Power key (on a PS/2
keyboard, the ACPI Power key) or the OSD's reset turns it on again. With the OSD's
**Power switch** set to **Locked on**, Shut Down restarts the Mac instead, as with the
IIcx's rear switch locked on.

## Keyboard

Alt is the Command (⌘) key and the Windows key is Option (⌥). Hold Shift after the startup
chime to start System 7 with extensions off.

## Building

Quartus Prime 17.0.2 Lite: open `MacSE30.qpf` and compile; for the IIcx, compile the
`MacIIcx` revision (`MacIIcx.qsf`). The 68882 microcode in `rtl/fpu/ucode` is built from
`tools/fpu_ucode/ucode` with `tools/fpu_ucode/asm.py`.

## Credits

- **Sorgelig**: the MiSTer framework (`sys/`, from [Template_MiSTer](https://github.com/MiSTer-devel/Template_MiSTer))
  and the [MacPlus core](https://github.com/MiSTer-devel/MacPlus_MiSTer)
- **Tobias Gubener**: the TG68K CPU core
- **apolkosnik**: the 68030 PMMU ([Minimig-AGA_MiSTer](https://github.com/apolkosnik/Minimig-AGA_MiSTer), branch `030_mmu2`)
- **Dani Sarfati**: the [MacLC](https://github.com/MiSTer-devel/MacLC_MiSTer) and
  [MacIIvi](https://github.com/danifunker/MacIIvi_MiSTer) cores, the source of several peripheral
  modules and the PMMU's route to the Macintosh
- **Steve Chamberlin**: [Plus Too](http://www.bigmessowires.com/plus-too/), where the MacPlus core began
- **Bolle**: the reproduction of the SE/30's video PALs and the `macse30mlb` schematic redraw,
  which made the video readable

## Licence

GPL-2.0-or-later. The TG68K files are LGPL-3.0-or-later.
