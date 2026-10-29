# Super A'Can

The super A'Can was a largely forgotten console made in Taiwan in the mid 90's. Unlike most chinese consoles, this one was not intended to be a clone or knockoff, but rather an ernest attempt at making a real console for chinese speakers. Unfortunately, it was released as a powerful, well made 4th gen console in an era where consoles such as Playstation were being released, and for less money. Consequently, the A'can failed fast and hard.

The library for this system was all in traditional chinese, and most of them are fairly well made conceptual copies of popular games for other systems. That said, several are very playable and have quite a bit of charm. The extreme rarity of this console plus the language barrier have been an challenge for emulator progress.

I've created english translation patches for most of the game's library here: <https://www.github.com/kitrinx/ACan>.

## Setup

This console requires four BIOS files. Copy them to `games/SuperAcan/` on the MiSTer using the names in the last column.

| Original file       | Contents         | Size  | CRC32      | MiSTer name |
|---------------------|------------------|-------|------------|-------------|
| internal_68k.bin    | 68000 IPL        | 4 KB  | `8d575662` | boot0.rom   |
| internal_6502_1.bin | 6502 ROM (low)   | 8 KB  | `fc9fb05f` | boot1.rom   |
| internal_6502_2.bin | 6502 ROM (high)  | 8 KB  | `bf950ab7` | boot2.rom   |
| umc6650.bin         | UM6650 key       | 16 B  | `0ba78597` | boot3.rom   |

## Development and QA

The console costs thousands of dollars, and there is no flash cart for it. Some existing reverse engineering was done however, and a set of high quality real hardware videos of deterministic game attract screens was put on youtube by Diskman. Because the 68000 and 6502 CPU are already well known, we already were starting from a good place. Those videos, coupled with diassemblies of the whole game library, was enough to reverse engineer a significant amount of UMC's ASIC behaviors, enough the play the entire game library (apparently) bug free and accurately.