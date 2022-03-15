# Ondra SPO 186
![Ondra SPO 186 image](/pictures/Ondra_th.jpg)  
[Ondra SPO 186](https://cs.wikipedia.org/wiki/Ondra_(po%C4%8D%C3%ADta%C4%8D)) is [Czechoslovakian](https://en.wikipedia.org/wiki/Czechoslovakia) 8-bit computer developed in 1985 in [Tesla Liberec](https://en.wikipedia.org/wiki/Tesla_(Czechoslovak_company)) by [Ing. Eduard Smutný](https://cs.wikipedia.org/wiki/Eduard_Smutn%C3%BD), Ing. Tomáš Smutný a Ing. Jan Mercl as a cheap school and home computer. Tesla produced about 2000 Ondra computers.
And this is its implementation in Verilog for [MISTEer](https://github.com/MiSTer-devel/Main_MiSTer/wiki) FPGA.

## Short demo video of this core on youtube

https://youtu.be/B2MRWTKYOYU

## Specifications

* CPU [U880](https://en.wikipedia.org/wiki/U880) @4MHz - [GDR](https://en.wikipedia.org/wiki/East_Germany) clone of [Z80](https://en.wikipedia.org/wiki/Z80)
* 64 kB RAM (10kB used by video RAM)
* 4 - 16 kB ROM (EPROM) 
* TV output 
* up to 320x255 pixels B/W (40 columns x 24 rows)
* relay for cassette player control - often used for "sound (click) signalling"
* 7 frequency sound generator (only 7 different given frequencies)
* one 20 pins connector for joystick, centronics parallel port (8-bit data out, Strobe_n out, Busy in), UART (Reserva In = RXD, Reserva Out = TXD)
* cassette player connector for SW load and save at 2400[Bd](https://en.wikipedia.org/wiki/Baud)

## Keyboard

Ondra has a modest keyboard with 37 keys only and so each key can serve for 2 or 3 different characters based on used modifier-key.

**Modifier keys:**  
**Ondra      -> PC Keyboard**  
Shift      -> Shift  
Symbols    -> Alt  
Ctrl       -> Ctrl  
Numbers    -> Tab  
ČS         -> Caps Lock (used for Czech diacritics)  

Each modifier key needs to be pressed (and hold) before pressing character key. 
Here is mapping Ondra keys to PC Keyboard. Please note modifier keys are in different colors as invoked characters on other keys.

![Ondra Keyboard mapping](/pictures/OndraKeyboardMapping_small.jpg)

[Here](/pictures/OndraKeyboardMapping.jpg) is bigger picture of keyboard mapping.

## Graphics generation (Video circuit)

Ondra has a very unique video circuit. Video address counter is made with 2x КР580ВИ53 programmable interval timers - Russian clone of [i8253](https://en.wikipedia.org/wiki/Intel_8253). In fact although Ondra was designed and manufactured in Czechoslovakia most of ICs were "Made in [USSR](https://en.wikipedia.org/wiki/Soviet_Union)".
Timers are used for generating [VSync and HSync](https://en.wikipedia.org/wiki/Analog_television#Vertical_synchronization) start pulses as well as for generaing video address itself. Cheap, simple but not easy :)
Advantage of this solution is that screen resolution can be programmatically changed. Disadvantage is that CPU has to be while screen is being drawn. CPU works on about 18-20% only.


## What is implemented

* CPU
* 64 kB RAM
* Keyboard
* Sound
* tape load via ADC MISTer connector (line in)
* load via serial port (MISTer user port)

## What is missing

* [Ondra SD](https://sites.google.com/site/ondraspo186/4-rom-card-sd) - modern HW for easier SW load and save from/to SD Card

## How to install core

* copy file **Ondra_SPO186_########.rbf** from **[releases](/releases)** folder to your MISTer SD card to **Computer** folder
(*######## stands here for date of version - you might want to delete earlier from SD card if you have some*)
* in MISTer menu navigate to Ondra_SPO186 item and start the core

## How to start

### Options
 

### Loading games via serial port (MISTer user port)

**This is interim solution before [Ondra SD](https://sites.google.com/site/ondraspo186/4-rom-card-sd) will be implemented to the core.**  

* You will need [Ondra Link](https://sites.google.com/site/ondraspo186/rs232/ondralink) SW on PC and some games. Here is direct [link](https://sites.google.com/site/ondraspo186/download/9-2-rom-a-utility/OndraLink32.zip?attredirects=0&d=1). Games can be found [here](https://sites.google.com/site/ondraspo186/download/9-1-hry).
* You also need MISTer user port cable with UART to USB converter. **Please mind MISTer FPGA uses 3.3V logic and your converter MUST support it. Otherwise you will destroy your MISTer!**
* Choose ViLi ROM in menu
* Run Ondra Link SW on your PC, select appropriate USB to UART converter and load game you want to transfer to Ondra
* On Ondra (MISTer) type # (Alt + e) and press Enter. Screen turns black and Ondra is waiting for UART data.
* On Ondra Link SW click on double arrow up. This loads turbo (increase transfer speed), then it plays a sound and continue loading game itself
* Enjoy the Ondra SPO 186 and the game :)

```diff
- Once again: Please mind MISTer FPGA uses 3.3V logic and your converter MUST support it. 
- Otherwise you will destroy your MISTer!
- I've warned you and you do it at your own risk!
```
Here is simple picture how you should wire your MISTer to UART-to-USB converter. And [here](/pictures/Mister_UART.jpg) is bigger picture as plugged into MISTer.

![User Port to UART USB](/pictures/UserPortToUART_USB.jpg)


### Loading games via ACD (audio line in)

* connect your audio source (cassette player, mobile, ...) to MISTer ADC (line in)
* Choose ViLi ROM
* press any key. Screen turn black and will flicker time to time. You can see text .KÓD 1. This is ok. Ondra turn off screen to gain more time for CPU and text .KÓD x will change as game will be loading to Ondra (x will raise from 1).
* start playing WAV file
* Enjoy the Ondra SPO 186 and the game :)

## For more info see

* http://www.sapi.cz/ondra/ondra.php
* https://cs.wikipedia.org/wiki/Ondra_(po%C4%8D%C3%ADta%C4%8D)
* https://sites.google.com/site/ondraspo186/home
* https://sites.google.com/site/ondra186/home 
* https://github.com/omikron88/jondra
* https://www.clous.cz/ondra-spo-186/

Some of them are only in Czech or Slovak, but Google translator is your friend :)
