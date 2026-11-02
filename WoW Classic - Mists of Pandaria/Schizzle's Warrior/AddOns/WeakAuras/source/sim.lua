-- Offline test for "Schizzle's Warrior Rotation": decodes the export exactly like WeakAuras' Transmission.lua,
-- compiles every custom function inside WeakAuras' real aura sandbox (AuraEnvironment.lua) and runs rotation scenarios
-- against a mocked WoW API. Needs a WeakAuras2 checkout with tests/helpers.lua + tests/wow_stubs.lua (run from that tests dir).
local WA_TESTS = os.getenv("WA_TESTS") or "/workspace/wa2/tests"
local LIBDIR = os.getenv("WA_LIBS") or "/workspace"
local EXPORT = os.getenv("WA_EXPORT") or "/workspace/All-in-One Rotation.txt"
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
local data = t.d
data.controlledChildren = {}
local parentsOk = true
for i, child in ipairs(t.c) do parentsOk = parentsOk and child.parent == data.id; data.controlledChildren[i] = child.id; child.parent = data.id end
print(("decoded OK: group %q uid=%s, %d children, s=%s, internalVersion=%s, toc=%s"):format(data.id, data.uid, #t.c, t.s, data.internalVersion, data.tocversion))
local byId = { [data.id] = data }
local P, F = 0, 0
local function check(cond, msg) if cond then P = P + 1 else F = F + 1; print("FAIL " .. msg) end end
local uids = {}
for _, c in ipairs(t.c) do
  byId[c.id] = c
  print("  child", c.id, c.regionType, "subs=" .. #(c.subRegions or {}), "conds=" .. #(c.conditions or {}))
  check(c.id:sub(1, 4) == "SWR ", "child prefix " .. c.id)
  check(c.load.use_class == true and c.load.class.single == "WARRIOR", "class load " .. c.id)
  -- no spec requirement anywhere: a level 1-9 warrior has no specialisation
  check(not c.load.use_class_and_spec and not c.load.use_spec and not c.load.use_level and next(c.load.class_and_spec.multi) == nil, "no spec load " .. c.id)
  check(not uids[c.uid], "unique uid " .. c.uid); uids[c.uid] = true
  for _, s in ipairs(c.subRegions or {}) do if s.type == "subtext" then check(s.text_font == "Fira Sans Condensed Medium", "font " .. c.id) end end
  if c.font then check(c.font == "Fira Sans Condensed Medium", "font " .. c.id) end
end
check(not str:lower():find("peanut") and not decompressed:lower():find("peanut"), "no Peanut naming")
check(data.uid == "SchizzleWarriorGroup", "group uid")
check(not data.load.use_class_and_spec and not data.load.use_spec, "group has no spec load")
local release = data.id:match("^Schizzle's Warrior Rotation v(%d+%.%d+[%.%d]*)$")
check(release ~= nil, "group name carries the version: " .. data.id)
check(release and (data.desc or ""):find("v" .. release:gsub("%.", "%%.") .. "%.$") ~= nil, "description ends with the same version")
check(parentsOk, "every child's parent is the versioned group name")
check(byId["SWR Next"] and byId["SWR Next"].uid == "SWRNext", "child ids/uids unversioned (stable across bumps)")
WeakAuras.GetData = function(id) return byId[id] end
Private.UIDtoID = function(uid) for id, d in pairs(byId) do if d.uid == uid then return id end end end

---------------- mock WoW API ----------------
local W = {}
local now = 1000
_G.GetTime = function() return now end
_G.UnitPower = function(_, p) if p == 1 then return W.rage end return 0 end
_G.UnitPowerMax = function(_, p) if p == 1 then return W.rageMax or 120 end return 0 end
_G.UnitHealth = function(u) if u == "target" then return W.thp or 100 end return W.hp end
_G.UnitHealthMax = function() return 100 end
_G.UnitLevel = function() return W.level or 90 end
_G.IsCurrentSpell = function(id) if id == 6603 then return W.attacking end return false end
_G.UnitAttackSpeed = function() return W.mhSpeed or 2.6, W.ohSpeed end
_G.UnitGUID = function(u) if u == "player" then return "Player-1-1" end return "Creature-0-1" end
local CLEU = {}
_G.CombatLogGetCurrentEventInfo = function() return unpack(CLEU) end
_G.IsPlayerSpell = function(id) return W.known[id] and true or false end
_G.C_SpellBook = { IsSpellKnown = function(id) return W.known[id] and true or false end }
local NAMES = {}
_G.C_Spell = {
  GetSpellName = function(id) return NAMES[id] or ("Spell" .. id) end,
  GetSpellTexture = function(id) return 100000 + id end,
  GetSpellCooldown = function(id) local r = W.cd[id] or (id == 61304 and W.gcd) if r then return { startTime = now - 1, duration = r + 1, isEnabled = true, isOnGCD = false } end return { startTime = 0, duration = 0, isEnabled = true } end,
  GetSpellCharges = function(id) if id == 2565 then return { currentCharges = W.sbCharges or 2, maxCharges = 2 } end return nil end,
  IsSpellInRange = function(id, unit) if W.oor and W.oor[id] then return false end return true end,
  IsSpellUsable = function(id)
    if W.noMana and W.noMana[id] then return false, true end
    if (id == 78 or id == 845 or id == 5308) and (W.rage or 0) < 30 then return false, true end -- 30 rage cost
    return true end,
}
-- aura lists: { spellId, remaining, stacks, points }
_G.C_UnitAuras = { GetAuraDataByIndex = function(unit, i, filter)
  local list
  if unit == "player" then list = (filter == "HELPFUL") and W.buffs or W.debuffs
  elseif unit == "target" then
    if filter == "HARMFUL|PLAYER" then list = W.tdebuffs else
      list = {} for _, a in ipairs(W.tdebuffs) do list[#list + 1] = a end for _, a in ipairs(W.tdebuffsOther or {}) do list[#list + 1] = a end end
  end
  local a = list and list[i]
  if a then return { spellId = a[1], name = NAMES[a[1]] or ("Spell" .. a[1]), expirationTime = now + a[2], duration = 20, applications = a[3] or 0, points = a[4] and { a[4] } or nil } end
end }
_G.AuraUtil = { FindAuraByName = function() return nil end }
_G.UnitExists = function(u) if u == "target" then return W.target end if u == "focus" then return W.cast and W.cast.unit == "focus" end return true end
_G.UnitCanAttack = function() return true end
_G.UnitIsDead = function() return false end
_G.UnitIsUnit = function(a, b) return a == b end
_G.UnitAffectingCombat = function() return W.combat end
_G.UnitClassification = function() return W.boss and "worldboss" or "normal" end
local function castFor(unit)
  local c = W.cast
  if c == true then c = {} end
  if not c then return nil end
  if (c.unit or "target") ~= unit then return nil end
  return c
end
_G.IsSpellInRange = function() return nil end
_G.UnitCastingInfo = function(u) local c = castFor(u) if c and not c.channel then
  return "Fireball", "Fireball", 135812, (now - 0.5) * 1000, (now + (c.dur or 2)) * 1000, false, 42, c.notInt and true or false, 133 end end
_G.UnitChannelInfo = function() return nil end
_G.UnitGroupRolesAssigned = function() return W.role or "NONE" end
_G.UnitDetailedThreatSituation = function() return W.tanking end
_G.IsInGroup = function() return W.group end
local FORMS = { 2457, 71, 2458 }
_G.GetNumShapeshiftForms = function() return 3 end
_G.GetShapeshiftFormInfo = function(i) return nil, W.stance == FORMS[i], true, FORMS[i] end
_G.GetSpecialization = function() return W.spec end
_G.C_SpecializationInfo = { GetSpecialization = function() return W.spec end }
_G.C_NamePlate = { GetNamePlates = function() local tt = {} for i = 1, W.n do tt[i] = { namePlateUnitToken = "nameplate" .. i } end return tt end }
_G.GetInventoryItemID = function(_, slot) return (W.weap or {})[slot] end
local ITEMLOC = { [1] = "INVTYPE_2HWEAPON", [2] = "INVTYPE_WEAPON", [3] = "INVTYPE_SHIELD" }
_G.GetItemInfoInstant = function(item) return item, "Weapon", "x", ITEMLOC[item] end
WeakAuras.CheckRange = function(_, yards) return (W.dist or 0) <= yards end
SLOTS = { [1] = { "spell", 12294 }, [2] = { "spell", 86346 }, [3] = { "spell", 23922 } }
BINDS = { ACTIONBUTTON1 = "1", ACTIONBUTTON2 = "SHIFT-2", ACTIONBUTTON3 = "3" }
_G.GetActionInfo = function(slot) local a = SLOTS[slot] if a then return a[1], a[2] end end
_G.GetBindingKey = function(b) return BINDS[b] end
_G.GetMacroSpell = function() return nil end
_G.C_ActionBar = { GetActionBarPage = function() return 1 end, HasBonusActionBar = function() return false end }
for i = 1, 12 do _G["ActionButton" .. i] = { action = i, bindingAction = "ACTIONBUTTON" .. i, IsVisible = function() return true end } end

T.loadAddonFile("WeakAuras/AuraEnvironment.lua", "WeakAuras", Private)

---------------- compile every custom function inside the WA sandbox ----------------
local nextData = byId["SWR Next"]
local initFn = assert(WeakAuras.LoadFunction("return function() " .. nextData.actions.init.custom .. "\n end", "SWR Next"))
Private.customActionsFunctions["SWR Next"] = { init = initFn }
local tsu = {}
for _, c in ipairs(t.c) do
  local tr = c.triggers[1].trigger
  tsu[c.id] = assert(WeakAuras.LoadFunction("return " .. tr.custom, c.id), "tsu " .. c.id)
  assert(WeakAuras.LoadFunction("return function() return \n" .. tr.customVariables .. "\n end", c.id))()
end
print("sandbox compile OK for init + " .. #t.c .. " TSU + customVariables")

---------------- spell book per spec ----------------
local COMMON = { 5308, 78, 845, 6343, 1719, 114207, 6673, 469, 18499, 6544, 57755, 6552, 23920, 97462, 871, 34428, 2457, 71, 2458, 100 }
local SPEC = {
  [1] = { 12294, 7384, 1464, 12328, 86346, 1680, 118038, 56636, 29725 },
  [2] = { 23881, 85288, 100130, 86346, 1680, 118038, 46917, 81099, 46915, 12950 },
  [3] = { 23922, 6572, 20243, 2565, 112048, 12975, 1160, 46953, 122509 },
}
local function book(spec, talents)
  local k = {}
  for _, id in ipairs(COMMON) do k[id] = true end
  for _, id in ipairs(SPEC[spec] or {}) do k[id] = true end
  for _, id in ipairs(talents or {}) do k[id] = true end
  return k
end
local SN = { [12294]="MortalStrike",[7384]="Overpower",[1464]="Slam",[12328]="SweepingStrikes",[86346]="ColossusSmash",[5308]="Execute",
  [78]="HeroicStrike",[845]="Cleave",[1680]="Whirlwind",[6343]="ThunderClap",[1719]="Recklessness",[114207]="SkullBanner",[6673]="BattleShout",
  [469]="CommandingShout",[18499]="BerserkerRage",[57755]="HeroicThrow",[6552]="Pummel",[97462]="RallyingCry",[871]="ShieldWall",[34428]="VictoryRush",
  [2457]="BattleStance",[71]="DefensiveStance",[2458]="BerserkerStance",[23881]="Bloodthirst",[85288]="RagingBlow",[100130]="WildStrike",
  [118038]="DieByTheSword",[23922]="ShieldSlam",[6572]="Revenge",[20243]="Devastate",[2565]="ShieldBlock",[112048]="ShieldBarrier",[12975]="LastStand",
  [1160]="DemoShout",[46924]="Bladestorm",[46968]="Shockwave",[118000]="DragonRoar",[107574]="Avatar",[12292]="Bloodbath",[107570]="StormBolt",
  [102060]="DisruptingShout",[1250619]="Charge",[6603]="Attack",[100]="ChargeOld",[7386]="SunderArmor",[103840]="ImpendingVictory",[55694]="EnragedRegen",[107079]="QuakingPalm",[69179]="ArcaneTorrent" }

local ORDER = {}
for _, c in ipairs(t.c) do ORDER[#ORDER + 1] = c.id end
local states = {}
for _, id in ipairs(ORDER) do states[id] = {} end
local function nm(st) if not st or not st.show then return "-" end return (SN[(st.icon or 0) - 100000] or st.name or "?") .. ((st.keybind or "") ~= "" and ("[" .. st.keybind .. "]") or "") .. (st.glow and "*" or "") .. ((st.tag or "") ~= "" and ("{" .. st.tag .. "}") or "") .. (st.waiting and "(wait)" or "") .. (st.oorTint and "(OOR)" or "") end
local getE = WeakAuras.LoadFunction("return function() return SchizzleWarrior end", "SWR Next")

local function run(label, sc, expect)
  W = { rage = 50, hp = 100, thp = 100, buffs = {}, debuffs = {}, tdebuffs = {}, tdebuffsOther = {}, cd = {}, target = true, combat = true,
        n = 1, spec = 1, stance = 2457, group = false, attacking = true }
  for k, v in pairs(sc) do W[k] = v end
  if sc.noSpec then W.spec = nil end   -- GetSpecialization() returns nil before level 10
  if sc.noStance then W.stance = nil end
  if sc.notAttacking then W.attacking = false end
  if sc.knownOnly then W.known = {} for _, id in ipairs(sc.knownOnly) do W.known[id] = true end
  else W.known = book(W.spec, sc.talents) end
  for id in pairs(sc.removeKnown or {}) do W.known[id] = nil end
  local cf = byId["SWR Next"].config
  cf.aoe, cf.protMode, cf.amMode, cf.fuMode, cf.shout, cf.dpsStance, cf.dumpMargin, cf.slamRage, cf.wildRage = 3, 1, 1, 1, 1, 1, 20, 80, 70
  cf.showOff, cf.showDef, cf.showCDs, cf.showKeys, cf.tintOOR, cf.showInt, cf.intCC, cf.intMain, cf.intFocus = true, true, true, true, true, true, true, false, false
  for k, v in pairs(sc.cfg or {}) do cf[k] = v end
  Private.DeleteAuraEnvironment("SWR Next")
  Private.ActivateAuraEnvironment("SWR Next", nil, nil, nil)
  Private.ActivateAuraEnvironment()
  now = now + (sc.dt or 1)
  if sc.before then sc.before(getE()) end
  for _, id in ipairs(ORDER) do
    -- honour load conditions like WeakAuras would (class always WARRIOR here; spec only if a child asked for it)
    local ld = byId[id].load
    local specId = ({ 71, 72, 73 })[W.spec or 0]
    if not ld.use_class_and_spec or (specId and ld.class_and_spec.multi[specId]) then
      Private.ActivateAuraEnvironment(id, nil, nil, states[id])
      local ok2, err = pcall(tsu[id], states[id], "FRAME_UPDATE")
      Private.ActivateAuraEnvironment()
      if not ok2 then print("ERROR in " .. id .. ": " .. tostring(err)) os.exit(1) end
    else
      states[id] = {}
    end
  end
  local s = states
  local function st(id) local x = s[id] and s[id][""] return (x and x.show) and x or nil end
  local trk = {}
  for i = 1, 4 do local x = st("SWR Tracker " .. i) trk[i] = x and (x.label .. (x.inactive and "-" or "+") .. (x.stacks ~= "" and x.stacks or "") .. (x.alert and "!" or "")) or "." end
  local line = ("%-40s Next=%-24s +1=%-16s off=%-14s L=%s,%s R=%s,%s | %s | %s | trk %s"):format(label, nm(st("SWR Next")), nm(st("SWR Next+1")), nm(st("SWR Off-GCD")),
    nm(st("SWR Defensive 1")), nm(st("SWR Defensive 2")), nm(st("SWR Cooldown 1")), nm(st("SWR Cooldown 2")),
    st("SWR Next") and st("SWR Next").mode or "-", st("SWR Resources") and st("SWR Resources").res or "-", table.concat(trk, " "))
  local it = st("SWR Interrupt")
  if it then line = line .. " | INT " .. nm(it) end
  local nx = st("SWR Next")
  local got = nx and SN[(nx.icon or 0) - 100000] or "-"
  local pass = (expect == nil) or (got == expect)
  if sc.check then local okc, why = sc.check(st) if not okc then pass = false; line = line .. " CHECK FAILED: " .. tostring(why) end end
  print((pass and "PASS " or "FAIL ") .. line .. (expect and (" (expect " .. expect .. ")") or ""))
  if pass then P = P + 1 else F = F + 1 end
end
local function has(st, side, sid) for i = 1, 3 do local x = st("SWR " .. side .. " " .. i) if x and x.icon == 100000 + sid then return true, x end end return false end
local function icon(x, sid) return x and x.icon == 100000 + sid end

local CS = { 86346, 6 }
print("\n== Arms ==")
R = run
R("CS ready, no CS debuff", { rage = 40 }, "ColossusSmash")
R("CS up -> Mortal Strike", { rage = 40, tdebuffs = { CS }, cd = { [86346] = 14 } }, "MortalStrike")
R("CS up, MS cd, 2 TfB -> Overpower", { rage = 40, tdebuffs = { CS }, cd = { [86346] = 14, [12294] = 3 }, buffs = { { 60503, 10, 2 } } }, "Overpower")
R("CS up, MS cd, no TfB -> Slam", { rage = 40, tdebuffs = { CS }, cd = { [86346] = 14, [12294] = 3 } }, "Slam")
R("outside CS, MS cd, 1 TfB -> Overpower", { rage = 40, cd = { [86346] = 10, [12294] = 3 }, buffs = { { 60503, 10, 1 } } }, "Overpower")
R("outside CS, 90 rage -> Slam", { rage = 90, cd = { [86346] = 10, [12294] = 3 } }, "Slam")
R("outside CS, 40 rage -> Battle Shout", { rage = 40, cd = { [86346] = 10, [12294] = 3 } }, "BattleShout")
R("outside CS, shout option Commanding", { rage = 40, cd = { [86346] = 10, [12294] = 3 }, cfg = { shout = 2 } }, "CommandingShout")
R("outside CS, nothing -> wait MS", { rage = 40, cd = { [86346] = 10, [12294] = 3, [6673] = 30 },
  check = function(st) return st("SWR Next").waiting, "waiting" end }, "MortalStrike")
R("Dragon Roar talent on cooldown", { rage = 40, talents = { 118000 }, cd = { [86346] = 10 } }, "DragonRoar")
R("Bladestorm only in CS window (ST)", { rage = 40, talents = { 46924 }, tdebuffs = { { 86346, 6 } }, cd = { [86346] = 14, [12294] = 3 } }, "Bladestorm")
R("Bladestorm not outside CS (ST)", { rage = 40, talents = { 46924 }, cd = { [86346] = 10 } }, "MortalStrike")
R("Shockwave picked: nothing shown ST", { rage = 40, talents = { 46968 }, cd = { [86346] = 10 } }, "MortalStrike")
R("Sudden Death proc tag", { rage = 40, buffs = { { 52437, 5 } }, check = function(st) return st("SWR Next").tag == "SD", "tag" end }, "ColossusSmash")
R("Execute phase in CS", { rage = 40, thp = 15, tdebuffs = { CS }, cd = { [86346] = 14, [12294] = 3 } }, "Execute")
R("Execute phase CS ready", { rage = 40, thp = 15 }, "ColossusSmash")
R("AoE 4 -> Sweeping Strikes", { rage = 40, n = 4 }, "SweepingStrikes")
R("AoE 4, SS up -> Thunder Clap (Deep Wounds)", { rage = 40, n = 4, buffs = { { 12328, 8 } } }, "ThunderClap")
R("rage 110/120 -> Heroic Strike off-GCD", { rage = 110, tdebuffs = { CS }, cd = { [86346] = 14 },
  check = function(st) return icon(st("SWR Off-GCD"), 78), "HS" end }, "MortalStrike")
R("rage 110, 2 targets -> Cleave off-GCD", { rage = 110, n = 2, tdebuffs = { CS }, cd = { [86346] = 14 },
  check = function(st) return icon(st("SWR Off-GCD"), 845), "Cleave" end }, nil)
R("rage 60 -> no off-GCD", { rage = 60, check = function(st) return st("SWR Off-GCD") == nil, "none" end }, nil)
R("Arms in Defensive Stance -> Battle Stance reminder (left)", { rage = 40, stance = 71,
  check = function(st) local okb, x = has(st, "Defensive", 2457) return okb and x.glow and st("SWR Resources").res:find("^!") ~= nil, "stance" end }, "ColossusSmash")
R("boss, CS ready -> Recklessness + Skull Banner + Avatar", { rage = 40, boss = true, talents = { 107574 },
  check = function(st) return has(st, "Cooldown", 1719) and has(st, "Cooldown", 107574) and has(st, "Cooldown", 114207), "cds" end }, "ColossusSmash")
R("boss, CS 15s away -> hold Recklessness", { rage = 40, boss = true, cd = { [86346] = 15 },
  check = function(st) return not has(st, "Cooldown", 1719), "held" end }, nil)
R("Bloodbath on cooldown", { rage = 40, talents = { 12292 }, check = function(st) return has(st, "Cooldown", 12292), "bb" end }, nil)
R("hp 35 -> Die by the Sword + Shield Wall", { rage = 40, hp = 25, check = function(st) return has(st, "Defensive", 118038) and has(st, "Defensive", 871), "defs" end }, nil)
R("Impending Victory talent at hp 40", { rage = 40, hp = 40, talents = { 103840 } }, "ImpendingVictory")
R("Arms trackers: CS up, TfB 3", { rage = 40, tdebuffs = { CS }, buffs = { { 60503, 10, 3 } }, cd = { [86346] = 14 },
  check = function(st) local a, b = st("SWR Tracker 1"), st("SWR Tracker 2") return not a.inactive and b.stacks == "3" and st("SWR Colossus Smash").up, "trk" end }, nil)
R("CS bar shows cooldown text", { rage = 40, cd = { [86346] = 9 }, check = function(st) local b = st("SWR Colossus Smash") return b and not b.up and b.label:find("CS in") ~= nil, b and b.label end }, nil)
R("out of combat, no target -> hidden", { combat = false, target = false, check = function(st) return st("SWR Rage") == nil, "hidden" end }, "-")

print("\n== Fury ==")
local TG = { [16] = 1, [17] = 1 }
local SMF = { [16] = 2, [17] = 2 }
R("TG: CS ready", { spec = 2, rage = 40, weap = TG, check = function(st) return st("SWR Next").mode:find("FURY TG") ~= nil, "mode" end }, "ColossusSmash")
R("SMF detected from 1H off hand", { spec = 2, rage = 40, weap = SMF, check = function(st) return st("SWR Next").mode:find("FURY SMF") ~= nil, "mode" end }, "ColossusSmash")
R("outside CS, BT ready, 0 RB", { spec = 2, rage = 40, weap = TG, cd = { [86346] = 10 } }, "Bloodthirst")
R("outside CS, BT cd, 2 RB charges", { spec = 2, rage = 40, weap = TG, cd = { [86346] = 10, [23881] = 2 }, buffs = { { 131116, 10, 2 }, { 12880, 5 } } }, "RagingBlow")
R("TG: 2 RB + Bloodsurge -> Raging Blow first", { spec = 2, rage = 40, weap = TG, cd = { [86346] = 10, [23881] = 2 }, buffs = { { 131116, 10, 2 }, { 46916, 10, 3 }, { 12880, 5 } } }, "RagingBlow")
R("SMF: 2 RB + Bloodsurge -> Wild Strike first", { spec = 2, rage = 40, weap = SMF, cd = { [86346] = 10, [23881] = 2 }, buffs = { { 131116, 10, 2 }, { 46916, 10, 3 }, { 12880, 5 } },
  check = function(st) return st("SWR Next").tag == "BS", "tag" end }, "WildStrike")
R("1 RB charge, CS in 3s -> hold RB", { spec = 2, rage = 40, weap = TG, cd = { [86346] = 3, [23881] = 2, [6673] = 30 }, buffs = { { 131116, 10, 1 }, { 12880, 5 } },
  check = function(st) return st("SWR Next").waiting, "wait" end }, "Bloodthirst")
R("CS window: BT cd, 1 RB -> Raging Blow", { spec = 2, rage = 40, weap = TG, tdebuffs = { CS }, cd = { [86346] = 14, [23881] = 2 }, buffs = { { 131116, 10, 1 }, { 12880, 5 } } }, "RagingBlow")
R("CS window: nothing but rage -> Wild Strike", { spec = 2, rage = 60, weap = TG, tdebuffs = { CS }, cd = { [86346] = 14, [23881] = 2 }, buffs = { { 12880, 5 } } }, "WildStrike")
R("Execute phase in CS", { spec = 2, rage = 50, thp = 12, weap = TG, tdebuffs = { CS }, cd = { [86346] = 14 } }, "Execute")
R("Execute phase, 20 rage, no CS -> Bloodthirst", { spec = 2, rage = 20, thp = 12, weap = TG, cd = { [86346] = 8 } }, "Bloodthirst")
R("no Enrage, no CS -> Berserker Rage right", { spec = 2, rage = 40, weap = TG, cd = { [86346] = 8 },
  check = function(st) return has(st, "Cooldown", 18499), "brage" end }, nil)
R("AoE 4 -> Bloodthirst then Whirlwind", { spec = 2, rage = 60, n = 4, weap = TG,
  check = function(st) return icon(st("SWR Next+1"), 1680), "ww next" end }, "Bloodthirst")
R("AoE 4, BT cd, 3 Meat Cleaver -> Raging Blow", { spec = 2, rage = 60, n = 4, weap = TG, cd = { [23881] = 2 }, buffs = { { 85739, 10, 3 }, { 131116, 10, 1 } } }, "RagingBlow")
R("Fury trackers: Enrage missing alert", { spec = 2, rage = 40, weap = TG, check = function(st) return st("SWR Tracker 2").alert, "alert" end }, nil)
R("Fury Storm Bolt talent in CS", { spec = 2, rage = 40, weap = TG, talents = { 107570 }, tdebuffs = { CS }, cd = { [86346] = 14 } }, "StormBolt")

print("\n== Protection ==")
local WB = { 115798, 20 }
local WA3 = { 113746, 20, 3 }
R("Prot in Battle Stance -> Defensive Stance", { spec = 3, rage = 30, stance = 2457, role = "TANK" }, "DefensiveStance")
R("Shield Slam ready", { spec = 3, rage = 30, stance = 71, tdebuffsOther = { WB, WA3 } }, "ShieldSlam")
R("Sword and Board -> Shield Slam glow", { spec = 3, rage = 30, stance = 71, buffs = { { 50227, 5 } }, tdebuffsOther = { WB, WA3 },
  check = function(st) local x = st("SWR Next") return x.glow and x.tag == "S&B", "snb" end }, "ShieldSlam")
R("SS cd -> Revenge", { spec = 3, rage = 30, stance = 71, cd = { [23922] = 4 }, tdebuffsOther = { WB, WA3 } }, "Revenge")
R("SS/Rev cd, Weakened Blows missing -> TC", { spec = 3, rage = 30, stance = 71, cd = { [23922] = 4, [6572] = 5 }, tdebuffsOther = { WA3 } }, "ThunderClap")
R("WB from another player counts", { spec = 3, rage = 30, stance = 71, cd = { [23922] = 4, [6572] = 5, [6673] = 30 }, tdebuffsOther = { WB, WA3 } }, "Devastate")
R("Weakened Armor 1 stack -> Devastate tag", { spec = 3, rage = 30, stance = 71, cd = { [23922] = 4, [6572] = 5 }, tdebuffsOther = { WB, { 113746, 20, 1 } },
  check = function(st) return st("SWR Next").tag == "WA", "tag" end }, "Devastate")
R("AoE 4 -> Thunder Clap first", { spec = 3, rage = 30, n = 4, stance = 71, tdebuffsOther = { WB, WA3 } }, "ThunderClap")
R("AM: 70 rage, no Block -> Shield Block (left, glow)", { spec = 3, rage = 70, stance = 71, tdebuffsOther = { WB, WA3 },
  check = function(st) local okb, x = has(st, "Defensive", 2565) return okb and x.glow, "block" end }, nil)
R("AM: Block up, 100 rage -> Shield Barrier", { spec = 3, rage = 100, stance = 71, sbCharges = 1, buffs = { { 132404, 4 } }, tdebuffsOther = { WB, WA3 },
  check = function(st) return has(st, "Defensive", 112048), "barrier" end }, nil)
R("AM: Barrier-first option", { spec = 3, rage = 70, stance = 71, cfg = { amMode = 3 }, tdebuffsOther = { WB, WA3 },
  check = function(st) return has(st, "Defensive", 112048), "barrier" end }, nil)
R("Ultimatum -> Heroic Strike off-GCD glow", { spec = 3, rage = 20, stance = 71, buffs = { { 122510, 8 } }, tdebuffsOther = { WB, WA3 },
  check = function(st) local x = st("SWR Off-GCD") return icon(x, 78) and x.glow and x.tag == "ULT", "ult" end }, nil)
R("rage 110, Block up -> HS dump", { spec = 3, rage = 110, stance = 71, buffs = { { 132404, 4 } }, tdebuffsOther = { WB, WA3 },
  check = function(st) return icon(st("SWR Off-GCD"), 78), "hs" end }, nil)
R("rage 110, Block down + charges -> no HS (save for AM)", { spec = 3, rage = 110, stance = 71, tdebuffsOther = { WB, WA3 },
  check = function(st) return st("SWR Off-GCD") == nil, "no hs" end }, nil)
R("tank hp 25 -> Shield Wall + Last Stand", { spec = 3, rage = 30, hp = 25, stance = 71, tdebuffsOther = { WB, WA3 },
  check = function(st) return has(st, "Defensive", 871) and has(st, "Defensive", 12975), "defs" end }, nil)
R("boss -> Demoralizing Shout (left)", { spec = 3, rage = 30, boss = true, stance = 71, sbCharges = 0, tdebuffsOther = { WB, WA3 },
  check = function(st) return has(st, "Defensive", 1160), "demo" end }, nil)
R("Prot trackers: WB missing alert", { spec = 3, rage = 30, stance = 71, tdebuffsOther = { WA3 },
  check = function(st) return st("SWR Tracker 1").alert and not st("SWR Tracker 2").alert, "trk" end }, nil)
R("Shield Block bar + charges", { spec = 3, rage = 30, stance = 71, sbCharges = 1, buffs = { { 132404, 4 } },
  check = function(st) local b = st("SWR Shield Block") return b and b.up and b.label == "Shield Block (1)" and st("SWR Colossus Smash") == nil, b and b.label end }, nil)
R("Shield Barrier bar shows absorb", { spec = 3, rage = 30, stance = 71, buffs = { { 112048, 5, 0, 45200 } },
  check = function(st) local b = st("SWR Shield Barrier") return b and b.up and b.label == "Barrier 45.2k", b and b.label end }, nil)
R("Prot DPS mode: no AM, HS at 60", { spec = 3, rage = 65, stance = 2457, cfg = { protMode = 3 }, tdebuffsOther = { WB, WA3 },
  check = function(st) return not has(st, "Defensive", 2565) and icon(st("SWR Off-GCD"), 78) and st("SWR Next").mode:find("PROT DPS") ~= nil, "dps" end }, "ShieldSlam")
R("Prot execute only with 90+ rage when tanking", { spec = 3, rage = 50, thp = 10, stance = 71, cd = { [23922] = 4, [6572] = 5 }, tdebuffsOther = { WB, WA3 }, sbCharges = 0,
  check = function(st) return not icon(st("SWR Next"), 5308), "no exe" end }, nil)
R("Prot Shockwave talent", { spec = 3, rage = 30, stance = 71, talents = { 46968 }, cd = { [23922] = 4, [6572] = 5 }, tdebuffsOther = { WB, WA3 } }, "Shockwave")

print("\n== Leveling (no spec, levels 1-9) ==")
-- MoP Classic: Battle Stance + Heroic Strike at 1, Charge at 3, Victory Rush at 5, Execute at 7
local L1 = { 2457, 78 }
local L3 = { 2457, 78, 1250619 }
local L5 = { 2457, 78, 1250619, 34428 }
local L7 = { 2457, 78, 1250619, 34428, 5308 }
local VIC = { 32216, 15 }
local function lev(st) local x = st("SWR Next") return x and x.mode:find("^LEVELING") ~= nil, x and x.mode end
local function noSpecBars(st) return st("SWR Colossus Smash") == nil and st("SWR Shield Block") == nil and st("SWR Shield Barrier") == nil and st("SWR Tracker 1") == nil and st("SWR Tracker 4") == nil end
R("L1 attacking, 0 rage -> Attack (building rage), HS next", { noSpec = true, level = 1, rage = 0, knownOnly = L1,
  check = function(st) local x = st("SWR Next") return lev(st) and not x.waiting and x.tag == "RAGE" and icon(st("SWR Next+1"), 78) and st("SWR Rage") ~= nil and st("SWR Resources").res == "Battle  Lv 1" and noSpecBars(st), st("SWR Resources") and st("SWR Resources").res end }, "Attack")
R("L1 GetSpecialization 0, 30 rage -> Heroic Strike", { spec = 0, level = 1, rage = 30, knownOnly = L1,
  check = function(st) return lev(st) and not st("SWR Next").waiting and st("SWR Off-GCD") == nil, "hs main, no off-GCD copy" end }, "HeroicStrike")
R("L1 spec 5 (initial) counts as no spec", { spec = 5, level = 1, rage = 30, knownOnly = L1, check = lev }, "HeroicStrike")
R("L1 no stance -> Battle Stance reminder", { noSpec = true, level = 1, rage = 30, noStance = true, knownOnly = L1,
  check = function(st) return has(st, "Defensive", 2457), "stance" end }, "HeroicStrike")
R("L1 out of combat, no target -> hidden", { noSpec = true, level = 1, combat = false, target = false, knownOnly = L1,
  check = function(st) return st("SWR Rage") == nil and st("SWR Resources") == nil, "hidden" end }, "-")
R("L1 target 15 yd, no Charge yet -> Heroic Strike OOR", { noSpec = true, level = 1, rage = 30, dist = 15, oor = { [78] = true }, knownOnly = L1,
  check = function(st) return st("SWR Next").oorTint, "oor" end }, "HeroicStrike")
R("L3 target 15 yd -> Charge", { noSpec = true, level = 3, rage = 0, dist = 15, knownOnly = L3,
  check = function(st) return st("SWR Next").glow and icon(st("SWR Next+1"), 78), "charge glow, HS next" end }, "Charge")
R("L3 old Charge ID 100 also works", { noSpec = true, level = 3, rage = 0, dist = 15, knownOnly = { 2457, 78, 100 } }, "ChargeOld")
R("L3 Charge on cooldown -> Heroic Strike", { noSpec = true, level = 3, rage = 30, dist = 15, cd = { [1250619] = 12 }, knownOnly = L3 }, "HeroicStrike")
R("L3 in melee -> no Charge", { noSpec = true, level = 3, rage = 30, knownOnly = L3 }, "HeroicStrike")
R("L5 Victorious up -> Victory Rush", { noSpec = true, level = 5, rage = 40, buffs = { VIC }, knownOnly = L5 }, "VictoryRush")
R("L5 Victorious, hp 50 -> Victory Rush glow", { noSpec = true, level = 5, rage = 40, hp = 50, buffs = { VIC }, knownOnly = L5,
  check = function(st) return st("SWR Next").glow, "glow" end }, "VictoryRush")
R("L5 no proc -> Heroic Strike", { noSpec = true, level = 5, rage = 40, knownOnly = L5 }, "HeroicStrike")
R("L5 target 10% but no Execute yet -> Heroic Strike", { noSpec = true, level = 5, rage = 40, thp = 10, knownOnly = L5,
  check = function(st) return not st("SWR Next").mode:find("EXEC"), "no exec" end }, "HeroicStrike")
R("L7 target 15% -> Execute", { noSpec = true, level = 7, rage = 40, thp = 15, knownOnly = L7,
  check = function(st) return st("SWR Next").mode == "LEVELING EXEC", st("SWR Next").mode end }, "Execute")
R("L7 low hp + proc beats Execute", { noSpec = true, level = 7, rage = 40, thp = 15, hp = 40, buffs = { VIC }, knownOnly = L7 }, "VictoryRush")
R("L7 cast on target, no Pummel -> no interrupt", { noSpec = true, level = 7, rage = 40, cast = true, knownOnly = L7,
  check = function(st) return st("SWR Interrupt") == nil, "no int" end }, "HeroicStrike")
R("L9 full COMMON book, no spec, 3 targets", { noSpec = true, level = 9, rage = 40, n = 3,
  check = function(st) return lev(st) and noSpecBars(st), "lev" end }, "ThunderClap")

print("\n== Level 10, just specced ==")
local B10 = { 2457, 78, 1250619, 34428, 5308 }
local function plus(t, ...) local o = {} for _, v in ipairs(t) do o[#o + 1] = v end for _, v in ipairs({ ... }) do o[#o + 1] = v end return o end
R("spec picked mid-session: Arms lv10 -> Mortal Strike", { spec = 1, level = 10, rage = 30, knownOnly = plus(B10, 12294),
  check = function(st) return st("SWR Next").mode == "ARMS" and st("SWR Colossus Smash") == nil and st("SWR Tracker 1") == nil and st("SWR Resources").res:find("TfB") ~= nil, "arms10" end }, "MortalStrike")
R("Arms lv10, MS on cd, 40 rage -> Heroic Strike filler", { spec = 1, level = 10, rage = 40, cd = { [12294] = 4 }, knownOnly = plus(B10, 12294),
  check = function(st) return st("SWR Off-GCD") == nil, "no duplicate off-GCD" end }, "HeroicStrike")
R("Arms lv10, MS on cd, 10 rage -> wait MS", { spec = 1, level = 10, rage = 10, cd = { [12294] = 4 }, knownOnly = plus(B10, 12294),
  check = function(st) return st("SWR Next").waiting, "wait" end }, "MortalStrike")
R("Arms lv10, target 15 yd -> Charge", { spec = 1, level = 10, rage = 30, dist = 15, knownOnly = plus(B10, 12294) }, "Charge")
R("Arms lv10, Victorious, MS cd -> Victory Rush", { spec = 1, level = 10, rage = 10, buffs = { VIC }, cd = { [12294] = 4 }, knownOnly = plus(B10, 12294) }, "VictoryRush")
R("Fury lv10 -> Bloodthirst", { spec = 2, level = 10, rage = 30, knownOnly = plus(B10, 23881),
  check = function(st) return st("SWR Next").mode:find("^FURY") ~= nil and st("SWR Tracker 2") ~= nil and st("SWR Tracker 3") == nil, "fury10 trackers" end }, "Bloodthirst")
R("Prot lv10 in Battle Stance, no Def Stance yet -> Shield Slam", { spec = 3, level = 10, rage = 30, knownOnly = plus(B10, 23922),
  check = function(st) return st("SWR Shield Block") == nil and st("SWR Shield Barrier") == nil and not has(st, "Defensive", 2565), "no AM bars" end }, "ShieldSlam")
R("Prot lv12 with Def Stance -> stance first", { spec = 3, level = 12, rage = 30, role = "TANK", knownOnly = plus(B10, 23922, 71) }, "DefensiveStance")
R("back to no spec (respec / reset) -> Leveling again", { noSpec = true, level = 10, rage = 30, knownOnly = B10, check = lev }, "HeroicStrike")
R("level 90 Arms unchanged: wait MS, HS stays off-GCD", { spec = 1, rage = 110, cd = { [86346] = 10, [12294] = 3, [6673] = 30, [1464] = 0 }, removeKnown = { [1464] = true },
  check = function(st) return icon(st("SWR Off-GCD"), 78) and st("SWR Next").waiting, "off-gcd hs" end }, "MortalStrike")

print("\n== Auto attack ==")
R("L1 not attacking, target in melee -> Attack", { noSpec = true, level = 1, rage = 0, notAttacking = true, knownOnly = L1,
  check = function(st) local x = st("SWR Next") return x.glow and x.tag == "ATK" and not x.waiting, "start attack" end }, "Attack")
R("L1 not attacking, 30 rage -> Heroic Strike first (it starts auto attack)", { noSpec = true, level = 1, rage = 30, notAttacking = true, knownOnly = L1,
  check = function(st) local x = st("SWR Next") return x.tag ~= "ATK" and not x.waiting, "hs, no ATK" end }, "HeroicStrike")
R("L1 not attacking, 60 rage -> Heroic Strike first", { noSpec = true, level = 1, rage = 60, notAttacking = true, knownOnly = L1 }, "HeroicStrike")
R("L1 not attacking, 29 rage -> Attack (HS unaffordable)", { noSpec = true, level = 1, rage = 29, notAttacking = true, knownOnly = L1,
  check = function(st) local x = st("SWR Next") return x.glow and x.tag == "ATK", "start attack" end }, "Attack")
R("L1 not attacking, 30 rage, HS on cooldown -> Attack", { noSpec = true, level = 1, rage = 30, notAttacking = true, cd = { [78] = 1.2 }, knownOnly = L1,
  check = function(st) return st("SWR Next").tag == "ATK", "start attack" end }, "Attack")
R("L1 not attacking, 40 rage, out of combat -> Heroic Strike opener", { noSpec = true, level = 1, rage = 40, notAttacking = true, combat = false, knownOnly = L1 }, "HeroicStrike")
R("L7 not attacking, target 15%, 10 rage, Victorious -> Victory Rush (Execute unaffordable)", { noSpec = true, level = 7, rage = 10, thp = 15, notAttacking = true, buffs = { VIC }, knownOnly = L7 }, "VictoryRush")
R("L1 attacking, 29 rage -> still Attack, never a grey HS", { noSpec = true, level = 1, rage = 29, knownOnly = L1,
  check = function(st) return st("SWR Next").tag == "RAGE" and not st("SWR Next").waiting, "building" end }, "Attack")
R("L1 attacking, 30 rage -> Heroic Strike", { noSpec = true, level = 1, rage = 30, knownOnly = L1,
  check = function(st) return not st("SWR Next").waiting and not st("SWR Next").oorTint, "hs" end }, "HeroicStrike")
R("L3 not attacking, 15 yd -> Charge (no Attack out of melee)", { noSpec = true, level = 3, rage = 0, dist = 15, notAttacking = true, knownOnly = L3 }, "Charge")
R("L5 not attacking, Victorious -> Victory Rush (free, starts auto attack)", { noSpec = true, level = 5, rage = 0, notAttacking = true, buffs = { VIC }, knownOnly = L5,
  check = function(st) return st("SWR Next").tag ~= "ATK", "no ATK" end }, "VictoryRush")
R("L7 attacking, target 15%, 10 rage -> Attack building (Execute unaffordable)", { noSpec = true, level = 7, rage = 10, thp = 15, knownOnly = L7,
  check = function(st) return st("SWR Next").tag == "RAGE", "building" end }, "Attack")
R("Arms 90 not attacking, rage for CS -> Colossus Smash first", { rage = 40, notAttacking = true,
  check = function(st) return st("SWR Next").tag ~= "ATK", "no ATK" end }, "ColossusSmash")
R("Arms 90 not attacking, CS unaffordable -> Mortal Strike, not Attack", { rage = 40, notAttacking = true, noMana = { [86346] = true },
  check = function(st) return st("SWR Next").tag ~= "ATK", "no ATK" end }, "MortalStrike")
R("Arms 90 first pick unaffordable -> next affordable", { rage = 40, noMana = { [86346] = true } }, "MortalStrike")
R("Arms 90 attacking -> no Attack prompt", { rage = 40 }, "ColossusSmash")
R("Prot lv10 not attacking, 0 rage -> Shield Slam (costs no rage, starts auto attack)", { spec = 3, level = 10, rage = 0, notAttacking = true, knownOnly = plus(B10, 23922),
  check = function(st) return st("SWR Next").tag ~= "ATK", "no ATK" end }, "ShieldSlam")
R("Fury lv10 not attacking -> Bloodthirst, not Attack", { spec = 2, level = 10, rage = 30, notAttacking = true, knownOnly = plus(B10, 23881),
  check = function(st) return st("SWR Next").tag ~= "ATK", "no ATK" end }, "Bloodthirst")
R("Arms lv10 not attacking, MS on cd, 40 rage -> Heroic Strike, not Attack", { spec = 1, level = 10, rage = 40, notAttacking = true, cd = { [12294] = 4 }, knownOnly = plus(B10, 12294),
  check = function(st) return st("SWR Next").tag ~= "ATK", "no ATK" end }, "HeroicStrike")
R("Arms lv10 not attacking, MS on cd, 10 rage -> Attack", { spec = 1, level = 10, rage = 10, notAttacking = true, cd = { [12294] = 4 }, knownOnly = plus(B10, 12294),
  check = function(st) return st("SWR Next").tag == "ATK", "start attack" end }, "Attack")

print("\n== GCD swipe ==")
do local n, n1 = byId["SWR Next"], byId["SWR Next+1"]
  check(n.cooldown == true and n.cooldownSwipe == true and n1.cooldown == true and n1.cooldownSwipe == true and n.useCooldownModRate, "GCD swipe config on Next / Next+1") end
R("GCD running -> swipe on Next and Next+1", { rage = 40, gcd = 0.7,
  check = function(st) local a, b = st("SWR Next"), st("SWR Next+1")
    return a.duration > 0 and a.expirationTime > now and b.duration > 0 and b.expirationTime > now, a.duration end }, "ColossusSmash")
R("GCD running, Heroic Strike in Next stays bright (off-GCD)", { noSpec = true, level = 1, rage = 30, gcd = 0.7, knownOnly = L1,
  check = function(st) local x = st("SWR Next") return not x.waiting and x.duration == 0, x.duration end }, "HeroicStrike")
R("Heroic Strike 1.5 s cooldown is shown (not mistaken for the GCD)", { noSpec = true, level = 1, rage = 60, cd = { [78] = 0.5 }, knownOnly = L1,
  check = function(st) local x = st("SWR Next") return x.waiting and x.duration == 1.5 and x.tag ~= "RAGE", x.duration end }, "HeroicStrike")

print("\n== Swing timer ==")
local function cl(sub, src, off)
  local t = { now, sub, false, src }
  for i = 5, 21 do t[i] = false end
  if sub == "SWING_DAMAGE" then t[21] = off or false else t[13] = off or false end
  for i = 1, 21 do CLEU[i] = t[i] end
end
local function reset(E) E.swing.mh = { s = 0, d = 0 }; E.swing.oh = { s = 0, d = 0 } end
local function sw(st, h) return st(h == "oh" and "SWR Swing Timer OH" or "SWR Swing Timer") end
R("L1 main-hand SWING_DAMAGE -> 2.6 s swing bar", { noSpec = true, level = 1, rage = 0, knownOnly = L1,
  before = function(E) reset(E) cl("SWING_DAMAGE", "Player-1-1") E:OnEvent("COMBAT_LOG_EVENT_UNFILTERED") end,
  check = function(st) local b = sw(st) return b and b.up and b.duration == 2.6 and math.abs(b.expirationTime - (now + 2.6)) < 1e-6 and sw(st, "oh") == nil, b and b.duration end }, "Attack")
R("swing bar keeps running between ticks", { noSpec = true, level = 1, rage = 0, knownOnly = L1, dt = 1,
  check = function(st) local b = sw(st) return b and b.up and math.abs(b.expirationTime - (now + 1.6)) < 1e-6, b and b.expirationTime end }, "Attack")
R("SWING_MISSED counts as a swing", { noSpec = true, level = 1, rage = 0, knownOnly = L1,
  before = function(E) reset(E) cl("SWING_MISSED", "Player-1-1") E:OnEvent("COMBAT_LOG_EVENT_UNFILTERED") end,
  check = function(st) local b = sw(st) return b and b.up, "missed" end }, "Attack")
R("someone else's swing is ignored", { noSpec = true, level = 1, rage = 0, knownOnly = L1,
  before = function(E) reset(E) cl("SWING_DAMAGE", "Creature-0-1") E:OnEvent("COMBAT_LOG_EVENT_UNFILTERED") end,
  check = function(st) local b = sw(st) return b and not b.up, "static ready bar" end }, "Attack")
R("not attacking, no swing -> swing bar hidden", { noSpec = true, level = 1, rage = 0, notAttacking = true, knownOnly = L1,
  before = function(E) reset(E) end, check = function(st) return sw(st) == nil, "hidden" end }, "Attack")
R("Fury dual wield: main + off-hand bars", { spec = 2, rage = 40, weap = TG, mhSpeed = 3.6, ohSpeed = 3.4,
  before = function(E) reset(E) cl("SWING_DAMAGE", "Player-1-1") E:OnEvent("COMBAT_LOG_EVENT_UNFILTERED") cl("SWING_MISSED", "Player-1-1", true) E:OnEvent("COMBAT_LOG_EVENT_UNFILTERED") end,
  check = function(st) local a, b = sw(st), sw(st, "oh") return a and b and a.up and b.up and a.duration == 3.6 and b.duration == 3.4, "mh/oh" end }, nil)
R("UNIT_ATTACK_SPEED rescales the running swing", { noSpec = true, level = 1, rage = 0, knownOnly = L1, mhSpeed = 4,
  before = function(E) reset(E) E.swing.mh = { s = now - 1, d = 2 } E:OnEvent("UNIT_ATTACK_SPEED", "player") end,
  check = function(st) local b = sw(st) return b and b.duration == 4 and math.abs(b.expirationTime - (now + 2)) < 1e-6, b and b.duration end }, "Attack")
R("swing timer option off -> hidden", { noSpec = true, level = 1, rage = 0, knownOnly = L1, cfg = { showSwing = false },
  before = function(E) reset(E) cl("SWING_DAMAGE", "Player-1-1") E:OnEvent("COMBAT_LOG_EVENT_UNFILTERED") end,
  check = function(st) return sw(st) == nil, "off" end }, "Attack")

print("\n== Cast feedback ==")
R("setup: HS suggested", { noSpec = true, level = 1, rage = 30, knownOnly = L1 }, "HeroicStrike")
R("HS cast while suggested -> Next pulses, Last Cast = HS (green)", { noSpec = true, level = 1, rage = 0, knownOnly = L1,
  before = function(E) E:OnEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-1", 78) end,
  check = function(st) local l = st("SWR Last Cast") return st("SWR Next").flash and l and icon(l, 78) and l.glow, "flash" end }, "Attack")
R("0.5 s later: pulse over, Last Cast still shown", { noSpec = true, level = 1, rage = 0, knownOnly = L1, dt = 0.5,
  check = function(st) local l = st("SWR Last Cast") return not st("SWR Next").flash and l and icon(l, 78), "after" end }, "Attack")
R("3 s later: Last Cast gone", { noSpec = true, level = 1, rage = 0, knownOnly = L1, dt = 3,
  check = function(st) return st("SWR Last Cast") == nil, "gone" end }, "Attack")
R("cast of an unsuggested spell: Last Cast, no pulse, no green", { noSpec = true, level = 1, rage = 0, knownOnly = L1,
  before = function(E) E:OnEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-2", 6673) end,
  check = function(st) local l = st("SWR Last Cast") return l and not l.glow and not st("SWR Next").flash, "plain" end }, "Attack")
R("other units' casts ignored", { noSpec = true, level = 1, rage = 0, knownOnly = L1, dt = 4,
  before = function(E) E:OnEvent("UNIT_SPELLCAST_SUCCEEDED", "target", "Cast-3", 78) end,
  check = function(st) return st("SWR Last Cast") == nil, "ignored" end }, "Attack")

print("\n== Interrupts ==")
local function intIs(st, sid) local it = st("SWR Interrupt") if sid == nil then return it == nil, "none" end return icon(it, sid) and it.expirationTime > now, "int" end
R("Pummel ready", { rage = 40, cast = true, check = function(st) return intIs(st, 6552) end }, nil)
R("Pummel out of range -> Disrupting Shout", { rage = 40, cast = true, oor = { [6552] = true }, talents = { 102060 }, check = function(st) return intIs(st, 102060) end }, nil)
R("Pummel cd -> Storm Bolt", { rage = 40, cast = true, cd = { [6552] = 10 }, talents = { 107570 }, check = function(st) return intIs(st, 107570) end }, nil)
R("Pummel cd, CC off -> nothing", { rage = 40, cast = true, cd = { [6552] = 10 }, talents = { 107570 }, cfg = { intCC = false }, check = function(st) return intIs(st, nil) end }, nil)
R("Uninterruptible -> nothing", { rage = 40, cast = { notInt = true }, check = function(st) return intIs(st, nil) end }, nil)
R("Interrupt in main icon option", { rage = 40, cast = true, cfg = { intMain = true }, check = function(st) return intIs(st, nil) end }, "Pummel")
R("Prot interrupt too", { spec = 3, rage = 30, stance = 71, cast = true, check = function(st) return intIs(st, 6552) end }, nil)

print("\n== Range / GCD / keybinds ==")
R("out of range -> red tint", { rage = 40, oor = { [86346] = true }, check = function(st) local x = st("SWR Next") return x.oor and x.oorTint, "oor" end }, "ColossusSmash")
R("GCD -> desaturated", { rage = 40, gcd = 0.7, check = function(st) return st("SWR Next").waiting, "gcd" end }, "ColossusSmash")
R("keybind read from action bar", { rage = 40, check = function(st) return st("SWR Next").keybind == "S2", st("SWR Next").keybind end }, "ColossusSmash")
R("rage bar orange near cap", { rage = 105, check = function(st) local b = st("SWR Rage") return b and b.dump and b.value == 105 and b.total == 120, "rage" end }, nil)
do local E = getE() print("     /dump SchizzleWarrior.R.why -> main=" .. tostring(E.R.why.main) .. " | " .. tostring(E.R.why.mode)) end
print(("\n%d passed, %d failed; sandbox warnings: %d"):format(P, F, #warnings))
for _, w in ipairs(warnings) do print("  warning", w.key, w.message) end
if F > 0 then os.exit(1) end
