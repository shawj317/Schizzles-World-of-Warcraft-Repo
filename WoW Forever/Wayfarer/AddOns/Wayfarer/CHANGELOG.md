# Changelog

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
