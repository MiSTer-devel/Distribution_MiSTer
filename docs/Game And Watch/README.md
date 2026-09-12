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

Migration details and verification notes are documented in [docs/mister_migration.md](docs/mister_migration.md).

The current source uses a dedicated 54.000 MHz `CLK_VIDEO` and emits an actual
360x240 analog-facing raster at a 6.750 MHz `CE_PIXEL` cadence. CRT sync,
blanking, DE, and its 429x262 raster continue through packet-FIFO
search/recovery; only unavailable RGB is blacked. The output transport requests
each CRT source pixel and holds a recovered source SOF until the next local
frame boundary, so the two clock domains cannot resume at mismatched raster
coordinates.

The current release-style artifact is `output_files/GameAndWatch.rbf`:
3,494,544 bytes, SHA-256
`16E14B86EBA8C9422F9C6F9E966BA5C01627659193D6EDD7070912B556DBEF6F`.
Normal builds leave `CORE_ENABLE_DEBUG_OVERLAY` undefined, removing the debug
menu entries, capture state, and pixel grid. The transport/CDC audit is clean.
The 98.3203125 MHz core domain is within the project's accepted one-nanosecond
floor at `-0.401 ns` worst setup slack and `-0.587 ns` TNS, although this is not
strict zero-slack timing closure.

Native output remains exactly 32.768 MHz and approximately 59.375 Hz. Its
internal packet producer runs at 32.7734375 MHz and is paused between FIFO
occupancy thresholds 768 and 640, providing elasticity without changing the
visible raster. A USB-2 Star Fox smoke test captured 60 one-second-spaced
720x720 frames: the first was the normal startup transition and frames 1-59
were byte-identical, with no partial or black frames. The saved CFG and prior
core were restored afterward. Morph/analog lock and audible sound quality
remain user-observed hardware checks.

## Installation Instructions

See [Platform Installation Instructions](docs/platform_installation.md) for platform-specific instructions on how to install the core.

## Generating ROMs

MiSTer loads `.gnw` ROM packages through the OSD. The ROM generator source and manifest extractor live in [rom generator/](rom%20generator/); full usage notes are in [docs/rom_generator.md](docs/rom_generator.md). Current packages contain native artwork and LCD-mask payloads for both the default CRT-friendly `360x240` mode and the selectable `720x720` mode. The regenerated 168-package set has passed full-directory validation and is present in the repository `roms/` baseline.

## Supported Systems

The Game and Watch (and related) series used several CPU variants. The currently supported CPUs are:

- SM510 - the base CPU used by Donkey Kong, Fire Attack, Mickey and Donald, and others
- SM511 - later Game & Watch titles with a dedicated melody ROM, including Super Mario Bros., Climber, and Balloon Fight
- SM512 - later Multi Screen titles with an added C segment group, including Black Jack, Bomb Sweeper, Gold Cliff, and Zelda
- SM530 - Nelsonic Game Watch titles with SM500-style LCD outputs and a dedicated melody ROM, including Super Mario Bros. 3, Super Mario World, and Star Fox
- SM510 Tiger variant - Street Fighter II, Double Dragon, and others
- SM511 Tiger 1-bit and 2-bit variants - later Tiger melody/sound hardware
- SM5a - Ball, Octopus, and others

The [ROM Generator](docs/rom_generator.md) will read the attached `manifest.json` file to determine what CPU is used by each game. You can manually look through this file yourself, or use the generator tool to determine if a game is supported at this time.


### Input Limitations

The 168-title MAME 0.289-derived supported set, including two retained homebrew entries, fits a four-direction D-pad plus ten buttons. The package selects the appropriate meaning for each stable MiSTer position:

| Physical position | Package-selected function |
| --- | --- |
| D-pad | Main/left joystick directions |
| Buttons 1-4 | Buttons 1-4 or right joystick Down/Right/Left/Up |
| System 1 | Time / Pause / Status |
| System 2 | Alarm |
| System 3 | Game A / Power On |
| System 4 | Game B / Power Off |
| System 5 | Sound / Minute |
| System 6 | ACL (All Clear) |

These pairings are mutually exclusive within every supported package; the largest games occupy nine of the ten buttons. The first eight button positions retain their legacy order, while Sound/Minute and ACL are appended and require an explicit controller binding. Input is suppressed while the MiSTer OSD is open.

Games whose original hardware depends on a keyboard, calculator-style keypad matrix, or dial are not currently supported. The Micro Vs. titles `gnw_boxing`, `gnw_dkong3`, and `gnw_dkhockey` carry per-input player ownership in current packages and use MiSTer's independent player-one and player-two controller buses. Older packages without that metadata retain their legacy one-controller behavior.

### Homebrew

For homebrew titles (I only know of [Bride and Squeeze](https://forums.atariage.com/topic/282578-two-new-homebrew-lcd-games-game-watch/)), you should rename the artwork and roms zips to have the `hbw_` prefix, and the name of the game. Thus Bride becomes `hbw_bride` and Squeeze becomes `hbw_squeeze`.

Squeeze does not run correctly due to having a completely different artwork design than any other core. [See #11 for more information](https://github.com/agg23/fpga-gameandwatch/issues/11#issuecomment-1614828078).

## Features

* CRT-friendly `360x240` native video by default, with live switching to `720x720`
* Generator-native artwork and LCD masks for both resolutions in each current package
* Independent two-player controls for Boxing, Donkey Kong 3, and Donkey Kong Hockey
* Trace-matched HA1152/HMC sound effects for Nelsonic Star Fox using its dumped 128-byte effect ROM
* Package-declared default-on music for Nelsonic Super Mario Bros. 3, with a global Audio mute
* Sample-backed MSM6373 voice support for Star Trek, Teenage Mutant Ninja Turtles II, and Top Gun
* Ability to show inactive LCD segments with configurable opacity
* Deflicker on the LCD
* VSync after the deflicker has taken place

## Settings

* `Native Video` - selects `360x240 CRT` (the default 4:3 presentation) or `720x720` (1:1). Current dual-resolution packages switch image and LCD-mask banks with the timing mode; older packages use a compatibility bridge in CRT mode.
* `Inact. LCD Alpha` - sets the opacity of inactive LCD segments from Off (the default) through 100%.
* `Acc. LCD Timing` - uses the original 64 Hz LCD update behavior when enabled. The default 1 kHz update avoids visible flicker on modern displays.
* `Audio` - leaves game audio on by default or mutes the final core output without changing emulated sound state.

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
