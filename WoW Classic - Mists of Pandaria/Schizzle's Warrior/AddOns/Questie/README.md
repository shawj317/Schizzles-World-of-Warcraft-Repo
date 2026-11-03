# Schizzle's Warrior Questie Profile

A Questie profile for the non-ElvUI Warrior kit in MoP Classic 5.5.x by Jon Shaw (Schizzle): smaller map icons, a darker tracker in Fira Sans Condensed Medium, and a tracker that stays out of the way in dungeons.

> **Heads-up:** Questie has no settings import, so the profile is applied by the [Schizzle's Warrior Setup](../SchizzlesWarriorSetup/) helper addon (`/schizzle quests`). Questie runs on MoP Classic and WoW Forever with the same settings.

| File | What it is |
|---|---|
| [Profile.lua](Profile.lua) | the profile, in Questie's own setting keys |

## Install (step by step)
1. Install Questie and the [helper addon](../SchizzlesWarriorSetup/).
2. Log in and click **Yes** on the Schizzle's Warrior prompt, or type `/schizzle quests`.
3. Click **Reload** when asked.

Quest progress isn't touched; only settings. Your old profile is kept (`/questie` > Profiles).

## What it does
- **Map icons** at 0.6 (world map and minimap), quest givers and townsfolk a little smaller; quest areas glow on the world map only, not the minimap.
- **Tracker** in Fira Sans Condensed Medium (headers 13, zones and quests 12, objectives 11) on a near-black backdrop and border that only show while the mouse is over it, so the tracker is plain text the rest of the time. Quest levels shown. Locked, and at most 30% of the screen tall, so it ends above the [Details! windows](../Details!/).
- **In dungeons and raids** the tracker minimises; in combat it stays.
- **Quest level** in tooltips.
- **Party announce:** objective and quest item progress posted to party.

If the tracker sits over something on your screen, unlock it in `/questie` > Tracker, drag it, and lock it again.

## Checks
In [SchizzlesWarriorSetup/source](../SchizzlesWarriorSetup/source/): `verify.lua` writes the profile the way the helper does, loads it with Questie's own AceDB-3.0, checks every value comes back as written, and checks every key here appears in Questie's code.

## Version history
- **v1 (Nov 2 2026):** first release.

## License

MIT with an attribution requirement. See the repository [LICENSE](../../../../LICENSE). Credit: Jon Shaw (Schizzle).
