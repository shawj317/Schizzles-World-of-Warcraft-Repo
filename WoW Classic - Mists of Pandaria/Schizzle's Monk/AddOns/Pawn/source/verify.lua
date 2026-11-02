-- Checks the Schizzle's Monk Pawn scale tags with Pawn's own parser and stat list.
-- Usage (from this folder): lua verify.lua     env: PAWN_SRC (a checkout of github.com/VgerMods/Pawn), OUT_DIR
local HERE = (arg and arg[0] or ""):match("^(.*[/\\])") or "./"
local OUT_DIR = os.getenv("OUT_DIR") or (HERE .. "../")
local PAWN = os.getenv("PAWN_SRC") or "/workspace/pawn-src/"
if PAWN:sub(-1) ~= "/" then PAWN = PAWN .. "/" end
local S = dofile(HERE .. "scales.lua")
local fails, checks = 0, 0
local function check(c, m) checks = checks + 1 if not c then fails = fails + 1 print("FAIL: " .. m) end end
local function readfile(p) local f = assert(io.open(p, "rb")) local s = f:read("*a") f:close() return s end

-- 1. Pawn's stat list as the MoP Classic client builds it (UIStrings.lua, filtered with VgerCore.IsMists)
local any = setmetatable({}, {__index = function(_, k) return tostring(k) end})
local env = setmetatable({PawnLocal = {Stats = any, UI = any}, VgerCore = {IsMists = true}, tinsert = table.insert, pairs = pairs},
  {__index = function(_, k) return "G:" .. k end})
local chunk = assert(loadstring((readfile(PAWN .. "UIStrings.lua"):gsub("^\239\187\191", "")), "UIStrings"))
setfenv(chunk, env)
pcall(chunk) -- only the stat table at the top of the file is needed
local mists = {}
for _, st in ipairs(rawget(env, "PawnStats") or {}) do if st[2] then mists[st[2]] = st end end
check(mists.Agility and mists.Intellect and mists.HitRating and mists.ExpertiseRating, "loaded Pawn's MoP stat list")
check(mists.SpellPower and mists.Spirit and mists.MetaSocketEffect and mists.IsFrill and not mists.SpellDamage, "MoP stat list has SpellPower, Spirit, MetaSocketEffect, IsFrill and no SpellDamage")
check(not mists.Versatility, "stat list is the MoP one (no Versatility)")

-- 2. Pawn's own scale tag parser (Pawn.lua: PawnParseScaleTag ... PawnGetSpecIDFromName)
local src = readfile(PAWN .. "Pawn.lua"):gsub("^\239\187\191", "")
local a = src:find("function PawnParseScaleTag%(")
local b = select(2, src:find("function PawnGetSpecIDFromName.-\nend\n", a))
check(a and b, "found PawnParseScaleTag in Pawn.lua")
local penv = setmetatable({strfind = string.find, gsub = string.gsub, PawnCurrentScaleVersion = 1, PawnIgnoreStatValue = -1000000},
  {__index = _G})
local pchunk = assert(loadstring(src:sub(a, b), "PawnParse"))
setfenv(pchunk, penv) pchunk()
local parse = penv.PawnParseScaleTag

for _, sc in ipairs(S) do
  local tag = readfile(OUT_DIR .. sc.file):gsub("%s+$", "")
  local t = sc.file .. ": "
  check(not tag:find("\n"), t .. "one line")
  local name, values = parse(tag)
  check(name == sc.name, t .. "name parses as " .. sc.name .. " (got " .. tostring(name) .. ")")
  if values then
    check(values.Class == 10, t .. "Class=Monk -> 10")
    check(values.Spec == sc.spec, t .. "Spec -> " .. sc.spec)
    local n = 0
    for k in tag:gmatch("([%a%d]+)%s*=") do if k ~= "Class" and k ~= "Spec" then n = n + 1 check(values[k] ~= nil, t .. k .. " parsed") end end
    for stat, v in pairs(values) do
      if stat ~= "Class" and stat ~= "Spec" then
        check(mists[stat] ~= nil, t .. stat .. " is a MoP Classic Pawn stat")
        check(type(v) == "number", t .. stat .. " numeric")
        if mists[stat] and v == -1000000 then check(mists[stat][4] ~= 2, t .. stat .. " may be ignored") end
      end
    end
    for _, p in ipairs(sc.values) do check(values[p[1]] == p[2], t .. p[1] .. " = " .. p[2]) end
    check(values.IsLeather == nil and values.IsCloth == -1000000 and values.IsMail == -1000000 and values.IsPlate == -1000000, t .. "leather scored, cloth/mail/plate ignored")
    check(values.MetaSocketEffect == 160, t .. "meta socket credit")
    if sc.role == "healer" then
      check(values.Intellect == 1 and values.Agility == nil and values.SpellPower and values.Spirit, t .. "Intellect = 1, caster stats, no Agility")
      check(values.MeleeDps == nil and values.ExpertiseRating == nil and values.IsFrill == nil, t .. "no weapon DPS or expertise; frills usable")
    else
      check(values.Agility == 1 and values.Intellect == nil and values.Spirit == nil and values.SpellPower == nil, t .. "Agility = 1, no caster stats")
      check(values.HitRating > 1 and values.ExpertiseRating > 1, t .. "hit/expertise valued above Agility (below cap)")
      check(values.MeleeDps and values.MeleeDps > 0 and values.IsFrill == -1000000, t .. "weapon DPS valued, frills ignored")
    end
    if sc.role == "tank" then
      check(values.Stamina > 1 and values.ParryRating and values.DodgeRating and values.Armor, t .. "tank stats valued")
    else
      check(values.Stamina == 0.01 and values.ParryRating == nil and values.DodgeRating == nil, t .. "no tank stats")
    end
  end
end
-- quick sanity: Pawn's parser rejects a broken tag
check(parse('( Pawn: v1: "x" )') == nil, "parser rejects a tag with no values")
print(("%d checks, %d failures"):format(checks, fails))
os.exit(fails == 0 and 0 or 1)
