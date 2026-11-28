# Macintosh IIci for the [MiSTer Board](https://github.com/MiSTer-devel/Main_MiSTer/wiki)

An emulation core for the **Apple Macintosh IIci** running on MiSTer FPGA: the 25 MHz 68030
Macintosh with built-in video, including Apple's Portrait Display.

The core is built from Apple's documentation (the *Guide to the Macintosh Family Hardware*,
Apple's specifications of the IIci's MDU and RBV chips, and the chips' manuals), with MAME used
as a cross-check. It comes from the same project as the
[Macintosh SE/30 and IIcx cores](https://github.com/MiSTer-devel/MacSE30_MiSTer) and shares
their CPU, FPU and peripherals. See [Credits](#credits) for the people whose work this builds on.

## Status

### Working

- Tested with **System 7.1 and 7.5.5**, from floppy and SCSI
- **68030 CPU with PMMU, caches and burst fills** at 25 MHz, timed to match a real IIci
- **68882 FPU** at 25 MHz
- **Memory:** 4, 8, 16 or 32 MB (32 MB needs a 64 MB or larger SDRAM module)
- **Built-in video:** the 640×480 colour monitor (1 to 8 bits per pixel), or Apple's
  **Portrait Display** (640×870, 1 to 4 bits per pixel grey), upright or turned for a monitor
  on its side
- **RAM cache card** (32 or 128 KB) or none
- **Sound** (Apple Sound Chip)
- **Floppy disks (read/write):** 400K/800K GCR and 720K/1.44 MB MFM, raw or DiskCopy 4.2
- **SCSI hard disks** on IDs 0 and 1 (read/write, boot)
- **CD-ROM drive** on SCSI ID 3 (data discs)
- **ADB keyboard and mouse**
- **PRAM:** saved to an image file, loaded at core start, and wipeable from the OSD
- **Soft power:** Shut Down turns the Mac off
- Runs **A/UX 3.1** and **NetBSD 11.1** (see [NetBSD](#netbsd))

### Not included

- Serial ports / LocalTalk
- CD audio
- NuBus cards (the slots are empty)
- The programmer's switch (NMI)

## Usage

1. Copy the newest `MacIIci_<date>.rbf` from [releases](releases) to the `_Computer` folder of
   your MiSTer SD card.
2. Copy `boot0.rom` and `boot2.rom` from [releases](releases) to the `games/MACIICI` folder.
3. Place a bootable SCSI hard-disk image (`.vhd` / `.img`) or floppy image in the `games/MACIICI` folder.

Open the on-screen display with **F12** to mount images and change options. **Aspect ratio**
and **Scale** set the picture's shape and integer scaling; **Mouse speed** slows a modern
mouse (/2, /4, /8) toward the feel of Apple's.

## ROMs

| file | contents |
|---|---|
| `boot0.rom` | the 512 KB Macintosh IIci ROM (checksum `$368CADFE`) |
| `boot2.rom` | the 1 KB ADB transceiver firmware (342S0440-B); without it the keyboard and mouse do not work |

## Monitor

**Monitor** chooses the 640×480 colour monitor or the Portrait Display. The Mac reads the
monitor at startup: choose it, then use **Reset & Apply**. Set the colours or greys in the
Monitors control panel.

**Portrait rotated** turns the Portrait Display's picture a quarter turn, clockwise or
anticlockwise, for a monitor on its side; it takes effect at once. The analogue video output
stays upright. For even text, choose a scaler filter made for vertical displays in MiSTer's
video settings, and set `osd_rotate=1` or `2` in `MiSTer.ini` to turn the OSD as well.

The Portrait Display is much taller than the 640×480 screen: a faster tracking speed in the
Mouse control panel helps.

## Floppy disks

The internal drive takes raw (`.dsk` / `.img`) or DiskCopy 4.2 images. Writes go back to
the image on the SD card. Eject a disk from within the Mac before mounting another one.
A disk mounted while another is still in the drive waits until the Mac ejects the old
one (or restarts). Meanwhile the old disk is read-only.

## Hard disks and CD-ROM

`Mount SCSI-0` and `Mount SCSI-1` are hard disks at IDs 0 and 1. `Mount CD-ROM` takes ISO
or Toast images at ID 3; the System needs Apple's CD-ROM extension to read them. A hard-disk
image needs an Apple partition map and driver (prepare a blank image with Apple HD SC Setup).

**Never mount the same image file in both SCSI slots.** The Mac then sees two disks sharing
every block, and the image is quickly destroyed. The core cannot detect it.

The drive is an AppleCD SC. Use Apple CD-ROM 5.1.7 or later, or keep a disc mounted:
versions 4.0.x and 5.0.1 poll an empty drive and slow the Mac to a crawl, as on a real Mac.

## Memory and cache card

Select the memory and the cache card in the OSD and use **Reset & Apply**. The 8 and 32 MB
settings use both RAM banks and are offered only with a 64 MB or larger SDRAM module. The IIci
ROM is 32-bit clean: turn 32-Bit Addressing on in the Memory control panel to use more than
8 MB.

## NetBSD

NetBSD 11.1 (mac68k) runs with the **SBC** kernels (`INSTALLSBC` to install, `GENERICSBC` to
run). Quitting X can panic the kernel: NetBSD's `pmap_enter` mishandles physical page 0, where
the IIci's frame buffer is, so a real IIci does the same. A kernel with that fixed avoids it.

## Power

Shut Down turns the Mac off, leaving a dark screen. The keyboard's Power key (on a PS/2
keyboard, the ACPI Power key) or the OSD's reset turns it on again. With the OSD's
**Power switch** set to **Locked on**, Shut Down restarts the Mac instead.

## PRAM

Copy the blank `MacIIci.nvr` from [releases](releases) to `games/MACIICI` and mount it with
`Mount PRAM` to keep the Mac's settings. It is loaded at core start, and changes are saved
automatically. `Mount PRAM` and `Wipe PRAM` restart the Mac. The clock is set from MiSTer's
time.

## Keyboard

Alt is the Command (⌘) key and the Windows key is Option (⌥). Hold Shift after the startup
chime to start System 7 with extensions off.

## Building

Quartus Prime 17.0.2 Lite: open `MacIIci.qpf` and compile. The 68882 microcode in
`rtl/fpu/ucode` is built in the [MacSE30 project](https://github.com/MiSTer-devel/MacSE30_MiSTer).

## Credits

- **Sorgelig**: the MiSTer framework (`sys/`, from [Template_MiSTer](https://github.com/MiSTer-devel/Template_MiSTer))
  and the [MacPlus core](https://github.com/MiSTer-devel/MacPlus_MiSTer)
- **Tobias Gubener**: the TG68K CPU core
- **apolkosnik**: the 68030 PMMU ([Minimig-AGA_MiSTer](https://github.com/apolkosnik/Minimig-AGA_MiSTer), branch `030_mmu2`)
- **Dani Sarfati**: the [MacLC](https://github.com/MiSTer-devel/MacLC_MiSTer) and
  [MacIIvi](https://github.com/danifunker/MacIIvi_MiSTer) cores, the source of several peripheral
  modules and the PMMU's route to the Macintosh
- **Steve Chamberlin**: [Plus Too](http://www.bigmessowires.com/plus-too/), where the MacPlus core began

## Licence

GPL-2.0-or-later. The TG68K files are LGPL-3.0-or-later.
