# VideoBrain Family Computer for MiSTer

An FPGA implementation of the 1978 Umtech VideoBrain Family Computer.

- 4x analog joysticks
- Expander 1
- 2x cassette tape decks
- Expander 2 modem / Timeshare support via UART
- Printer output via UART or mounted image

F8 instruction cycle timing has been thoroughly referenced against all available hardware measurements and documentation. See [accuracy and remaining-work report](docs/ACCURACY.md) for current scope and evidence limits.

## Installing

Place the latest .rbf from [releases](releases) in /media/fat/_Computers.

The core folder is /media/fat/games/VideoBrain. A BIOS is required. Verified BIOS ROMs are circulated split:

- **uvres1.bin** (a.k.a. **uvres_1n.d67**): MD5 CDF2F70F616AB61D7FBF31A3763BFC21, 2,048 bytes
- **uvres2.bin** (a.k.a. **resn2.e5**): MD5 E4B8B681CCCF4E8ECB09C3FDC206B8B2, 2,048 bytes

Use the [BIOS tool](tools/README.md#bios) to combine the files.

```text
tools/make_boot_rom.sh uvres1.bin uvres2.bin boot0.rom
```

Place boot0.rom in the VideoBrain games folder.

- boot0.rom: MD5 E1E7F6120EB8E23CA5C63B4246F04F18, 4,096 bytes

[Expander 1](docs/EXPANDER1.md) needs its firmware as boot1.rom (or loaded manually). This is required for Information Manager, Timeshare, and tape operation.

- boot1.rom: MD5 41DE2BCEFFB8257930A16E03FC431550, 2048 bytes

## Using the core

The OSD provides these file actions:

| Action | Use |
| --- | --- |
| Load Cartridge | Load .bin cartridge |
| Mount Playback Tape | Mount read-only .vbt |
| Mount Record Tape | Mount writable .vbt |
| Keyboard > Load Keyboard File | Load .vbk automatic keyboard entry file |
| Printer > Mount Capture Image | Mount .vbp printer capture image |

### Cartridges (BIN)

All 18 known VideoBrain cartridge dumps are supported. Cartridge ROMs must be a single raw .bin image, with any split chip dumps assembled in the correct layout. Mappers are selected automatically for all known titles. System > Mapper Fallback can be used to manually set the memory mapping for an unrecognized cartridge.

Information Manager and APL/S: The Computational Language need assembled ROM images. See [cartridge assembly](docs/CARTRIDGES.md#split-cartridge-conversion).

### Tapes (VBT)

Tapes are used to save and restore user data on the VideoBrain, not to load software directly. To enable tape save/load in most software, loading a single cassette into the Record deck is sufficient. Data can be loaded from either deck, so the Playback deck can be used to prevent accidental overwrite. 

You may encounter an I/O error when tape data is invalid, or if the tape had advanced and was not rewound before operation. Re-mounting a tape also rewinds it to the beginning. See [tape setup and recording behavior](docs/TAPE.md) for more info on loading from/saving to tape.

Note that [Information Manager](docs/INFOMAN-MANUAL.md)'s EDIT mode uniquely requires a tape with an existing saved record in Playback, in addition to a Record tape to receive modified data. If this is not configured, an I/O ERR will occur. 

### Keyboard Entry (VBK)

.vbk files are effectively macros. The principal use case is to have the core automatically input APL/S programs for you, though they have other uses (including playback of monophonic music files in Music Teacher 1). They can be loaded in any software, including the BIOS. [Example](/examples) files and a [converter](tools/README.md#keyboard-files) to create new files are provided.

The converter accepts text files containing supported inputs and converts them to .vbk files which will replay the input sequence. SHIFT state is observed to avoid flipped-state entries. The loader is configured to wait just long enough for the software to signal it is ready to accept each new keypress, preventing dropped inputs. Pressing any key or opening the OSD aborts entry. Keyboard > OSD Aborts VBK can be optionally disabled to allow .vbk playback to continue while in the menu.

Music Macro Language (.mml) files can also be converted. MML files must use a simplified subset of the QB64 PLAY format. The converter generates unique musical .vbk files (with VBK2 header for differentiation from text entry files) for automatic playback in the free play mode in Music Teacher 1. Press Z (for 1) in Music Teacher 1 to get to the play/record screen before loading a .vbk. In other software, make sure you're at a text entry prompt.

### Printer capture (VBP)

The Expander 1 printer stream can be saved to a mounted .vbp image while Timeshare uses the UART for modem communication. Mount a copy of [blank-printer.vbp](examples/blank-printer.vbp), select the baud rate, and choose Start Capture. When finished, choose Stop Capture and Save, wait for Ready, and unmount before exporting. See [printer capture](docs/PRINTER.md).

### Options

System > Master Control (Soft Reset) and Esc operate the physical Master Control key: one reset pulse per press, sampled at the end of vertical blank. RAM remains powered; software decides what to retain. In APL/S, this discards the program in RAM. Keyboard > Esc Soft Reset > Off prevents accidental activation. **Reset** performs a power cycle, clearing volatile memory and restoring the cartridge's initial bank while retaining loaded ROMs.

Pop-up overlays provide status during use: keyboard file entry starting, finishing or being aborted; joystick calibration in progress; and tape activity, rewinding, end of tape or errors. Tape busy means a tape operation is in progress; Tape idle means activity has ended, but does not verify the saved data. Tape error reports a controller failure even if the software reports TAPE OK. Messages appear after the OSD closes. System > Info Messages > Off disables these notifications, including error messages.

## Keyboard

![VideoBrain keyboard manual](/images/VB_Keyboard.gif)

In the BIOS and most software, VideoBrain's SHIFT key is a toggle (like CapsLock on a modern keyboard). A square in the bottom right of the screen appears in some software to indicate when SHIFT is active; a light square is unshifted, dark is shifted. Other software will show your cursor as an L for unshifted (lowercase) and a U for shifted (uppercase). Timeshare uniquely uses SHIFT by holding, not as a toggle.

[How to play and use VideoBrain software](docs/HOW-TO-PLAY.md) provides the original manual diagrams, cartridge keyboard layouts, game-selection charts, and MiSTer control mappings for games and utilities.

Unique VideoBrain keys are mapped like this:

    SPACE           RUN/STOP
    ESC             MASTER CONTROL (soft reset)
    F1 / Backspace  BACK/TEXT
    F2 / Home       PREVIOUS/COLOR
    F3 / Enter      NEXT/CLOCK
    F4 / End        SPECIAL/ALARM
    F5 / Ctrl+Enter ERASE/RESTART

Both main Enter and keypad Enter alias F3. Enter and Backspace follow the same SHIFT mode and cartridge functions as F3 and F1; in Timeshare, carriage return remains F5.

The PC number row and numeric keypad also map `1234567890` to the VideoBrain key positions `ZXCSDFWER/`. These are aliases for the physical keys: select VideoBrain's numeric/SHIFT mode when the software requires it. In letter mode, they enter the corresponding letters (or `?` for `0`); cartridge overlays can assign other functions.

## Joysticks

VideoBrain supports 4 analog joysticks with one fire button each, though only one game (Tennis) supports 4 players. 

Use Calibrate Sticks when joysticks are active in-game to fully calibrate all joysticks for use. Joysticks drift diagonally until calibrated.

The physical VideoBrain joystick does not automatically re-center itself. This can make things bit awkward in Tennis. Joysticks > Analog Mode > Relative allows you to move around in Tennis without snapping back to the center when using a modern self-centering joystick; 3 speeds are provided.

Tennis and other games do not share centering positions - this is correct to hardware. Auto applies the correct centering. You can override this in the OSD.

Joysticks > Paired Sticks lets a controller's right stick and Fire (Paired) operate another joystick. See [calibration and controller pairing](docs/JOYSTICK.md).

## Video

VideoBrain native output is interlaced. Video > 240p > On toggles progressive output. This changes vertical rollover and could affect joystick reads across that boundary; no issue has been observed in use.

## Timeshare online over UART

The Timeshare cartridge can connect to remote text services through MiSTer's HPS UART and a Linux network bridge. Expander 1 firmware (boot1.rom) is required. See the [Timeshare setup and Telehack example](docs/EXPANDER1.md#timeshare-over-uart) for connection commands, keyboard controls, and display setup.

For printer output, select System > UART Output > Printer and use the [Linux file-capture utility](docs/EXPANDER1.md#printer-file-capture). It captures the actual printer stream, including Information Manager's PTR output. Modem is the default for Timeshare; the UART serves one port at a time.

## Tools

See [tools/README.md](tools/README.md) for BIOS and cartridge assembly, keyboard file conversion, and tape utilities.

## Building

Use Quartus 17.0.2. Simulation and regression instructions are in [verilator/README.md](verilator/README.md). See [contributing](CONTRIBUTING.md) for user-supplied ROM paths and validation requirements.

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
