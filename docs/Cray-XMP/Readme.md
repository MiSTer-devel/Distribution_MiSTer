# [CRAY X-MP](https://en.wikipedia.org/wiki/Cray_X-MP) for MiSTer

**This was developed using AI.**

This core is a CRAY X-MP supercomputer running the Cray Operating System,
COS 1.17. You start the machine the way its operators did: answer the
questions on the operator's console (**F1**), dead start COS, log on at the
station (**F2**) and submit batch jobs. You can also work with COS directly at
the station: write a program in its text editor, assemble or compile it and
run it. If the OS ever asks for a year make sure it is before 2000.

## What you need

- A [MiSTer](https://mister-devel.github.io/MkDocs_MiSTer/) with a keyboard. No SDRAM module is needed.
- 700 MB free on the SD card.

## Setup

1. Copy `Cray-XMP_YYYYMMDD.rbf` from [releases](releases) to the `_Computer` folder on the SD card.
2. Unpack `Cray-XMP_COS-1.17.zip` from [releases](releases) onto the SD card, so that its `games`
   folder goes into the card's.

## Starting COS

1. Start **Cray-XMP** from the Computer menu. The screen says
   `Load a boot file from the menu to start it.`
2. Open the menu (**F12**) and choose these four files of `games/Cray-XMP`, in this order. The
   menu closes after each one; open it again for the next.
   - **Expander disk**: `exp_disk.img`
   - **Disk drives**: `drives.img`
   - **Printer file**: `printer.txt`
   - **Load boot file**: `cos117.ios`, which starts the machine
3. The screen now is the operator's console (**F1**). Wait for `ENTER DATE [MM/DD/YY]` and type
   a date, such as `10/05/89`. **The year must be 80 to 99.**
4. Type a time, such as `09:30:00`.
5. Type `START COS_117 DEADSTART` and wait for `START COMPLETE`.
6. Type `STATION`, then press **F2** to see the station.
7. On the station (**F2**) type `LOGON`.
8. Type `STMSG`. COS asks for configuration changes. Type `REPLY,0,GO`.
9. Type `STMSG,I` to see how far start-up is, until the list ends with `STARTUP COMPLETE`.
10. Type `CLASS,ALL,ON`, then `LIMIT,5`, so that jobs can run.

Every line ends with RETURN, and Backspace takes back the last character. Backspace is the
only way to correct a line: there is no history, and the arrow keys and Home do not move
within it. Right arrow and Home spoil the line. Commands are in
capital letters; Caps Lock is on when the core starts. Type them as they are shown: none of
the commands above ends with a period, and where one further down does, the period is part
of it.

## Switching off

COS needs no shutdown. A dataset is on the SD card when COS has answered its `SAVE` with
`SAVE COMPLETE`, and the next dead start finds it. What is lost are jobs that still wait or
run and the texts of an open session, so wait for a job's `END OF JOB` on the printer
(**F3**) and leave a session with `/LOGOFF` first.

## Running a job

1. On the station (**F2**) type `SUBMIT,JFTN`. The job compiles a small FORTRAN program and runs it.
2. Press **F3** to see what the printer prints.

`SUBMIT,JCAL` does the same with a program in assembly language, and `SUBMIT,JLISP` runs a few
lines of LISP. The printout is also in `games/Cray-XMP/printer.txt` on the SD card, after what
was printed before. `FSTAT` on the operator's console (**F1**) lists the files the jobs come from.

## Working at the station

On the station (**F2**) COS also takes statements one at a time and answers on the screen.
**A COS statement ends with a period, which has to be typed.** The station's own commands
and those of the operator's console (**F1**) have none, and neither have those that begin
with `/`.

1. On the operator's console (**F1**) type `IAIOP LOG`.
2. On the station (**F2**) type `IAC`, then `/LOGON`. COS now asks for statements with a `!`.
3. Type `ACCOUNT,AC=CRAY,US=SYSTEM.` COS prints a row of dots under it.
4. Type `AUDIT.` to list the permanent datasets.
5. `/LOGOFF` ends the session, and `/BYE` brings the station's own display back.

## Writing a program

Programs are written in a session, with the text editor TEDI
([manual](http://www.bitsavers.org/pdf/cray/COS/SG-0055A-01_Text_Editor_%5BTEDI%5D_Users_Guide_Dec84.pdf)).

- `TEDI.` starts it. The first time it asks `DN:` for a name for the text. Later it opens the
  last text again, and `O` asks for another name.
- `AL` adds lines. The prompt turns from `*` into `&`, and every line you type goes into the
  text as it is. **A line that holds only a period (`.`) ends this**: it is not added, and the
  `*` comes back. That period is the only one: the lines of a program do not end with one.
- `T 1,30` shows lines 1 to 30 with their numbers. A text that is opened again ends with a
  line `<EOF>`; `BL 8` adds lines before line 8.
- To put a wrong line right, `RL 4` takes line 4 out and lets you type it again; end with the
  line that holds only a period. `DL 4` deletes line 4. `RP 4` changes a part of it: TEDI asks
  `P:` for the part that is wrong and `R:` for what belongs there.
- `END` saves the text and leaves. `QUI` leaves without saving.
- If the editor does not do what you expect: the line with only a period gets you out of
  adding lines, `QUI` out of the editor, and `/ABORT` stops it wherever it is and brings back
  the `!` of COS.
- `?` lists all its commands.

A text lasts until the session ends. `SAVE,DN=PROG.` keeps the text `PROG` as a permanent
dataset, and `ACCESS,DN=PROG.` gets it back in a later session. The editor shows a saved text
and does not change it. To change one, type `RELEASE,DN=PROG.`, `ACCESS,DN=PROG,UQ.` and
`DELETE,DN=PROG.`, which leave you the text without its saved copy; then edit it and save it
again.

### In assembly language

In the [Cray Assembly Language](http://www.bitsavers.org/pdf/cray/CAL/SR-2003_CAL_Assembler_Version_2_Feb86.pdf)
a line is a label, an instruction and its operands, with spaces between them. The label is a
name for that place in the program and starts at the very beginning of the line; most lines
have none. **A line without a label starts with a space**: press the space bar first, or the
assembler takes the instruction for a label. How many spaces there are does not matter.

1. In a session type `TEDI.` and name the text `PROG`.
2. Type `AL`, then these ten lines. `HELLO` is the label of the fourth; the others start with
   a space. The `O'17` of the sixth begins with the letter O, which marks an octal number;
   the lines with `S0` have the digit zero.

   ```
    IDENT HELLO
    ENTRY HELLO
    START HELLO
   HELLO S0 4
    S1 ='Hello from COS'Z
    S2 O'17
    EX
    S0 0
    EX
    END
   ```

3. Type a line that holds only a period. `T 1,30` shows the ten lines. If one lacks its
   space, say line 3, `RP 3` puts it there: answer `P:` with `START` and `R:` with a space
   and `START`.
4. Type `END` to save the text and leave the editor.
5. Type `CAL,I=PROG,L=0.` to assemble it. It says nothing if all is well, and how many
   errors it found otherwise.
6. Type `LDR,AB,DN=$BLD.` to link it, and `$ABD.` to run it. It prints `Hello from COS`.

To see where the errors are, assemble with `CAL,I=PROG,L=LST.` and look at `LST` in the
editor: `TEDI.`, then `O`, then `LST`, then `T 1,40`.

### In FORTRAN 77

FORTRAN runs as a job and prints on the printer (**F3**). Its lines have fixed columns: a
statement starts in column 7, after six spaces, and a statement number such as `10` stands
in the first five columns.

1. In a session type `TEDI.` If it opens the last text instead of asking for a name, type `O`.
   Name the text `SRC`.
2. Type `AL`, then these seven lines:

   ```
         PROGRAM SQ
         INTEGER I
         DO 10 I = 1, 5
           PRINT 100, I, I * I
      10 CONTINUE
     100 FORMAT(1X, I4, I6)
         END
   ```

3. Type a line that holds only a period, then `END`, then `SAVE,DN=SRC.` to keep the text.
4. Type `ACCESS,DN=FTN.`, then `SUBMIT,DN=FTN.` The job `FTN` compiles `SRC` and runs it.
   Both are needed every time the job is to run.
5. Press **F3** for the printout: the numbers 1 to 5 and their squares.

The first character of a printed line is not printed: it tells the printer how far to
advance, so start a `FORMAT` with `1X`. All the commands are listed in
[software/cos-tools](software/cos-tools/README.md).

## Screens

- **F1** the operator's console
- **F2** the station
- **F3** the printer

Keys go to the station (**F2**) while it is shown, and to the operator's console (**F1**) otherwise.

The top line of a console is the status line of its terminal, an Ampex Dialogue 80. **F4** to
**F11** are that terminal's own keys (clear, insert, delete, modes); COS needs none of them.
[What each does](docs/MACHINE.md#the-consoles).

## Menu options

- Load boot file, Expander disk, Disk drives and Printer file take the four files of
  [Starting COS](#starting-cos).
- Tape: a `.tap` file for the tape drive, in place of the boot tape until the next reset.
  `tape.tap` in `games/Cray-XMP` is a blank one. On the operator's console (**F1**)
  `FDUMP STATION/name @MT0:` copies a file of the kernel's disk to the tape and
  `FLOAD @MT0:` copies what is on the tape back.
- Reset starts the machine again: go on from the date. The four files stay chosen.
- Aspect ratio (with the custom ratios of `MiSTer.ini`), Scale and Scandoubler Fx work as in
  other cores. The scandoubler is for the 8x8 font.
- Text color: white, green, amber or cyan
- Font: 8x8 (15 kHz lines), the one the core starts with, or 8x16 (31 kHz lines), which is
  sharper: choose it on HDMI or a VGA monitor.
- Device times: Fast, or Real: the disk drives, the tape, the printer, the consoles and the
  channel to the CPU take as long as the real ones did

## Troubleshooting

- `Load a boot file from the menu to start it.`: the four files of [Starting COS](#starting-cos)
  have to be chosen each time the core is started.
- `INVALID COMMAND`: the command was typed in small letters. Press Caps Lock.
- Typing shows on the screen but the computer does not answer, and the top line says `BLK`: the
  terminal is in block mode. Press **F10**.
- The top line says `PRT` or `WPT`, or new text is dim: press **F11**, then **Ctrl+F11**.
- `ENTER DATE` comes back: the year must be 80 to 99.
- `DISK NOT INITIALIZED` and `START ABORTED`: the Expander disk file is not chosen. Choose it,
  and the Disk drives file, and type the `START` line again.
- `CC001 - CONTROL STATEMENT TERMINATOR MISSING`: the period at the end of the statement is missing.
- `INSTRUCTION PLACEMENT ERROR` from the assembler: a line without a label does not start
  with a space.
- `TE019 - READ ONLY DATASET` in the editor: the text was saved. See
  [Writing a program](#writing-a-program) for how to change it.
- `PD009 - DATASET NOT FOUND` for a dataset you saved in a job: put `US=SYSTEM` into the job's
  `ACCOUNT` statement, as above.
- `CRAY HALT` during start-up after the disk images were replaced: start **Cray-XMP** from the
  Computer menu again instead of using Reset.
- `Concentrator ordinal 3  VAX interface select error. Command aborted.` a while after `START`:
  COS looks for a front-end computer, which this machine does not have. It runs without one.

How the machine is built, where it differs from a real one and how to work on the core are in [docs](docs).

## Credits

Thanks to the people whose work this core rests on:

- [Chris Fenton](https://www.chrisfenton.com/homebrew-cray-1a/) for the CRAY-1 in an FPGA that the CPU started from,
  and for [reading COS 1.17 off its disk pack](https://www.chrisfenton.com/cos-recovery/).
- [andrastantos](https://github.com/andrastantos) for bringing that disk back to life in [cray-sim](https://github.com/andrastantos/cray-sim),
  which the core was checked against, and for telling how in [The Cray Files](https://www.modularcircuits.com/blog/articles/the-cray-files/).
- [kej715](https://github.com/kej715) for [COS-Tools](https://github.com/kej715/COS-Tools) and the [compiler kit for COS](https://github.com/kej715/ack):
  the assembler, the loader, the FORTRAN compiler and the other commands and libraries on the disk.
- [davidgiven](https://github.com/davidgiven) and the Vrije Universiteit for the [Amsterdam Compiler Kit](https://github.com/davidgiven/ack), which those are compiled with.
- Mats Nordström and his colleagues at Uppsala for LISP F4, and [blakemcbride](https://github.com/blakemcbride) for [keeping it](https://github.com/blakemcbride/LISPF4).
- [Zorislav-Shoyat](https://github.com/Zorislav-Shoyat) for [Cray-on-FPGA](https://github.com/Zorislav-Shoyat/Cray-on-FPGA) and the
  [CAL translator](https://github.com/Zorislav-Shoyat/CAL-Cray-Assembly-Language-Translator), a second opinion on the CPU and on the assembler.
- Robert Hyatt, Albert Gower and Harry Nelson for Cray Blitz, and [swenson](https://github.com/swenson) for
  [keeping its sources](https://github.com/swenson/cray-blitz): real Cray code to test with.
- [fvaneijk](https://github.com/fvaneijk) for the [VT52 core](https://github.com/MiSTer-devel/VT52_MiSTer), where the fonts and the video timing come from,
  and Dimitar Zhekov for the [Terminus Font](https://terminus-font.sourceforge.net/).
- [sorgelig](https://github.com/sorgelig) and the [MiSTer project](https://github.com/MiSTer-devel) for the framework.
- [Bitsavers](http://www.bitsavers.org/pdf/cray/) and [cray-history.net](https://cray-history.net/) for the Cray manuals.
- The [Verilator](https://www.veripool.org/verilator/) and [Verible](https://github.com/chipsalliance/verible) projects for the simulator and the formatter.
