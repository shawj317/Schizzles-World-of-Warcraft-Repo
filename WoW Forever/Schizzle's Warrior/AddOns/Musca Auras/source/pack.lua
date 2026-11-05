-- Schizzle's Warrior Essentials for Musca Auras on WoW Forever, by Jon Shaw (Schizzle).
-- The pack's contents. PackBuilder.lua (GPL-2.0, derived from Musca Auras) turns this into auras; build.lua encodes
-- the import string. Spell IDs are checked against Forever's game data (build 1.60.1.70755) by verify.lua.
--
-- This is a visual helper: it shows what is ready, what is missing and what to press next. It never presses
-- anything for you.
local here = (debug.getinfo(1, "S").source:match("^@(.*[/\\])") or "./")
local Pack = dofile(here .. "PackBuilder.lua")

local VERSION = "1.13"
local battleShout = { 6673, 5242, 6192, 11549, 11550, 11551, 25289 }
local rend = { 772, 6546, 6547, 6548, 11572, 11573, 11574 }
local sunder = { 7386, 7405, 8380, 11596, 11597 }
local thunderClap = { 6343, 8198, 8204, 8205, 11580, 11581 }
local demoShout = { 1160, 6190, 11554, 11555, 11556 }
local hamstring = { 1715, 7372, 7373 }

local SOUND = "Interface\\AddOns\\WeakAuras\\Media\\Sounds\\"
-- The kit's colours (AGENTS.md).
local GREY = { 0.45, 0.45, 0.45, 1 }
local BRONZE = { 0.72, 0.45, 0.2, 1 }
local EMBER = { 1, 0.47, 0, 1 }

-- Stances (form): 1 Battle, 2 Defensive, 3 Berserker. A stance spell shows only in its stance.
return Pack.Build({
  class = "WARRIOR", name = "Warrior Essentials", prefix = "schzWarE1",
  root = "Schizzle's Warrior Essentials v" .. VERSION,
  font = "Fira Sans Condensed Medium",
  -- The group's centre sits at 0,-55 from the middle of the screen. Every row below is measured from there and stays
  -- inside the HUD box (170 px either side, 180 px below to 160 px above the group's centre).
  x = 0, y = -55,
  layout = { range = 140, reminders = 112, procs = 92, effects = 66, target = 40, resourceTop = 26 },
  -- At most 10 icons per aura row: 10 x 30 px with 3 px gaps is 327 px, inside the 340 px box.
  rowLimit = 10,
  reminderSize = 24,
  noTrinkets = false,

  -- What to press, in order. Arms, Fury and Protection load from the tree with the most talent points spent
  -- (from level 10); below level 10 the Starter lane shows instead.
  lanes = {
    { name = "Starter", levelBelow = 10, entries = {
      { name = "Rend", spell = 772, aura = rend, dot = true },
      { name = "Heroic Strike", spell = 78 },
      { name = "Thunder Clap", spell = 6343, form = 1 },
    } },
    { name = "Arms", spec = "WARRIOR_ARMS", level = 10, entries = {
      { name = "Rend", spell = 772, aura = rend, dot = true },
      { name = "Overpower", spell = 7384, form = 1 },
      { name = "Mortal Strike", spell = 12294 },
      { name = "Slam", spell = 1240193 },
      { name = "Execute", spell = 5308 },
      { name = "Victory Rush", spell = 402927 },
      { name = "Sweeping Strikes", spell = 12292, form = 1 },
      { name = "Whirlwind", spell = 1680, form = 3 },
    } },
    { name = "Fury", spec = "WARRIOR_FURY", level = 10, entries = {
      { name = "Bloodthirst", spell = 23881 },
      { name = "Whirlwind", spell = 1680, form = 3 },
      { name = "Execute", spell = 5308 },
      { name = "Victory Rush", spell = 402927 },
      { name = "Slam", spell = 1240193 },
      { name = "Rend", spell = 772, aura = rend, dot = true, form = { 1, 2 } },
    } },
    { name = "Protection", spec = "WARRIOR_PROTECTION", level = 10, entries = {
      { name = "Shield Slam", spell = 23922 },
      { name = "Revenge", spell = 6572, form = 2 },
      { name = "Sunder Armor", spell = 7386, aura = sunder },
      { name = "Shield Block", spell = 2565, form = 2 },
      { name = "Demoralizing Shout", spell = 1160, aura = demoShout },
      { name = "Thunder Clap", spell = 6343, aura = thunderClap, form = 1 },
      { name = "Victory Rush", spell = 402927 },
    } },
  },

  -- Lights up the moment it can be used, with a glow and a sound (v1.0 set). Queued Heroic Strike / Cleave
  -- do not sit here: they put a Pixel glow + main-hand swing swirl on the Main priority icons instead.
  procs = {
    { name = "Overpower", usable = 7384, form = 1, sound = SOUND .. "WaterDrop.ogg" },
    { name = "Revenge", usable = 6572, form = 2, sound = SOUND .. "WaterDrop.ogg" },
    { name = "Execute", usable = 5308, sound = SOUND .. "RobotBlip.ogg" },
    { name = "Victory Rush", usable = 402927, sound = SOUND .. "WaterDrop.ogg" },
  },
  -- Rank-1 IDs; Queued Action matches every rank by name (HS 78..25286, Cleave 845..20569).
  queuedSwing = { 78, 845 },

  -- Major cooldowns and utility, each only in the stance that can use it.
  cooldowns = {
    { name = "Recklessness", spell = 1719, form = 3 },
    { name = "Death Wish", spell = 12328 },
    { name = "Shield Wall", spell = 871, form = 2 },
    { name = "Last Stand", spell = 12975 },
    { name = "Retaliation", spell = 20230, form = 1 },
    { name = "Berserker Rage", spell = 18499, form = 3 },
    { name = "Bloodrage", spell = 2687 },
    { name = "Pummel", spell = 6552, form = 3 },
    { name = "Shield Bash", spell = 72, form = { 1, 2 } },
    { name = "Charge", spell = 100, form = 1 },
    { name = "Intercept", spell = 20252, form = 3 },
    { name = "Intimidating Shout", spell = 5246 },
    { name = "Taunt", spell = 355, form = 2 },
    { name = "Mocking Blow", spell = 694, form = 1 },
    { name = "Challenging Shout", spell = 1161 },
    { name = "Disarm", spell = 676, form = 2 },
    { name = "Concussion Blow", spell = 12809 },
  },

  -- Your buffs while they are up; the last 3 seconds blink red.
  buffs = {
    { name = "Battle Shout", aura = battleShout, remaining = true },
    { name = "Enrage", aura = { 12880 }, known = 12317 },
    { name = "Flurry", aura = { 12966 }, known = 12319 },
    { name = "Blood Craze", aura = { 16488 }, known = 16487 },
    { name = "Bloodrage (active)", aura = { 29131 }, known = 2687 },
    { name = "Shield Block (active)", aura = { 2565 } },
    { name = "Sweeping Strikes (active)", aura = { 12292 } },
    { name = "Death Wish (active)", aura = { 12328 } },
    { name = "Recklessness (active)", aura = { 1719 } },
    { name = "Berserker Rage (active)", aura = { 18499 } },
    { name = "Last Stand (active)", aura = { 12976 }, known = 12975 },
    { name = "Shield Wall (active)", aura = { 871 } },
    { name = "Retaliation (active)", aura = { 20230 } },
  },

  -- Your debuffs on the target, with their time left. Main Rend (v1.12) always shows; greys via Spell Cast
  -- Succeeded self-timer while your Rend is up on the current target (Forever-safe; aura2 cannot see
  -- target debuffs in combat). Target-row Rend tracker stays removed. Pack unloads in classic capitals.
  debuffs = {
    { name = "Sunder Armor", aura = sunder, stacks = true },
    { name = "Thunder Clap", aura = thunderClap },
    { name = "Demoralizing Shout", aura = demoShout },
    { name = "Hamstring", aura = hamstring },
  },

  -- Rage: red as usual, grey below 15 (nothing to spend), bronze from 30 (Heroic Strike or Cleave on top of your
  -- rotation), ember from 60 (dump it before it's wasted).
  power = { { label = "Rage", type = 1, width = 100, height = 14, low = { value = 15, color = GREY }, steps = {
    { value = 30, color = BRONZE },
    { value = 60, color = EMBER },
  } } },
  stance = 2457,
  swing = { "main", "off" },
  meleeRange = { { name = "Sunder Armor", spell = 7386 } },
  reminders = {
    { name = "Battle Shout", aura = battleShout, known = 6673 },
    -- Find Minerals (Mining): Musca Tracking trigger (C_Minimap), inverse = show while off.
    -- Icon + "Track Minerals" under Reminders; OOC, alive, not resting, capitals via pack load.
    { name = "Find Minerals", tracking = 2580, known = 2580, icon = true,
      text = "Track Minerals", label = "Track Minerals", alive = true,
      texture = "Interface\\Icons\\Spell_Nature_Earthquake" },
  },
})
