# Macintosh SE/30 for the [MiSTer Board](https://github.com/MiSTer-devel/Main_MiSTer/wiki)

An emulation core for the **Apple Macintosh SE/30** running on MiSTer FPGA.

The core is built from the SE/30's documentation (the *Guide to the Macintosh Family
Hardware*, Apple's schematic and the chips' manuals), with MAME and WinUAE used as
cross-checks. The CPU is Tobias Gubener's TG68K core with apolkosnik's 68030 PMMU, extended
here to the full 68030 bus and caches. The SCSI target (hard disks and CD-ROM) is Daniel
Baum's rewrite of the one in the [MacPlus MiSTer core](https://github.com/MiSTer-devel/MacPlus_MiSTer),
which came from the MiST port of Plus Too. Bolle's
reproduction of the SE/30's video PALs made the video readable.

## Status

### Working

- Boots **System 6.0.5, 6.0.8, 7.1 and 7.5.5** from floppy or SCSI, in 24-bit or 32-bit mode
- **68030 CPU with PMMU and caches** at the SE/30's 15.67 MHz, timed to match a real machine
- **68882 FPU**
- **Memory:** 8 MB or 16 MB
- **Display:** the built-in 512×342 black-and-white screen
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
- Expansion (PDS) cards
- The programmer's switch (NMI)

## Usage

1. Copy the newest `MacSE30_<date>.rbf` from [releases](releases) to the `_Computer` folder of
   your MiSTer SD card (any folder works; update_all puts it in `_Computer` and fetches each
   new version).
2. Copy `boot0.rom`, `boot1.rom` and `boot2.rom` from [releases](releases) to the `games/MACSE30` folder.
3. Place a bootable SCSI hard-disk image (`.vhd` / `.img`) or floppy image in the `games/MACSE30` folder.

Open the on-screen display with **F12** to mount images and change options.

## ROMs

| file | contents |
|---|---|
| `boot0.rom` | the 256 KB SE/30 ROM (checksum `$97221136`) |
| `boot1.rom` | the 8 KB video declaration ROM |
| `boot2.rom` | the 1 KB ADB transceiver firmware (342S0440-B); without it the keyboard and mouse do not work |

## Floppy disks

The internal drive takes raw (`.dsk` / `.img`) or DiskCopy 4.2 images. Writes go back to
the image on the SD card. Eject a disk from within the Mac before mounting another one.
A disk mounted while another is still in the drive waits until the Mac ejects the old
one (or restarts). Meanwhile the old disk is read-only: anything written to it fails
with a disk error, and the Mac may then eject it by itself.

## Hard disks and CD-ROM

`Mount SCSI-0` and `Mount SCSI-1` are hard disks at IDs 0 and 1. `Mount CD-ROM` takes ISO
or Toast images at ID 3; the System needs Apple's CD-ROM extension to read them.

## Memory and 32-bit mode

Select 8 MB or 16 MB in the OSD and use **Reset & Apply Memory**. In 24-bit mode the Mac
uses at most 8 MB. The SE/30 ROM is not 32-bit clean: for 32-bit addressing install
Apple's **MODE32** extension (with its installer) and turn 32-Bit Addressing on in the
Memory control panel. Older software often fails in 32-bit mode, as on a real SE/30.

## PRAM

Copy the blank `MacSE30.nvr` from [releases](releases) to `games/MACSE30` and mount it with
`Mount PRAM` to keep the Mac's settings. It is loaded at core start, and changes are saved
automatically. `Mount PRAM` and `Wipe PRAM` restart the Mac. The clock is set from
MiSTer's time.

## Keyboard

Alt is the Command (⌘) key and the Windows key is Option (⌥). Hold Shift after the startup
chime to start System 7 with extensions off.

## Building

Quartus Prime 17.0.2 Lite: open `MacSE30.qpf` and compile. The 68882 microcode in
`rtl/fpu/ucode` is built from `tools/fpu_ucode/ucode` with `tools/fpu_ucode/asm.py`.

## Licence

GPL-2.0-or-later. The TG68K files are LGPL-3.0-or-later.
