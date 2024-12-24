MiSTer MultiComp
================

Port of Grant Searle's MultiComp to the MiSTer.

Ported by Cyril Venditti and Fred VanEijk.

Updated by S0urceror to use MiSTer image files, use all 4 machine types and have the MiSTer
UART connected to serial interface 2 of the core. The latter allows to use the core remotely.

## Using the MiSTer Serial Terminal/Console

### Connection Methods

1. USB: Connect the console port from the MiSTer FPGA to your computer using a USB cable.  

2. Network: Use SSH to connect to the MiSTer FPGA if you have a Wireless or Ethernet connection.

3. USB/Serial cable: For more information see the Serial Port section of the Altair8800_MiSTer repository:  <https://github.com/MiSTer-devel/Altair8800_MiSTer>

### Setting Up the Connection

#### For UART/Serial with PuTTY

- Connect at 115200 baud, 8 bits, no parity to the COM port.

#### USB to serial cable connection

##### User Port - extra USB 3.1A style connector on MiSTer

| USB  |  P7 |  Name  | PIN  |   Mister | emu wire |
|---|---|---|---|---|---|
|1  |  +5V |   +5V|
|2  |  2  |  TX   | SDA  |  AH9   | USER_IO[1] |
|3  |  1    |RX   | SCL   | AG11   | USER_IO[0] |
|4  |  GND   | GND|
|5  |  8   | DSR  |  IO10  |  AF15  |  USER_IO[5]|
|6  |  7   | DTR  |  IO11  | AG16   | USER_IO[4]|
|7  |  6   | CTS  |  IO12  |  AH11  |  USER_IO[3]|
|8  |  5   | RTS  |  IO13  |  AH12  |  USER_IO[2]|
|9  |  10  |  IO6 |   IO8  |  AF17  |  USER_IO[6]|
|10 |   Shield |   Shield |

##### FT232 USB to serial cable

|wire |name | mister usb IO port|
|---|---|---|
| Red|5V|N/C|
| Black|GND|GND|
| White|RXD|2|
| Green|TXD|3|
| Yellow|RTS|7|
| Blue|CTS|8|

#### For SSH with PuTTY

- Connect to the ip address of your MiSTer fpga.

#### Linux command line to establish the connection to the core

1. Identify the UART device:
   - Usually mapped to `/dev/ttyS1` or `/dev/ttyUSB0`
   - Use this command to help identify the correct device:

     ``` bash
     dmesg | grep tty
     ```

2. Access the serial terminal:
   - Use `screen` or `minicom`
   - Example command with `screen`:

     ``` bash
     screen /dev/ttyS1 115200
     ```

   - Replace `/dev/ttyS1` with the correct device identifier
   - Change 115200 to the appropriate baud rate if different

3. Enable Flow Control:
   - Use `stty`

     ``` bash
     stty -F /dev/ttyS1 crtscts
     ```

   - Replace `/dev/ttyS1` with the correct device identifier
   - This is done before the screen command

### Additional Information

For more details on console connection, refer to the official MiSTer documentation:
[MiSTer Console Connection Guide](https://MiSTer-devel.github.io/MkDocs_MiSTer/advanced/console/)

## The MiSTer OSD allows the access to four machines

### Z80 CP/M

You can now use both an external SDCard in the secondary slot and/or select the image file within MiSTer. Whatever you like.

### Formatting the SD Card and Installing CP/M

Note this procedure has to be performed from a tty terminal as descibed above.

#### Formatting the Drive

1. Load the Intel-HEX dump of the `FORMAT` program into memory by copying the contents of `FORM128.HEX` (for 128MB SD card utilization) into the terminal window.
2. The `FORMAT` program will reside at memory address `$5000` when loaded. To start the formatting process, execute the program by typing `G5000` and pressing ENTER.
3. You will see the following message:

```
CP/M Formatter by G. Searle 2012
```

4. After a few seconds, the formatting process will display:

```
ABCDEFGHIJKLMNOP
Formatting complete
```

Each drive is 8MB, so a 128MB SD card will have drives labeled A: to P:.

#### Installing CP/M

CP/M is installed on the first track of the disk. When booted, the first track is read into memory and executed. To install CP/M, follow these steps:

1. Load the Intel-HEX dump of CP/M by copying the contents of `CPM22.HEX` into the terminal window (this takes about 10 seconds).
2. Load the Intel-HEX dump of the CBIOS by copying the contents of `CBIOS128.HEX` (for 128MB total drive space) into the terminal window (this takes about 3 seconds).
3. Load the Intel-HEX dump of `PUTSYS` by copying the contents of `PUTSYS.HEX` into the terminal window.

The `PUTSYS` program also resides at memory address `$5000`. To transfer CP/M and CBIOS to the disk, execute `PUTSYS` by typing `G5000` and pressing ENTER. You will see:

```
CP/M System Transfer by G. Searle 2012
System transfer complete
```

At this point, CP/M is installed and ready for boot. You can now proceed with installing applications.

#### Boot CP/M from image file

Note that currently the `DOWNLOAD.COM` program is not working reliably (we hope to fix this in the future).  To get around the issues with `DOWNLOAD.COM` we have added the cpm image file and some Python based utilities, thus being able to get a working and custamizable CP/M sytem up and running.

In the CPM-sd-image directory, you will find a zip file that contains a cmp.img file that can be copied to the /media/fat/games/MultipComp directory.  This file can be used to boot CP/M without the SD card.  It contains the structure for disks A thru P with A having the DOWNLOAD program and other utilities available.  Use this as a strating point to place CP/M applications on the image.  See the Installing Applications section at <http://searle.x10host.com/Multicomp/cpm/fpgaCPM.html#InstallingCPM>.  

Note the process for this is mostly described in PART 2 - Using the Windows packager program.  The packager program is in windowsApp.  Again, this process requires the use of the tty terminal not the console, as you will be pasting the file data into the terminal.

We have also added a zip file in the CPM-sd-image directory with a set of application pre installed.  See cpm-apps.zip.  This file can also be copied to the /media/fat/games/MultipComp directory and mounted.  It contains 5 drives A,C,D,E, and F where A still only has the DOWNLOAD program and the other drives contain the following.  The cpm.zip file contains just the basic utilities described in the  [CPM-sd-image](CPM-sd-image/README.MD)  directory.

| C:              | D:                | E:               | F:              |
|-----------------|-------------------|------------------|-----------------|
| 0_FILES.TXT     | 0_GAMES           | 0_OLDUTILS       | 0_NEWUTILS      |
| 1_BDS_TINY_C    | 1_MUMATHSIMP      | 1_F80M80BASIC    | 1_ROMS          |
| 2_APL           | 2_CROSSTALK       | 2_AZTEC_C_106D   | 2_ZSYSTEM       |
| 3_JANUS_ADA15   | 3_QTERM43         | 3_TPASCAL3       | 3_MICROPRO      |
| 4_MS_COBOL      | 4_CLINK           | 4_DXFORTH401     | 4_MULTIPLAN     |
| 5_PILOT         | 5_SUPERSFTUTIL    | 5_PLI14          | 5_DBASEII       |
| 6_SYSLIB        | 6_RCPM            | 6_ALGOLM         | 6_DWG_APPS      |
| 7_BBC BASIC     | 7_DDTZ SOURCES    | 7_SUPERCALC      | 8_MICROSHELL    |

Note the use of user numbers here i.e. 0_, 1_ etc..  
(Not all the applications were tested to run, so you are on your own)

The applications were obtained from the Obsolescence Guaranteed site.

Included in the CPM-sd-image directory are also some python scripts to initialize/build the image for the CP/M disks.  Along with a script in the transient packages directory that can extract the .COM files from the package (note this was used to provide some content to build the cpm.img file provided in CPM-sd-image directory).

To use the Python scripts we recommend using Visual Studio Code and opening the MultiComp_MiSTer directory as its project location.  Them just run the Python scripts from within Visual Studio Code.

__Other useful links.__

For convenience you can use the Multicomp FPGA - CP/M Demo Disk from Obsolescence Guaranteed:
<http://obsolescence.wixsite.com/obsolescence/multicomp-fpga-cpm-demo-disk>

After you have flashed the CP/M Demo Disk to the SD Card you will have to use the secondary SD Card on the MiSTer on the I/O Board:
<https://github.com/MiSTer-devel/Wiki_MiSTer/wiki/IO-Board>

Using CP/M - from Grant Searle website:
<http://searle.x10host.com/Multicomp/cpm/fpgaCPM.html>

DeRamp - This website focuses on early personal computers from the mid 70s into the early 80s. Here you'll find resources for restoring and maintaining many of the great computers and peripherals from this era, in addition it has a Downloads section where you can find the bits for many applications. <https://deramp.com/>

### Z80 Basic

SGN, INT, ABS ,USR, FRE, INP, POS, SQR, RND ,LOG, EXP, COS, SIN, TAN, ATN, PEEK ,DEEK ,LEN, STR$, VAL ,ASC, CHR$ ,LEFT$,
RIGHT$, MID$, END, FOR, NEXT, DATA, INPUT, DIM, READ, LET, GOTO, RUN, IF, RESTORE, GOSUB, RETURN, REM, STOP, OUT, ON,
NULL, WAIT,  DEF, POKE, DOKE, LINES, CLS, WIDTH, MONITOR, PRINT, CONT, LIST, CLEAR, NEW, TAB, TO, FN, SPC, THEN, NOT,
STEP, +, -, *, /, ^, AND, OR, >, <, =

PLUS additional implementations here (making it version 4.7b):

HEX$(nn) - convert a SIGNED integer (-32768 to +32767) to a string containing the hex value

BIN$(nn) - convert a SIGNED integer (-32768 to +32767) to a string containing the binary value

&Hnn - interpret the value after the &H as a HEX value (signed 16 bit)

&Bnn - interpret the value after the &B as a BINARY value (signed 16 bit)

### 6502 Basic - No SD card support (No CSAVE/CLOAD)

END, FOR, NEXT, DATA, INPUT, DIM, READ, LET, GOTO, RUN, IF, RESTORE, GOSUB, RETURN, REM, STOP, ON, NULL, WAIT, DEF, POKE, PRINT,
CONT, LIST, CLEAR, NEW, TAB(, TO, FN, SPC(, THEN, NOT, STEP, SGN, INT, ABS, USR, FRE, POS, SQR, RND, LOG, EXP, COS, SIN, TAN, ATN,
PEEK, LEN, STR$, VAL, ASC, CHR$, LEFT$, RIGHT$, MID$, +, -, *, /, ^, AND, OR, >, +, <

### 6809 Basic - No SD card support(No CSAVE/CLOAD)

FOR, GO, REM, ELSE, IF, DATA, PRINT, ON GOSUB, ON GOTO, INPUT, LINE INPUT, END, NEXT, DIM, READ, RUN, RESTORE, RETURN, STOP, POKE,
CONT, LIST, CLEAR, NEW, EXEC, TAB, TO, SUB, THEN, NOT, STEP, +, -, *, /, ^, AND, OR, >, =, <, DEL, DEF, LET, RENUM, FN, &, &H, TRON,
TROFF, EDIT, SGN, INT, ABS, USR, RND, SIN, PEEK, LEN, STR$, VAL, ASC, CHR$, LEFT$, RIGHT$, MID$, INKEY$, MEM, ATN, COS, TAN, EXP, FIX,
LOG, SQR, HEX$, VARPTR, INSTR, STRING$, MID$ (MODIFICATION), POS

<http://searle.x10host.com/Multicomp/#BASICKeywords>

# MultiComp OSD Configuration

This section describes the On-Screen Display menu configuration for the MultiComp system, providing control over CPU selection, storage, and communication parameters.

## Menu Structure

### System Control

- __Mount *.IMG__: Provide the image in the games/Multicomp directory if no image is specified it will attempt to use the secondary SD card
- __Reset after Mount__: Configures system behavior after mounting storage - Options: No, Yes
- __Reset__: System reset function

### CPU and ROM Configuration

- __CPU-ROM Selection__:
- Z80 with CP/M
- Z80 with BASIC
- 6502 with BASIC
- 6809 with BASIC

### Communication Settings

- __Baud Rate__:
- 115200
- 38400
- 19200
- 9600
- 4800
- 2400
- __Serial Port__:
- Console Port - use the MiSTer console port
- User IO Port - use the MiSTer user I/O USB 3.1 port
- __Flow Control__:
- None - no hardware flow control
- RTS/CTS - enable hardware flow control using RTS/CTS signals

### Additional Information
The OSD includes version information and build date tracking. This configuration interface provides comprehensive control over the MultiComp's core functionality, allowing users to switch between different CPU architectures, operating systems, and I/O configurations.

The menu system is designed for straightforward navigation and configuration of the MultiComp's essential features, making it accessible for both basic setup and advanced customization needs.

## Troubleshooting

### Serial Communication Issues

- Only the Z80 supports the external uart at this time
- If no response when typing:
  - Verify correct baud rate is selected
  - Check that the correct serial port is selected (Console vs User IO)
  - Try enabling/disabling flow control
  - For User IO port, verify cable connections match pinout documentation

### Storage Issues

- If unable to access CP/M:
- Verify Secondary SD card is properly formatted or an image is selected in the OSD
- Try toggling "Reset after Mount" option
- Once either the secondary SD card is selected or the Image file is selected a complete MiSTer re-start is required to change the selection i.e. it can not be changed with a reset of the core.

### System Stability

- 6809 Basic had known reset issues (inherited from original design) the core was actually being reset but only a warm reset, now it supports a cold or warm reset with a prompt
- If system becomes unresponsive:
  - Use OSD Reset function
  - Try power cycling the MiSTer
  - Verify correct CPU-ROM selection for your intended use

### Known Limitations

- If the DOWNLOAD\.COM program has reliability issues in CP/M use a slower baud rate, we have had some sucess at 2400 and 9600 baud, 115200 baud seems to consistantly drop characters even with flow control enabled
- 6502 and 6809 Basic variants do not support SD card operations (no CSAVE/CLOAD)\

### License

__Software and VHDL project download link__

By downloading these files you must agree to the following: The original
copyright owners of ROM contents are respectfully acknowledged.  Use of the
contents of any file within your own projects is permitted freely, but any
publishing of material containing whole or part of any file distributed
here, or derived from the work that I have done here will contain an
acknowledgment back to myself, Grant Searle, and a link back to this page.
Any file published or distributed that contains all or part of any file
arom this page must be made available free of charge.

### Original Author

Grant Searle

### URL

[Grant's MULTICOMP pick and mix computer](http://searle.x10host.com/Multicomp/)

# MiSTer MultiComp BASIC Keywords Reference

## Keywords by Category

### Mathematical Functions

| Keyword | Z80 | 6502 | 6809 | Description | Usage Example |
|---------|-----|------|------|-------------|---------------|
| ABS | ✓ | ✓ | ✓ | Returns absolute value | `X = ABS(-5)` |
| ATN | ✓ | ✓ | ✓ | Returns arctangent | `A = ATN(1)` |
| COS | ✓ | ✓ | ✓ | Returns cosine | `C = COS(3.14159/2)` |
| EXP | ✓ | ✓ | ✓ | Returns e raised to power | `E = EXP(2)` |
| FIX | - | - | ✓ | Truncates decimal portion | `F = FIX(3.7)` |
| INT | ✓ | ✓ | ✓ | Returns integer portion | `I = INT(5.7)` |
| LOG | ✓ | ✓ | ✓ | Returns natural logarithm | `L = LOG(100)` |
| SGN | ✓ | ✓ | ✓ | Returns sign of number (-1,0,1) | `S = SGN(-42)` |
| SIN | ✓ | ✓ | ✓ | Returns sine | `S = SIN(3.14159/2)` |
| SQR | ✓ | ✓ | ✓ | Returns square root | `R = SQR(16)` |
| TAN | ✓ | ✓ | ✓ | Returns tangent | `T = TAN(0.785)` |

### String Functions

| Keyword | Z80 | 6502 | 6809 | Description | Usage Example |
|---------|-----|------|------|-------------|---------------|
| ASC | ✓ | ✓ | ✓ | Returns ASCII value of character | `A = ASC("A")` |
| CHR$ | ✓ | ✓ | ✓ | Returns character for ASCII value | `C$ = CHR$(65)` |
| INSTR | - | - | ✓ | Searches for substring | `I = INSTR(A$, "FIND")` |
| LEFT$ | ✓ | ✓ | ✓ | Returns leftmost characters | `L$ = LEFT$("HELLO", 2)` |
| LEN | ✓ | ✓ | ✓ | Returns string length | `L = LEN("TEST")` |
| MID$ | ✓ | ✓ | ✓ | Returns substring | `M$ = MID$("HELLO", 2, 2)` |
| RIGHT$ | ✓ | ✓ | ✓ | Returns rightmost characters | `R$ = RIGHT$("WORLD", 3)` |
| STR$ | ✓ | ✓ | ✓ | Converts number to string | `S$ = STR$(123)` |
| STRING$ | - | - | ✓ | Creates string of repeated characters | `S$ = STRING$(5, "*")` |
| VAL | ✓ | ✓ | ✓ | Converts string to number | `V = VAL("123")` |

### Program Control

| Keyword | Z80 | 6502 | 6809 | Description | Usage Example |
|---------|-----|------|------|-------------|---------------|
| CONT | ✓ | ✓ | ✓ | Continues program execution | `CONT` |
| END | ✓ | ✓ | ✓ | Ends program | `END` |
| FOR/NEXT | ✓ | ✓ | ✓ | Loop structure | `FOR I=1 TO 10 : PRINT I : NEXT I` |
| GOSUB | ✓ | ✓ | ✓ | Calls subroutine | `GOSUB 1000` |
| GOTO | ✓ | ✓ | ✓ | Jumps to line number | `GOTO 100` |
| IF/THEN | ✓ | ✓ | ✓ | Conditional execution | `IF X=5 THEN PRINT "YES"` |
| ON GOSUB | - | - | ✓ | Multiple branch subroutine | `ON X GOSUB 100,200,300` |
| ON GOTO | - | - | ✓ | Multiple branch jump | `ON X GOTO 100,200,300` |
| RETURN | ✓ | ✓ | ✓ | Returns from subroutine | `RETURN` |
| STOP | ✓ | ✓ | ✓ | Halts program execution | `STOP` |

### Data and Variables

| Keyword | Z80 | 6502 | 6809 | Description | Usage Example |
|---------|-----|------|------|-------------|---------------|
| DATA | ✓ | ✓ | ✓ | Stores program data | `DATA 100,200,"TEXT"` |
| DEF FN | ✓ | ✓ | ✓ | Defines function | `DEF FNA(X)=X*X+2` |
| DIM | ✓ | ✓ | ✓ | Declares array dimensions | `DIM A(10),B$(20)` |
| INPUT | ✓ | ✓ | ✓ | Accepts user input | `INPUT "Name?";N$` |
| LET | ✓ | ✓ | ✓ | Assigns variable value | `LET A=5` or `A=5` |
| LINE INPUT | - | - | ✓ | Inputs entire line | `LINE INPUT "Text?";A$` |
| READ | ✓ | ✓ | ✓ | Reads DATA values | `READ A,B,C$` |
| RESTORE | ✓ | ✓ | ✓ | Resets DATA pointer | `RESTORE` |

### System and Memory

| Keyword | Z80 | 6502 | 6809 | Description | Usage Example |
|---------|-----|------|------|-------------|---------------|
| DEEK | ✓ | - | - | Reads word from memory | `D = DEEK(16384)` |
| DOKE | ✓ | - | - | Writes word to memory | `DOKE 16384,12345` |
| FRE | ✓ | ✓ | - | Returns free memory | `F = FRE(0)` |
| INP | ✓ | - | - | Reads from I/O port | `I = INP(255)` |
| MEM | - | - | ✓ | Returns memory size | `M = MEM` |
| OUT | ✓ | - | - | Writes to I/O port | `OUT 255,10` |
| PEEK | ✓ | ✓ | ✓ | Reads byte from memory | `P = PEEK(16384)` |
| POKE | ✓ | ✓ | ✓ | Writes byte to memory | `POKE 16384,255` |
| USR | ✓ | ✓ | ✓ | Calls machine language routine | `U = USR(32768)` |
| VARPTR | - | - | ✓ | Returns variable address | `V = VARPTR(A)` |

### Program Editing

| Keyword | Z80 | 6502 | 6809 | Description | Usage Example |
|---------|-----|------|------|-------------|---------------|
| CLEAR | ✓ | ✓ | ✓ | Clears variables | `CLEAR` |
| CLS | ✓ | - | - | Clears screen | `CLS` |
| DEL | - | - | ✓ | Deletes program lines | `DEL 100-200` |
| EDIT | - | - | ✓ | Edits program line | `EDIT 100` |
| LIST | ✓ | ✓ | ✓ | Lists program | `LIST` or `LIST 100-200` |
| NEW | ✓ | ✓ | ✓ | Clears program | `NEW` |
| RENUM | - | - | ✓ | Renumbers program lines | `RENUM 100,10` |
| RUN | ✓ | ✓ | ✓ | Executes program | `RUN` or `RUN 100` |
| TRON/TROFF | - | - | ✓ | Trace mode on/off | `TRON` or `TROFF` |

### Z80 BASIC Specific Extensions (v4.7b)

| Keyword | Description | Usage Example |
|---------|-------------|---------------|
| HEX$(nn) | Converts signed integer to hex string | `H$ = HEX$(255)` |
| BIN$(nn) | Converts signed integer to binary string | `B$ = BIN$(15)` |
| &Hnn | Interprets nn as hexadecimal value | `X = &H1F` |
| &Bnn | Interprets nn as binary value | `Y = &B1010` |

### Operators

| Operator | Z80 | 6502 | 6809 | Description | Usage Example |
|----------|-----|------|------|-------------|---------------|
| + | ✓ | ✓ | ✓ | Addition | `A = B + C` |
| - | ✓ | ✓ | ✓ | Subtraction | `X = Y - Z` |
| * | ✓ | ✓ | ✓ | Multiplication | `P = Q * R` |
| / | ✓ | ✓ | ✓ | Division | `D = N / 2` |
| ^ | ✓ | ✓ | ✓ | Exponentiation | `E = 2 ^ 3` |
| AND | ✓ | ✓ | ✓ | Logical AND | `IF A>0 AND B<10 THEN...` |
| OR | ✓ | ✓ | ✓ | Logical OR | `IF X=0 OR Y=0 THEN...` |
| NOT | ✓ | ✓ | ✓ | Logical NOT | `IF NOT A THEN...` |
| > | ✓ | ✓ | ✓ | Greater than | `IF X > 10 THEN...` |
| < | ✓ | ✓ | ✓ | Less than | `IF Y < 5 THEN...` |
| = | ✓ | ✓ | ✓ | Equal to | `IF A = B THEN...` |
| & | - | - | ✓ | Bitwise AND | `R = X & Y` |

Notes:
1. Z80 BASIC is the most commonly used version for CP/M systems
2. 6502 BASIC is a Microsoft BASIC variant
3. 6809 BASIC has the most extensive command set but lacks storage commands
4. None of the 6502 and 6809 variants support CSAVE/CLOAD operations

Each example shows the most common usage pattern for the command. Many commands have additional optional parameters or alternate syntaxes not shown in these basic examples.
