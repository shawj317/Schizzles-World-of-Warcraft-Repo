# Schizzle's Questie Zones

A small WoW Forever companion by Jon Shaw (Schizzle). Collapse a zone (or any other Questie tracker group) and it stays collapsed after `/reload` and after a relog on that character. Expand it, and it stays expanded.

Questie is not shipped in this repo. The Forever kit lists **Questie 12.5.0** (`_Camelot.toc`, Interface 16001). The same tracker behaviour is in the later Forever builds **12.5.1, 12.6.0 and 12.6.4**. This addon is the fix for those builds. It does not replace Questie.

## Why a reload opens the zone

Questie stores the choice on the character, in `Questie.db.char.collapsedZones`. On Forever it also keeps Blizzard's native quest watch. Each login and `/reload`, tracker init re-adds those watched quests and clears the collapsed flag for each quest's group. The group draws expanded. The click itself is fine; the next load throws the choice away.

## What it does

On `ADDON_LOADED`, before that retrack, it remembers the collapsed groups for this character in its own per-character saved variables. After Questie says it is ready (`Questie.API.RegisterOnReady`), it writes those same keys back if the retrack cleared them, then asks the tracker to draw again when `QuestieTracker:Update` is already there.

A click after that is remembered as-is. Tracking a new quest still opens that quest's group, which is Questie's own rule. A tracker refresh that does not clear the table leaves a collapsed group collapsed. A group you have never collapsed stays expanded. Another character has its own list.

It writes keys on `Questie.db.char.collapsedZones` only. It does not replace that table. Questie's profile, account data, sort order, completed-quest collapse, and the minimise-in-dungeons / minimise-in-combat behaviour are left alone. No tracker button scripts are hooked.

## Install

1. Install a Forever Questie build from **12.5.0 through 12.6.x** (Interface 16001, the `_Camelot.toc` build). 12.5.0 is the version this kit was checked against on Nov 3 2026. 12.6.4 is the newest Forever tag read for this addon (Nov 7 2026).
2. Copy the inner `SchizzlesQuestieZones` folder (the one with the `.toc`) into `World of Warcraft\_forever_\Interface\AddOns\`.
3. Enable **Schizzle's Questie Zones** on the addons list. It loads after Questie when both are enabled.
4. `/reload`.

Chat prints one line when the version is one it accepts. `/sqz` prints how many groups are collapsed for this character. Collapse a zone, `/reload`, and the zone stays collapsed.

The first collapse after install is the one that sticks. A collapse that a previous reload already threw away is already gone from Questie's saved variables, so collapse that zone once more.

## Uninstall

1. Disable **Schizzle's Questie Zones**, or delete `Interface\AddOns\SchizzlesQuestieZones`.
2. Delete this character's saved file: `WTF\Account\<Account>\<Realm>\<Character>\SavedVariables\SchizzlesQuestieZones.lua`.
3. `/reload`.

Questie's own `QuestieConfig` saved variables are not part of this addon. Leave them in place. After uninstall, a reload opens collapsed groups again, which is stock Questie.

## Checked builds and limits

| Questie | What was read |
|---|---|
| 12.5.0 | Forever `_Camelot.toc`, Interface 16001. The kit's listed build. |
| 12.5.1, 12.6.0, 12.6.4 | Same character table, same clear inside the native-watch retrack, same `Questie.API.RegisterOnReady`. |

The addon accepts any **12.5.x** or **12.6.x** version string. Any other version, a missing `RegisterOnReady`, or a `collapsedZones` value that is not a table, makes it print the reason and change nothing.

In-game checking on client 1.60.1 is not available in this workspace. The reload, relog, and click paths were run in an offline simulation of the character table (`source/test.lua`). They were not clicked inside the Forever client.

Other limits:

- For about half a second after Questie finishes loading, outside combat, a cleared group is put back. That window is the login retrack. A click after it sticks, including the expand Questie does when a new quest is tracked.
- While you are in combat at login, the retrack waits. Clicks during that combat are kept. When combat ends, groups the retrack opens are put back if you had collapsed them.
- Sort modes that use one header ("Quests (By Level)" and the others) use that header text as the key. Switching sort mode does not carry a zone name onto the new header.
- Achievements and Recipes use the same character table. A collapse there is remembered too.
- `/sqz` is the only command. There is no option window.

## Source files

| File | What it is |
|---|---|
| [SchizzlesQuestieZones/Logic.lua](SchizzlesQuestieZones/Logic.lua) | the per-character memory |
| [SchizzlesQuestieZones/Core.lua](SchizzlesQuestieZones/Core.lua) | Questie ready callback, ticker, saved variables |
| [source/test.lua](source/test.lua) | the per-character memory, including reload, expand, zones, characters and a new quest |
| [source/core_test.lua](source/core_test.lua) | loads the addon against a stand-in client: ready callback, redraw, saved variables, and a refused version |

Run both from this folder: `lua5.1 source/test.lua` and `lua5.1 source/core_test.lua`

## License

MIT with an attribution requirement. See the repository [LICENSE](../../../../LICENSE). Credit: Jon Shaw (Schizzle). https://github.com/shawj317/Schizzles-World-of-Warcraft-Repo
