# Schizzle's Warrior Rotation

An all-in-one WeakAuras rotation helper for Warriors in MoP Classic 5.5.x: **Arms, Fury and Protection in one import**.

> **Heads-up:** this aura is built for Mists of Pandaria Classic (5.5.x). It will be revised for WoW Forever after that launches.

This folder also holds a second, separate import: the **[XP & Rep Tray](#xp--rep-tray-separate-import)**, three slim experience, reputation and guild reputation bars that sit under the Details! windows.

**File:** [`All-in-One Rotation.txt`](All-in-One%20Rotation.txt) (33,261 chars, starts `!WA:2!`). Current version: **v1.7** (engine `VERSION = 9`).
**Built for:** WeakAuras 5.22.1, Mists build (interface 50504, internalVersion 90). Font: **Fira Sans Condensed Medium** (it ships with WeakAuras).
**Switches automatically:** the aura reads your specialization (`GetSpecialization`) and swaps the priority list, trackers and bars when you change spec. You don't need separate imports for tanking in dungeons, DPS in raids and the other DPS spec in PvP. Before level 10 (no specialization yet) it runs a **Leveling** mode instead, and it switches to the spec priority as soon as a spec is picked, with no `/reload`.
**Talents handled:** every spell is gated by `IsPlayerSpell`, so only the talent you actually took shows up. That covers tier 4 (Bladestorm, Shockwave or Dragon Roar) and tier 6 (Avatar, Bloodbath or Storm Bolt), plus Impending Victory, Enraged Regeneration and Disrupting Shout.
**Verified offline:** the export string decodes the same way WeakAuras' importer does. All custom code compiles inside WeakAuras' own aura sandbox with 0 warnings, and a mock-API rotation simulator passes 364 checks across all three specs, the no-spec Leveling mode (levels 1, 3, 5, 7 and 9), freshly specced level 10 characters, the auto attack logic, the rage bar visibility, the GCD swipe and the cast feedback. **It has not been tested in the game client yet.** See "Known limits" below.

## Install (step by step)

1. Install **WeakAuras** for MoP Classic (CurseForge app or Wago app) and log in on your Warrior.
2. Open `All-in-One Rotation.txt` on GitHub, then click the **Copy raw file** button (two overlapping squares, top right of the file). This copies the whole string.
3. In game, type `/wa` and click **Import** (top left of the WeakAuras window).
4. Paste with **Ctrl+V** (Cmd+V on Mac), then click **Import**.
5. WeakAuras shows a summary of the "Schizzle's Warrior Rotation v1.7" group. Click **Import** again to accept it.
6. Type `/reload`.
7. Target a training dummy. The HUD appears under the middle of your screen (the group defaults to x 0, y -40: its centre sits on the screen's centre, 40 px down).
8. To move it, open `/wa`, click the group name and drag, or set the X/Y offset on the group's **Display** tab.
9. Options live on **Schizzle's Warrior Rotation v1.7 → SWR Next → Custom Options** (see "Options" below).

**Group name and updates:** the in-game group name carries the version ("Schizzle's Warrior Rotation v1.7" now), so it changes with every release. The child auras keep fixed names ("SWR Next", "SWR Rage" and so on). WeakAuras matches an import to an installed group by its internal ID (uid), not by its name, and that ID has never changed (it is the same one the first upload, "Schizzle's Warrior Rotation WeakAura", used). So importing a new version shows WeakAuras' **Update** dialog for the existing group. Leave **Aura Names** ticked in that dialog (it is ticked by default) so the group picks up the new name; untick it to keep the old name. Settings in Custom Options carry over unless you also tick Custom Configuration. Only if the import shows up as a second group (for example after choosing "Import as Copy") should you delete the older one.

**Position on update:** a fresh import puts the group at x 0, y -40 (group CENTER on the screen's CENTER). When you update an existing group, WeakAuras leaves its position alone unless you tick **Size & Position** in the Update dialog (it is unticked by default). That category covers the group's x/y offsets, anchor points, anchor frame, strata, size and scale. Tick it to move the group to 0, -40; leave it unticked to keep where you dragged it. The child auras' layout inside the group (their positions and sizes) falls under **Group Arrangement** (ticked by default).

**Group Scale and Alpha:** the whole group is drawn at **Scale 0.8** and **Alpha 0.8** (80% size, 80% opacity; on the group's **Display** tab as Group Scale and Group Alpha). Alpha rides in **Display**, so a plain Update applies it. Scale is in **Size & Position**, so tick that box on Update to get the 0.8 scale (it also moves the group back to 0, -40).

**Text sizes on update:** WeakAuras sorts changes by the top-level field that changed. Icon and bar texts (keybind, tag, mode, KICK and bar labels) live inside each aura's sub-regions, so a change to their size, font or outline rides in **Display** (ticked by default) and a plain **Update** applies it. Only a text aura's own `fontSize` (the SWR Resources text) counts as a size field, and on a child aura WeakAuras files size fields under **Group Arrangement** (also ticked by default). **Size & Position** only matters for the group itself: tick it only if you want the group moved back to 0, -40, because it also resets the group's position.

## What's on screen

All 30 auras read one shared engine, the global `SchizzleWarrior`, which lives in the **SWR Next** icon's On Init action. The engine works out the rotation 10 times a second and rescans your keybinds every 2 seconds.

| Element | Size | Position | What it shows |
|---|---|---|---|
| **SWR Interrupt** + "KICK" | 44 px | y +126 | Pummel when the target is casting something interruptible (red glow), with the cast-time swipe |
| **SWR Interrupt Cast** | 120x10 | y +98 | Name and % of the cast you should kick |
| **SWR Resources** | 12 pt | y +76 | Spec counters (see each spec below). No stance name or level; hidden in Leveling mode, which has no counters |
| **SWR Rage** | 80x5 | y +62 | Rage bar, with the rage number just to its right. Shown only **in combat with more than 0 rage**; hidden otherwise. It turns orange when you're close to the rage cap and should dump rage |
| Mode label | 14 pt gold | above Next | `ARMS`, `FURY TG`, `FURY SMF`, `PROT TANK`, `PROT DPS` or `LEVELING`, plus `AoE n` and `EXEC` |
| **SWR Next** | 56 px | 0, 0 | The ability to press now, with its keybind, a reason tag (top left), and a glow for high-priority picks. A GCD swipe runs over it after each GCD spell, and a short white sparkle plays when the suggested spell goes off |
| **SWR Defensive 1-3** | 36 px | x -52 / -92 / -132 | Stance reminder, Prot active mitigation, and defensives when your health drops |
| **SWR Cooldown 1-3** | 36 px | x +52 / +92 / +132 | Offensive cooldowns, lined up with Colossus Smash |
| **SWR Next+1** | 34 px | y -50 | The next different ability in the list, with the same GCD swipe |
| **SWR Last Cast** | 26 px | x -40, y -50 | The spell that just went off, for 3 s. A green border means it was one of the suggested spells |
| **SWR Off-GCD** | 34 px | x +40, y -50 | Heroic Strike or Cleave. These are off the global cooldown, so press them alongside the Next icon |
| **SWR Tracker 1-4** | 28 px | y -90 | Four buff/debuff icons for your spec. Greyed out when missing, with a red glow when something important is missing. A tracker stays hidden until its spell is learned, and all four are hidden in Leveling mode |
| **SWR Sunder** | 28 px | x +80, y -90 | Arms/Fury/Leveling, with the "Track Sunder Armor" option on and Sunder Armor learned. Sits right of the trackers in the same style: Weakened Armor stacks on the target (from anyone) with its timer swipe, greyed out when missing, red glow in combat when it's missing, under 3 stacks or under 5 s left. Prot keeps its own Weakened Armor tracker |
| **SWR Colossus Smash** | 160x12 | y -129 | Arms/Fury only, once Colossus Smash is learned. Your CS window on the target, or `CS in Xs` / `CS READY` |
| **SWR Shield Block** | 160x12 | y -129 | Prot only, once Shield Block is learned. Shield Block uptime with charges, e.g. `Shield Block (1)` |
| **SWR Shield Barrier** | 160x12 | y -144 | Prot only, once Shield Barrier is learned. Shield Barrier uptime and absorb left, e.g. `Barrier 45.2k` |
| **SWR Tray 1-8** | 32 px | y -172, x +134 to -118 (36 px apart) | Cooldown tray, bottom right: racials and big cooldowns that aren't in the rotation, shown only when known and off cooldown. Fills from the right edge (x +150) toward the left. See [Cooldown tray](#cooldown-tray) |

**Spacing (v1.7):** the tracker labels end 13 px under the tracker icons (y -117). The Colossus Smash / Shield Block bar starts 6 px below that, Shield Barrier sits 3 px under Shield Block, and the tray starts 6 px under Shield Barrier, so nothing overlaps. Before v1.7 the CS bar at y -118 covered the tracker labels.

**When it shows:** in combat, or when you have a hostile target, at any level. Every aura loads for the Warrior class only, with no spec or level condition, because a warrior under level 10 has no spec. The engine decides what each aura shows: the Colossus Smash bar appears only for Arms/Fury and the two Shield bars only for Protection, and each one waits until its spell is learned.

**Colours on the icons:** desaturated (grey) means you're waiting on the GCD or a cooldown. Grey plus red tint means you're out of range. The Next icon never shows a spell you can't afford: it shows the next affordable one, or Attack (see below).

**Auto attack (all modes and levels):** warriors build rage from white swings, and any instant melee attack (Heroic Strike, Mortal Strike, Bloodthirst, Shield Slam, Victory Rush, Execute and so on) starts auto attack by itself.
- Target in melee range and auto attack off (`IsCurrentSpell(6603)` is false): if a melee attack is learned, off cooldown and affordable, Next shows it, because using it starts auto attack too. Only when no melee attack is usable (for example under 30 rage at level 1) does Next show **Attack** with a glow and the `ATK` tag, with the waiting spell in Next+1.
- Auto attack on, but not enough rage for the top suggestion: Next shows the next affordable ability. If nothing is affordable, it shows Attack in full colour with the `RAGE` tag ("building rage"), and the rage-starved spell waits in Next+1.
- Out of melee range: the Charge / Heroic Throw logic is unchanged.
- A wait on a real cooldown (e.g. Mortal Strike coming back) still shows the greyed-out spell with its swipe.

**Heroic Strike is not on-next-swing in MoP.** It has been an instant attack since patch 4.0.1. Since 5.0.4 it is off the global cooldown, with a 1.5 s cooldown shared with Cleave. Heroic Strike and Cleave never get the GCD swipe or grey-out; their own 1.5 s cooldown shows as a swipe instead.

## Per spec

### Arms

- **Priority outside Colossus Smash:** Colossus Smash > Dragon Roar > Mortal Strike > Overpower (Taste for Blood) > Storm Bolt (when CS is far away) > Sunder Armor (option on, Weakened Armor missing / under 3 / under 5 s, tag `WA`) > Slam only at 80+ rage > Battle/Commanding Shout for rage.
- **Priority in the Colossus Smash window:** Mortal Strike > Bladestorm/Dragon Roar > Storm Bolt > Overpower with 2+ Taste for Blood > Slam > Overpower > Sunder Armor (option on, as above) > Heroic Throw.
- **Execute phase (target under 20%):**
  - Colossus Smash, then Mortal Strike for rage.
  - Execute inside CS.
  - Outside CS, Execute only near the rage cap.
  - No Sunder Armor prompt in the execute phase (rage goes to Execute); the Sunder icon still glows.
  - Overpower is tagged `free` when Sudden Execute makes it free.
- **Sudden Death:** when it resets Colossus Smash, CS glows with an `SD` tag.
- **AoE (3+ by default):** Sweeping Strikes > Thunder Clap to spread Deep Wounds (Blood and Thunder) > Bladestorm/Dragon Roar/Shockwave > CS > Mortal Strike > Whirlwind at 4+ > Overpower > Slam under Sweeping Strikes.
- **Off-GCD:** Heroic Strike near the rage cap (Cleave on 2+ targets). In execute phase only when rage is capped, so rage goes into Execute.
- **Trackers:** Colossus Smash on target, Taste for Blood stacks, Sudden Death (Sudden Execute during execute), Enrage.
- **Resources text:** `TfB n` (Taste for Blood stacks).

### Fury (Titan's Grip and Single-Minded Fury)

- **Weapon detection:** the aura reads your off hand. A two-hander means Titan's Grip; a one-hander means Single-Minded Fury. You can force either mode in Options. The mode label shows `FURY TG` or `FURY SMF`.
- **Outside CS:**
  - Colossus Smash, then Bloodthirst (when below 2 Raging Blow charges or not Enraged).
  - Dragon Roar.
  - Raging Blow at 2 charges, or at 1 when CS is more than 6 s away, so you keep a charge for the CS window.
  - Whirlwind for Meat Cleaver on 2-3 targets.
  - Wild Strike with Bloodsurge (tag `BS`), then Bloodthirst, then Storm Bolt (when CS is more than 10 s away).
  - Sunder Armor when the option is on and Weakened Armor is missing, under 3 stacks or under 5 s left (tag `WA`). Not in the CS window or the execute phase.
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
- **Resources text:** `RB n  MC n` (Raging Blow charges, Meat Cleaver stacks).

### Protection

- **Stance:** if you're not in Defensive Stance, it becomes the Next icon, with a glow.
- **Single target:**
  - Shield Slam (glows with an `S&B` tag on Sword and Board), then Revenge.
  - Thunder Clap when Weakened Blows is missing (tag `WB`).
  - Execute only with 90+ rage while tanking.
  - Dragon Roar/Shockwave/Storm Bolt.
  - Devastate when Weakened Armor is below 3 stacks or under 4 s left (tag `WA`). Devastate applies Weakened Armor itself. With "Track Sunder Armor" off this bump is skipped (Devastate stays the filler) and the Weakened Armor tracker doesn't glow.
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
- **Resources text:** `Block n/2` (Shield Block charges).
- **Prot DPS mode:** for off-tanking or soloing. It skips active mitigation and dumps rage into Heroic Strike at 60+.

### Leveling (levels 1-9, no spec)

Before level 10, `GetSpecialization()` returns nothing, so the aura runs a Leveling priority instead of a spec list. It uses only spells the character has learned (`IsPlayerSpell`). In MoP Classic, a warrior has Battle Stance and Heroic Strike at level 1, Charge at 3, Victory Rush at 5 and Execute at 7.

- **Priority:**
  1. Victory Rush below 70% health (glows).
  2. Charge when the target is out of melee range and within Charge range, 8-25 yd (glows). Charge is only suggested when it is learned, ready (its 20 s recharge is over) and the target is hostile. If Charge is recharging, Heroic Throw once it is learned; if neither is ready, the list moves on to the next spell.
  3. Execute on a target under 20% health (30 rage).
  4. Victory Rush whenever the Victorious proc is up.
  5. Thunder Clap on 2+ enemies, once learned.
  6. Heroic Strike at 30+ rage. It is the main attack while leveling, so it sits in the Next icon and the Off-GCD icon stays empty.
  7. Sunder Armor (in combat, when Weakened Armor needs it and the "Track Sunder Armor" option is on) and Battle/Commanding Shout, once learned.
  8. Otherwise Attack (`RAGE` tag) while rage builds, with Heroic Strike in Next+1. With auto attack off and the target in melee range, Attack (`ATK`) shows only when none of the melee attacks above is usable; Heroic Strike at 30+ rage comes first and starts auto attack itself.
- **Resources text:** hidden. Leveling mode has no counters to show, and the stance and level are no longer printed.
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

## Cooldown tray

A row of small icons (32 px, about 57% of the Next icon) under the HUD at y -172 (y -160 before v1.7). They show racials and big cooldowns that the rotation doesn't call for, so you can see at a glance what's ready.

- **Ready only:** an icon shows only when the spell is known (`IsPlayerSpell`) and off cooldown (the GCD doesn't count). A spell on cooldown or not learned is simply not there, so nothing shows greyed out.
- **Packs from the right:** ready spells fill slot 1 at the right edge first and grow leftward, up to 8. No gaps, no overlap.
- **No duplicates:** a spell that the Next, Next+1, Off-GCD, Interrupt, Defensive or Cooldown icons already show is left out of the tray for that moment. For example, Recklessness sits in the Cooldown icons during a boss Colossus Smash window, so the tray drops it until then.
- **Spec-aware:** the engine picks the list from your current spec. All tray auras load for the Warrior class only, like the rest of the HUD, and they show at the same times (in combat, or with a hostile target).
- **Order:** your racial first, then the spec list in the order below.

| Spec | Tray spells (in order) |
|---|---|
| Arms / Fury | Recklessness, Skull Banner, Avatar, Bloodbath, Die by the Sword, Shield Wall, Rallying Cry, Heroic Leap, Shattering Throw |
| Protection | Shield Wall, Last Stand, Spell Reflection, Demoralizing Banner, Rallying Cry, Avatar, Bloodbath, Heroic Leap |
| Leveling (no spec) | Recklessness, Shield Wall, Rallying Cry, Heroic Leap, Last Stand, Die by the Sword, Shattering Throw |

Talent spells (Avatar, Bloodbath) show only if you took the talent. Bladestorm, Dragon Roar, Shockwave, Storm Bolt, Berserker Rage and Impending Victory are left out because the rotation already suggests them.

| Race | Racial |
|---|---|
| Orc | Blood Fury |
| Troll | Berserking |
| Human | Every Man for Himself (Will to Survive in the MoP Classic client) |
| Dwarf | Stoneform |
| Undead | Will of the Forsaken, Cannibalize |
| Tauren | War Stomp |
| Blood Elf | Arcane Torrent |
| Draenei | Gift of the Naaru |
| Gnome | Escape Artist |
| Night Elf | Shadowmeld |
| Worgen | Darkflight |
| Goblin | Rocket Barrage, Rocket Jump |
| Pandaren | Quaking Palm |

Turn it off with **Show cooldown tray** in the options.

## Options (SWR Next → Custom Options)

| Option | Default | What it does |
|---|---|---|
| AoE threshold (enemies) | 3 | Nearby enemies (nameplates, ~8 yd) that switch to AoE priority (2-10) |
| Protection mode | Auto | Auto = Tank when in Defensive Stance, queued as TANK, or holding threat. Tank / DPS force it |
| Prot active mitigation | Auto (Block first) | Auto / Block only / Barrier first (magic) |
| Fury weapons | Auto | Auto reads your off hand; or force Titan's Grip / Single-Minded Fury |
| Shout for rage | Battle Shout | Which shout to suggest as the rage generator (pick the one your group is missing) |
| Arms/Fury stance | Battle Stance | Stance the left-side reminder asks for |
| Rage dump margin | 20 | Heroic Strike / Cleave when rage is within this much of max |
| Arms: Slam outside CS at rage | 80 | Outside Colossus Smash, Arms only Slams above this |
| Fury: Wild Strike filler at rage | 70 | Fury only uses Wild Strike as a filler (no Bloodsurge) above this |
| Track Sunder Armor (Weakened Armor) | on | **On** if you're tanking or assigned to keep Weakened Armor up: Sunder Armor is suggested (tag `WA`, below the big hitters, above Slam / shout / Wild Strike fillers) when the target's Weakened Armor, from anyone, is missing, under 3 stacks or under 5 s left, and the SWR Sunder icon shows stacks and time. If someone else keeps it at 3 stacks you get no prompt. **Off** if someone else does it: no Sunder prompt and no Sunder icon (Prot also skips the Devastate `WA` bump) |
| Show off-GCD / defensives / stance (left) / offensive cooldowns (right) / keybinds | on | Turn parts of the HUD off |
| Red tint when out of range | on | Adds a red tint to the grey out-of-range look |
| Show last cast | on | The small Last Cast icon left of Next+1 |
| Show cooldown tray | on | The ready-only racial / cooldown row at the bottom right |
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
- **Cooldown tray extras:** Shattering Throw 64382, Demoralizing Banner 114203, Spell Reflection 23920, Heroic Leap 6544.
- **Racials** (every rank the client uses): Blood Fury 20572 / 33697 / 33702, Berserking 26297, Every Man for Himself 59752, Stoneform 20594, Will of the Forsaken 7744, Cannibalize 20577, War Stomp 20549, Arcane Torrent 69179 / 129597 / 28730 / 25046 / 50613 / 80483, Gift of the Naaru 28880 / 121093 / 59542-59548, Escape Artist 20589, Shadowmeld 58984, Darkflight 68992, Rocket Barrage 69041, Rocket Jump 69070, Quaking Palm 107079. Names were checked against Wowhead's MoP Classic tooltips.

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

## XP & Rep Tray (separate import)

**File:** [`XP & Rep Tray.txt`](XP%20%26%20Rep%20Tray.txt) (6,669 chars, starts `!WA:2!`). In-game group: **Schizzle's XP & Rep Tray v1.3**. It has nothing to do with the rotation group, so it works on any class and can be imported on its own.

**What it is:** three slim bars, each **500 x 10 px**, stacked with 2 px gaps (**34 px tall** in total), in the bottom-right corner 4 px from the right and bottom edges of the screen. From the top: experience (28-38 px up), watched reputation (16-26 px up) and guild reputation (4-14 px up). That is directly under the two side-by-side [Details! windows](../Details!/), which are 500 px wide together, so the tray and the meters line up edge to edge. The Details! profiles from v1.7 on are 250 x 141 with their bottom edge 38 px up to make room for it (v1.5 and v1.6 were sized for the two-bar tray).

- **Top bar, experience:** a **blue** fill for the XP earned this level. Right after it comes a **green** overlay for the XP waiting in quests that are **complete but not turned in yet**, then a **purple** overlay for **rested XP**. Both overlays are clipped at the bar's end. Left text: `Level 42   Rested 35%` (the rested part only shows while you have rested XP). Right text: current / needed and percent, plus the waiting quest XP when there is some, for example `12,345 / 50,000   24.7%   +3,500 quest`. The green part shows roughly where the bar will be after turning those quests in.
- **Middle bar, reputation:** the faction you're watching (tick **Show as Experience Bar** on a faction in the reputation panel, `U`). Left text: faction name and standing, for example `Shado-Pan   Honored`. Right text: progress inside that standing and percent. **The bar colour follows the standing:** red (Hated, Hostile), orange (Unfriendly), yellow (Neutral), green (Friendly), sea green (Honored), blue (Revered) and purple (Exalted). Friendship factions such as the Tillers farmers show their own rank (Stranger to Best Friend) on a green bar, and a maxed rank shows a full bar with the rank name. If you watch your guild's faction, the bar shows the guild's name.
- **Bottom bar, guild reputation (v1.3):** your standing with your guild, read from `C_Reputation.GetGuildFactionData` (the guild faction, ID 1168). Left text: guild name and standing, for example `Example Guild   Honored`; right text: progress inside that standing and percent. Same standing colours as the reputation bar.
- **Mouseover tooltips:** hover a bar for the details. The XP tooltip shows the level, current / needed XP and percent, XP to the next level, rested XP (amount and percent of the level), the XP waiting in completed quests with the number of quests, and where you'll be after turning them in (or "level N +X" if they level you up). The reputation tooltip shows the faction, its standing (or friendship rank), progress inside the standing and the amount and percent left to the next one. The guild tooltip shows the guild name, guild standing, progress inside it and what's left to the next standing. There is no weekly cap line: MoP Classic's API has no guild reputation cap field or function. The tooltip opens to the left of the tray, so it never covers the Details! windows. The bars only react to the mouse moving over them: clicks still go straight through to the game world.
- **Kit look:** Fira Sans Condensed Medium at size 9 with an outline, a near-black background and a thin bronze frame drawn inside each bar, so nothing spills onto the meters above.

**When a bar hides:**
- **The XP bar hides at the level cap (90)**, and also if XP gain is switched off. The bars below it move up, so the top one always sits right under Details! and the strip at the very bottom of the screen stays empty. The tray's top edge never moves, so there's never a gap between the meters and the bars.
- **The reputation bar hides when no faction is watched.** Watch one again and it comes back.
- **The guild bar hides when you're not in a guild** (or the client reports guild reputation as off).
- **No duplicate:** if the faction you're watching *is* your guild, the guild bar hides and the reputation bar shows the guild instead (with its name). Watch another faction and the guild bar comes back.
- If all are hidden, the tray shows nothing at all.

**Game APIs (checked against the MoP Classic 5.5.4 client source):** `UnitXP`, `UnitXPMax`, `GetXPExhaustion`, `UnitLevel`, `IsXPUserDisabled`, `GetMaxLevelForPlayerExpansion`, `C_Reputation.GetWatchedFactionData`, `C_Reputation.GetGuildFactionData` (which the 5.5.4 guild UI itself reads), `IsInGuild`, `GetGuildInfo`, `C_GuildInfo.IsGuildReputationEnabled` and `C_GossipInfo.GetFriendshipReputation`. The quest XP comes from the quest log: `GetNumQuestLogEntries`, `GetQuestLogTitle` (a quest counts when the log marks it complete) and `GetQuestLogRewardXP`. In the quest log that last one reads the **selected** quest: MoP Classic's own quest panel calls `SelectQuestLogEntry` and then `GetQuestLogRewardXP()` with no argument. So the tray selects each completed quest in turn, reads its XP and then puts your own selection back. MoP Classic's `C_QuestLog` doesn't have the retail quest-log functions, so these older ones are the right ones there. The tray falls back to the older `GetWatchedFactionInfo` and `GetGuildFactionInfo` if `C_Reputation` is ever missing, and to a level cap of 90 if the client doesn't report one. Every optional API is type-checked first, and the code uses no `pcall`, `AuraUtil` or anything else WeakAuras' sandbox blocks. The tooltips use a plain `CreateFrame` hover frame and Blizzard's `GameTooltip`. The bars only update on game events (XP gained, level up, rested change, quest log changes, quest turned in, reputation change, guild change, loading screens), so they cost nothing between them.

### Import the tray (step by step)
1. Open `XP & Rep Tray.txt` on GitHub and click **Copy raw file** (two overlapping squares, top right of the file).
2. In game, type `/wa` and click **Import**.
3. Paste with **Ctrl+V** (Cmd+V on Mac), then click **Import**.
4. WeakAuras shows the "Schizzle's XP & Rep Tray v1.3" group with three auras (Schizzle Tray XP, Schizzle Tray Rep and Schizzle Tray Guild). Click **Import** again.
5. Type `/reload`.
6. To get the reputation bar, press `U`, click a faction and tick **Show as Experience Bar**.
7. Import the **v1.7 Details! profiles** too (see the [Details! README](../Details!/)), so the meters are 250 x 141 and sit right on top of the 34 px tray. With older Details! profiles the meters cover the tray's top bar (v1.5 / v1.6) or more.

**Updating to v1.3 (from any earlier version):** do steps 1 to 3 the same way and click **Update**. Keep the default ticks (Add Missing Auras brings in the new guild bar) and **also tick Size & Position** this time: the group's default spot moved from y 26 to **y 38** so the taller tray still ends 4 px from the bottom. Leaving it unticked keeps the group at y 26: the guild bar would then sit almost entirely below the bottom of the screen (only its top 2 px showing) and the v1.7 Details! windows would float 12 px above the tray. Ticking it resets any spot you dragged the group to. Click **Import**, then `/reload`, and import the v1.7 Details! profiles.

**Updating from v1.0 or v1.1 to v1.2 (older note):** do steps 1 to 3 the same way. WeakAuras recognises the tray and shows an **Update** button instead of a plain import: click it, leave the default ticks (Trigger brings the quest XP fix, Actions the tooltips, Display the colours; leave Size & Position unticked to keep your spot), click **Import**, then `/reload`. The group is renamed to v1.2.

**Quest log note:** the client only lists quests under expanded headers in the quest log, so a completed quest under a collapsed zone header isn't counted in the green overlay until you expand that header. The tray doesn't expand headers itself, because that would change your quest log.

**Moving it:** open `/wa`, click the group and drag it, or set X/Y on its **Display** tab. The default is the group's top-right corner on the screen's bottom-right corner at x -4, y 38. On a later update, WeakAuras keeps your position unless you tick **Size & Position**.

**Verified offline:** `source/tray_sim.lua` decodes the string like WeakAuras' importer, replays WeakAuras' dynamic group layout (XP 28-38 px up, reputation 16-26 px up, guild 4-14 px up, all 4-504 px in from the right, and every combination of hidden bars collapsing upwards), compiles all three triggers inside WeakAuras' own sandbox (0 warnings) and runs 176 checks with a mocked game: the blue / green / purple colours and their order, mid level with and without rested XP, completed quests waiting (headers, unfinished and failed quests don't count), a quest log change, turning a quest in, a missing quest API, levelling to 90, XP switched off, no watched faction, a normal faction, Exalted, friendship ranks (mid and maxed), the `GetWatchedFactionInfo` fallback, and for the guild bar: not in a guild, guild progress and text, the tooltip (no cap line), rep gain, watching the guild (guild bar hides, Rep bar shows the guild name), Exalted, a new member at Neutral 0, guild reputation off, leaving the guild, guild data not loaded yet and the `GetGuildFactionInfo` fallback. The mocked `GetQuestLogRewardXP` reads the selected quest like the real client, which reproduces the v1.1 bug (v1.1 sums to 0). It also checks that the selection is restored, the tooltip text for both bars, the tooltip's position, the hover frame taking mouse motion only, and that the 5.5.4 client's quest panel calls the function that way. **It has not been tested in the game client yet.**

## Known limits

- **Not tested in game yet.** Everything was checked offline against a mocked WoW API. Report anything that looks wrong with `/dump SchizzleWarrior.R.why`.
- **MoP-era behaviour:** the aura assumes 5.4-style mechanics, as the MoP Classic guides describe them. If Blizzard changes a spell in a Classic patch, its rule may need an update.
- **Range:** the enemy count uses nameplates, so turn on enemy nameplates for the AoE switch to work.
- **Shield Barrier absorb:** the amount comes from the aura's points value. If the client doesn't report it, the bar just says "Shield Barrier".
- **Leveling spell levels:** the level 5 (Victory Rush) and level 7 (Execute) unlocks come from guide text, not from client data. The Leveling mode reads `IsPlayerSpell`, so a different unlock level only changes when the spell first appears.
- **Sunder Armor costs 15 rage and a GCD.** In a raid with a tank (or a Feral druid / Rogue) keeping Weakened Armor up, turn the option off. Weakened Armor is one shared 3-stack debuff (about 30 s), so stacks from different players don't add up past 3. The prompt waits for combat, a hostile target and 15 rage.
- **Stance swaps** (for example Defensive Stance for a big hit as DPS) are your call. The left-side reminder only nudges you back.

## Source files (`source/`)

- `engine.lua`: the rotation engine that goes into SWR Next → Actions → On Init.
- `build.lua`: builds the export string from `engine.lua` and writes `../All-in-One Rotation.txt`. The version lives in one place, `RELEASE` near the top, which sets the group name and description. It needs LibSerialize and LibDeflate (point `WA_LIBS` at the folder that holds both); `WA_OUT` sets the output file.
- `tray_build.lua`: builds the separate XP & Rep Tray and writes `../XP & Rep Tray.txt` (same `WA_LIBS` / `WA_OUT` settings).
- `tray_sim.lua`: the tray's offline test (176 checks), run the same way as `sim.lua`. Set `WOW_UI_SOURCE` to a wow-ui-source checkout of the 5.5 client to also confirm every game API it calls exists there.
- `sim.lua`: the offline test. It decodes the export like WeakAuras does, compiles every custom function in WeakAuras' sandbox and runs 413 checks. It needs a WeakAuras2 checkout: run it from its `tests/` folder, or set `WA_TESTS`, `WA_LIBS` and `WA_EXPORT`.

No SavedVariables or personal data are included.

## Version history

The XP & Rep Tray has its own version: **v1.0** (Nov 3, 2026) was the first release; **v1.1** (Nov 3, 2026) makes the XP fill blue, turns the rested overlay purple and adds a green overlay (and right-side text) for XP waiting in completed quests that haven't been turned in; **v1.2** (Nov 3, 2026) fixes that green overlay, which never showed in game because `GetQuestLogRewardXP` reads the selected quest rather than a questID, and adds mouseover tooltips to both bars; **v1.3** (Nov 3, 2026) adds a third bar for guild reputation (the tray is now 34 px tall and the group's default y moved from 26 to 38; update with Size & Position ticked, plus the v1.7 Details! profiles). Update it with Import → **Update**. The list below is the rotation's.

- **v1.7** (Nov 3, 2026): new **Track Sunder Armor (Weakened Armor)** option (Custom Options, on by default) and a layout fix.
  - On: in combat with a hostile target and 15+ rage, Sunder Armor is suggested (tag `WA`) when Weakened Armor on the target (from anyone) is missing, under 3 stacks or under 5 s left. Arms: after Storm Bolt, before Slam and the shout; in the CS window after Overpower, before Heroic Throw. Fury: after Storm Bolt, before the shout and the Wild Strike filler; not in the CS window. Never in the execute phase. Leveling's Sunder now follows the option too (and waits for combat). Nothing is suggested when someone keeps it at 3 stacks.
  - New **SWR Sunder** icon right of the trackers (Arms/Fury/Leveling): Weakened Armor stacks and timer, red glow when Sunder is needed.
  - Off: no Sunder prompt, no Sunder icon, and Prot skips the Devastate `WA` bump and the Weakened Armor tracker's glow.
  - Layout: the Colossus Smash / Shield Block bar covered the tracker labels (CS, TfB, SD, Exe/Enr). Bars moved from y -118 to -129 (Shield Barrier -133 to -144) and the tray from -160 to -172, each 6 px clear of the element above.
  - Engine `VERSION = 9`. 413 simulator checks (Sunder priority, the 3-stack and refresh cases, option off, Prot, and the new spacing). **Updating:** import and click **Update** with the default ticks. Group Arrangement (ticked by default) moves the bars and tray, Add Missing Auras adds SWR Sunder, and Actions must stay ticked for the engine. Your Custom Options carry over and the new option starts on. Then `/reload`.
- **v1.6.1** (Nov 3, 2026): bug fix for Charge being suggested while it was on cooldown. In MoP Classic 5.5 Charge is a charge spell (one charge, 20 s recharge; charge category 1219 in the client's spell data), and the client reports that recharge only through `C_Spell.GetSpellCharges`. `GetSpellCooldown` returns 0 for it, and that was all the engine read, so Charge always looked ready. The engine's cooldown check now reads both and uses whichever is longer, with the global `GetSpellCooldown` / `GetSpellCharges` as a fallback, and ignores the global cooldown by comparing against the GCD spell (61304). The `isOnGCD` flag is only trusted for a cooldown of 1.5 s or less, because the client can leave it stale. Charge is also skipped when the target is within its 8 yd minimum range. When Charge isn't usable, the list falls through to Heroic Throw, Mortal Strike, Victory Rush and the rest. Heroic Throw, Mortal Strike and Colossus Smash use the same cooldown check; Victory Rush follows the Victorious buff. Engine `VERSION = 8`. 383 simulator checks, now with Charge recharging (both spell IDs, modern and older APIs), during the GCD, in melee, at 6 and 30 yd, and the level 10 and 90 Arms fallbacks. **Updating:** import and click **Update** with the default ticks (Actions, which holds the engine, must stay ticked). Leave Size & Position unticked to keep your spot, then `/reload`.
- **v1.6** (Nov 3, 2026): a smaller, quieter HUD.
  - The rage bar is half the size (80x5, was 160x10). Its number moved to the right of the bar, and the "Rage" label is gone.
  - The rage bar shows only in combat with more than 0 rage. Out of combat, or at 0 rage, it is hidden (the engine's custom trigger checks both, so every child keeps the same load settings as before).
  - The swing timer is removed for all specs: the SWR Swing Timer and SWR Swing Timer OH auras, the "Show swing timer" option and the engine's swing tracking are gone. Nothing sat below the bars, so no gap is left; the mode label is re-centred between the Next icon and the smaller rage bar.
  - The Resources text no longer shows the stance name or the level (for example `Battle  Lv 8`), and no longer starts with `!` in the wrong stance. The stance reminder icon on the left still glows when you're in the wrong stance.
  - The group draws at Group Scale 0.8 and Group Alpha 0.8.
  - Engine `VERSION = 7`, so it replaces a v1.5.1 engine that is still loaded. 364 simulator checks.
  - **Updating:** import and click **Update**. Keep the default ticks (Group Arrangement applies the new bar size; Add Missing Auras and the removal of the two swing auras happen on their own) and also tick **Size & Position** to get the 0.8 scale. That also moves the group back to 0, -40. Then `/reload`.
- **v1.5.1** (Nov 2, 2026): bug fix for `Lua error in Aura 'SWR Resources' … AuraUtil.lua:25: attempt to call a nil value`. When a buff wasn't found by the aura scan, the engine fell back to Blizzard's `AuraUtil.FindAuraByName`. That helper calls through a swappable data provider, and Edit Mode's sample provider (swapped in by `AURA_DATA_PROVIDER_SWITCH`) has no `GetAuraDataBySpellName`, so the call failed. The engine no longer uses AuraUtil at all. Its own lookup tries `C_UnitAuras.GetAuraDataByIndex`, then a `UnitAura` / `UnitBuff` / `UnitDebuff` index loop (plus `C_UnitAuras.GetPlayerAuraBySpellID` for player buffs when the index API is missing). It matches by spell ID, and by name only as a last resort. Every API is type-checked and runs protected (through a coroutine, since WeakAuras' sandbox blocks `pcall`), so a missing or broken API means "no aura" and never a Lua error. Engine `VERSION = 6`. 371 simulator checks, including AuraUtil missing or erroring, C_UnitAuras missing, and GetAuraDataByIndex erroring. **Updating:** re-import with WeakAuras' default Update ticks. **Actions** (which holds the engine) must stay ticked. Size & Position can stay unticked.
- **v1.5** (Nov 2, 2026): new **cooldown tray**, 8 small icons (32 px) at the bottom right (y -160, growing leftward from x +150). It shows your racial and the spec's big cooldowns that aren't in the rotation, only while they are known and off cooldown, and never a spell another icon already shows. New "Show cooldown tray" option. Engine `VERSION = 5`. 353 simulator checks. **Updating:** the existing child auras keep their IDs, so WeakAuras offers **Update**. Leave **Add Missing Auras** ticked (default) to get the eight SWR Tray auras. Tick **Size & Position** and **Group Arrangement** if your group or icons were moved and you want the default layout back.
- **v1.4.1** (Nov 2, 2026): the group's default position is now x 0, y -40 (was 0, -190), anchored CENTER to the screen's CENTER. The child auras keep their positions relative to the group. The group name follows the version: "Schizzle's Warrior Rotation v1.4.1". On Update, tick **Size & Position** to apply the new position. No rotation changes (engine `VERSION = 4`). 292 simulator checks.
- **v1.4** (Nov 2, 2026): opener fix. With auto attack off, Next used to put Attack first even when there was enough rage for Heroic Strike (or another melee attack). That came from the v1.3 auto attack rule, which put Attack in front of every suggestion whenever auto attack was off. Now a usable, affordable melee attack stays first, since using it starts auto attack anyway, and Attack is only the fallback when nothing is usable. This applies to Leveling mode and to Arms, Fury and Protection at every level. The in-game group name now carries the version: **"Schizzle's Warrior Rotation v1.4"** (it comes from one `RELEASE` constant in `source/build.lua`, which also sets the description). Its internal ID is unchanged, so re-importing updates the existing group in place. New simulator checks bring the total to 290. Engine `VERSION = 4`, so it replaces the v1.3 engine if that one is still loaded.
- **v1.3** (Nov 1, 2026): auto attack fix. Next shows Attack when auto attack is off in melee range, and it never shows a spell you can't afford: it shows the next affordable one, or Attack with a `RAGE` tag while rage builds. New main-hand/off-hand **swing timer** under the rage bar. The GCD swipe now runs on the Next and Next+1 icons (Heroic Strike and Cleave are off the GCD, so their real 1.5 s cooldown shows instead). The Next icon sparkles when the suggested spell is cast, and a new **Last Cast** icon shows what just went off. New "Show swing timer" and "Show last cast" options. Engine `VERSION = 3`.
- **v1.2** (Nov 1, 2026): the aura now works before level 10. A no-spec **Leveling** mode (Heroic Strike, Charge, Victory Rush, Execute and anything else learned) runs until a spec is picked, then the spec priority takes over without a `/reload`. Every aura loads for the class only (no spec condition). Trackers and the CS and Shield bars stay hidden until their spells are learned, and level 10-19 spec priorities add Charge, Victory Rush and Heroic Strike as fillers. Engine `VERSION = 2`, so it replaces an older engine that is still loaded.
- **v1.1** (Nov 1, 2026): the in-game group is renamed to "Schizzle's Warrior Rotation" and the files moved to `Schizzle's Warrior/AddOns/WeakAuras/`, with the import string renamed to `All-in-One Rotation.txt`. The rotation hasn't changed (engine `VERSION = 1`).
- **v1** (Nov 1, 2026): first release. One group covers Arms, Fury (TG/SMF) and Protection, with automatic spec switching. It includes the rotation queue, off-GCD icon, defensives and cooldowns, rage bar, spec trackers, Colossus Smash bar, Shield Block and Barrier bars, interrupts with fallbacks, a stance reminder, keybinds and range tint.

## License

MIT with an attribution requirement. See [LICENSE](LICENSE). AI tools and agents, please read [AGENTS.md](AGENTS.md). Original repo: https://github.com/shawj317/Schizzles-World-of-Warcraft-Repo/tree/main/WoW%20Classic%20-%20Mists%20of%20Pandaria/Schizzle's%20Warrior/AddOns/WeakAuras
