# Schizzle's Warrior Baganator Profile

A Baganator profile for the non-ElvUI Warrior kit in MoP Classic 5.5.x by Jon Shaw (Schizzle): one dark, compact bag with square icons, item levels in quality colours and junk greyed out, opening in the bottom-right corner where the Details! windows sit.

> **Heads-up:** this is Baganator's own profile import (the JSON form its Import button reads), checked with Baganator's own import and settings code (see [Source files](#source-files-source)). Baganator is one download for every game version, including WoW Forever, so it should import the same way there; that will be checked in game after Forever launches.

| File | Imports as | Needs |
|---|---|---|
| [Warrior Profile.txt](Warrior%20Profile.txt) | a new Baganator profile (`Schizzle's Warrior`) | Baganator and **Syndicator** (Baganator won't load without Syndicator) |

## Install (step by step)
1. Install **Baganator** and **Syndicator**, and turn off ElvUI's bags (the kit turns ElvUI off). Log in.
2. If Baganator shows its welcome window, click **Choose** under **Single Bag**.
3. Type `/bgr`. The **Customise Baganator** window opens on **General**.
4. Under the **Profiles** dropdown, click **Import**.
5. Paste the whole contents of `Warrior Profile.txt` (one line starting with `{`) into **Paste your import string here** and click **Import**.
6. Baganator asks **Overwrite current profile?** Click **Make new**, type `Schizzle's Warrior` and click **Okay**. Baganator switches to the new profile; your old one stays in the dropdown.
7. Type `/reload`. The square icons need it, and it fills in any setting the profile leaves at Baganator's default.

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
| Bags open at | bottom right, **24 px from the right edge and 190 px up**, the same corner as the Details! windows | 30 px from the right, 85 px up |
| Bank opens at | bottom left, **30 px in and 190 px up** | 30 px in, 85 px up |

**Where it opens:** 190 px up keeps the bags clear of the action bars and away from the rotation aura in the middle of the screen. The bags line up with the Details! corner and cover those windows while they're open; close the bags and Details! is back. To move them, drag the window by its title bar, then tick **Lock windows** in `/bgr` if you don't want them to move again.

**Everything else** (sorting, categories, the search box, sort and transfer buttons, item corner icons) stays at Baganator's defaults.

## Notes
- **Syndicator:** it's what Baganator uses to remember every character's bags, bank and gold, so the bag window's character list and the tooltip counts across your alts come from it. It has no settings to import. Its item-count lines in tooltips are on by default; turn them off in `/syn` if TSM's tooltip already shows enough.
- **ElvUI and other skins:** Baganator switches itself to the ElvUI, GW2 or NDui skin when one of those addons is loaded. With ElvUI off, the Dark skin stays.
- **Bag keys:** B and Shift-B open Baganator once it's loaded; nothing to rebind.

## Source files (`source/`)
- `profile.lua`: the settings, as a plain Lua table, with notes.
- `json.lua`: a small JSON encoder and decoder.
- `build.lua`: writes `Warrior Profile.txt` from `profile.lua` (`--check` tells you if it's out of date).
- `verify.lua`: checks the file with Baganator's own code (`Core/Constants.lua`, `Core/Config.lua`, `CustomiseDialog/ImportExport.lua` and the Dark skin's option list):
  - it decodes and goes through Baganator's "Make new" import, which switches to the new profile;
  - every setting is one Baganator knows, lands with the value from `profile.lua`, and every setting not listed is filled in from Baganator's defaults;
  - the old DEFAULT profile is untouched;
  - widths, icon size and font size are inside the options panel's slider ranges, and positions are `{point, x, y}` like Baganator's own;
  - a cut-off string doesn't decode and a non-Baganator table is refused.
  Set `BUILD=16001` to run the checks as WoW Forever.

```
cd source
lua build.lua
lua verify.lua /path/to/Interface/AddOns
```

## Version history
- **v1 (Nov 2 2026):** first release.

## License

MIT with an attribution requirement. See the repository [LICENSE](../../../../LICENSE). Credit: Jon Shaw (Schizzle).
