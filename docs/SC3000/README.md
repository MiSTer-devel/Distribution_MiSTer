# Sega SC-3000 / SG-1000 for MiSTer

The Sega SC-3000 home computer (1983) and the SG-1000 console it grew out
of. The core also has the SF-7000 disk unit and Tsukuda Original's Othello
Multivision, an SG-1000 clone with Othello built in.

It runs:

- SG-1000 and SC-3000 cartridges
- BASIC Level II and Level III
- cassette tapes
- SF-7000 disks

## Getting started

1. Copy the newest `releases/SC3000_YYYYMMDD.rbf` to `_Computer/` on your SD
   card.
2. Put your cartridges, tapes and disks in `games/SC3000/`.
3. Start the core and load a cartridge from **Cartridge** in the menu (F12).

The SC-3000 has no built-in ROM, and neither has the SG-1000. Everything
starts from a cartridge, BASIC included, so the screen stays black until
you load one.

### Optional ROMs

Plain SC-3000 and SG-1000 use needs no extra files. Two features need a ROM
from MAME, placed in `games/SC3000/`:

| File | Needed for | MAME file |
|---|---|---|
| `boot0.rom` | SF-7000 disk unit | `sf7000.zip`: `ipl.rom` (8 KB, CRC32 d76810b8) |
| `boot1.rom` | Othello Multivision | `omv2000.zip`: `omvbios.bin` (16 KB, CRC32 c5a67b95) |

### File types

| Type | Extensions |
|---|---|
| Cartridges | `.sg`, `.sc`, `.bin`, `.rom`, `.sms` |
| Tapes | `.wav` (8 or 16-bit, any sample rate), `.bit` (MAME) |
| Disks | `.sf7` |
| SF-7000 printer | `.prn`, `.txt` |

## Cartridges

Load a cartridge from **Cartridge**. The core works out the cartridge type
by itself, so leave **Machine > Mapper** on Auto. That includes:

- BASIC Level II and III
- The Castle, Othello, Music Editor
- Terebi Oekaki: the drawing tablet is the mouse, and the left button
  puts the pen down
- Taiwanese RAM cartridges
- the SC-3000 Survivors Multicart and Megacart
- Sega's 315-5208 paging chip, as on *Loretta no Shouzou* (often found
  as a `.sms` file). Any unknown image over 64 KB gets this type.

A few programs need extra RAM on the cartridge. **Machine > Cart RAM**
adds it: 2 KB or 16 KB at 8000-BFFF, or 32 KB at 8000-FFFF. Auto (the
default) gives each known cartridge what it had.

Joystick: button 1 and button 2. Start is the RESET key on the SC-3000
and PAUSE on the SG-1000.

## BASIC and the keyboard

Load a BASIC cartridge. BASIC Level III is the usual one.

With **Input > Keyboard = PC** (the default), keys type what is printed on
your PC keyboard. The SC-3000 puts many symbols in other places (`=` is
Shift + `-`, `:` and `@` have their own keys), and the core presses the
right SC-3000 keys for you. Shift + letter gives a capital, as on a PC.
You can paste a whole program into the core and nothing is lost.

With **Keyboard = SC-3000**, keys work by position, as on the real machine:
a plain letter gives a capital and Shift gives lower case.

| SC-3000 key | PC key |
|---|---|
| RESET | F10, or a joypad's Start |
| BREAK | Esc |
| GRAPH | Alt |
| ENG DIER'S / KANA | Caps Lock |
| FUNC | Tab or F1 |
| CLR/HOME | Home or Backspace |
| INS/DEL | Insert / Delete |
| ¥ | `\` |

## Tapes

1. Load BASIC.
2. Mount the tape in **Tape**.
3. Type `LOAD` and press Return.
4. When `Ready` comes back, type `RUN`.

The tape plays by itself while BASIC reads it, and a bar at the bottom of
the screen shows the time and progress. With **Machine > Tape speed = 4x**
(the default), a tape loads four times faster: a 47 second tape takes
about 12 seconds. **Machine > Rewind tape** goes back to the start.

The SC-3000 can't start a program straight from a tape, so you always
load tapes from BASIC with `LOAD`.

### Saving to tape

1. Copy `releases/blank_tape_15min.bit` (a blank 15-minute tape) to
   `games/SC3000/`.
2. Mount it in **Tape save**.
3. Type `SAVE "NAME"`.
4. To load it back, mount the same file in **Tape** and type `LOAD "NAME"`.

Saving writes into the file itself, so keep a spare copy of the blank tape.
The file can't grow, so its size sets how much fits on the tape.

## SF-7000 disk unit

Put `boot0.rom` in `games/SC3000/` and mount a `.sf7` disk in **SF-7000
disk**. The machine restarts with the disk unit attached and boots the
disk. Disk BASIC uses `FILES`, `LOAD "name"` and `SAVE "name"`. Anything you
save is written back to the disk image on the SD card, so keep copies of
your disks.

Type `UTILITY` to start the IPL's utility program: `F` formats a disk (put
the new disk in when it asks; any 160 KB file works as a blank disk), `C`
copies a disk, `B` boots again.

### Printer

LPRINT and LLIST print into a file:

1. Copy `releases/sf7000_printer_256k.prn` (a file of spaces) to
   `games/SC3000/`.
2. Mount it in **SF-7000 printer**.
3. In Disk BASIC, type `CONSOLE ,,,,2` to choose the SF-7000's printer
   (the default, `,,,,1`, is the SC-3000's own printer port).
4. `LPRINT` and `LLIST` now go into the file.

The file gets exactly what BASIC sends, printer control codes included (it
starts with `ESC Q P ESC e`), and is written to the SD card half a second
after printing stops. The file can't grow, so its size sets how much fits.
Mounting it again starts from the beginning. With no file mounted, printing
still works but the output is thrown away.

### RS-232

The SF-7000's serial port is connected to the MiSTer's UART. Choose the
connection and the baud rate (9600 down to 300) in the system menu's
**UART mode** (the page to the right of the core's menu). The core follows
that baud rate. The Baud row only shows for connections other than None,
but the rate you save there also applies with None.

With the connection set to None, Linux's `/dev/ttyS1` on the MiSTer is the
other end of the cable, for example:

    stty -F /dev/ttyS1 9600 cs8 parenb -parodd cstopb raw -echo clocal
    cat /dev/ttyS1

In Disk BASIC, `COMSAVE` sends the program as text and `COMLOAD` receives
one (it ends at an empty line). `COMSET 8,E` sets the format: 5 to 8 bits,
parity N, E or O, always 2 stop bits. After booting, the format is 8 bits,
even parity, 2 stop bits.

Disk BASIC 1.0p has a bug: after a `COMSET`, the serial port stops sending
and `COMSAVE` hangs (MAME does the same). Version 1.1p fixes it. With 1.0p,
leave the format as it is after booting.

## Othello Multivision

1. Put `boot1.rom` in `games/SC3000/`.
2. Set **Machine > Model = Othello Multivision** and choose **Apply and
   reset**.
3. With no cartridge loaded, the built-in Othello starts. Use **Eject
   cartridge** if one is in. SG-1000 cartridges also run on this model.

The Multivision's keypad is on your keyboard:

- `1`-`8` and `A`-`H` are the rows and columns of the board
- `9` (or `#`) and `0` (or `*`) are the keypad's other keys
- joystick button 1 is S-1, button 2 is S-2

In Othello, S-1 is a game against the computer and S-2 is a two-player
game. To play a move, press a letter, a digit, then S-1.

Set Model back to SC-3000 afterwards.

## Menu

Only the settings that change the machine (Model, Mapper, SF-7000, SK-1100
keyboard, Cart RAM) wait until you choose **Apply and reset** ("Changes
pending" shows until then). Everything else changes straight away; Video
standard and Border at the next frame.

| Page | Setting | |
|---|---|---|
| | Cartridge, Tape, Tape save, SF-7000 disk, SF-7000 printer | load files |
| | Load ROM | load the boot ROM of the chosen model by hand |
| Machine | Model | SC-3000 (default), SG-1000 or Othello Multivision |
| | Mapper | Auto (default), or force a cartridge type |
| | SF-7000 | Auto: attached when a disk is mounted (default), On, Off |
| | SK-1100 keyboard | SG-1000 only: Off (default) or On, the SC-3000 keyboard unit |
| | Cart RAM | Auto (default), Off, 2KB, 16KB or 32KB |
| | Tape speed | 4x (default) or Normal |
| | Rewind tape, Eject cartridge | |
| Video | Video standard | NTSC (default) or PAL |
| | Border, Aspect ratio, Scale, Scandoubler Fx | |
| | Tape overlay | show or hide the tape bar |
| Input | Keyboard | PC (default) or SC-3000 layout |
| | Joysticks swap | |
| Audio | Tape audio | hear the tape while it plays |

## Not supported yet

- The SC-3000's own printer port (the SF-7000's printer works)
- SF-7000 RS-232: the CTS line and the synchronous mode
- Tape loads started from inside the Multicart or Megacart menus may not
  work at 4x. Use Tape speed = Normal for those.

## Hardware emulated

| Part | |
|---|---|
| CPU | Z80A, 3.58 MHz |
| Video | TMS9918A (NTSC) / TMS9929A (PAL), 16 KB VRAM |
| Sound | SN76489AN |
| I/O | 8255 PPI: keyboard, joysticks, cassette |
| RAM | 2 KB (SG-1000: 1 KB), plus any RAM on the cartridge |
| SF-7000 | 64 KB RAM, IPL ROM, uPD765A floppy controller, 3" drive (160 KB), 8251 RS-232, Centronics printer |
| Othello Multivision | 2 KB RAM, 16 KB BIOS, keypad |

## Credits

- Core: Alan Steremberg (alanswx)
- Z80: T80 by Daniel Wallner, MikeJ, Sorgelig and others. The
  SystemVerilog translation (t80sv) is by Rodimus.
- TMS9918A: vdp18 by Arnim Laeuger, converted to SystemVerilog
- SN76489 (jt89) and 8255 (jt8255): Jose Tejada (jotego)
- SDRAM controller and the MiSTer framework: Sorgelig and the MiSTer
  developers
- MAME was the reference for the hardware, the cartridge types and the
  cartridge list.

## License

GPL-3.0, see `LICENSE`. Some parts have their own licenses, given in their
file headers:

- t80sv and vdp18v: BSD-style (see also `rtl/t80sv/LICENSE`)
- jt8255: MIT

No ROMs or software are included.

For developers: `verilator/` has a simulator of the same RTL (see
`verilator/README.md`). `tools/gen_cart_db.py` rebuilds the cartridge table
from MAME's software lists.
