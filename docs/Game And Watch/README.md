# Game and Watch for MiSTer

This core is an original creation by [@agg23](https://github.com/agg23). It is based strongly on the original documentation for the Game and Watch CPU (see [Documentation Overview](docs/overview.md)), but additional supported CPUs in the core (like the SM5a) are based entirely on MAME's implementation. I have tried to accurately transcribe and rewrite the existing documentation and MAME's code into a more understandable, fewer error form. See [Licensing](#licensing) for more information.

This split is focused on the MiSTer version of the core, assisted by Codex. The active project follows the MiSTer template layout: `sys/` is the untouched MiSTer framework, `rtl/` is the core RTL, `GameAndWatch.sv` is the framework glue, and `files.qip` is the manually maintained Quartus source list.

## Building for MiSTer

Use Quartus 17.0.x, matching the upstream MiSTer template recommendation:

```sh
quartus_sh --flow compile GameAndWatch.qpf
```

Release RBFs should be placed in `releases/` with MiSTer naming:

```text
GameAndWatch_YYYYMMDD.rbf
```

Migration details and verification notes were written by Codex are documented in [docs/mister_migration.md](docs/mister_migration.md).

## Installation Instructions

See [Platform Installation Instructions](docs/platform_installation.md) for platform-specific instructions on how to install the core.

## Generating ROMs

MiSTer loads `.gnw` ROM packages through the OSD. The ROM generator source and manifest extractor live in [rom generator/](rom%20generator/); full usage notes are in [docs/rom_generator.md](docs/rom_generator.md).

## Supported Systems

The Game and Watch (and related) series of devices used varied hardware for each device. The currently supported CPUs are:
* SM510 - The "base" CPU the other's were based off of - Donkey Kong, Fire Attack, Mickey and Donald, etc
* SM511 - Later Game & Watch titles with a dedicated melody ROM - Super Mario Bros., Climber, Balloon Fight, etc
* SM512 - Later Multi Screen titles with an added C segment group - Black Jack, Bomb Sweeper, Gold Cliff, Zelda, etc
* SM510 (Tiger Variant) - Experimental - Street Fighter 2, Double Dragon, etc
* SM5a - Ball, Octopus, etc

The [ROM Generator](docs/rom_generator.md) will read the attached `manifest.json` file to determine what CPU is used by each game. You can manually look through this file yourself, or use the generator tool to determine if a game is supported at this time.


### Input Limitations

The MiSTer core is built around the controller mapping shown in the OSD. Games whose original hardware depends on a keyboard or calculator-style keypad matrix are not currently supported, even if the CPU and ROM package load correctly. These packages may boot, play sound, or show static artwork but will not be playable until a preservation-friendly input mapping is designed.

### Homebrew

For homebrew titles (I only know of [Bride and Squeeze](https://forums.atariage.com/topic/282578-two-new-homebrew-lcd-games-game-watch/)), you should rename the artwork and roms zips to have the `hbw_` prefix, and the name of the game. Thus Bride becomes `hbw_bride` and Squeeze becomes `hbw_squeeze`.

Squeeze does not run correctly due to having a completely different artwork design than any other core. [See #11 for more information](https://github.com/agg23/fpga-gameandwatch/issues/11#issuecomment-1614828078).

## Features

* 720 x 720 pixel resolution
* Ability to show inactive LCD segments with configurable opacity
* Deflicker on the LCD
* VSync after the deflicker has taken place

## Settings

* `Show Inactive LCD` - LCD segments that are inactive (off) remain displayed. See `Inact. LCD Alpha`
* `Inact. LCD Alpha` - `Inactive LCD Alpha` - If `Show Inactive LCD` is on (or this setting is set on MiSTer), sets the opacity of the disabled segments. Defaults to approximately 5%, or 13/255.
* `Acc. LCD Timing` - `Accurate LCD timing` - By default, the Game and Watch's LCD pulses at 64hz, which is what drives the static LCD screen. However, due to lack of persistence of our modern LCDs, this just results in a bunch of flicker. Instead when this setting is disabled, the LCD data will be updated at 1000 Hz. Enabling this setting updates the LCD at 64 Hz.

## Core Docs

I've tried to be thorough with my design decisions and provide/update various supporting documents through the process. See the `/docs` folder, or start looking at the [Overview](docs/overview.md).

## Licensing

There are a lot of components to this project, and the licensing on them depends on where they came from and potentially how they're used.

| Contents                                                                                                                              | License |
| ------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| Main Game and Watch core RTL and documentation (other than the original docs owned by Sharp)                                          | MIT     |
| MiSTer framework files in `sys/`                                                                                                       | Upstream MiSTer template license/source headers |
| MiSTer glue in `GameAndWatch.sv`                                                                                                       | GPLv3   |
| Vendored SDRAM controller in `rtl/vendor/sdram-controller/`                                                                            | MIT     |
