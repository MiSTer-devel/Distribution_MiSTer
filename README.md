# MiSTer Distribution

This repository contains all the files that you'll want in your MiSTer.

You may download all of them at once as a zip through the [following link](https://github.com/MiSTer-devel/Distribution_MiSTer/archive/refs/heads/main.zip). Once you have them, place them as-is in your [properly initialised SD card](https://github.com/MiSTer-devel/mr-fusion), and everything should work out of the box.

### MiSTer Project

If you want to check more about the MiSTer project, please check [this wiki](https://github.com/MiSTer-devel/Wiki_MiSTer/wiki).

### MiSTer Downloader

For downloading all of these files directly from your MiSTer, use the [MiSTer Downloader](https://github.com/MiSTer-devel/Downloader_MiSTer).

#### Tags that you may use with 'Download Filters' feature

Read about how to use them [here](https://github.com/MiSTer-devel/Downloader_MiSTer/blob/main/docs/download-filters.md).

##### List:

ALL_TAGS_GO_HERE

##### Some relevant tag descriptions:

- `arcade-cores` / `arcade`: All arcade cores and MRA files.
- `computer-cores` / `computer`: All computer cores and related folders.
- `console-cores` / `console`: All console cores and related folders.
- `other-cores` / `other`: All cores from the top folder Other with their related folders.
- `service-cores` / `utility`: All utility cores and related folders.
- `cores`: All cores (RBF files).
- `mra`: All MRA files & folders.
- `alternatives`: All MRA Alternatives
- `hbmame`: All files & folders linked to the HBMame collection.
- `handheld2p`: All 2 Player versions for Handheld cores.
- `filters_video`: All video filters (`gamma` & `filters` & `shadow_masks`).
- `all_filters`: All video & audio filters (`filters_video` & `filters_audio`).
- `essential`: Menu core & MiSTer firmware.
- `readme`: All README files.
- `docs`: All documentation files & folders, including README files.
- `extra-utilities`: All extra utilities that are installed in games folders of some computer cores.
- `bios`: All bioses that are installed in the games folders for some computer & console cores.
- `cheats`: All cheat files & folders.

##### Tags based on the Arcade Database:

The following tags are calculated with the information contained in the [MiSTer Arcade Database](https://github.com/MiSTer-devel/ArcadeDatabase_MiSTer):

- `unlicensed_games`: All arcade bootlegs, hacks or homebrew games
- `controls_1_button`: All arcade games playable with just 1 button.
- `controls_2_buttons`: All arcade games playable with 2 buttons.
- `controls_3_buttons`: All arcade games playable with 3 buttons.
- `controls_4_buttons`: All arcade games playable with 4 buttons.
- `controls_5_buttons`: All arcade games playable with 5 buttons.
- `controls_6_buttons`: All arcade games playable with 6 buttons.
- `controls_spinner`: All arcade games designed to be played with a spinner.
- `controls_paddle`: All arcade games designed to be played with a paddle.
- `controls_dial`: All arcade games designed to be played with a dial.
- `controls_trackball`: All arcade games designed to be played with a trackball.
- `controls_move_2-way`: All arcade games that require 2-way movement (left-right or up-down).
- `controls_move_4-way`: All arcade games that utilize 4-way directional movement.
- `controls_move_8-way`: All arcade games that utilize 8-way omnidirectional movement.
- `screen_rotation_horizontal` / `screen_no_tate`: All arcade games designed for horizontal screens.
- `screen_rotation_vertical_cw` / `screen_tate_cw`: All arcade games designed for clock-wise vertical screens.  Including counter clock-wise with a flip option.
- `screen_rotation_vertical_ccw` / `screen_tate_ccw`: All arcade games designed for counter clock-wise vertical screens. Including clock-wise with a flip option.
- `screen_horizontal_scan_rate_15khz`: All arcade games only supported by 15kHz CRT screens.
- `screen_horizontal_scan_rate_31khz`: All arcade games only supported by 31kHz CRT screens.

If there is any mismatch between one of the previous terms and the game, please report it in that Arcade Database repository.

### Contributing

You are more than welcome to contribute to the [MiSTer-devel Organization](https://github.com/MiSTer-devel). But you can't do it by openening PRs to the main branch of this repository. This repository is only for file distribution. Whatever content shows up here depends on the other repositories of this organization, so you should target your PRs there.

There is a development branch in this repository for the content collection. Is fine to send PRs there but they should only modify the content collection scripts that are being used by the workflows.
