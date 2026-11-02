-- Checks ../Warrior Profile.txt against BetterBlizzFrames' own code (tested on v2.2.0d).
-- Usage (from this folder):  BBF_SRC=/path/to/BetterBlizzFrames WA_TYPES=/path/to/WeakAuras/Types.lua lua verify.lua
local C = dofile("common.lua")
local profile = dofile("profile.lua")
local WA_TYPES = os.getenv("WA_TYPES") or "/workspace/wa2/WeakAuras/Types.lua"

local pass, fail = 0, 0
local function check(ok, what)
  if ok then pass = pass + 1 else fail = fail + 1; print("FAIL: " .. what) end
end
local function same(a, b)
  if a == b then return true end
  if type(a) ~= "table" or type(b) ~= "table" then return false end
  for k, v in pairs(a) do if not same(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end

local str = C.readfile("../Warrior Profile.txt")
BBF.exportDefaults = CopyTable(C.classicsDefaults)

-- 1. Wrapper, exactly as BBF.OldImportProfile checks it
check(str:sub(1, 4) == "!BBF" and str:sub(-4) == "!BBF", "string starts and ends with !BBF")
check(not str:sub(5, -5):find("!"), "no '!' inside (BBF's double-paste check)")
check(not str:find("[\r\n ]"), "one line, no spaces or line breaks")

-- 2. BBF's real decode path (LibDeflate + LibSerialize-BB + shared/ImportExport.lua)
local data, err = BBF.OldImportProfile(str, "fullProfile")
check(data ~= nil and err == nil, "BBF.OldImportProfile(str, 'fullProfile') accepts it: " .. tostring(err))
data = data or {}
check(data.exportVersion == "BBF: " .. C.bbfVersion .. " WoW: " .. C.wowVersion, "exportVersion set by BBF.ExportProfile")
for k, v in pairs(profile) do
  local d = C.classicsDefaults[k]
  if k ~= "version" and d ~= nil and same(v, d) then
    check(data[k] == nil, k .. " equals BBF's default, so the export leaves it out")
  else
    check(same(data[k], v), k .. " survives the round trip")
  end
end
for k in pairs(data) do
  check(profile[k] ~= nil or k == "exportVersion" or k == "skipUpdateMsg", "no unexpected key " .. k)
end
-- The Aura Whitelist import box takes the same string and pulls out just the whitelist
local wl = BBF.OldImportProfile(str, "auraWhitelist")
check(same(wl, profile.auraWhitelist), "Aura Whitelist box: BBF.OldImportProfile(str, 'auraWhitelist') returns the whitelist")
-- Re-export the decoded table with BBF's own export and decode again: same data
BetterBlizzFramesDB = CopyTable(data)
local again = BBF.OldImportProfile(BBF.ExportProfile(BetterBlizzFramesDB, "fullProfile"), "fullProfile")
check(same(again, data), "re-export with BBF.ExportProfile decodes to the same table")

-- 3. Keys are real: in the Mists defaults, or read/written by the Mists (shared/ + classics/) code
local mistsKeys = C.codeKeys(C.mistsFiles())
local foreverKeys = C.codeKeys(C.foreverFiles())
local notInForever = {}
for k, v in pairs(profile) do
  local d = C.classicsDefaults[k]
  check(d ~= nil or mistsKeys[k], k .. " is a BBF Mists setting key")
  if d ~= nil then check(type(d) == type(v), k .. " has the same type as BBF's default (" .. type(d) .. ")") end
  if type(v) ~= "table" and not (C.foreverDefaults[k] ~= nil or foreverKeys[k]) then notInForever[#notInForever + 1] = k end
  if k:lower():find("nameplate") then check(v == false, k .. " is off (Plater owns nameplates)") end
end
for _, k in ipairs{ "unitFrameFontSize", "unitFrameValueFontSize", "partyFrameFontSize", "partyFrameStatusFontSize" } do
  check(type(profile[k]) == "number" and profile[k] >= 6 and profile[k] <= 24, k .. " is in BBF's 6-24 size list")
end

-- 4. Whitelist entries use BBF's current format (classics/gui.lua addOrUpdateEntry, auras.lua GetAuraDetails)
local fields = { name = "string", id = "number", comment = "string", color = "table", important = "boolean",
  pandemic = "boolean", enlarged = "boolean", compacted = "boolean", onlyMine = "boolean" }
for key, e in pairs(profile.auraWhitelist) do
  check(key == e.name:lower(), key .. ": keyed by lowercase name, as BBF does for name entries")
  for f, v in pairs(e) do check(fields[f] == type(v), key .. "." .. f .. " is a BBF whitelist field") end
  check(#e.color == 4, key .. ": colour is {r,g,b,a}")
  for i = 1, 4 do check(type(e.color[i]) == "number" and e.color[i] >= 0 and e.color[i] <= 1, key .. " colour " .. i) end
end

-- 5. Font is the one WeakAuras registers with LibSharedMedia (the same name Plater and Details! use)
local wa = io.open(WA_TYPES) and C.readfile(WA_TYPES)
if wa then
  check(wa:find('LSM:Register("font", "' .. profile.unitFrameFont .. '"', 1, true), "WeakAuras registers " .. profile.unitFrameFont)
else print("skip: WeakAuras Types.lua not found (set WA_TYPES)") end
check(profile.unitFrameFont == profile.unitFrameValueFont and profile.unitFrameFont == profile.partyFrameFont, "one font everywhere")

-- 6. Simulated GUI import (classics/gui.lua Import button, Full Profile box), then a /reload
local db = CopyTable(C.classicsDefaults)
db.darkModeUi, db.targetdeBuffFilterOnlyMe, db.hasSaved, db.someOldGuiOnlyKey = false, false, true, "kept"
db.auraWhitelist["old entry"] = { name = "Old Entry" }
for k in pairs(BBF.exportDefaults) do db[k] = nil end
for k, v in pairs(data) do db[k] = v end
BBF.UseDefaultsUntilReload(db)
for k, v in pairs(profile) do check(same(db[k], v), "after import, " .. k .. " reads as the profile value") end
check(db.darkModeColor == C.classicsDefaults.darkModeColor, "unset keys fall back to BBF defaults")
check(db.auraWhitelist["old entry"] == nil, "import replaces the old whitelist")
check(db.someOldGuiOnlyKey == "kept" and db.hasSaved == true, "keys outside BBF's defaults are left alone (expected BBF behaviour)")
-- InitializeSavedVariables after the reload fills nil keys with defaults; the profile keys stay
local saved = {}
for k, v in pairs(db) do saved[k] = v end -- rawget view of what gets saved
for k, v in pairs(C.classicsDefaults) do if saved[k] == nil then saved[k] = v end end
for k, v in pairs(profile) do check(same(saved[k], v), "after /reload, " .. k .. " is still the profile value") end

-- 7. BBF's own target/focus aura filter (classics/modules/auras.lua ShouldShowBuff, lines 435-602), run on test auras
local src = {}
local n = 0
for line in io.lines(C.src .. "/classics/modules/auras.lua") do
  n = n + 1
  if n >= 435 and n <= 602 then src[#src + 1] = line end
end
check(src[1]:find("local function isInBlacklist", 1, true) and src[#src] == "end", "auras.lua filter block found at the expected lines")
local code = "local BlizzardShouldShowDebuffs = true\nlocal function isMountAura() return false end\n"
  .. table.concat(src, "\n") .. "\nreturn ShouldShowBuff"
local env = setmetatable({ BetterBlizzFramesDB = saved, UnitIsFriend = function() return false end, BBF = { filterOverride = false } }, { __index = _G })
local fn = assert(loadstring(code, "=auras.lua:ShouldShowBuff"))
setfenv(fn, env)
local ShouldShowBuff = fn()
local function aura(name, id, mine, dur)
  return { name = name, spellId = id, duration = dur or 30, expirationTime = 100, sourceUnit = mine and "player" or "raid2", isHarmful = true }
end
for _, unit in ipairs{ "target", "focus" } do
  local function show(a) return ShouldShowBuff(unit, a, unit) end
  local s, imp, pan, enl, _, col = show(aura("Colossus Smash", 86346, true, 6))
  check(s and imp and enl and col[1] == 1 and col[2] == 0.2, unit .. ": my Colossus Smash shows, enlarged, red important glow")
  check(not show(aura("Colossus Smash", 86346, false, 6)), unit .. ": another Warrior's Colossus Smash is hidden")
  s, imp = show(aura("Demoralizing Shout", 1160, false, 10))
  check(s and imp, unit .. ": Demoralizing Shout from anyone shows with the gold important glow")
  s, _, pan = show(aura("Deep Wounds", 115767, true, 15))
  check(s and pan, unit .. ": my Deep Wounds shows with pandemic glow")
  check(not show(aura("Deep Wounds", 115767, false, 15)), unit .. ": someone else's Deep Wounds is hidden")
  for _, w in ipairs{ { "Weakened Armor", 113746 }, { "Weakened Blows", 115798 }, { "Hamstring", 1715 } } do
    s, _, pan = show(aura(w[1], w[2], false, 30))
    check(s and pan, unit .. ": " .. w[1] .. " shows from any source, flagged pandemic")
  end
  check(show(aura("Rend", 772, true, 15)), unit .. ": Rend (Forever) is listed")
  check(show(aura("Mortal Wounds", 115804, false, 10)), unit .. ": Mortal Wounds from anyone shows")
  check(show(aura("Some Boss Debuff", 999001, true, 20)), unit .. ": any debuff you cast shows (Only mine)")
  check(not show(aura("Shadow Word: Pain", 589, false, 18)), unit .. ": other players' unlisted debuffs are hidden")
end

print(("%d passed, %d failed"):format(pass, fail))
if #notInForever > 0 then
  table.sort(notInForever)
  print("note: keys not found in BBF's forever/ code path: " .. table.concat(notInForever, ", "))
else print("note: every setting key is also used by BBF's forever/ code path") end
os.exit(fail == 0 and 0 or 1)
