-- Checks ../Warrior Profile.txt against BetterBlizzPlates' own code (tested on v2.2.3c).
-- Usage (from this folder):  BBP_SRC=/path/to/BetterBlizzPlates WA_TYPES=/path/to/WeakAuras/Types.lua lua verify.lua
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
local keep = { version = true, updates = true, mopUpdated = true } -- part of BBP's exportKeepKeys
local added = { exportVersion = true, classicExport = true, friendlyNameplatesEnabledOnExport = true }

local str = C.readfile("../Warrior Profile.txt")
BBP.exportDefaults = CopyTable(C.classicsDefaults)

-- 1. Wrapper, exactly as BBP.OldImportProfile checks it
check(str:sub(1, 4) == "!BBP" and str:sub(-4) == "!BBP", "string starts and ends with !BBP")
check(not str:sub(5, -5):find("!"), "no '!' inside (BBP's double-paste check)")
check(not str:find("[\r\n ]"), "one line, no spaces or line breaks")

-- 2. BBP's real decode path (LibDeflate + LibSerialize + shared/ImportExport.lua)
local data, err = BBP.OldImportProfile(str, "fullProfile")
check(data ~= nil and err == nil, "BBP.OldImportProfile(str, 'fullProfile') accepts it: " .. tostring(err))
data = data or {}
check(data.exportVersion == "BBP: " .. C.bbpVersion .. " WoW: " .. C.wowVersion, "exportVersion set by BBP.ExportProfile")
check(data.classicExport == true, "marked as a classic (Mists) export")
check(data.retailExport == nil, "not marked retail, so BBP's retail-to-classic fix-up never runs")
for k, v in pairs(profile) do
  local d = C.classicsDefaults[k]
  if not keep[k] and d ~= nil and same(v, d) then
    check(data[k] == nil, k .. " equals BBP's default, so the export leaves it out")
  else
    check(same(data[k], v), k .. " survives the round trip")
  end
end
for k in pairs(data) do
  check(profile[k] ~= nil or added[k], "no unexpected key " .. k)
end
-- The Aura Whitelist import box takes the same string and pulls out just the whitelist
local wl = BBP.OldImportProfile(str, "auraWhitelist")
check(same(wl, profile.auraWhitelist), "Aura Whitelist box: BBP.OldImportProfile(str, 'auraWhitelist') returns the whitelist")
-- Re-export the decoded table with BBP's own export and decode again: same data
BetterBlizzPlatesDB = CopyTable(data)
local again = BBP.OldImportProfile(BBP.ExportProfile(BetterBlizzPlatesDB, "fullProfile"), "fullProfile")
check(same(again, data), "re-export with BBP.ExportProfile decodes to the same table")

-- 3. Keys are real: in the Mists defaults, or read/written by the Mists (shared/ + classics/) code
local mistsKeys = C.codeKeys(C.mistsFiles())
local foreverKeys = C.codeKeys(C.foreverFiles())
local notInForever = {}
for k, v in pairs(profile) do
  local d = C.classicsDefaults[k]
  check(d ~= nil or mistsKeys[k], k .. " is a BBP Mists setting key")
  if d ~= nil then check(type(d) == type(v), k .. " has the same type as BBP's default (" .. type(d) .. ")") end
  if not (C.foreverDefaults[k] ~= nil or foreverKeys[k]) then notInForever[#notInForever + 1] = k end
end
local function rgb(t, n) -- BBP unpacks colour keys as {r, g, b[, a]}
  if type(t) ~= "table" or #t < 3 or #t > 4 then return false end
  for i = 1, #t do if type(t[i]) ~= "number" or t[i] < 0 or t[i] > 1 then return false end end
  return true
end
for k, v in pairs(profile) do
  if k:find("RGB$") or k:find("Color$") and type(v) == "table" then check(rgb(v), k .. " is an {r,g,b[,a]} colour") end
end
check(profile.executeIndicatorThreshold >= 5 and profile.executeIndicatorThreshold <= 100, "execute threshold in the GUI's 5-100 range")
check(profile.castBarHeight >= 4 and profile.castBarHeight <= 36, "castbar height in the GUI's 4-36 range")
check(profile.nameplateEnemyWidth >= 26 and profile.nameplateEnemyWidth <= 200, "enemy width in the GUI's 26-200 range")
check(profile.nameplateGeneralHpHeight >= 4 and profile.nameplateGeneralHpHeight <= 50, "health bar height in the GUI's 4-50 range")
check(profile.nameplateShowClassColor == "1", "nameplateShowClassColor is the CVar string \"1\"")
-- Pummel (6552) is in the classic castbar module's interrupt list, so the interrupt-CD colours track it
local castbar = C.readfile(C.src .. "/classics/modules/castbar.lua")
check(castbar:find("%f[%d]6552%f[%D]"), "Pummel (6552) is in classics/modules/castbar.lua's interrupt spells")
local bbpMain = C.readfile(C.src .. "/classics/BetterBlizzPlates.lua")
check(bbpMain:find('LSM:Register("statusbar", "' .. profile.customTexture .. '"', 1, true), "BBP registers the " .. profile.customTexture .. " texture")

-- 4. Whitelist entries use BBP's format (classics/gui.lua addOrUpdateEntry, auras.lua GetAuraDetails)
local fields = { name = "string", id = "number", comment = "string", flags = "table", entryColors = "table" }
local flagNames = { important = true, pandemic = true, enlarged = true, compacted = true, onlyMine = true }
check(#profile.auraWhitelist == 13, "13 whitelist entries, the same list as the BBF profile")
for i, e in ipairs(profile.auraWhitelist) do
  local n = e.name or ("#" .. i)
  for f, v in pairs(e) do check(fields[f] == type(v), n .. "." .. f .. " is a BBP whitelist field") end
  check(e.id == nil, n .. ": name-only entry, so it matches every spell ID with that name")
  for f, v in pairs(e.flags) do check(flagNames[f] and type(v) == "boolean", n .. ".flags." .. f .. " is a boolean BBP flag") end
  local c = e.entryColors.text
  check(type(c) == "table" and type(c.r) == "number" and type(c.g) == "number" and type(c.b) == "number" and type(c.a) == "number",
    n .. ": glow colour is entryColors.text {r,g,b,a}")
end

-- 5. Font is the one WeakAuras registers with LibSharedMedia (the same name BBF, Plater and Details! use)
local wa = io.open(WA_TYPES) and C.readfile(WA_TYPES)
if wa then
  check(wa:find('LSM:Register("font", "' .. profile.customFont .. '"', 1, true), "WeakAuras registers " .. profile.customFont)
else print("skip: WeakAuras Types.lua not found (set WA_TYPES)") end

-- 6. Simulated GUI import (classics/gui.lua Import button, Full Profile box), then a /reload
local db = CopyTable(C.classicsDefaults)
db.executeIndicator, db.hasSaved, db.someRuntimeKey, db.nameplateFriendlyWidth = false, true, "kept", 150
db.auraWhitelist = { { name = "Old Entry", flags = {} } }
for k in pairs(BBP.exportDefaults) do db[k] = nil end
for k, v in pairs(data) do db[k] = v end
BBP.UseDefaultsUntilReload(db)
for k, v in pairs(profile) do check(same(db[k], v), "after import, " .. k .. " reads as the profile value") end
check(same(db.castBarNoninterruptibleColor, C.classicsDefaults.castBarNoninterruptibleColor), "unset keys fall back to BBP defaults")
check(#db.auraWhitelist == 13 and db.auraWhitelist[1].name == "Colossus Smash", "import replaces the old whitelist")
check(db.someRuntimeKey == "kept" and db.hasSaved == true and db.nameplateFriendlyWidth == 150,
  "keys outside BBP's defaults (runtime and CVar values) are left alone (expected BBP behaviour)")
-- InitializeSavedVariables after the reload fills nil keys with defaults; the profile keys stay
local saved = {}
for k, v in pairs(db) do saved[k] = v end -- rawget view of what gets saved
for k, v in pairs(C.classicsDefaults) do if saved[k] == nil then saved[k] = v end end
for k, v in pairs(profile) do check(same(saved[k], v), "after /reload, " .. k .. " is still the profile value") end
check(not saved.retailExport, "no retailExport after the reload, so TempRetailNpFix is skipped")
-- BBP's own load-time fix-up (classics/BetterBlizzPlates.lua) only fills dpsOrHealTargetAggroColorRGB when nil
check(same(saved.dpsOrHealTargetAggroColorRGB, profile.dpsOrHealTargetAggroColorRGB), "DPS 'targeted' threat colour is set, not filled from the default")

-- 7. BBP's own enemy debuff filter (classics/modules/auras.lua: GetAuraDetails and ShouldShowBuff), run on test auras
local lines = {}
for line in io.lines(C.src .. "/classics/modules/auras.lua") do lines[#lines + 1] = line end
local function block(startPat)
  for i = 1, #lines do
    if lines[i]:find(startPat) then
      for j = i + 1, #lines do
        if lines[j] == "end" then return table.concat(lines, "\n", i, j) end
      end
    end
  end
end
local blocks = { block("^local function isInWhitelist%("), block("^local function isInBlacklist%("),
  block("^local function GetAuraDetails%("), block("^local function ShouldShowBuff%(") }
check(#blocks == 4, "auras.lua: isInWhitelist, isInBlacklist, GetAuraDetails and ShouldShowBuff found")
local code = table.concat(blocks, "\n") .. "\nreturn ShouldShowBuff, GetAuraDetails"
local env = setmetatable({
  BetterBlizzPlatesDB = saved,
  BBP = { GetUnitReaction = function() return true, false, false end },
  UnitCanAttack = function() return true end, UnitIsUnit = function() return false end,
  spellsForAllCata = {}, spellsForAllMoP = {}, keyAuraList = {}, crowdControl = {}, importantBuffs = {},
  IsBreakCCDotAura = function() return false end,
}, { __index = _G })
local fn = assert(loadstring(code, "=auras.lua"))
setfenv(fn, env)
local ShouldShowBuff, GetAuraDetails = fn()
local function aura(name, id, mine, dur)
  return { name = name, spellId = id, duration = dur or 30, expirationTime = 100,
           sourceUnit = mine and "player" or "raid2", isHarmful = true }
end
local function show(a) return ShouldShowBuff("nameplate1", a, false) end
check(show(aura("Colossus Smash", 86346, true, 6)), "my Colossus Smash shows")
local _, imp, _, col, mine, enl = GetAuraDetails("Colossus Smash", 86346)
check(imp and enl and mine and col.r == 1 and col.g == 0.2, "Colossus Smash: important red glow, enlarged, only mine")
check(not show(aura("Colossus Smash", 86346, false, 6)), "another Warrior's Colossus Smash is hidden")
check(show(aura("Demoralizing Shout", 1160, false, 10)), "Demoralizing Shout from anyone shows")
_, imp, _, col = GetAuraDetails("Demoralizing Shout", 1160)
check(imp and col.g == 0.82, "Demoralizing Shout: gold important glow")
check(show(aura("Deep Wounds", 115767, true, 15)), "my Deep Wounds shows")
check(select(3, GetAuraDetails("Deep Wounds", 115767)), "Deep Wounds: pandemic glow")
check(not show(aura("Deep Wounds", 115767, false, 15)), "someone else's Deep Wounds is hidden")
for _, w in ipairs{ { "Weakened Armor", 113746 }, { "Weakened Blows", 115798 }, { "Hamstring", 1715 } } do
  check(show(aura(w[1], w[2], false, 30)) and select(3, GetAuraDetails(w[1], w[2])), w[1] .. " shows from any source, flagged pandemic")
end
check(show(aura("weakened armor", 999999, false, 30)), "names match case-insensitively, whatever the spell ID")
check(show(aura("Rend", 772, true, 15)), "Rend (Forever) is listed")
check(show(aura("Mortal Wounds", 115804, false, 10)), "Mortal Wounds from anyone shows")
check(show(aura("Some Boss Debuff", 999001, true, 20)), "any debuff you cast shows (Only mine)")
check(not show(aura("Shadow Word: Pain", 589, false, 18)), "other players' unlisted debuffs are hidden")

-- 6. Enemy name vs Blizzard's health text (v2). The numbers come from the code that draws them:
-- BBP.RepositionName puts the name's BOTTOM at the bar TOP + fakeNameYPos + 5, and the debuff
-- row (modules/auras.lua) sits at the bar top + 10 + nameplateAurasYPos, icons from 13 px up.
-- Blizzard (Blizzard_NamePlateUnitFrame.lua, 5.5.4) puts the health text's bottom at the bar
-- top + 2 in the Legacy/Thin/focus styles, 12 px font x 1.25 at the Large size.
local bbpMain = C.readfile(C.src .. "/classics/BetterBlizzPlates.lua")
local bbpAuras = C.readfile(C.src .. "/classics/modules/auras.lua")
check(bbpMain:find('frame.name:SetPoint(db.fakeNameAnchor, frame.healthBar.topNameAnchor or frame.healthBar, db.fakeNameAnchorRelative, db.fakeNameXPos, db.fakeNameYPos + 5)', 1, true),
  "BBP anchors the enemy name at fakeNameYPos + 5 above the bar")
check(bbpAuras:find("local yPos = 10 + BetterBlizzPlatesDB.nameplateAurasYPos", 1, true) and bbpAuras:find("verticalOffset - 13", 1, true),
  "BBP's debuff row sits at 10 + nameplateAurasYPos, icons 13 px up")
local d = C.classicsDefaults
check(d.fakeNameAnchor == "BOTTOM" and d.fakeNameAnchorRelative == "TOP" and profile.fakeNameAnchor == nil,
  "name stays centred: BOTTOM of the name on the TOP of the bar")
local healthTop = 2 + 12 * 1.25 + 2 -- bottom offset + Large font + line padding
local nameBottom = profile.fakeNameYPos + 5
local nameTop = nameBottom + 13 * 1.25 -- generous name line height
local iconsBottom = 10 + profile.nameplateAurasYPos + 13
check(nameBottom >= healthTop, ("name bottom (+%d) clears the health text top (+%d)"):format(nameBottom, healthTop))
check(iconsBottom >= nameBottom + 13, "debuff icons keep the same gap above the name as BBP's default")
check(nameBottom - 5 == profile.nameplateAurasYPos, "name and debuff row move up by the same amount")

print(("%d passed, %d failed"):format(pass, fail))
if #notInForever > 0 then
  table.sort(notInForever)
  print("note: keys not found in BBP's forever/ code path: " .. table.concat(notInForever, ", "))
else print("note: every setting key is also used by BBP's forever/ code path") end
os.exit(fail == 0 and 0 or 1)
