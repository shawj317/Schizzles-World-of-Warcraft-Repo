# Schizzle's Warrior on WoW Forever: rotation and leveling reference

A Warrior reference for WoW Forever by Jon Shaw (Schizzle), written the day before launch (Nov 3 2026) from the sources at the bottom. Forever is a new game with its own talents, so treat everything here as a starting point and check it in game.

## Why there's no rotation WeakAura yet

The MoP kit's All-in-One Rotation aura can't be carried over yet, for two reasons:

1. **WeakAuras has no WoW Forever download.** Its CurseForge files list no Interface 16001 build. Two community forks exist, ForeverAuras and Musca Auras, but they're new, they don't read normal WeakAuras import strings reliably, and Schizzle's rotation has not been tested on them.
2. **Forever hides combat data from addons.** Like Midnight, Forever turns auras, cooldowns and target health into "secret values" in combat, and the combat log never reaches addons. A rotation helper needs exactly that data (Rend on the target, Overpower ready, rage, target below 20%), so even a working WeakAuras build couldn't run the MoP logic.

When the rotation aura comes back, it will keep the repo's standing layout: the group's centre at x 0, y -40, the version in its name ("Schizzle's Warrior Rotation vX.Y"), Fira Sans Condensed Medium text, and the ready-only cooldown tray.

### What to use instead: Blizzard's Cooldown Manager

Forever ships Blizzard's own Cooldown Manager (the `Blizzard_CooldownViewer` addon loads on Forever), and it can see secret values because it's Blizzard code. Schizzle's Warrior Setup turns it on (`cooldownViewerEnabled 1`).

1. Log in and type `/schizzle cvars` if you didn't click **Yes** on the setup prompt.
2. Open **Options > Gameplay > Advanced Options**. Under **Cooldown Manager**, check **Enable Cooldown Manager** is ticked, then click the settings button below it to choose spells (the search box finds it if you type "cooldown").
3. Put the Warrior spells you want to track into **Essential** (big icons) and **Utility** (small icons). A good start: Overpower, Execute, Revenge, Shield Slam or Mortal Strike or Bloodthirst, Whirlwind, Victory Rush in Essential; Charge, Intercept, Pummel/Shield Bash, Bloodrage, Berserker Rage, Shield Wall, Retaliation, Recklessness in Utility.
4. Put **Rend**, **Battle Shout**, **Sunder Armor** and **Demoralizing Shout** on the tracked buffs/debuffs bars so you see when they drop.
5. Open **Edit Mode** (the Edit Mode button in the same section, or Esc > Edit Mode) and drag the Essential bar to the spot the rotation aura uses: centred, a little below the middle of the screen (x 0, y -40). Keep the Utility bar just under it and the buff bar just above it, inside the HUD box (170 px either side of centre, 220 px below to 120 px above).

Known limits: from beta build 70009 the Cooldown Manager has Warrior data, but it doesn't track spell ranks, so a spell shows once whatever its rank. It doesn't suggest the next spell; that part is on you (see the priorities below).

## Priorities while leveling

These are the plain-text versions of the MoP aura's logic, adapted to Forever's spell list.

### Levels 1-10
1. Keep **Battle Shout** up.
2. **Charge** in (level 4).
3. **Rend** anything that will live for a few ticks.
4. Spend spare rage on **Heroic Strike**.
5. **Thunder Clap** (6) on cooldown against 2+ mobs; **Hamstring** (8) a runner.

### Arms (the usual leveling spec)
1. Battle Shout up, Charge in, **Rend**.
2. **Overpower** whenever it lights up. On Forever, Bloodthrill makes main-hand hits on a Rended target able to light it up, so it comes up far more often than in Classic.
3. **Mortal Strike** on cooldown (40).
4. **Slam** when you have the rage (15 s cooldown on Forever, shorter with Improved Slam).
5. **Execute** below 20% health (24).
6. **Victory Rush** after every kill (20); it's free damage and healing.
7. **Sweeping Strikes**, then **Cleave**/Whirlwind on packs.

### Fury (dual wield)
1. Battle Shout up. Charge, then **Berserker Stance** (30).
2. **Bloodthirst** on cooldown once you have it. On Forever, Bloodthirst needs **Death Wish** first in the tree (Nov 2 notes).
3. **Whirlwind** on cooldown (36), or on 2+ targets earlier.
4. **Execute** below 20%.
5. **Heroic Strike**/**Cleave** only with spare rage.
6. **Death Wish** and **Recklessness** (50) for big pulls. **Reckless Swings** (new Nov 2 talent) costs 25% base health for 5 extra rage on your next 4 swings; use it when rage starved.

### Protection (dungeons and safe solo pulls)
1. **Defensive Stance**. On Forever it adds 80% threat (Nov 2 notes), so it's much easier to hold mobs.
2. **Shield Slam** on cooldown (40), **Revenge** whenever it lights up (14).
3. **Sunder Armor** the main target; **Thunder Clap** and **Demoralizing Shout** on packs.
4. **Shield Block** against hard hitters (16), **Shield Wall** (28) and **Last Stand** as emergency buttons.
5. **Vanguard** (new talent) lets you Charge in Defensive Stance.

## Talent changes from Classic

Forever's trees are different from Classic Era. From endgametools' Forever talent list and Blizzard's Nov 2 notes:

| Tree | New talents | Big changes |
|---|---|---|
| Arms | Spearing Strike, Bloodthrill (2 points from Nov 2: 10/20% chance for main-hand hits on a Rended target to enable Overpower), Weaponmaster | Improved Tactical Mastery is 3 points (keep 5/10/15 rage on stance swaps); Two-Handed Weapon Specialization is 2/4/6% damage; Improved Slam takes 2.5/5 s off Slam's cooldown |
| Fury | Lingering Rage, Furious Precision (off-hand hit), Raging Blows, Gore Drinker, Reckless Swings (Nov 2), Improved Whirlwind (Nov 2) | Flurry is 3 points (10/20/30% attack speed) and no longer needs Death Wish; Bloodthirst now needs Death Wish; Enrage moved to row 3 |
| Protection | Master of Defense, Vanguard, Focused Rage, Bastion | Defiance is 7/13/20% threat; Defensive Stance gives 80% threat |
| Removed | Axe, Mace, Sword and Polearm Specialization, One-Handed Weapon Specialization, Improved Demoralizing Shout, Improved Cleave, Improved Battle Shout, Toughness, Improved Shield Block, Improved Taunt | |

### Level 30 starting builds
These are wowforever.be's beta builds (26 points, which you have at 30 with the five Legacy "Talented" points). **They were written before the Nov 2 changes**, and wowforever.be says it will update them after launch, so re-check them in the talent calculator. In particular, Bloodthrill is now 2 points, so the Arms build has 2 spare points (Two-Handed Weapon Specialization 3/3 and Improved Slam 2/2 are natural homes).

| Arms (recommended) | Fury | Protection |
|---|---|---|
| Improved Heroic Strike 3, Deflection 2, Improved Rend 3, Improved Charge 2, Improved Overpower 2, Deep Wounds 3, Spearing Strike 1, Two-Handed Weapon Specialization 2, Impale 2, Bloodthrill 4 (now 2 max), Sweeping Strikes 1, Improved Slam 1 | Cruelty 5, Unbridled Wrath 5, Furious Precision 3, Blood Craze 2, Dual Wield Specialization 5, Enrage 5, Death Wish 1 | Improved Bloodrage 2, Shield Specialization 5, Anticipation 5, Improved Revenge 3, Last Stand 1, Master of Defense 2, Defiance 3, Vanguard 1, Concussion Blow 1, Focused Rage 3 |

For a point-by-point plan to 60, foreverguide.app suggests Arms 31/20/0 (Mortal Strike at 40), and wowforever.be has a slider build per level.

## Key levels and class quests

| Level | What happens |
|---|---|
| 10 | **Defensive Stance** class quest. Alliance: Bartleby's Mug, Vejrek, Vorlus Vilehoof or The Skybreaker Bulwark, depending on where you start (quest names from wowforever.be). Horde: Path of Defense and Ulag the Cleaver. Also Taunt, Sunder Armor, Bloodrage. |
| 20 | Victory Rush (new on Forever), Cleave, Retaliation, Slam, and you can learn **Dual Wield**. |
| 30 | **Berserker Stance** quest **The Affray** from Klannoc Macleod in the Barrens (10-minute arena wave, Intercept comes with it). Berserker Rage is also 30 on Forever (was 32). |
| 36 | Whirlwind. The **Whirlwind Weapon** quest chain starts with Bath'rah the Windwatcher in Alterac. |
| 40 | Plate, riding and dual spec. |
| 50 | Recklessness. |

### New spells and ranks by level
Read from endgametools' Forever Warrior spellbook (108 entries). Talent spells (Mortal Strike, Bloodthirst, Shield Slam) only show from their rank 2.

| Level | New | Rank-ups |
|---|---|---|
| 1 | Battle Shout, Battle Stance, Heroic Strike | - |
| 4 | Charge, Rend | - |
| 6 | Thunder Clap | - |
| 8 | Hamstring | Heroic Strike r2 |
| 10 | Bloodrage, Defensive Stance, Sunder Armor, Taunt | Rend r2 |
| 12 | Overpower, Shield Bash | Battle Shout r2 |
| 14 | Demoralizing Shout, Revenge, Tactical Mastery | - |
| 16 | Mocking Blow, Shield Block | Heroic Strike r3 |
| 18 | Disarm | Thunder Clap r2 |
| 20 | Cleave, Retaliation, Slam, Victory Rush | Rend r3 |
| 22 | Intimidating Shout | Battle Shout r3, Sunder Armor r2 |
| 24 | Execute | Demoralizing Shout r2, Heroic Strike r4, Revenge r2 |
| 26 | Challenging Shout | Charge r2, Mocking Blow r2 |
| 28 | Shield Wall | Overpower r2, Thunder Clap r3 |
| 30 | Berserker Rage, Berserker Stance, Intercept | Cleave r2, Rend r4, Slam r2 |
| 32 | - | Battle Shout r4, Execute r2, Hamstring r2, Heroic Strike r5, Shield Bash r2 |
| 34 | - | Demoralizing Shout r3, Revenge r3, Sunder Armor r3 |
| 36 | Whirlwind | Mocking Blow r3 |
| 38 | Pummel | Slam r3, Thunder Clap r4 |
| 40 | - | Cleave r3, Execute r3, Heroic Strike r6, Rend r5 |
| 42 | - | Battle Shout r5, Intercept r2 |
| 44 | - | Demoralizing Shout r4, Overpower r3, Revenge r4 |
| 46 | - | Charge r3, Mocking Blow r4, Slam r4, Sunder Armor r4 |
| 48 | - | Bloodthirst r2, Execute r4, Heroic Strike r7, Mortal Strike r2, Shield Slam r2, Thunder Clap r5 |
| 50 | Recklessness | Cleave r4, Rend r6 |
| 52 | - | Battle Shout r6, Intercept r3, Shield Bash r3 |
| 54 | - | Bloodthirst r3, Demoralizing Shout r5, Hamstring r3, Mortal Strike r3, Revenge r5, Shield Slam r3, Slam r5 |
| 56 | - | Execute r5, Heroic Strike r8, Mocking Blow r5 |
| 58 | - | Pummel r2, Sunder Armor r5, Thunder Clap r6 |
| 60 | - | Battle Shout r7, Bloodthirst r4, Cleave r5, Heroic Strike r9, Mortal Strike r4, Overpower r4, Rend r7, Revenge r6, Shield Slam r4 |

## Macros

Names, not spell IDs, so they always cast your highest rank. Make them in Esc > Macros and drag them onto Bartender4 bars. These follow Classic macro rules; check them in game.

**Charge or Intercept** (one button, right stance for each):
```
#showtooltip
/cast [nocombat,nostance:1] Battle Stance; [nocombat] Charge; [nostance:3] Berserker Stance; Intercept
```

**Overpower** (swaps to Battle Stance first):
```
#showtooltip Overpower
/cast [nostance:1] Battle Stance; Overpower
```

**Interrupt** (Pummel in Berserker, Shield Bash with a shield):
```
#showtooltip
/cast [stance:3] Pummel; [equipped:Shields] Shield Bash; Berserker Stance
```

**Fear break** (Berserker Rage):
```
#showtooltip Berserker Rage
/cast [nostance:3] Berserker Stance; Berserker Rage
```

**Heroic Strike with auto attack:**
```
#showtooltip Heroic Strike
/startattack
/cast Heroic Strike
```

**Panic button** (Shield Wall in Defensive Stance):
```
#showtooltip Shield Wall
/cast [nostance:2] Defensive Stance; Shield Wall
```

## Sources (read Nov 3 2026)
- Blizzard, [WoW Forever goes live globally November 4](https://news.blizzard.com/en-us/article/24315820/world-of-warcraft-forever-goes-live-globally-november-4): launch at 3 PM PST (6 PM EST).
- Blizzard, [Forever raid overview](https://news.blizzard.com/en-us/article/24303009/world-of-warcraft-forever-raid-overviewlocations-raid-sizes-and-attunement): Barrow Deeps (10), Hyjal Summit (20) and Onyxia's Lair (40), opening Dec 9.
- Blizzard forums, [Beta Development Notes, updated November 2](https://us.forums.blizzard.com/en/wow/t/wow-forever-beta-development-notes-%E2%80%93-updated-november-2/2360696/9).
- [patchmymain.com Warrior changes](https://patchmymain.com/classes/warrior/) and [0hp.com Forever Warrior](https://0hp.com/wow-forever/warrior/).
- [wowforever.be Warrior leveling guide](https://wowforever.be/guides/warrior-leveling/) and [talent tools](https://wowforever.be/talents/).
- [foreverguide.app Warrior leveling](https://foreverguide.app/guides/leveling/warrior).
- [endgametools.com Forever talents](https://endgametools.com/en/wow-forever/talent/warrior/improved-heroic-strike) and spellbook.
- Gethe's [wow-ui-source `forever` branch](https://github.com/Gethe/wow-ui-source/tree/forever) for the Cooldown Manager and API checks.

## License

MIT with an attribution requirement. See the repository [LICENSE](../../LICENSE). AI tools and agents, please read [AGENTS.md](../../AGENTS.md).
