# Ashen Trail v1.3.0: re-audit task list (Nov 4, 2026, 5:04 PM EST)

1. Fix the XP/hr label: UI.lua:795 reads `AT.XpText` but Tracker.lua:2279 sets `AT.xpText`. Rename it, and update the label from the ticker every second.
2. Replace the Excavation Site Horde steps (Data.lua:168 and :278, RXP pack :699). "Lost in the Thicket Things" from Llana is the Alliance chain. Use the Horde pickups from questing.wiki: "Changing Tastes" from Borstan in Orgrimmar, and "Earthen Echo", which ends at Muln Earthfury in Mulgore.
3. UI.lua:932: restore `local step = AT.CurrentStep()` inside UpdateMapPins. Without it the C_QuestLog.GetNextWaypoint pins never show.
4. Call UpdateMinimapPins from the ticker, throttled to about 0.5s, and use yards from C_Map.GetWorldPosFromMapPos plus the minimap zoom.
5. Fix the Warrior opener in TALENT. Cruelty is row 2 and can't be taken at level 10, so start with Improved Heroic Strike or Deflection. Check every class against the Talents Forever data.
6. Anchor the Target and quest-item holders to UIParent with their own saved position, not to the main frame, so moving or scaling the window in combat can't be blocked.
7. RXP pack: add `.complete 871,2` and `.complete 871,3`.
8. Test `/targetexact "Name"` in game and drop the quotes if they break targeting.
9. Commit scripts/generate-addon.ts, or remove the "Do not edit by hand" header from Data.lua.
10. Confirm where Mazu'kon and The Drowned City entrance are on Forever.
11. Clean up the unused UI.lua code (guideRows, renderOptions, pinPool, stepLabel), and fix the `|cRXP_FRIENDLY_` color code in the RXP toc title.

## Feature roadmap (after the fixes above, highest impact first)

### Biggest wins
12. Real Forever routes: replace the Classic placeholders zone by zone with Forever quest IDs, starting with Skyborne and levels 1 to 12. Source them from questing.wiki (CC BY, credit it) or Wowhead Forever. Write the route text yourself; don't copy RXP's.
13. Route modes: a Speedrun mode (fastest path) and a Discovery mode (prioritize new Forever quests and zones), switchable in options.
14. Per-class branches: class quests at 10, 20 and 30, the Warlock pet chains, the Undead Paladin chain, and the Dwarf Shaman chain. Use the existing `only` tags.
15. Legacy Points and Legacy achievements: recommend where to spend points as you level, and track progress on the Legacy achievements.

### Quality of life
16. Smart quest skipping: mark quests that aren't worth the time, and suggest which to abandon as the 40-quest log fills up.
17. Group and elite warnings: flag elite and group quests ahead of time, with an option to skip them.
18. Hearthstone planning: show the hearthstone cooldown and add "set hearth here" steps at inns.
19. Shopping reminders before leaving town: bags, food and water, arrows or ammo, class reagents.
20. Trainer reminders: when new ranks are available, show the nearest trainer and an ETA.
21. Rare and treasure hooks: if RareScanner is loaded, surface rares near the current route.
22. Gathering route overlay: if GatherMate2 is loaded and you have Mining or Herbalism, show nodes along the current leg.

### Progress and stats
23. Session summary: XP per hour, quests per hour, time to level, gold earned this session, and a comparison with your previous best time for the current level.
24. Per-character level history: time spent at each level, stored in SavedVariables, so alts can compare their pace with the main.

### Polish
25. Import and export of custom routes as a shareable string.
26. Compact mode: show only the current step and the arrow.
27. Sound cues: step complete, quest ready to turn in, level up. Each can be turned off.
28. Account-wide settings profile that alts pick up by default.

### Out of scope on Forever (blocked in combat)
Combat advice like "safe to pull", automatic targeting or clicks in combat, and anything that reads health, auras or cooldowns.
