# QuestRoute

Zone quest route for **World of Warcraft: Forever** (client 1.60.1, Interface 16001), by Jon Shaw (Schizzle).

It plans the quests in the zone you are standing in, including turn-ins and Questie follow-ups, and can point TomTom at the next step. Settings save in `QuestRouteDB`.

QuestRoute is an improved take on RutaMisiones (shown in game as **Fastest Quest Route**, by Nico, MIT). It does not ship that addon's files. See [Relationship to RutaMisiones](#relationship-to-rutamisiones). The two addons use different folders and different saved variables, so they can both be installed.

## Install

1. Copy the `QuestRoute` folder into `Interface\AddOns\` on the Forever client (`World of Warcraft\_forever_\Interface\AddOns\`).
2. The folder name must stay `QuestRoute`.
3. Reload (`/reload`).
4. `/qr` opens the route. `/qr help` lists the commands.

Questie and TomTom are optional. Without Questie there are no map pins and no follow-up chain. Without TomTom there is no arrow. The window still plans the route.

## What's on screen

The window opens at the top right. Drag the header or the list to move it. Drag the corner to resize. Escape closes it. The first open uses the default place; after that, `QuestRouteDB` keeps the place and the size.

- **Step 1** is the next thing to do. Click it, or any later step, to aim TomTom at that step.
- **Then** lists the following steps, up to the "Show N steps" setting. The rest stay in the plan.
- The gold line is the step count, the rough time, and experience per hour.
- **Other zones** says how many logged quests are somewhere else, and which of those zones looks like the best move.
- **Notices** fold open when you click the line.
- **Avoid** lists quests left out because they are failed, too low, too high, or a dungeon.

Numbered pins draw on the world map and the minimap while "Show numbered steps on the map" is on. The first pin is filled bronze. Click a pin to aim the arrow. Lines connect pins that are on the map you are looking at (or, on the minimap, pins close enough to be on the minimap).

## Options

`/qr config` opens the options window. The same settings are also registered under Esc > Options > AddOns when the client has that panel.

| Setting | Default | What it does |
|---|---|---|
| Include low-level quests | Off | Gray quests. Off, they are listed under Avoid and left out of the route. |
| Omit dungeon quests | On | Dungeon quests stay out of the route and are listed under Avoid. |
| Up to N levels above you | 3 | Quests higher than you by more than this are left for later. |
| Show N steps | 7 | How many steps the window lists. The plan still contains the rest. |
| Show numbered steps on the map | On | World map and minimap pins. |
| Send every step to TomTom | On | A waypoint for every step that has a pin. The arrow follows step 1 when the route changes. |
| Font and size | Game font, 13 | The route window and the options window. |

Font 6, "PT Sans Narrow Bold", looks for `Interface\AddOns\QuestRoute\Fonts\PTSansNarrow-Bold.ttf`. That file is not included. If it is missing, the game font is used.

The minimap addon compartment (the drawer button) toggles the window. Right-click opens options.

## Slash commands

| Command | What it does |
|---|---|
| `/qr` or `/questroute` | Show or hide the route |
| `/qr config` | Options. `options` and `settings` do the same |
| `/qr recalc` | Show the window, plan again from where you are standing, and point the arrow at step 1. `recalculate` does the same |
| `/qr reset` | Same as `/qr recalc`. It does not wipe saved settings |
| `/qr debug` | Client, Questie, TomTom, and route diagnostics |
| `/qr help` | The command list |

## Questie and TomTom

QuestRoute reads Questie through `QuestieLoader` (`ZoneDB`, `QuestieDB`, `QuestiePlayer`) when that loader is present. Pins, objective names, turn-in NPCs, and the next quest in the chain come from that database. The quest log is still the list of what you have accepted.

If Questie is running but the loader cannot be read, the window says so. That is the case to check on a Questie build that only exposes `LibQuestieDB`. RutaMisiones talks to `LibQuestieDB`. QuestRoute does not, yet.

TomTom gets one waypoint per pinned step (`AddWaypoint` when the step has a uiMap, otherwise `AddZWaypoint` when it has an area id). The crazy arrow is aimed at step 1 when the route changes, and at whatever step you click.

## Saved variables

`QuestRouteDB` is the same table as 1.0.5. These keys are unchanged:

`includeLowLevel`, `omitDungeons`, `showOnMap`, `useTomTom`, `maxLevelsAbove`, `stepsShown`, `font`, `fontSize`, `point`, `configPoint`, `userSized`, `width`, `height`.

Version 1.1.0 stamps `schema = 1` on an older file and does not rename anything. A file written by a newer build (a higher `schema`) is not downgraded. Out-of-range font, size, step count, and level values are clamped the same way 1.0.5 clamped them.

There is no per-character saved variable. QuestRoute and RutaMisiones do not share a database.

## Check in game

This build was checked offline (Lua 5.1 tests, a syntax check, and a load of every file under stubs). It still needs a pass on the Forever client:

1. `/qr` opens the window. Escape closes it. `/qr` again toggles it.
2. Drag it, resize it, `/reload`, and confirm it comes back where you left it.
3. `/qr config` changes "Show N steps" and the list length follows. Turn low-level quests on and off and watch Avoid.
4. `/qr recalc` aims TomTom at step 1. Click a later step and the arrow moves.
5. Open the world map and the minimap and confirm numbered pins, the line between them, and a click that sets the arrow.
6. Accept a quest, turn one in, and change zone. The window should refresh on its own after a short pause, and not throw while you are in combat.
7. With Questie enabled, a follow-up chain should appear after the turn-in when the next quest is in this zone. With Questie disabled, the notice should say it is not installed.
8. If Questie is enabled and the notice says the database could not be read, the installed Questie is the `LibQuestieDB` build. That path is not wired up yet.
9. Right-click the addon compartment icon for options. Left-click toggles the window.
10. Confirm an existing `QuestRouteDB` from 1.0.5 still loads (font, filters, and window position).

## Relationship to RutaMisiones

RutaMisiones (Fastest Quest Route) by Nico is MIT licensed. QuestRoute was written with Cursor as Jon's own take on that addon.

What was checked: QuestRoute does not include RutaMisiones source, locales, guide data, or flight tables. The planner is a different heuristic (nearest ready step, then a short local search). The quest log is read with Questie's older `QuestieLoader` modules, not `LibQuestieDB`.

This release still credits Nico, in `LICENSE`, the TOC notes, and `X-Credits`, because QuestRoute is an improved take on his addon and because a few robustness ideas are adopted from it:

- Secret-value guards and addon-restriction checks (`Secrets.lua`). Forever can hand the addon values that must not be used in arithmetic or as a boolean.
- The three-signal Forever client check (`Detect.lua`): project id, the TOC `[Game]` token, and the 16000–19999 interface band.
- The addon compartment button, and a native AddOns options page when `Settings` exists.
- TOC fields for Forever: `AllowLoadGameType: camelot, forever`, `IconTexture`, and the `X-*` metadata.

Those files are written for QuestRoute. They are not a paste of the RutaMisiones sources.

Worth adding later, from RutaMisiones, if you want them: `LibQuestieDB` as the Questie path, guide-data fallback, flight and boat times, learned quests, auto-accept and auto-turn-in, and ignore-quest. None of those are in this build, so the 1.0.5 route is unchanged apart from the bug fixes below.

## Bug fixes in 1.1.0

- `GetQuestLogRewardXP` was called with the quest log index. On this client that argument is a quest ID, so the experience could belong to a different quest. It now passes the quest ID, and falls back to the no-argument call after selecting the row.
- `Render` was a global. It is local to the window file.
- The step highlight was created and never shown on hover.
- The current step line started with a literal `?`.
- Unit speed, level, map coordinates, and quest-log fields that can be secret on Forever are not used in arithmetic or comparisons. Automatic refreshes wait until combat ends. Recalculate still runs when you click it.

## Files

| File | Purpose |
|---|---|
| `Planner.lua` | Route planner. Plain Lua 5.1, no client API |
| `QuestLog.lua` | Quest log and Questie |
| `MapPins.lua` | TomTom, world map, minimap |
| `UI.lua` | Route window |
| `Options.lua` | Options, the AddOns settings page, the compartment button |
| `Saved.lua` | `QuestRouteDB` defaults and schema 1 |
| `Secrets.lua` | Secret values and addon restrictions |
| `Detect.lua` | Forever / other client signals |
| `Locales/enUS.lua` | English strings |
| `Core.lua` | Load and events |
| `Slash.lua` | `/qr` |

Offline tests live next to this addon in the repo (`WoW Forever/QuestRoute/tests/`) and are not part of the release zip.

## License

MIT. Copyright (c) 2026 Nico and Copyright (c) 2026 Jon Shaw (Schizzle). See [LICENSE](LICENSE).

Visible credit for this project also stays with Jon Shaw (Schizzle) and [https://github.com/shawj317/Schizzles-World-of-Warcraft-Repo](https://github.com/shawj317/Schizzles-World-of-Warcraft-Repo).
