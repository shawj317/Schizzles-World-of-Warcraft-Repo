# Changelog

## 1.3.4 (2026-11-10)

- Wayfarer no longer draws pins on the minimap. World map pins and the TomTom arrow stay. Only the current step's TomTom waypoint asks for a minimap icon. Extra steps, when that option is on, stay off the minimap.

## 1.3.3 (2026-11-10)

- The green arrows left of the minimap were Wayfarer's TomTom waypoints. An earlier guess that they belonged to another addon was wrong. Each route now removes only Wayfarer's own waypoints before adding the next ones, so they do not pile up, and other TomTom waypoints stay. The default is one arrow for the current step. Every step is an option. Clicking a step always creates that waypoint again and points the crazy arrow at it, including after TomTom's own clear. Waypoints are not saved across reloads. An unchanged step does not replace the arrow.
- This zone keeps only steps whose map is the current zone or a child of it. A turn-in, objective, or Questie follow-up on another zone's map is left out, and This zone does not add a flight out of the zone.
- Omit PvP quests is on by default, next to Skip dungeons. Battleground headers (Warsong Gulch, Arathi Basin, Alterac Valley, and the others), PvP tag 41, and battleground maps are listed under Avoid as PvP in both route scopes.
- Auto recalculate is on by default, every 30 seconds (15 to 120). It waits out combat, skips when the window is hidden and TomTom is not loaded, and skips when the log, zone, and rounded position have not changed. Quest log and zone events stay throttled.

## 1.3.2 (2026-11-10)

- Wayfarer is registered in the AddOns list before any individual setting. A control that fails is skipped. The cog opens that category by id. If the category never registered, it says so in chat instead of opening the Game tab. `/wayfarer debugsettings` prints the errors and which Settings functions this client has.
- The route window uses MEDIUM strata, so the settings panel, game menu, world map, bags, and dialogs draw over it. Tooltips still use the normal game tooltip.

## 1.3.1 (2026-11-10)

- The cog opens the Blizzard settings panel without registering the settings again. Registration runs once at load. A second click no longer throws "Setting variable 'Wayfarer_rememberWindow' was previously registered."
- The ant trail is gone. Round numbered pins stay. Ant trail, Animate the trail, and Trail opacity are no longer settings. Old `showTrail`, `trailAnimated`, `trailAlpha`, `trailR`, `trailG`, `trailB`, and `trailCustom` keys are cleared on load.

## 1.3.0 (2026-11-10)

- Settings live only in Blizzard's AddOns panel, under Wayfarer, with General, Map, and Appearance. The old options window is gone. The cog, a right-click, the addon compartment, and `/wayfarer options` open that panel. Labels are short. The explanation is the tooltip. Pin size no longer draws an edit box over the slider.
- General: remember the window, show it on login, hide it in battlegrounds, hide it in dungeons and raids, and Recalculate. Hiding waits until you are out of combat, and the window comes back when you leave.
- Escape no longer closes the route window. Use the close button or `/wayfarer`.
- A collect step with no spawn data stays in the list as location unknown. It does not get a pin or a TomTom arrow, and it is never aimed at you. Item drops use the creatures that drop them. The pin is the middle of that spawn cluster, so it does not follow you.
- Minimap pins are clipped to the minimap.
- Questie and TomTom stay optional. Without Questie the route has no objective coordinates and says so. Without TomTom there is no arrow, and the TomTom checkbox is greyed out.

## 1.2.0 (2026-11-09)

Wayfarer is the new name of QuestRoute. Delete the old `QuestRoute` folder after installing `Wayfarer`. The first launch copies `QuestRouteDB` into `WayfarerDB` when Wayfarer has no saved settings yet. `/qr` and `/questroute` still open it. `/wayfarer` and `/wf` do too.

- Round pins: a disc, a ring, a soft shadow, and a glow on the current step. Pickups are gold, objectives are bronze, turn-ins are ember. Pin size is an option.
- Ant trail: pooled dots along the route, marching toward the next step. The world-map trail pauses while the map is closed. The minimap trail only draws a leg that stays inside the minimap. Trail on/off, animation, color, and opacity are in the Map options.
- Route scope: **This zone** (the default, same route as before) or **All quests** (every non-dungeon quest in the log). All-quests mode does the current zone first, then finishes one continent before the next. `/wayfarer scope zone` and `/wayfarer scope all`. The header shows which scope is on. Gray quests and the step cap still apply. Dungeons are always left out of the all-quests route.
- Flight paths, on by default. A long leg or a zone change is compared with the flight masters you know. Boats and zeppelins link continents. The step can read `Fly Crossroads → Orgrimmar, ~2m`. The measured flight seconds are reused from RutaMisiones (Fastest Quest Route) by Nico, MIT.
- Appearance: themes **Wayfarer** (charcoal, bronze, and gold), **Classic** (dialog box and gold edge), and **Class** (border, header, current-step ring, and the default trail use your class color, or bronze if the class color cannot be read). Background opacity is 0–100%, default 85%, and it tints only the backdrop. **Show border** is on by default; off, every theme drops the edge and the insets so the header, cog, and close button sit flush.
- The route window no longer has Recalculate and Options buttons. A cog in the header opens settings (right-click the window or a step does too). A small refresh icon recalculates, as does `/wayfarer recalc`. Shift-click a step to skip it until the quest list changes, you recalculate, or you `/wayfarer unskip`.

## 1.1.0 (2026-11-09)

Polish release, still named QuestRoute. The route planner is the 1.0.5 planner. `QuestRouteDB` keys were unchanged, and an older file was stamped `schema = 1`.

- Window, options, pins, and type used charcoal, bronze, and gold, with native buttons and a hover highlight.
- Split into modules, an English locale file, and a Forever TOC.
- Secret-value guards, combat deferral for automatic refreshes, and a client check. The approach follows RutaMisiones (Fastest Quest Route) by Nico.
- `GetQuestLogRewardXP` is called with the quest ID. 1.0.5 passed the log index.
- `Render` is no longer a global. The stray `?` on step 1 is gone.

## 1.0.5

- Single-file route window: current zone, turn-ins, Questie follow-ups, TomTom, map pins, and `QuestRouteDB`.
