# UNIX PC (3B1 / PC7300) for MiSTer

Normal people hit a certain age and buy the vintage sports car they had on their bedroom wall as a kid. I just dreamt of the computer equivalent: a high-end workstation straight out of a magazine ad. At roughly $17,000 in today’s money, it was out of reach for most people. Still, having a UNIX machine of your own seemed like magic.

In 1985, AT&T introduced the UNIX PC, an office workstation with a 68010 CPU, a mouse, and an integrated modem. It ran System V UNIX, years before Linux or OpenBSD existed. For a home user, that kind of access to UNIX was extraordinary.

In the spirit of the “we have UNIX at home” meme, this project recreates the machine in FPGA logic for the MiSTer. Real UNIX PCs are hard to find - they never sold in large numbers, and there’s no software emulator hiding under the hood.

Four decades later, UNIX is booting again, blissfully unaware it's been transported through time and squeezed into a tiny piece of silicon. If you can't buy the UNIX workstation of your childhood dreams, you might as well make one.

<a href="https://www.youtube.com/watch?v=H2lQfCW9Y_Y"><img src="img/video.jpg" alt="Video: the core running on a MiSTer" width="480"></a>

*Click the picture to watch the demo video (YouTube).*

## What it does

- The **68010** core, mostly cycle exact with the original memory management unit and page map around it
- **512 KB to 4 MB of RAM**, with the parity checking
- **Hard disk (WD1010) and floppy (WD2797)** controllers, with the DMA path modelled chip by chip, working from images on the SD card
- **Video** is the machine's 720 × 348 monochrome picture, drawn as a CRT in 1280 × 720, with phosphor, glow, glass, curvature, a rolling band, noise and a monitor frame around it
- **Keyboard** with the keys a PC keyboard doesn't have, and a mouse
- A **real time clock**, set from your MiSTer's date
- A **virtual line printer**, with a sheet of fan-fold paper to look at
- **Front panel LEDs**
- **Ethernet** through the expansion card (a LANCE), bridged to your LAN
- A working **telephone**: hook, dialer, ringer and modem, with the tones coming out of the HDMI audio and calls turn into telnet connections
- A **serial port**, with a console you can log in through or an external connection to the board
- The **boot diagnostics** and the diagnostic floppy run, so you can use the original hardware tests

## Getting started

You need a DE10 Nano board with the **SDRAM add-on** (the main RAM lives there, because the FPGA's own memory is under 1 MB and the machine can have 4), the latest Main_MiSTer (the Ethernet support needs it), a boot ROM and a disk image. The ROM and the disk images are still under copyright, so this project distributes neither. Here's where to get them.

### 1. Install the core

Copy the latest `.rbf` from the [releases](https://github.com/hrvach/3b1_project/tree/release/releases) to your MiSTer's SD card like any other core. The boot ROMs it needs should be provided in their own folder, as described below.

### 2. Get the boot ROM

The ROM of the machine consisted of two 8 KB EPROMs on the logic board, and the core wants the two files just as they come.

Why two? The 68010 reads 16 bits at a time and each EPROM is only 8 bits wide, so one chip supplies the high byte of every word (15C) and the other one the low byte (14C).

- Download the 3B1 ROMs from Bitsavers: [3b1_roms.zip](http://bitsavers.org/pdf/att/3b1/firmware/3b1_roms.zip)
- Unzip it and copy the two files to the SD card, with these names and in this folder:

| Original file | Path | Save it as | MD5 |
|---|---|---|---|
| `15C 72-00617.bin` | `3b1/` | `boot0.rom` | `79cc4930b2a60046a9316107265a98ef` |
| `14C 72-00616.bin` | `3b1/` | `boot1.rom` | `443fab727d1e0f6e81829672fa87f6e4` |

They're loaded every time the core starts. Both halves have to be there: without them the the machine stays in reset and the screen says **NO BOOT ROM FOUND**.

<p align="center"><img src="img/3b1.png" alt="The UNIX PC, booting UNIX" width="420"></p>

*UNIX PC booting.*

### 3. Get a disk

- **The easy way** is a finished disk image with UNIX System V 3.51 installed. 
    - David Gesswein [made one for the VCF Museum](http://www.pdp8online.com/3b1/3b1-hd.zip) - Disk geometry selection in OSD: 17 sect (136, default)
    - Arnold Robbins [made one loaded with software](https://www.skeeve.com/3b1/all-sw+fixdisk-hd.img.gz) - IMPORTANT: select 17 sect (272) from the disk geometry in OSD. 
- **The long way** is installing UNIX yourself from the Foundation Set floppies on [Bitsavers](http://bitsavers.org/bits/ATT/unixPC/system_software_3.51/), following the [Software Installation Guide](http://bitsavers.org/pdf/att/3b1/999-801-025IS_ATT_UNIX_PC_System_Software_Installation_Guide_1987.pdf).

Put the image in `3b1/` folder on the SD card just like the boot ROMs, and name it **boot0.vhd**.

The `.vhd` ending is only a name here, the file is a raw sector dump. 

### 4. Start it

1. Load the core, it should automatically boot - just wait. If it doesn't, press **F12** for the OSD (the MiSTer's on-screen menu) and pick the image with **Mount hard disk**.

Select floppy, if needed, from the OSD or name it `boot1.vhd` and it's there when the core starts.

![The login prompt on the core](img/login.gif)

*The login prompt after boot, with the blinking cursor.*

## Using it

A PC keyboard doesn't have the same keys UNIX PC had, so some of them need to either be mapped to an existing key, or get a shortcut of their own. 

Obviously, these were assigned without any careful planning and yoloed into the core. If you'd rather have them somewhere else, it's a single table in `rtl/keyboard/kbd_scancode_rom.sv`.

| You press | The 3B1 gets | | You press | The 3B1 gets |
|---|---|---|---|---|
| Alt+Esc | Exit | | Alt+F9 | Ops |
| Alt+Return | Enter | | Alt+F10 | Copy |
| Alt+Backspace | Cancel | | Alt+F11 | Undo |
| Alt+F3 | Clear Line | | Alt+1 | Replace |
| Alt+F4 | Rstrt / Ref | | Alt+2 | Delete Char |
| Alt+F5 | Message | | Alt+3 | Select / Mark |
| Alt+F6 | Create | | Alt+4 | Input Mode |
| Alt+F7 | Save | | Alt+5 | Redo |
| Alt+F8 | Move | | Alt+6 | Find |

Two combinations are the core's own: 
  - **Alt+F1** shows the machine's screen again
  - **Alt+F2** shows the sheet of printer paper. 
  
  **F12** opens the MiSTer's OSD.

## How it fits together

![Block diagram](img/3b1_architecture.svg)

*The logic board, as implemented by this core.*

The Unix PC isn’t just moving bytes around: its MMU gives programs virtual memory, complete with page faults and swapping, while the disk controllers move data straight to and from RAM using DMA. Getting the CPU, memory, and disk to share the bus without tripping over one another is where the logic board gets interesting.

The MMU translates each logical address in the lower 4 MB from the CPU into a physical RAM address. Addresses above that (the boot ROM, the board's registers and the chips) go straight to the bus with no translation. The ROM, video RAM, disk controllers, serial chip, keyboard and Ethernet card all connect to that shared bus. While the CPU continues working, the disk controllers can transfer sectors to RAM using **DMA**; a bus arbiter coordinates access among them.

The SDRAM add-on board provides the machine's RAM. The MiSTer's ARM side handles disk images stored on the SD card and provides the keyboard, UART and Ethernet interfaces; the other components are implemented in the FPGA.

### What lives where

The table below maps the computer's address space. The CPU can address 16 MB; addresses are shown in hexadecimal.

| Address | What is there |
|---|---|
| `000000-3FFFFF` | RAM, through the MMU (4 MB of logical addresses) |
| `400000-4FFFFF` | the board's registers, picked by the top byte of the address |
| &nbsp;&nbsp;&nbsp;&nbsp;`400000` | page map RAM, one entry per logical page |
| &nbsp;&nbsp;&nbsp;&nbsp;`410000` | general status (GSR) |
| &nbsp;&nbsp;&nbsp;&nbsp;`420000` | video RAM, 32 KB |
| &nbsp;&nbsp;&nbsp;&nbsp;`430000` | bus status 0 (BSR0): the access that caused the last bus error: page fault flag, which DMA master (if any), which byte lanes, and address bits 23-16 |
| &nbsp;&nbsp;&nbsp;&nbsp;`440000` | bus status 1 (BSR1): address bits 15-0 of that access. With BSR0 it gives the full address that faulted |
| &nbsp;&nbsp;&nbsp;&nbsp;`450000` | telephone status: off hook, ring on line 1 and 2, message waiting |
| &nbsp;&nbsp;&nbsp;&nbsp;`460000` | disk DMA count and enable |
| &nbsp;&nbsp;&nbsp;&nbsp;`470000` | printer and disk status: busy, select, no paper, error, memory parity error |
| &nbsp;&nbsp;&nbsp;&nbsp;`480000` | real time clock: chip enable, address latch, read/write and the nibble |
| &nbsp;&nbsp;&nbsp;&nbsp;`490000-497000` | telephone line latches: handset relay, line select, hook relays, hold |
| &nbsp;&nbsp;&nbsp;&nbsp;`4A0000` | miscellaneous control (MCR): 60 Hz interrupt clear, printer strobe, the four front panel LEDs |
| &nbsp;&nbsp;&nbsp;&nbsp;`4B0000-4B03FF` | modem baud rate latch |
| &nbsp;&nbsp;&nbsp;&nbsp;`4B0400`, `4B0800` | dialer load: low byte, then high byte |
| &nbsp;&nbsp;&nbsp;&nbsp;`4C0000` | clear status (CSR): clears the error flags |
| &nbsp;&nbsp;&nbsp;&nbsp;`4D0000-4D7FFF` | disk DMA address |
| &nbsp;&nbsp;&nbsp;&nbsp;`4E0000` | disk control: drive select, motor, head, controller resets |
| &nbsp;&nbsp;&nbsp;&nbsp;`4F0000` | printer data |
| `800000-BFFFFF` | boot ROM |
| `C00000-DFFFFF` | expansion slots, 256 KB each. The Ethernet card is in slot 0 at `C00000`, with its ID PROM at the end of the block |
| `E00000-FFFFFF` | the chips: disk controllers, control latch, serial chip, modem, clock, keyboard |
| &nbsp;&nbsp;&nbsp;&nbsp;`E00000` | hard disk controller (WD1010) |
| &nbsp;&nbsp;&nbsp;&nbsp;`E10000` | floppy controller (WD2797) |
| &nbsp;&nbsp;&nbsp;&nbsp;`E20000` | control register 2 (MCR2) |
| &nbsp;&nbsp;&nbsp;&nbsp;`E30000` | real time clock read |
| &nbsp;&nbsp;&nbsp;&nbsp;`E40000-E46000` | general control (GCR), a latch of single bits: one bit per 4 KB step, the value is bit 15 of the data (error enable, parity enable, bad parity, ROM low map, modem connect) |
| &nbsp;&nbsp;&nbsp;&nbsp;`E50000` | serial controller (uPD7201), channel A is the serial port and B the modem |
| &nbsp;&nbsp;&nbsp;&nbsp;`E60000` | modem chip and its transceiver control |
| &nbsp;&nbsp;&nbsp;&nbsp;`E70000`, `E70002` | keyboard (6850 ACIA), mirrored at `EF`, `F7` and `FF` |

![The logic board of the UNIX PC](img/mainboard.png)

*The logic board illustration, showing the locations of the important components*

### Paging

Memory is divided into 4 KB pages, and the MMU has an entry for each of the 1024 logical pages. The entry says which physical page it lives in and carries a few status bits. The CPU changes the mapping by writing to the page map like it was ordinary memory. This is how UNIX gives each process a private address space, and how it can run programs bigger than the RAM.

When a program touches a page that isn't there, the MMU raises a bus error, the kernel reads the page from disk, marks it present and the instruction runs again. The MMU also sets the accessed and modified bits by itself, and that's what the kernel looks at when it has to decide what to throw out. DMA goes through the same page map, so a disk transfer into a missing page is a fault like any other.

![Animated: a logical address is translated through the page map to a physical address](img/virtual_memory.svg)

*How an address is translated. The page number goes through the page map, and the offset passes straight through.*

If you want the reference material, with the PAL equations and register layouts, the AT&T documents are on [Bitsavers](http://www.bitsavers.org/pdf/att/3b1/).

## Network

![Ethernet card](img/ethernet1.png)

*3B1 Ethernet Card*

The Ethernet card is an AMD LANCE chip in the expansion slot, and the stock WIN/3B LAN 1.4 software drives it as if four decades hadn't passed. The FPGA stops at the edge of the frames, then a small module in Main_MiSTer carries them between a mailbox in memory and your LAN.

The UNIX PC doesn't start its network by itself. Nothing in the stock `/etc/rc` loads the driver. Log in as root, open `/etc/rc` (with `vi`, or `ed` if you're feeling historical) and add this at the end. The addresses are examples, use ones from your own network:

```sh
# /dev/net is the file the network programs use to reach the driver
/etc/mknod /dev/net c 10 0
chmod 666 /dev/net

# load the Ethernet driver (lddrv loads drivers that aren't built into the kernel):
# -dv unloads an old copy if there is one, -av loads it. lddrv looks for ether.o
# and unix.sym in the current directory, so it has to run from /etc/lddrv
cd /etc/lddrv
./lddrv -dv ether
./lddrv -av ether

# turn the card into the network interface en0 and give it an address
/usr/bin/ifconfig en0 192.168.10.77 arp -trailers

# send everything that isn't on your network to the router
/usr/bin/route add default 192.168.10.1 1

# the servers, so you can log in and copy files from your PC
/usr/ethernet/daemons/telnetd
/usr/ethernet/daemons/ftpd
```

The servers speak 1980s protocols with no encryption, so it goes without saying - **keep this machine inside your own network and never forward its ports to the Internet.**

Reboot, and from your PC (you may have to install a telnet client first, most systems don't ship one any more):

```sh
telnet 192.168.10.77
```

You'll see the FPGA answer with `login:` from the 1980s. Some things to save you time:

- There's no `ping`. Yes, really. The package has `ifconfig`, `netstat`, `route`, `hostname`, `telnet` and `ftp`. Use `telnet` to test things, and `netstat -i` to watch packets arrive.
- This `ifconfig` doesn't take `netmask`. It assumes a class C network, which is what you have anyway.
- There's no DNS resolver. Names live in `/etc/hosts`, by hand.
- The OSD option **Ethernet** decides how the core shows up on your LAN. Through the MiSTer's own `eth0` is the default, or as a **macvlan** child with its own MAC address, which your router sees as a separate host. Use macvlan if the 3B1 and the MiSTer need to talk to each other.

## Phone and modem

LAN is great, but if you wanted to reach a far-away computer, this was what you used. The UNIX PC was sold as a telephone as much as a computer. The logic board has a hook relay, a dialer chip that makes the touch-tones (DTMF), a ringer and a 1200 baud modem. There's no Hayes AT command set anywhere in it. The kernel does the dialling through a custom driver and listens for the answer tone.

The core can't plug into a phone line (and it's hard to even find one nowadays), so it does something more useful. It watches the kernel dial, turns the number into an IP address / port and then lets the 3B1 talk to anything on the Internet that speaks telnet. All sounds come from the core and the slow speed should be authentic.

There are a few names for serial and phone things below, and they're different devices:

| Where | Name | What it is |
|---|---|---|
| In the 3B1 | `tty000` | the serial port (channel A of the serial chip) |
| In the 3B1 | `ph0` | phone line 1, with the modem (channel B of the serial chip) and the dialer |
| In the 3B1 | `ph1` | phone line 2. The machine has two line jacks and one modem, and the core only wires up line 1, so use `ph0` |
| On the MiSTer | `ttyS1` | the MiSTer's own UART, which the core's serial port or modem is connected to (OSD **Serial port**) |

### How to set up the modem

Log in as root and do this (only needed once, if not already set up):

1. Create the device node of the line: `/etc/mknod /dev/ph0 c 8 0`
2. Tell the dialling program about it: `echo "OBM ph0 UNIXPC 1200" >> /usr/lib/uucp/L-devices`
3. Switch the line to tone dialling: `/etc/phupd ph0 DATA YES NO NO`, and put the same line at the end of `/etc/rc`. Left at its defaults, the kernel pulse-dials by clicking the hook relay, and the core never sees the digits. An old-school phone line wouldn't mind, but we do.
4. If `/etc/inittab` has a `ph0` line, comment it out and run `telinit q`, or `getty` will fight `cu` for the line.
5. If a call was ever interrupted, delete the stale lock file `/usr/spool/uucp/LCK..ph0`.

### Dialling an IP address

You get the dial tone, the DTMF sequence, the ringing, a pause while the MiSTer connects, the handshake tone and then `Connected`. You're on a TCP connection to the other end, through a 1985 modem driver. `~.` hangs up. Is that keyboard sequence familiar to you maybe? :-)

To connect, type

```sh
cu -l ph0 -s 1200 '192168010254*23'
```

That's `192.168.010.254` port 23. Quote it, or the shell takes the star for a wildcard. 

### Serial console

The serial port can also be a login on your MiSTer. Set the OSD **Serial port** to **Console**, and from the 3B1 run `cu -l tty000 -s 9600 dir` (`dir` means a direct line, no phone number).

### Troubleshooting

- **The first call works and the second one doesn't.** The stock MiSTer `/etc/inittab` starts a `getty` on `ttyS1`, the port MidiLink uses, and after a call it resets the port to 9600 baud. Comment out the `ttyS1` line (it starts with `console::respawn:/sbin/agetty`) and run `telinit q`.
- **The modem and the serial port don't work together.** They share the one MiSTer UART, so while the modem is in use the serial port can't use it.
- **No digits arrive.** The line is still pulse-dialling. Do step 3 above.

## Printer

The parallel port has a virtual line printer on it, always on line. Press **Alt+F2** and the screen turns into a sheet of fan-fold paper, with green bars, sprocket holes and black type, scrolling with every line feed. Send something to the printer and watch it come out.

```sh
cat /etc/passwd > /dev/rawlp
```

![The sheet of printer paper showing a file printed from the UNIX PC](img/printer_web.png)

*The paper view, with the last lines of a printout.*

**Alt+F1** takes you back, and **Tear off paper** in the OSD starts a clean sheet.

## The picture

The machine makes a 720 × 348 monochrome bitmap at 60 Hz. What you see is that bitmap drawn again as a CRT, at 1280 × 720, in the FPGA. There's phosphor persistence and glow, the dark glass of the tube, barrel curvature, rounded corners, a rolling band, line wobble and noise. You can turn all of it off in the OSD page **CRT effects**, and change the colour of the phosphor too: green by default (my favourite), white, amber or mint. The picture sits inside a drawing of the real monitor's bezel, with the LEDs of the side panel at the bottom right.

![The System Information window of the UNIX PC desktop on the core](img/gui.jpg)

*The desktop: the System Information window, with the Ethernet and Administration windows behind it.*

## How the CRT is made

The monitor isn't a filter slapped on top of the picture, it's a little pipeline of its own, and some of it is even fun.

![Block diagram of the video path](img/video_architecture.svg)

*The video path: two clocks from one PLL, and a small ring buffer between them instead of a frame buffer.*

### No frame buffer

If you want to resize or bend a picture, the textbook way is a frame buffer: write the whole frame into memory as it arrives, then read it back out in whatever order and at whatever speed the display wants. It works, but it needs resources. Our frame is 720 × 348, about 250 KB, and the 1280 × 720 output frame is closer to 900 KB. The FPGA on a DE10-Nano has around 700 KB of block RAM, so one output frame would eat almost all of it. Putting it in DDR3 instead makes you fight the ARM side for bandwidth, and you really want two buffers so nobody reads a half-written frame.

So, I improvised. Both clocks, the machine's 20 MHz and the video's 75 MHz, come out of the same PLL (600 MHz divided by 30 and by 8), which makes the ratio exact. A machine line is 896 clocks (44.8 µs), an output line is 1680 clocks (22.4 µs), so there are exactly two output lines for every machine line, and both frames take 16.67 ms. The output frame starts at a fixed distance behind the machine's and just stays there. It never drifts, so there's nothing to absorb.

And if you know when a line gets made and when it will be wanted, you only have to keep it for the time in between. That time is set by the barrel distortion (more on it below), because a bowed output row shows lines from above and below where it would be on a flat screen. If you want to modify a single line (e.g. to flip the image horizontally) you only need to keep the current line in memory, but if you want to modify in vertical direction, you need to remember several lines.

The module can bend the picture so that a row reaches up to 10 lines either side, and the memory is sized for that: the output runs about 35 rows behind the machine, a line is needed for about 40 lines, and then it can be overwritten. (The board uses k = 1/32, a bend of about 3 %, which needs less.) The whole memory is a ring buffer of 64 lines, 64 KB, instead of 900 KB: the machine writes line after line, and when it gets to the end it wraps around and overwrites the oldest. As a bonus there's no tearing, because the reader can't ever overtake the writer.

![The ring buffer: 64 slots of one picture line each, with the machine writing into one slot and the output reading a few lines behind it](img/ring_buffer.svg)

*The ring buffer: the machine writes lines in, the output reads a few lines behind, and a line lives in memory for only about three milliseconds.*

(The only memory that holds a whole picture is the one for persistence, 4 bits for each pixel. The fade of the phosphor needs to remember what every pixel did.)

### Barrel distortion

A CRT's glass is curved, so the picture bulges and straight lines bow outwards towards the edges. The trick is to work backwards. Don't ask where a bitmap pixel ends up, ask what each output pixel should show. Take the pixel's position $(x_{\text{new}}, y_{\text{new}})$ on the screen, measured from the middle, and scale it by something that grows with the distance from the middle. The result $(x_{\text{old}}, y_{\text{old}})$ is the spot in the original, undistorted bitmap to read:

$$x_{\text{old}} = x_{\text{new}} \cdot \left(a + b \cdot r_{\text{new}}^2\right)$$

$$y_{\text{old}} = y_{\text{new}} \cdot \left(a + b \cdot r_{\text{new}}^2\right)$$

where the squared distance from the middle is

$$r_{\text{new}}^2 = x_{\text{new}}^2 + y_{\text{new}}^2$$

with two constants that depend on the one knob $k$:

$$a = \frac{1}{1+k}, \qquad b = a \cdot k$$

In the middle the factor is $a$, and towards the corners it gets bigger, so the corner pixels reach further out into the bitmap, which is exactly the bow. I picked $a$ so that the middle of each edge of the screen lands precisely on the edge of the bitmap ($a + b = 1$ there). The picture is bent but never cropped. The one knob is $k$. The module can do seven strengths, from $1/64$ to $8/64$, each just a pair of constants, but the OSD only switches the effect on or off and the board fixes $k$ at $1/32$.

![Barrel distortion: a flat grid is bent so the middle of each edge stays put and the corners are pulled in; every screen pixel reads the bitmap at its own distance from the middle times a factor that grows with that distance; the factor is worked out with squares, a sum and a multiply](img/barrel_distortion.svg)

*The bend animates from none to a much stronger one than the core uses (k = 0.4 against 1/32), and the two arrows show a bitmap pixel (A, B) being copied to the screen pixel that needs it (A′, B′): A lies further out in the bitmap than A′ because A′ is near a corner, B lies nearer the centre than B′. Below: how big the factor is and what the FPGA does for every pixel.*

The nice part is that it needs no square root and no division. Everything is fixed point, with 1.0 being 65536. Even dividing by the half width of the screen is a multiplication by a constant, and a constant like 130 is just two shifts and an add ($128 + 2$). What's left is five real multiplications: the two squares, $b \cdot r^2$, and the factor times each coordinate. It's a pipeline 12 stages deep, running at 75 MHz, and each stage does one small thing, so nothing has far to travel. About 21 clocks of latency, which nobody will ever notice.

The same numbers tell us where the picture ends. How far inside the bowed edge a pixel is falls out of the same calculation, so the picture fades out towards that edge and goes black beyond it. That draws the curved outline and the rounded corners, and the monitor's frame shows through where the picture isn't. The bitmap is read from the ring buffer with horizontal interpolation, so the bowed lines don't turn into stairs.

### The rest of it

- **Two resolutions.** Brightness effects (persistence, glow, noise) work on the machine's own 720 × 348. Geometry (barrel, wobble, glass, frame) works on the 1280 × 720 output. Bending an already enlarged picture gives much smoother lines than bending the small one and enlarging it.

- **Line wobble.** Every third frame one line, picked at random, jumps sideways by a few sixteenths of a pixel. You'll hardly see it, but it makes the picture look drawn by a beam instead of printed.

- **Persistence.** Each pixel keeps a 4 bit level. A lit pixel starts at 15 and loses 2 every frame. The level is the logarithm of the light, so taking away a constant multiplies the brightness by a constant, which is an exponential fade (255, 198, 153, 118, 92, 71, 55, off). A pixel is gone after eight frames, about 133 ms, so a fast mouse pointer leaves a short tail and not a row of footprints.

- **Glow.** The light of a lit pixel spills into its neighbours, like on real phosphor. The picture is blurred with the weights 1-4-6-4-1 across five pixels and 1-2-1 across three lines, and added back on top of the sharp one. That vertical blur needs the lines above and below, which is why two line buffers delay the picture by one line.

- **Noise.** A 16 bit shift register with feedback (an LFSR) steps once per pixel clock and gives every pixel its own random number. Every pixel that carries light gets its brightness shifted by 6, 9 or 12 percent, new in every frame. The dark background stays quiet and big bright areas get a quarter of the noise, because grain looks right on thin text and wrong on a solid block. The whole picture also breathes by a percent or two about once a second.

### The glass and its rings

A smooth dark gradient requires finer brightness steps than an 8-bit HDMI signal can represent. To fake those extra levels, spatial dithering adds pseudo-random noise before rounding to 8 bits, so that neighboring pixels average out to the intended value. Using a single uniform random number (rectangular dither) makes the noise intensity modulate across the gradient: pixels landing exactly on an 8-bit step receive zero jitter, while those halfway between steps flip constantly. 

This creates alternating bands of clean and grainy areas that form visible rings. Adding two uniform random numbers gives triangular probability density function (TPDF) dither, which makes the noise variance independent of the signal level. The noise floor is then uniform across the whole gradient and the rings disappear.

## OSD options

| Option | What it does |
|---|---|
| Mount hard disk, Mount floppy, Eject floppy | the disk images. The layout comes from the disk's label |
| RAM | 512 KB, 1 MB, 2 MB (default) or 4 MB |
| CRT effects | screen colour, invert, phosphor, glow, glass, curvature, roll band, line wobble, noise, monitor frame, screen edges, round corners |
| Ethernet | eth0, off, or macvlan |
| Serial port | the MiSTer's UART (console or modem), the user port (the header on the MiSTer's I/O board), or both |
| Serial loopback plug | makes the serial port loop back on itself, which the diagnostics test needs |
| Modem flow control | on, off, or the opposite way round, for modems that wire it differently |
| Sound volume, Call sounds, Modem sound | what comes out of the HDMI audio |
| Tear off paper, Reset | clear the printout, reset the machine |

## Demos

Even toasters can run Linux, so why wouldn't this? Getting it to boot and support the MMU, interrupts, clock, and console was tricky. I picked an elegant weapon for a more civilized age, kernel 2.6.25, since its memory requirements actually fit the machine.

The effort was mostly met with my foul-mouthed references to a widespread assumption that every 68k is a 68020. The m68k port is full of instructions the 3B1 CPU has never heard of: bitfield operations, 32-bit multiply and divide (sigh), long branches the assembler quietly generates, even unaligned reads that a 68020 shrugs off and 68010 answers with an address error. Each one meant finding it, usually by watching the machine die in some unrelated place, and replacing it with something plainer. The system libgcc turned out to be 68020 code too.

The hardware had its own surprises. MMU was tricky to get right, format-8 bus error for the 68010 reading the fault registers properly (GSR, BSR0 and BSR1), unexpected level 2 interrupts, console that draws text into video ram, 6850 ACIA support for the keyboard (otherwise it's not much of a computer), disk via WD1010 etc. 

![Linux booting](img/linux.webp)

**Me**: Mom, I want this Amiga 500. 

**Mom**: We have an Amiga at home.

Amiga at home:

![Bouncy Ball](img/amiga_ball.webp)

*Amiga's Bouncy Ball Demo created for the Unix PC. Plain C, writing directly to video memory. No Fat Agnus here. :(*

## FAQ

**Q. It boots to a screen with only a stripe pattern**

A. That was my first bitstream, too. The boot ROM tests the page map memory by writing a counter and reading it back, and a block RAM that quietly dropped the upper byte made the test fail. If your build does this, look at the inferred RAMs in the map report.

**Q. The screen says NO BOOT ROM FOUND**

A. That's what the machine does without its boot ROM. Put the two ROM files in the core's folder as `boot0.rom` (15C) and `boot1.rom` (14C) and load the core again.

**Q. The kernel can't find the root file system**

A. The disk's label (the first sector, starting with `UQVQ`) is missing or damaged, so the core falls back to 1040 cylinders, 8 heads, 16 sectors and reads the wrong sectors. Try a different image, or restore the label.

**Q. Screen is not the right colour**

A. The original screen was actually mint. I just happen to like green better. Mint is in the OSD if you want it authentic, and so are white and amber.

**Q. Does it run on a plain DE10-Nano?**

A. You need the MiSTer SDRAM add-on, because the main RAM lives there.

## Known issues and missing features

- The printer shows its output but can't save it to a file
- Only one floppy drive and one hard disk

## Credits and license

The CPU core is a tweaked [fx68k](https://github.com/ijor/fx68k) by Jorge Cwik, a 68000 implementation that this project extends with 68010 features. The SDRAM controller and the MiSTer framework are made by Alexey Melnikov (Sorgelig) and the MiSTer team, and the modem's far end is MidiLink by Bbond007. Thanks to everyone who keeps the manuals, the documents and the software of this strange and wonderful machine alive.

The code of this project is licensed under the GPLv3. The parts that come from others (fx68k, and the MiSTer framework in `sys/`) keep their own licenses.

## AI Slop

AI helped in this project ¯\\\_(ツ)_/¯ . Due to serious lack of photos and other information, some photos had to be recreated. Sections of the code were AI written, formatted or debugged.

I nearly gave up on this project. A weird CPU bug I was unable to solve combined with a chronic lack of time resulted in a huge delay. AI came to the rescue and gave me the push I needed. Despite all its shortcomings, problems and controversies, I'm still very grateful for the help.

- Demo Video narration was generated using Elevenlabs model.
- Claude Sonnet 5.5 and Haiku 5.5 were used to help with the code.
- Muse was used to do research, summarize and process documentation into consumable markdown.
- Some images and videos were (re)processed with Gemini
- Luna 6 was used to cross-check and keep other models true.

## Disclaimer

This is a strictly non-profit hobby project. It is not made, endorsed or supported by AT&T, NCR, Unisys, The Open Group, OpenText or any other company, group or movement. UNIX, System V, AT&T and UNIX PC are trademarks of their respective owners and are used here only to say what the machine is.

The core comes with no warranty, as the GPL says. It is a model of hardware written from the manuals, and it can be wrong. I have (sadly) never seen or used this device personally. Use it at your own risk, and don't expect it to behave like the machine in every detail.

The boot ROMs, disk images and floppies of the UNIX PC are not part of this project. Their copyrights belong to their owners, and you need to obtain them through legal means.

If you made it this far, hope the writeup wasn't too boring. Have fun with computer archaeology and enjoy the time travel!
