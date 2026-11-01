# Schizzle's Warrior Rotation

An all-in-one WeakAuras rotation helper for Warriors in MoP Classic 5.5.x: **Arms, Fury and Protection in one import**.

> **Heads-up:** this aura is built for Mists of Pandaria Classic (5.5.x). It will be revised for WoW Forever after that launches.

**File:** [`All-in-One Rotation.txt`](All-in-One%20Rotation.txt) (28,756 chars, starts `!WA:2!`). Current version: **v1.3** (engine `VERSION = 3`).
**Built for:** WeakAuras 5.22.1, Mists build (interface 50504, internalVersion 90). Font: **Fira Sans Condensed Medium** (it ships with WeakAuras).
**Switches automatically:** the aura reads your specialization (`GetSpecialization`) and swaps the priority list, trackers and bars when you change spec. You don't need separate imports for tanking in dungeons, DPS in raids and the other DPS spec in PvP. Before level 10 (no specialization yet) it runs a **Leveling** mode instead, and it switches to the spec priority as soon as a spec is picked, with no `/reload`.
**Talents handled:** every spell is gated by `IsPlayerSpell`, so only the talent you actually took shows up. That covers tier 4 (Bladestorm, Shockwave or Dragon Roar) and tier 6 (Avatar, Bloodbath or Storm Bolt), plus Impending Victory, Enraged Regeneration and Disrupting Shout.
**Verified offline:** the export string decodes the same way WeakAuras' importer does. All custom code compiles inside WeakAuras' own aura sandbox with 0 warnings, and a mock-API rotation simulator passes 278 checks across all three specs, the no-spec Leveling mode (levels 1, 3, 5, 7 and 9), freshly specced level 10 characters, the auto attack logic, the swing timer, the GCD swipe and the cast feedback. **It has not been tested in the game client yet.** See "Known limits" below.

## Install (step by step)

1. Install **WeakAuras** for MoP Classic (CurseForge app or Wago app) and log in on your Warrior.
2. Open `All-in-One Rotation.txt` on GitHub, then click the **Copy raw file** button (two overlapping squares, top right of the file). This copies the whole string.
3. In game, type `/wa` and click **Import** (top left of the WeakAuras window).
4. Paste with **Ctrl+V** (Cmd+V on Mac), then click **Import**.
5. WeakAuras shows a summary of the "Schizzle's Warrior Rotation" group. Click **Import** again to accept it.
6. Type `/reload`.
7. Target a training dummy. The HUD appears under the middle of your screen (190 px below centre).
8. To move it, open `/wa`, click the group name and drag, or set the X/Y offset on the group's **Display** tab.
9. Options live on **Schizzle's Warrior Rotation → SWR Next → Custom Options** (see "Options" below).

Renamed group: the first upload was called "Schizzle's Warrior Rotation WeakAura". The group's internal ID hasn't changed, so WeakAuras should offer to update it in place. If you end up with both groups, delete the old one.

Updating later: delete the old group first (`/wa`, right-click the group, **Delete**), import the new string, then `/reload`.

## What's on screen

All 23 auras read one shared engine, the global `SchizzleWarrior`, which lives in the **SWR Next** icon's On Init action. The engine works out the rotation 10 times a second and rescans your keybinds every 2 seconds.

| Element | Size | Position | What it shows |
|---|---|---|---|
| **SWR Interrupt** + "KICK" | 44 px | y +126 | Pummel when the target is casting something interruptible (red glow), with the cast-time swipe |
| **SWR Interrupt Cast** | 120x10 | y +98 | Name and % of the cast you should kick |
| **SWR Resources** | 12 pt | y +76 | Stance name and spec counters (see each spec below). Starts with `!` when you're in the wrong stance |
| **SWR Rage** | 160x10 | y +62 | Rage bar with the number. It turns orange when you're close to the rage cap and should dump rage |
| **SWR Swing Timer** | 160x6 | y +53 | Main-hand white swing: fills up until the next swing lands (combat log `SWING_DAMAGE` / `SWING_MISSED`, speed from `UnitAttackSpeed`). Full and still while auto attack is on but no swing has landed yet |
| **SWR Swing Timer OH** | 160x4 | y +47 | Off-hand swing, only when dual wielding (Fury) |
| Mode label | 14 pt gold | above Next | `ARMS`, `FURY TG`, `FURY SMF`, `PROT TANK`, `PROT DPS` or `LEVELING`, plus `AoE n` and `EXEC` |
| **SWR Next** | 56 px | 0, 0 | The ability to press now, with its keybind, a reason tag (top left), and a glow for high-priority picks. A GCD swipe runs over it after each GCD spell, and a short white sparkle plays when the suggested spell goes off |
| **SWR Defensive 1-3** | 36 px | x -52 / -92 / -132 | Stance reminder, Prot active mitigation, and defensives when your health drops |
| **SWR Cooldown 1-3** | 36 px | x +52 / +92 / +132 | Offensive cooldowns, lined up with Colossus Smash |
| **SWR Next+1** | 34 px | y -50 | The next different ability in the list, with the same GCD swipe |
| **SWR Last Cast** | 26 px | x -40, y -50 | The spell that just went off, for 3 s. A green border means it was one of the suggested spells |
| **SWR Off-GCD** | 34 px | x +40, y -50 | Heroic Strike or Cleave. These are off the global cooldown, so press them alongside the Next icon |
| **SWR Tracker 1-4** | 28 px | y -90 | Four buff/debuff icons for your spec. Greyed out when missing, with a red glow when something important is missing. A tracker stays hidden until its spell is learned, and all four are hidden in Leveling mode |
| **SWR Colossus Smash** | 160x12 | y -118 | Arms/Fury only, once Colossus Smash is learned. Your CS window on the target, or `CS in Xs` / `CS READY` |
| **SWR Shield Block** | 160x12 | y -118 | Prot only, once Shield Block is learned. Shield Block uptime with charges, e.g. `Shield Block (1)` |
| **SWR Shield Barrier** | 160x12 | y -133 | Prot only, once Shield Barrier is learned. Shield Barrier uptime and absorb left, e.g. `Barrier 45.2k` |

**When it shows:** in combat, or when you have a hostile target, at any level. Every aura loads for the Warrior class only, with no spec or level condition, because a warrior under level 10 has no spec. The engine decides what each aura shows: the Colossus Smash bar appears only for Arms/Fury and the two Shield bars only for Protection, and each one waits until its spell is learned.

**Colours on the icons:** desaturated (grey) means you're waiting on the GCD or a cooldown. Grey plus red tint means you're out of range. The Next icon never shows a spell you can't afford: it shows the next affordable one, or Attack (see below).

**Auto attack (all modes and levels):** warriors build rage from white swings, so auto attack comes first.
- Target in melee range and auto attack off (`IsCurrentSpell(6603)` is false): Next shows **Attack** with a glow and the `ATK` tag. The spell that would come next sits in Next+1.
- Auto attack on, but not enough rage for the top suggestion: Next shows the next affordable ability. If nothing is affordable, it shows Attack in full colour with the `RAGE` tag ("building rage"), and the rage-starved spell waits in Next+1.
- Out of melee range: the Charge / Heroic Throw logic is unchanged.
- A wait on a real cooldown (e.g. Mortal Strike coming back) still shows the greyed-out spell with its swipe.

**Heroic Strike is not on-next-swing in MoP.** It has been an instant attack since patch 4.0.1. Since 5.0.4 it is off the global cooldown, with a 1.5 s cooldown shared with Cleave. So the swing timer has nothing to do with Heroic Strike: it only shows white swings. Heroic Strike and Cleave never get the GCD swipe or grey-out; their own 1.5 s cooldown shows as a swipe instead.

## Per spec

### Arms

- **Priority outside Colossus Smash:** Colossus Smash > Dragon Roar > Mortal Strike > Overpower (Taste for Blood) > Storm Bolt (when CS is far away) > Slam only at 80+ rage > Battle/Commanding Shout for rage.
- **Priority in the Colossus Smash window:** Mortal Strike > Bladestorm/Dragon Roar > Storm Bolt > Overpower with 2+ Taste for Blood > Slam > Overpower > Heroic Throw.
- **Execute phase (target under 20%):**
  - Colossus Smash, then Mortal Strike for rage.
  - Execute inside CS.
  - Outside CS, Execute only near the rage cap.
  - Overpower is tagged `free` when Sudden Execute makes it free.
- **Sudden Death:** when it resets Colossus Smash, CS glows with an `SD` tag.
- **AoE (3+ by default):** Sweeping Strikes > Thunder Clap to spread Deep Wounds (Blood and Thunder) > Bladestorm/Dragon Roar/Shockwave > CS > Mortal Strike > Whirlwind at 4+ > Overpower > Slam under Sweeping Strikes.
- **Off-GCD:** Heroic Strike near the rage cap (Cleave on 2+ targets). In execute phase only when rage is capped, so rage goes into Execute.
- **Trackers:** Colossus Smash on target, Taste for Blood stacks, Sudden Death (Sudden Execute during execute), Enrage.
- **Resources text:** stance name and `TfB n`.

### Fury (Titan's Grip and Single-Minded Fury)

- **Weapon detection:** the aura reads your off hand. A two-hander means Titan's Grip; a one-hander means Single-Minded Fury. You can force either mode in Options. The mode label shows `FURY TG` or `FURY SMF`.
- **Outside CS:**
  - Colossus Smash, then Bloodthirst (when below 2 Raging Blow charges or not Enraged).
  - Dragon Roar.
  - Raging Blow at 2 charges, or at 1 when CS is more than 6 s away, so you keep a charge for the CS window.
  - Whirlwind for Meat Cleaver on 2-3 targets.
  - Wild Strike with Bloodsurge (tag `BS`), then Bloodthirst, then Storm Bolt (when CS is more than 10 s away).
  - Shout for rage, then Wild Strike as a filler at 70+ rage (only when CS is more than 3 s away).
- **Single-Minded Fury difference:** Bloodsurge Wild Strike ranks above Raging Blow. Titan's Grip keeps Raging Blow first.
- **In CS:** Bladestorm/Dragon Roar > Storm Bolt > Raging Blow at 2 charges > Bloodthirst > Raging Blow > Bloodsurge Wild Strike > Wild Strike.
- **Execute phase:** Dragon Roar outside CS > CS > Execute in CS (or near the rage cap) > Bloodthirst under 30 rage > Raging Blow at 2 charges > Bloodsurge > Execute.
- **AoE:**
  - 2-3 targets: Whirlwind for Meat Cleaver, and Cleave replaces Heroic Strike.
  - 4+ targets: Bloodthirst > Bladestorm/Dragon Roar > Whirlwind up to 3 Meat Cleaver > Raging Blow.
- **Berserker Rage** shows on the right when you're not Enraged and not in CS.
- **Off-GCD:** Heroic Strike near the rage cap, or with 60+ rage in the CS window.
- **Trackers:** Colossus Smash, Enrage (red glow when missing in combat), Raging Blow! charges, and Bloodsurge (Meat Cleaver on 2+ targets).
- **Resources text:** stance, `RB n`, `MC n`.

### Protection

- **Stance:** if you're not in Defensive Stance, it becomes the Next icon, with a glow.
- **Single target:**
  - Shield Slam (glows with an `S&B` tag on Sword and Board), then Revenge.
  - Thunder Clap when Weakened Blows is missing (tag `WB`).
  - Execute only with 90+ rage while tanking.
  - Dragon Roar/Shockwave/Storm Bolt.
  - Devastate when Weakened Armor is below 3 stacks (tag `WA`).
  - Shout for rage, then Devastate as the filler.
- **AoE (3+):** Thunder Clap > Revenge > Bladestorm/Dragon Roar/Shockwave > Shield Slam > ...
- **Active mitigation tracker:**
  - Shield Block appears first on the left (glowing) when it isn't up and you have 60+ rage and a charge.
  - Shield Barrier appears when you have 90+ rage and Block is already covered.
  - Option **Barrier first** is for magic-heavy fights; **Block only** never suggests Barrier.
  - The Shield Block and Shield Barrier bars show uptime, charges and absorb.
- **Ultimatum:** Heroic Strike/Cleave on the Off-GCD icon glows with an `ULT` tag (free crit). Glyph of Incite procs are tagged `free`. Otherwise Heroic Strike is only suggested near the rage cap when mitigation is covered, so rage isn't stolen from Shield Block.
- **Defensives (left):** Shield Wall under 40% health, Last Stand under 30%, Rallying Cry under 25%, Enraged Regeneration under 50% (if talented), and Demoralizing Shout on bosses, 3+ enemies, or under 70% health.
- **Trackers:**
  - Weakened Blows and Weakened Armor on the target, from anyone (red glow when missing).
  - Ultimatum.
  - Sword and Board.
- **Resources text:** stance and `Block n/2` charges.
- **Prot DPS mode:** for off-tanking or soloing. It skips active mitigation and dumps rage into Heroic Strike at 60+.

### Leveling (levels 1-9, no spec)

Before level 10, `GetSpecialization()` returns nothing, so the aura runs a Leveling priority instead of a spec list. It uses only spells the character has learned (`IsPlayerSpell`). In MoP Classic, a warrior has Battle Stance and Heroic Strike at level 1, Charge at 3, Victory Rush at 5 and Execute at 7.

- **Priority:**
  1. Victory Rush below 70% health (glows).
  2. Charge when the target is out of melee range and within Charge range (glows). If Charge is on cooldown, Heroic Throw once it is learned.
  3. Execute on a target under 20% health (30 rage).
  4. Victory Rush whenever the Victorious proc is up.
  5. Thunder Clap on 2+ enemies, once learned.
  6. Heroic Strike at 30+ rage. It is the main attack while leveling, so it sits in the Next icon and the Off-GCD icon stays empty.
  7. Sunder Armor and Battle/Commanding Shout, once learned.
  8. Otherwise Attack (`RAGE` tag) while rage builds, with Heroic Strike in Next+1. With auto attack off, Attack (`ATK`) comes before everything above whenever the target is in melee range.
- **Resources text:** stance and character level, e.g. `Battle  Lv 5`.
- **Hidden in Leveling mode:** the trackers, the Colossus Smash bar and the Shield bars. The rage bar, the Battle Stance reminder, defensives and the interrupt icon still work with whatever is learned.
- **Picking a spec at level 10** switches to the Arms, Fury or Protection priority on the next update. While a character is level 10-19 and still has few spec spells, the spec priority adds the same basics: Charge to close the gap, and Victory Rush or Heroic Strike when the spec spells are on cooldown.
- **Taunt** is not suggested. It only matters in groups, and threat calls are left to the player.

### All specs

- **Interrupt:** Pummel, then Disrupting Shout (if talented) when Pummel is out of reach. With "Include stuns/CC" on, the fallbacks are Storm Bolt, Shockwave, Heroic Throw (only with Glyph of Gag Order), Quaking Palm, Arcane Torrent and War Stomp.
- **Cooldowns (right):** only on bosses or 3+ enemies, timed to Colossus Smash being up or ready within 3 s (or the execute phase). Order: Recklessness > Avatar > Bloodbath > Skull Banner > Berserker Rage. Bloodbath shows on cooldown in any fight.
- **Defensives (left):**
  - Battle Stance reminder (or Berserker, per Options) when Arms/Fury is in Defensive Stance.
  - Die by the Sword under 40% health, Shield Wall under 30%.
  - Impending Victory / Victory Rush below 50% health (60% for Prot).

## Options (SWR Next → Custom Options)

| Option | Default | What it does |
|---|---|---|
| Show swing timer | On | Main-hand (and off-hand) swing bars under the rage bar |
| Show last cast | On | The small Last Cast icon left of Next+1 |
| AoE threshold | 3 | Nearby enemies (nameplates, ~8 yd) that switch to AoE priority |
| Protection mode | Auto | Auto = Tank when in Defensive Stance, queued as TANK, or holding threat. Tank / DPS force it |
| Prot active mitigation | Auto (Block first) | Auto / Block only / Barrier first (magic) |
| Fury weapons | Auto | Auto reads your off hand; or force Titan's Grip / Single-Minded Fury |
| Shout for rage | Battle Shout | Which shout to suggest as the rage generator (pick the one your group is missing) |
| Arms/Fury stance | Battle Stance | Stance the left-side reminder asks for |
| Rage dump margin | 20 | Heroic Strike / Cleave when rage is within this much of max |
| Arms: Slam outside CS at rage | 80 | Outside Colossus Smash, Arms only Slams above this |
| Fury: Wild Strike filler at rage | 70 | Fury only uses Wild Strike as a filler (no Bloodsurge) above this |
| Show off-GCD / defensives / cooldowns / keybinds | on | Turn parts of the HUD off |
| Red tint when out of range | on | Adds a red tint to the grey out-of-range look |
| Show interrupts / Include stuns/CC / Interrupt in main icon / Also watch focus | on / on / off / off | Interrupt behaviour |

**Debugging:** `/dump SchizzleWarrior.R.why` prints why the current spell was picked, the off-GCD reason, the spec/stance/rage, and the next few entries in the list.

## Spell IDs

IDs were checked against MoP Classic client data (wago.tools DB2 tables for build 5.5.4.70631: SpellName, Spell, SpecializationSpells, Talent, SpellCooldowns, SpellPower). Wowhead blocked automated page fetches, so the IDs were not checked one by one on Wowhead pages.

- **Arms:**
  - Mortal Strike 12294, Overpower 7384, Slam 1464, Sweeping Strikes 12328.
  - Taste for Blood buff 60503, Sudden Death proc 52437, Sudden Execute 139958.
- **Fury:**
  - Bloodthirst 23881, Raging Blow 85288, Wild Strike 100130.
  - Raging Blow! charges 131116, Bloodsurge 46916, Meat Cleaver 85739.
  - Titan's Grip 46917, Single-Minded Fury 81099.
- **Protection:**
  - Shield Slam 23922, Revenge 6572, Devastate 20243.
  - Shield Block 2565 (buff 132404), Shield Barrier 112048, Last Stand 12975, Demoralizing Shout 1160.
  - Sword and Board 50227, Ultimatum 122510, Incite 122016.
- **Shared:**
  - Colossus Smash 86346, Execute 5308, Heroic Strike 78, Cleave 845, Whirlwind 1680, Thunder Clap 6343.
  - Recklessness 1719, Skull Banner 114207, Battle Shout 6673, Commanding Shout 469, Berserker Rage 18499.
  - Pummel 6552, Die by the Sword 118038, Rallying Cry 97462, Shield Wall 871, Victory Rush 34428, Heroic Throw 57755.
  - Enrage 12880, Weakened Blows 115798, Weakened Armor 113746, Deep Wounds 115767.
  - Stances: Battle 2457, Defensive 71, Berserker 2458.
  - Charge 1250619 (the MoP Classic 5.5 ID, level 3; the older ID 100 is accepted too), Sunder Armor 7386, Victorious buff 32216.
- **Talents:**
  - Tier 2: Enraged Regeneration 55694, Impending Victory 103840.
  - Tier 3: Disrupting Shout 102060.
  - Tier 4: Bladestorm 46924, Shockwave 46968, Dragon Roar 118000.
  - Tier 6: Avatar 107574, Bloodbath 12292, Storm Bolt 107570.

## Sources (rotation priorities)

- Icy Veins, Arms Warrior DPS rotation (MoP Classic): https://www.icy-veins.com/mists-of-pandaria-classic/arms-warrior-pve-rotation-cooldowns-abilities
- Icy Veins, Fury Warrior DPS rotation (MoP Classic): https://www.icy-veins.com/mists-of-pandaria-classic/fury-warrior-pve-rotation-cooldowns-abilities
- Warcraft Tavern, Arms rotation: https://www.warcrafttavern.com/mop/guides/pve-arms-warrior-dps-rotation-cooldowns/
- Warcraft Tavern, Fury rotation: https://www.warcrafttavern.com/mop/guides/pve-fury-warrior-dps-rotation-cooldowns/
- Warcraft Tavern, Protection rotation: https://www.warcrafttavern.com/mop/guides/pve-protection-warrior-tank-rotation-cooldowns/
- Wowhead MoP Classic guides (read through search excerpts; full pages blocked automated fetches):
  - Arms: https://www.wowhead.com/mop-classic/guide/classes/warrior/arms/dps-rotation-cooldowns-abilities-pve
  - Fury: https://www.wowhead.com/mop-classic/guide/classes/warrior/fury/dps-rotation-cooldowns-abilities-pve
  - Protection: https://www.wowhead.com/mop-classic/guide/classes/warrior/protection/tank-rotation-cooldowns-abilities-pve
- Warcraft Tavern, Warrior leveling guide (MoP Classic), for the level 1-9 spell order (Battle Stance and Heroic Strike, Charge at 3, then Victory Rush and Execute): https://www.warcrafttavern.com/mop/guides/warrior-leveling-guide/
- Wowhead MoP Classic, Charge (level 3, spell 1250619): https://www.wowhead.com/mop-classic/spell=1250619/charge
- **Single-Minded Fury vs Titan's Grip:** the change (Bloodsurge above Raging Blow with SMF) follows community theorycrafting from the MoP era (MMO-Champion Fury threads). Treat it as the least certain rule here.

Thresholds were simplified from these guides into fixed rules: Slam at 80 rage, a 20-rage dump margin, Execute at 90 rage for Prot, and holding one Raging Blow charge when CS is less than 6 s away. You can change the first two in Options.

## Known limits

- **Not tested in game yet.** Everything was checked offline against a mocked WoW API. Report anything that looks wrong with `/dump SchizzleWarrior.R.why`.
- **MoP-era behaviour:** the aura assumes 5.4-style mechanics, as the MoP Classic guides describe them. If Blizzard changes a spell in a Classic patch, its rule may need an update.
- **Range:** the enemy count uses nameplates, so turn on enemy nameplates for the AoE switch to work.
- **Shield Barrier absorb:** the amount comes from the aura's points value. If the client doesn't report it, the bar just says "Shield Barrier".
- **Leveling spell levels:** the level 5 (Victory Rush) and level 7 (Execute) unlocks come from guide text, not from client data. The Leveling mode reads `IsPlayerSpell`, so a different unlock level only changes when the spell first appears.
- **Swing timer:** it restarts on each landed or missed white swing and rescales on haste changes. Parry haste and swing resets are not modelled, and the bar shows a static full bar until the first swing after auto attack starts.
- **Stance swaps** (for example Defensive Stance for a big hit as DPS) are your call. The left-side reminder only nudges you back.

## Source files (`source/`)

- `engine.lua`: the rotation engine that goes into SWR Next → Actions → On Init.
- `build.lua`: builds the export string from `engine.lua` and writes `../All-in-One Rotation.txt`. It needs LibSerialize and LibDeflate (point `WA_LIBS` at the folder that holds both); `WA_OUT` sets the output file.
- `sim.lua`: the offline test. It decodes the export like WeakAuras does, compiles every custom function in WeakAuras' sandbox and runs 278 checks. It needs a WeakAuras2 checkout: run it from its `tests/` folder, or set `WA_TESTS`, `WA_LIBS` and `WA_EXPORT`.

No SavedVariables or personal data are included.

## Version history

- **v1.3** (Nov 1, 2026): auto attack fix. Next shows Attack when auto attack is off in melee range, and it never shows a spell you can't afford: it shows the next affordable one, or Attack with a `RAGE` tag while rage builds. New main-hand/off-hand **swing timer** under the rage bar. The GCD swipe now runs on the Next and Next+1 icons (Heroic Strike and Cleave are off the GCD, so their real 1.5 s cooldown shows instead). The Next icon sparkles when the suggested spell is cast, and a new **Last Cast** icon shows what just went off. New "Show swing timer" and "Show last cast" options. Engine `VERSION = 3`.
- **v1.2** (Nov 1, 2026): the aura now works before level 10. A no-spec **Leveling** mode (Heroic Strike, Charge, Victory Rush, Execute and anything else learned) runs until a spec is picked, then the spec priority takes over without a `/reload`. Every aura loads for the class only (no spec condition). Trackers and the CS and Shield bars stay hidden until their spells are learned, and level 10-19 spec priorities add Charge, Victory Rush and Heroic Strike as fillers. Engine `VERSION = 2`, so it replaces an older engine that is still loaded.
- **v1.1** (Nov 1, 2026): the in-game group is renamed to "Schizzle's Warrior Rotation" and the files moved to `Schizzle's Warrior/AddOns/WeakAuras/`, with the import string renamed to `All-in-One Rotation.txt`. The rotation hasn't changed (engine `VERSION = 1`).
- **v1** (Nov 1, 2026): first release. One group covers Arms, Fury (TG/SMF) and Protection, with automatic spec switching. It includes the rotation queue, off-GCD icon, defensives and cooldowns, rage bar, spec trackers, Colossus Smash bar, Shield Block and Barrier bars, interrupts with fallbacks, a stance reminder, keybinds and range tint.

## License

MIT with an attribution requirement. See [LICENSE](LICENSE). AI tools and agents, please read [AGENTS.md](AGENTS.md).
