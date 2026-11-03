# Schizzle's Warrior BigWigs Profile

A BigWigs profile for the non-ElvUI Warrior kit in MoP Classic 5.5.x by Jon Shaw (Schizzle): boss timer bars in Fira Sans Condensed Medium on the flat "Minimalist" texture, bronze bars that turn ember orange when they're about to happen, and every BigWigs element placed around the [WeakAuras rotation](../WeakAuras/) instead of on top of it. LittleWigs (dungeons) uses the same BigWigs settings, so this covers it too.

> **Heads-up:** this is a real BigWigs share string (`BW2:`), built and checked with BigWigs' own export and import code (see [Source files](#source-files-source)). BigWigs uses the same sharing code on every game version it supports, so it should import the same way on WoW Forever; that will be checked in game after Forever launches.

| File | Imports as | Built for |
|---|---|---|
| [Warrior Profile.txt](Warrior%20Profile.txt) | the current BigWigs profile (make a new one first, step 3) | BigWigs with the "BW2" sharing format |

## Install (step by step)
1. Install BigWigs (and LittleWigs if you want dungeon timers). Log in.
2. Type `/bw`. The BigWigs options open.
3. Click **Profiles**. Under **New**, type `Schizzle's Warrior` and press Enter. This keeps your old BigWigs profile; the import goes into the new one.
4. Click the **Import** tab (next to Profiles).
5. Paste the whole contents of `Warrior Profile.txt` (one line starting with `BW2:`) into **Import String**.
6. **Tick every box** that appears: Position, Settings and Colors under **Bars**, **Messages** and **Countdown**.
7. Click **Import**. BigWigs prints what it imported. It applies straight away; no reload needed.

**Font and texture:** Fira Sans Condensed Medium comes with WeakAuras and the Minimalist texture with BetterBlizzFrames or BetterBlizzPlates. Without them, BigWigs uses its own default font or texture; everything else still works.

## What's on screen
Positions are from the centre of the screen. The rotation aura keeps the middle clear (170 px either side, from 220 px below to 120 px above the centre), and the Details! windows sit in the bottom right.

| Element | Where | Look |
|---|---|---|
| Timer bars | left of the rotation aura (centre 420 px left, 20 px below centre), new bars stack upwards, at most 8 | 200 x 18, Fira 11 with outline, **bronze** on a charcoal background, icon on the left |
| Emphasized bars (the last 11 seconds) | the mirror image on the right (centre 380 px right), at most 5 | 240 x 22, Fira 13, **ember orange**; bars slide across from the left stack |
| Countdown (5, 4, 3...) | centre, 180 px above the middle, above the rotation aura | Fira 40, thick outline, ember orange |
| Messages | top centre (BigWigs' default spot, under the raid warnings); new lines push upwards, away from the aura | Fira 20 with outline, class coloured names, icons |
| Big messages | centre, 250 px above the middle | Fira 36, thick outline, upper case |

**Message colours:** BigWigs' meanings stay (red = danger, blue = information, green = good, and so on). Orange is the kit's ember and yellow is its gold.

To move anything: `/bw`, click **Show Moving Anchors**, drag, then click **Hide Moving Anchors**.

## What it doesn't change
- **Boss-specific settings** (which abilities warn, sounds, custom names). The general share string can't carry them.
- **Nameplate icons, Mythic+ and battle res and combat timer settings.** Left at BigWigs' defaults; they aren't in the string.
- **The countdown voice.** Left as it is.

## Source files (`source/`)
- `profile.lua`: the settings, as a plain Lua table, with the layout notes.
- `encoding.lua`: a Lua stand-in for the game's `C_EncodingUtil` (CBOR the way the game writes it, deflate through LibDeflate, Base64).
- `common.lua`: loads BigWigs' own `BigWigs_Options/Sharing.lua` with the game mocked around it.
- `build.lua`: writes `Warrior Profile.txt` by calling BigWigs' own `GetExportString`, the code behind the Export box.
- `verify.lua`: checks the string with BigWigs' own code:
  - it imports through BigWigs' import code, BigWigs reports success and sends its profile update, and every bar, message, countdown and colour setting lands with the value from `profile.lua`;
  - every key is one BigWigs exports and imports;
  - every number is inside the ranges BigWigs' plugins check on load (parsed from `Bars.lua`, `Messages.lua` and `Countdown.lua`), and positions use valid anchor points;
  - a string with one character changed imports nothing;
  - Python's zlib and cbor2 decode the string on their own.

```
cd source
BW_SRC=/path/to/Interface/AddOns LIBDEFLATE=/path/to/LibDeflate.lua lua build.lua
BW_SRC=/path/to/Interface/AddOns LIBDEFLATE=/path/to/LibDeflate.lua lua verify.lua
```

## Version history
- **v1 (Nov 2 2026):** first release.

## License

MIT with an attribution requirement. See the repository [LICENSE](../../../../LICENSE). Credit: Jon Shaw (Schizzle).
