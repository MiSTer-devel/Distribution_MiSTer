# [Atari Lynx](https://en.wikipedia.org/wiki/Atari_Lynx) for [MiSTer Platform](https://github.com/MiSTer-devel/Main_MiSTer/wiki)

This branch is a special version for splitscreen multiplayer.
In case you are searching for the normal Atari Lynx, please go here:
https://github.com/MiSTer-devel/AtariLynx_MiSTer

# HW Requirements
SDRam module of any size is required

# Bootrom
You need to add the Bootrom file(often called lynxboot.img) to the AtariLynx Folder and name it: boot.rom

Checksum for valid Bootrom:

SHA-1:
E4ED47FAE31693E016B081C6BDA48DA5B70D7CCB

MD5:
FCD403DB69F54290B51035D82F835E7B

# Status
All official games should be playable.
Most Homebrew works.

# Features
- CPU GPU Turbo - give games additional computation power
- Orientation: rotate video by 90 or 270 degree
- ComLynx using USERIO
- Multi Lynx mode with two, three, or four internal cores connected over ComLynx
- ComLynx

# Multi Lynx
Load a ROM normally to run the same cartridge image on all active Lynx instances.
Use the OSD option "Lynx instances" to select 2, 3, or 4 linked systems. Horizontal games use side-by-side screens for two instances and a 2x2 grid for three or four. Vertical games use side-by-side screens for two instances and a 1x4 portrait strip for three or four.

# Refresh Rate
Lynx uses custom refresh rates from ~50Hz up to ~79Hz.
Some games switch between different modes.
To compensate you can either:
- live with tearing
- Sync core to 60Hz: Run core at exact 60Hz output rate, no matter what internal speed is used

# Rotation
Lynx has built in rotation, supported by most games, using the Joypad Keys "Option2" + "Pause"

# Missing features
Custom external EEPROM not supported(not used in official games, only homebrew)

# ComLynx
Uses USER_IO[0] for the data line.