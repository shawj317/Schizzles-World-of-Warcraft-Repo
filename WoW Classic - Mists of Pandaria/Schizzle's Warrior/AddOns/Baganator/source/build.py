#!/usr/bin/env python3
"""Schizzle's Warrior Baganator profile (Jon Shaw / Schizzle), MIT with attribution.

Builds ../Warrior Profile.txt, a Baganator "BGR!1!" profile import, from
profile.json. Baganator's export button makes that string as
  "BGR!1!" .. EncodeBase64(CompressString(SerializeCBOR(profile)))
which is CBOR (strings as byte strings), raw deflate at zlib's default level,
then standard base64. This script does the same with only the standard library,
so a rebuild gives back the exact string Baganator exported.

profile.json keeps the keys in the order Baganator wrote them; that order is
what makes the rebuild byte-for-byte identical.

Usage:
  python3 build.py            write ../Warrior Profile.txt
  python3 build.py --check    fail if the file is not what profile.json builds
  python3 build.py --decode   print the file decoded as JSON (Baganator's import steps)
"""
import base64, json, os, struct, sys, zlib
from collections import OrderedDict

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "profile.json")
OUT = os.path.join(HERE, "..", "Warrior Profile.txt")
PREFIX = "BGR!1!"


def head(major, n):
    if n < 24:
        return bytes([major << 5 | n])
    for ai, size in ((24, 1), (25, 2), (26, 4), (27, 8)):
        if n < 1 << (8 * size):
            return bytes([major << 5 | ai]) + n.to_bytes(size, "big")
    raise ValueError(n)


def cbor(v):
    if v is True:
        return b"\xf5"
    if v is False:
        return b"\xf4"
    if isinstance(v, int):
        return head(0, v) if v >= 0 else head(1, -1 - v)
    if isinstance(v, float):
        return b"\xfb" + struct.pack(">d", v)
    if isinstance(v, str):
        b = v.encode("utf-8")
        return head(2, len(b)) + b  # WoW writes Lua strings as CBOR byte strings
    if isinstance(v, list):
        return head(4, len(v)) + b"".join(cbor(x) for x in v)
    if isinstance(v, dict):
        return head(5, len(v)) + b"".join(cbor(k) + cbor(x) for k, x in v.items())
    raise TypeError(type(v))


def uncbor(d, i=0):
    b = d[i]; major, ai = b >> 5, b & 31; i += 1
    if major == 7:
        if ai == 20: return False, i
        if ai == 21: return True, i
        if ai == 27: return struct.unpack(">d", d[i:i + 8])[0], i + 8
        raise ValueError("unsupported simple/float %d" % ai)
    if ai < 24:
        n = ai
    else:
        size = {24: 1, 25: 2, 26: 4, 27: 8}[ai]
        n = int.from_bytes(d[i:i + size], "big"); i += size
    if major == 0: return n, i
    if major == 1: return -1 - n, i
    if major in (2, 3): return d[i:i + n].decode("utf-8"), i + n
    if major == 4:
        out = []
        for _ in range(n):
            x, i = uncbor(d, i); out.append(x)
        return out, i
    if major == 5:
        out = OrderedDict()
        for _ in range(n):
            k, i = uncbor(d, i); x, i = uncbor(d, i); out[str(k)] = x
        return out, i
    raise ValueError("unsupported major type %d" % major)


def encode(profile):
    c = zlib.compressobj(6, zlib.DEFLATED, -15)  # CompressString's default: raw deflate, level 6
    return PREFIX + base64.b64encode(c.compress(cbor(profile)) + c.flush()).decode("ascii")


def decode(text):
    if not text.startswith(PREFIX):
        raise ValueError("no BGR!1! prefix")
    data = zlib.decompress(base64.b64decode(text[len(PREFIX):], validate=True), -15)
    value, end = uncbor(data)
    if end != len(data):
        raise ValueError("trailing bytes after the CBOR value")
    return value


def main():
    with open(SRC, encoding="utf-8") as f:
        profile = json.load(f, object_pairs_hook=OrderedDict)
    built = encode(profile)
    arg = sys.argv[1] if len(sys.argv) > 1 else ""
    if arg == "--check":
        cur = open(OUT, encoding="ascii").read()
        if cur != built:
            print("Warrior Profile.txt is out of date; run python3 build.py"); sys.exit(1)
        if decode(cur) != profile:
            print("Warrior Profile.txt does not decode back to profile.json"); sys.exit(1)
        print("Warrior Profile.txt is current (%d chars)" % len(cur))
    elif arg == "--decode":
        print(json.dumps(decode(open(OUT, encoding="ascii").read()), separators=(",", ":")))
    else:
        with open(OUT, "w", encoding="ascii", newline="") as f:
            f.write(built)
        print("wrote Warrior Profile.txt (%d chars)" % len(built))


if __name__ == "__main__":
    main()
