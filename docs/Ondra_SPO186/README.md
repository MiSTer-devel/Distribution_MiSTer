# Ondra SPO 186
[![Ondra SPO 186 image](/pictures/Ondra_th.jpg)](/pictures/Ondra.jpg)  
[Ondra SPO 186](https://cs.wikipedia.org/wiki/Ondra_(po%C4%8D%C3%ADta%C4%8D)) was a [Czechoslovak](https://en.wikipedia.org/wiki/Czechoslovakia) 8-bit computer developed in 1985 at [Tesla Liberec](https://en.wikipedia.org/wiki/Tesla_(Czechoslovak_company)) by [Ing. Eduard Smutný](https://cs.wikipedia.org/wiki/Eduard_Smutn%C3%BD), Ing. Tomáš Smutný and Ing. Jan Mercl as an affordable school and home computer. Tesla produced around 2000 Ondra computers.  
This repository contains a Verilog implementation for [MiSTer](https://github.com/MiSTer-devel/Main_MiSTer/wiki) FPGA.

## Short demo video of this core

https://youtu.be/YnFbf-u1D80 


Older video with load via serial port - not supported anymore  
https://youtu.be/B2MRWTKYOYU

## Original hardware specifications

* CPU [U880](https://en.wikipedia.org/wiki/U880) @2MHz - [East German](https://en.wikipedia.org/wiki/East_Germany) clone of [Z80](https://en.wikipedia.org/wiki/Z80)
* 64 kB RAM (10 kB used by video RAM)
* 4-16 kB ROM (EPROM) 
* TV output 
* flexible resolution (commonly 322×240 or 322×252; up to ~400×255 possible), black and white, 40 columns × 24 rows
* relay for cassette player control - often used for "sound (click) signaling"
* Sound: 7 fixed tones (no musical scale)
* one 20 pins connector for joystick, Centronics parallel port (8-bit data out, Strobe_n out, Busy in), UART (Reserva In = RXD, Reserva Out = TXD)
* cassette player connector for SW load and save at 2400[Bd](https://en.wikipedia.org/wiki/Baud)

## Keyboard

Ondra has a modest keyboard with only 37 keys, so each key can serve 2 or 3 different characters depending on the modifier key used.

**Modifier keys:**  
**Ondra      -> PC Keyboard**  
Shift      -> Shift  
Symbols    -> Alt  
Ctrl       -> Ctrl  
Numbers    -> Tab  
ČS         -> Caps Lock (used for Czech diacritics)

Each modifier key needs to be pressed (and held) before pressing character key. 
Here is mapping Ondra keys to PC Keyboard. Please note modifier keys are in different colors as invoked characters on other keys.

[![Ondra Keyboard mapping](/pictures/OndraKeyboardMapping_small.jpg)](/pictures/OndraKeyboardMapping.jpg)

## Graphics generation (Video circuit)

Ondra has a very unique video circuit. Video address counter implemented using two КР580ВИ53 programmable interval timers - Russian clone of [i8253](https://en.wikipedia.org/wiki/Intel_8253). In fact, although Ondra was designed and manufactured in Czechoslovakia, most of ICs were "Made in [USSR](https://en.wikipedia.org/wiki/Soviet_Union)".
Timers are used for generating [VSync and HSync](https://en.wikipedia.org/wiki/Analog_television#Vertical_synchronization) start pulses as well as for generating video address itself. Cheap, simple but not easy :)
Advantage of this solution is that screen resolution can be programmatically changed. Disadvantage is that CPU must wait while the screen is being drawn. Due to video DMA timing, the CPU is active only a small fraction of each display frame (18–20%).


## Implemented features

* CPU
* 64 kB RAM
* Keyboard
* Sound (7 different sounds - not forming a scale, as on real HW)
* Tape load via ADC MiSTer connector (line in)
* [Ondra SD](https://sites.google.com/site/ondraspo186/3-ondra-sd) - modern HW for easier SW load from SD Card
* [OndraMELODIK](https://github.com/72ka/OndraMELODIK) - new HW for Ondra bringing better sound using [SN76489 chip](https://en.wikipedia.org/wiki/Texas_Instruments_SN76489). Here is link to [YouTube video](https://youtu.be/u5RyUs0VGdg) with demo app

## Missing features

* [Ondra SD](https://sites.google.com/site/ondraspo186/3-ondra-sd) - RAW R/W support (required for [CP/M](https://sites.google.com/site/ondraspo186/7-ondra-cpm))

## Installation

* copy file **Ondra_SPO186_########.rbf** from **[releases](/releases)** folder to your MiSTer SD card to **Computer** folder
(*######## stands here for date of version - you might want to delete earlier from SD card if you have some*)
* in MiSTer menu navigate to Ondra_SPO186 item and start the core

## Usage
 
### Loading games via [Ondra SD](https://sites.google.com/site/ondraspo186/3-ondra-sd) 

* No external HW required - [Ondra SD](https://sites.google.com/site/ondraspo186/3-ondra-sd) is implemented inside FPGA

#### Preparing for use
* Create "**Ondra**" folder on your **secondary SD card** 
* Copy "**__LOADER.BIN**" and "**_ONDRADM.BIN**" to this SD Card from [OndraSD.zip](https://drive.google.com/file/d/1seHwftKzaBWHR4sSZVJLq7IKw-ZLafei/view?usp=drive_web)
* Copy there some games too :) Here is good source [https://sites.google.com/site/ondraspo186/d-download/d-1-hry](https://sites.google.com/site/ondraspo186/d-download/d-1-hry)  
Your SD Card should look like this

![SD Card content](/pictures/SDCard.jpg)

#### Using [Ondra SD](https://sites.google.com/site/ondraspo186/3-ondra-sd)
* Use **ViLi ROM** (Ondra greets you with message "Zdraví Vás ONDRA")
* type # (ALT + E) and press Enter - if Ondra SD doesn't react press enter again or hold it longer. Or reset Ondra
* Ondra File Manager appears in few seconds after several beeps
* Choose file or folder and press Enter to change dir or load a file
* Shift changes the directory to the root of the SD card


### Loading games via audio line in

* connect your audio source (cassette player, mobile, ...) to MiSTer ADC (line in)
* Choose ViLi ROM
* press any key. Screen turn black and will flicker time to time. You can see text ".KÓD 1". This is ok. Ondra turns off the screen to give the CPU more time. Text ".KÓD x" will change as game will be loading to Ondra (x will raise from 1).
* start playing WAV file
* Enjoy the Ondra SPO 186 and the game :)

## Links

* http://www.sapi.cz/ondra/ondra.php
* https://github.com/72ka/Tesla_Ondra - New firmware and many new games for Ondra!
* [https://cs.wikipedia.org/wiki/Ondra (počítač)](https://cs.wikipedia.org/wiki/Ondra_(po%C4%8D%C3%ADta%C4%8D))
* https://sites.google.com/site/ondraspo186/ondra-spo-186
* https://github.com/omikron88/jondra
* https://www.clous.cz/ondra-spo-186/
* https://www.old-computers.com/museum/computer.asp?st=1&c=612

Some of them are only in Czech or Slovak, but Google translate is your friend :)
