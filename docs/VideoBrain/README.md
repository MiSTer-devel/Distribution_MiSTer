# VideoBrain Family Computer for MiSTer

FPGA implementation of the 1978 Umtech VideoBrain Family Computer.

- All 18 known cartridge dumps
- Four analog joysticks
- Expander 1 and two cassette decks
- Timeshare modem communication over UART
- Printer capture over UART or to an SD image

See [accuracy and remaining work](docs/ACCURACY.md).

## Installing

- Core: latest `.rbf` from [releases](releases) in `/media/fat/_Computers`.
- ROMs and media: `/media/fat/games/VideoBrain`.
- `boot0.rom`: required BIOS; combine the two dumps below with the [BIOS tool](tools/README.md#bios).
- `boot1.rom`: Expander 1 firmware; required for Information Manager, Timeshare and tape operation. Also loadable from the OSD.

| ROM | Bytes | MD5 |
| --- | ---: | --- |
| `uvres1.bin` / `uvres_1n.d67` | 2,048 | `CDF2F70F616AB61D7FBF31A3763BFC21` |
| `uvres2.bin` / `resn2.e5` | 2,048 | `E4B8B681CCCF4E8ECB09C3FDC206B8B2` |
| `boot0.rom` (combined BIOS) | 4,096 | `E1E7F6120EB8E23CA5C63B4246F04F18` |
| `boot1.rom` (Expander 1) | 2,048 | `41DE2BCEFFB8257930A16E03FC431550` |

## Using the core

| OSD action | File | Guide |
| --- | --- | --- |
| Load Cartridge | `.bin`, `.vbc` | [Cartridge assembly and mapping](docs/CARTRIDGES.md) |
| Mount Playback Tape | `.vbt` | [Read-only tape playback](docs/TAPE.md) |
| Mount Record Tape | `.vbt` | [Tape recording](docs/TAPE.md) |
| Keyboard > Load Keyboard File | `.vbk` | [Automatic key entry and music](docs/KEYBOARD-INPUT.md) |
| Printer > Mount Capture Image | `.vbp` | [Printer capture and export](docs/PRINTER.md) |

- Tapes store user data, not software. Use the cartridge's SAVE/LOAD commands.
- Keyboard files: listings, text and music; [examples](examples/README.md) and [converters](tools/README.md#keyboard-files) provided. Any key cancels entry. Keyboard > OSD Aborts VBK controls cancellation when opening the menu.
- Printer capture: Stop Capture and Save, wait for Ready, then unmount before export.
- Timeshare: [UART network bridge setup](docs/EXPANDER1.md#timeshare-over-uart). Mounted printer images support simultaneous modem use.

## Keyboard

| PC key | VideoBrain key |
| --- | --- |
| Space | RUN/STOP |
| Esc | MASTER CONTROL (soft reset) |
| F1 / Backspace | BACK/TEXT |
| F2 / Home | PREVIOUS/COLOR |
| F3 / Enter (either) | NEXT/CLOCK |
| F4 / End | SPECIAL/ALARM |
| F5 / Ctrl+Enter | ERASE/RESTART |

- **SHIFT:** toggle in the BIOS and most software; held in Timeshare.
- **Numbers:** number row and keypad alias the VideoBrain numeric positions; select the software's numeric/SHIFT mode first.
- [Original keyboard, cartridge overlays and software instructions](docs/HOW-TO-PLAY.md).

## Joysticks

- **Calibrate Sticks:** run while the game reads its sticks; repeat after reset or a new game as needed.
- **Stick Preset > Auto:** cartridge-specific centering; manual override available.
- **Analog Mode > Relative:** hold position on release, useful for Tennis. Three speed settings.
- **Paired Sticks:** right stick and Fire (Paired) operate another joystick. Pinball pairs 1+2 / 3+4; Doubles pairs 1+3 / 2+4.

[Calibration, pairing and timing](docs/JOYSTICK.md).

## Video

- **Output:** 480i (Original), 240p or 480p; select Apply Video Output to switch.
- **Colors:** 16 (Original) by default; 32 (Patent) uses experimental intensity mapping.

[Output behavior and color accuracy](docs/VIDEO.md).

## Reset and status

- **Reset:** power cycle; clears volatile memory, retains loaded ROMs.
- **System > Master Control (Soft Reset) / Esc:** original reset key; software decides what to retain. Discards the APL/S program. Disable Esc with Keyboard > Esc Soft Reset > Off.
- **System > Info Messages > Off:** disable status popups, including errors.
- [Reset, cartridge reload and RTC clock options](docs/RESET.md).

## Tools and building

- [Tools](tools/README.md): ROM assembly, keyboard conversion, tape and printer utilities.
- Quartus 17.0.2 for core builds.
- [Simulation and regressions](verilator/README.md); [contributing and ROM requirements](CONTRIBUTING.md).

## Sources

- [Sean Riddle - seanriddle.com](https://www.seanriddle.com/vbinfo.html)
- [Kevin Horton - kevtris.org](http://blog.kevtris.org/blogfiles/videobrain/videobrain_unwrapped.txt)
- [Tempest - atariprotos.com](https://www.atariprotos.com/othersystems/videobrain/videobrain.htm)
- [orphanedgames.com](https://orphanedgames.com/videobrain/)
- [MAME](https://github.com/mamedev/mame/tree/master/src/mame/vidbrain)
- US patents [US4232374A](https://patents.google.com/patent/US4232374A) & [US4177462A](https://patents.google.com/patent/US4177462A)
- [channel_f_and_videobrain Yahoo/groups.io group](https://groups.io/g/Channel-F-and-VideoBrain)
- [James Price - 21 APL/S Games and One-Liners for Your Umtech VideoBrain (GitHub)](https://github.com/jamescprice/21-APL-Games-and-One-Liners-For-Your-Umtech-Videobrain)
- [E5frog - VESWiki](https://channelf.se/veswiki/index.php?title=Opcode)
- [Lowell O. Turner - nyx.net](https://www.nyx.net/~lturner/public_html/Fairchild_F8.html)
- [Home Computer & Video Game Museum - VideoBrain](http://hcvgm.org/VideoBrain.html)
- [oldcomputers.net/videobrain.html](https://www.oldcomputers.net/videobrain.html)
- [forums.atariage.com](https://forums.atariage.com/topic/71151-videobrain-anyone-have-info/)

## Credits

Core by [Elle Ball (meauxdal)](https://github.com/meauxdal) with assistance from [Alan Steremberg (alanswx)](http://github.com/alanswx). LLM assistance was used in the creation of this core.

The F8 CPU and packages derive from [Grabulosaure's Channel F core](https://github.com/MiSTer-devel/ChannelF_MiSTer).

## License

[GPL-2.0-or-later](LICENSE). Bundled components retain their respective licenses.
