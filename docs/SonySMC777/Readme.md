# Sony SMC-777 for MiSTer

The Sony SMC-777 (1983): Z80A at 4.028 MHz, 64 KiB RAM, 16 KiB IPL ROM, HD46505 CRTC with 80/40-column text and a
programmable font (PCG), 640x200 4-colour / 320x200 16-colour graphics, the colour palette board (SMC-777C), kanji
ROM, SN76489AN + beeper, MB8877A floppy controller with 3.5" drives, cassette, joysticks and mouse.

## Installation

Copy `SonySMC777_YYYYMMDD.rbf` to `_Computer/` on the SD card.

The core needs `games/SonySMC777/boot.rom`: the IPL ROM (`SMCROM.DAT`, 16 KiB) followed by the kanji ROM
(`KANJIROM.DAT`, 144 KiB), as used by the WinSMC and Common Source Code Project emulators:

```
cat SMCROM.DAT KANJIROM.DAT > boot.rom
```

Without the kanji part, everything but kanji text works. A ROM can also be loaded from the OSD (Load ROM).

## Disks

D88 images on drives A and B. The SMC-777 disk images found as `.1dd` are D88 files and mount as they are; 40-track
2D images are read in the 80-track drive as on the real machine. Mount a disk on drive A and choose Apply and reset,
or use an MGL. Writes go back to the image on the SD card.

System 1.1J is Sony's disk system (menu and BASIC); most games boot directly from their own disk. Sony's CP/M 2.2
for the SMC-70 also runs.

## Cassette

Mount a WAV on the Tape slot (PCM, 8- or 16-bit, mono or stereo, 4-192 kHz). Boot System 1.1J, start BASIC and type
`CLOAD "NAME"`, or `CLOAD ""` for the next file (a bare `CLOAD` is a syntax error). The tape plays while BASIC has
the motor on, like a recorder with remote control. Each mount starts rewound; Rewind tape (Machine) goes back to the
start.

Tape speed 8x (the default) loads eight times faster: the CPU and the tape both run faster while the motor is on, so
BASIC sees the same timing. A status bar at the bottom left shows the tape position while it plays (Video: Tape
overlay). Without a tape image, the cassette input is the MiSTer line-in.

## OSD

- Top: Pri. Drive A, Drive B, Tape, Load ROM; Machine, Video, Input, Audio; Apply and reset (cold reset).
- Machine: Tape speed (8x, Normal), Rewind tape, RESET key (the SMC-777's warm reset: memory is kept).
- Video: Aspect ratio, Scandoubler Fx, Border (the border colour around the picture), Tape overlay, Interlace text.
  Aspect ratio, Scandoubler Fx and Border take effect at Apply and reset ("Changes pending" shows until then).
- Input: Port 2 = Joystick or Mouse.
- Audio: Tape audio (hear the tape while it loads).

Interlace text: the SMC-70 CP/M's SETUP offers a "525 I" interlaced screen mode, for SMC-70 hardware. SMC-777 (the
default) shows it as a real SMC-777 most likely does, with every other font line doubled; SMC-70 shows the whole
font, as the SMC-70 would.

## Keyboard

The SMC-777 keyboard is ASCII-layout, so a US PC keyboard maps by position.

| SMC-777 | PC |
|---|---|
| Function keys 1-5 | F1-F5 |
| RUB OUT | F6, F10 or the JP yen key |
| HOME | F11 |
| LF | F12 |
| CLR | End |
| Kana | JP kana key, or Right Alt tapped on its own |

## Joysticks and mouse

Joystick port 1 has four directions and one trigger (Trigger 1); port 2 has two triggers. In Choplifter, tap the
trigger to fire, hold it and push left or right to turn the helicopter, or hold it and push down to face the front.

With Input: Port 2 = Mouse, the MiSTer's mouse is the SMC-777 mouse on joystick port 2 (SMC Paint).

## Known issues

- System 1.1J BASIC answers "Drive not available" for drive B (`"B:NAME"`); CP/M uses drive B.
- Not modelled: printer, RS-232, the expansion bus, the SMC-70's extra hardware (clock, 640x400 graphics).

## Credits

- T80 CPU: Daniel Wallner, MikeJ, Sorgelig and others.
- HD46505 (mc6845): Mike Stirling, David Banks (hoglet).
- WD1793 floppy controller: Viacheslav Slavinsky, Sorgelig.
- SN76496: MiSTer-X.
- RAM modules: Jim Gregory (JimmyStones).
- SMC-777 core: JasonA-dev, Alan Steremberg.
