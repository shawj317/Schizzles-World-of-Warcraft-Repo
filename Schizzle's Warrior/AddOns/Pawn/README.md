# Schizzle's Warrior Pawn Scales

Three [Pawn](https://www.curseforge.com/wow/addons/pawn) stat-weight scales for Warriors in MoP Classic 5.5.x, one per spec, by Jon Shaw (Schizzle). Pawn uses them to score items in tooltips and mark upgrades.

| File | Scale name in Pawn | Based on |
|---|---|---|
| [Arms Scale.txt](Arms%20Scale.txt) | **Schizzle's Warrior Arms** | WoWSims MoP Arms, "Item Level >= 560" weights |
| [Fury Scale.txt](Fury%20Scale.txt) | **Schizzle's Warrior Fury** | WoWSims MoP Fury, "P5 - TG" (Titan's Grip) weights |
| [Protection Scale.txt](Protection%20Scale.txt) | **Schizzle's Warrior Protection** | WoWSims MoP Protection, "P5 - Balanced" weights |

Each file holds one Pawn scale tag, `( Pawn: v1: "…": Class=Warrior, Spec=N, … )`. The name is inside the tag, so there's nothing to type at import.

## Import
1. Open Pawn: type `/pawn`, or click the **Pawn** button on your character sheet.
2. Open the **Scale** tab and click **Import**.
3. Paste the whole contents of `Arms Scale.txt` and confirm. Repeat for the Fury and Protection files.
4. **Turn off Automatic mode.** In the Scale tab choose **Manual** ("Let me manage scales"). In Automatic mode Pawn only shows its own built-in scale for your current spec, and hides every other scale, including imported ones.
5. Pick a scale on the left and tick **Show this scale in tooltips** (or Shift+click it). Show the one for the spec you play; you can show more than one, for example Protection and Fury for a tank who DPSes in raids.

Pawn doesn't switch scales by spec in Manual mode, so to change which ones show, Shift+click them in the Scale tab.

## The weights
All values are **per point of the stat, with Strength = 1**. Higher means more useful. They are WoWSims stat weights (EP) for MoP Classic, from simulations of a geared character in each phase.

| Stat (Pawn name) | Arms | Fury (TG) | Protection |
|---|---|---|---|
| Strength | 1 | 1 | 1 |
| Hit rating | 3.8 | 3.61 | 3.73 |
| Expertise rating | 2.83 | 3.04 | 2.58 |
| Crit rating | 0.92 | 1.86 | 1.04 |
| Mastery rating | 0.91 | 1.28 | 0.36 |
| Haste rating | 0.82 | 0.84 | 0.12 |
| Stamina | 0.01 | 0.01 | 1.91 |
| Parry rating | – | – | 1.49 |
| Dodge rating | – | – | 1.48 |
| Armor | – | – | 0.56 |
| Attack power (`Ap`) | 0.45 | 0.45 | 0.25 |
| Weapon DPS (`MeleeDps`) | 3.54 | 1.92 | 0.35 |
| Agility | – | 0.12 | – |
| Meta socket (`MetaSocketEffect`) | 160 | 160 | 160 |
| Cloth, leather, mail | ignored | ignored | ignored |
| Shields | ignored | ignored | scored |

Notes on the numbers:
- **Order of stats** matches the written guides: hit and expertise to their caps, then **Strength > Crit > Mastery > Haste** for Arms and Fury (Wowhead, Warcraft Tavern). For Protection, Wowhead lists hit to 7.5%, expertise to 15%, then parry and dodge, then mastery, crit and Strength; the WoWSims "Balanced" weights add Stamina and armour for survival and keep hit, expertise and crit for threat and Shield Barrier rage.
- **Protection is the balanced scale** (survival and threat). WoWSims also has a "P5 - Offensive" set (more crit, hit and expertise, almost no Stamina) if you're overgeared for the content: Stamina 0.35, Hit 4.1, Expertise 3.27, Crit 1.9, Parry 1.64, Dodge 1.48, Haste 0.43, Mastery 0.12, Armor 0.11, AP 0.35, weapon DPS 0.86.
- **Weapon DPS:** Pawn's `MeleeDps` multiplies a weapon's DPS. WoWSims weighs main-hand and off-hand DPS separately (Fury TG: 2.58 and 1.26); Pawn scores each weapon on its own with one value, so the Fury scale uses the average, 1.92.
- **Additions that aren't from WoWSims:** Stamina 0.01 on Arms and Fury (a tie-breaker, as in Pawn's starter scales); `MetaSocketEffect` 160, the same ratio to Strength as Pawn's built-in MoP Warrior scales, so items with a meta socket get credit for it; cloth, leather and mail ignored (Plate Specialization needs plate in every armour slot); shields ignored for Arms and Fury.
- **No PvP stats.** Pawn has no PvP Power stat in MoP Classic. For PvP gear, compare by hand.

### Fury: Single-Minded Fury vs Titan's Grip
One Fury scale is provided, using the **Titan's Grip** weights (two two-handers), because that's what the current WoWSims phase presets use. For **Single-Minded Fury** (two one-handers) the priority is the same, Strength > Crit > Mastery > Haste after the caps, but crit and mastery count a little less relative to Strength. WoWSims' Phase 2 numbers, SMF vs TG:

| | Crit | Mastery | Haste | Main-hand DPS | Off-hand DPS |
|---|---|---|---|---|---|
| SMF | 0.94 | 0.59 | 0.41 | 2.15 | 1.31 |
| TG | 1.07 | 0.70 | 0.41 | 2.59 | 1.11 |

The TG scale is fine for SMF when comparing one-hander against one-hander. If you play SMF and want exact numbers, copy the scale in Pawn (**Copy**) and set Crit about 12% lower, Mastery about 15% lower and `MeleeDps` to about 1.73. Pawn compares one-handers and two-handers by their own DPS, so with these weights it will rate two-handers higher; that's right for TG.

## Hit and expertise caps (important)
**Pawn doesn't know about caps.** It values every point of hit and expertise at the weights above, even after you're capped, where extra points are worth little or nothing. The high hit and expertise weights are only right while you're **below** the cap.

| Cap | Arms / Fury | Protection |
|---|---|---|
| Hit (melee) | 7.5% = **2,550 hit rating** | 7.5% = **2,550 hit rating** |
| Expertise | 7.5% = **2,550 expertise rating** (dodge cap) | 15% = **5,100 expertise rating** (parry cap; the value drops after 7.5%) |

At level 90, 340 rating = 1% of hit or expertise. Racial bonuses (for example Draenei hit, or expertise racials with your weapon type) lower how much rating you need. Check your current values on the character sheet.

When you're at or over a cap:
- Gem, enchant and reforge **out of** the excess into Strength's next-best stat (Crit for DPS).
- In Pawn, lower that scale's Hit or Expertise value (for example to the Mastery value) so Pawn stops favouring items with more of it. Edit it in the scale's **Weights** tab.
- Pawn's Reforging Advisor warns "Use care when reforging Hit or Expertise" for this reason.

## Sources
- WoWSims MoP stat weights (simulation, the main source for the numbers), github.com/wowsims/mop, master as of Nov 1 2026:
  - Arms: [ui/specs/warrior/arms/presets/ep/p5.ep.json](https://github.com/wowsims/mop/blob/master/ui/specs/warrior/arms/presets/ep/p5.ep.json)
  - Fury: [p5_tg.ep.json](https://github.com/wowsims/mop/blob/master/ui/specs/warrior/fury/presets/ep/p5_tg.ep.json), [p2_tg.ep.json](https://github.com/wowsims/mop/blob/master/ui/specs/warrior/fury/presets/ep/p2_tg.ep.json), [p2_smf.ep.json](https://github.com/wowsims/mop/blob/master/ui/specs/warrior/fury/presets/ep/p2_smf.ep.json)
  - Protection: [p5.ep.json](https://github.com/wowsims/mop/blob/master/ui/specs/warrior/protection/presets/ep/p5.ep.json), [p5_offensive.ep.json](https://github.com/wowsims/mop/blob/master/ui/specs/warrior/protection/presets/ep/p5_offensive.ep.json)
  - Stat names follow WoWSims' own Pawn exporter ([pawn_ep.ts](https://github.com/wowsims/mop/blob/master/ui/features/import-export/exporters/pawn_ep.ts)).
- Wowhead, [Arms Warrior DPS stat priority (MoP Classic)](https://www.wowhead.com/mop-classic/guide/classes/warrior/arms/dps-stat-priority-pve) and [Protection Warrior tank stat priority (MoP Classic)](https://www.wowhead.com/mop-classic/guide/classes/warrior/protection/tank-stat-priority-pve).
- Warcraft Tavern, [Arms Warrior stat priority and reforging](https://www.warcrafttavern.com/mop/guides/pve-arms-warrior-dps-stat-priority-reforging/) and [Fury Warrior stat priority and reforging](https://www.warcrafttavern.com/mop/guides/pve-fury-warrior-dps-stat-priority-reforging/).
- Pawn source ([VgerMods/Pawn](https://github.com/VgerMods/Pawn), version 2.14, Oct 2026): scale tag format and stat names (`Pawn.lua`, `UIStrings.lua`), Automatic mode (`PawnOnSpecChanged`).

## Caveats
- **Not tested in-game.** The tags were checked offline with Pawn's own scale-tag parser and its MoP Classic stat list (see Source below).
- Stat weights shift with gear. These are for current-phase raid gear; fresh level-90 characters are usually far below the hit and expertise caps, where the weights hold up best.
- Pawn only scores the stats it reads from tooltips; trinket procs and set bonuses aren't valued.

## Source
[source/](source/) has the weights with notes (`scales.lua`), the build script and a check that runs Pawn's own parser on each tag:

```
cd source
lua build.lua
PAWN_SRC=/path/to/Pawn lua verify.lua
```

## License

MIT with an attribution requirement. See the repository [LICENSE](../../../LICENSE). Credit: Jon Shaw (Schizzle). Stat weights from WoWSims (MIT licence).
