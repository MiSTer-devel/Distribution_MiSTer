# MemTest256 - Dual SDRAM Memory Tester

Enhanced memory testing utility for MiSTer FPGA with dual SDRAM slot support, real-time text UI, and automated per-slot frequency characterization.

Source and documentation: <https://github.com/alijani1/MemTest256>

Built on the original [MemTest_MiSTer](https://github.com/MiSTer-devel/MemTest_MiSTer) by Sorgelig.

## Screen

![MemTest256 screen](https://raw.githubusercontent.com/alijani1/MemTest256/main/MemTest256.png)

## Features

- **Dual SDRAM support** — tests both Slot 1 (GPIO 0) and Slot 2 (GPIO 1) independently, no physical module swapping needed
- **Auto-detection at boot** — probes Slot 2 at 100MHz; if RAM responds, enters Both Slots mode automatically
- **Auto-detects Slot 2 capacity** — probe tries 128MB first, falls back to 64MB then 32MB. Mismatched module configurations are supported.
- **Two-phase frequency search** — coarse 10MHz ramp-up (120→130→…→167) to locate the failure band, then 1MHz step-down to find the exact stable ceiling (the "start point")
- **Live per-slot history** — after start point, current freq and pass count are shown in the history row; blinking pass count indicates the slot being actively tested
- **Clean text UI** — readable frequencies, pass counts, per-slot timers, and total elapsed time. Color-coded pass/fail status.
- **Chip select** — cycle between Both / Chip 1 / Chip 2 for isolating faults in a specific chip on a 128MB module (C key)
- **Robust error handling** — state-machine and progress watchdogs with retry escalation
- **Backward compatible** — works on all MiSTer hardware and I/O board revisions including the new A/V Pro v9.2

## Controls

| Key | Action |
|-----|--------|
| S | Cycle test mode (Both Slots / Slot 1 / Slot 2) |
| P | Toggle displayed slot in Both Slots mode |
| A | Re-enable auto stepping at current frequency |
| Up | Increase frequency (manual/locked mode) |
| Down | Decrease frequency (manual/locked mode) |
| Enter | Reset test |
| C | Cycle chip select (Both / 1 / 2) |

Gamepad equivalents are also supported.

## Result interpretation

Frequencies below 130MHz should be considered marginal. 130–144MHz is acceptable for most MiSTer cores. 145MHz and up is excellent. High readings (150+MHz) reflect favorable conditions — treat them as headroom, not a target for cores.

See the [project README](https://github.com/alijani1/MemTest256#interpreting-results) for a fuller results guide and caveats.

## SW[3] note

On older MiSTer I/O boards, SW[3] on the DE10-Nano must be **ON** to physically route Slot 2. On the new A/V Pro v9.2 board, SW[3] should be **OFF** — the framework auto-detects the board and handles Slot 2 signaling via MCP23009 I2C. MemTest256 does not depend on SW[3] itself.
