# Virtual Boy

The notorious early 3D experiment by Nintendo. This core recreates the Virtual Boy console faithfully in all it's bright-red 50hz hz stereo glory.

## Setup
This core has no bios or other requirements for setup. ROMs come in a padded and and unpadded variety, and sometimes one will work better than another. I suspect this is because the romsets tend to have a lot of bad and corrupt roms included in either of the two varieties. It should also be noted that a lot of the homebrew for this system was made for old, inaccurate emulators and will not load on real hardware or modern emulators. The Virtual Boy runs natively at close to 50.1fps. Some TV's may support this but stutter in which case it's worth trying to enable MiSTer's built-in VRR options, or in the worst case enable 60hz compatibility with `vsync_adjust=0`. For CRT's, any CRT that supports PAL frequencies should also tolerate this core. There is an internal 60hz compatibility mode but it may have uneven frame cadence as an unavoidable compromise.

## 3D compatibility
Anaglyph 3D using colored glasses and side-by-side output for 3DTV's are both supported by this core. By default only one eye will be shown for 2D play. There's a variety of color and configuration options in the `Audio & Video` menu. Additionally, you may load 4-color *.gbp files to extrapolate a colorful luma table for more interesting 2D play. `The Stereo Scale` menu can be used to try to adjust the distance between 3D objects which can sometimes make anaglyph style 3d more comfortable, though due to system structure this can't adjust baked-in background textures distance.

## Other Features
Savestates, cheats, and other typical MiSTer features are supported. Additionally the third party rumble support is in the core.

### SNAC
Set `Advanced > User IO` to `SNAC` to use an original Virtual Boy controller through a level-shifting SNAC adapter. The core uses the SNES SNAC signal pins: clock is USER1 (USB 3.0 D-), latch is USER0 (USB 3.0 D+), and controller data is USER5 (USB 3.0 RX-). `Off` releases the USER port.

## Development
Originally this was started as a fully hand written project, but like most contemporary development, AI was introduced and used for a lot of refactoring, auditing, and improvements. I know it is a controverial topic, but I can say with no hesitation that AI is an invaluable and game-changing tool for development of this nature. Like most tools, the quality of the results is largely dictated by the choices of the operator, and I feel this is no different. I strongly believe that in future, continued refinement of how we use AI in our development process will lead to results that are measurably higher quality than the results we can get without it. I don't claim we're at that point yet, but this marks some of my first attempts at using it this way. Amongst some of my experiments I had AI craft a suite of several test roms to run on real hardware which did comprehensive probes of the CPU and VIP to gather data on several of the silicon unknowns as best you can without a physical logic analyzer connected. The interpreted results yielded significant new hardware insights which allowed these chips to be implemented with more accuracy than previously possible in emulators.

## QA
- Guy's Cycle Test shows cycle accurate CPU timings to a real system, although it is likely not 100% cycle accurate because the pipelining is not well charactertized or understood by the existing knowledge pool.
- Guy's Speed Profile shows close, but not perfect bus timings. This is likely due to minor differences in the VIP RAM arbitration or cpu pipelining. They are closer than any other emulator I tried though.
- Extensive CPU audits were done against opcode sanity, output sanity, opcode timing, and reference matching.
- The VIP is largely a black box, but every retail title and all homebrew known to me was tested for accuracy until no defects were found in any of the video.
- Audio captures from the real system were programatically compared to captures from the core to test for accuracy. Many of the most difficult audio edge cases such as "Wario is gonna win" "Virtual Bowling" and "Galactic Pinball" voices all are real-system accurate in pitch and quality.
