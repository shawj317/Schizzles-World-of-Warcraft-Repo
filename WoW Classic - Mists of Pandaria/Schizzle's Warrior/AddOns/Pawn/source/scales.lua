-- Schizzle's Warrior Pawn scales: the weights, and where each number comes from.
-- Weights are WoWSims MoP stat weights (EP, Strength = 1), from the warrior presets in
-- https://github.com/wowsims/mop (ui/specs/warrior/<spec>/presets/ep/*.ep.json, master as of Nov 1 2026).
-- Stat names follow WoWSims' own Pawn exporter (ui/features/import-export/exporters/pawn_ep.ts):
--   StatAttackPower -> Ap, PseudoStatMainHandDps -> MeleeDps. Pawn has no separate bonus-armor stat.
return {
  {
    file = "Arms Scale.txt", name = "Schizzle's Warrior Arms", spec = 1,
    source = "WoWSims MoP arms/presets/ep/p5.ep.json (\"Item Level >= 560\")",
    values = {
      {"Strength", 1}, {"HitRating", 3.8}, {"ExpertiseRating", 2.83}, {"MeleeDps", 3.54},
      {"CritRating", 0.92}, {"MasteryRating", 0.91}, {"HasteRating", 0.82}, {"Ap", 0.45},
    },
  },
  {
    file = "Fury Scale.txt", name = "Schizzle's Warrior Fury", spec = 2,
    source = "WoWSims MoP fury/presets/ep/p5_tg.ep.json (\"P5 - TG\", Titan's Grip)",
    -- MeleeDps: WoWSims has 2.58 per main-hand DPS and 1.26 per off-hand DPS. Pawn scores each weapon on
    -- its own with one MeleeDps value, so the average of the two hands is used.
    values = {
      {"Strength", 1}, {"HitRating", 3.61}, {"ExpertiseRating", 3.04}, {"MeleeDps", 1.92},
      {"CritRating", 1.86}, {"MasteryRating", 1.28}, {"HasteRating", 0.84}, {"Ap", 0.45}, {"Agility", 0.12},
    },
  },
  {
    file = "Protection Scale.txt", name = "Schizzle's Warrior Protection", spec = 3,
    source = "WoWSims MoP protection/presets/ep/p5.ep.json (\"P5 - Balanced\": survival and threat)",
    values = {
      {"Strength", 1}, {"HitRating", 3.73}, {"ExpertiseRating", 2.58}, {"Stamina", 1.91},
      {"ParryRating", 1.49}, {"DodgeRating", 1.48}, {"CritRating", 1.04}, {"Armor", 0.56},
      {"MasteryRating", 0.36}, {"MeleeDps", 0.35}, {"Ap", 0.25}, {"HasteRating", 0.12},
    },
  },
  -- Added to every scale (not from WoWSims):
  --   Stamina 0.01 on Arms/Fury: a tie-breaker only, the same value Pawn's own starter scales use.
  --   MetaSocketEffect 160: credit for a meta socket's bonus, worth 160 Strength per meta socket, matching the ratio in
  --     Pawn's built-in MoP Warrior scales (16000 against Strength 100, ClassicHawsJon.lua).
  --   IsCloth/IsLeather/IsMail = X: ignore non-plate armour (Plate Specialization needs plate in every armour slot).
  --   IsShield = X on Arms and Fury.
  extras = {
    all = {{"MetaSocketEffect", 160}, {"IsCloth", "X"}, {"IsLeather", "X"}, {"IsMail", "X"}},
    dps = {{"Stamina", 0.01}, {"IsShield", "X"}},
  },
}
