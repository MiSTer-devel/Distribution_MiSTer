# Casio Loopy MiSTer

The Casio Loopy, the world's cutest game console. This core supports save states and all the games in the library. Magical Shop will run, but does not support composite input because, well, there is no way to input composite video. Stickers can print to a preview windows, but there isn't a way to save them.

## BIOS files

Two system ROMs load automatically at start. Put them in `games/Loopy/`:

| File on MiSTer | ROM | Chip | Size | CRC32 |
|---|---|---|---|---|
| `boot0.rom` | Loopy BIOS (`hd6437021.lsi302`) | SH7021 internal mask ROM | 32 KB | `8C57FF9F` |
| `boot1.rom` | Synth wave ROM (`hn62434fa.lsi352`) | HN62434 | 512 KB | `8F51FA17` |

`boot1.rom` is the file some sets name `[BIOS] Internal Thermal Printer (Japan).bin`.
The MSM6653 speech ROM is regenerated from samples, and is built into the core so needs no file.

## Development and QA

This is a pretty well documented system, so it wasn't too hard to build it against existing reference materials. I would have liked a more robust test harness for the SH1 but I think it's pretty good regardless. One thing is worth noting: the SDRAM is not quite fast enough to represent the DRAM of this system. I used a page mode sdram controller along with a pretty elaborate caching system to get it almost up to par, but occasional sdram refresh collisions will make the system have to hold for a cycle. Consequently the system can run up to about 1.5% too slow in some circumstances. Given the nature of this system's library, that really shouldn't be a problem for anyone, but it's worth mentioning.