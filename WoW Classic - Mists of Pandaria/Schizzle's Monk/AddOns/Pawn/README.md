# Schizzle's Monk Pawn Scales

Three [Pawn](https://www.curseforge.com/wow/addons/pawn) stat-weight scales for Monks in MoP Classic 5.5.x, one per spec, by Jon Shaw (Schizzle). Pawn uses them to score items in tooltips and mark upgrades.

The scales score gear with WoWSims weights for Brewmaster, Windwalker and Mistweaver. You need the Pawn addon. Turn Automatic mode off after import, or the imported scales stay hidden. Hit and expertise keep a high weight after you are capped, which the cap section below explains.

| File | Scale name in Pawn | Based on |
|---|---|---|
| [Brewmaster Scale.txt](Brewmaster%20Scale.txt) | **Schizzle's Monk Brewmaster** | WoWSims MoP Brewmaster, "P5 - Balanced" weights |
| [Windwalker Scale.txt](Windwalker%20Scale.txt) | **Schizzle's Monk Windwalker** | WoWSims MoP Windwalker, "RoRo >= 560" (Phase 5) weights |
| [Mistweaver Scale.txt](Mistweaver%20Scale.txt) | **Schizzle's Monk Mistweaver** | WoWSims MoP Mistweaver, "Default" weights |

Each file holds one Pawn scale tag, `( Pawn: v1: "…": Class=Monk, Spec=N, … )`. The name is inside the tag, so there's nothing to type at import. (Pawn numbers the Monk specs 1 = Brewmaster, 2 = Mistweaver, 3 = Windwalker.)

## Import
1. Open Pawn: type `/pawn`, or open your character sheet (press `C`) and click the **Pawn** button.
2. Open the **Scale** tab and click **Import**.
3. Paste the whole contents of `Brewmaster Scale.txt` and confirm. Repeat for the Windwalker and Mistweaver files.
4. **Turn off Automatic mode.** In the Scale tab choose **Manual** ("Let me manage scales"). In Automatic mode Pawn only shows its own built-in scale for your current spec, and hides every other scale, including imported ones.
5. Pick a scale on the left and tick **Show this scale in tooltips** (or Shift+click it). Show the one for the spec you play; you can show more than one, for example Brewmaster and Windwalker for a tank who also DPSes.

Pawn doesn't switch scales by spec in Manual mode, so to change which ones show, Shift+click them in the Scale tab.

## The weights
All values are **per point of the stat, with the primary stat = 1** (Agility for Brewmaster and Windwalker, Intellect for Mistweaver). Higher means more useful. They are WoWSims stat weights (EP) for MoP Classic, from simulations of a geared character.

| Stat (Pawn name) | Brewmaster | Windwalker | Mistweaver |
|---|---|---|---|
| Agility | 1 | 1 | – |
| Intellect | – | – | 1 |
| Hit rating | 2.56 | 2.46 | 0.9 |
| Expertise rating | 1.56 | 2.11 | – |
| Haste rating | 0.79 | 1.05 | 1 |
| Crit rating | 0.85 | 0.83 | 0.42 |
| Mastery rating | 0.55 | 0.39 | 0.13 |
| Spirit | – | – | 0.9 |
| Spell power (`SpellPower`) | – | – | 0.79 |
| Stamina | 1.11 | 0.01 | 0.01 |
| Parry rating | 0.39 | – | – |
| Dodge rating | 0.27 | – | – |
| Armor | 0.32 | – | – |
| Attack power (`Ap`) | 0.2 | 0.34 | – |
| Weapon DPS (`MeleeDps`) | 0.73 | 1.65 | – |
| Meta socket (`MetaSocketEffect`) | 160 | 160 | 160 |
| Cloth, mail, plate | ignored | ignored | ignored |
| Off-hand frills (`IsFrill`) | ignored | ignored | scored |

Notes on the numbers:
- **Order of stats** matches the written guides (Wowhead, Phase 5):
  - **Brewmaster:** item level (Agility, Armor, Stamina), hit to 7.5%, expertise 7.5–15%, then Haste and Crit (offensive) or Mastery (defensive). The WoWSims "Balanced" weights sit between the two: Stamina and armour for survival, hit, expertise, crit and haste for damage, Chi and Elusive Brew.
  - **Windwalker:** Agility, hit and expertise to 7.5%, then **Haste > Crit > Mastery**.
  - **Mistweaver:** Intellect and spell power, Spirit (Stance of the Wise Serpent turns Spirit into hit and expertise, so it covers the melee caps and mana), then Haste to the next Renewing/Enveloping Mist breakpoint, Crit, more Haste, Mastery last.
- **Brewmaster is the balanced scale.** WoWSims also has a "P5 - Offensive" set if you're comfortable on survival: Stamina 0.35, Hit 3.25, Expertise 1.91, Crit 1.02, Haste 1.01, Mastery 0.52, Parry 0.24, Dodge 0.1, Armor 0.1, AP 0.24, main-hand DPS 1.28, off-hand DPS 0.72. To use it, copy the scale in Pawn (**Copy**) and edit the numbers in its **Weights** tab.
- **Weapon DPS:** Pawn's `MeleeDps` multiplies a weapon's DPS. WoWSims weighs main-hand and off-hand DPS separately (Brewmaster 0.98 and 0.47, Windwalker 2.19 and 1.10). Pawn scores each weapon on its own with one value, so the scales use the average of the two hands, 0.73 and 1.65 (the same rule as the Warrior Fury scale). Monks can use a two-hander (staff or polearm) or two one-handers. Pawn rates a two-hander on its own higher DPS, so check a two-hander against a pair of one-handers by hand or in a sim.
- **Mistweaver hit:** WoWSims values hit rating at 0.9 because it also helps Crackling Jade Lightning (15% spell hit). In practice Spirit already gives you the melee caps through Stance of the Wise Serpent, so hit rating on gear is rarely needed.
- **Spell power name:** WoWSims' own Pawn exporter writes spell power as `SpellDamage`, but in MoP Classic Pawn calls it `SpellPower` (`SpellDamage` only exists for Classic and TBC), so these scales use `SpellPower`.
- **Additions that aren't from WoWSims:**
  - Stamina 0.01 on Windwalker and Mistweaver, as a tie-breaker (as in the Warrior DPS scales).
  - `MetaSocketEffect` 160, the same ratio to the primary stat as Pawn's built-in MoP Monk scales, so items with a meta socket get credit for it.
  - Cloth, mail and plate ignored (Leather Specialization needs leather in every armour slot).
  - Off-hand frills (held-in-off-hand caster items) ignored for Brewmaster and Windwalker, as in Pawn's own spec templates.
- **No PvP stats.** Pawn has no PvP Power stat in MoP Classic. For PvP gear, compare by hand.

## Hit and expertise caps (important)
**Pawn doesn't know about caps.** It values every point of hit and expertise at the weights above, even after you're capped, where extra points are worth little or nothing. The high hit and expertise weights are only right while you're **below** the cap.

| Cap | Brewmaster | Windwalker | Mistweaver |
|---|---|---|---|
| Hit (melee) | 7.5% = **2,550 hit rating** | 7.5% = **2,550 hit rating** | 7.5%, mostly from Spirit |
| Expertise | 7.5% = **2,550** (dodge cap), up to 15% = **5,100** (parry cap, for attacks from the front) | 7.5% = **2,550 expertise rating** (dodge cap; stand behind the boss) | 7.5%, mostly from Spirit |
| Spell hit (Crackling Jade Lightning) | – | – | 15% |

At level 90, 340 rating = 1% of hit or expertise. Racial bonuses (for example Draenei hit, or weapon expertise racials) lower how much rating you need. Check your current values on the character sheet.

When you're at or over a cap:
- Gem, enchant and reforge **out of** the excess into the next-best stat (Haste for Windwalker, Haste or Crit for Brewmaster).
- In Pawn, lower that scale's Hit or Expertise value (for example to the Mastery value) so Pawn stops favouring items with more of it. Edit it in the scale's **Weights** tab.
- Pawn's Reforging Advisor warns "Use care when reforging Hit or Expertise" for this reason.

## Sources
- WoWSims MoP stat weights (simulation, the main source for the numbers), github.com/wowsims/mop, master as of Oct 13 2026 (commit ec2c6c2552):
  - Brewmaster: [p5_balanced.ep.json](https://github.com/wowsims/mop/blob/master/ui/specs/monk/brewmaster/presets/ep/p5_balanced.ep.json), [p5_offensive.ep.json](https://github.com/wowsims/mop/blob/master/ui/specs/monk/brewmaster/presets/ep/p5_offensive.ep.json)
  - Windwalker: [roro_p5.ep.json](https://github.com/wowsims/mop/blob/master/ui/specs/monk/windwalker/presets/ep/roro_p5.ep.json)
  - Mistweaver: [default.ep.json](https://github.com/wowsims/mop/blob/master/ui/specs/monk/mistweaver/presets/ep/default.ep.json)
  - Stat names follow WoWSims' own Pawn exporter ([pawn_ep.ts](https://github.com/wowsims/mop/blob/master/ui/features/import-export/exporters/pawn_ep.ts)), except `SpellPower` (see above).
- Wowhead stat priority guides (MoP Classic, Phase 5): [Brewmaster](https://www.wowhead.com/mop-classic/guide/classes/monk/brewmaster/tank-stat-priority-pve), [Windwalker](https://www.wowhead.com/mop-classic/guide/classes/monk/windwalker/dps-stat-priority-pve), [Mistweaver](https://www.wowhead.com/mop-classic/guide/classes/monk/mistweaver/healer-stat-priority-pve).
- Pawn source ([VgerMods/Pawn](https://github.com/VgerMods/Pawn), version 2.14, Oct 2026): scale tag format, stat names and Monk spec numbers (`Pawn.lua`, `UIStrings.lua`), the meta socket ratio in its built-in MoP scales (`ClassicHawsJon.lua`), frill handling (`ScaleTemplates.lua`).

## Caveats
- **Not tested in-game.** The tags were checked offline with Pawn's own scale-tag parser and its MoP Classic stat list (see Source below).
- Stat weights shift with gear. These are for current-phase raid gear; fresh level-90 characters are usually far below the hit and expertise caps, where the weights hold up best.
- The Mistweaver weights come from WoWSims' single "Default" healer preset. Healing sims depend on the fight more than DPS sims, so treat the Mistweaver scale as a guide and mind your Haste breakpoints.
- Pawn only scores the stats it reads from tooltips; trinket procs and set bonuses aren't valued.

## Version history
- **v1 (Nov 2 2026):** first release: Brewmaster, Windwalker and Mistweaver scales.

## Source
[source/](source/) has the weights with notes (`scales.lua`), the build script and a check that runs Pawn's own parser on each tag:

```
cd source
lua build.lua
PAWN_SRC=/path/to/Pawn lua verify.lua
```

## License

MIT with an attribution requirement. See the repository [LICENSE](../../../../LICENSE). Credit: Jon Shaw (Schizzle). Stat weights from WoWSims (MIT licence).
