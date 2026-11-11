-- Fixture shared with tools/test_plan.py. Prints machine-readable lines.
local source = debug.getinfo(1, "S").source
if source:sub(1, 1) == "@" then source = source:sub(2) end
local root = source:gsub("tools[\\/]test_plan%.lua$", "") .. "AddOns/SkillLedger/"
dofile(root .. "Plan.lua")
local P = SkillLedgerPlan

local function show(base, steps, expect)
  local got = P.ApplyDiscount(base, steps)
  print(string.format("DISCOUNT %d %d %d", base, steps, got))
end

show(20, 1)
show(20, 2)
show(20, 3)
show(20, 4)
show(10, 1)
show(10, 4)
show(1, 4)

local data = {
  professions = {
    { id = 129, name = "First Aid", secondary = true, gathering = false },
    { id = 164, name = "Blacksmithing", secondary = false, gathering = false },
  },
  items = {
    [2589] = "Linen Cloth",
    [2770] = "Copper Ore",
    [2840] = "Copper Bar",
    [3371] = "Empty Vial",
  },
  vendor = {
    [3371] = {
      price = 20,
      factions = {
        { id = 72, name = "Stormwind", side = "Alliance" },
        { id = 76, name = "Orgrimmar", side = "Horde" },
        { id = 470, name = "Ratchet", side = "Neutral" },
      },
    },
  },
  recipes = {
    { spell = 3275, skill = 129, name = "Linen Bandage", orange = 1, yellow = 30, green = 45, grey = 60, ups = 1, made = 1251, count = 1, reagents = { {2589, 1} }, classMask = 0, raceMask = 0, skillup = true, rankSource = "wowhead" },
    { spell = 3276, skill = 129, name = "Heavy Linen Bandage", orange = 40, yellow = 50, green = 75, grey = 100, ups = 1, made = 2581, count = 1, reagents = { {2589, 2} }, classMask = 0, raceMask = 0, skillup = true, rankSource = "wowhead" },
    { spell = 2657, skill = 186, name = "Smelt Copper", orange = 1, yellow = 25, green = 47, grey = 70, ups = 1, made = 2840, count = 1, reagents = { {2770, 1} }, classMask = 0, raceMask = 0, skillup = true, rankSource = "wowhead" },
    { spell = 2662, skill = 164, name = "Copper Chain Pants", orange = 1, yellow = 1, green = 20, grey = 40, ups = 1, made = 2852, count = 1, reagents = { {2840, 2} }, classMask = 0, raceMask = 0, skillup = true, rankSource = "test" },
  },
}

local plans, shopping = P.PlanCharacter(
  data,
  { [2589] = 10 },
  { { name = "First Aid", skillLine = 129, rank = 1, maxRank = 50 } },
  { [2589] = 100 },
  { [76] = 5, [72] = 8 },
  {},
  "Horde",
  1,
  2,
  {}
)
local plan = plans[1]
print(string.format("TOTAL %d", plan.total))
for i = 1, #plan.steps do
  local step = plan.steps[i]
  print(string.format("STEP %d %d %d %d", step.spell, step.start, step.finish, step.cost))
end

local plans2 = P.PlanCharacter(
  data,
  {},
  { { name = "Blacksmithing", skillLine = 164, rank = 1, maxRank = 4 } },
  { [2770] = 30, [2840] = 100 },
  {},
  {},
  "Horde",
  1,
  2,
  {}
)
local bs = plans2[1]
print(string.format("BS %d %d", bs.steps[1].spell, bs.total))
local joined = table.concat(bs.steps[1].notes, "|")
print("BSNOTE " .. joined)

local plans3 = P.PlanCharacter(
  data,
  {},
  { { name = "Blacksmithing", skillLine = 164, rank = 1, maxRank = 2 } },
  { [2770] = 30, [2840] = 10 },
  { [76] = 5 },
  { [3371] = { unit = 19, factionId = 76, faction = "Orgrimmar", standingId = 5 } },
  "Horde", 1, 2, {}
)
-- captured vial is not on this recipe; the note we want is buying bars
local bs2 = plans3[1]
print("BUYNOTE " .. table.concat(bs2.steps[1].notes, "|"))
