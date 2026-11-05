# NeXT_MiSTer

NeXT core for MiSTer: a NeXTcube 68040 in FPGA.

Based on the [Previous](https://github.com/probonopd/previous) emulator
as the hardware reference (submodule at `reference/previous`), the
[AP68040](https://github.com/apolkosnik/AP68040) MC68040-compatible CPU
core (submodule at `rtl/AP68040`), and the
[MiSTer core template](https://github.com/MiSTer-devel/Template_MiSTer).

Status: working.  The real Rev 2.5 v66 boot ROM executes on the
real CPU core through the NeXT memory map, system registers, RTC/NVRAM,
interrupt controller, hardclock, and the 1120x832 monochrome video
pipeline, and passes the complete power-on system test.  Keyboard input, mouse,
and a peripherials (image mounted from the OSD "SCSI Disk" slot) are
wired. Boots NeXTSTEP 3.3 disk from Previous emulator.  See [docs/PORTING.md](docs/PORTING.md) for the module map
and roadmap. 

## Building

```
git clone --recurse-submodules <this repo>
cd before
quartus_sh --flow compile NeXT     # Quartus 17.0.x, DE10-Nano / MiSTer
```

Output: `output_files/NeXT.rbf`.

## Keyboard

The keyboard follows Previous's default non-ADB scancode mapping, with one
intentional exception: **Delete is not a power button**.

| PC key | NeXT function |
| --- | --- |
| F10 | Power request (press/release on the separate `INT_POWER` interrupt) |
| Delete | Unassigned |
| Backspace | Delete |
| Windows / GUI | Command (left/right) |
| Alt | Alt (left/right) |
| Caps Lock | Shift lock |
| F1 / Page Down, F2 / Page Up | Brightness down, up |
| F5 / End, F6 / Home | Volume down, up |
| ISO extra backslash | Backslash |
| Keypad = | Keypad equals |

Both Control keys share the NeXT Control modifier; releasing one does not
clear it while the other remains held. Caps Lock immediately updates the
guest modifier state. F10 requests guest shutdown, not physical MiSTer
power-off. The core recognizes keypad `=` at PS/2 set-2 `0x0F`, but
MiSTer Main leaves USB `KEY_KPEQUAL` unmapped; no Main change is included.

## Boot device

The ROM picks its boot device from the battery-backed NVRAM boot command.
The OSD "Boot device" setting is evaluated and applied on a user reset, so
mount images before resetting the machine. Auto selects the first mounted
SCSI hard disk on target 0, 1, or 2; if none is mounted it selects a valid
floppy, and otherwise leaves the boot command empty for the ROM's default
order. The explicit choices are Disk (`sd`), Floppy (`fd`), Network (`en`),
ROM Default (empty command), Optical (`od`), and CD-ROM probe (a qualified
SCSI target command).

The v66 ROM does not complete a direct boot from CD-ROM. To install from CD,
select Floppy and boot the installer floppy; the CD is then used as the root
media. CD-ROM probe only makes the ROM probe the selected CD target. A guest
CPU `RESET` instruction resets devices but preserves the NVRAM boot command;
use a user reset to apply a changed OSD selection.

## Network

The OSD "Network" option bridges the machine's onboard ethernet to a
host interface (eth0 shared with MiSTer, eth1, a macvlan child, or
tap0), using the DDR3 mailbox architecture of the Minimig A2065
support.  It needs the matching Main_MiSTer build from the
`next-ethernet` branch (releases/MiSTer_20260828 there); with stock
Main the machine sees an empty network.

## Audio recording

Select **Audio input → ADC** in the OSD to record from ADC-IN (built into
Digital IO, or supplied by the separate input adapter). The default
**Silence** option allows recording without an external audio source.
Recording uses the NeXT mono codec at 8,012 Hz. See
[audio input](docs/AUDIO_INPUT.md) for the DMA fix and validation.
Playback supports normal 44.1 kHz stereo and the NeXT's 22.05 kHz repeat
and zero-fill modes, guest volume controls, and de-emphasis. See
[audio fixes](docs/AUDIO_FIXES.md) for the audit results and tests.

## Boot ROM

Copy `reference/previous/src/Rev_2.5_v66.BIN` to the MiSTer as
`boot1.rom` next to the core (or load it from the OSD, Boot ROM slot).
The machine is held in reset until a ROM is loaded.

## Tests

```
cd tb && ./run_tests.sh            # needs verilator 5.x and python3
cd tb && ./run_tests.sh post       # additionally runs the full
                                   # power-on system test (about 5 min)
```

Runs the real RTL only - the real AP68040 submodule sources, the real
next_* modules, and the real boot ROM image from the Previous
submodule.  The `post` mode boots the ROM through its complete
power-on system test to the "System test passed" path.  See the test
list in docs/PORTING.md.
