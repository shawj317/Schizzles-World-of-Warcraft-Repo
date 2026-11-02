-- Offline test for "Schizzle's Monk Rotation": decodes the export exactly like WeakAuras' Transmission.lua,
-- compiles every custom function inside WeakAuras' real aura sandbox (AuraEnvironment.lua) and runs rotation scenarios
-- against a mocked WoW API. Needs a WeakAuras2 checkout with tests/helpers.lua + tests/wow_stubs.lua (run from that tests dir).
-- Env: WA_TESTS (WeakAuras2 tests dir), WA_LIBS (folder with LibSerialize/ and LibDeflate/), WA_EXPORT (export file).
local HERE = (arg and arg[0] and arg[0]:match("^(.*)/[^/]*$")) or "."
local WA_TESTS = os.getenv("WA_TESTS") or "/workspace/wa2/tests"
local LIBDIR = os.getenv("WA_LIBS") or "/workspace"
local EXPORT = os.getenv("WA_EXPORT") or (HERE .. "/../All-in-One Rotation.txt")
package.path = WA_TESTS .. "/?.lua;" .. package.path
local LibSerialize = dofile(LIBDIR .. "/LibSerialize/LibSerialize.lua")
local LibDeflate = dofile(LIBDIR .. "/LibDeflate/LibDeflate.lua")
local T = require("helpers")
local stubs = require("wow_stubs")
stubs.install()
_G.WeakAuras = stubs.newWeakAuras()
local WeakAuras = _G.WeakAuras
local Private, warnings = stubs.newPrivate()

---------------- decode exactly like Transmission.lua StringToTable ----------------
local f = assert(io.open(EXPORT)) local str = f:read("*a") f:close()
local _, _, encVersion, encoded = str:find("^(!WA:%d+!)(.+)$")
assert(encVersion == "!WA:2!", "header")
local decoded = assert(LibDeflate:DecodeForPrint(encoded), "DecodeForPrint")
local decompressed = assert(LibDeflate:DecompressDeflate(decoded), "DecompressDeflate")
local ok, t = LibSerialize:Deserialize(decompressed)
assert(ok and type(t) == "table", "Deserialize")
assert(t.m == "d" and t.d and t.c and t.v == 1421, "transmit shape")
-- Import(): v < 2000 with children -> controlledChildren from c, child.parent = d.id
local data = t.d
data.controlledChildren = {}
for i, child in ipairs(t.c) do data.controlledChildren[i] = child.id; child.parent = data.id end
print(("decoded OK: group %q, %d children, s=%s, internalVersion=%s, toc=%s"):format(data.id, #t.c, t.s, data.internalVersion, data.tocversion))
local byId = { [data.id] = data }
for _, c in ipairs(t.c) do byId[c.id] = c; print("  child", c.id, c.regionType, "subs=" .. #(c.subRegions or {}), "conds=" .. #(c.conditions or {})) end
WeakAuras.GetData = function(id) return byId[id] end
Private.UIDtoID = function(uid) for id, d in pairs(byId) do if d.uid == uid then return id end end end

---------------- mock WoW API ----------------
local W = {}
local now = 1000
_G.GetTime = function() return now end
_G.UnitPower = function(_, p) if p == 12 then return W.chi end if p == 3 then return W.en end return 0 end
_G.UnitPowerMax = function(_, p) if p == 12 then return W.chiMax end if p == 3 then return 100 end return 0 end
_G.UnitHealth = function() return W.hp end
_G.UnitHealthMax = function() return 100 end
_G.UnitStagger = function() return W.stagger or 0 end
_G.IsPlayerSpell = function(id) return W.known[id] and true or false end
_G.C_SpellBook = { IsSpellKnown = function(id) return W.known[id] and true or false end }
local NAMES = {}
_G.C_Spell = {
  GetSpellName = function(id) return NAMES[id] or ("Spell" .. id) end,
  GetSpellTexture = function(id) return 100000 + id end,
  GetSpellCooldown = function(id) local r = W.cd[id] or (id == 61304 and W.gcd) if r then return { startTime = now - 1, duration = r + 1, isEnabled = true, isOnGCD = false } end return { startTime = 0, duration = 0, isEnabled = true } end,
  GetSpellCharges = function(id) return nil end,
  IsSpellInRange = function(id, unit) if W.oor and W.oor[id] then return false end
    local r = W.range and W.range[id] if r == "oor" then return false elseif r == "nil" then return nil end return true end,
  IsSpellUsable = function(id) if id == 115080 then return W.todUsable and true or false end if W.noMana and W.noMana[id] then return false, true end return true end,
}
_G.C_UnitAuras = { GetAuraDataByIndex = function(unit, i, filter)
  local list = (unit == "player" and filter == "HELPFUL") and W.buffs or (unit == "player") and W.debuffs or (unit == "target") and W.tdebuffs or {}
  local a = list[i]
  if a then return { spellId = a[1], name = NAMES[a[1]] or ("Spell" .. a[1]), expirationTime = now + a[2], duration = 20, applications = a[3] or 0 } end
end }
_G.AuraUtil = { FindAuraByName = function() return nil end }
_G.UnitExists = function(u) if u == "target" then return W.target end return true end
_G.UnitCanAttack = function() return true end
_G.UnitIsDead = function() return false end
_G.UnitIsUnit = function(a, b) return a == b end
_G.UnitAffectingCombat = function() return W.combat end
_G.UnitClassification = function() return W.boss and "worldboss" or "normal" end
-- W.cast = true | { unit=, notInt=, channel=, dur= }
local function castFor(unit)
  local c = W.cast
  if c == true then c = {} end
  if not c then return nil end
  if (c.unit or "target") ~= unit then return nil end
  return c
end
-- legacy name-based range API: 1 / 0 / nil
_G.IsSpellInRange = function(name, unit)
  local id = tonumber((name or ""):match("^Spell(%d+)$"))
  if not id then for k, v in pairs(NAMES) do if v == name then id = k break end end end
  local r = W.range and id and W.range[id]
  if r == "oor" then return 0 elseif r == "nil" then return nil end
  return 1
end
_G.UnitCastingInfo = function(u) local c = castFor(u) if c and not c.channel then
  return "Fireball", "Fireball", 135812, (now - 0.5) * 1000, (now + (c.dur or 2)) * 1000, false, 42, c.notInt and true or false, 133 end end
_G.UnitChannelInfo = function(u) local c = castFor(u) if c and c.channel then
  return "Mind Flay", "Mind Flay", 136208, (now - 0.5) * 1000, (now + (c.dur or 2)) * 1000, false, c.notInt and true or false, 15407 end end
_G.UnitGroupRolesAssigned = function() return W.role or "NONE" end
_G.UnitDetailedThreatSituation = function() return W.tanking end
_G.IsInGroup = function() return W.group end
_G.GetNumShapeshiftForms = function() return W.noForms and 0 or 2 end
_G.GetShapeshiftFormInfo = function(i) local ids = { 115069, 103985 } return nil, W.form == ids[i], true, ids[i] end
_G.GetSpecialization = function() return W.spec end
_G.C_SpecializationInfo = { GetSpecialization = function() return W.spec end }
_G.C_NamePlate = { GetNamePlates = function() local t = {} for i = 1, W.n do t[i] = { namePlateUnitToken = "nameplate" .. i } end return t end }
WeakAuras.CheckRange = function() return true end
-- action slots: { type, id }
SLOTS = { [1] = { "spell", 100780 }, [2] = { "spell", 121253 }, [3] = { "spell", 100787 }, [62] = { "spell", 115203 } }
BINDS = { ACTIONBUTTON1 = "1", ACTIONBUTTON2 = "SHIFT-2", ACTIONBUTTON3 = "CTRL-BUTTON4", MULTIACTIONBAR1BUTTON2 = "ALT-F" }
MACROS = {}
_G.GetActionInfo = function(slot) local a = SLOTS[slot] if a then return a[1], a[2] end end
_G.GetBindingKey = function(b) return BINDS[b] end
_G.GetBonusBarOffset = function() return 0 end
_G.GetMacroSpell = function(m) return MACROS[m] end
BONUS = 0
_G.C_ActionBar = { GetActionBarPage = function() return 1 end, HasBonusActionBar = function() return BONUS > 0 end, GetBonusBarIndex = function() return BONUS end }
-- Blizzard button frames: action = paged slot, bindingAction
local PREF = { {"ActionButton","ACTIONBUTTON",1}, {"MultiBarBottomLeftButton","MULTIACTIONBAR1BUTTON",6}, {"MultiBarBottomRightButton","MULTIACTIONBAR2BUTTON",5},
  {"MultiBarRightButton","MULTIACTIONBAR3BUTTON",3}, {"MultiBarLeftButton","MULTIACTIONBAR4BUTTON",4}, {"MultiBar5Button","MULTIACTIONBAR5BUTTON",13},
  {"MultiBar6Button","MULTIACTIONBAR6BUTTON",14}, {"MultiBar7Button","MULTIACTIONBAR7BUTTON",15} }
BARVIS = { ActionButton = true, MultiBarBottomLeftButton = true, MultiBarBottomRightButton = true }
function layoutButtons()
  for _, p in ipairs(PREF) do for i = 1, 12 do
    local page = p[3]
    if p[1] == "ActionButton" and BONUS > 0 then page = BONUS end
    _G[p[1] .. i] = { action = (page - 1) * 12 + i, bindingAction = p[2] .. i, IsVisible = function() return BARVIS[p[1]] and true or false end }
  end end
end
layoutButtons()

T.loadAddonFile("WeakAuras/AuraEnvironment.lua", "WeakAuras", Private)

---------------- compile every custom function inside the WA sandbox ----------------
local nextData = byId["SMR Next"]
local initFn = assert(WeakAuras.LoadFunction("return function() " .. nextData.actions.init.custom .. "\n end", "SMR Next"))
Private.customActionsFunctions["SMR Next"] = { init = initFn }
local tsu, vars = {}, {}
for _, c in ipairs(t.c) do
  local tr = c.triggers[1].trigger
  tsu[c.id] = assert(WeakAuras.LoadFunction("return " .. tr.custom, c.id), "tsu " .. c.id)
  vars[c.id] = assert(WeakAuras.LoadFunction("return function() return \n" .. tr.customVariables .. "\n end", c.id))()
end
print("sandbox compile OK for init + " .. #t.c .. " TSU + customVariables")

---------------- spell book by level ----------------
local BOOK = { -- id, level, spec (0 = all, 1 = BM, 3 = WW)
  {100780,1,0},{100787,3,0},{103985,1,0},{109132,5,0},{100784,7,0},{115069,10,1},{115180,10,1},{121253,11,1},
  {115546,14,0},{115181,18,1},{101545,18,3},{113656,10,3},{137384,15,3},{115080,22,0},{122470,22,3},
  {115203,24,0},{115072,26,0},{115295,26,1},{116705,32,0},{117967,34,1},{115308,36,1},{115288,36,3},
  {126060,45,1},{101546,46,0},{107428,56,3},{116740,56,3},{119582,75,1},{137639,75,3},
}
local TALENTS = { [30] = 115098, [45] = 115396, [75] = { [1] = 122278, [3] = 122783 }, [90] = { [1] = 123904, [3] = 116847 } }
NAMES[125359] = "Tiger Power"; NAMES[115307] = "Shuffle"; NAMES[115308] = "Elusive Brew"; NAMES[128939] = "Elusive Brew"; NAMES[116740] = "Tigereye Brew"; NAMES[125195] = "Tigereye Brew"
local function book(level, spec)
  local k = {}
  for _, b in ipairs(BOOK) do if b[2] <= level and (b[3] == 0 or b[3] == spec) then k[b[1]] = true end end
  for lv, tl in pairs(TALENTS) do if lv <= level then local id = type(tl) == "table" and tl[spec] or tl if id then k[id] = true end end end
  return k
end

local ORDER = { "SMR Next", "SMR Next+1", "SMR Defensive 1", "SMR Defensive 2", "SMR Cooldown 1", "SMR Cooldown 2", "SMR Resources", "SMR Shuffle",
  "SMR Chi 1/4", "SMR Chi 2/4", "SMR Chi 3/4", "SMR Chi 4/4", "SMR Chi 1/5", "SMR Chi 2/5", "SMR Chi 3/5", "SMR Chi 4/5", "SMR Chi 5/5",
  "SMR Stagger", "SMR Interrupt", "SMR Interrupt Cast", "SMR Defensive 3" }
for i = 1, 8 do if byId["SMR Tray " .. i] then ORDER[#ORDER + 1] = "SMR Tray " .. i end end
local states = {}
for _, id in ipairs(ORDER) do states[id] = {} end
local SN = { [100780]="Jab",[100787]="TigerPalm",[100784]="BlackoutKick",[121253]="KegSmash",[115181]="BreathOfFire",[115072]="ExpelHarm",
  [115080]="TouchOfDeath",[115203]="FortBrew",[115295]="Guard",[115308]="ElusiveBrew",[119582]="PurifyingBrew",[101546]="SCK",[115098]="ChiWave",
  [123904]="Xuen",[116847]="RJW",[107428]="RSK",[113656]="FoF",[116740]="TigereyeBrew",[115288]="EnergizingBrew",[116705]="SpearHand",
  [122470]="TouchOfKarma",[115078]="Paralysis",[119381]="LegSweep",[107079]="QuakingPalm",[20549]="WarStomp",[129597]="ArcaneTorrent",[115069]="SturdyOx",[103985]="FierceTiger",[122278]="DampenHarm",[122783]="DiffuseMagic" }
local function nm(st) if not st or not st.show then return "-" end return (SN[(st.icon or 0) - 100000] or st.name or "?") .. (st.keybind ~= "" and ("[" .. st.keybind .. "]") or "") .. (st.glow and "*" or "") .. ((st.tag or "") ~= "" and ("{" .. st.tag .. "}") or "") .. (st.waiting and "(wait)" or "") .. (st.oorTint and "(OOR-red)" or (st.oor and "(OOR)" or "")) end

local inited = false
local function run(label, sc, expect)
  W = { chi = 0, chiMax = 4, en = 100, hp = 100, buffs = {}, debuffs = {}, tdebuffs = {}, cd = {}, target = true, combat = true,
        n = 1, spec = 1, form = 115069, group = false }
  for k, v in pairs(sc) do W[k] = v end
  W.known = book(W.level, W.spec)
  for id in pairs(sc.addKnown or {}) do W.known[id] = true end
  for id in pairs(sc.removeKnown or {}) do W.known[id] = nil end
  if W.known[115396] and not sc.chiMax then W.chiMax = 5 end
  byId["SMR Next"].config.bmMode = sc.bmMode or 1
  byId["SMR Next"].config.aoe = sc.aoeThreshold or 3
  local cf = byId["SMR Next"].config
  cf.showInt, cf.intCC, cf.intMain, cf.intFocus, cf.tintOOR, cf.tpWindow = true, true, false, false, true, 4
  cf.showTray = true
  for k, v in pairs(sc.cfg or {}) do cf[k] = v end
  -- re-run init each scenario (like editing the aura) so config is picked up
  Private.DeleteAuraEnvironment("SMR Next")
  Private.ActivateAuraEnvironment("SMR Next", nil, nil, nil)
  Private.ActivateAuraEnvironment()
  if not inited then inited = true end
  now = now + 1
  local out = {}
  for _, id in ipairs(ORDER) do
    Private.ActivateAuraEnvironment(id, nil, nil, states[id])
    local ok2, changed = pcall(tsu[id], states[id], "FRAME_UPDATE")
    Private.ActivateAuraEnvironment()
    if not ok2 then print("ERROR in " .. id .. ": " .. tostring(changed)) os.exit(1) end
  end
  local s = states
  local line = ("%-34s Next=%-22s +1=%-16s L=%s,%s R=%s,%s | %s | %s | %s"):format(label, nm(s["SMR Next"][""]), nm(s["SMR Next+1"][""]),
    nm(s["SMR Defensive 1"][""]), nm(s["SMR Defensive 2"][""]), nm(s["SMR Cooldown 1"][""]), nm(s["SMR Cooldown 2"][""]),
    s["SMR Next"][""] and s["SMR Next"][""].show and s["SMR Next"][""].mode or "-", s["SMR Resources"][""] and s["SMR Resources"][""].show and s["SMR Resources"][""].res or "-",
    s["SMR Shuffle"][""] and s["SMR Shuffle"][""].show and "Shuffle bar" or "no shuffle bar")
  local nx = s["SMR Next"][""]
  local got = nx and nx.show and SN[(nx.icon or 0) - 100000] or "-"
  local pips = ""
  for _, m in ipairs({ 4, 5 }) do for n = 1, m do local p = s["SMR Chi " .. n .. "/" .. m][""] if p and p.show then pips = pips .. (p.value == 1 and "o" or ".") end end end
  local it = s["SMR Interrupt"][""]
  if it and it.show then line = line .. " | INT " .. nm(it) .. " cast " .. it.castName end
  local sg = s["SMR Stagger"][""]
  line = line .. " | chi[" .. pips .. "]" .. ((sg and sg.show) and (" stag " .. (sg.heavy and "RED" or sg.moderate and "YEL" or "GRN") .. " " .. sg.pcttext) or "")
  local pass = (expect == nil) or (got == expect)
  if sc.check then local okc, why = sc.check(s) if not okc then pass = false; line = line .. " CHECK FAILED: " .. tostring(why) end end
  print((pass and "PASS " or "FAIL ") .. line .. (expect and (" (expect " .. expect .. ")") or ""))
  return pass
end

local function noKeg(s) for _, id in ipairs({ "SMR Next", "SMR Next+1" }) do local st = s[id][""] if st and st.show and st.icon == 100000 + 121253 then return false end end return true end
local P, F = 0, 0
local function R(...) if run(...) then P = P + 1 else F = F + 1 end end
local TP = { 125359, 15 }
local TPlow = { 125359, 2 }
local SH = { 115307, 10 }
print("\n== Brewmaster ==")
R("BM16 0chi no TP", { level = 16, chi = 0, en = 100 }, "KegSmash")
R("BM16 2chi no TP keg cd (reported case)", { level = 16, chi = 2, en = 60, cd = { [121253] = 5 } }, "TigerPalm")
R("BM16 2chi TP up keg cd", { level = 16, chi = 2, en = 60, buffs = { TP }, cd = { [121253] = 5 } }, "BlackoutKick")
R("BM16 0chi TP up 30en keg cd", { level = 16, chi = 0, en = 30, buffs = { TP }, cd = { [121253] = 5 } }, "KegSmash")
R("BM16 1chi TP up 80en keg cd", { level = 16, chi = 1, en = 80, buffs = { TP }, cd = { [121253] = 5 } }, "Jab")
R("BM26 hp60 0chi keg cd", { level = 26, chi = 0, en = 60, hp = 60, buffs = { TP }, cd = { [121253] = 5 }, bmMode = 2 }, "ExpelHarm")
R("BM26 dps tod usable", { level = 26, chi = 3, en = 60, buffs = { TP }, todUsable = true, cd = { [121253] = 5 } }, "BlackoutKick")
R("BM34 tank no shuffle 2chi", { level = 34, chi = 2, en = 100, buffs = { TP }, bmMode = 2 }, "BlackoutKick")
R("BM34 tank shuffle up 0chi", { level = 34, chi = 0, en = 100, buffs = { TP, SH }, bmMode = 2 }, "KegSmash")
R("BM34 AoE5 2chi shuffle", { level = 34, chi = 2, en = 30, n = 5, buffs = { TP, { 115307, 9 } }, cd = { [121253] = 5 }, bmMode = 2 }, "BreathOfFire")
R("BM60 auto solo -> DPS", { level = 60, chi = 4, en = 50, buffs = { TP, SH }, cd = { [121253] = 5 } }, "BlackoutKick")
R("BM60 auto grp tank heavy stag", { level = 60, chi = 3, en = 50, group = true, role = "TANK", buffs = { TP, SH, { 128939, 12, 12 } }, debuffs = { { 124273, 5 } }, hp = 35, cd = { [121253] = 5 } }, nil)
R("BM60 DPS forced AoE4", { level = 60, chi = 1, en = 80, n = 4, buffs = { TP, SH }, cd = { [121253] = 5 }, bmMode = 3 }, "SCK")
R("BM90 tank full", { level = 90, chi = 1, en = 100, bmMode = 2, buffs = { TP, SH, { 118636, 10 } }, debuffs = { { 124274, 5 } }, boss = true, cast = true, todUsable = true }, "KegSmash")
R("BM90 tank wait", { level = 90, chi = 1, en = 10, bmMode = 2, buffs = { TP, SH }, cd = { [121253] = 4, [115098] = 5, [115072] = 5, [123904] = 60 } }, "TigerPalm")
R("BM90 EB active -> no EB pop", { level = 90, chi = 1, en = 10, bmMode = 2, buffs = { TP, SH, { 115308, 5 }, { 128939, 20, 14 } }, cd = { [121253] = 4, [115098] = 5 } }, "TigerPalm")
R("BM90 tank-lock in Tiger: no Ox on main", { level = 90, chi = 1, en = 10, bmMode = 2, form = 103985, buffs = { TP, SH },
  check = function(s) local l = s["SMR Defensive 1"][""] return l and l.show and l.icon == 100000 + 115069 and not l.glow and s["SMR Next"][""].mode == "TANK" and noKeg(s), "quiet Ox side icon" end }, "ChiWave")
print("\n== Windwalker ==")
R("WW16 0chi", { level = 16, spec = 3, form = 103985, chi = 0, en = 100 }, "Jab")
R("WW16 1chi no TP", { level = 16, spec = 3, form = 103985, chi = 1, en = 100 }, "TigerPalm")
R("WW16 3chi TP up 40en", { level = 16, spec = 3, form = 103985, chi = 3, en = 40, buffs = { TP } }, "FoF")
R("WW26 2chi TP up hp80", { level = 26, spec = 3, form = 103985, chi = 2, en = 100, hp = 80, buffs = { TP }, cd = { [113656] = 10 } }, "ExpelHarm")
R("WW34 CB BoK proc", { level = 34, spec = 3, form = 103985, chi = 0, en = 50, buffs = { TP, { 116768, 10 } }, cd = { [113656] = 10, [115072] = 5 } }, "BlackoutKick")
R("WW60 RSK debuff missing", { level = 60, spec = 3, form = 103985, chi = 2, en = 60, buffs = { TP } }, "RSK")
R("WW60 TEB 10 stacks", { level = 60, spec = 3, form = 103985, chi = 0, en = 20, buffs = { TP, { 125195, 30, 10 } }, tdebuffs = { { 130320, 10 } }, cd = { [107428] = 5, [113656] = 10, [115072] = 5, [115098] = 8 } }, "Jab")
R("WW90 AoE5", { level = 90, spec = 3, form = 103985, chi = 3, en = 80, n = 5, buffs = { TP }, tdebuffs = { { 130320, 10 } }, cd = { [107428] = 5 } }, "RJW")
R("WW90 wrong stance", { level = 90, spec = 3, form = 115069, chi = 3, en = 80 }, "FierceTiger")
R("WW90 no target out of combat", { level = 90, spec = 3, form = 103985, target = false, combat = false }, "-")
print("\n== v2: GCD swipe / waiting / pips / stagger ==")
local function nx(s) return s["SMR Next"][""] end
R("GCD active -> desat + GCD swipe", { level = 16, chi = 2, en = 60, gcd = 0.6, cd = { [121253] = 5 },
  check = function(s) local st = nx(s) return st.waiting and st.duration > 0 and math.abs(st.expirationTime - (now + 0.6)) < 1e-6, "waiting/gcd" end }, "TigerPalm")
R("No GCD -> full colour", { level = 16, chi = 2, en = 60, cd = { [121253] = 5 },
  check = function(s) local st = nx(s) return (not st.waiting) and st.duration == 0, "not waiting" end }, "TigerPalm")
R("Own CD longer than GCD -> CD swipe", { level = 90, chi = 1, en = 10, bmMode = 2, buffs = { TP, SH }, gcd = 0.5, cd = { [121253] = 4, [115098] = 5, [115072] = 5, [123904] = 60 },
  check = function(s) local a, b = nx(s), s["SMR Next+1"][""]
    return math.abs(a.expirationTime - (now + 0.5)) < 1e-6 and math.abs(b.expirationTime - (now + 4)) < 1e-6 and b.waiting, "gcd vs own cd" end }, "TigerPalm")
R("Not enough energy -> desat", { level = 16, chi = 2, en = 60, cd = { [121253] = 5 }, noMana = { [100787] = true },
  check = function(s) return nx(s).waiting, "noMana waiting" end }, "TigerPalm")
R("Chi pips 2/4", { level = 16, chi = 2, en = 60, cd = { [121253] = 5 },
  check = function(s) local a, d, e = s["SMR Chi 2/4"][""], s["SMR Chi 3/4"][""], s["SMR Chi 1/5"][""]
    return a.show and a.value == 1 and d.show and d.value == 0 and not (e and e.show), "pips" end }, nil)
R("Chi pips 5/5 Ascension", { level = 60, spec = 3, form = 103985, chi = 5, en = 60, buffs = { TP },
  check = function(s) local e, f = s["SMR Chi 5/5"][""], s["SMR Chi 1/4"][""] return e and e.show and e.value == 1 and not (f and f.show), "pip5" end }, nil)
R("Stagger moderate -> yellow", { level = 34, chi = 0, en = 100, buffs = { TP, SH }, bmMode = 2, debuffs = { { 124274, 5 } }, stagger = 30,
  check = function(s) local g = s["SMR Stagger"][""] return g and g.show and g.moderate and not g.heavy and g.value == 30, "stagger" end }, nil)

print("\n== v3: stance ==")
R("BM34 Auto in Tiger opener -> DPS, no Ox spells", { level = 34, form = 103985, chi = 0, en = 100,
  check = function(s) return s["SMR Next"][""].mode == "DPS" and noKeg(s), "mode/keg" end }, "TigerPalm")
R("BM34 Auto Tiger TP up 0chi -> Chi Wave, then Jab", { level = 34, form = 103985, chi = 0, en = 100, buffs = { TP },
  check = function(s) return noKeg(s) and s["SMR Next+1"][""].icon == 100000 + 100780, "keg/jab" end }, "ChiWave")
R("BM34 Auto Tiger 3chi -> Jab not overcapped (2 Chi)", { level = 34, form = 103985, chi = 3, en = 100, buffs = { TP }, cd = { [115098] = 5 }, removeKnown = { [100784] = true },
  check = function(s) local n = s["SMR Next"][""] return n.icon ~= 100000 + 100780 or n.waiting, "jab at 3/4 chi in tiger" end }, nil)
R("BM60 Auto Tiger grouped TANK w/ threat -> DPS", { level = 60, form = 103985, chi = 2, en = 60, group = true, role = "TANK", tanking = true, buffs = { TP, SH },
  check = function(s) local l = s["SMR Defensive 1"][""] return s["SMR Next"][""].mode == "DPS" and not (l and l.show), "dps, no ox nag" end }, "BlackoutKick")
R("BM60 Auto Ox grouped TANK -> TANK", { level = 60, form = 115069, chi = 0, en = 100, group = true, role = "TANK", buffs = { TP, SH },
  check = function(s) return s["SMR Next"][""].mode == "TANK", "tank" end }, "KegSmash")
R("BM60 Tank-lock Tiger + threat -> Ox side glows", { level = 60, form = 103985, chi = 0, en = 100, bmMode = 2, tanking = true, buffs = { TP, SH },
  check = function(s) local l = s["SMR Defensive 1"][""] return l and l.icon == 100000 + 115069 and l.glow and noKeg(s), "ox glow" end }, nil)
R("BM34 stance via aura fallback (no stance bar)", { level = 34, noForms = true, form = nil, buffs = { TP, { 103985, 3600 } }, chi = 0, en = 100,
  check = function(s) return noKeg(s), "aura fallback" end }, "ChiWave")
R("WW90 Tiger: no stance nag", { level = 90, spec = 3, form = 103985, chi = 2, en = 60, buffs = { TP } }, "RSK")

print("\n== v3: interrupts ==")
local function intIs(s, sid) local it = s["SMR Interrupt"][""] if sid == nil then return not (it and it.show) end
  return it and it.show and it.icon == 100000 + sid and it.duration > 0 and it.expirationTime > now, "int" end
R("SHS ready, interruptible cast", { level = 60, chi = 1, en = 60, buffs = { TP, SH }, cast = true, check = function(s) return intIs(s, 116705) end }, nil)
R("SHS on CD -> Paralysis", { level = 60, chi = 1, en = 60, buffs = { TP, SH }, cast = true, cd = { [116705] = 10 }, addKnown = { [115078] = true },
  check = function(s) return intIs(s, 115078) end }, nil)
R("SHS out of range -> Leg Sweep", { level = 60, chi = 1, en = 60, buffs = { TP, SH }, cast = true, oor = { [116705] = true }, addKnown = { [119381] = true },
  check = function(s) return intIs(s, 119381) end }, nil)
R("Channel interruptible", { level = 60, chi = 1, en = 60, buffs = { TP, SH }, cast = { channel = true }, check = function(s) return intIs(s, 116705) end }, nil)
R("Uninterruptible cast -> nothing", { level = 60, chi = 1, en = 60, buffs = { TP, SH }, cast = { notInt = true }, check = function(s) return intIs(s, nil), "none" end }, nil)
R("Nothing known -> nothing", { level = 20, chi = 1, en = 60, buffs = { TP }, cast = true, check = function(s) return intIs(s, nil), "none" end }, nil)
R("SHS cd, CC fallback off -> nothing", { level = 60, chi = 1, en = 60, buffs = { TP, SH }, cast = true, cd = { [116705] = 10 }, addKnown = { [115078] = true },
  cfg = { intCC = false }, check = function(s) return intIs(s, nil), "none" end }, nil)
R("Pandaren Quaking Palm fallback", { level = 60, chi = 1, en = 60, buffs = { TP, SH }, cast = true, cd = { [116705] = 10 }, addKnown = { [107079] = true },
  check = function(s) return intIs(s, 107079) end }, nil)
R("Interrupt in main icon option", { level = 60, chi = 1, en = 60, buffs = { TP, SH }, cast = true, cfg = { intMain = true },
  check = function(s) return intIs(s, nil), "dedicated hidden" end }, "SpearHand")
R("Focus cast (option on)", { level = 60, chi = 1, en = 60, buffs = { TP, SH }, cast = { unit = "focus" }, cfg = { intFocus = true },
  check = function(s) return intIs(s, 116705) end }, nil)
R("Focus cast (option off) -> nothing", { level = 60, chi = 1, en = 60, buffs = { TP, SH }, cast = { unit = "focus" },
  check = function(s) return intIs(s, nil), "none" end }, nil)

print("\n== v4: range ==")
local function vis(st) return st.waiting or st.oor, st.oorTint end -- desaturated?, tinted?
local base = { level = 16, chi = 2, en = 60, cd = { [121253] = 5 } } -- Next = Tiger Palm
local function sc(extra) local t = {} for k, v in pairs(base) do t[k] = v end for k, v in pairs(extra) do t[k] = v end return t end
R("in range + ready -> full colour", sc({ check = function(s) local d, t = vis(nx(s)) return not d and not t, "colour" end }), "TigerPalm")
R("out of range -> desat + red tint", sc({ range = { [100787] = "oor" }, check = function(s) local st = nx(s) return st.oor and st.oorTint, "oor" end }), "TigerPalm")
R("out of range, tint option off -> desat only", sc({ range = { [100787] = "oor" }, cfg = { tintOOR = false }, check = function(s) local st = nx(s) return st.oor and not st.oorTint, "no tint" end }), "TigerPalm")
R("GCD + in range -> grey, no tint", sc({ gcd = 0.6, check = function(s) local st = nx(s) return st.waiting and not st.oor and not st.oorTint, "grey" end }), "TigerPalm")
R("nil range (API nil) -> in range", sc({ range = { [100787] = "nil" }, check = function(s) local st = nx(s) return not st.oor, "nil" end }), "TigerPalm")
R("no target (in combat) -> no tint", sc({ target = false, range = { [100787] = "oor" }, check = function(s) local st = nx(s) return st and st.show and not st.oor and not st.oorTint, "no target" end }), "TigerPalm")
R("self spell (Fort Brew side icon) ignores range", { level = 60, chi = 1, en = 60, hp = 30, buffs = { TP, SH }, range = { [115203] = "oor" },
  check = function(s) for i = 1, 3 do local st = s["SMR Defensive " .. i][""] if st and st.show and st.icon == 100000 + 115203 then return not st.oor, "fort" end end return false, "no fort" end }, nil)
R("Breath of Fire uses 8yd melee check", { level = 34, chi = 2, en = 30, n = 5, buffs = { TP, { 115307, 9 } }, cd = { [121253] = 5 }, bmMode = 2, range = { [115181] = "oor" },
  check = function(s) return not nx(s).oor, "bof melee" end }, "BreathOfFire")
R("Next+1 out of range tinted", sc({ range = { [100784] = "oor" }, check = function(s) local st = s["SMR Next+1"][""] return st.oorTint and not nx(s).oor, "next2" end }), "TigerPalm")
R("interrupt icon carries range flags", { level = 60, chi = 1, en = 60, buffs = { TP, SH }, cast = true,
  check = function(s) local it = s["SMR Interrupt"][""] return it and it.show and it.oor == false, "int" end }, nil)

print("\n== v4: Tiger Palm audit ==")
local getPM2 = WeakAuras.LoadFunction("return function() return SchizzleMonk end", "SMR Next")
local function tpIn(s) local r = {} for _, id in ipairs({ "SMR Next", "SMR Next+1" }) do local st = s[id][""] if st and st.show and st.icon == 100000 + 100787 then r[#r + 1] = id .. ":" .. (st.tag or "") end end return table.concat(r, ",") end
local function whyMain() local E = getPM2() return E and E.R and E.R.why and E.R.why.main or "" end
R("BrM TP 8s, 2 Chi -> BoK, TP only as tagged filler", { level = 34, chi = 2, en = 60, buffs = { { 125359, 8 } }, cd = { [121253] = 5, [115098] = 5 },
  check = function(s) local t = tpIn(s) return (t == "" or t:find("filler")) and not t:find("refresh"), t end }, "BlackoutKick")
R("BrM TP 4.1s, no Energy -> filler (not refresh)", { level = 34, chi = 0, en = 30, buffs = { { 125359, 4.1 } }, cd = { [121253] = 5, [115098] = 5 },
  check = function(s) local n = nx(s) return n.tag == "filler" and whyMain():find("filler") ~= nil, whyMain() end }, "TigerPalm")
R("BrM TP 3.9s -> refresh", { level = 34, chi = 0, en = 30, buffs = { { 125359, 3.9 } }, cd = { [121253] = 5, [115098] = 5 },
  check = function(s) local n = nx(s) return n.tag == "refresh" and whyMain():find("refresh") ~= nil, whyMain() end }, "TigerPalm")
R("BrM TP 5s, window option 6 -> refresh", { level = 34, chi = 0, en = 30, buffs = { { 125359, 5 } }, cd = { [121253] = 5, [115098] = 5 }, cfg = { tpWindow = 6 },
  check = function(s) return nx(s).tag == "refresh", "window" end }, "TigerPalm")
R("BrM pre-34 TP 8s, 1 Chi, nothing else -> TP filler", { level = 16, chi = 1, en = 30, buffs = { { 125359, 8 } }, cd = { [121253] = 5 },
  check = function(s) return nx(s).tag == "filler" and whyMain():find("pre%-34") ~= nil, whyMain() end }, "TigerPalm")
R("BrM pre-34 TP 8s, 2 Chi -> Blackout Kick, no TP", { level = 16, chi = 2, en = 30, buffs = { { 125359, 8 } }, cd = { [121253] = 5 },
  check = function(s) return tpIn(s) == "", tpIn(s) end }, "BlackoutKick")
R("BrM pre-34 TP 8s, 1 Chi, Jab usable -> Jab first", { level = 16, chi = 1, en = 80, buffs = { { 125359, 8 } }, cd = { [121253] = 5 },
  check = function(s) return not tpIn(s):find("Next:"), tpIn(s) end }, "Jab")
R("BrM pre-34 TP 3.9s, 1 Chi -> refresh tag", { level = 16, chi = 1, en = 30, buffs = { { 125359, 3.9 } }, cd = { [121253] = 5 },
  check = function(s) return nx(s).tag == "refresh", whyMain() end }, "TigerPalm")
R("WW TP 8s, 1 Chi, nothing else -> no TP filler", { level = 60, spec = 3, form = 103985, chi = 1, en = 20, buffs = { { 125359, 8 } }, tdebuffs = { { 130320, 10 } }, cd = { [107428] = 5, [113656] = 10, [115098] = 5, [115072] = 5 },
  check = function(s) return tpIn(s) == "", tpIn(s) end }, nil)
R("BrM TP 8s, Keg ready -> Keg, no TP refresh", { level = 34, chi = 0, en = 80, buffs = { { 125359, 8 } },
  check = function(s) return not tpIn(s):find("refresh"), tpIn(s) end }, "KegSmash")
R("WW TP 8s, no proc -> no Tiger Palm", { level = 60, spec = 3, form = 103985, chi = 2, en = 60, buffs = { { 125359, 8 } }, tdebuffs = { { 130320, 10 } }, cd = { [107428] = 5, [113656] = 10 },
  check = function(s) return tpIn(s) == "", tpIn(s) end }, nil)
R("WW TP 4.1s -> no refresh yet", { level = 60, spec = 3, form = 103985, chi = 2, en = 60, buffs = { { 125359, 4.1 } }, tdebuffs = { { 130320, 10 } }, cd = { [107428] = 5, [113656] = 10 },
  check = function(s) return tpIn(s) == "", tpIn(s) end }, nil)
R("WW TP 3.9s -> refresh", { level = 60, spec = 3, form = 103985, chi = 2, en = 60, buffs = { { 125359, 3.9 } }, tdebuffs = { { 130320, 10 } }, cd = { [107428] = 5, [113656] = 10 },
  check = function(s) return nx(s).tag == "refresh", whyMain() end }, "TigerPalm")
R("WW TP 8s + Combo Breaker TP proc -> proc tag", { level = 60, spec = 3, form = 103985, chi = 0, en = 20, buffs = { { 125359, 8 }, { 118864, 10 } }, tdebuffs = { { 130320, 10 } }, cd = { [107428] = 5, [113656] = 10, [115098] = 5, [115072] = 5 },
  check = function(s) return nx(s).tag == "proc" and whyMain():find("Combo Breaker") ~= nil, whyMain() end }, "TigerPalm")
do local E = getPM2() print("     /dump SchizzleMonk.R.why -> main=" .. tostring(E.R.why.main) .. " | " .. tostring(E.R.why.tigerPower) .. " | " .. tostring(E.R.why.mode)) end

print("\n== v5.2: cooldown tray ==")
local function trayIds(st)
  local ids, gap = {}, false
  for i = 1, 8 do local x = st["SMR Tray " .. i] and st["SMR Tray " .. i][""]
    if x and x.show then if gap then return false end ids[#ids + 1] = x.icon - 100000 else gap = true end end
  return ids
end
local function trayIs(want) return function(st) local ids = trayIds(st) if not ids then return false, "not packed" end
  local g = table.concat(ids, ",") return g == table.concat(want, ","), "tray=" .. g end end
local function trayHas(id, yes) return function(st) local ids = trayIds(st) if not ids then return false, "not packed" end
  local f = false for _, v in ipairs(ids) do if v == id then f = true end end return f == yes, "tray=" .. table.concat(ids, ",") end end
local function all(...) local fs = { ... } return function(st) for _, fn in ipairs(fs) do local ok, w = fn(st) if not ok then return false, w end end return true end end
R("T1 BM90 Orc: Blood Fury, Fortifying, Dampen Harm, Xuen", { level = 90, chi = 0, en = 100, buffs = { TP, SH }, addKnown = { [33697] = true },
  check = trayIs({ 33697, 115203, 122278, 123904 }) }, nil)
R("T2 BM90 boss: Xuen on the right, not in the tray", { level = 90, chi = 0, en = 100, boss = true, buffs = { TP, SH },
  check = all(trayHas(123904, false), trayHas(115203, true)) }, nil)
R("T3 BM90 hp 30: Fortifying + Dampen on the left, not in the tray", { level = 90, chi = 0, en = 100, hp = 30, buffs = { TP, SH },
  check = all(trayHas(115203, false), trayHas(122278, false)) }, nil)
R("T4 BM90 Fortifying on cooldown -> hidden", { level = 90, chi = 0, en = 100, buffs = { TP, SH }, cd = { [115203] = 120 },
  check = trayIs({ 122278, 123904 }) }, nil)
R("T5 BM90 + Zen, Avert, Leg Sweep, Ring, Tiger's Lust, Stoneform -> max 8, racial first", { level = 90, chi = 0, en = 100, buffs = { TP, SH },
  addKnown = { [20594] = true, [115176] = true, [115213] = true, [119381] = true, [116844] = true, [116841] = true },
  check = trayIs({ 20594, 115203, 122278, 115176, 115213, 123904, 119381, 116844 }) }, nil)
R("T6 WW90: Touch of Karma, Fortifying, Energizing Brew, Diffuse Magic (no Tigereye Brew)", { level = 90, spec = 3, form = 103985, chi = 0, en = 100, buffs = { TP },
  check = trayIs({ 122470, 115203, 115288, 122783 }) }, nil)
R("T7 WW90 Touch of Karma on cooldown -> hidden", { level = 90, spec = 3, form = 103985, chi = 0, en = 100, buffs = { TP }, cd = { [122470] = 60 },
  check = trayIs({ 115203, 115288, 122783 }) }, nil)
R("T8 WW90 energy 20: Energizing Brew on the right, not in the tray", { level = 90, spec = 3, form = 103985, chi = 0, en = 20, buffs = { TP },
  check = trayIs({ 122470, 115203, 122783 }) }, nil)
R("T9 WW90 Pandaren Quaking Palm", { level = 90, spec = 3, form = 103985, chi = 0, en = 100, buffs = { TP }, addKnown = { [107079] = true },
  check = trayIs({ 107079, 122470, 115203, 115288, 122783 }) }, nil)
R("T10 BM16: nothing learned yet -> empty", { level = 16, chi = 0, en = 100, check = trayIs({}) }, "KegSmash")
R("T11 out of combat, no target -> hidden", { level = 90, spec = 3, form = 103985, target = false, combat = false, check = trayIs({}) }, "-")
R("T12 Show cooldown tray off -> empty", { level = 90, chi = 0, en = 100, buffs = { TP, SH }, cfg = { showTray = false }, check = trayIs({}) }, nil)
R("T13 tray icons: full colour, no glow, no timer", { level = 90, chi = 0, en = 100, buffs = { TP, SH }, check = function(st)
  local x = st["SMR Tray 1"][""] return x and x.show and not x.waiting and not x.glow and x.duration == 0, "flags" end }, nil)

print("\n== v2: keybinds ==")
local getPM = WeakAuras.LoadFunction("return function() return SchizzleMonk end", "SMR Next")
local function keyOf(sc, expect, label, setup)
  local SchizzleMonk = getPM()
  setup(); layoutButtons(); if SchizzleMonk then SchizzleMonk.keysAt = -99 end
  local st
  R(label, sc, nil)
  st = states["SMR Next"][""]
  local k = st and st.keybind
  SchizzleMonk = getPM()
  local ks = SchizzleMonk.keysrc and SchizzleMonk.keysrc["Tiger Palm"]
  print(("     Next keybind=%s expect=%s  keysrc: key=%s src=%s"):format(tostring(k), expect, tostring(ks and ks.key), tostring(ks and ks.src)))
  if ks then for _, a in ipairs(ks.all) do print("       cand " .. a) end end
  if k == expect then P = P + 1 else F = F + 1; print("FAIL keybind") end
end
NAMES[100787] = "Tiger Palm"; NAMES[100780] = "Jab"
local TPsc = { level = 16, chi = 2, en = 60, cd = { [121253] = 5 } }
keyOf(TPsc, "CM4", "K0 TP direct on ActionButton3", function() BONUS = 0 end)
keyOf(TPsc, "A3", "K1 macro on bar1 vs spell on BottomLeft", function()
  MACROS = { [7] = 100787 }; SLOTS = { [3] = { "macro", 7 }, [63] = { "spell", 100787 } }; BINDS.MULTIACTIONBAR1BUTTON3 = "ALT-3" end)
keyOf(TPsc, "F", "K2 stance bonus bar hides page-1 TP; TP on MultiBar5", function()
  BONUS = 7; BARVIS.MultiBar5Button = true; MACROS = {}
  SLOTS = { [3] = { "spell", 100787 }, [75] = { "spell", 100780 }, [145] = { "spell", 100787 } }; BINDS.MULTIACTIONBAR5BUTTON1 = "F" end)
keyOf(TPsc, "A3", "K3 rank/override ID matched by name", function()
  BONUS = 0; NAMES[999001] = "Tiger Palm"; SLOTS = { [63] = { "spell", 999001 } } end)
keyOf(TPsc, "S4", "K4 hidden bar only -> raw fallback", function()
  BARVIS = { ActionButton = true }; SLOTS = { [40] = { "spell", 100787 } }; BINDS.MULTIACTIONBAR4BUTTON4 = "SHIFT-4" end)
print("\n== static: group, fonts, tray layout ==")
local function C(ok, msg) if ok then P = P + 1; print("PASS " .. msg) else F = F + 1; print("FAIL " .. msg) end end
local rel = data.id:match("^Schizzle's Monk Rotation v(%d+%.%d+[%.%d]*)$")
C(rel ~= nil, "group name carries the version: " .. data.id)
C(rel and data.desc:sub(-(#rel + 2)) == "v" .. rel .. ".", "description ends with v" .. tostring(rel) .. ".")
C(data.uid == "SchizzleMonkGroup", "group uid SchizzleMonkGroup")
C(data.xOffset == 0 and data.yOffset == -40 and data.anchorPoint == "CENTER" and data.selfPoint == "CENTER" and data.anchorFrameType == "SCREEN", "group at 0,-40 CENTER/CENTER of the screen")
do
  local bad = {}
  for _, c in ipairs(t.c) do
    if c.regionType == "text" and c.font ~= "Fira Sans Condensed Medium" then bad[#bad + 1] = c.id end
    for _, s in ipairs(c.subRegions or {}) do if s.type == "subtext" and s.text_font ~= "Fira Sans Condensed Medium" then bad[#bad + 1] = c.id end end
  end
  C(#bad == 0, "every font is Fira Sans Condensed Medium " .. table.concat(bad, ","))
end
do
  local function box(c) local w, h = c.width or 0, c.height or 0 return c.xOffset - w / 2, c.xOffset + w / 2, c.yOffset - h / 2, c.yOffset + h / 2 end
  local okL, why, n = true, "", 0
  for i, a in ipairs(t.c) do if a.id:find("^SMR Tray ") then n = n + 1
    local k = tonumber(a.id:match("%d+"))
    if a.uid ~= "SMRTray" .. k or a.width ~= 32 or a.height ~= 32 or a.yOffset ~= -122 or a.xOffset ~= 134 - 36 * (k - 1) then okL, why = false, "pos " .. a.id end
    if not a.triggers[1].trigger.custom:find("R.tray[" .. k .. "]", 1, true) then okL, why = false, "trigger " .. a.id end
    for j, b in ipairs(t.c) do if j ~= i and b.width and b.regionType ~= "text" then
      local a1, a2, a3, a4 = box(a) local b1, b2, b3, b4 = box(b)
      if a1 < b2 and b1 < a2 and a3 < b4 and b3 < a4 then okL, why = false, a.id .. " overlaps " .. b.id end end end
  end end
  C(okL and n == 8, "tray: 8 x 32 px at y -122, x +134..-118 (right edge +150), no overlap " .. why)
end
print(("\n%d passed, %d failed; sandbox warnings: %d"):format(P, F, #warnings))
for _, w in ipairs(warnings) do print("  warning", w.key, w.message) end
if F > 0 then os.exit(1) end
