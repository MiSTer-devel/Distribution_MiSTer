# Jaguar_MiSTer

Atari Jaguar FPGA core, written by Torlus.

Initial attempt to port to MiSTer by ElectronAsh and Kitrinx.

The proper Jag BIOS is now being used. If a cart is failing the checksum, a patch can skip the failure by selecting it in the menu. Testing was done with the M version of the BIOS.

The BIOS file (usually "jagboot.rom") should be renamed to boot.rom or boot0.rom, then copied into the Jaguar folder on the SD card. Supports K and M versions as well as Kitrinx's modified version.

The CD BIOS must be loaded manually or automatically When using CDs (including VLM). The CD BIOS can be auto-loaded if named boot1.rom in the Jaguar folder. Can also use Kitrinx's modified version.

The Memory Track cart is now supported. The ROM from the cart can be auto-loaded by naming it boot2.rom in the Jagaur folder.

To enable global saves select corresponding files (for the CD eeprom and the memorytrack cart) from the OSD to select where they are saved. Blank eeprom.jce and memorytrack.jcm files are included in the release directory but still must be selected from the OSD at least once.

The controls for player 1 and 2 are now hooked up to MiSTer.

The core is now using SDRAM for cart loading and for main RAM as well as BIOSes and memtrack save data. So SDRAM is *required*.

The latency of SDRAM is a bit too high for more games to run cycle acurately with only one SDRAM module.

All known games now appear to work correctly with dual ram builds. For single ram builds all boot, some with glitches or slow down, and others that might crash to a black screen (but often the game keeps running).
 
The older j68 CPU core was replaced with FX68K, which is claimed to be cycle-accurate. This has now been replaced with nuked's 68k core. The fx68k can be built by using a define, but differences in FC signals will cause inaccuracies including memtrack checksums to fail.

Turbo is currently not available.

If a game doesn't work try turning on max compatibility, homebrew support or loading more than once.

Jaglink over SNAC works. Rx is on User In 2 and Tx is on User Out 1.

Cheat codes work.

Remaining tasks (No guarantees to complete)
- DSP sometimes does not come up correctly even after reboot (not sure if still occurs)
- Quality of life improvements
- Other CD formats beside cdi (cue/bin, chd - not sure if this is possible as it requires multi-session)
- Single RAM improvement? Not sure if further improvement possible. Maybe caching with DDR.
- Re-add turbo support? Not sure if possible with nuked 68k
- Clean-up?

updates from Kitrinx and GreyRogue
