# Emerson Arcadia 2001 game console

## General description
This core implements a game console with Signetics 2650 CPU and 2637 Video controller.
This chipset was used in many game consoles such as the systems listed below.

## Emerson-Compatible Family
These systems are fully compatible with the standard Emerson Arcadia 2001 cartridges.

- Arcadia 2001 (Emerson Electronics, USA/Australia)
- Home Arcade (Advision, France)
- Arcadia (Bandai Electronics, Japan) - Featured 4 exclusive Japanese titles.
- Tele-Computer (Cosmos, Spain)
- Home Arcade Centre (Hanimex, UK)
- HMG-2650 (Hanimex, Germany/Australia/Canada)
- Ch-50 Home Entertainment Centre (Inno-Hit, Italy)
- Tele-Computer XL 2000 (Intercord, Germany)
- Leisure-Vision (Leisure-Dynamics, Canada)
- Leonardo (GiG Electronics, Italy) - Featured the most rare, 3D Attack.
- TVG-2000 (Schmid, Germany)
- Tele-Fever (Tchibo/Eduscho, Germany)
- Tunix Home Arcade (Monaco Leisure, New Zealand/Australia) 

## MPT-03 Family
These variants often used the "MPT-03" designation and may have slight BIOS differences
or cartridge shell variations, though the internal architecture is identical.

- Dynavision (Morning-Sun Commerce, Japan)
- Educat (Israel)
- Ekusera (P.I.C, Japan)
- MPT-03 (Hanimex, France; Tempest, Australia)
- Intelligent Game MPT-03 (USA/Canada)
- ITMC MPT-03 (France)
- Poppy MPT-03 (Germany)
- Prestige Video Computer Game (Germany)
- Robdajet MPT-03 (Switzerland)
- Rowtron 2000 (UK)
- Soundic MPT-03 (France/Finland)
- Tobby MPT-03 (Unknown region)
- Video Game Center (Tryom, USA) 

## Other Compatibility Groups
Several other branding families existed with minor hardware or casing revisions, 
often limiting direct cartridge compatibility without modification.

- Ormatu Group: Included the Ormatu 2001 (Netherlands), Intervision 2001/3001 (Switzerland),
  and Sheen 2001 (Australia). 
- Palladium Group: Included the Palladium Video-Computer-Game (Neckermann, Germany),
  Polybrain (Germany), Mr.  Altus (HGS Electronic, Germany), and Trakton (Australia). 
- Orbit Group: Included the UVI Compu-Game and Video Master (Grandstand), 
  primarily found in New Zealand and Australia. 

The list may not be 100% accurate or complete.  Corrections are appreciated.

## Controls

The Arcadia handheld controller has 18 inputs: a 4-directional disc, two action buttons,
and a 12-button keypad (0-9, Enter, Clear). Combined with Start, Select, and Option
on the console, the core maps 21 total inputs. Analog control is supported on the right
stick. D-pad can also emulate analog input, in either auto-centering or non-auto-centering
modes. Non-auto-centering works well for Circus, auto-centering works well for Ocean Battle.
Those are the only two known games that support analog.

### Button Mapping

A standard gamepad can cover the first eight buttons; the keypad is best handled
via the keyboard hybrid described below.

Recommended mapping:

| Arcadia    | MiSTer Suggested | NTT Data (via Raphnet) | HID |
|------------|------------------|------------------------|-----|
| Disc Up    | D-Pad Up         | D-Pad Up               | hat |
| Disc Down  | D-Pad Down       | D-Pad Down             | hat |
| Disc Left  | D-Pad Left       | D-Pad Left             | hat |
| Disc Right | D-Pad Right      | D-Pad Right            | hat |
| Action     | A / South        | B                      | b1  |
| Action 2   | B / East         | A                      | b4  |
| Start      | Start            | . (keypad)             | b20 |
| Select     | Select           | Prev Page              | b3  |
| Option     | X / North        | Next Page              | b2  |
| Enter      | R / Right Bumper | C (keypad)             | b21 |
| Clear      | L / Left Bumper  | * (keypad)             | b18 |
| 0          | Y / West         | 0 (keypad)             | b8  |
| 1          | (keyboard)       | 1 (keypad)             | b9  |
| 2          | (keyboard)       | 2 (keypad)             | b10 |
| 3          | (keyboard)       | 3 (keypad)             | b11 |
| 4          | (keyboard)       | 4 (keypad)             | b12 |
| 5          | (keyboard)       | 5 (keypad)             | b13 |
| 6          | (keyboard)       | 6 (keypad)             | b14 |
| 7          | (keyboard)       | 7 (keypad)             | b15 |
| 8          | (keyboard)       | 8 (keypad)             | b16 |
| 9          | (keyboard)       | 9 (keypad)             | b17 |

Full remapping is available in the MiSTer menu under "Define Arcadia buttons."
A hybrid setup with keyboard for the keypad plus a gamepad for the stick works well.
Keyboard keys are mapped to the controller keypad, so a standard gamepad without a
keypad can still play all games. This is the inverse of the Odyssey² core, which maps
the console keyboard to controller buttons.

### Keyboard Keypad Mapping

| Keypad | P1 Keyboard | P2 Keyboard |
|--------|-------------|-------------|
| 1      | 1           | 8           |
| 2      | 2           | 9           |
| 3      | 3           | 0           |
| 4      | Q           | I           |
| 5      | W           | O           |
| 6      | E           | P           |
| 7      | A           | K           |
| 8      | S           | L           |
| 9      | D           | ;           |
| 0      | X           | ,           |
| Enter  | C           | .           |
| Clear  | Z           | /           |

### Auto Controller Swap

Swaps player 1 and player 2 inputs including keypad and analog routing. Useful for games
where the "wrong" controller is player 1, or when using a single controller for
alternating two-player games.

Since P1 maps to the Left controller and P2 maps to the right, and some games
had this reversed, the core auto swaps 20 ROM variants across 12 distinct games
(plus overdumps and enhanced revisions) detected by CRC32.

- 3D Soccer
- Crazy Climber
- Crazy Gobbler
- Funky Fish
- Hobo
- Jump Bug
- R2D Tank
- Red Clash
- Space Attack/Space War
- Spiders
- The End
- Turtles/Turpin

### Auto XY-Swap

Ten ROM variants across six games have their correct X/Y orientation detected
automatically by CRC32.

- 3D Soccer
- Funky Fish
- Jump Bug
- Spiders
- The End
- Turtles/Turpin

### Pause on OSD

When enabled, opening the MiSTer menu freezes the CPU and silences audio output
Leave Off when adjusting video settings that need a live picture.

## Known Issues

- **3D Attack** doesn't boot properly
- **3D Soccer:** graphics corruption
- **Alien Invaders:** graphic corruption, missile launcher is forced to the right.
- **Basketball:** This game just controls very weird, not a glitch.
- **Black Jack & Poker:** doesn't boot properly
- **Circus:** requires analog stick input or D-pad emulation
- **Crazy Climber:** Missing audio. Graphical issues.
- **Doraemon:** appears to lock up at the playfield load
- **Dr. Slump:** graphics corruption, locks up
- **Escape:** doesn't play right
- **Frogger:** graphics corruption - a known ROM issue
- **Funky Fish:** locks up
- **Golf:** unable to start
- **Grand Slam Tennis:** graphics corruption, unable to start
- **Hobo:** locks up
- **Horse Racing:** unable to start game
- **Mobile Soldier Gundam:** graphics corruption, can't start play
- **Monaco Grand Prix:** controls are just weird, not a glitch
- **Ocean Battle:** analog input supported for ships dropping depth charges
- **Robot Killer:** unable to control properly
- **Route 16:** game doesn't start
- **Star Chess:** graphics corruption
- **Super Dimension Fortress Macross:** doesn't boot properly.
- **Turtles:** Missing energy bar which indicates bomb availability.

Unknown issues may exist. Please refer to known working behavior when reporting bugs.

## Changelog 20260816

- Changed P2 keymapping to not interfere with numpad as joystick

## Changelog 20260811

- Analog input emulation now available
- P2 Keyboard buttons fixed. Note that they overlap with the numpad as joystick,
  but that isn't working anyway.  If numpad as joystick is fixed, they should be moved
  to different keys, recommended: 8, 9, 0, I, O, P, K, L, ;, comma, period, /.

## Changelog 20260803

- Hardcoded correct stick routing: left stick = P1, right stick = P2 for all games.
- Fixed controller swap to properly route d-pad and analog inputs.
- Added pause-on-OSD with menu toggle.
- Added keyboard-to-keypad hybrid input for players 1 and 2.
- Auto XY-swap via CRC32 detection table; manual toggle remains as override.
- Auto controller swap via CRC32 detection table; manual toggle remains as override.
- Framework updates for current MiSTer sys.
