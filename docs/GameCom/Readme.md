# Game.com core for MiSTer

## Overview
This is a core for the much reviled Tiger Game.Com. The system came out in 1997 as a competitor to the Nintendo Gameboy. Tiger managed to license ports of several noteworthy franchises such as Resident Evil 2, Castlevania Symphony of the Night, and Duke Nukem 3D, however the system's poor specs and lackluster screen led to it being a colossal failure. The initial model of this device had two cart slots. They could be populated by two games, but the intention seems to have been that one of the carts would be an "internet" cart that eventually would have allowed for connected gameplay. This never materialized and later revisions of the hardware dropped the second cart slot.

## Setup
This core requires the Game.Com *external* BIOS renamed to boot.rom and placed in the GameCom game folder, similar to many other system boot roms. The *internal* BIOS is not needed for this core. The Game.Com uses a fixed block of system memory for saves, similar to a memory card. For this, you must supply a blank 8KB `boot1.vhd` file in your GameCom games folder.

## Save States
Save states are supported, but because of MiSTer framework restrictions they are only supported for the game loaded in cart slot 1. It's best to use this for all your primary gaming. The second slot mostly exists for system accuracy and novelty.

## Internet Connectivity
Internet connectivity is supported. Set the UART to Modem, 9600 baud, using the 'custom carrier' option in the Tiger.com Internet Cart (not Delphi). You may create a MidiLink.DIR file in your MiSTer's linux folder and create an entry like `2223334444=192.168.1.100:23` to associate a phone number to an IP address. There isn't much practical use in this, but given that .com was the console's namesake it seemed like it was the least I could do.

## Development
This core was the first one in which I attempted to integrate AI into my workflow. For me it was very much a learning exercise into how best to use AI to improve the quality and speed of the results with a minimal loss to code quality. Ultimately, I found the best way to handle this particular core was to lay out skeletons of code and have AI fill them in a bit like a color-by-numbers book, then hand-review the issues and results. In particular using it to generate a ghidra plugin for the very unusual cpu in this system and disassemble things to learn about a lot of the undocumented system behaviors was extremely useful. That said, various hardware comparisons and tests were run to ensure that the resulting core is as close to real thing as I can get it with what we know. The speed, audio, and display are all pretty faithful, warts and all.
