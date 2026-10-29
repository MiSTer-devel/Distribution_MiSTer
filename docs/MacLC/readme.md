# Macintosh LC for the [MiSTer Board](https://github.com/MiSTer-devel/Main_MiSTer/wiki)

An emulation core for the **Apple Macintosh LC** running on MiSTer FPGA.

Based on the [MacPlus MiSTer core](https://github.com/MiSTer-devel/MacPlus_MiSTer) by Sorgelig,
which originated from the [Plus Too project](http://www.bigmessowires.com/plus-too/). The Mac LC
emulates a Motorola 68020 CPU (via a modified TG68K core), the V8 gate array (video/glue),
the Egret (HC05) system controller, and the LC's other peripherals.

> **Work in progress.** This is an actively-developed core.

## Status

### Working

- Boots **Mac OS 6.0.8, 7.1, and 7.5.5** from SCSI to the Finder desktop
- **68020 CPU** via TG68K (with core-specific tweaks), running at the LC's native ~15.67 MHz
- **SCSI hard disks** on IDs 0 and 1 (read/write, boot) — two drives plus the CD-ROM
  run together
- **File transfer** to/from the SD card via the BlueSCSI Toolbox — see
  [File transfer](#file-transfer-bluescsi-toolbox)
- **CD-ROM drive** on SCSI ID 3 — data, mixed-mode and audio discs, including the
  AppleCD Audio Player. Needs a CD driver in the guest System — see
  [CD-ROM support](#cd-rom-support-scsi).
- **Color display** — 1/2/4/8/16bpp, 512×384 (12" RGB) or 640×480 (VGA)
- **Sound**, including CD audio
- **QuickTime video playback**
- **Memory:** 2 MB or 10 MB configurations
- **PRAM/NVRAM:** save (on entering the OSD), automatic load at core start (or forced load),
  and clear
- **SCC serial** is wired in and "usable" but not yet doing anything useful
- **Floppy disks (read-only):** 800 KB GCR and 1.44 MB MFM disks in raw or
  DiskCopy 4.2 format — booting, mounting, launching applications and copying
  files off a floppy all work. See [Floppy disk support](#floppy-disk-support)

### Not working yet

- **Floppy writes** (disks mount locked/write-protected)

## Usage

1. Copy the `*.rbf` to the root of your MiSTer SD card.
2. Place the 512 KB Mac LC ROM as `boot0.rom` in the `MACLC` folder.
3. Place a bootable SCSI hard-disk image (`.vhd` / `.img` / `.hda`) in the `MACLC` folder.
4. Optional: put files to share with the Mac in `games/MacLC/shared` — see
   [File transfer](#file-transfer-bluescsi-toolbox).

Open the on-screen display with **F12** to mount images and change options.

## ROM

The core requires the 512 KB Macintosh LC ROM (version `$67C`, checksum `$350EACF0`),
placed as `boot0.rom`. The ROM is loaded into SDRAM at core start; changing it requires
a reset/reload.

## SCSI bus layout

Three real targets sit on the emulated SCSI bus. The remaining OSD slots are
**not SCSI devices** — they are private channels the core uses to talk to MiSTer's
Main (file transfer, PRAM, CD swapping), and the guest never sees them:

| OSD slot | SCSI ID | Purpose |
|---|---|---|
| `Mount SCSI-0` | **0** | Primary hard disk (boot device) |
| `Mount SCSI-1` | **1** | Secondary hard disk |
| `Mount CD-ROM` | **3** | CD-ROM drive |
| `Mount PRAM` | — | PRAM/NVRAM save image (host channel) |
| *(no OSD entry)* | — | BlueSCSI Toolbox shared folder (host channel) |
| *(no OSD entry)* | — | BlueSCSI Toolbox CD changer control (host channel) |

The two host channels without an OSD entry are mounted automatically by an updated
Main_MiSTer (see [Updating Main_MiSTer](#updating-main_mister)); on an older Main they
stay unmounted and the features that use them degrade gracefully.

The Toolbox file-transfer commands are answered by the **SCSI ID 0** target and the
CD changer commands by the **ID 3** target — clients find them by INQUIRY, not by ID.

## Hard disk support (SCSI)

The on-screen display exposes two SCSI slots:

- **Mount SCSI-0** — primary drive (SCSI ID 0), the usual boot device
- **Mount SCSI-1** — secondary drive (SCSI ID 1)

> **The disk IDs are 0 and 1** (they were 6 and 5 in earlier builds). The boot SCSI ID
> is stored in PRAM, so an existing install blessed for ID 6 will not boot until you
> run **Reset PRAM & Core** — or re-bless the volume for its new ID.

Images use a raw SCSI format (same as the SCSI2SD project, documented
[here](http://www.codesrc.com/mediawiki/index.php?title=HFSFromScratch)) with a `.vhd`,
`.img`, or `.hda` extension. The SCSI disk is writable; data written from within the OS is
persisted to the image file.

Cold boots of System 6.0.8, 7.1, and 7.5.5 to the Finder desktop have been verified, and
SCSI writes were validated. A blank 20 MB image with a partition table and SCSI driver is 
included as `releases/empty_hdd.zip`; a matching image is also available from the
[MacPlus core releases](https://github.com/MiSTer-devel/MacPlus_MiSTer/tree/master/releases).
A tool to create hard-disk images (with driver and partition table) is available
[here](https://diskjockey.onegeekarmy.eu/).

Both drives can be mounted at once, with the CD-ROM alongside them — all three targets
active on the bus is the normal, tested configuration.

## CD-ROM support (SCSI)

The core emulates an Apple-compatible CD-ROM drive on **SCSI ID 3**:

- **Mount CD-ROM** — mounts a disc image (the disc auto-remounts at core start)
- **CD-ROM Drive** (Enabled/Disabled) — removes the drive from the SCSI bus entirely
  when disabled

**The guest System must have a CD driver installed** — the stock Apple *CD-ROM* extension
works: the drive presents an AppleCD-family identity (`CD-ROM CDU-8004`, the AppleCD 300
mechanism).

Image format support:

| Format | Status |
|---|---|
| `.iso` / `.toast` / `.bin` (2048-byte sectors) | stock MiSTer Main |
| `.cue`+`.bin` (2352-byte raw), `.chd` | needs an updated Main_MiSTer, see [Updating Main_MiSTer](#updating-main_mister) |

**CD audio is fully supported** (July 2026): audio and mixed-mode discs mount correctly
(pure-audio discs reject data reads like a real drive — the Audio CD Access extension
depends on that), and the **AppleCD Audio Player** works end to end: full track listing
with durations, play, pause/resume, next/previous track, stop, and fast-forward/rewind
scan with audio, and the player's **volume slider** scales the audio. CD audio requires
`.cue`+`.bin` or `.chd` images (and therefore the forked Main, below) — flat 2048-byte
images carry no audio tracks.

The drive also implements the **BlueSCSI CD changer** commands, so a guest-side changer
utility can list the discs in `games/MacLC/CD3` and swap between them without going
through the OSD.

CUE/BIN and CHD support needs the updated Main_MiSTer — see
[Updating Main_MiSTer](#updating-main_mister).

Ejecting from the Finder (drag to Trash) is honored; use the OSD to insert a
different disc.

## File transfer (BlueSCSI Toolbox)

Files move between the SD card and the running Mac using the **BlueSCSI Toolbox**
protocol — no floppies or network needed. The core answers the Toolbox vendor SCSI
commands and MiSTer's Main serves a folder on the SD card as shared storage.

1. Put files in `games/MacLC/shared` on the SD card (or set `SHARED_FOLDER=` in
   `MiSTer.ini` to point elsewhere).
2. Install the client, once: unzip
   [`releases/MiSTer_BlueSCSI_Toolbox_1.1.0b5.hda.zip`](releases/), put the `.hda`
   in your `MACLC` folder, and mount it with **Mount SCSI-1** (the secondary drive).
   It appears on the desktop — copy its contents to a folder on your boot volume,
   then unmount it; you won't need it again.
3. Run **BlueSCSI SD Transfer** from that folder. It lists the shared folder:
   **Download** copies a file to the Mac, and **File → Upload File** copies one
   back to the SD card.

Both directions are verified and perform at roughly 120 KB/s down and 170 KB/s up.

This requires the updated Main_MiSTer — see [Updating Main_MiSTer](#updating-main_mister).
Stock Main has no Toolbox handler; the core degrades gracefully without it, and Toolbox
commands simply report that no shared folder is available.

*BlueSCSI Toolbox files distributed with permission from Eric Helgeson (c) 2026*

## CD Swapping (BlueSCSI Toolbox)

To use CD Swapping via BlueSCSI toolbox, Create a folder in `/media/fat/games/MacLC` called `CD3` and place CD images into that folder.

The updated Main_MiSTer must be running.

Note- this has not been fully tested yet.


## Using custom MiSTer Binary for this core

Two features — **file transfer** and **CUE/BIN + CHD CD images** — need support in
MiSTer's main executable. The changes are **merged upstream**
([PR #1255](https://github.com/MiSTer-devel/Main_MiSTer/pull/1255)) but have not
appeared in a released MiSTer binary yet, so `update_all` / the standard updater will
not give you them. Until a release includes them, perform this task:

1. Back up the existing one: `cp /media/fat/MiSTer /media/fat/MiSTer.orig`
2. cp `/media/fat/games/MacLC/MiSTer /media/fat/MiSTer` and make it executable (`chmod +x /media/fat/MiSTer`).
3. Reboot the MiSTer.

Note that the normal MiSTer updater may overwrite this file with the current official
build, which silently removes both features — re-copy it after running an update, until
a release ships with the merged support. Once one does, the updater is all you need and
this step goes away.

## Floppy disk support

**Floppy reading works** — 800 KB GCR and 1.44 MB MFM 
Mount images through the OSD's **"Mount Pri Floppy"** slot. Disks are **read-only** for now:
they mount write-protected, exactly like a locked physical floppy.

Both common image formats are auto-detected — no conversion needed:

- **Raw** (`.dsk` / `.img`): 819,200 bytes for 800K, 1,474,560 for 1.44 MB,
  409,600 for 400K, 737,280 for 720K
- **DiskCopy 4.2** (`.dsk` / `.image` / `.dc42`): the 84-byte DC42 header is parsed and
  skipped automatically; the disk geometry comes from the header's format byte

720K images are for PC/FAT disks and need PC Exchange installed in the guest.

### Swapping floppies — works like a real Mac

**Media changes are fully reported to the Mac** (verified on hardware, August 2026):
the drive now presents both the "disk in place" transition and the SuperDrive's
"disk switched" flag exactly the way a real drive does, so a running Mac notices
ejects, inserts, and swaps on its own — no reset needed.

The natural flow is the real-Mac one:

- **Multi-disk installers just work.** The installer ejects the disk itself and asks
  for the next one; mount the requested image in the OSD and the installation
  continues. A complete **System 6.0.8 install from its two 1.44 MB floppies**
  (including the installer's back-and-forth disk swaps) has been run end to end this
  way on hardware.
- **In the Finder, eject first** — drag the floppy to the Trash (the Mac ejects it and
  the drive really empties), then mount the next image in the OSD. The new disk is
  picked up within a couple of seconds and mounts as itself.
- Mounting a *different* image over a still-mounted one (no eject) is the equivalent
  of yanking a disk out of a real drive mid-use: the Mac sees its volume vanish. It
  copes, but may complain — real Macs never experience this (their drives only eject
  under software control), so prefer the eject-first flow.

Mount floppies through **"Mount Pri Floppy"** — that is the internal SuperDrive, the
drive the Mac boots from and the only one that can read 1.44 MB MFM disks. The
Sec slot emulates a second, external 800K-class drive.

### Booting from a floppy

Booting from floppy works (verified on hardware, August 2026). Mount a bootable image
at the flashing-`?` screen and the ROM picks it up within a few seconds and boots from
it — this is also how to start a floppy-based OS installation onto a fresh hard-disk
image. Mounting before a reset ("Reset & Apply") works too.

## PRAM / NVRAM

The Mac LC's parameter RAM (PRAM) — which stores settings such as the monitor color depth and
the real-time clock — is backed by a persistent NVRAM image:

- **Save:** PRAM is written back when you open the OSD.
- **Load:** the PRAM image is loaded automatically when the core starts; you can also force a
  reload via the "Mount PRAM" slot in the OSD.
- **Clear:** "Reset PRAM & Core" clears PRAM and resets the machine (a fresh, default PRAM).

A default PRAM image is included as `releases/MacLC.nvr`.

## Memory

Two configurations are selectable in the OSD: **2 MB** (motherboard RAM only) or **10 MB**
(2 MB soldered + 8 MB SIMM), matching real LC configurations. Changing the memory setting
applies on reset ("Reset & Apply CPU+Memory"). A cold boot with 10 MB selected takes longer to
complete its RAM test before booting — be patient.

### Skipping the boot RAM test (optional)

The boot ROM runs a destructive RAM test (the "memory march") on cold boot, which is what makes
a 10 MB cold boot slow. You can optionally patch the ROM to skip this test and take the ROM's
fast warm-start path instead.

> Both the stock and the patched ROM have been verified booting System 7.5.5 to the desktop.
> The stock ROM remains the reference configuration — if you hit
> boot problems, retest with a stock, unpatched ROM before reporting.

A patcher is provided at
[`verilator/patch_skip_ramtest.py`](verilator/patch_skip_ramtest.py). It needs Python 3 and the
standard 512 KB Mac LC ROM (checksum `350EACF0`):

```bash
python3 verilator/patch_skip_ramtest.py boot0.rom boot0_skipramtest.rom
```

This applies a 2-byte patch at ROM offset `0x46558` (`cmpi.l #'WLSC',d3` → `bra.s $46570`) that
forces the warm-start path, and recomputes the header checksum so the ROM self-check still
passes. Back up your original ROM, then copy the patched file to your `MACLC` folder as
`boot0.rom`.

## Display

The core supports two monitors/resolutions, selectable in the OSD:

- **640×480 VGA** (supports 256-colors only)
- **512×384 12" RGB** (the LC's "Macintosh 12-inch RGB Display")

All the LC's colour depths render — 1, 2, 4, 8 and 16bpp* (only available on 512x384 resolution, due to VRAM limtations- . Aspect ratio and scaling
options are available in the OSD. The "Original" aspect ratio is true **4:3**
for both monitor modes (both LC screens are 4:3 — 640×480 and 512×384), so
integer scaling fits every common panel, including 1280×1024 (5:4) displays.

### Fixed-frequency displays (e.g. 1280×1024 / SXGA panels)

Some displays — particularly 5:4 1280×1024 panels — have been reported to
negotiate an output mode outside their supported range with certain build
combinations (an ~80 kHz / 75 Hz-class mode instead of 60 Hz). If your
display shows "out of range", no picture, or an unexpected refresh rate,
pin the output mode in the `[MacLC]` section of `MiSTer.ini`:

```ini
[MacLC]
video_mode=1280,48,112,248,1024,1,3,38,108000
vsync_adjust=0
```

That is the standard VESA 1280×1024@60 timing (63.98 kHz / 60.02 Hz), within
spec for any SXGA panel. For a 1080p display, use the standard CEA
1920×1080@60 line instead:

```ini
[MacLC]
video_mode=1920,88,44,148,1080,4,5,36,148500
vsync_adjust=0
```

For any other panel native, substitute its own mode line — the key is a
**fixed `video_mode` plus `vsync_adjust=0`**, which stops automatic mode
negotiation for this core only.

## Keyboard & mouse

Keyboard and mouse are delivered over a wire-level ADB device model. The **Alt** key maps to
the Mac's Command (⌘) key and the **Windows** key maps to Option (⌥). The numeric keypad is
emulated.

## Building from source

### FPGA (Quartus)

Built with **Intel Quartus 17.0.2 Lite**. Either open `MacLC.qpf` in the Quartus GUI and
compile, or use the scripted CLI flow (repeatable, headless-friendly):

```bash
bash scripts/setup_env.sh   # once: create scripts/local.env, set QUARTUS_BIN
bash scripts/build_only.sh  # full compile -> output_files/MacLC.rbf + STA verdict
```

See [BUILD.md](BUILD.md) for details. Deploy the resulting `.rbf` from `output_files/` to the
SD card.

### Simulation (Verilator)

A Verilator testbench is provided for development:

```bash
cd verilator
make
./obj_dir/Vemu --help
```

See [CLAUDE.md](CLAUDE.md) and the `docs/` directory for architecture notes and the
development workflow.

## AI Disclaimer
Please be aware this core was developed with heavy use of AI tooling, including Claude (Fable, Opus, Sonnet Models) and GPT (Codex), and does borrow for MAME. That said, a physical Macintosh LC computer was also used to assist with the development of this core.

## Known Inaccuracies
- VRAM is limited to 384KB which cannot exist on a physical Macintosh LC (only 256KB or 512KB sticks are available)
- TG68K CPU is not cycle accurate, however the CPU test suite included in this repository was used to verify CPU instruction accuracy on the physical hardware

## MAME Sourced Components
- SCSI subsystem
- EGRET (this core does uses the original EGRET firmware which is baked into core) this includes ADB connectivity
- Floppy (SWIM)
- CD-ROM & CD-ROM Audio
- V8 (video subsystem)
- ASC (sound subsystem)* Personally I could not notice sound differences between the mame core for the Macintosh LC sound system and my physical Macintosh LC

## Credits

- **MacPlus MiSTer** core by Sorgelig
- **Plus Too** by Steve Chamberlin (Big Mess o' Wires)
- **BlueSCSI Toolbox** protocol and client by [Eric Helgeson](https://github.com/erichelgeson)
- Mac LC port and ongoing development by [danifunker](https://github.com/danifunker) and [alanswx](https://github.com/alanswx)
