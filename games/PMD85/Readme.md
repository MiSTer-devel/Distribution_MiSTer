# PMD85 v2
![PMD image](/pictures/PMD_th.jpg)  
Computer [PMD 85](https://en.wikipedia.org/wiki/PMD_85) is [Czechoslovakian](https://en.wikipedia.org/wiki/Czechoslovakia) 8-bit computer produced by [Tesla](https://en.wikipedia.org/wiki/Tesla_(Czechoslovak_company)) Piešťany and Tesla Bratislava. First version was designed by Roman Kišš.
And this is its implementation in Verilog for [MISTEer](https://github.com/MiSTer-devel/Main_MiSTer/wiki) FPGA.

## Short demo video of this core on youtube

https://youtu.be/VVukIzzWiKY 

## Specifications

* CPU MHB8080A @2.048MHz - Czechoslovakian clone of [Intel 8080](https://en.wikipedia.org/wiki/Intel_8080)
* 64 kB RAM
* 4 kB ROM + up to 32 kB in detachable/changeable ROM pack used for example for Basic but also might be used other devices like emulator of 8048 uProcessor
* TV output or RGB video
* 288x256 pixels - 2 bits "color" attributes per 6 pixels (grayscale or blink or RGB)
* 2x8-bit parallel bus connectors
* application connector directly connected to IO system bus
* IMS-2 connector
* current loop RS232 connector
* connector for tape recorder to store and load programs

## What is implemented

* CPU
* 64 kB RAM
* Keyboard
* Beeper
* Green monitor mode, TV mode, RGB mode
* Color ACE mode - homemade color 
* loadable ROM Pack via menu for loading SW - *.rmm files needed
* MIF85 sound interface
* tape load via ADC MISTer connector (line in)
* mouse 

## What is missing

* floppy!!
* i8251 is not implemented - it only reports empty buffers. Implement and connect it to MISTer on board UART?
* i8253 gate inputs - missing pull ups

## How to install core

* copy file **PMD85_########.rbf** from **[releases](/releases)** folder to your MISTer SD card to **Computer** folder
(*######## stands here for date of version - you might want to delete earlier from SD card if you have some*)
* create subfolder **PMD85** in **games** folder on SD card and put there *.rmm games files you have
* in MISTer menu navigate to PMD85 item and start the core

## How to start

### Options

* Enable MIF85 in menu in sound item before load to be detected by SW and used
* Joystick and color mode can be changed during SW runs
* Mouse can be changed too, but SW probably do mouse presence test at start

### Loading games via ROM Pack

* In menu choose *.rmm file you want to load
* Reset PMD - rom pack usually contains automatic load
* Enjoy the PMD and the game :)

### Loading games via ACD (audio line in)

* connect your audio source (cassette player, mobile, ...) to MISTer ADC (line in)
* type MGLD ## and type EOL. ## replace with number of game you want to load. If you don't know game's number put there 00 and watch what PMD type on screen when loading, then reset and use that number for loading
* start playing WAV file. Games might have loaders and might draw a picture during load
* Enjoy the PMD and the game :)

## For more info see

* http://www.sapi.cz/pmd-85/pmd85-2a.php
* https://en.wikipedia.org/wiki/PMD_85
* https://pmd85.borik.net/
* https://www.schotek.cz/pmd/

Some of them are only in Czech or Slovak, but Google translator is your friend :)
