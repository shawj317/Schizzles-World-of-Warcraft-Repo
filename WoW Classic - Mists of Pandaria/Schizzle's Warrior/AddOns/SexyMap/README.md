# Schizzle's Warrior SexyMap Profile

A SexyMap minimap profile for the non-ElvUI Warrior kit in MoP Classic 5.5.x by Jon Shaw (Schizzle): a **square minimap at 1.5x size** in the top-right corner, framed by a bronze tooltip-style border, with small gold zone text and a tan clock and coordinates in Fira Sans Condensed Medium. These are Jon's own settings, tuned in game and taken from SexyMap's saved settings (only the shared profile, no character names or realms).

> **Heads-up:** SexyMap's own import only takes border presets, so the profile is applied by the [Schizzle's Warrior Setup](../SchizzlesWarriorSetup/) helper addon (`/schizzle map`). It uses SexyMap's **global profile**, so other characters on the global profile get it too.

| File | What it is |
|---|---|
| [Profile.lua](Profile.lua) | the profile, in SexyMap's own setting keys |

## Install (step by step)
1. Install SexyMap, MinimapButtonButton and the [helper addon](../SchizzlesWarriorSetup/).
2. Log in and click **Yes** on the Schizzle's Warrior prompt, or type `/schizzle map`.
3. Click **Reload** when asked.
4. Set up MinimapButtonButton (below).

The minimap sits in the top-right corner, about 4 px in from each edge. It's left **unlocked**, the way Jon has it, so it can be dragged anywhere; tick **Lock Minimap** in `/sexymap` to pin it.

Already ran the helper before v2? Type `/schizzle map` and reload to get the new map.

## What it does
- **Square** map at **1.5x** Blizzard's size, clamped to the screen, with Blizzard's round border and the north marker hidden.
- **Border:** no background plate behind the map, just Blizzard's tooltip border (6 px) in bronze, set 3% out from the map's edge.
- **Zone text** in gold, size 9, sitting 18 px lower than SexyMap's spot. **Clock** in Warrior tan, size 9. **Coordinates** (`45.2, 61.8`) in tan, size 8, 9 px up from the bottom, updated ten times a second. All of them are in Fira Sans Condensed Medium on dark boxes with bronze edges. TomTom's own coordinate box is off in the [TomTom profile](../TomTom/), so coordinates show once.
- **Buttons:** the calendar, zoom and world map buttons are hidden (use the mouse wheel and M). Tracking, mail, the battleground/LFG eye, zone text and clock always show. Button dragging is locked.
- **Add-on buttons:** Bartender4, BigWigs, Details! (and its streamer), Leatrix Plus, Questie, RareScanner, RestedXP Guide, TomTom, TradeSkillMaster and WeakAuras are set to always show, not only on hover, if they're on the map.
- **Movers:** the durability figure (the little armour man) can be moved and is locked in place. Buffs, the objective tracker and the other movers stay where Blizzard puts them.
- **Auto zoom out** 15 seconds after you zoom; right-click opens SexyMap's options.

### What changed in v2
| Setting | v1 | v2 |
|---|---|---|
| Map size | Blizzard's | **1.5x** |
| Map position | where Blizzard puts it | **top right, about 4 px in** |
| Lock minimap | on | **off** |
| Auto zoom out | after 5 s | **after 15 s** |
| Border | 2 px solid bronze line on a near-black plate | **6 px bronze tooltip border, no plate** |
| Calendar button | on hover | **hidden** |
| Tracking button | on hover | **always** |
| Add-on buttons | SexyMap's default (on hover) | **always** (11 buttons) |
| Clock text | size 11 | **size 9** |
| Zone text | size 12, at SexyMap's spot | **size 9, 18 px lower** |
| Coordinates | size 11, 10 px up, twice a second | **size 8, 9 px up, ten times a second** |
| Durability figure | Blizzard's | **movable, locked** |

The font, the colours (gold, tan, charcoal and bronze) and the square shape are the same as v1.

## MinimapButtonButton (click guide)
MinimapButtonButton collects add-on buttons (Questie, GatherMate2, TomTom, Details!, WeakAuras and so on) into one button. Any button it collects goes into its list whatever SexyMap's setting says; the "always" setting above covers the ones left on the map. It has no profile import; settings are typed:
1. Type these, one at a time:
   - `/mbb set autoclose true` (the list closes when the mouse leaves)
   - `/mbb set buttonsperrow 6`
   - `/mbb set scale 9` (scale is in tenths, so 9 = 0.9)
   - `/mbb set direction leftdown` (the list opens to the left and down, away from the screen edge)
2. Drag the MinimapButtonButton button (middle mouse button, or Alt and any button) to just under the bottom-left corner of the minimap.
3. A button it missed: `/mbb include <name>`. One you want left on the map: `/mbb ignore <name>`. `/mbb list` shows both lists.

## Checks
In [SchizzlesWarriorSetup/source](../SchizzlesWarriorSetup/source/): `verify.lua` checks the helper writes this as SexyMap's global profile and points the character at it (the same as SexyMap's own "global profile" option). It also checks every v2 value above, makes sure no character names or realms got in, and confirms every key here appears in SexyMap's code. The add-on button names are checked against the `LibDBIcon10_` frame names that SexyMap's LibDBIcon creates.

## Version history
- **v2 (Nov 2 2026):** Jon's own in-game setup (see the table above).
- **v1 (Nov 2 2026):** first release.

## License

MIT with an attribution requirement. See the repository [LICENSE](../../../../LICENSE). Credit: Jon Shaw (Schizzle).
