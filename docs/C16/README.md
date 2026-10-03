# [Commodore 264 (C16 and Plus/4)](https://www.c64-wiki.com/wiki/Commodore-264_series) for [MISTer](https://github.com/MiSTer-devel/Main_MiSTer/wiki)

MiSTer port by Sorgelig

## Features

This port has the following changes and enhancements:

- Choose between C16(64KB) and Plus/4
- Cartridge support (*.BIN) for Plus/4 model
- Disk with write support (*.D64)
- Partly/fully loadable system ROM for C1541, Kernal, Basic, Function.
- Scandoubler with HQ2x and Scanlines
- Joystick with swap function
- Reset procedure has been improved and should be stable now.

Multiple alternative Kernal ROMs can be loaded from SD card. Put for example kernal.rom, kernal2.rom, jiffy.rom, etc. into C16 folder or subfolder.

Content of kernal.rom: C1541 + kernal + basic + func_low + func_high  
Each part is 16KB.   
You can load only part of a whole ROM, for example only C1541+kernal (JiffyDOS).

TED core is based on [FPGATED](https://hackaday.io/project/11460-fpgated) v1.9. Release notes for versions after v1.3 are in the header of `rtl/ted.v`.

### Original ReadMe (has outdated and non-related info)

```
FPGATED
Copyright 2013-2021 Istvan Hegedus

FPGATED is a cycle exact FPGA core for the MOS 7360/8360 TED chip written in verilog language.
MOS 7360/8360 is a complex chip providing graphic, sound, bus and memory control for the Commodore 264
series 8 bit computers, namely the Commodore Plus4, Commodore 16 and Commodore 116.

In addition to the TED core modul FPGATED contains a simple C16 implementation using TED core and Gadget Factory's 
Papilio One/Pro platform with a customized IO wing called Papilio TEDWing. This release contains two different 6502
CPU cores which can be chosen by the user during compilation.
The original 6502 CPU core used for FPGATED is created by Peter Wendrich in vhdl and is taken from the FPGA64 project
with the permission of the author. The second version is T65 from opencores.com.

For more technical details and building Papilio TEDWing module visit https://hackaday.io/project/11460-fpgated

Files

basic_rom.v         C16/Plus4 Basic rom module
c16.v               This is the TOP module of FPGATED implementing a Commodore 16
c16_keymatrix.v     C16/Plus4 keyboard matrix emulation module
c16_testbench.v     C16 testbench for simulation
colors_to_rgb.v     TED color code conversion module to 12bit RGB values
cpu65xx_e.vhd       6502 core vhdl header (by Peter Wendrich)
cpu65xx_fast.vhd    6502 core vhdl code   (by Peter Wendrich)
dram.v              DRAM module for internal FPGA SRAM memory implementation
kernal_rom.v        C16/Plus4 Kernal rom module
mos6529.v           MOS 6529 IO chip emulation module
mos8501.v           MOS 8501 CPU shell for 6502 core
mos8501_t65.v       MOS 8501 CPU shell for T65 core
palclockgen.v       Xilinx DCM module for PAL system clock signal (for Spartan3E)
ps2receiver.v       PS2 keyboard receiver module
ram.v               Simulated RAM for testbench
ted.v               MOS 7360/8360 FPGA core
T65.vhd             T65 MOS 6502 core top module
T65_ALU.vhd         T65 core ALU
T65_MCode.vhd       T65 core submodule
T65_Pack.vhd        T65 core submodule

basic.hex           C16/Plus4 BASIC rom hexadecimal dump
Diag264_NTSC.hex    Diag264 NTSC kernal hexadecimal dump
Diag264_PAL.hex     Diag264 PAL kernal hexadecimal dump
kernal_NTSC.hex     C16/Plus4 NTSC Kernal rom hexadecimal dump
kernal_PAL.hex      C16/PLus4 PAL Kernal rom hexadecimal dump

TEDwing.ucf         Xilinx user constraint file for Papilio TEDwing pinout (for Papilio One board)
TEDwingPro.ucf      Xilinx user constraint file for Papilio TEDwing pinout (for Papilio Pro board)

bin2hex.pl          Perl script for creating hex dump of binary rom image files

Installation instructions are for Xilinx FPGA platforms but the source files with the exception of palclockgen.v
and Xilinx ucf files can be used for other vendor's FPGAs. 
Some modules are using Xilinx specific (* RAM_STYLE="BLOCK" *) directive for forcing the synthesis tool to 
use FPGA internal block ram for certain arrays. In case of other vendor's FPGAs see vendor specific documentation
for generating block ram.

Building FPGATED on the Papilio Platform requires a suitable wing. One can use the Arcade megawing but it lacks
external memory and IEC bus for peripherial connections. Thus I recommend to build TEDwing designed by me. Look for
eagle PCB and schematic files in FPGATED source package.
Although FPGATED can be synthetised to a Papilio One board using Spartan3E chip, I recommend to go for Papilio Pro
platform which has external 8Mbyte SDRAM and a Spartan 6 LX9 FPGA which has more internal sram. In both cases there
are plenty of free resources on the FPGA for FPGATED.

Installation instructions:

1. Create a new project in Xilinx ISE Webpack and choose the proper FPGA family for the implementation.
2. Choose to use HDL verilog and vhdl for the design.
3. Add all *.v files to the project
4. Using ISE DCM wizard create a clock generator for FPGATED. 
   Use CLKFX output of DCM and specify 28.37515MHz PAL or 28.63636MHz for NTSC system
   This will be the main FPGA clock connected to the clk signal of all modules
   Modify C16.v to use proper DCM instantiation (out of scope of this document)
5. Open kernal_rom.v and uncomment the proper Kernal file (Kernal_NTSC.hex or Kernal_PAL.hex) to use.
   You can even use a custom rom or JiffyDos if you own it (JiffyDos is working fine, I have tested).
   Diag264 roms are included for testing purposes.
6. If you don't use TEDwing modify or replace TEDwing.ucf file for proper pinout setup
7. Video output of FPGATED is a PAL/NTSC RGBS signal so you will need a VGA->scart custom cable to
   hook it up to a monitor or television. The cable is identical to minimig scart cables (see internet for wiring diagram)

Enjoy FPGATED.

See https://hackaday.io/project/11460-fpgated for detailed installation instructions.

TED module signals:

 input wire clk                 main FPGA clock must be 4*dot clk so 28.375152MHz for PAL and 28.63636 for NTSC 
 input wire [15:0] addr_in      16 bits address bus in
 output wire [15:0] addr_out    16 bits address bus out
 input wire [7:0] data_in       8 bits data bus in
 output wire [7:0] data_out     8 bits data bus out
 input wire rw                  RW signal to TED, low during write, high during read (real TED pulls it high during reads)
 output wire cpuclk             this is a CPU clock out for external real CPU
 output wire [6:0] color        7 bits color code using TED's color palette values
 output wire csync              composite sync signal for PAL/NTSC displays
 output wire irq                active low IRQ signal to CPU
 output wire ba                 BA (or with other name RDY) signal to 8501 CPU 
 output reg mux                 MUX signal, identical to original
 output reg ras                 RAS signal, identical to original
 output reg cas                 CAS signal, identical to original
 output reg cs0                 CS0 signal, identical to original
 output reg cs1                 CS1 signal, identical to original
 output reg aec                 AEC signal, identical to original
 output wire snd                Sound output. PWM modulated sound, needs a low pass filter outside the FPGA
 input wire [7:0] k             Keyport in, same as in original TED
 output wire cpuenable          a short enable signal used for synchronous FPGA 6502 CPU clocking
 output reg pal,                pal/ntsc flag (PAL=0 NTSC=1). For fpga clock and chroma generator 
 output wire hsync,             horizontal sync for composite video generator or scandoubler
 output wire vsync,             vertical sync for composite video generator or scandoubler
 output wire burst,             burst enabler signal for chroma generator
 output wire even,              signals even scanlines for PAL chroma encoder
 output wire data_oe            used for databus OE signal when TED places data on bus (active high)

FPGATED v1.3 is now highly accurate implementation of MOS8360R2.
A separate chroma/luma generator module is already developed and tested successfuly in a C16 and Plus4, 
however the source code of these modules are not public yet (sorry). 
Physical drop-in prototype works already fine, final production version is being developed.
Follow https://hackaday.io/project/11460-fpgated

Future improvement possibilities (which will work on a real C16/Plus4):

- scandoubler for VGA displays (prototype is still 15KHz only)
- HDMI output
- SID cart integrated inside fpga
- additional kernals stored inside the fpga

Release notes:

07.14.2016  1.0     First public release of FPGATED
08.08.2016  1.0.1   Minor bugs fixed in C16.v module. c16_datalatch size fixed to 8 bits, synchronous reset signal activates now while reset button is kept pressed.
17.08.2016  1.1     Joystick emulation is added to c16.v and c16_keymatrix.v modules. TED core module has not been changed.
                    Joystick emulation works on the numeric keypad. By default joy0 is active and the direction keys on numeric keypad act as joystick directions,
                    0 key is the fire button. Pressing F11 changes between joy0 and joy1. The 2 joysticks cannot be active on keyboard at the same time.
                    Implementing real joystick output is not difficult from this point, it can be combined with emulated joysticks too.
04.10.2019  1.2     New ted.v core (v1.1) released and included. FLI bug has been fixed, now displays FLI images properly.
13.01.2021  1.3     New ted core (v1.3) released. DMA delay behaviour fixed thanks to gyurco. Now challenging games are running properly (Alpharay,Pets Rescue)

Contact: Contact me via Hackaday (https://hackaday.io/hege)  or Plus4world (http://plus4world.powweb.com/members/Hege) 

Special Thanks to Levente Harsfalvi for the technical information on TED sound generators and for some other important hints!
Thanks to Laszlo Jozsef for the color conversion table!
Thanks to gyurco for the DMA delay fix!
```
