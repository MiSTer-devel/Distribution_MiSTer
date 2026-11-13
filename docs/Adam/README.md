# [Coleco Adam](https://en.wikipedia.org/wiki/Coleco_Adam) for [MiSTer](https://mister-devel.github.io/MkDocs_MiSTer/)

This core is a conversion of the Colecovision core into verilog. Adam support was added by alanswx and spacexguy (asicguy).  


### Supported Filetypes
 * .col/.bin/.rom files for Coleco system
 * DSK - Coleco Adam disks in various formats
 * DDP - Coleco Adam Data Packs

### Expansion RAM

The OSD's **Expansion RAM** option fits a memory expander: **64K, 256K, 512K, 1M, 2M or None**.
64K is the plain Coleco Memory Expander, which has no bank register. The larger settings are the
third-party cards (Orphanware, Micro Innovations and the like), which take a bank number as data
written to port 42h; a bank is 64K, seen through the two 32K windows of port 7Fh.

Two things surprise people, and neither is a fault:

**Software often reports less than is fitted.** PowerPAINT's SYSTEM STATUS panel reads 64, 256
and 512 correctly but shows 512 for 1M and 2M as well. Its sizer counts to four banks past the
base and then stores a saturated value, so it cannot tell 512K from 2MB. That is the program's
limit, not the core's.

**RAMTEST reports 0 banks the second time you run it.** RAMTEST v2.0 (Eric Pearson) counts banks
by stamping a marker - the value 2680h at offset 0086h - into every bank it accepts. Finding that
marker already present is how it recognises a bank that wraps around to one it has already
counted, so it stops there. Resetting the core does not clear the expander's contents, so on a
second run it reads back its own marker in bank 0 and reports **0 Banks Detected**.

That is faithful: a warm reset does not clear DRAM on a real ADAM either. To run it again,
reload the core so the memory starts empty. A fresh run reports the real count - 32 banks at the
2M setting.

**Settings saved by an older core read as 64K.** The Expansion RAM option needed a third bit and
moved to different status bits, so a `.CFG` written before that selects 64K whatever it used to
say. Set it again in the OSD and re-save.

### Known Bugs

 * reset doesn't work quite the same as Adam
 * no printer support
 * key repeat doesn't match original

Fixed since this list was written: the bad character on the first keystroke; disk writes -
writing from SmartWRITER and saving a high score both work, including on disk images much larger
than the 160K standard; and Cosmo Fighter II's missing star field, which was the Z80's R
register reading back as a constant 0 because the refresh logic was compiled out. Tape (DDP)
writes are implemented but have not been confirmed on hardware yet.

AdamNet adapted from ColEm https://fms.komkon.org/ColEm/  
Original colecovision core https://github.com/wsoltys/mist-cores/tree/master/fpga_colecovision  
Original MiSTer core https://github.com/MiSTer-Devel/ColecoVision_MiSTer/  


### Information

http://adamarchive.org/archive/Manuals/  
https://console5.com/techwiki/images/b/b5/Coleco_ADAM_Technical_Reference_Manual.pdf  
https://console5.com/techwiki/images/2/28/Coleco_Adam_Schematics.pdf  
