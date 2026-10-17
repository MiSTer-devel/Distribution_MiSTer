# TSConf for MiSTer FPGA

This is a port of [TSConf](http://forum.tslabs.info/viewforum.php?f=20), an advanced ZX Spectrum-compatible platform, to the [MiSTer FPGA](https://mister-devel.github.io/MkDocs_MiSTer/).

## Features

### TSConf features

- High compatibility with original Pentagon-128 clone
- Advanced video features:
  - Pixel resolutions 360x288, 320x240, 320x200, 256x192
  - Up to 720x288 Hi-res pixel resolution
  - Hardware scrolled graphic planes
  - 256 and 16 indexed colors per pixel
  - Programmable color RAM with RGB555 color space and 256 cells
  - 512 and 256 bytes per line addressing
  - Text mode with loadable font and hardware vertical scroll
  - Up to 256 graphic screens
- Hardware engine for Tiles and Sprites graphics
  - Up to 85 sprites per line
  - Sprites sized from 8x8 to 64x64 pixels
  - Up to 3 sprite planes
  - Up to 2 tile planes with 8x8 pixels tiles
  - Up to 16 palettes for sprites per line
  - Up to 4 palettes for tiles per line for each tile plane
- Z80 Memory addressing enhancements:
  - Programmable RAM page for any 16kB window
- Z80 acceleration features
  - Selectable CPU clock 14MHz, 7MHz and 3.5MHz
  - 512 bytes of zero-wait RAM for 14MHz
  - On-the-fly programmable maskable interrupt position
  - Separate IM2 vectors for different interrupt sources
- Advanced hardware features
  - DRAM-to-Device, Device-to-DRAM and DRAM-to-DRAM DMA Controller

See details in the official git repository: [link](https://github.com/tslabs/zx-evo/blob/master/pentevo/docs/TSconf/tsconf_en.md)

### MiSTer port features

* Synced with the newest upstream TSConf version as of July 15, 2026
* Scandoubler with HQ2x and Scanlines
* 48.8 Hz and 60 Hz video modes
* RTC
* Configurable CMOS settings through OSD
* Two SD cards can be used simultaneously: card #1 is a VHD stored on MiSTer's primary SD card, and card #2 is the physical secondary SD card. Without a mounted VHD, the physical secondary SD card becomes card #1
* Two configurable joysticks supporting 8-bit Kempston, Sinclair, Cursor, and QAOPM modes
* Kempston mouse with wheel support and an option to swap the buttons
* Keyboard mapping matching ZX Evolution
* Improved PS/2 keyboard controller compatibility
* Turbosound FM (dual YM2203)
* General Sound 512KB-2MB
* SAA1099
* OPL3
* Covox
* SounDrive
* VDAC1
* Switchable ABC/ACB PSG panning
* Tape out mixed into audio output
* MIDI output via AY I/O ports
* [ZiFi](https://github.com/UzixLS/ZiFi) support


## Installation and usage

1. Copy `TSConf_YYYYMMDD.rbf` from the [releases](releases/) to the MiSTer `_Computer` directory.
2. Copy `boot0.rom` and `boot1.rom` to the `games/TSConf/` directory on the MiSTer SD card.
3. Put a FAT32-formatted TSConf VHD image to the `games/TSConf` directory and mount it from the
   core menu, or use a physical secondary SD card formatted in FAT32.
4. Install [Wild Commander](https://forum.tslabs.info/viewtopic.php?f=26&t=143) on the VHD (or SD card).
5. Download a few demos and games from https://prods.tslabs.info/

If everything is done right, Wild Commander will start and let you choose your demos and games to start.

A small [example](releases/vhd-example.zip) VHD with preinstalled Wild Commander is included in the release.


## PS/2 keyboard mapping

Letters `A`–`Z`, digits `0`–`9`, `Enter`, and `Space` map directly to the corresponding ZX Spectrum keys. The remaining mapped PS/2 keys are:

| PS/2 key | ZX Spectrum key or special function |
|---|---|
| Left Shift | `Caps Shift` |
| Right Shift | `Symbol Shift` |
| Left, Down, Up, Right arrow | `Caps Shift+5`, `Caps Shift+6`, `Caps Shift+7`, `Caps Shift+8` |
| Backspace | `Caps Shift+0` |
| Caps Lock | `Caps Shift+2` |
| Tab | `Caps Shift+Space` (Break) |
| `` ` `` | `Caps Shift+1` (Edit) |
| Page Up, Page Down | `Caps Shift+3`, `Caps Shift+4` |
| Delete | `Caps Shift+9` |
| Home, End, Insert | `Symbol Shift+Q`, `Symbol Shift+E`, `Symbol Shift+W` |
| `;` | `Symbol Shift+Z` |
| `/?` | `Symbol Shift+C` |
| `'/"` | `Symbol Shift+P` |
| `-/_` | `Symbol Shift+J` |
| `=/+` | `Symbol Shift+K` |
| `[` | `Symbol Shift+8` |
| `]` | `Symbol Shift+9` |
| `,` | `Symbol Shift+N` |
| `.` | `Symbol Shift+M` |
| `\` | `Caps Shift+Symbol Shift` |
| `F11` | Reset |
| `F12` | MiSTer OSD menu |
| `Left Shift+F11` | CS reset |
| `Right Shift+F11` | Reset into TS-BIOS Setup Utility |


## Joystick buttons mapping

Both joystick ports use the same mapping. Kempston mode exposes the indicated joystick bits directly and does not generate key presses. Sinclair, Cursor, and QAOPM modes convert joystick input to the following keyboard keys.

| Joystick input | Kempston bit | Sinclair 1 | Sinclair 2 | Cursor | QAOPM |
|---|---:|---:|---:|---|---:|
| Right | 0 | `7` | `2` | `Right` arrow | `P` |
| Left | 1 | `6` | `1` | `Left` arrow | `O` |
| Down | 2 | `8` | `3` | `Down` arrow | `A` |
| Up | 3 | `9` | `4` | `Up` arrow | `Q` |
| Fire 1 | 4 | `0` | `5` | `Enter` | `M` |
| Fire 2 | 5 | `M` | `Z` | `Tab` (`Break`) | `Space` |
| Fire 3 | 6 | `N` | `X` | `Space` | `N` |
| Fire 4 | 7 | `B` | `C` | `Esc` (not mapped to the ZX matrix) | `B` |


## Building

The project targets the MiSTer Cyclone V device and Quartus Prime Lite 17.0.
Run `make build`, or build the project directly in the Quartus GUI.
The resulting bitstream is written to `output_files/TSConf.rbf`.


## Credits

- [TSConf / ZX Evolution](https://github.com/tslabs/zx-evo)
- T80 Z80 HDL implementation
- [JT12 Yamaha OPN HDL implementation](https://github.com/jotego/jt12)
- [OPL3 FPGA implementation from ao486_MiSTer](https://github.com/MiSTer-devel/ao486_MiSTer/tree/master/rtl/soc/sound/opl3)
