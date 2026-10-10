# FM Towns Marty for MiSTer

The FM Towns was a semi-popular Japanese computer line from the early to mid 90s, mostly known for a lot of arcade ports. The notable feature of this computer system was that it always included a CDROM drive. Because the majority of games were discs and booted directly, Fujitsu decided to consolize it into the FM Towns Marty console. It was a phenominal flop because the video output was poor and the RAM and CPU speed limited the number of games it could play. This core is a recreation of that console.

## Why Marty?

This is generally the first question any FM Towns enthusiast asks. It's known to have compatibility problems, performance problems, and other things that make it less than desireable. It used a 386SX-16mhz cpu rather than the 386DX-16 CPU the older desktop models, with faster ram to make up for the 16 bit bus (vs 32 bit). The reason I chose Marty rather than computer itself isn't one thing, but rather a combination of things:

- A BIOS and system made for consolized behavior is more idomatic to the MiSTer platform, where a lot of people don't have a full computer setup.
- The 16 bit bus is easier to deal with the memory constraints MiSTer has, and ironically can scale a little better because of this.
- Most of the things that made Marty undesireable originally can be addressed with optional enhancements.

So you could see this core as a "Marty Plus". It runs at the original speed with the original hardware configuration of the Marty, but also optionally can do several things that make up for Marty's original shortcomings. The Floppy drives can be expanded to 2, the RAM can be expanded to 6mb, and the 386 cpu can have an optional (very large) instruction cache enabled and clocked up to 25mhz, making it on par with the performance of 486 systems. These things together make the vast majority of the Towns library comfortably playable.

The 386 cpu allows for the system to run at accurate speeds, where using a 486 would not, and there is no room for both. In this core design, the memory bandwidth is actually a much larger constraint than the cpu instruction speed, so I suspect the gains would not be substantially different than just using the anachronistic instruction cache, anyway.

## Setup

The games folder for this core is `Marty`. In this folder you can place all CD's, HDDs, and FDD images, as well as the bios and game database.

### BIOS

The two BIOS files required are `mrom.m36` and `mrom.m37`. They do not need to be renamed, they will get seen as is.

### Database

The file marty_db.tsv contains a database of game entries, and optionally will automatically adjust the system's speed, RAM, and inputs to the current game's needs. It goes in the base of the `Marty` folder beside the BIOS.

### File Organization

CD's image files should be placed in their own folder, similar to other CD-based cores. Several games for this system require either a boot diskette to start, or a blank diskette to run properly and save. If you put a diskette image in the same folder as the CD and name it the same as the cd's .cue or .chd or .iso file, the core will optionally automatically mount this diskette for you. If you append `_1` to that filename, it will mount in the second FDD drive instead. There also exists bootable Towns System Software CDs images where you can load a diskette, launch from the GUI and avoid the renaming procedure. Some popular sets of CD images do not come with any boot diskettes, so you will have to find them elsewhere.

If you have the database enabled, the core will automatically create and mount a blank floppy for you when the cd requires it.

### MIDI

MT32-pi is supported over USER I/O port. To use MIDI you must enable the FMT-40x MIDI card in System Options.

## Special thanks

Special thanks to nand2mario for the z386 CPU core used here. It's based off real 386 microcode and also came along with a substantial.

Also thank you to the testers in Discord who helped me so much to test and debug this huge game library!
