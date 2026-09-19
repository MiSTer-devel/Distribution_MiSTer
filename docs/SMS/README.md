# [Sega Master System](https://en.wikipedia.org/wiki/Master_System)/[Game Gear](https://en.wikipedia.org/wiki/Game_Gear) for [MiSTer FPGA](https://mister-devel.github.io/MkDocs_MiSTer/) and [MiST](https://github.com/mist-devel/mist-board/wiki)

This core is a port of Ben's Sega Master System implementation for the Papilio. See [http://fpga-hacks.blogspot.de/](http://fpga-hacks.blogspot.de/).

## Features

* Sega Master System, Game Gear, SC-3000 and [SG-1000](https://en.wikipedia.org/wiki/SG-1000) Support
* [Sega System E arcade hardware](https://segaretro.org/Sega_System_E) Support
* Master System Evolution/Noza hardware and 132-game flash memory Support
* NTSC & PAL Support
* Hide Borders Option - Allows you to fill the screen vertically without black borders.
* FM Audio Support
* Extra Sprites Option
* Cheats
* Extended Game Gear Resolution Option
* Z80 Turbo Option
* Lightgun, Paddle controls, Keyboard(SK-1100) and Multitap Support
* Independent SMS, Mega Drive 3-button and 6-button controller emulation per port
* Gear to Gear link cable over USERIO
* BIOS Loading Support
* Savestates

## Where to Download

* For MiSTer, go to [releases](https://github.com/MiSTer-devel/SMS_MISTer/tree/master/releases).
* For MiST, go to [mist-binaries](https://github.com/mist-devel/mist-binaries/tree/master/cores/sms).

### Installation

* Copy the *.rbf file at the root of the SD card.
* Copy *.SMS,.GG,.SG,.SC ROMs into SMS folder.

## Notes

* Some games come in .gg format but are in fact SMS games. Rename the .gg extension to .sms or .bin to fix them. These games are mostly listed in this page [SMSpower-SMS-GG list](http://www.smspower.org/Tags/SMS-GG).
* The "Aspect ratio" doesn't do much in PAL mode, that's normal.
* The "Region" parameter toggle some hardware features that are specific to the different console models. Some localized games need these modifications to work properly. If a game doesn't work right, try to toggle this setting and reset the game in order to troubleshoot.
* Each game cartridge comes with a specific mapper, which description is not included in the .gg ou .sms file. The core has a special logic to automatically determine which mapper needs to be used, but some games make a good effort to make this logic fail. The "Mapper" parameter permits to force the usage of specific mappers in case the automatic detection fails.
* The "Masked left column" option controls behaviour of left column when hidden by system (usually during horizontal scrolling). "BG" sets it to the background/overscan colour, as on original hardware. "Black" makes it black, which may look better on non full-screen settings as the column will blend in with surrounding black area. "Cut" will remove the column from the active image, so the horizontal resolution becomes 248 instead of 256. This will distort the image when scaled, particularly on integer scaling settings, but will use more of the screen. When "Border" is set to "Yes" the left column is always shown as part of the border, so "Masked left column" is disabled.
* Regular ROMs savestates are persistent in the SD card. BIOS built-in games will save to memory only (non-persistent). Workaround: load the BIOS and an empty ROM.

### Gear To Gear USERIO Mapping

| GG Signal    | Cable Pin	 | USERIO Pin|
| -------- | ------- | ------- |
| PC4 / TX  | 6    |USER_IO[1]|
| PC5 / RX | 9     |USER_IO[2]|
| PC0   | 1   |USER_IO[0]|
| PC1   | 2   |USER_IO[3]|
| PC2   | 3   |USER_IO[4]|
| PC3  | 4   |USER_IO[5]|
| PC6 / NMI  | 7   |USER_IO[6]|
| GND | 8   |GND|

### Controller types

Under **Input**, choose **P1 Controller** and **P2 Controller** independently. Both default to **SMS 2 Buttons**. **Swap Joysticks** exchanges the MiSTer devices feeding the ports; each port keeps its selected controller type.

In either Mega Drive mode, **Fire 1** acts as B and **Fire 2** as C. Map **Mega Drive A**, **Mega Drive Start**, **Mega Drive X**, **Mega Drive Y**, **Mega Drive Z** and **Mega Drive Mode** through the joystick configuration menu as needed. The six additional buttons and SaveState have no automatic mapping. Existing saved mappings remain usable. **Pause** continues to operate the console's Pause button independently of Mega Drive Start.

Mega Drive modes reproduce the controller's TH protocol, including the identification sequence and timeout for six-button pads. Games must support that protocol to read the additional buttons. Keep SMS mode for games incompatible with Mega Drive controllers. The existing Japanese-region TH restrictions still apply.

SNAC, lightgun, paddle and multitap modes take precedence over these emulated controller types on both ports. Game Gear and System E keep their existing controls.

### Master System Evolution

The core supports the Master System Evolution/Noza hardware used by the 132-game console, not just its flash mapper. This includes the original launcher menu, Evolution board registers and I/O, reset wiring, included Master System software and Game Gear-compatible titles. Load a user-supplied 16 MiB flash dump as an `.sms` file; individual games do not need to be extracted.

The two known flash revisions are detected automatically by their complete ROM CRC-32 (`0C90A6CA` or `CBD7FF82`), regardless of filename. Loading either exact image activates the full Evolution hardware profile automatically, unless another mapper is explicitly forced from the menu.

The Evolution profile also enables the clone VDP behavior required by the software, including its 224-line name-table addressing, menu interrupt and VRAM-write timing, extended palette modes and relaxed per-line sprite limit. Game Gear-compatible palette and controller behavior is selected automatically for the applicable included titles while retaining TV-sized video output.

Save states are supported in both the launcher and included games. As with other cartridge save states, keep the same flash image loaded when restoring a state.

Press **Pause + Fire 1 + Fire 2** together to reset back to the Evolution launcher. With a port configured as **MD 6 Buttons**, **X + Y + Z** provides the equivalent shortcut. These combinations are active only while an Evolution flash image is running.
