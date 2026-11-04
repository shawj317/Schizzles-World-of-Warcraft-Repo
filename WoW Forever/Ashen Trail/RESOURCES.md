# Ashen Trail: resources for the task list

Compiled for Jon Shaw (Schizzle) to hand to Cursor alongside [TASKS.md](TASKS.md). The numbers below match the task numbers in that file. Every link was checked on Nov 4, 2026. Links marked *(403)* refuse automated fetches but exist; open them in a browser.

## Ground rules

- **Ashen Trail stays original.** Overlapping features with Dugi, RestedXP or Zygor are fine. Copying their code, guide text or route data is not.
- **Licenses to respect:**
  - The RestedXP guide files are CC BY-NC-SA 4.0. Read them for ideas only and never paste them in.
  - Questie is GPL-3.0. Use it as a reference only.
  - GatherMate2 is "All Rights Reserved". Call its public functions at runtime and never copy its code.
  - Talents Forever data is CC BY 4.0. You may use it with credit and a link.
  - questing.wiki pages say where each dataset comes from and under what license. Credit questing.wiki for anything taken from it.
- **Forever is the Retail (Midnight) client on interface 16001**, not the Classic client. Use the modern `C_*` APIs. Many Classic globals are gone, for example `GetTalentInfo` and the old `GetItemCooldown`.

## Core references (all tasks)

- **WoW Forever hub on questing.wiki:** https://questing.wiki/wow-forever/
  - Use it for quest IDs, givers and enders, NPC coordinates, zones and dungeons.
  - Quest pages follow `/wow-forever/quests/<id>/`.
- **Wowhead WoW Forever:** https://www.wowhead.com/forever
  - The database is at https://www.wowhead.com/forever/database *(403)*.
  - Use it to cross-check quest, NPC and item IDs.
- **Wowhead launch compendium:** https://www.wowhead.com/forever/news/every-guide-youll-need-for-launch-the-wow-forever-guide-compendium-383727
  - An overview of every Forever system, including Legacy, races and dungeons.
- **Blizzard UI source for Forever:** https://github.com/Gethe/wow-ui-source/tree/forever
  - This is the `forever` branch of the FrameXML mirror (branches `classic_era` and `live` also exist).
  - The generated API docs are in https://github.com/Gethe/wow-ui-source/tree/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated
  - Use them to confirm an API exists on Forever before you call it.
- **TOC format:** https://warcraft.wiki.gg/wiki/TOC_format
  - Covers `## Interface: 16001`, the `_Forever` / `_Camelot` TOC suffixes and the `AllowLoadGameType forever` directive.
- **Forever addon findings, measured in the beta client:** https://github.com/Thunderz96/forever-addon-kit (MIT)
  - Read it before trusting any Classic-era assumption.
  - It found that Forever is the Retail client and that talents use `C_Traits`.
  - It found that registering an unknown event throws, so wrap `RegisterEvent` in `pcall`.
  - It found a beta bug where SavedVariables were never read back. Re-test this on the live build.
- **Community bug tracker:** https://github.com/ClassicWoWCommunity/forever-bugs
  - Check it before blaming Ashen Trail for odd client behaviour.
- **Lua 5.1 manual:** https://www.lua.org/manual/5.1/
- **luacheck:** https://github.com/lunarmodules/luacheck

## Forever combat and secret-value restrictions (tasks 4, 6, 8 and "out of scope")

- **Secret values:** https://warcraft.wiki.gg/wiki/Secret_Values
  - Describes what tainted code can't do with secret values: compare them, do arithmetic, or use them as table keys.
  - Lists the `C_Secrets` predicates and the `addonCombatRestrictionsForced` CVar, which simulates combat restrictions out of combat.
- **issecretvalue:** https://warcraft.wiki.gg/wiki/API_issecretvalue
  - Guard any value that might be secret before you compare it or do maths with it.
- **Forever restrictions explainer:** https://wowforevertierlist.com/addons/restrictions
  - A plain-English summary: no combat log, secret values in combat, and secret chat in instances.
- **Icy Veins on Forever addons:** https://www.icy-veins.com/wow-forever/news/addons-in-wow-forever-blizzard-devs-just-addressed-the-big-question/
  - Blizzard's statement that Forever uses the Retail addon API.
- **Combat lockdown and taint:** https://warcraft.wiki.gg/wiki/Secure_Execution_and_Tainting
  - The rule behind task 6: restrictions on a protected frame also apply to its parents and to anything it is anchored to.
- **InCombatLockdown:** https://warcraft.wiki.gg/wiki/API_InCombatLockdown
  - Lists what is blocked in combat: Show, Hide and SetPoint on protected frames.
- **PLAYER_REGEN_ENABLED:** https://warcraft.wiki.gg/wiki/PLAYER_REGEN_ENABLED
  - Queue layout changes and run them when this fires.
- **SecureActionButtonTemplate:** https://warcraft.wiki.gg/wiki/SecureActionButtonTemplate
  - The target and quest-item buttons use this template.
  - It explains the `macrotext` 255-character limit and `InsecureActionButtonTemplate`.

## Fixes (1-11)

**1. XP/hr label**
- UnitXP: https://warcraft.wiki.gg/wiki/API_UnitXP
- UnitXPMax: https://warcraft.wiki.gg/wiki/API_UnitXPMax
- PLAYER_XP_UPDATE: https://warcraft.wiki.gg/wiki/PLAYER_XP_UPDATE
  - Use this event as the XP source. The ticker only redraws the label.

**2. Excavation Site, Horde steps**
- The dungeon page: https://questing.wiki/wow-forever/dungeons/excavation-site-wetlands/
  - It lists both factions' quest chains.
- "Changing Tastes" (95697): https://questing.wiki/wow-forever/quests/95697/
  - The Horde pickup from Borstan.
- "Earthen Echo" (98823): https://questing.wiki/wow-forever/quests/98823/
  - The Horde chain ending at Muln Earthfury.
- "Lost in the Thicket Things" (95647): https://questing.wiki/wow-forever/quests/95647/
  - The Alliance chain. Use it to confirm what to remove from the Horde steps.

**3. Map pins (`UpdateMapPins`)**
- C_QuestLog.GetNextWaypoint: https://warcraft.wiki.gg/wiki/API_C_QuestLog.GetNextWaypoint
  - Returns `mapID, x, y` for a quest. It is available on Forever.
- C_Map.GetBestMapForUnit: https://warcraft.wiki.gg/wiki/API_C_Map.GetBestMapForUnit

**4. Minimap pins on the ticker**
- C_Map.GetWorldPosFromMapPos: https://warcraft.wiki.gg/wiki/API_C_Map.GetWorldPosFromMapPos
  - Converts map coordinates into world yards.
- C_Map.GetPlayerMapPosition: https://warcraft.wiki.gg/wiki/API_C_Map.GetPlayerMapPosition
  - Returns nil in instances. Hide the pins there.
- Minimap:GetZoom: https://warcraft.wiki.gg/wiki/API_Minimap_GetZoom
- MINIMAP_UPDATE_ZOOM: https://warcraft.wiki.gg/wiki/MINIMAP_UPDATE_ZOOM
  - Fires when the minimap switches between indoor and outdoor zoom.
- GetPlayerFacing: https://warcraft.wiki.gg/wiki/API_GetPlayerFacing
  - Needed when the minimap rotates. Returns nil in instances.
- Console variables (search for `rotateMinimap`): https://warcraft.wiki.gg/wiki/Console_variables
  - Read the CVar with `GetCVar("rotateMinimap")`.
- HereBeDragons: https://github.com/Nevcairiel/HereBeDragons
  - Also on CurseForge: https://www.curseforge.com/wow/addons/herebedragons *(403)*.
  - It is the standard library for map and world coordinates and for map and minimap pins.
  - HereBeDragons-Pins: https://github.com/Nevcairiel/HereBeDragons/blob/master/HereBeDragons-Pins-2.0.lua
  - Embedding it would replace the hand-rolled minimap maths in task 4. Check its license before bundling.

**5. Talent openers**
- Talents Forever: https://talentsforever.com/
  - About: https://talentsforever.com/about
  - Terms (data under CC BY 4.0): https://talentsforever.com/terms
- **Export URLs:**
  - Full dump: https://talentsforever.com/data.json
  - Per class: `https://talentsforever.com/export/<class>.json`, for example https://talentsforever.com/export/warrior.json
  - Use the export to check that every class's first points are legal at level 10.
- **License and attribution:** https://creativecommons.org/licenses/by/4.0/
  - Credit "Talents Forever (talentsforever.com), CC BY 4.0" in the README.
- Class talent planners on questing.wiki, built from the Talents Forever data: https://questing.wiki/wow-forever/talents/warrior/
  - Swap the class in the URL for druid, hunter, mage, paladin, priest, rogue, shaman or warlock.
- Talent data notes on the Forever wiki: https://wowfwiki.com/wiki/Project:Talent_data
- C_Traits.GetNodeInfo: https://warcraft.wiki.gg/wiki/API_C_Traits.GetNodeInfo
  - Forever talents run on `C_Traits`.
  - The Classic `GetTalentInfo` is gone (see the API page: https://warcraft.wiki.gg/wiki/API_GetTalentInfo).
- TraitConfig API docs: https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/TraitConfigDocumentation.lua

**6. Holders anchored to UIParent**
- The anchoring rule: https://warcraft.wiki.gg/wiki/Secure_Execution_and_Tainting
  - The "Protected frames and secure templates" section explains why the holders must not be anchored to the main frame.
- Combat restrictions: https://warcraft.wiki.gg/wiki/API_InCombatLockdown
- SavedVariables for the holders' own positions: https://warcraft.wiki.gg/wiki/Saving_variables_between_game_sessions

**7. RXP pack `.complete 871,2/3`**
- The quest: https://questing.wiki/wow-forever/quests/871/
  - "Disrupt the Attacks". Use it to confirm the objective indexes.
- RXP guide syntax: https://github.com/RestedXP/RXPGuides
  - License (CC BY-NC-SA 4.0): https://github.com/RestedXP/RXPGuides/blob/master/LICENSE
  - Reference only, for the syntax of the optional RXP pack.

**8. `/targetexact`**
- SecureActionButtonTemplate: https://warcraft.wiki.gg/wiki/SecureActionButtonTemplate
  - Covers the `macro` / `macrotext` action types.
  - Test `/targetexact` in game with and without the quotes.
- UnitName: https://warcraft.wiki.gg/wiki/API_UnitName
  - Unit-derived values may be secret in combat on Forever (see the Secret_Values page). Guard them with `issecretvalue` before comparing.

**9. generate-addon.ts header**
- No external resource is needed. Either commit the generator or drop the "Do not edit by hand" header.

**10. Mazu'kon and The Drowned City**
- questing.wiki has no Drowned City dungeon page yet.
  - The dungeon list is at https://questing.wiki/wow-forever/dungeons/.
  - Check the NPC search at https://questing.wiki/wow-forever/npcs/ for Mazu'kon.
- Zygor's Forever page: https://zygorguides.com/forever/
  - Confirms The Drowned City is one of the 9 new Forever dungeons. Read it for context and copy nothing.
- Wowhead Forever: https://www.wowhead.com/forever
  - Search it for the entrance and NPC.
  - Confirm the location in game before shipping coordinates.

**11. Clean-up and the RXP toc title**
- TOC format: https://warcraft.wiki.gg/wiki/TOC_format
  - `## Title` takes normal `|cAARRGGBB...|r` color escapes. `|cRXP_FRIENDLY_` only works inside RXP's own renderer.
- luacheck: https://github.com/lunarmodules/luacheck
  - Use it to find the unused locals.

## Feature roadmap (12-28)

**12. Real Forever routes**
- questing.wiki:
  - Leveling: https://questing.wiki/wow-forever/leveling/
  - Zones: https://questing.wiki/wow-forever/zones/
  - Races (Skyborne start): https://questing.wiki/wow-forever/races/
  - Quests index: https://questing.wiki/wow-forever/quests/
- Wowhead Forever database: https://www.wowhead.com/forever/database *(403)*
  - Cross-check IDs here.
- C_QuestLog.IsQuestFlaggedCompleted: https://warcraft.wiki.gg/wiki/API_C_QuestLog.IsQuestFlaggedCompleted
  - Use it to auto-skip steps that are already done.
- QUEST_TURNED_IN: https://warcraft.wiki.gg/wiki/QUEST_TURNED_IN
- Write the step text yourself, and credit questing.wiki for IDs and coordinates.

**13. Speedrun and Discovery modes**
- For ideas only, with nothing copied:
  - RestedXP Forever: https://shop.restedxp.com/forever/ *(timed out)*. It sells Speedrun, Dungeon, Discovery and Legacy guides.
  - Zygor Forever: https://zygorguides.com/forever/
  - Dugi's Forever update: https://www.dugiguides.com/dugi-wow-forever-guide-update/
  - RestedXP addon on CurseForge: https://www.curseforge.com/wow/addons/restedxp-guide *(403)*.

**14. Per-class branches**
- Class and race pages on questing.wiki: https://questing.wiki/wow-forever/races/
  - New combinations such as Undead Paladin and Dwarf Shaman.
- Talent planners: https://questing.wiki/wow-forever/talents/warrior/
  - Swap the class in the URL.
- Zygor's Forever page: https://zygorguides.com/forever/
  - Notes that new race and class combinations get their own class quests. Context only.

**15. Legacy Points and achievements**
- Legacy system: https://questing.wiki/wow-forever/legacy/
- Wowhead's launch compendium: https://www.wowhead.com/forever/news/every-guide-youll-need-for-launch-the-wow-forever-guide-compendium-383727
  - Covers the Legacy system.
- Forever's Legacy tree also runs on `C_Traits`. See the forever-addon-kit findings: https://github.com/Thunderz96/forever-addon-kit
  - That tree unlocks at level 25 and has a seasonal point cap.

**16. Smart skipping and the 40-quest log**
- C_QuestLog.GetMaxNumQuestsCanAccept: https://warcraft.wiki.gg/wiki/API_C_QuestLog.GetMaxNumQuestsCanAccept
- C_QuestLog.GetInfo: https://warcraft.wiki.gg/wiki/API_C_QuestLog.GetInfo
  - The Forever API for reading the quest log.
  - The legacy `GetQuestLogTitle` (https://warcraft.wiki.gg/wiki/API_GetQuestLogTitle) does not list Forever under its game types, so prefer `C_QuestLog.GetInfo`.

**17. Group and elite warnings**
- C_QuestLog.GetInfo: https://warcraft.wiki.gg/wiki/API_C_QuestLog.GetInfo
  - `suggestedGroup` > 0 marks a group quest.
- questing.wiki quest pages show the quest type: https://questing.wiki/wow-forever/quests/

**18. Hearthstone planning**
- GetBindLocation: https://warcraft.wiki.gg/wiki/API_GetBindLocation
- C_Container.GetItemCooldown: https://warcraft.wiki.gg/wiki/API_C_Container.GetItemCooldown
  - Hearthstone is item 6948.
- C_Item.GetItemCooldown: https://warcraft.wiki.gg/wiki/API_C_Item.GetItemCooldown
- The legacy GetItemCooldown: https://warcraft.wiki.gg/wiki/API_GetItemCooldown
  - Its deprecation fallback was removed in 12.1.5, and Forever includes changes up to 12.1.5. Don't call it.
- TaxiNodeGetType: https://warcraft.wiki.gg/wiki/API_TaxiNodeGetType
  - Only valid while the flight map is open.

**19. Shopping reminders**
- GetMoney: https://warcraft.wiki.gg/wiki/API_GetMoney
- Items index on questing.wiki: https://questing.wiki/wow-forever/items/
  - Use it for reagent, ammo and food item IDs.

**20. Trainer reminders**
- PLAYER_LEVEL_UP: https://warcraft.wiki.gg/wiki/PLAYER_LEVEL_UP
- NPC index (trainer locations): https://questing.wiki/wow-forever/npcs/

**21. RareScanner hooks**
- RareScanner: https://www.curseforge.com/wow/addons/rarescanner *(403)*
  - Also on Wago: https://addons.wago.io/addons/rarescanner
  - No documented public API was found. Read the installed addon's source before relying on any function.
  - If there's nothing stable, only detect that it's loaded and point the player to its own UI.

**22. GatherMate2 overlay**
- Source: https://github.com/Nevcairiel/GatherMate2
  - Main file: https://github.com/Nevcairiel/GatherMate2/blob/master/GatherMate2.lua
  - CurseForge: https://www.curseforge.com/wow/addons/gathermate2 *(403)*.
  - Its toc lists Interface 16001 and `X-License: ARR`.
- Public entry points in its source:
  - `_G.GatherMate2`
  - `GatherMate:GetNodesForZone(zone, nodeType, ignoreFilter)`
  - `GatherMate:FindNearbyNode(zone, x, y, nodeType, radius, ignoreFilter)`
  - `GatherMate:DecodeLoc(id)`
  - The AceEvent messages `GatherMate2NodeAdded` and `GatherMate2NodeDeleted`
- Call these at runtime only. Copy no code, because the license is ARR.

**23. Session summary**
- TIME_PLAYED_MSG: https://warcraft.wiki.gg/wiki/TIME_PLAYED_MSG
- RequestTimePlayed: https://warcraft.wiki.gg/wiki/API_RequestTimePlayed
  - Suppress the chat echo when you call it.
- PLAYER_XP_UPDATE: https://warcraft.wiki.gg/wiki/PLAYER_XP_UPDATE
- QUEST_TURNED_IN: https://warcraft.wiki.gg/wiki/QUEST_TURNED_IN
  - Includes `xpReward` and `moneyReward`.
- GetMoney: https://warcraft.wiki.gg/wiki/API_GetMoney

**24. Per-character level history**
- SavedVariables and SavedVariablesPerCharacter: https://warcraft.wiki.gg/wiki/Saving_variables_between_game_sessions
  - Also https://warcraft.wiki.gg/wiki/TOC_format#SavedVariables
- PLAYER_LEVEL_UP: https://warcraft.wiki.gg/wiki/PLAYER_LEVEL_UP
- Re-test SavedVariables persistence on the live build. The beta bug is described at https://github.com/Thunderz96/forever-addon-kit.
- Store only levels and durations. Don't store gold history or any account or realm identifiers in a shared export.

**25. Import and export strings**
- LibSerialize: https://github.com/rossnichols/LibSerialize
  - A compact serializer, recommended together with LibDeflate.
- LibDeflate: https://github.com/SafeteeWoW/LibDeflate
  - Compression and `EncodeForPrint` for copy-paste strings.
  - Also on CurseForge: https://www.curseforge.com/wow/addons/libdeflate *(403)*.
- AceSerializer-3.0: https://www.wowace.com/projects/ace3/pages/api/ace-serializer-3-0
  - The alternative serializer.
  - Ace3 source: https://github.com/WoWUIDev/Ace3

**26. Compact mode**
- No new API is needed. Reuse the existing frames, and follow task 6 so the frames don't break combat rules.

**27. Sound cues**
- PlaySound: https://warcraft.wiki.gg/wiki/API_PlaySound
  - Use `SOUNDKIT` IDs.
- QUEST_TURNED_IN: https://warcraft.wiki.gg/wiki/QUEST_TURNED_IN
- PLAYER_LEVEL_UP: https://warcraft.wiki.gg/wiki/PLAYER_LEVEL_UP

**28. Account-wide profile**
- Saving variables between sessions: https://warcraft.wiki.gg/wiki/Saving_variables_between_game_sessions
  - `SavedVariables` holds the account-wide defaults and `SavedVariablesPerCharacter` holds the overrides.

## Optional integrations and references

- **TomTom:** https://www.curseforge.com/wow/addons/tomtom *(403)*
  - Also on Wago: https://addons.wago.io/addons/tomtom
  - It's an optional waypoint arrow. Its public source repo couldn't be confirmed, and the `AddWaypoint` signature has changed between versions.
  - Read the signature in the installed `TomTom.lua` before calling it, and call it only if `TomTom` is loaded.
- **Questie:** https://github.com/Questie/Questie
  - GPL-3.0 (https://github.com/Questie/Questie/blob/master/LICENSE.md). Reference only.
  - Its Forever port notes are useful reading: https://github.com/Questie/Questie/blob/master/FOREVER_WORK_LEFT_TO_DO.md
  - Also on Wago: https://addons.wago.io/addons/questie

## Font (Fira Sans Condensed Medium)

- Fira Sans: https://github.com/bBoxType/FiraSans
  - Also on Google Fonts: https://fonts.google.com/specimen/Fira+Sans+Condensed
- License (SIL Open Font License 1.1): https://github.com/mozilla/Fira/blob/master/LICENSE
  - Official OFL text: https://openfontlicense.org/open-font-license-official-text/
  - The OFL allows bundling the font in the addon. Ship the license text next to the font file.
