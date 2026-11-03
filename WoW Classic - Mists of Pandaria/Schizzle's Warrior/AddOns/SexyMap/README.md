# Schizzle's Warrior SexyMap Profile (with MinimapButtonButton)

A SexyMap minimap profile for the non-ElvUI Warrior kit in MoP Classic 5.5.x by Jon Shaw (Schizzle): a **square, dark minimap** with a thin bronze frame, gold zone text, a tan clock and coordinates in Fira Sans Condensed Medium, and Blizzard's clutter hidden. Add-on buttons go into **MinimapButtonButton**.

> **Heads-up:** SexyMap's own import only takes border presets, so the profile is applied by the [Schizzle's Warrior Setup](../SchizzlesWarriorSetup/) helper addon (`/schizzle map`). It uses SexyMap's **global profile**, so other characters on the global profile get it too.

| File | What it is |
|---|---|
| [Profile.lua](Profile.lua) | the profile, in SexyMap's own setting keys |

## Install (step by step)
1. Install SexyMap, MinimapButtonButton and the [helper addon](../SchizzlesWarriorSetup/).
2. Log in and click **Yes** on the Schizzle's Warrior prompt, or type `/schizzle map`.
3. Click **Reload** when asked.
4. Set up MinimapButtonButton (below).

The minimap stays where Blizzard puts it (top right). To move it, untick **Lock Minimap** in `/sexymap`, drag it, and tick it again.

## What it does
- **Square** map, a 2 px **bronze** edge on a near-black fill, Blizzard's round border and the north marker hidden.
- **Zone text** in gold, **clock** and **coordinates** (`45.2, 61.8`, updated twice a second) in Warrior tan, all in Fira Sans Condensed Medium on dark boxes with bronze edges. TomTom's own coordinate box is off in the [TomTom profile](../TomTom/), so coordinates show once.
- **Buttons:** zoom and world map buttons hidden (use the mouse wheel and M); tracking and calendar show on hover; mail, the battleground/LFG eye, zone text and clock always show. Button dragging is locked.
- **Auto zoom out** 5 seconds after you zoom, clamped to the screen, right-click opens SexyMap's options.

## MinimapButtonButton (click guide)
MinimapButtonButton collects add-on buttons (Questie, GatherMate2, TomTom, Details!, WeakAuras and so on) into one button. It has no profile import; settings are typed:
1. Type these, one at a time:
   - `/mbb set autoclose true` (the list closes when the mouse leaves)
   - `/mbb set buttonsperrow 6`
   - `/mbb set scale 9` (scale is in tenths, so 9 = 0.9)
   - `/mbb set direction leftdown` (the list opens to the left and down, away from the screen edge)
2. Drag the MinimapButtonButton button (middle mouse button, or Alt and any button) to just under the bottom-left corner of the minimap.
3. A button it missed: `/mbb include <name>`. One you want left on the map: `/mbb ignore <name>`. `/mbb list` shows both lists.

## Checks
In [SchizzlesWarriorSetup/source](../SchizzlesWarriorSetup/source/): `verify.lua` checks the helper writes this as SexyMap's global profile and points the character at it (the same as SexyMap's own "global profile" option), and that every key here appears in SexyMap's code.

## Version history
- **v1 (Nov 2 2026):** first release.

## License

MIT with an attribution requirement. See the repository [LICENSE](../../../../LICENSE). Credit: Jon Shaw (Schizzle).
