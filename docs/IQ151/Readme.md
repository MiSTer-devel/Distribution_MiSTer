# IQ 151
[![IQ 151 image](/pictures/IQ151_th.jpg)](/pictures/IQ151.jpg)  
The [IQ 151](https://cs.wikipedia.org/wiki/IQ_151) was [Czechoslovak](https://en.wikipedia.org/wiki/Czechoslovakia) 8-bit computer produced by [ZPA](https://cs.wikipedia.org/wiki/Z%C3%A1vody_p%C5%99%C3%ADstroj%C5%AF_a_automatizace) [Nový Bor](https://cs.wikipedia.org/wiki/Nov%C3%BD_Bor) from 1985.  
This repository contains a Verilog implementation for [MiSTer](https://github.com/MiSTer-devel/Main_MiSTer/wiki) FPGA.

## Short demo video of this core

https://youtu.be/eqjSAlvpqkQ

## Original hardware specifications

* CPU MHB8080A @2.048MHz - Czechoslovak clone of the [Intel 8080](https://en.wikipedia.org/wiki/Intel_8080)
* 32 kB RAM (later versions had 64 kB RAM where some space was shadowed by installed modules)
*  4 kB ROM
* TV output 
* 512×256 pixels B/W
* Computer is modular - many functions are enabled by installing appropriate modules.
  * Video & Grafik Modules:
    * Video32 module = 32 rows x 32 columns, character is 8 pixels width x 8 pixels height, 6.144 MHz pixel frequency
    * Video64 module = 32 rows x 64 columns, character is 6 pixels width x 8 pixels height, 9.216 MHz pixel frequency
    * Grafik module  = 256 width x 512 height pixels, 12.288 MHz pixel frequency. Must be used together with Video32 or Video64
  * programming languages: 
    * Basic 6
    * Basic G
    * AMOS = whole new operating system
      * Assembler
      * Pascal
  * Other modules (peripherals):
    * Stapper = STAndard PERipherals - used for puncher, paper tape reader, printer
    * Sestyk/Sestyk9 = serial line realized with 8251
    * SERI = another serial line module used for FELNET computer network
    * MS151 & Minigraf = interface modules for plotters XY 4120-4150 
    * DISC 2 = floppy drive controller for 8" diskette drives with driver (firmware)
    * FLOPPY = floppy drive controller for 8" diskette drives without driver (firmware)
    * SD-ROM = acting as Stapper but modern HW allowing load and save programs on SD Card instead of paper tape. A homebrew device by Stamil
* Connector for tape recorder to store and load programs

## Implemented features

* CPU
* 64 kB RAM
* Keyboard
* Beeper
* Video32 & Video64 modules
* Grafik module
* SD-ROM module
* Tape load via ADC MiSTer connector (line in)
* Sestyk module (serial line connected to MiSTer user port)
  
## Missing features

* DISC 2 - floppy module
* write support to SD-ROM module

## Installation

* Copy file **IQ151_########.rbf** from **[releases](/releases)** folder to your MiSTer SD card to **Computer** folder
(*######## stands here for date of version - you might want to delete earlier from SD card if you have some*)
* Create subfolder **IQ151** on **secondary SD card** and put there content of ZIP file from **[SW folder](/SW)**. You should end up with similar layout as on picture below. Please make sure you have "**__BLOADER.BAS**" present. This file is needed for SD-ROM  module. Some games are included in that ZIP file (including best games from Stamil - thank you!)
![Secondary SD card layout image](/pictures/Secondary%20SD%20Card%20layout.jpg)
* In MiSTer menu navigate to IQ151 item and start the core



**************************************************************************
## Usage

### Configuration

* Changing Video32 to Video64 or vice versa will need to reset IQ151 core via menu


### SD-ROM module loading

* No external HW required - SD-ROM module is implemented inside FPGA

#### Preparing for use
* Follow instructions from [How to install core](#How-to-install-core)
* Copy there some games too :) Here is good source [http://www.iq151.cz/programy.htm](http://www.iq151.cz/programy.htm)  


#### Using SD-ROM module for loading games

* If you have Basic module selected
  * Type PTAPE command (or press ALT+K) and press CR (Enter) to load file manager
* If there is no Basic module selected (IQ monitor or AMOS)
  * Type S3 and press CR (Enter), press right arrow, type 55 and then press CR (enter). This will change input from tape player to punch reader (SD-ROM act as puncher & punch reader)
  * Type L to load file manager
* In file manager navigate to appropriate game and press CR (Enter) to load it. Basic games can't be run without Basic module selected and you will need to RUN them

#### Using SD-ROM module for saving games/programs

* **NOT IMPLEMENTED YET**
* In Basic type PLIST to save basic program to SD (puncher)
* In monitor you have to change value at address 0003 to 55 (type S3 and press CR (Enter), press right arrow, type 55 and press CR (enter)) and then type W<start_addr>,<stop_addr>,<run_addr> to save ("punch") appropriate memory range


### Loading games via ACD (audio line in)

* Connect your audio source (cassette player, mobile, ...) to MiSTer ADC (line in)
* type MLOAD (or press ALT+L) and press CR (Enter) 
* Start playing WAV file. Basic games will print source code lines as they load
* Enjoy the IQ 151 and the games :)



## Links

* http://www.sapi.cz/iq151/iq.php
* http://www.iq151.net
* https://sites.google.com/site/cssrpocitace/registr/iq151
* https://cs.wikipedia.org/wiki/IQ_151
* https://github.com/omikron88/iq-151
* [https://sites.google.com/site/computerresearchltd/home/staré-stroje/zpa-nový-bor-iq-151](https://sites.google.com/site/computerresearchltd/home/star%C3%A9-stroje/zpa-nov%C3%BD-bor-iq-151)

Some of them are only in Czech or Slovak, but Google translator is your friend :)




