# Wayfarer

Quest route for **World of Warcraft: Forever** (client 1.60.1, Interface 16001), by Jon Shaw (Schizzle).

`/wayfarer` or `/wf` opens it. `/qr` and `/questroute` still work. It plans the quests in your current zone, or every non-dungeon quest in your log, and can point TomTom at the next step.

Wayfarer is the new name of QuestRoute. It is an improved take on RutaMisiones (shown in game as **Fastest Quest Route**, by Nico, MIT). The measured flight times in `FlightData.lua` are reused from that addon. Wayfarer does not ship the rest of RutaMisiones' source. The two addons can both be installed. This one uses the folder `Wayfarer` and the saved variable `WayfarerDB`.

## Install

1. Copy the `Wayfarer` folder into `Interface\AddOns\` on the Forever client (`World of Warcraft\_forever_\Interface\AddOns\`).
2. The folder name must stay `Wayfarer`.
3. If you still have the old `QuestRoute` folder, delete it. Saved variables are not renamed by the client, and two copies would both try to handle `/qr`.
4. Reload (`/reload`). The first launch copies `QuestRouteDB` into `WayfarerDB` when Wayfarer has no saved settings yet.

Questie and TomTom are optional. Without Questie, Wayfarer still reads your quest log and orders the steps, but it has no objective coordinates, no follow-up chain, and no map pins for those steps. It says so in a notice. Without TomTom there is no arrow. The TomTom checkbox is greyed out and explains that. Neither addon missing stops the window from opening.

## What's on screen

The window opens at the top right. Drag the header or the list to move it. Drag the corner to resize. Escape does not close it. Use the close button or `/wayfarer`. The header shows **This zone** or **All quests**. The cog, a right-click, and `/wayfarer options` open Wayfarer in the AddOns settings. Shift-click a step to skip it (`/wayfarer unskip` puts them back, and so does recalculate).

Settings are in three pages: **General**, **Map**, and **Appearance**. A step with no known location stays in the list as **location unknown** and is not pinned on you.

- **Step 1** is the next thing to do. Click a step to aim TomTom there.
- **Then** lists the following steps, up to the step cap. The rest stay in the plan.
- In **All quests** scope, a zone header appears when the route changes zone, and a line such as `Fly Crossroads → Orgrimmar, ~2m` shows how to get there.
- The gold line is the step count, the rough time, and experience per hour.
- **Avoid** lists quests left out because they are failed, too low, too high, or a dungeon.

Round pins sit on the world map and the minimap: gold for a pickup, bronze for an objective, ember for a turn-in. The current step has a gold ring. An ant trail of dots runs toward the next step. The world-map trail pauses while the map is closed. On the minimap, a leg is drawn only while both ends are inside the minimap circle, so the trail does not run across the rim to a pin that has been pulled in from off the map.

## Options

`/wayfarer config` opens options. The same toggles are also under Esc > Options > AddOns when that panel exists. Route scope itself is in this window and on `/wayfarer scope`.

| Setting | Default | What it does |
|---|---|---|
| Route scope | This zone | **This zone** is the old behavior. **All quests** routes every non-dungeon quest in the log, one zone at a time, current zone first, and it does not bounce between continents. |
| Include low-level quests | Off | Gray quests stay under Avoid. |
| Omit dungeon quests | On | In This zone, turn it off to include dungeon quests. All quests scope always leaves dungeons out. |
| Use flight paths | On | A long leg, or a leg into another zone, is flown or taken by boat or zeppelin when that is faster than walking and you know the flight masters. |
| Up to N levels above you | 3 | Higher quests are left for later. |
| Show N steps | 7 | How many steps the window lists. |
| Show numbered steps | On | Round pins. A step on another map is not drawn until you open that map. |
| Ant trail | On | Dotted trail. |
| Animate the trail | On | The dots march toward the next step. |
| Pin size | 20 | 14 to 32. |
| Trail opacity and color | 90%, gold | Gold, bronze, ember, tan, or white. |
| Theme | Wayfarer | Wayfarer (charcoal, bronze, gold), Classic (dialog box), or Class (your class color, or bronze if it cannot be read). |
| Background | 85% | Opacity of the window backdrop only. Text and icons stay solid. |
| Show border | On | Off removes the edge on every theme. The header, cog, and close button stay flush, with no empty corner. |
| Send every step to TomTom | On | A waypoint for every pinned step. |

## Slash commands

| Command | What it does |
|---|---|
| `/wayfarer`, `/wf`, `/qr`, `/questroute` | Show or hide the route |
| `/wayfarer config` | Options. `options` and `settings` do the same |
| `/wayfarer scope zone` | Current zone only |
| `/wayfarer scope all` | All non-dungeon quests in the log |
| `/wayfarer recalc` | Plan again and point the arrow at step 1. `reset` does the same and does not wipe settings |
| `/wayfarer debug` | Client, Questie, TomTom, and route diagnostics |
| `/wayfarer help` | This list |

`/wf` is a short alias. If another addon already owns it, use `/wayfarer`.

## Questie, TomTom, and flights

Questie is read through `QuestieLoader` when that loader is present. A Questie build that only exposes `LibQuestieDB` is reported in the window and is not read yet.

Flight times are the measured Forever times from RutaMisiones. Wayfarer asks `C_TaxiMap.GetTaxiNodesForMap` which flight masters you know (Kalimdor and Eastern Kingdoms). Boats and zeppelins use a fixed estimate of about 6 minutes, including the wait. The trip is labeled on the step. If the taxi API is missing, the route still plans and simply does not add a flight line.

## Saved variables

`WayfarerDB` keeps the QuestRoute keys (`includeLowLevel`, `omitDungeons`, `showOnMap`, `useTomTom`, `maxLevelsAbove`, `stepsShown`, `font`, `fontSize`, `point`, `configPoint`, `userSized`, `width`, `height`) and adds `scope`, `useFlights`, `showTrail`, `trailAnimated`, `trailAlpha`, `trailR`, `trailG`, `trailB`, `trailCustom`, `pinSize`, `theme`, `backdropAlpha`, and `showBorder`. Schema 2 is stamped on an older file. Nothing is renamed, and a newer schema is not downgraded.

## Check in game

1. Delete the old QuestRoute folder, `/reload`, and confirm the window opens with `/wayfarer`, `/wf`, and `/qr`.
2. An old `QuestRouteDB` should come across (font, filters, window position) the first time Wayfarer has no settings of its own.
3. Drag, resize, `/reload`.
4. `/wayfarer scope all` on a log that spans two zones. Zone headers appear, dungeon quests stay out, and gray quests stay out unless you include them.
5. With a known flight path, a cross-zone step should name the flight or the boat and a minute count. Turn **Use flight paths** off and that line should go away.
6. Open the world map: round pins, colored by pickup / objective / turn-in, gold ring on step 1, and a moving dotted trail. Close the map and the world trail should stop. The minimap trail should only cover legs inside the circle.
7. Click a pin. The tooltip and the TomTom arrow should still work.
8. `/wayfarer scope zone` returns to the current zone only.

## License

MIT. Copyright (c) 2026 Nico and Copyright (c) 2026 Jon Shaw (Schizzle). Flight times are Nico's measurements from RutaMisiones. See [LICENSE](LICENSE).

Visible credit for this project also stays with Jon Shaw (Schizzle) and [https://github.com/shawj317/Schizzles-World-of-Warcraft-Repo](https://github.com/shawj317/Schizzles-World-of-Warcraft-Repo).
