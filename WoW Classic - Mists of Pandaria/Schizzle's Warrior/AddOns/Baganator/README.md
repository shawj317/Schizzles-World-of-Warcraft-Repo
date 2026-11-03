# Schizzle's Warrior Baganator Profile

A Baganator profile for the non-ElvUI Warrior kit in MoP Classic 5.5.x by Jon Shaw (Schizzle): one dark, compact bag with square icons, item levels in quality colours and junk greyed out, opening in the bottom-right corner where the Details! windows sit. It sorts itself every time it opens, and it pops open on its own at the bank, guild bank, vendors, the auction house, the mailbox, trades and crafting windows.

> **Heads-up:** this is the profile string Baganator's own Export button made from Jon's in-game setup (the compressed form that starts with `BGR!1!`), checked with Baganator's own import and settings code (see [Source files](#source-files-source)). Baganator is one download for every game version, including WoW Forever, so it should import the same way there; that will be checked in game after Forever launches.

| File | Imports as | Needs |
|---|---|---|
| [Warrior Profile.txt](Warrior%20Profile.txt) | a new Baganator profile (`Schizzle's Warrior`) | Baganator and **Syndicator** (Baganator won't load without Syndicator) |

## Install (step by step)
1. Install **Baganator** and **Syndicator**, and turn off ElvUI's bags (the kit turns ElvUI off). Log in.
2. If Baganator shows its welcome window, click **Choose** under **Single bag**.
3. Type `/bgr`. The **Customise Baganator** window opens on **General**.
4. Under the **Profiles** dropdown, click **Import**.
5. Paste the whole contents of `Warrior Profile.txt` (one line starting with `BGR!1!`) into **Paste your import string here** and click **Import**.
6. Baganator asks **Overwrite current profile?** Click **Make new**, type `Schizzle's Warrior` and click **Okay**. Baganator switches to the new profile; your old one stays in the dropdown.
7. Type `/reload`. The square icons need it.

## What you get
| Setting | Value | Baganator default |
|---|---|---|
| Skin | **Dark**, 15 % see-through, borders on | Blizzard |
| Icons | **square** (Dark skin option), 32 px | the skin's usual icons, 37 px |
| Layout | **single bag** for bags and bank | single bag |
| Width | **10 columns** for bags, 16 for the bank | 12 and 18 |
| Spacing | **reduced** | normal |
| Icon text | size 12, item levels in **quality colours** | size 14, white |
| Junk and unusable gear | **junk greyed out, unusable gear marked red** | off |
| Sorting | by type, and **sorted every time the bags open** | by type, only when you click sort |
| Opens by itself at | the bank, a vendor and **the guild bank, a trade, a crafting window, the auction house and the mailbox** | the bank and vendors |
| Junk detection | **RestedXP Guide's junk list** | grey (poor quality) items |
| Upgrade detection | **Pawn**, with its upgrade arrow in the top-left corner of each icon | none |
| Bags open at | bottom right, **24 px from the right edge and 190 px up**, the same corner as the Details! windows | 30 px from the right, 85 px up |
| Bank opens at | bottom left, **30 px in and 190 px up** | 30 px in, 85 px up |

**Where it opens:** 190 px up keeps the bags clear of the action bars and away from the rotation aura in the middle of the screen. The bags open just above the Details! windows, covering only the top few pixels of their title bars while open. To move them, drag the window by its title bar, then tick **Lock windows** in `/bgr` if you don't want them to move again.

**Junk and upgrades:** Baganator picks these up by itself when RestedXP Guide and Pawn are loaded, and both are in the kit. Without RestedXP it goes back to treating grey items as junk; without Pawn there are no upgrade arrows. Both can be changed under **General** in `/bgr`.

**Everything else** (categories, the search box, sort and transfer buttons, the other corner icons) stays at Baganator's defaults. The string is a full export, so every setting is written out, but anything not listed above has Baganator's default value. It holds no character names, realms or gold; Baganator leaves per-character settings out of its exports.

## Notes
- **Syndicator:** it's what Baganator uses to remember every character's bags, bank and gold, so the bag window's character list and the tooltip counts across your alts come from it. It has no settings to import. Its item-count lines in tooltips are on by default; turn them off in `/syn` if TSM's tooltip already shows enough.
- **ElvUI and other skins:** Baganator switches itself to the ElvUI, GW2 or NDui skin when one of those addons is loaded. With ElvUI off, the Dark skin stays.
- **Bag keys:** B and Shift-B open Baganator once it's loaded; nothing to rebind.

## Source files (`source/`)
- `profile.json`: Jon's exported profile, decoded into readable JSON, with the keys in the order Baganator wrote them.
- `build.py`: writes `Warrior Profile.txt` from `profile.json` the same way Baganator's Export button does it (CBOR, then compressed, then base64, behind `BGR!1!`). The rebuild matches the in-game export byte for byte. `--check` tells you if the file is out of date; `--decode` prints the file as JSON, following the steps of Baganator's Import button. It only needs Python 3.
- `json.lua`: a small JSON encoder and decoder; the checks use it to read the decoded profile.
- `verify.lua`: checks the file with Baganator's own code (`Core/Constants.lua`, `Core/Config.lua`, `CustomiseDialog/ImportExport.lua` and the Dark skin's option list):
  - the file rebuilds from `profile.json` and decodes back to it;
  - it goes through Baganator's "Make new" import, which switches to the new profile;
  - every key is one Baganator knows and lands with its exported value, nothing per-character is in it, and the old DEFAULT profile is untouched;
  - widths, icon size and font size are inside the options panel's slider ranges, positions are `{point, x, y}` like Baganator's own, and the auto-open, sorting, junk and upgrade settings are the ones listed above;
  - a cut-off string doesn't decode and a non-Baganator table is refused.
  Set `BUILD=16001` to run the checks as WoW Forever.

```
cd source
python3 build.py
lua verify.lua /path/to/Interface/AddOns
```

## Version history
- **v2 (Nov 2 2026):** replaced with Jon's own in-game export. The bags now sort every time they open and open by themselves at the guild bank, trades, crafting windows, the auction house and the mailbox. Junk detection uses RestedXP Guide and upgrade arrows come from Pawn. The look, sizes and positions are unchanged.
- **v1 (Nov 2 2026):** first release.

## License

MIT with an attribution requirement. See the repository [LICENSE](../../../../LICENSE). Credit: Jon Shaw (Schizzle).
