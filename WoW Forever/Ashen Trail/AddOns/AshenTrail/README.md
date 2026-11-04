# Ashen Trail

Standalone Horde 1-60 tracker for World of Warcraft: Forever. It does not need RestedXP.

## Install

1. Copy the `AshenTrail` folder into `World of Warcraft\_forever_\Interface\AddOns\`.
2. The folder name must stay `AshenTrail`.
3. Reload (`/reload`). The window opens on your race's route, at the first step you have not finished.

`/at` toggles the window. `/at help` lists commands.

## What it tracks

- Quest givers, turn-ins, and kill spots from the Ashen Trail steps, on the map and as nameplate icons.
- Townsfolk: innkeepers, flight masters, repair, trainers, boats, and zeppelins. Nearest list is sorted for the zone you are in.
- Step completion from the quest log. Accept, complete, turn-in, and level steps advance on their own. Pure travel steps wait for Next.
- On login it reads quests you already turned in and loads the matching chapter.
- A travel plan from where you stand to the step: run, hearth, flight, boat, or zeppelin. The arrow points at the next hop in your current zone.
- A Target button that runs `/targetexact` for the step's NPC, with an icon on their nameplate.
- A gear check that scores quest rewards and bag gear against what you have equipped.
- A per-character turn-in history.

Flight masters, boats, and the hearth are suggestions. The addon cannot take a flight or hearth for you. Trainer pins outside Orgrimmar are district markers. Riverglades has a boat hop and no map pin until its dock coordinates are known. Above level 30 the route is planning guidance.

## RestedXP

The sibling folder `RXPGuides_CustomHordeForever` is an optional import of the same route. Ashen Trail runs without it.
