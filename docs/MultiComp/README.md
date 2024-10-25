MISTer MultiComp
================

Port of Grant Searle's MultiComp to the MiSTer.

Ported by Cyril Venditti and Fred VanEijk.

Updated by S0urceror to use MiSTer image files, use all 4 machine types and have the MiSTer
UART connected to serial interface 2 of the core. The latter allows to use the core remotely.

## Using the MiSTer Serial Terminal/Console

### Connection Methods

1. USB: Connect the console port from the MiSTer FPGA to your computer using a USB cable.
2. Network: Use SSH to connect to the MiSTer FPGA if you have a Wireless or Ethernet connection.

### Setting Up the Connection

#### For UART/Serial with PuTTY

- Connect at 115200 baud, 8 bits, no parity to the COM port.

#### For SSH with PuTTY

- Connect to the ip address of your MISTer fpga.

#### Linux command line to establish the connection to the core

1. Identify the UART device:
   - Usually mapped to `/dev/ttyS1` or `/dev/ttyUSB0`
   - Use this command to help identify the correct device:

     ```
     dmesg | grep tty
     ```

2. Access the serial terminal:
   - Use `screen` or `minicom`
   - Example command with `screen`:

     ```
     screen /dev/ttyS1 115200
     ```

   - Replace `/dev/ttyS1` with the correct device identifier
   - Change 115200 to the appropriate baud rate if different

### Additional Information

For more details on console connection, refer to the official MiSTer documentation:
[MiSTer Console Connection Guide](https://mister-devel.github.io/MkDocs_MiSTer/advanced/console/)

## The MiSTer OSD allows the access to four machines

### Z80 CP/M

You can now use both an external SDCard and/or select the image file within MiSTer. Whatever you like.

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

In the CPM-sd-image directory, you will find a zip file that contains a cmp.img file that can be copied to the /media/fat/games/MultipComp directory.  This file can be used to boot CP/M without the SD card.  It contains the structure for disks A thru P with A having the DOWNLOAD program available.  Use this as a strating point to place CP/M applications on the image.  See the Installing Applications section at <http://searle.x10host.com/Multicomp/cpm/fpgaCPM.html#InstallingCPM>

Note the process for this is mostly described in PART 2 - Using the Windows packager program.  The packager program is in windowsApp.  Again, this process requires the use of the tty terminal not the console, as you will be pasting the file data into the terminal.

We have also added a zip file in the CPM-sd-image directory with a set of application pre installed.  See cpm-apps.zip.  This file can also be copied to the /media/fat/games/MultipComp directory and mounted.  It contains 5 drives A,C,D,E, and F where A still only has the DOWNLOAD program and the other drives contain the following.

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

Included in the CPM-sd-image directory are also some python scripts to initialize/build the image for the CP/M disks.

__Other useful links.__

For convenience you can use the Multicomp FPGA - CP/M Demo Disk from Obsolescence Guaranteed:
<http://obsolescence.wixsite.com/obsolescence/multicomp-fpga-cpm-demo-disk>

After you have flashed the CP/M Demo Disk to the SD Card you will have to use the secondary SD Card on the MiSTer on the I/O Board:
<https://github.com/MiSTer-devel/Wiki_MiSTer/wiki/IO-Board>

Using CP/M - from Grant Searle website:
<http://searle.x10host.com/Multicomp/cpm/fpgaCPM.html>

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

### Note

The 6809 Basic is not resetting  properly. This issue is present in the original Grant Searle's MultiComp project
