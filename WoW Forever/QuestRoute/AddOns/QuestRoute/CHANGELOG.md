# Changelog

## 1.1.0 (2026-11-09)

Polish release. The route planner is the 1.0.5 planner. `QuestRouteDB` keys are unchanged, and an older file is stamped `schema = 1`.

- Window, options, pins, and type use the charcoal, bronze, and gold UI from the rest of the Forever kit. Native buttons, a header, and a hover highlight.
- Split into modules, an English locale file, and a Forever TOC (`AllowLoadGameType: camelot, forever`, icon, addon compartment, `X-Credits`).
- Secret-value guards, combat deferral for automatic refreshes, and a client check. The approach follows RutaMisiones (Fastest Quest Route) by Nico.
- `GetQuestLogRewardXP` is called with the quest ID. 1.0.5 passed the log index.
- `Render` is no longer a global. The stray `?` on step 1 is gone.
- If Questie is loaded but `QuestieLoader` cannot be read, the notice says that, instead of saying Questie is not installed.
- `/qr help` and `/qr debug` are new. `/qr reset` still means recalculate, not "wipe settings".

## 1.0.5

- Single-file route window: current zone, turn-ins, Questie follow-ups, TomTom, map pins, and `QuestRouteDB`.
