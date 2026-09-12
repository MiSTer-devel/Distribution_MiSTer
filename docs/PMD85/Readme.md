# PMD85 v2A+v3
[![PMD image](/pictures/PMD_th.jpg)](/pictures/PMD85.jpg)  

The [PMD 85](https://en.wikipedia.org/wiki/PMD_85) was [Czechoslovak](https://en.wikipedia.org/wiki/Czechoslovakia) 8-bit computer produced by [Tesla](https://en.wikipedia.org/wiki/Tesla_(Czechoslovak_company)) [Piešťany](https://sk.wikipedia.org/wiki/Pie%C5%A1%C5%A5any) and [Tesla](https://en.wikipedia.org/wiki/Tesla_(Czechoslovak_company)) [Bratislava](https://sk.wikipedia.org/wiki/Bratislava) since 1985. The first version was designed by [Ing. Roman Kišš](https://sk.wikipedia.org/wiki/Roman_Ki%C5%A1%C5%A1).  
This repository contains a Verilog implementation for [MiSTer](https://github.com/MiSTer-devel/Main_MiSTer/wiki) FPGA.

## Short demo video of this core

https://www.youtube.com/watch?v=VDQYh1MQ5hU


Old video is still available on https://youtu.be/VVukIzzWiKY 

## Original hardware specifications

* CPU MHB8080A @2.048MHz - Czechoslovak clone of the [Intel 8080](https://en.wikipedia.org/wiki/Intel_8080)
* 64 kB RAM
* 4 kB ROM + up to 32 kB in detachable/changeable ROM pack used for example for Basic but also might be used for other devices like emulator of 8048 microprocessor
* TV or RGB video output 
* 288x256 pixels - 2-bit "color" attributes per 6 pixels (grayscale or blink or RGB)
* 2x8-bit parallel bus connectors
* application connector directly connected to I/O system bus
* IMS-2 connector
* current-loop RS232 connector
* connector for tape recorder to store and load programs

## Implemented features

* CPU
* 64 kB RAM
* Keyboard
* Beeper
* Green monitor mode, TV mode, RGB mode
* [Color ACE](https://pmd85.borik.net/wiki/ColorAce) - homebrew hardware modification
* Loadable [ROM Pack](https://pmd85.borik.net/wiki/ROM_Modul) (.rmm) and [Mega ROM Pack](https://pmd85.borik.net/wiki/ROM_MEGAmodul) (.mrm) via menu
* [MIF85 sound interface](https://pmd85.borik.net/wiki/MIF_85) - homebrew sound card/addon
* Tape load via ADC MiSTer connector (line in)
* [Mouse ](https://pmd85.borik.net/wiki/My%C5%A1_Poly-08)
* MHB8251 (i8251 clone) UART 
* [All RAM mode](https://pmd85.borik.net/wiki/AllRAM) (when all ram mode is activated, green led is blinking)

## Missing features

* floppy!!
* virtual cassette player (ptp files)
* PMD85 v3 is not properly initializing on JUMP FFF0 command (switching to v2 compatibility mode)

## Installation

* copy file **PMD85_########.rbf** from **[releases](/releases)** folder to your MiSTer SD card to **Computer** folder
(*######## stands here for date of version - you might want to delete earlier from SD card if you have some*)
* create subfolder **PMD85** in **games** folder on SD card and put there *.rmm and/or *.mrm game files you have. Please note I get kind permission to include one Mega ROM Pack file with Borik brothers games with this release - thank you!. You can find it in [SW folder](/SW). Other great source for PMD85 games is https://pmd85.borik.net/wiki/Download
* in MiSTer menu navigate to PMD85 item and start the core

## Usage

### Configuration

* Enable [MIF85](https://pmd85.borik.net/wiki/MIF_85) in menu in sound item before load to be detected by SW and used
* Joystick and [Color ACE](https://pmd85.borik.net/wiki/ColorAce) settings can be changed during SW runs
* Mouse can be changed too, but SW probably do mouse presence test at start. Please mind Mouse can't be activated with [MIF85](https://pmd85.borik.net/wiki/MIF_85) - they compete for same computer connector

### ROM Pack loading

* In menu choose *.rmm or *.mrm file you want to load
* Reset PMD - PMD85 v2 has automatic load
* Enjoy the PMD85 and the games :)

### Cassette (ADC) loading (audio line in)

* connect your audio source (cassette player, mobile, ...) to MiSTer ADC (line in)
* type MGLD ## and press EOL. ## replace with number of game you want to load. If you don't know game's number put there 00 and watch what PMD type on screen when loading, then reset and use that number for loading
* start playing WAV file. Games might have loaders and might draw a picture during load
* Enjoy the PMD and the games :)

### Serial console (optional)

* this is optional - just in case you want to try to communicate with the outside world

### Links

* https://pmd85.borik.net
* https://www.sapi.cz/pmd-85/pmd-85.php
* https://www.schotek.cz/pmd/
* [https://sites.google.com/site/computerresearchltd/home/staré-stroje/tesla-pmd-85](https://sites.google.com/site/computerresearchltd/home/star%C3%A9-stroje/tesla-pmd-85)


