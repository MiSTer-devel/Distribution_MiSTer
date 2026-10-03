# Arduboy_MiSTer

Arduboy core for MiSTer, ported by Dan O'Shea and based on Iulian Gheorghiu's atmega core:

https://github.com/MorgothCreator/atmega-xmega-soft-core

## Loading games

Games can be loaded from anywhere on the SD card, but are most conveniently kept in
`/media/fat/games/Arduboy`. Both Intel HEX (`.hex`) and raw binary (`.bin`) files load
directly - no conversion needed.

A collection of `.bin` files converted and tested so far can be found here (you can hit the
green 'Clone or download' button, and then 'Download ZIP' to get them all at once):

https://github.com/uXeBoy/ArduboyCollection

If you prefer to convert `.hex` to `.bin` yourself, use hex2bin with the command line option
`-l 8000` to pad the file out to 32K:

https://sourceforge.net/projects/hex2bin/

The core boots with Arduventure built in, so it will run without loading anything.

## Options

**Orientation** - `Horizontal` / `Vertical`. Rotates the display for games designed to be
played with the Arduboy held on its side; the D-pad is remapped to match.

**Aspect ratio** - `Original` / `Full Screen`, plus the two user-defined MiSTer ratios.

**Scandoubler Fx** - `None` / `HQ2x` / `CRT 25%` / `CRT 50%` / `CRT 75%`.

**ADC** - `Random` / `AnalogStick` / `Paddle`. Selects what feeds the ATmega's analog input.
`Random` leaves it unconnected, which is what most games expect. Choose one of the others only
for games that actually read the ADC as a control.

### Custom palette

The Arduboy display is 1-bit: every pixel is either lit or unlit. By default the core renders
that as white on black, but it can be colorized instead.

**Custom Palette** - `Off` / `On`. Turning it on reveals the two options below.

**Load Palette** - loads a `.gbp` palette file. As with games these can live anywhere on the SD
card, but are most conveniently kept in `/media/fat/games/Arduboy/Palettes`. The first color in
the file becomes the lit (foreground) color and the fourth becomes the unlit (background) color.
Loading a palette does not reset the running game, so palettes can be auditioned while playing.

**Palette Colors** - `Normal` / `Swapped`. Exchanges the foreground and background colors.
Because a set pixel means different things in different games - some titles draw light artwork
on a dark field, others the reverse - a single fixed assignment cannot suit every game. Leave
this on `Normal` unless a palette comes out inverted.

With Custom Palette on and no file loaded, the default is the stock white on black, so
`Swapped` alone gives black on white.

## Controls

| Arduboy | MiSTer |
|---------|--------|
| D-pad   | D-pad / stick |
| A       | Button 1 |
| B       | Button 2 |

The RGB LED is mapped to the MiSTer board LEDs.

## TODO

Work on more complete sound support, look at making EEPROM non-volatile, improve stability
(some games will randomly reset, or not run at all), pull requests / improvements welcome!
