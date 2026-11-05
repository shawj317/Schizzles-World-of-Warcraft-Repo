# Schizzle's Warrior Essentials (Musca Auras, WoW Forever)

A Musca Auras pack for a Warrior on WoW Forever, made by Jon Shaw (Schizzle). It shows what's ready, what's missing and what to press next: proc alerts with a glow and a sound, a numbered priority lane for each talent tree, a rage bar that changes colour, your buffs, your debuffs on the target, cooldowns for your current stance, and swing timers.

> **It's a visual helper, not a rotation bot.** Nothing in the pack presses a key or casts a spell. It reads what the game lets addons read and lights things up; you still pick and press every spell.

| File | Imports as | Needs |
|---|---|---|
| [Schizzle's Warrior Essentials.txt](Schizzle's%20Warrior%20Essentials.txt) | one group: `Schizzle's Warrior Essentials v1.18` | Musca Auras 1.14.0 |

Musca Auras is a WeakAuras fork for Forever that understands Forever's "secret values" (auras, cooldowns and power hidden from addons in combat). Get it from its [GitHub releases](https://github.com/dldvlpr-addons-wow/Musca-Auras/releases) (1.14.0, Interface 16001). Normal WeakAuras doesn't load on Forever. ForeverAuras is a different fork and can't import this pack.

## Install
1. Install Musca Auras 1.14.0. The addon folder is still called `WeakAuras`, so turn off any other WeakAuras copy first.
2. Log in on your Warrior and type `/schizzle auras` (needs Schizzle's Warrior Setup F2.10 or later). The import window opens with the pack already in it. Click **Import**.
   Or open the file, copy all of it, type `/wa`, click **Import** and paste it in.
3. Type `/reload`.
4. The pack and Blizzard's Cooldown Manager both use the middle of the screen. Type `/schizzle cdm` to turn the Cooldown Manager off, or keep it for buffs only and drag its bars out of the HUD box (see the [Warrior Guide](../../Warrior%20Guide.md#the-cooldown-manager-alongside-the-pack)).

Importing again updates the auras you already have (each aura's ID stays the same between versions). Your own changes to them are overwritten.

## What's on screen
Everything sits in the HUD box around the middle of the screen. The group's centre is 55 px below the screen's centre. The rows below are listed top to bottom, with their place measured from the screen's centre (+ is up).

| Row | Where (y) | Shows |
|---|---|---|
| Not in melee range | +90 to +110 | red text while you're in combat with a target that Sunder Armor can't reach |
| Reminders | +72 and up | gold text out of combat: **Missing Battle Shout** |
| Procs | +41 to +63 | Overpower, Revenge, Execute, Victory Rush (glow and sound) |
| Your buffs | +15 to +37 | buffs while they're up; Battle Shout shows remaining time; the last 3 seconds blink red. At most 10 icons |
| Target and stance | -11 to +11 | your debuffs on the target with time left, then your stance |
| Rage bar | -20 and below | rage, 100 px wide, coloured by how much you have |
| Priority lane | from -38 | what to press, in order, numbered 1 to 8; while Heroic Strike or Cleave is queued, every icon here gets Battle Shout's Pixel glow and a main-hand swing swirl (does not replace the spell's own cooldown swipe) |
| Cooldowns | below the lane | major cooldowns, interrupts, taunts, trinkets and your racial; each only in the stance that can use it |
| Swing timers | bottom, above -220 | main hand and off hand |

`verify.lua` works out the worst case for every row (all of a row's icons up at once) and checks it stays inside the box: x within 170 px of the centre, y from 235 px below to 120 px above.

## Per spec
The lane loads from the talent tree with the most points spent, from level 10. Below level 10 the Starter lane shows. If two trees have the same number of points, both lanes show. A lane icon dims while the spell can't be used yet (not enough rage, on cooldown, wrong stance or no proc), turns red while the target is out of range and blue while you're short of rage. Out of combat with no target the whole lane fades.

| Lane | Order | Notes |
|---|---|---|
| Starter (below 10) | Rend, Heroic Strike, Thunder Clap | Thunder Clap in Battle Stance |
| Arms | Rend, Heroic Strike, Thunder Clap, Overpower, Mortal Strike, Slam, Execute, Victory Rush, Sweeping Strikes, Whirlwind | HS/TC kept after first talent point; Overpower and Sweeping Strikes in Battle Stance, Whirlwind in Berserker |
| Fury | Bloodthirst, Heroic Strike, Thunder Clap, Whirlwind, Execute, Victory Rush, Slam, Rend | HS/TC early; Whirlwind in Berserker; Rend in Battle or Defensive |
| Protection | Shield Slam, Revenge, Sunder Armor, Heroic Strike, Shield Block, Demoralizing Shout, Thunder Clap, Victory Rush | HS early; Revenge and Shield Block in Defensive, Thunder Clap in Battle |

Sunder Armor, Demoralizing Shout and Thunder Clap in a lane track the target debuff. Main Rend always shows; it greys while Setup reports your Rend landed on the current target (rank duration; Forever cannot read target debuffs or CLEU in combat).

## Rage colours
| Rage | Colour | Meaning |
|---|---|---|
| under 15 | grey | nothing worth pressing |
| 15 to 29 | red (Musca's rage colour) | enough for your main spell |
| 30 to 59 | bronze | room for Heroic Strike or Cleave on top |
| 60 and up | ember | dump it before it's wasted |

The grey mark is a condition on the bar. The bronze and ember steps are copies of the bar laid over it, which the game shows only above their percent. Forever reads power through a curve in combat, and Musca can only apply one such condition per property, so stacked colour conditions would stop at the first one in combat.

## What the alerts mean
| Alert | Sound | What to do |
|---|---|---|
| Overpower lights up | water drop | the target dodged: Overpower now (Battle Stance) |
| Revenge lights up | water drop | you blocked, dodged or parried: Revenge now (Defensive Stance) |
| Execute lights up | robot blip | target under 20%: Execute is your top button |
| Victory Rush lights up | water drop | you got a killing blow: free heal and damage |
| Priority icons glow + swing swirl | none | Heroic Strike or Cleave is queued on your next swing; press it again to cancel if you need the rage |
| A lane icon glows | none | that debuff is missing from the target |
| Main Rend is grey | none | you recently landed Rend on the current target (self-timer) |
| A buff blinks red | none | it runs out in 3 seconds |
| Missing Battle Shout | none | out of combat: shout before the pull |
| Not in melee range | none | in combat: close the gap (Charge, Intercept) |

## Spell IDs
Every spell ID was checked against Forever's game data (build 1.60.1.70755, from wago.tools DB2 exports): 81 IDs, all present, and every aura ID applies an aura. `verify.lua` repeats the check when the exports are given.

A few couldn't be confirmed beyond the game data and will be checked in game at launch:
- **Enrage 12880**: Forever has only this one rank (the original game also had 14201 to 14204). Flurry 12966, Blood Craze 16488 and the Last Stand buff 12976 are single IDs as well.
- **Sweeping Strikes 12292**: the cast and the buff share an ID.
- **Victory Rush 402927** (cast) and Victorious 402975 (the buff): the alert relies on the spell turning usable, not on the buff.
- **Deep Wounds** isn't tracked: 12162 applies no aura in Forever's data.
- **Reckless Swings** isn't in Forever's game data, so it's left out.
- **Berserking 20554**: Musca's own pack uses 26297, which Forever doesn't have.
- Reading Sunder Armor, Thunder Clap and Demoralizing Shout on the target in combat hasn't been seen in game yet.

## Known limits
- Musca Auras is young. If something stops showing after an update, reimport the pack first.
- No combat log reaches addons on Forever, so the pack can't count damage, track Deep Wounds or predict procs. It reacts to what the game shows.
- The lane is a fixed order, not a live suggestion. When two icons are lit, the lower number comes first.
- With no talent points spent the lane follows the tree whose signature spell you know (Mortal Strike, Bloodthirst or Shield Slam). Before that, from level 10 to your first talent, no lane shows.
- It doesn't replace knowing your spells. The [Warrior Guide](../../Warrior%20Guide.md) covers priorities per spec.

## Source files (`source/`)
| File | Does |
|---|---|
| `pack.lua` | the pack: lanes, procs, buffs, debuffs, cooldowns, rage colours, layout |
| `PackBuilder.lua` | turns `pack.lua` into Musca auras. A modified copy of Musca's own pack builder (GPL-2.0, see below) |
| `build.lua` | `MUSCA=<Musca Auras 1.14.0 folder> lua build.lua` writes the import string with Musca's own LibSerialize and LibDeflate, compiles every custom-code string with the same `LoadFunction` wraps Musca uses (fails the build on errors), scans custom code for Musca's Forever `removedFunctions`, triage remaining Power/Health trigger warnings, and checks it decodes back; `--check` fails if the file is out of date |
| `scenario.lua` | a scenario for Musca's own test harness (`Tests/run.lua`): Musca's pack checks (every aura loads, triggers compile, secret auras pass Musca's validator, anchors resolve, combat runs clean), then the right lane for each tree and level, then the rage colours at 5 to 100 rage in and out of combat |
| `verify.lua` | runs all of it: `MUSCA=... WOW_UI_SOURCE=<Forever UI source> DB2=<DB2 CSV folder> LUACHECK=<luacheck> PRIVATE_WORDS=... lua verify.lua`. Also checks the HUD box, the font and the version in the group name. Any part without its variable is skipped |

## Checks
Last run (Nov 3, 2026) on Musca Auras 1.14.0 with the Forever UI source for build 1.60.1.70755: all checks pass.

## Version history
| Version | Changes |
|---|---|
| 1.18 | Utility tray keybinds INNER_TOPLEFT (match Main); was OUTER sitting in gap above icons |
| 1.17 | Level-10 Arms keeps HS/TC; rage bar default Y 20; Utility tray keybinds OUTER_TOPLEFT + baked names |
| 1.16 | All BT4 bars + castable Essentials keybind labels; Main Rend rank duration + miss-safe land via Setup (CLEU closed on Forever) |
| 1.15 | Main hotkeys via Setup SchizzlesWarriorSetup_Keys (Bartender4 BT4Button primary) |
| 1.14 | Main hotkeys: Bartender4 CLICK BT4ButtonN:Keybind/LeftButton + skip-secret scan; Blizzard/BT4 harness |
| 1.13 | Reminders: Find Minerals (spell 2580) icon + "Track Minerals" via Musca Tracking inverse; OOC/alive/capitals |
| 1.12 | Forever compat: customText uses C_Spell.GetSpellName/GetSpellInfo; Main Rend always shows (CD primary) and greys via Spell Cast Succeeded self-timer (target aura2 cannot see debuffs in combat); Musca scanner in build gate |
| 1.11 | Unload the whole pack in the six classic capitals (Stormwind, Ironforge, Darnassus, Orgrimmar, Thunder Bluff, Undercity) via negated zone + uiMapIDs; keep v1.10 init fix and v1.9 Rend/queue behaviour
| 1.10 | Fix Main icons: actions.init.custom is a body (Musca wraps function()); build compiles every custom-code string as Musca LoadFunction does
| 1.9 | Main Rend: aura2 primary (no Cooldown Progress) so Forever no longer greys it always; desaturate only while own Rend is up. HS/Cleave queue Pixel only on the queued ability's own icon
| 1.8 | Main Rend: saturated when Rend is missing from the target, desaturated when your Rend is on it (aura2 by name); removed rage desat / usable glow / queue border / timer / <4s flash
| 1.7 | Main Rend: rage desat / usable highlight / Pixel queue border / present timer; removed Target Rend duplicate
| 1.6 | Main Rend: desaturate while up, Action Button highlight when usable (IsSpellUsable power flag), Autocast Shine while queued
| 1.5 | Main corner labels = real keybinds (GetActionInfo/GetBindingKey); Rend Proc-blink flash when remaining < 4s (secret-safe)
| 1.4 | queued HS/Cleave: Pixel glow + MH swing swirl on Main priority icons; Procs back to v1.0 set (no standalone HS/Cleave) |
| 1.3 | remove Next Swing row; Heroic Strike/Cleave in Procs with Battle Shout Pixel glow + main-hand swing radial; Battle Shout remaining-time text; keep group 0,-55 and 100 px rage |
| 1.2 | group default 0,-55; rage bar 100 px wide |
| 1.1 | glow + NEXT SWING on queued Heroic Strike / Cleave |
| 1.0 | first release: proc alerts with sounds, priority lanes for Starter, Arms, Fury and Protection, rage colours, buffs, target debuffs, stance cooldowns, swing timers, Battle Shout and range reminders |

## License
The pack is built by `PackBuilder.lua`, a modified copy of Tests/Packs/PackBuilder.lua from [Musca Auras](https://github.com/dldvlpr-addons-wow/Musca-Auras) v1.14.0 by dldvlpr and the WeakAuras Team. Musca Auras is licensed under the GNU General Public License v2, so `PackBuilder.lua` and the import string it makes are under GPL-2.0 too: see [LICENSE-GPL-2.0.txt](LICENSE-GPL-2.0.txt). The rest of this folder (`pack.lua`, `build.lua`, `scenario.lua`, `verify.lua`, this README) is MIT with an attribution requirement, like the rest of the repository: see the repository [LICENSE](../../../../LICENSE). AI tools and agents, please read [AGENTS.md](../../../../AGENTS.md).
