# [Gameboy](https://en.wikipedia.org/wiki/Game_Boy)  / [Gameboy Color](https://en.wikipedia.org/wiki/Game_Boy_Color) port to [MiSTer](https://github.com/MiSTer-devel/Main_MiSTer/wiki)

This is port of [Gameboy for MiST](https://github.com/mist-devel/gameboy)

* Place RBF file into root of SD card.
* Place *.gb|*.gbc files into Gameboy folder.

## Features
* Original Gameboy & Gameboy Color Support
* Super Gameboy Support - Borders, Palettes and Multiplayer
* Custom Borders
* SaveStates
* Fastforward 
* Rewind - Allows you to rewind up to 40 seconds of gameplay
* Frameblending - Prevents flicker in some games (e.g. "Chikyuu Kaihou Gun Zas") 
* Custom Palette Loading
* Real-Time Clock Support
* Gameboy Link Port Support - Requires USERIO adapter
* Cheats

## Open Source Bootstrap roms
This now includes the open source boot ROMs from [https://github.com/LIJI32/SameBoy/](https://github.com/LIJI32/SameBoy/). For maximum GBC compatibility/authenticity you can still place the Gameboy color bios/bootrom into the Gameboy folder and rename it to boot1.rom

## Palettes
This core supports custom palettes (*.gbp) which should be placed into the Gameboy folder. Some examples are available in the palettes folder.

## Custom Borders
This core supports custom borders (*.sgb) which should be placed into the Gameboy folder. Some examples are available in the borders folder.

## Autoload
To autoload your favorite game at startup rename it to `boot2.rom`.

## Video output
The Gameboy can disable video output at any time which causes problems with vsync_adjust=2 or analog video during screen transitions. Enabling the Stabilize video option may fix this at the cost of some increased latency.

# Savestates
This core provides 4 slots to save and restore the memory state which means you can save at any point in the game. These can be saved to your SDCard or they can reside only in memory for temporary use (OSD Option). Save states can be performed with the Keyboard, a mapped button to a gamepad, or through the OSD.

Keyboard Hotkeys for save states:
- Alt+F1 thru Alt+F4 - save state
- F1 thru F4 - restore state

Gamepad:
- Savestatebutton+Left or Right switches the savestate slot
- Savestatebutton+Start+Down saves to the selected slot
- Savestatebutton+Start+Up loads from the selected slot
