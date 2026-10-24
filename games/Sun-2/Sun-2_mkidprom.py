#!/usr/bin/env python3
#
# Sun-2_mkidprom.py -- write a boot1.rom: the Sun-2's ID PROM, which gives the
# machine its Ethernet address, serial number and hostid.
#
# The core reads games/Sun-2/boot1.rom at start-up when it exists.  Without
# one, a Main_MiSTer with Sun support makes an ID PROM from this MiSTer's own
# Ethernet address each time the core loads, so the Sun's identity follows the
# MiSTer: another MiSTer, or another network adapter, and the Sun's Ethernet
# address and hostid change.  Writing a boot1.rom pins it.
#
# Run on the MiSTer (or anywhere with Python 3):
#
#   python3 Sun-2_mkidprom.py                  this MiSTer's identity, exactly as
#                                              Main makes it today
#   python3 Sun-2_mkidprom.py --mac 08:00:20:12:34:56
#   python3 Sun-2_mkidprom.py --mac 08:00:20:12:34:56 --serial 1234567
#   python3 Sun-2_mkidprom.py --show           decode an existing boot1.rom
#
# It writes /media/fat/games/Sun-2/boot1.rom (-o to choose), and will not
# replace one that is there without --force.  Load the core again for it to
# take effect.
#
# The 32 bytes (Sun-2 Architecture Manual, 4.2):
#
#   0       format, 1
#   1       machine type: 2, a VME Sun-2 (the 2/50 board in this 2/160)
#   2-7     Ethernet address; Sun's own begin 08:00:20
#   8-11    manufacturing date, seconds since 1970
#   12-14   serial number; SunOS's hostid is the machine type and this
#   15      checksum: bytes 0..15 XOR to zero
#   16-31   0xFF
#
# Main makes the address 08:00:20 followed by the last three bytes of the
# MiSTer's eth0 (wlan0 if there is no eth0), uses the same three bytes as the
# serial number, and a fixed date, 18 April 1984.

import argparse
import datetime
import os
import sys

DEFAULT_OUT = "/media/fat/games/Sun-2/boot1.rom"
MAIN_DATE = 0x1AE4233B          # what Main_MiSTer writes: 1984-04-18
SUN_OUI = bytes([0x08, 0x00, 0x20])
MACHINE_SUN2_VME = 0x02


def host_mac():
    """This machine's Ethernet address, eth0 first, as Main reads it."""
    for iface in ("eth0", "wlan0"):
        try:
            with open("/sys/class/net/%s/address" % iface) as f:
                return parse_mac(f.read().strip())
        except (OSError, ValueError):
            pass
    return None


def parse_mac(text):
    parts = text.replace("-", ":").split(":")
    if len(parts) != 6:
        raise ValueError("an Ethernet address is six bytes, like 08:00:20:12:34:56")
    return bytes(int(p, 16) for p in parts)


def make(mac, serial, date, machine=MACHINE_SUN2_VME):
    p = bytearray([0xFF] * 32)
    p[0] = 0x01
    p[1] = machine
    p[2:8] = mac
    p[8:12] = date.to_bytes(4, "big")
    p[12:15] = serial.to_bytes(3, "big")
    c = 0
    for b in p[:15]:
        c ^= b
    p[15] = c
    return bytes(p)


def describe(p):
    ok_sum = 0
    for b in p[:16]:
        ok_sum ^= b
    mac = ":".join("%x" % b for b in p[2:8])
    date = int.from_bytes(p[8:12], "big")
    serial = int.from_bytes(p[12:15], "big")
    when = datetime.datetime.fromtimestamp(date, datetime.timezone.utc).strftime("%Y-%m-%d")
    lines = [
        "format         %d" % p[0],
        "machine type   %d%s" % (p[1], " (Sun-2 VME)" if p[1] == 2 else ""),
        "Ethernet       %s%s" % (mac, "" if p[2:5] == SUN_OUI else "  (not Sun's 08:00:20)"),
        "date           %s" % when,
        "serial         %d" % serial,
        "hostid         %02x%06x" % (p[1], serial),
        "checksum       %s" % ("good" if ok_sum == 0 else "BAD -- the boot PROM will say ID PROM INVALID"),
    ]
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser(description="Write a Sun-2 ID PROM (boot1.rom).")
    ap.add_argument("--mac", help="Ethernet address; default 08:00:20 and the last three "
                                  "bytes of this machine's eth0, as Main makes it")
    ap.add_argument("--serial", type=int,
                    help="serial number, 0..16777215; default the last three bytes "
                         "of the Ethernet address")
    ap.add_argument("--date", help="manufacturing date, YYYY-MM-DD; default 1984-04-18, as Main")
    ap.add_argument("-o", "--out", default=DEFAULT_OUT, help="default " + DEFAULT_OUT)
    ap.add_argument("--force", action="store_true", help="replace an existing file")
    ap.add_argument("--show", nargs="?", const=DEFAULT_OUT, metavar="FILE",
                    help="decode a boot1.rom instead of writing one")
    a = ap.parse_args()

    if a.show:
        with open(a.show, "rb") as f:
            p = f.read()
        if len(p) < 16:
            sys.exit("%s: %d bytes, too short for an ID PROM" % (a.show, len(p)))
        print(describe(p))
        return

    if a.mac:
        try:
            mac = parse_mac(a.mac)
        except ValueError as e:
            sys.exit("--mac: %s" % e)
        if mac[:3] != SUN_OUI:
            print("note: %s is not one of Sun's addresses (08:00:20:...)" % a.mac)
    else:
        hw = host_mac()
        if hw is None:
            sys.exit("no eth0 or wlan0 here to take an address from: give --mac")
        mac = SUN_OUI + hw[3:]

    serial = a.serial if a.serial is not None else int.from_bytes(mac[3:], "big")
    if not 0 <= serial <= 0xFFFFFF:
        sys.exit("--serial: 0 to 16777215")

    if a.date:
        try:
            d = datetime.datetime.strptime(a.date, "%Y-%m-%d").replace(tzinfo=datetime.timezone.utc)
        except ValueError:
            sys.exit("--date: YYYY-MM-DD")
        date = int(d.timestamp())
    else:
        date = MAIN_DATE

    if os.path.exists(a.out) and not a.force:
        sys.exit("%s exists; --force to replace it (--show to see what it holds)" % a.out)

    p = make(mac, serial, date)
    with open(a.out, "wb") as f:
        f.write(p)
    print("wrote %s:" % a.out)
    print(describe(p))


if __name__ == "__main__":
    main()
