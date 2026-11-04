# WoW Forever launch-day checklist

Jon Shaw (Schizzle)'s launch-day plan for the Schizzle's Warrior kit. WoW Forever goes live on **Wednesday Nov 4 2026 at 3 PM PST (6 PM EST)**, after maintenance from about 10 AM to 3 PM PST (1 PM to 6 PM EST). Raids (Barrow Deeps, Hyjal Summit, Onyxia's Lair) open on **Dec 9**.

The same steps are in the [launch-day manual (PDF)](Manual/).

## Before the servers open
- [ ] Update the Battle.net app and let it patch WoW Forever.
- [ ] Copy the Forever-ready addons into `World of Warcraft\_forever_\Interface\AddOns\` (see [Addon Compatibility](Addon%20Compatibility.md)). Keep a copy of the folder first.
- [ ] Copy `Schizzle's Warrior/AddOns/SchizzlesWarriorSetup/SchizzlesWarriorSetup` into the same folder.
- [ ] Optional: make the private `SchizzlesWarriorSetup_Local` addon with your Warrior's name ([how](Schizzle's%20Warrior/AddOns/SchizzlesWarriorSetup/#your-own-copy-local-settings)).
- [ ] Leave **TradeSkillMaster**, **WeakAuras** and **WagoAppCompanion** off on Forever; they have no Forever build.

## First login
- [ ] At the character screen, click **AddOns** and check nothing important says "Out of date". Don't tick "Load out of date AddOns".
- [ ] Log in. Click **Yes** on "Set up Schizzle's Warrior on this character?", then **Reload**.
- [ ] Check the chat lines: every piece should say "done", or "skipped" if that addon isn't installed.
- [ ] Look at the bottom-right corner: the XP bar should be there under the Details! meters.
- [ ] Open **Options > Gameplay > Advanced Options** and set up the **Cooldown Manager** ([Warrior Guide](Schizzle's%20Warrior/Warrior%20Guide.md#what-to-use-instead-blizzards-cooldown-manager)).
- [ ] Import the click-guide and import-string setups that work on Forever: BetterBlizzFrames, Baganator and BigWigs strings and the MoveAny, Leatrix Plus, GTFO, RareScanner and BetterFishing guides from the [MoP Warrior kit](../WoW%20Classic%20-%20Mists%20of%20Pandaria/Schizzle's%20Warrior/#non-elvui-interface-kit). Skip the MoP Pawn scales: they weigh MoP stats like haste and mastery.
- [ ] Import the [Auctionator leveling list](Schizzle's%20Warrior/AddOns/Auctionator/).
- [ ] Type `/sal auto` once (Speedy AutoLoot).

## In-game test list
Write down anything that fails, with the BugSack message, so it can be fixed:
- [ ] `/schizzle` lists every command, and no addon says "(not loaded)" that you installed.
- [ ] `/schizzle cvars` sets the seven console variables with none "skipped". Abilities fire on key down, camera zooms further out.
- [ ] `/schizzle details` imports the meter profile; two windows side by side in the bottom-right corner.
- [ ] XP & Rep Tray: the XP bar shows level and rested %; tick **Show as Experience Bar** on a faction and the second bar appears; hover each bar for its tooltip; complete a quest and the green "quest XP" part grows. In a guild with guild reputation, the third bar shows.
- [ ] `/schizzle tray` hides and shows the tray.
- [ ] Text in the tray, Bartender4 hotkeys and Prat chat uses Fira Sans Condensed.
- [ ] Keybinds: Q, E, R, F, T, G, Y and the mouse buttons fire Bar 3; Shift versions fire Bar 2; A and D strafe.
- [ ] Bar 1 swaps pages with stances once you have Defensive Stance at level 10 (drag abilities onto each page).
- [ ] BugSack's minimap icon stays green during a fight, a quest turn-in and a level-up.
- [ ] The Cooldown Manager shows your tracked spells in combat.

## Leveling plan
- **1-10:** Battle Shout, Charge, Rend, Heroic Strike. Train every even level.
- **10:** Defensive Stance quest. Learn **First Aid** (bandages are the Warrior's healing) and pick two gathering professions, or Mining + Blacksmithing for sharpening stones.
- **20:** Victory Rush after every kill. Dual Wield if you're going Fury.
- **25:** the **Legacy** panel unlocks. Its "Talented" node gives talent points from level 5 instead of 10 and is shared by every character on the account, so it's a good first pick.
- **30:** The Affray (Klannoc Macleod, The Barrens) for Berserker Stance and Intercept; Berserker Rage is also at 30 on Forever.
- **40:** plate, riding, dual spec, Mortal Strike for Arms.
- RXPGuides' free Forever routes cover 1-20; `/rxp` opens them. Questie shows quests on the map.

## Gold in the first week
- Sell leveling materials (Linen and Wool Cloth, Copper Ore, Peacebloom, Light Leather) and bags: everyone needs them at once.
- Post for 2 or 8 hours while prices move, and rescan with Auctionator before posting.
- Forever's auction house allows copper prices; undercut by 1 copper.
- See [Schizzle's TSM for Forever](Schizzle's%20TSM/) for the price rules to use once TSM updates.

## License
MIT with an attribution requirement. See the repository [LICENSE](../LICENSE). AI tools and agents, please read [AGENTS.md](../AGENTS.md).
