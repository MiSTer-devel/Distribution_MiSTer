# NGPC MiSTer

This core is pretty straightforward. It's a recreation of the NeoGeo Pocket Color handheld. It supports the Mono version as well.

## Setup
- Games and bios files go in the NGPC folder.
- boot0.rom should be the COLOR BIOS.
- boot1.rom should be the MONO BIOS.

## Link Cable
The `Serial Route` menu option selects the link-cable transport:

- `Internal` uses MiSTer's HPS UART at 19200 baud.
- `SNAC` connects the native link signals directly to the USERIO vector pins:
  `USER_IO[1]` RX, `USER_IO[2]` TX, `USER_IO[4]` CTS, and `USER_IO[6]` RTS..

That's it! Have Fun!

## Development
- This core was made with AI. I let AI do most of the work on this one while I kept it drawing inside the lines and spent my time doing heavy debugging.

## QA
- This core passes all the cpu benchmark tests, including the 10 I made to characterize and and implement the cpu accurately.
- All ROMs and known homebrew was tested and compared to real system behavior. Stringent comparison of every flicker, line, tear, and stray pixel I could find. It reproduces them all faithfully.
- I did repeated audits of all components against reference material.
- Community testing for a week.

The result is it seems to be more accurate in speed and behavior than any other emulator that I am aware of in meaningful ways, by a significant margin too.

