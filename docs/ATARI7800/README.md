# Atari7800 for MiSTer.

## Features
- Runs complete Atari 7800 retail library.
- Supports NTSC and PAL regions.
- Supports High Score Cart saving.
- Supports Light Guns, Trakballs, Mice, Quadtari, and Paddles.
- XEGS Keyboard support via POKEY at $450 or $4000.
- Dual Pokey audio.
- YM2151 Audio using Jotego's JT51.
- Supports Covox.
- Support for XM and XBoard modules.
- Supports Activision, Absolute, Souper, and Supergame mappers up to 1mb.
- Choice of Cool, Warm, or Hot system temperature color output.

## Setup
Not much setup is required, but you may optionally put a system bios as `boot0.rom` in your Atari7800 ROMs folder to use before loading a game. It may increase compatibility in some rare cases if used. This core does rely on properly configured Atari7800 headers as detailed [here](http://7800.8bitdev.org/index.php/A78_Header_Specification). Using Trebors 7800 ROM PROPack is recommended as this is a reliable source of correctly headered ROMs.

## 2600 Support
Most 2600 games are supported including most bankswitching schemes, with a few exceptions. ARM based mappers, such as DPC+ require a 70mhz ARM cpu, which would be either very difficult, or impossible, to have run properly on the cyclone V that MiSTer FPGA uses. To make the experience better, an Out of Order screen will be shown when one of these games using modern hardware is loaded. A few more eccentric peripherals are also not supported simply due to lack of any practical purpose, but anyone is welcome to add them someday if there's some need. This includes the Compumate and the Gameline peripherals. That said, the following bankswitching is supported: F8, F6, FE, E0, 3F, F4, P2, FA, CV, 2K, UA, E7, F0, 32, AR, 3E, SB, WD (8k dump), and EF. Bankswitching will now auto-detect the correct type, and does not require special extensions.

## Paddles
The paddle peripheral is mostly used in 2600 games and has special handling surrounding it because of its unusual 2-paddles-per-port configuration. Three types of inputs are supported for paddles: analog sticks, mice, and mr. spinner compatible joystick adapters. It's important to note that PADDLES HAVE A DEDICATED FIRE BUTTON in this core, and it must be set in order to use the paddles properly. Because there are four paddles and two controllers ports, and a myriad of input devices, paddles are assigned independently of joysticks. Every time a game is cold reset, paddles are re-assigned. The core will assign paddles in order, when a port has paddles enabled. The various devices are recognised under these conditions:

- Mice when you click the left button.
- Analog sticks when you move either the Y axis or X axis to an extreme (make sure to assign analog x/y in the main mapping).
- Mr. Spinner devices when they are moved to an extreme position.

Please note that some games do not use paddle 1A for their input, some exceptions are:

- Astroblast: Uses 1B.
- Tac Scan: Uses 2B.
- Demons to Diamonds: Uses 1B.

To make dealing with this easier, there is an option to swap paddles A and B of either port, so that 1A will become 1B and vice versa. Additionally, if the input type is set to "auto" with 2600 games, pressing the fire button will toggle the input into Joystick mode, and pressing the paddle button will toggle the input into Paddle mode, for convenience.

## Keyboard shortcuts
- F1 Select
- F2 Start
- F3 B/W toggle switch
- F4 Difficulty Left toggle switch A/B
- F5 Difficulty Right toggle switch A/B
- F6 Pause

## Additional Notes
Some games use the [difficulty switches](https://atariage.com/forums/topic/235913-atari-7800-difficulty-switches-guide/) to control their behavior, most notably Tower Toppler, which will continue to skip levels if the switches are in the "low" position. Tower Toppler also relies on composite blending artifacts to look correct, so it may be worthwhile to enable that for this game. The 7800 had issues with color consistency depending on the temperature of the system. Not all games may look ideal with the warm palette, so you may have to experiment per game to find the ideal colors.

## Known Bugs
- Expansion ram of XM module is not fully implemented because I couldnt find anything that used it.
- YM Auto detection appears to fail because of an edge-case detection routine.
- BupChip music chip is not implemented because it runs on a modern microcontroller.

## Special Thanks
- Mike Saarna for his enormous knowledge of the system and patient help.
- Osman Celimli for his DMA timing traces and experience.
- Robert Tuccitto for the extensive palette information.
- Remowilliams for testing a zillion games for me on real hardware.
- Alan Steremberg for getting access to valuable documentation.
