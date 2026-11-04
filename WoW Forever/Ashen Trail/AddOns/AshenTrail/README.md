# Ashen Trail

Original Horde 1-60 tracker for World of Warcraft: Forever. Its Lua does not load or call RestedXP.

## Install

1. Copy the `AshenTrail` folder into `Interface\AddOns\` on World of Warcraft: Forever. The TOC interface is 16001.
2. The folder name must stay `AshenTrail`.
3. Reload (`/reload`). The window opens on your race's route, at the first step you have not finished.

`/at` toggles the window. `/at help` lists commands.

## What it tracks

- Quest givers, turn-ins, and kill spots from the Ashen Trail steps, on the map and as nameplate icons.
- Townsfolk: innkeepers, flight masters, repair, trainers, boats, and zeppelins. Nearest list is sorted for the zone you are in.
- Step completion from the quest log. Accept, complete, turn-in, and level steps advance on their own. Pure travel steps wait for Next.
- On login it reads quests you already turned in and loads the matching chapter.
- A travel plan from where you stand to the step: run, hearth, flight, boat, or zeppelin. The arrow points at the next hop in your current zone.
- Step lines name the action: Talk to Lar Prowltusk. Accept: Thwarting Kolkar Aggression. Set Hearth to Razor Hill. The active step sends its coordinates to the arrow. Click a step to skip it, and click it again to mark it not complete. Right-click the window for chapters, reload, and options. Options open in their own window.
- Each dungeon quest giver is a separate step so the arrow points at that NPC. A giver with no published spot is described and not pinned.
- A Target button that runs `/targetexact` for the step's NPC, with an icon on their nameplate.
- A gear check that scores quest rewards and bag gear against what you have equipped. Empty slots score as zero.
- A quest-item button for the active step, on its own frame, updated out of combat.
- Minimap and world-map pins for the giver and turn-in on the current step and the next one.
- A route page with saved flight times and an estimated fastest-route time. The addon still cannot take the flight.
- A dungeon panel for the nine Forever instances: level, entrance, quests, and prep. Right-click the window and choose Dungeons.
- A talent line for the next point of the Talents Forever opener, shown out of combat. The line credits Talents Forever and questing.wiki. Rogue starts with Efficient Strikes, then Malice.
- The window uses Fira Sans Condensed Medium when that file loads, and the game font when it does not.
- A per-character turn-in history.
- Options grouped into theme, guide, quests, bags, arrow, and window. Themes: Blizzard, Dark, Vibrant, class color, and Ashen.
- Chapters advance automatically. Set them to Manual to stay on the chapter you picked.
- Junk can be marked, sold, or dropped when bags are full. A whitelist keeps named items.
- A flight timer and a drowning warning. Font size, colors, arrow size, and the update interval are adjustable.
- Skip, when a step will not finish. `/at skip` does the same thing. `/at unskip` clears the step you are on.

Flight masters, boats, and the hearth are suggestions. The addon cannot take a flight or hearth for you. Riding steps point at the published riding trainer for Orc, Troll, Tauren, and Undead. Above level 30 the route is planning guidance.

## Fallback pack

`RXPGuides_CustomHordeForever` is a saved RestedXP copy of this route. Keep it if the standalone addon misbehaves. Ashen Trail does not load that folder.
