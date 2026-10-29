# Vectrex (1982) for MiSTer FPGA

![Fifteen Vectrex games](images/Vectrex-fifteen-games.png)

An FPGA implementation of the **GCE Vectrex** console for the [MiSTer FPGA](https://github.com/MiSTer-devel/Main_MiSTer/wiki) platform.

The Vectrex has become a legend of console history: the only home system released with its own vector CRT. Its bright glow, clean lines, analog controls, and translucent color overlays gave it an unmistakable home-arcade character and a devoted cult following. More than four decades later, an active development community still creates new games, hardware, and tools for it.

This core recreates the console hardware and pairs it with a high-resolution vector renderer whose resolution-aware glow, bloom, broad halo, and phosphor persistence attempt to reproduce the unique character of a vector CRT.

---

## Included Games

### Vectorblade

**Vectorblade v1.13** by Malban is one of the Vectrex community's most ambitious modern games. It is bundled with the author's permission, together with converted artwork for all three display orientations. Its four-bank 256 KiB flash cartridge is fully supported, including persistent settings, scores, and game-managed progress.

Copy `Vectorblade (v1.13).bin` and `Vectorblade (v1.13).art` from
[`games/Vectorblade/`](games/Vectorblade/) to `/media/fat/games/Vectrex/`,
then load the ROM. Rotated overlays are in the `Tate` folder of [overlays.zip](overlays/overlays.zip). For calibration on this core, select **Buzz** in Vectorblade's own model-selection screen before adjusting the text.

### Telengard

**Telengard v1.03** by Malban (2022/2026), based on Daniel M. Lawrence's 1982 dungeon crawler, is also bundled with permission. It uses a 256 KiB four-bank flash cartridge with persistent character saves at Inns.

Copy `Telengard (v1.03).bin` and `Telengard (v1.03).art` from
[`games/Telengard/`](games/Telengard/) to `/media/fat/games/Vectrex/`,
then load the ROM. On the title screen, press **Button 3** to enter calibration and press **Button 1** to select **Buzz** (the calibrated model for this core).

### Neon Hawk Demo

**Neon Hawk Demo v1.0** by Jaakko and Mikko Huovinen is already one of the most impressive 3D games on the Vectrex. This spectacular rail shooter shows how much untapped potential the iconic vector console still holds, running entirely on original Vectrex hardware without help from additional processors. Its distinctive look also inspired our **Neon Blue** mode.

We're delighted to include the demo and matching artwork with the authors' permission. Give it a try, and when the full game is ready, rush out and buy it! Games like this deserve our support.

Copy `Neon Hawk Demo (v1.0).bin` and `Neon Hawk Demo (v1.0).art` from
[`games/NeonHawk/`](games/NeonHawk/) to `/media/fat/games/Vectrex/`,
then load the ROM. The [demo README](games/NeonHawk/README.md) covers controls and rotated artwork. Other game ROMs are not included.

---

## Original Hardware

| Subsystem | Original Hardware | FPGA Implementation |
|---|---|---|
| **CPU** | Motorola MC68A09 at 1.5 MHz | Greg Miller's cycle-accurate MC6809, adapted to Vectrex bus timing with corrected NMI arming, reset interrupt state, and `SEX` flags |
| **I/O and Timing** | MOS 6522 VIA | Gideon Zweijtzer's VIA model clocked on the Vectrex's inverted MC6809 E half-cycle, with corrected Timer 1 sequencing, full eight-bit shift output, CB2 beam-blanking timing, and interrupt readback |
| **Vector Generator** | 8-bit MC1408 DAC, CD4052 analog multiplexer, sample-and-hold circuits, and X/Y integrators | 12 MHz sampled DAC, multiplexer, reference, and integrator model with acquisition delays, calibrated beam cutoff and dwell energy, and Q301 RAMP timing |
| **Sound** | General Instrument AY-3-8912 PSG and MC1408 DAC audio | JT49 with Vectrex logarithmic volume mapping, corrected signed direct-DAC samples, and PSG/DAC balance calibrated against a real Vectrex line-out recording |
| **Speech** | Optional SP0256-AL2 VecVoice accessory connected through controller port 2, with separate audio output | Selectable SP0256-AL2 implementation using the physical PSG Port A serial-data and ready lines, digitally mixed at an adjustable speech level |
| **Display** | Built-in 9-inch monochrome XY vector CRT with interchangeable color overlays | 1080p, 720p, 480p, 480i, and 240p output through a 125 MHz tile/DDRAM renderer, with bloom, broad halo, tone mapping, phosphor decay, and alpha-channel overlays with independent translucent and opaque controls |
| **Cartridges** | Standard ROM cartridges; later homebrew PB6-banked and SST39SF020A flash designs | Standard ROMs, 64 KiB PB6 banking (e.g. Vector Patrol), and 256 KiB four-bank flash (e.g. Vectorblade and Telengard), with persistent saves |
| **Controls** | Two controller ports; each controller has an analog stick and four buttons | Analog stick, D-pad, and remappable MiSTer buttons for two players |

**Experimental PiTrex and UVMC2 support:** Check out [z00p's Vectrex fork](https://github.com/z00p/Vectrex_MiSTer), which runs PiTrex and UVMC2 software using the DE10-Nano's ARM processor. This is a separate project and an experimental work in progress; see the fork for downloads, instructions and compatibility information.

---

## Requirements

The high-resolution vector and CRT-effects pipeline uses MiSTer SDRAM and requires a 32 MB SDRAM module or larger.

---

## Installation

The core uses MiSTer's console directory structure:

1. Copy the latest dated `Vectrex_*.rbf` file from `releases/` to
   `/media/fat/_Console/`.
2. Copy the supplied `boot2.rom` to
   `/media/fat/games/Vectrex/`.
3. Copy game ROMs with a `.vec`, `.bin`, or `.rom` extension to
   `/media/fat/games/Vectrex/`.
4. For automatic overlay loading, place the `.art` file beside its ROM with a matching filename, apart from the extension, for example:
   ```text
   Armor Attack.vec
   Armor Attack.art
   ```
5. Supplied artwork is in [`overlays/overlays.zip`](overlays/overlays.zip).
   If you installed through **update_all** or **Downloader**, it should already be in
   `/media/fat/games/Vectrex/Overlays/`.
   Copy the desired artwork from there and rename it to match your ROM.

The repository includes ready-to-use artwork for the original Vectrex catalogue, including newly restored overlays for Japanese releases such as Scramble Wars and Harmagedon, as well as a selection of homebrew games.

---

## Controls

| Input | Function |
|---|---|
| **D-pad / Left Analog Stick** | Vectrex joystick |
| **A** | Button 1 |
| **B** | Button 2 |
| **X** | Button 3 |
| **Y** | Button 4 |
| **Select** | Pause |
| **R / Right shoulder** | View: cycle artwork and framing |

The controls are remappable through MiSTer's normal input assignment menu. When **Port 2** is set to **Joystick**, a second controller is available to software that supports it.

---

## Recommended MiSTer Video Settings

Unlike a conventional raster-console core, Vectrex has no native pixel resolution. The core reconstructs vectors directly at the output resolution reported by MiSTer for maximal quality without additional scaling. HDMI users whose HD display is already configured through `video_mode` do not need to select another resolution; the core follows it automatically. The per-core settings below are nevertheless recommended for the best presentation.

The renderer supports 1080p, 720p, 480p, 480i, and 240p output. **1080p is recommended** for the highest vector detail. Compatible 720p displays can also use the optional 120 Hz mode.

For high-resolution flat-panel output, place the following entries under the exact `[Vectrex]` header at the end of `MiSTer.ini`. Empty filter and mask entries prevent MiSTer's scaler effects from altering the core's own CRT pipeline.

```ini
[Vectrex]
video_mode=8   ; 8 = 1080p, 0 = 720p
video_mode_ntsc=
video_mode_pal=
hdr=0          ; use 1 if your display supports HDR
vsync_adjust=0 ; use 1 or 2 for lower latency and 120 Hz option
vscale_mode=0
hdmi_limited=0 ; use 1 for displays expecting limited RGB range
vfilter_default=
vfilter_vertical_default=
vfilter_scanlines_default=
shmask_default=
shmask_mode_default=0
```

### CRT Output

> **Required for 15 kHz CRT output:** Place the following `[Vectrex]` section at the end of `MiSTer.ini` so it overrides earlier global settings. These settings prevent an out-of-range HD signal and provide the best image quality.
```ini
[Vectrex]
video_mode=720,240,60
vsync_adjust=0
video_mode_ntsc=
video_mode_pal=
vga_scaler=0
forced_scandoubler=0
```
For a **31 kHz CRT**, use this `video_mode` instead:
```ini
video_mode=720,480,60
```
Under **Video Overlay & Geometry**, **15 kHz Format** selects 480i or 240p, with 480i used by default.

**CRT Vertical Offset** moves the whole picture up or down without changing its size. Positive steps move it down; negative steps move it up. The default is **0**; the setting has no effect at 720p or 1080p.

### Direct Video Output

For Direct Video, use the same settings and additionally add `direct_video=1` to the `[Vectrex]` section. This enables **Direct Video Scan Rate**, which selects **15 kHz** or **31 kHz** output. At 15 kHz, **15 kHz Format** selects **480i** or **240p**.

---

## OSD Options

### Video Profiles & Effects

| Profile | Description |
|---|---|
| **A Touch of CRT** | Modern clarity with subtle halo and bloom while vectors remain crisp. |
| **80s Cruise Control** | Default profile. Familiar vector CRT glow, richer halo and stronger bloom. |
| **80s Overdrive** | Hot vectors, heavy bloom and lingering phosphor trails. |
| **Neon Blue** | Electric blue vectors that turn white at their brightest, with a subdued blue halo and lingering phosphor trails. |
| **Red Alert** | Red warning-light palette with hard bloom and restless phosphor trails. |
| **Ultraviolet** | Violet arcade fever dream with neon haze and lingering trails. |
| **Custom 1 / Custom 2** | Two independently saved profiles exposing all advanced bloom, halo, grid, decay, and color controls. |

> **Warning:** Red Alert and Ultraviolet can produce excessive flashing bright lights and should not be used by anyone sensitive to them.

Select a profile through the **Video Profiles & Effects** menu, or use **-** and **=/+** outside the menu to cycle through the profiles (US keyboard layout). To create your own look, adjust the advanced controls exposed in the **Custom 1** or **Custom 2** profiles.

See [Video Settings and Profiles](Profiles/README.md) for details and tuning advice.

### Video Overlay & Geometry

| Option | Description |
|---|---|
| **Overlay** | Shows (**On**, default) or hides (**Off**) the overlay. |
| **Tint Strength** | Adjusts the overlay's tint strength, from **-1** to **+6** (**0** default). Higher settings favor richer color at the expense of dynamic range. Has no effect if Overlay is Off. |
| **Translucent Blend** | Sets base visibility of partially transparent overlay areas from 10% to 80% in 10% steps; `60%` is the default. Saved selections are retained. Fully transparent pixels remain unchanged. Shown only when Overlay is On. |
| **Opaque Brightness** | Sets the brightness of fully opaque overlay areas from 10% to 80% in 10% steps; `50%` is default. These regions usually contain borders, logos and printed instructions. Shown only when Overlay is On. |
| **Orientation** | Selects **Normal** (default), **90 CCW**, or **90 CW** display orientation. |
| **Framing** | **Overlay** (default) aligns game geometry with the overlay window; **Screen** enlarges it to use more screen space. |
| **View Area** | **Standard** (default) limits vectors to the calibrated screen; **Open Matte** reveals off-screen drawing up to the framebuffer boundary. |
| **Offset** | **Compensated** (default, recommended) shifts the vectors slightly upward to reproduce the alignment between vectors and overlay seen on an original Vectrex from a normal viewing angle. **Zero** applies no shift. |
| **120Hz (720p only)** | Enables ~120 Hz output when a compatible 720p video mode is active. Greyed out in other resolutions. |
| **Direct Video Scan Rate** | Selects **15 kHz** or **31 kHz**; shown only while Direct Video is active. |
| **15 kHz Format** | Selects **480i** (default) or **240p**; shown only in 15 kHz modes. |
| **CRT Vertical Offset** | Moves the entire CRT picture vertically (standard orientation), including the overlay. **0** is default; positive steps move down and negative steps move up. Applies to 240p, 480p and 480i. |

Adjust the overlay brightness to recreate different room lighting. Lower **Translucent Blend** and **Opaque Brightness** for a nighttime look that lets the vectors stand out. Raise them for a daytime look with a more prominent overlay.

Open Matte can reveal substantial geometry drawn outside the normally visible area of a Vectrex screen. In titles such as Pole Position, the Neon Hawk demo and Hyper Chase, this exposes normally hidden parts of the scene, allowing these titles to be experienced in a new way.

**View** cycles through these settings, skipping step 1 when no overlay is loaded. The OSD and a brief on-screen message show the selection.

| Step | Overlay | Framing | View Area |
|---|---|---|---|
| 1 | On | Overlay | Standard |
| 2 | Off | Overlay | Standard |
| 3 | Off | Screen | Standard |
| 4 | Off | Screen | Open Matte |

View is inactive while the OSD is open. Loading an overlay selects Overlay On, Framing Overlay, and View Area Standard.

### System

| Option | Description |
|---|---|
| **BIOS** | Selects **Rev 3** (default, fixes Mine Storm wave 13 bug) or **Rev 1** (original launch BIOS). |
| **Quick Boot** | **Yes** (default) skips redundant BIOS startup delay; **No** preserves the full startup timing. |
| **Beam Threshold** | Sets the global beam cutoff: **Z 20** (default), **Z 24**, **Z 28**, or **Off**. The remaining visible levels span the full brightness range in every mode. Off accepts all positive Z levels. Applies to every profile. |
| **Port 2** | Selects **Joystick** (default) for 2-player support, or **VecVoice (SP0256)** for the speech synthesizer. |
| **Speech Level** | Selects **Normal** (default), **Low** or **High** speech volume. Greyed out when Port 2 is set to Joystick. |
| **Cartridge Autosave** | Automatically saves pending cartridge changes after one second without flash activity (**On** by default). Available only for titles whose flash-save hardware is supported by the core. |
| **Save Cartridge** | Manually writes pending flash changes to SD card. Shown only for flash cartridges. |
| **Pause when OSD open** | Pauses the emulated console while the OSD is open (**Off** by default). |
| **Dim video after 60s** | Dims the display after 60 seconds of pause to reduce the risk of burn-in (**On** by default). |

### Diagnostic

These global controls are intended for testing and troubleshooting. Keep their defaults for normal use. See [Diagnostic Settings](Profiles/README.md#diagnostic-settings) in the profile guide for details.

---

## Vectrex Overlays

Digital overlays reproduce the printed sheets fitted in front of a real Vectrex screen. Translucent colors tint the vectors; opaque print forms borders, illustrations, game titles and control labels.

A curated collection of **65 overlay designs** is included in [overlays.zip](overlays/overlays.zip), including the restored **Scramble Wars** and **Harmagedon** artwork. Extract it to
`/media/fat/games/Vectrex/Overlays/`
for manual selection. Standard artwork is at the archive root, with 90CW and 90CCW versions in `Tate`. `CREDITS.md` inside the archive identifies each design and links to its upstream artwork or collection where available.

See [Installation](#installation) for automatic artwork loading.

After artwork loads successfully, the core automatically selects **Overlay: On**, **Framing: Overlay** and **View Area: Standard**. You can change these settings afterward.

### Startup Cartridge and Artwork

Place startup files in the Vectrex games directory on the MiSTer SD card:

| Files present | Startup behavior |
| --- | --- |
| `boot.rom` | Loads `boot.rom` into cartridge memory and starts it. |
| `boot.rom` and `boot2.rom` | Loads and starts the cartridge with the artwork overlay. |
| `boot2.rom` | Loads the artwork overlay and starts the built-in BIOS/Mine Storm. |
| Neither file | Starts normally with the built-in BIOS/Mine Storm. |

The supplied `boot2.rom` contains the standard Mine Storm overlay for startup. To use different artwork, copy a valid `.art` package into the Vectrex games directory and rename it to `boot2.rom`. PNG files must first be converted to ART format. Normal companion artwork loading and the **Load Overlay** menu option remain available.

### Creating ART Packages

Overlay artwork is usually supplied as an **846 x 1080 PNG**. The build tool converts this image into `.art` format and packages the required renderer planes. Extraction returns those stored planes as PNGs, including any resizing, palette reduction and alpha adjustments applied during creation. See [Overlay Tools](<Overlay Tools/README.md>) for setup and conversion instructions on Windows, Linux or macOS. The tools are a separate host-side download and are not included in the overlay archive.

---

## Cartridge Saves

The four-bank flash cartridges used by Vectorblade and Telengard support persistent storage. The core saves the flash sectors written by the game, including its settings, scores, and any game-managed saved progress.

**Cartridge Autosave** is on by default. Saving starts after one second without flash activity; **System > Save Cartridge** saves pending changes manually. Wait for the user LED to go out before loading another game, reloading the core, or switching off. Console reset does not cancel a save. With Autosave off, pending changes remain in memory until saved manually.

MiSTer stores a separate `.sav` file named after the ROM in its Vectrex saves directory.

---

## Limitations

- **3D Imager:** The 3D Imager is not supported. Titles requiring the 3D Imager (*3D Minestorm*, *3D Narrow Escape*, *3D Crazy Coaster*, and *3D Sector X*) will not work correctly and might not produce visible output.
- **Light Pen:** The GCE Light Pen is not supported. Titles requiring pen input (*Art Master*, *Melody Master*, and *AnimAction*) cannot be controlled.
- **Cartridge Saves:** Saving currently supports the 256 KiB four-bank SST39SF020A flash cartridges used by *Vectorblade* and *Telengard*. Other cartridge save hardware is currently unsupported.
- **Console Audio:** The "Buzz" Vectrex hardware model is simulated for game timing and calibration, but without the physical console's audio buzz.

---

## Compilation

The project uses Quartus Prime Lite 17.0 and targets the Cyclone V FPGA on the Terasic DE10-Nano.

1. Open `Vectrex.qpf` in Quartus.
2. Run the complete compilation flow, including TimeQuest timing analysis.
3. Find the generated `Vectrex.rbf` in `output_files/`.

---

## Credits and Acknowledgments

- **Original Vectrex design:** Mike Purvis and John Ross (concept), Jay Smith (project lead), John Ross (hardware), Gerry Karr and John Hall (system software), Walter Nakano and Colin Vowles (industrial design), and the teams at Smith Engineering and GCE
- **MiSTer FPGA implementation:** Based on Dar's DE10-Lite core, Sorgelig's MiSTer port, and additional work by alanswx; comprehensively overhauled by Videodr0me with an improved CPU and VIA, a new beam and dwell-energy model, high-resolution renderer and CRT presentation pipeline, full HD overlays, expanded video and CRT modes, and modern cartridge support
- **MC6809 CPU:** Greg Miller's cycle-accurate core, adapted by Sorgelig, with additional fixes by Videodr0me
- **6522 VIA:** Gideon Zweijtzer, with accuracy work by gyurco and Vectrex-specific timer, shift-register, CB2, and interrupt fixes by Videodr0me
- **AY-3-8912 sound implementation:** Jose Tejada's JT49, an open-source Verilog implementation of the AY-3-8910/YM2149 PSG family, configured for the Vectrex volume response and mixed with its direct DAC path
- **SP0256-AL2 research and implementation sources:** Joseph Zbiciak, Tim Lindner, and Dar
- **Vectorblade:** Malban, for the game, original overlay, and permission to bundle the ROM
- **Telengard:** Daniel M. Lawrence (original game) and Malban (Vectrex port, flash cartridge architecture, and permission to bundle)
- **Neon Hawk:** Jaakko and Mikko Huovinen, for the demo, original artwork, and permission to bundle
- **MiSTer platform:** Sorgelig and the MiSTer community

## Licensing

This repository contains components under multiple licenses. Individual file headers are authoritative. The MiSTer top-level integration is distributed under GPL-2.0-or-later, JT49 under GPL-3.0-or-later, and imported Vectrex, speech, CPU, and peripheral modules retain their original notices and terms. The bundled Vectorblade, Telengard and Neon Hawk demo ROMs, and original game artwork, retain their authors' rights; their inclusion does not place them under the FPGA core's software licenses.
