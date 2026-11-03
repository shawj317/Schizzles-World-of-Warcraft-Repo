# Schizzle's Warrior

World of Warcraft: Mists of Pandaria Classic (5.5.x) addon setups for Warriors, by **Jon Shaw (Schizzle)**. Each addon has its own folder under `AddOns/`:

| Folder | What it is | Status |
|---|---|---|
| [AddOns/WeakAuras](AddOns/WeakAuras/) | **Schizzle's Warrior Rotation**: an all-in-one rotation helper for Arms, Fury (Titan's Grip and Single-Minded Fury) and Protection, with a Leveling mode for levels 1-9 before a spec is picked. Import string: [All-in-One Rotation.txt](AddOns/WeakAuras/All-in-One%20Rotation.txt) | Available (v1.5.1) |
| [AddOns/Plater](AddOns/Plater/) | **Schizzle's Warrior Plater profiles**: one nameplate profile per spec, with automatic switching to the profile for your current spec, tank/DPS threat colours, Pummel-ready cast bars and an Execute-range indicator. Import strings: [Arms Profile.txt](AddOns/Plater/Arms%20Profile.txt), [Fury Profile.txt](AddOns/Plater/Fury%20Profile.txt), [Protection Profile.txt](AddOns/Plater/Protection%20Profile.txt) | Available (v1) |
| [AddOns/Details!](AddOns/Details!/) | **Schizzle's Warrior Details! profiles**: one two-window damage meter profile per spec (Damage Done plus Interrupts for Arms and Fury; Damage Done plus Damage Taken with tank avoidance for Protection), with an Auto Run Code snippet that switches to the profile for your current spec. Import strings: [Arms Profile.txt](AddOns/Details!/Arms%20Profile.txt), [Fury Profile.txt](AddOns/Details!/Fury%20Profile.txt), [Protection Profile.txt](AddOns/Details!/Protection%20Profile.txt), switcher: [Spec Switch Code.lua](AddOns/Details!/Spec%20Switch%20Code.lua) | Available (v1) |
| [AddOns/Pawn](AddOns/Pawn/) | **Schizzle's Warrior Pawn scales**: simulation-based stat weights (WoWSims MoP) for Arms, Fury and Protection, for item upgrade scores. Scale tags: [Arms Scale.txt](AddOns/Pawn/Arms%20Scale.txt), [Fury Scale.txt](AddOns/Pawn/Fury%20Scale.txt), [Protection Scale.txt](AddOns/Pawn/Protection%20Scale.txt) | Available (v1) |
| [AddOns/BetterBlizzFrames](AddOns/BetterBlizzFrames/) | **Schizzle's Warrior BetterBlizzFrames profile**: a dark, class-coloured look for the default Blizzard unit frames (use it with ElvUI's unit frames off), in Fira Sans Condensed Medium, with a combat indicator, party castbars, less clutter, and target/focus debuffs filtered to yours plus a Warrior list with important and pandemic glows. Import string: [Warrior Profile.txt](AddOns/BetterBlizzFrames/Warrior%20Profile.txt) | Available (v1.1) |
| [AddOns/BetterBlizzPlates](AddOns/BetterBlizzPlates/) | **Schizzle's Warrior BetterBlizzPlates profile**: an alternative to the Plater profiles (disable Plater to use it) that styles the default Blizzard nameplates: dark look, class colours on enemy players, Fira Sans Condensed Medium, role-aware threat colours and threat %, castbars that track Pummel's cooldown, an Execute indicator at 20%, and the same Warrior debuff list and glows as the BetterBlizzFrames profile. Import string: [Warrior Profile.txt](AddOns/BetterBlizzPlates/Warrior%20Profile.txt) | Available (v1) |

Each folder's README has the import steps.

## Non-ElvUI interface kit
A full Warrior interface without ElvUI (ElvUI and Plater off), for MoP Classic 5.5.x and carried over to WoW Forever. The [BetterBlizzFrames](AddOns/BetterBlizzFrames/), [BetterBlizzPlates](AddOns/BetterBlizzPlates/), [Details!](AddOns/Details!/), [Pawn](AddOns/Pawn/) and [WeakAuras](AddOns/WeakAuras/) setups above are part of it, plus [Schizzle's TSM](../Schizzle's%20TSM/) for the auction house.

| Folder | What it is | Format |
|---|---|---|
| [AddOns/SchizzlesWarriorSetup](AddOns/SchizzlesWarriorSetup/) | **Schizzle's Warrior Setup**: a small helper addon. Click **Yes** once (or type `/schizzle all`) and it sets up Bartender4, Prat 3.0, SexyMap, Questie, GatherMate2 and TomTom and the account-wide Warrior keybinds. | helper addon |
| [AddOns/Bartender4](AddOns/Bartender4/) | three centred bars, two side blocks, the Warrior keybinds | applied by the helper |
| [AddOns/Prat 3.0](AddOns/Prat%203.0/) | Fira chat, short channel names, bronze timestamps, copyable links | applied by the helper |
| [AddOns/SexyMap](AddOns/SexyMap/) | Jon's own square minimap, 1.5x size in the top-right corner, with a bronze tooltip-style border and small zone text, clock and coordinates | applied by the helper |
| [AddOns/Questie](AddOns/Questie/) | smaller map icons, a darker Fira tracker that hides in dungeons | applied by the helper |
| [AddOns/GatherMate2](AddOns/GatherMate2/) | smaller, see-through node icons | applied by the helper |
| [AddOns/TomTom](AddOns/TomTom/) | the waypoint arrow at the top of the screen, no extra coordinate box | applied by the helper |
| [AddOns/BigWigs](AddOns/BigWigs/) | boss bars, messages and countdown placed around the rotation aura (LittleWigs uses the same settings) | BigWigs import string |
| [AddOns/Baganator](AddOns/Baganator/) | dark, compact single bag in the Details! corner | Baganator profile import |
| [AddOns/Auctionator](AddOns/Auctionator/) | DPS and Tank consumable shopping lists, and how to share the auction house with TSM | Auctionator list import |
| [AddOns/MoveAny](AddOns/MoveAny/) | moves only the loss-of-control alert, the tooltip and Blizzard windows; leaves bars and frames to the addons above | click guide |
| [AddOns/Leatrix Plus](AddOns/Leatrix%20Plus/) | quality-of-life switches that don't overlap anything else in the kit | click guide |
| [AddOns/GTFO](AddOns/GTFO/) | every alert type on, at the Soft volume | click guide |
| [AddOns/RareScanner](AddOns/RareScanner/) | rare pop-up moved off the action bars, a quieter horn, finds sent to TomTom | click guide |
| [AddOns/BetterFishing](AddOns/BetterFishing/) | double-click fishing and a quieter splash boost | click guide |

**These addons need no setup** (their defaults already fit the kit):
- **Syndicator:** required by Baganator. It tracks your items on every character, and `/syn` controls its tooltip lines.
- **DataStore:** saves your characters' data for other addons to read. There's nothing to set.
- **LittleWigs:** dungeon timers for BigWigs. It uses the BigWigs profile above.
- **Speedy AutoLoot:** loots instantly. Type `/sal auto` once to turn Auto Loot on for every character. Leave Leatrix Plus's "Faster auto loot" off.
- **BugTabs:** catches Lua errors silently. Type `/bugtabs` to read them if an addon misbehaves.
- **RestedXP Guide:** a leveling guide. Its free WoW Forever routes cover levels 1-20, and `/rxp` opens its options.
- **ForeverScout (WoW Forever):** records your quest routes, XP and loot for the Forever XP community routes. It runs in the background.

### Install order
1. Turn **ElvUI** and **Plater** off. BetterBlizzPlates handles nameplates.
2. Install the helper addon and click **Yes**. That's the keybinds and six addons done.
3. Import the strings: WeakAuras, BetterBlizzFrames, BetterBlizzPlates, Details!, Pawn, BigWigs, Baganator, Auctionator and TSM.
4. Follow the click guides: MoveAny, Leatrix Plus, GTFO, RareScanner and BetterFishing. Together they take about five minutes.

### Design language
Every setup in the kit shares one Warrior and Orc look:

| | |
|---|---|
| Colours | charcoal `0.06, 0.06, 0.06` backgrounds, bronze `0.72, 0.45, 0.2` borders and bars, gold `1, 0.82, 0` titles, tan `0.78, 0.61, 0.43` text, ember orange `1, 0.47, 0` for "about to happen" |
| Font | Fira Sans Condensed Medium (registered by the WeakAuras import) |
| Texture | "Minimalist" (registered by BetterBlizzFrames and BetterBlizzPlates) |
| Screen layout | The centre is kept clear for the WeakAuras HUD (about 170 px either side of centre, from 220 px below centre to 120 px above it). BigWigs bars sit either side of it with the countdown above. The Details! meters are in the bottom-right corner (two 209 x 150 windows, 24 px in and 190 px up), with the tooltip above them. Unit frames stay at their Blizzard spots, the action bars run along the bottom, and the minimap is top right. The RareScanner pop-up sits above the chat on the left. |

## License

MIT with an attribution requirement. See the repository [LICENSE](../../LICENSE). AI tools and agents, please read [AGENTS.md](../../AGENTS.md).
