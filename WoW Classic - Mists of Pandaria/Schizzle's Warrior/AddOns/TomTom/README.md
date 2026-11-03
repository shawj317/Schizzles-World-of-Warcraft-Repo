# Schizzle's Warrior TomTom Profile

A TomTom profile for the non-ElvUI Warrior kit by Jon Shaw (Schizzle): the modern waypoint arrow at the top of the screen, out of the [WeakAuras](../WeakAuras/) area, and no second coordinate box (SexyMap shows coordinates).

> **Heads-up:** applied by the [Schizzle's Warrior Setup](../SchizzlesWarriorSetup/) helper addon (`/schizzle tomtom`). Saved waypoints are never touched.

| File | What it is |
|---|---|
| [Profile.lua](Profile.lua) | the profile, in TomTom's own setting keys |

## Install (step by step)
1. Install TomTom and the [helper addon](../SchizzlesWarriorSetup/).
2. Log in and click **Yes** on the Schizzle's Warrior prompt, or type `/schizzle tomtom`.
3. Click **Reload** when asked.

## What it does
- **Arrow:** TomTom's **modern** theme, top centre (24 px down), scale 0.9, locked; shows distance and time to arrive, clears at 10 yards, and switches to the closest waypoint when you reach one.
- **Corpse arrow** on when you die.
- **Coordinate box off** ([SexyMap](../SexyMap/) shows coordinates under the minimap).
- **World map:** Alt-click to drop a waypoint. Minimap and world map waypoints show tooltips.
- Asks before **Remove all waypoints**.

## Checks
In [SchizzlesWarriorSetup/source](../SchizzlesWarriorSetup/source/): `verify.lua` loads the written profile with TomTom's own AceDB-3.0 and checks the keys appear in TomTom's code. The modern arrow theme is in TomTom's `TomTom_Config.lua`.

## Version history
- **v1 (Nov 2 2026):** first release.

## License

MIT with an attribution requirement. See the repository [LICENSE](../../../../LICENSE). Credit: Jon Shaw (Schizzle).
