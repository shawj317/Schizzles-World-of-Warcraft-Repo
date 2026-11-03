# Schizzle's Warrior GatherMate2 Profile

A small GatherMate2 profile for the non-ElvUI Warrior kit by Jon Shaw (Schizzle): smaller, slightly see-through node icons so they don't crowd the square [SexyMap](../SexyMap/) minimap.

> **Heads-up:** applied by the [Schizzle's Warrior Setup](../SchizzlesWarriorSetup/) helper addon (`/schizzle gather`). Node data is never touched.

| File | What it is |
|---|---|
| [Profile.lua](Profile.lua) | the profile, in GatherMate2's own setting keys |

## Install (step by step)
1. Install GatherMate2 and the [helper addon](../SchizzlesWarriorSetup/).
2. Log in and click **Yes** on the Schizzle's Warrior prompt, or type `/schizzle gather`.
3. Click **Reload** when asked.

## What it does
- World map icons at 0.85, minimap icons at 0.7 and 90% opacity.
- Everything else stays at GatherMate2's defaults: treasure always shows, herbs, ore and fish only when you have the profession, and the tracking circle within 100 yards.

## Checks
In [SchizzlesWarriorSetup/source](../SchizzlesWarriorSetup/source/): `verify.lua` loads the written profile with GatherMate2's AceDB-3.0 and checks the keys appear in GatherMate2's code.

## Version history
- **v1 (Nov 2 2026):** first release.

## License

MIT with an attribution requirement. See the repository [LICENSE](../../../../LICENSE). Credit: Jon Shaw (Schizzle).
