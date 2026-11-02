-- Schizzle's Monk Pawn scales: the weights, and where each number comes from.
-- Weights are WoWSims MoP stat weights (EP, primary stat = 1), from the monk presets in
-- https://github.com/wowsims/mop (ui/specs/monk/<spec>/presets/ep/*.ep.json, master ec2c6c2552, Oct 13 2026).
-- Stat names follow WoWSims' own Pawn exporter (ui/features/import-export/exporters/pawn_ep.ts):
--   StatAttackPower -> Ap, PseudoStatMainHandDps -> MeleeDps. Two exceptions:
--   StatBonusArmor: Pawn has no separate bonus-armor stat, so only StatArmor is used (WoWSims gives both the same value).
--   StatSpellPower: the exporter writes SpellDamage, but in Pawn's MoP Classic stat list that is "SpellPower"
--     (SpellDamage is a Classic/TBC-only stat), so SpellPower is used.
-- Pawn's Monk spec numbers: 1 = Brewmaster, 2 = Mistweaver, 3 = Windwalker (Pawn.lua SpecNameToIDMap).
return {
  {
    file = "Brewmaster Scale.txt", name = "Schizzle's Monk Brewmaster", spec = 1, role = "tank",
    source = "WoWSims MoP brewmaster/presets/ep/p5_balanced.ep.json (\"P5 - Balanced\": survival and damage)",
    -- MeleeDps: WoWSims has 0.98 per main-hand DPS and 0.47 per off-hand DPS. Pawn scores each weapon on its own
    -- with one MeleeDps value, so the average of the two hands is used (same rule as the Warrior Fury scale).
    values = {
      {"Agility", 1}, {"HitRating", 2.56}, {"ExpertiseRating", 1.56}, {"Stamina", 1.11},
      {"CritRating", 0.85}, {"HasteRating", 0.79}, {"MeleeDps", 0.73}, {"MasteryRating", 0.55},
      {"ParryRating", 0.39}, {"Armor", 0.32}, {"DodgeRating", 0.27}, {"Ap", 0.2},
    },
  },
  {
    file = "Windwalker Scale.txt", name = "Schizzle's Monk Windwalker", spec = 3, role = "dps",
    source = "WoWSims MoP windwalker/presets/ep/roro_p5.ep.json (\"RoRo >= 560\", the current-phase preset)",
    -- MeleeDps: WoWSims has 2.19 per main-hand DPS and 1.10 per off-hand DPS; the average (1.645) rounds to 1.65.
    values = {
      {"Agility", 1}, {"HitRating", 2.46}, {"ExpertiseRating", 2.11}, {"MeleeDps", 1.65},
      {"HasteRating", 1.05}, {"CritRating", 0.83}, {"MasteryRating", 0.39}, {"Ap", 0.34},
    },
  },
  {
    file = "Mistweaver Scale.txt", name = "Schizzle's Monk Mistweaver", spec = 2, role = "healer",
    source = "WoWSims MoP mistweaver/presets/ep/default.ep.json (\"Default\", the only Mistweaver preset)",
    values = {
      {"Intellect", 1}, {"HasteRating", 1}, {"Spirit", 0.9}, {"HitRating", 0.9},
      {"SpellPower", 0.79}, {"CritRating", 0.42}, {"MasteryRating", 0.13},
    },
  },
  -- Added to every scale (not from WoWSims):
  --   MetaSocketEffect 160: credit for a meta socket's bonus, worth 160 of the primary stat per meta socket, matching the
  --     ratio in Pawn's built-in MoP Monk scales (16000 against Agility or Intellect 100, ClassicHawsJon.lua).
  --   IsCloth/IsMail/IsPlate = X: ignore non-leather armour (Leather Specialization needs leather in every armour slot).
  --   Stamina 0.01 on Windwalker and Mistweaver: a tie-breaker only, the same value as the Warrior DPS scales.
  --   IsFrill = X on Brewmaster and Windwalker: held-in-off-hand caster items, which Pawn's own templates mark unusable
  --     for those specs (ScaleTemplates.lua).
  extras = {
    all = {{"MetaSocketEffect", 160}, {"IsCloth", "X"}, {"IsMail", "X"}, {"IsPlate", "X"}},
    nontank = {{"Stamina", 0.01}},
    agility = {{"IsFrill", "X"}},
  },
}
