# Sega Master System and Game Gear for the [MiSTer](https://github.com/MiSTer-devel/Main_MiSTer/wiki) and [MiST](https://github.com/mist-devel/mist-board/wiki) boards

### Installation:
* Copy the *.rbf file at the root of the SD card.
* Copy *.SMS ROMs into SMS folder.

### Features: 
* Master System, Game Gear and SG-1000 Support
* Sega System E arcade hardware support
* NTSC & PAL Support
* Hide Borders Option - Allows you to fill the screen vertically without black borders.
* FM Audio Support
* Extra Sprites Option
* Cheats

### Download precompiled binaries at:
* For MiSTer, go to [releases](https://github.com/MiSTer-devel/SMS_MISTer/tree/master/releases) folder.
* For MiST, go to [mist-binaries](https://github.com/mist-devel/mist-binaries/tree/master/cores/sms).

### Notes:
* Some games come in .gg format but are in fact SMS games. Rename the .gg extention to .sms or .bin to fix them.
  These games are mostly listed in this page [SMSpower-SMS-GG list](http://www.smspower.org/Tags/SMS-GG).
* The "Aspect ratio" doesn't do much in PAL mode, that's normal
* The "Region" parameter toggle some hardware features that are specific to the different console models.
  Some localized games need these modifications to work properly
* The "Masked left column" option controls behaviour of left column when hidden by system (usually during horizontal 
  scrolling). "BG" sets it to the background/overscan colour, as on original hardware. "Black" makes it black,
  which may look better on non full-screen settings as the column will blend in with surrounding black area.
  "Cut" will remove the column from the active image, so the horizontal resolution becomes 248 instead of 256. This
  will distort the image when scaled, particularly on integer scaling settings, but will use more of the screen.
  When "Border" is set to "Yes" the left column is always shown as part of the border, so "Masked left column" is 
  disabled.
* Each game cartridge comes with a specific mapper, which description is not included in the .gg ou .sms file.
  The core has a special logic to automatically determine which mapper needs to be used, but some games make
  a good effort to make this logic fail. The "Disable mappers" parameter permits to force the usage 
  of the most used sega mapper. 
