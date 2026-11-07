# [IBM PC/XT](https://en.wikipedia.org/wiki/IBM_Personal_Computer_XT) for [MiSTer FPGA](https://mister-devel.github.io/MkDocs_MiSTer/)

PCXT port for MiSTer by [@spark2k06](https://github.com/spark2k06/).

Discussion and development of the core take place in the
[MiSTerFPGA PCXT forum section](https://misterfpga.org/viewforum.php?f=40).

![Splash](splash.jpg)

## Description

The goal of this core is to provide a reliable IBM PC/XT-compatible machine for
MiSTer. It builds on the [MCL86 core](https://github.com/MicroCoreLabs/Projects/tree/master/MCL86)
from [@MicroCoreLabs](https://github.com/MicroCoreLabs/) and
[KFPC-XT](https://github.com/kitune-san/KFPC-XT) from
[@kitune-san](https://github.com/kitune-san).

The video path is a full EGA implementation. Earlier releases used the
[Graphics Gremlin](https://github.com/schlae/graphics-gremlin) CGA and Hercules
adapters from TubeTimeUS ([@schlae](https://github.com/schlae)); those have been
replaced, and CGA-compatible software now runs through the EGA path the way it
does on real EGA hardware. The EGA and VGA 13h+ behaviour is modelled on the
video emulation in [86Box](https://github.com/86box/86box).

[JTOPL](https://github.com/jotego/jtopl) by Jose Tejada
([@jotego](https://github.com/jotego)) provides AdLib sound.

Splash artwork by [@mills32](https://github.com/mills32).

For an architectural overview and possible future improvements, see the
[PCXT technical report](https://aitorgomez.net/pcxt-ega/core-report)
(source in [docs/report/](docs/report/CORE_REPORT.html)).

## Key features

* Selectable 8088 or 8086 bus mode, applied safely with Reset & apply settings
* CPU speed settings: 4.77 MHz, 7.16 MHz, 9.54 MHz and **Max**. Max is the
  unthrottled performance profile shared by 8088 and 8086; it is neither a
  historical CPU grade nor cycle-accurate.
* IBM PC/XT 5160 and compatible systems
* **EGA video**: sequencer, graphics controller, attribute controller and a four-plane VRAM, around the UM6845R CRTC
* Dual EGA dot clock, 14.318181 MHz and 16.257 MHz, selected per mode as on real hardware
* CGA-compatible text and graphics behaviour, provided by the EGA rather than a separate adapter
* **Direct 15 kHz CRT output**, with the 350-line modes convertible to 480i or 240p from the OSD
* **Optional VGA 13h+**: packed 320×200×256 mode 13h, selected unchained
  256-colour profiles (320×200, 360×200 and 320×240), and a bounded planar
  320×200×16 mode 0Dh profile, with a 256-entry DAC; off by default, enabled
  by `VGATSR.COM`, with its Native/TV output raster selected from the OSD
* 640 KiB conventional memory plus an optional 48 KiB UMB at C400h-CFFFh
* EGA BIOS option ROM support (required — the card is initialised by its own ROM, as on real hardware)
* Optional EMS memory up to 2 MiB, with a fixed D000h-DFFFh page frame
* XTIDE support
* Audio: AdLib, C/MS, Sound Blaster Pro (IRQ 5/7), Tandy 1000 (SN76489) and PC speaker
* Joystick support and serial mouse on COM1 (for example CTMOUSE 1.9, in `hdd/`)
* Second SD card support
* EGA graphical boot splash

## Memory map

The 8088 exposes a 1 MiB physical address space. The core divides it as shown
below; the ROM rows describe the normal configuration after their images have
been loaded.

| Address range | Size | Core assignment | DOS availability |
| --- | ---: | --- | --- |
| `00000h–9FFFFh` | 640 KiB | Conventional SDRAM | Conventional memory |
| `A0000h–AFFFFh` | 64 KiB | EGA aperture and VGA 13h+ framebuffer | Reserved for video |
| `B0000h–B7FFFh` | 32 KiB | Selectable EGA monochrome aperture | Reserved for video |
| `B8000h–BFFFFh` | 32 KiB | Selectable EGA colour/text aperture | Reserved for video |
| `C0000h–C3FFFh` | 16 KiB | EGA option ROM | Reserved for EGA BIOS |
| `C4000h–CFFFFh` | 48 KiB | Optional SDRAM-backed UMB | UMB when enabled in the OSD |
| `D0000h–D3FFFh` | 16 KiB | EMS page-frame bank 0 | EMS bank 0 when enabled and mapped; otherwise unmapped |
| `D4000h–D7FFFh` | 16 KiB | EMS page-frame bank 1 | EMS bank 1 when enabled and mapped; otherwise unmapped |
| `D8000h–DBFFFh` | 16 KiB | EMS page-frame bank 2 | EMS bank 2 when enabled and mapped; otherwise unmapped |
| `DC000h–DFFFFh` | 16 KiB | EMS page-frame bank 3 | EMS bank 3 when enabled and mapped; otherwise unmapped |
| `E0000h–EBFFFh` | 48 KiB | Directly decoded SDRAM | Not registered as UMB by the supplied DOS configuration |
| `EC0000h–EFFFFh` | 16 KiB | XTIDE option ROM | Reserved when an XTIDE ROM is loaded |
| `F0000h–FFFFFh` | 64 KiB | Main system BIOS | Reserved for system BIOS |

EGA's graphics-controller map can select `A0000h–BFFFFh`, `A0000h–AFFFFh`,
`B0000h–B7FFFh` or `B8000h–BFFFFh`; the entire A/B area is therefore reserved
for video regardless of the active EGA map. VGA 13h+ owns `A0000h–AFFFFh`
while active: packed mode 13h uses its private packed framebuffer, while its
supported unchained profiles use the existing four EGA planes.

The *Hardware → UMB C400-CFFF* OSD option controls only the 48 KiB C400h UMB
block. The supplied `hdd/CONFIG.SYS` registers `C400h–CFFFh` with
`USE!UMBS.SYS` and keeps `D000h–DFFFh` exclusively for EMS. Although the core
also decodes SDRAM at E000h–EBFFh, it is intentionally left outside the DOS UMB
chain: the two candidates are separated by the EMS frame, and treating
`C400h–EC00h` as one contiguous UMB would collide with EMS.

The *Hardware → 2MB EMS D000-DFFF* OSD option gates the EMS page frame as a
whole. When it is disabled, `D0000h–DFFFFh` is unmapped; when enabled, each of
its four 16 KiB banks responds only after its corresponding EMS page register
has been mapped.

## DOS environment (CONFIG.SYS / AUTOEXEC.BAT)

`hdd/` ships a working reference setup, matched to this core's fixed I/O
addresses and default OSD settings, so a DOS install built from scratch does
not have to guess at any of it. `hdd/CONFIG.SYS`:

```
FILES=40
BUFFERS = 30
DOS = HIGH, UMB
DEVICE=C:\UTIL\USE!UMBS.SYS C400-D000
DEVICE=C:\UTIL\DOSMAX\DOSMAX.EXE /R+ /N+ /P-
DEVICEHIGH=C:\UTIL\LTEMM.EXE /p:D000 /x /n
SHELL=C:\UTIL\DOSMAX\SHELLMAX.COM C:\COMMAND.COM C:\ /E:256 /P
```

* `USE!UMBS.SYS C400-D000` registers exactly the 48 KiB UMB block described
  above, stopping at the EMS page frame rather than reaching into it.
* `DOSMAX.EXE` (`hdd/DOSMAX/`) moves DOS's own FILES/BUFFERS/COMMAND.COM
  overhead into that UMB instead of conventional memory; `SHELLMAX.COM` on the
  `SHELL=` line is its companion for COMMAND.COM. See `hdd/DOSMAX/DOSMAX.DOC`
  for the switches.
* `LTEMM.EXE` (`hdd/LTEMM-r01/`) is the Lo-tech EMS 4.0 driver. `/p:D000`
  matches the OSD's fixed EMS page frame, and it needs no `/i:` switch because
  the core's EMS I/O port, `260h`, is already LTEMM's own default.

Nothing loads a mouse driver automatically — add an `AUTOEXEC.BAT` alongside
it for that, for example:

```
@ECHO OFF
SET PATH=C:\UTIL;%PATH%
SET BLASTER=A220 I5 D1 T4
SET SOUND=C:\SB
SET MIDI=SYNTH:1 MAP:E MODE:0
C:\UTIL\CTMOUSE\CTMOUSE.EXE
```

`BLASTER=A220 I5 D1 T4` describes the core's default Sound Blaster Pro setup:
base address `220h`, IRQ 5, DMA channel 1 and Creative card type 4. If the OSD
or `XTEGACTL sbirq=7` selects IRQ 7, change `I5` to `I7` for that program as
well. `SOUND` is only the installation directory expected by Creative's own
utilities, and `MIDI` is likewise a software convention; neither variable
enables hardware in the core.

`CTMOUSE.EXE` (CuteMouse 1.9, `hdd/CTMOUSE/`) checks PS/2 first, then every COM
port, and settles on Mouse Systems mode at the first COM port if nothing
answers — so a serial mouse on COM1 is picked up with no switches at all. See
`hdd/CTMOUSE/CTMOUSE.TXT` for forcing a specific port, IRQ or three-button
mode.

The repository keeps both examples as [`hdd/CONFIG.SYS`](hdd/CONFIG.SYS) and
[`hdd/AUTOEXEC.BAT`](hdd/AUTOEXEC.BAT). See
[`docs/dos-configuration.md`](docs/dos-configuration.md) for the matching OSD
settings, the exact UMB/EMS windows and per-game Sound Blaster examples.

## Video

EGA is the active video hardware model, and it is what the machine reports to
software. Standalone CGA, Hercules and Tandy video are no longer selectable
paths: CGA-compatible programs work because the EGA implements the
CGA-compatible modes, which is how a real EGA card behaved.

The dot clock follows Miscellaneous Output bit 2, so 200-line CGA-compatible
modes run at 14.318181 MHz and the 350-line and MDA-compatible modes at
16.257 MHz, rather than one fixed rate for everything.

The *Hardware → Monitor* option models the four monitor switches on the IBM
EGA card. `IBM 5154/ECD` is the default full EGA configuration;
`IBM 5153/CGA` internally selects the card's 80-column CGA switch pattern and
makes the IBM EGA BIOS use its
200-line, 8×8 text tables; and `IBM 5151/MDA` selects the 720×350, 80×25
monochrome mode 7 configuration. The 5151 profile interprets the EGA connector's
Mono Video and Intensity pins as normal and bright white, so *Full Color* is
neutral and the separate *Display* option can tint it green, amber, or otherwise.
The same connector path supports EGA BIOS mode `0Fh`, 640×350 monochrome
graphics, in addition to mode 7 text.
Monitor changes remain pending until *Reset & apply settings*, as on the
physical card the switches were read during POST. The graphical boot splash
always uses the 5154/ECD colour profile; the selected monitor takes effect when
the BIOS starts after it.

### CRT output

The core drives a 15 kHz CRT directly, with no scaler in between. The 200-line
EGA and CGA-compatible modes reach the display at 15.7 kHz, the way the
original hardware drove one. VGA 13h+ with its `60Hz` setting is retimed onto
that same raster; its `Native` setting uses the standard 31.5 kHz / 70 Hz
VGA timing.

The `CRT 25%` and `CRT 50%` visual effects darken alternate scanlines. They
do not change the output timing or frequency. See [31 kHz monitors](#31-khz-monitors)
for output suitable for a 31 kHz display.

*Audio & Video → CRT H offset* and *CRT V offset* centre the picture. One pair
of values covers every mode that reaches a television. HDMI is unaffected by
any of this.

The 350-line EGA modes and MDA scan at about 21.8 and 18.4 kHz, which no 15 kHz
set will lock to. *Audio & Video → 350-line CRT* converts them:

* `Native` — the raster the card programs, unconverted. Default, and what an
  enhanced display, a 5151 or the scaler wants.
* `480i 15 kHz` — a standard interlaced television frame. All 350 lines are
  shown, half of them in each field.
* `240p 15 kHz` — a progressive 262-line frame. Steady, with no interlace
  flicker, but 350 lines are fitted into 224 and the rest are dropped.

The conversion captures a whole frame into the board's DDR3 and rebuilds the
raster from it, publishing only complete frames so a mode change landing
mid-picture cannot put half of one frame and half of another on screen. Nothing
is fed back to the emulated hardware: the CRTC, the display enable and the
retrace bits software polls behave identically whichever setting is chosen.

The CRT offsets deliberately do not move the `Native` 350-line picture. Those
modes do not go to a television, and they sit where the card's own registers
put them.

### 31 kHz monitors

There is no native 31 kHz output for EGA, CGA or MDA modes. Their 200-line
rasters are 15 kHz and the 350-line/MDA modes left on `Native` run at 18.4 to
21.8 kHz on the 16.257 MHz dot clock, below what a VGA monitor will accept.
The exception is VGA 13h+ in its `Native` profile, which uses a conventional
31.5 kHz / 70 Hz VGA raster. A multisync CRT or a flat panel on the analogue
port is otherwise served by the scaler. This core-specific section in
`MiSTer.ini` is a practical starting point:

```ini
[PCXT-EGA]
vga_scaler=1
video_mode=6
vsync_adjust=2
```

The section name is the core name embedded in the RBF, so these settings apply
only to PCXT-EGA and do not change other cores. `vga_scaler=1` routes the
scaler to the analogue output, meaning the core's own 15 kHz rasters are not
used there. `video_mode=6` is MiSTer's built-in 640×480, 25.175 MHz preset
(31.47 kHz), so no modeline is required. `vsync_adjust=2` follows the core's
real 59.917 Hz instead of forcing 60 Hz, avoiding a repeated frame roughly
every twelve seconds and reducing scaler latency. That refresh is
non-standard: a CRT will normally accept it, but a flat panel may not, so use
`vsync_adjust=1` if the display rejects the signal.

Leave *350-line CRT* on `Native` here. The 480i and 240p conversions exist to
reach a television and have nothing to offer a monitor that can already show
350 lines progressively.

### VGA 13h+

The optional VGA 13h+ path is a deliberately bounded VGA extension. It adds a
256-entry DAC on ports `3C7h`–`3C9h`, the original packed
320×200×256 mode 13h at `A000h`, selected unchained four-plane profiles and a
fixed VGA planar 16-colour profile:

| Profile | Layout | Supported output sizes |
| --- | --- | --- |
| VGA mode 0Dh | Four one-bit colour planes | 320×200×16 |
| Mode 13h | Packed 320×200×256 | 320×200 |
| Unchained 320×200 | Four pixels per byte across four planes | 320×200 |
| Unchained 360×200 | Four pixels per byte across four planes | 360×200 |
| Unchained 320×240 | Four pixels per byte across four planes | 320×240 |

The extension starts disabled, exactly as on an IBM EGA, and `VGATSR.COM`
enables it through XTEGACTL. `VGA 13h+ CRT` then selects its output raster:
`Native` uses the standard 800-clock, 31.5 kHz / 70 Hz VGA timing, while `60Hz`
keeps a 15.70 kHz / 59.9 Hz television-compatible raster. The 360×200 Native
profile retains a 912-clock line for its wider picture, and 320×240 borrows
vertical blanking.

An IBM-compatible warm boot clears the VGA 13h+ XTEGACTL field when the BIOS
writes its standard `1234h` marker to `0040:0072`, so the private VGA raster
releases the connector and the original EGA text mode is visible again.
`VGATSR.COM` must be run again before another VGA session.

While the extension is active, the DAC feeds **every** video mode, not only VGA
13h+. This
matters for software that detects a VGA, switches to a 16-colour mode for
gameplay and then sets its colours through the DAC: Titus the Fox and
Prehistorik 2 both do this, and without it they render in the stock EGA palette.
Entries the program never wrote fall back to the EGA palette, so nothing changes
for software that does not touch the DAC.

`hdd/VGATSR.COM` is the packaged BIOS-side companion; its source is
`SW/vga/vgatsr.asm`. The EGA option ROM has no DAC
subfunctions — `INT 10h AH=10h` with `AL=10h/12h/15h/17h` are VGA additions and
an EGA BIOS drops them silently — so the TSR hooks `INT 10h` and serves them,
along with the queries a game uses to detect a VGA in the first place. It
refuses to install if the core does not expose the required XTEGACTL interface,
so an older incompatible RBF is not falsely advertised as VGA-capable.

For VGA mode 0Dh, VGATSR first lets the existing EGA BIOS establish the normal
planar registers and BIOS state, then switches only the display fetch to the
fixed VGA raster. That renderer honours CRTC Start Address, Offset 20–23
(40–46 bytes per plane row) and horizontal pel panning, covering common
320×200 hardware scrolling without replacing the EGA implementation or adding
a programmable VGA CRTC. See
[the planar mode 0Dh scope](docs/vga-planar16-mode0d.md).

When it sets mode 13h, VGATSR also installs the IBM VGA CRTC baseline that
unchained software normally modifies. Within the profiles listed above, the
renderer honours CRTC Offset values 40–45 (80–90 bytes per plane row), CRTC
Start Address, Attribute Controller horizontal pel panning, one CRTC Line
Compare split with pel-panning suppression, and Maximum Scan Line values 0–7.
That covers hardware scrolling, page flipping, a virtual 336-pixel-wide map
and the simple status/window split used by software such as Cute Demo. CRTC
registers 00h–09h are readable as on VGA, so the read/modify/write updates of
R07 and R09 used by that software preserve the vertical timing and scanline
repeat bits. On exit, VGATSR restores the pre-VGA CRTC/attribute state before
chaining the requested EGA BIOS mode.

The core still recognises only the listed timing signatures after Chain-4 is
disabled; it is not a generic Mode X or full VGA CRTC implementation. Other
unchained resolutions, arbitrary timing generation, multiple splits, vertical
panning, VGA text/high-resolution modes and cycle-exact raster effects remain
outside this feature.

#### Should it stay off for EGA-only sessions?

For everyday use, loading the TSR doesn't break anything: the DAC only overrides
a palette entry that software has actually written, so an EGA game that never
touches `3C7h`–`3C9h` renders identically either way, and `VGATSR.COM` chains
every unrecognised `INT 10h` call straight through to the real BIOS.

But explicit activation exists for a reason, and not loading the TSR is the
right call when you want the machine to behave and be detected as a real EGA
with no VGA trace at all — this is why the ports are gated on the XTEGACTL
state rather than left decoding permanently:

* **Port-level fingerprint.** With the extension active, ports `3C7h`–`3C9h` answer as
  a DAC even if no software ever calls the BIOS for one — a real IBM EGA
  doesn't decode those ports at all, its palette lives in the attribute
  controller. Software that fingerprints hardware by probing I/O ports
  directly, rather than going through `INT 10h`, can see that and conclude a
  VGA is present. Not loading the TSR leaves those ports closed so the card
  answers exactly as an EGA should, to a port probe as much as to a BIOS call.
* **BIOS-level fidelity.** With `VGATSR.COM` resident, `INT 10h AH=12h/BL=10h`
  ("Return EGA information") — a standard EGA call, not a VGA-only one — is
  answered by the TSR with a fixed value instead of being chained to your
  loaded EGA BIOS ROM. Not loading the TSR means every EGA BIOS call gets
  exactly what that ROM would answer, with nothing intercepted.

So: fine to load VGATSR for normal play, but omit it when you specifically want
authentic, untraceable EGA behaviour — testing against real hardware, for
example, or running EGA-only software with nothing else in the picture.

## Current configuration

* System/ROM set to PC/XT
* EGA video active at boot
* CGA-compatible text and graphics behaviour through EGA
* Optional VGA 13h+, enabled by `VGATSR.COM`; Native/TV timing selected in the OSD
* OPL2 enabled for common DOS FM audio
* CMS enabled
* EMS enabled for expanded memory

## Quick Start

* Build the EGA BIOS with `SW/ROMs/EGA/make_ega_bios_rom.py` and copy the
  resulting `ega_bios.rom` to the SD card. **The core cannot show a usable
  picture without it** — see [EGA BIOS — required](#ega-bios--required).
* Copy the contents of `games/PCXT` to your MiSTer SD card and extract `hd_image.zip`. It contains a [FreeDOS](https://www.freedos.org/) image.
* Select the core from Computers/PCXT.
* Press Win + F12 on your keyboard.
  * Model: IBM PCXT.
  * CPU Speed: pick a speed.
  * System & BIOS → CPU Type: choose 8088 (compatible default) or 8086.
  * FDD & HDD → HDD Image: FreeDOS_HD.img
  * System & BIOS → PCXT BIOS: choose a compatible system BIOS, such as `bios-micro8088-xtide.rom` from `SW/8088_bios/binaries/`.
  * System & BIOS → EGA BIOS: `ega_bios.rom`. **Required.**
* Choose Reset & apply settings.

The 8086 mode uses a six-byte prefetch queue and transfers aligned SDRAM words
over its private 16-bit path. Odd words and the XT-class video and peripheral
buses remain split into byte cycles. The fixed 4.77/7.16/9.54 MHz settings keep
their cycle-accurate timing floor while the shared EU and selected BIU account
for each transfer; Max bypasses the nominal timing counter and exposes the
full bus benefit. The default 8088 keeps its four-byte queue and byte-wide
memory transfers in every profile.

### The F12 keys

* **Win + F12** opens the OSD. F12 on its own is the machine's, not the
  framework's, exactly as the splash says: it pauses and shows the credits.
  Once the OSD is open, F12 or Esc closes it again.
* **F12 during the boot splash** does the same thing: the credits come up and
  the machine is held, except that here it was already held and what stops is
  the splash's own countdown. Press it again to return to the splash and let
  it run out. That is the moment to reach the OSD with Win + F12 and pick a
  disk image or a video mode before DOS starts. Setting **Boot Splash Screen**
  to *No* still dismisses it, so a held splash is never a dead end.

## Known limitations

None specific to CPU speed remain. Two issues that used to affect the
**Max** setting are fixed in the current RTL:

* The former intermittent memory fault: an accepted RAM write is now retained
  until it reaches SDRAM even when its short CPU-side `MEMW` pulse overlaps a
  refresh. The refresh-collision regression passes at addresses across
  conventional memory, and Supersoft `SLOW REFRESH` has been confirmed
  error-free on MiSTer hardware.
* The intermittent IBM 5160 BIOS `101` at that speed: the 8088 core now
  samples `INTR` at instruction boundaries instead of asynchronously
  mid-instruction, closing a hot-interrupt race in the POST's PIC/PIT check.
  Hardware testing confirms the POST now completes without `101` at Max.

Video is not affected by either fix. I/O writes to the video ports cross into
the video clock domain as posted writes with a guaranteed pulse width, so they
are independent of how short the CPU's bus cycle gets, and display behaviour
is the same at all four speeds.

An older prebuilt RBF will not contain these source changes.

## XTEGACTL — per-program hardware control

`XTEGACTL.COM` sets the machine up from DOS the way a program wants it, so a
batch file can do what you would otherwise do by hand in the OSD:

```
XTEGACTL 4.77 adlib joy1=digital
GAME.EXE
XTEGACTL reset
```

It can set the CPU speed, Fake 286 FLAGS, the OPL2 address (or turn it off),
C/MS, Sound Blaster and its IRQ (5 or 7), EMS, UMB, Tandy sound, CRT position
and sync widths, the MPU-401, both joysticks (analog,
digital or disabled), the joystick swap and CPU-speed sync, and the MT32-pi
mode. Taking a device off the bus matters more than it sounds: a game that
probes `0C0h` and finds a Tandy, or `330h` and finds an MPU-401, may switch to
that device's music driver instead of the one you actually wanted — `notandy`
and `nompu` take them away for that program without disturbing anything else.
Anything you do not
name is left to the OSD, and settings are not cumulative — each run rewrites
them all, so nothing leaks from one program into the next. `XTEGACTL reset`
hands everything back to the menu.

`XTEGACTL status` now prints the effective value of every runtime setting. A
value is followed by `(OSD)` when it matches the live menu setting, so a
launcher can inspect the machine without opening the OSD. VGA 13h+ remains an
actual `on`/`off` report because its enable state belongs to `VGATSR.COM`.

Everything it can change applies immediately; nothing in it needs a machine
reset. Options the core only samples during reset — CPU Type, Monitor and
2nd SD card — are deliberately not included, because a program would have to
reboot the machine to make them take. Those stay in the OSD, which now tells
you when one of them is waiting on a reset.

It replaces `XTCTL.EXE`, which is retired on this core along with its `8888h`
port. Three of XTCTL's options had become silent no-ops here, and its speed
names never matched the speeds they picked. See
[`docs/xtegactl.md`](docs/xtegactl.md) for the register map and the reasoning,
and [`SW/XTEGACTL/README.txt`](SW/XTEGACTL/README.txt) for the full option
list.

## Sound Blaster Pro

The optional Sound Blaster Pro is mapped at `220h`, uses DMA channel 1, and
raises its interrupt on IRQ5 by default. *Hardware → Sound Blaster IRQ* in the
OSD selects IRQ5 or IRQ7. A launcher can make the same per-program choice with
`XTEGACTL sbirq=5` or `XTEGACTL sbirq=7`; omitting that option follows the OSD.
The card and C/MS remain mutually exclusive at `220h` when both are built.

DOS games normally discover that fixed setup through the environment:

```bat
SET BLASTER=A220 I5 D1 T4
SET SOUND=C:\SB
SET MIDI=SYNTH:1 MAP:E MODE:0
```

The `I` value must follow the effective OSD/XTEGACTL IRQ. `SOUND` and `MIDI`
are optional conventions used by Creative software; adjust the `SOUND` path to
the directory where those utilities or drivers are actually installed. See
the complete [`AUTOEXEC.BAT` example](hdd/AUTOEXEC.BAT).

## Tandy 1000 sound

An SN76489 at `0C0h`-`0CFh`, brought over from the parent PCXT core. It is the
audio part only: this fork has no Tandy video and no Tandy keyboard, so a
program that expects a whole Tandy 1000 will not find one — but the many DOS
games that simply write to the sound chip when they detect it will play through
it.

Include or omit it at build time from `config.tcl`:

```tcl
set_global_assignment -name VERILOG_MACRO "ENABLE_TANDY_AUDIO=1"
```

Its level follows the **Speaker Volume** setting rather than having a separate
volume control. **Audio & Video → Tandy Sound** is disabled by default and can be
overridden per program with `XTEGACTL tandy` or `XTEGACTL notandy`.

## RTC/CMOS port

The previous CGA/Hercules-based core exposed its RTC/CMOS device at
`2C0h`-`2C1h`. The EGA core mirrors `3C0h`-`3CFh` at `2C0h`-`2CFh`, so an
index write there also lands on the attribute controller and blanks the
display until the next mode change. The RTC/CMOS is now decoded at
`340h`-`341h` instead. Tools that read it directly — `GET_RTC.EXE` and the
`x86_launcher` AppId handled by `LAUNCHER.EXE` — need to be pointed at the
new port.

## ROM Instructions

ROMs are loaded from the **System & BIOS** section of the OSD. It provides slots
for the main system BIOS, an optional XTIDE ROM at `EC00h`, and the EGA BIOS,
which is required — see [EGA BIOS — required](#ega-bios--required) below.
Once loaded, a ROM remains available on subsequent boots until it is replaced.
Original and copyrighted system ROMs can be prepared with the Python scripts in
`SW/ROMs/`:

* `SW/ROMs/make_rom_with_ibm5160.py`: creates `pcxt.rom` from the original IBM 5160 ROM. It requires an XTIDE BIOS at `EC00h` to use hard-disk images.
* `SW/ROMs/make_rom_with_jukost.py`: creates `pcxt.rom` from the Juko ST ROM with the XTIDE BIOS embedded at `F000h`.

The same OSD section accepts an XTIDE ROM of up to 16 KiB at `EC00h`; one is
included in this repository.

Other Open Source ROMs are available in the same folder:

* `pcxt_pcxt31.rom`: includes the XTIDE BIOS at `F000h`. ([source code](https://github.com/virtualxt/pcxtbios))
* `bios-micro8088-xtide.rom`: Micro8088 BIOS with XTIDE support, built from the [8088 BIOS source code](https://github.com/skiselev/8088_bios).
* `ide_xtl.rom`: XTIDE BIOS used by some scripts and upgradeable from its [upstream project](https://www.xtideuniversalbios.org/).

### EGA BIOS — required

An **EGA BIOS** option ROM is loaded from the same section, and the core needs
it to produce a picture. It is not optional, and it is not only for software
that checks the equipment word.

On a real machine the video card's own option ROM is what programs the CRTC,
the sequencer and the attribute controller during POST. Nothing else does it.
With no EGA BIOS loaded those registers are never initialised, and the picture
has nowhere to go.

The core no longer lets that happen. If either the PCXT BIOS or the EGA BIOS is
missing, it stops at the boot splash instead of starting the machine, and says
which one it wants — see [If the core stops at the splash](#if-the-core-stops-at-the-splash).

Loading it also makes the machine report EGA in the equipment word, so software
that trusts the equipment word instead of probing takes the EGA path.

The original IBM EGA card BIOS (part number 6277356) is copyrighted and not
included in this repository. `SW/ROMs/EGA/make_ega_bios_rom.py` builds it from
the raw dump published at
[minuszerodegrees.net](https://minuszerodegrees.net/rom/rom.htm) (IBM, EGA,
U44, 27128), producing `ega_bios.rom`. That dump is stored byte-reversed — the
ROM socket on the card is wired with inverted address lines, so the raw EPROM
read doesn't match the order the CPU sees — and the script reverses it back
before writing the file.

### If the core stops at the splash

The splash staying on screen with a notice over it means a required ROM has not
been selected. The notice names which one, and repeats until it is:

* `No PCXT BIOS selected` — **System & BIOS → PCXT BIOS**
* `No EGA BIOS selected` — **System & BIOS → EGA BIOS**

The machine is held in reset for as long as that is true, and the splash is put
back up for it even if **Boot Splash Screen** is set to *No*. Both are
deliberate. An 8088 released with nothing at `F000h` executes whatever the
memory happens to hold and eventually reprograms the CRTC, at which point a
15 kHz television loses lock and takes the OSD with it — the "splash, then black
screen" that made the core impossible to configure without an HDMI display.
Holding it keeps the picture on the power-on 640×200, which any set that could
show the splash can show, so the OSD stays readable and the missing file can be
picked from the television itself.

Selecting the file releases the machine immediately; no reset is needed. The
same hold applies if a BIOS is replaced while the machine is running, which
restarts it rather than pulling `F000h` out from under DOS.

## Other BIOSes

* https://github.com/640-KB/GLaBIOS

## Mounting the FDD image

The floppy disk image size must be compatible with the BIOS, for example:

* On IBM 5160 only 360 KiB images work well.
* On Micro8088 only 720 KiB and 1.44 MiB images work properly.
* Other BIOS may not be compatible, such as OpenXT by Ja'akov Miles and Jon Petroski.

It is possible to use images smaller than the size supported by the BIOS, but
only pre-formatted images, as it will not be possible to format them from MS-DOS.

## Repository layout

* `rtl/video/` — the EGA core, the VGA 13h+ blocks and their testbenches
* `rtl/KFPC-XT/` — chipset, peripherals, RAM and the SDRAM controller
* `SW/vga/` — `vgatsr.asm`, source for the VGA 13h+ TSR packaged as `hdd/VGATSR.COM`
* `SW/XTEGACTL/` — the per-program hardware control tool
* `SW/ROMs/` — scripts for preparing system ROMs
* `SW/8088_bios/` — Micro8088 BIOS sources and binaries
* `docs/` — DOS configuration, implementation notes and the XTEGACTL reference
* `docs/report/` — source for the [technical report](https://aitorgomez.net/pcxt-ega/core-report)

## Developers

Please send contributions and pull requests to the prerelease branch. They are
reviewed periodically and merged into the main branch as part of releases.

Thank you!
