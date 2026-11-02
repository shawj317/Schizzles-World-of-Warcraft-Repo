-- behavioural simulation of the mods in a Plater-like sandbox with a mocked WoW API (run via verify.lua)
SIM_FAILS = 0
local passed = 0
local function ok(c, msg) if c then passed = passed + 1 else SIM_FAILS = SIM_FAILS + 1; print("  SIM FAIL: " .. msg) end end

local S, calls, timers, frames
local function reset()
  S = { t = 100, class = "WARRIOR", spec = 71, forms = {}, defAura = false, role = "NONE", inGroup = true,
        playerCombat = true, lockdown = false, rage = 50, playerMax = 500000,
        known = {[6552] = true, [5308] = true}, cd = {}, range = {}, units = {},
        profiles = {"Default", "Schizzle's Warrior Arms", "Schizzle's Warrior Fury", "Schizzle's Warrior Protection"},
        current = "Schizzle's Warrior Arms", invalidEvents = {} }
  calls, timers, frames = {}, {}, {}
end
local function log(name, ...) calls[#calls + 1] = {name = name, args = {...}} end
local function count(name) local n = 0 for _, c in ipairs(calls) do if c.name == name then n = n + 1 end end return n end
local function last(name) for i = #calls, 1, -1 do if calls[i].name == name then return calls[i] end end end
local function runTimers() local q = timers; timers = {} for _, f in ipairs(q) do f() end end
local function fire(event, ...) for _, f in ipairs(frames) do if f.events[event] and f.script then f.script(f, event, ...) end end end

local function newFont()
  local f = {shown = false, text = "", color = {1, 1, 1, 1}}
  function f:SetPoint() end
  function f:SetText(t) self.text = t end
  function f:SetTextColor(r, g, b, a) self.color = {r, g, b, a} end
  function f:GetTextColor() return unpack(self.color) end
  function f:Show() self.shown = true end
  function f:Hide() self.shown = false end
  function f:GetFont() return "Fonts\\FRIZQT__.TTF", 10, "OUTLINE" end
  function f:SetFont(a, b, c) self.size = b end
  return f
end
local function newUnitFrame(unit)
  local uf = {unit = unit, displayedUnit = unit, CanCheckAggro = true, InCombat = true}
  uf.healthBar = {lifePercent = newFont()}
  uf.healthBar.lifePercent.color = {0.9, 0.9, 0.9, 1}
  function uf.healthBar:CreateFontString() return newFont() end
  uf.castBar = {}
  return uf
end

local Plater = {
  PlayerIsTank = false,
  UpdateNameplateThread = function(uf) log("UpdateNameplateThread", uf) end,
  StartPixelGlow = function(frame, color, opts, key) assert(type(opts) == "table"); log("StartPixelGlow", frame, key) end,
  StopPixelGlow = function(frame, key) log("StopPixelGlow", frame, key) end,
  SetCastBarColor = function(uf, c) log("SetCastBarColor", uf, c) end,
  FlashNameplateBorder = function(uf) log("Flash", uf) end,
  SetNameplateColor = function(uf, c) log("SetNameplateColor", uf, c) end,
  RefreshNameplateColor = function(uf) log("RefreshNameplateColor", uf) end,
  SetFontOutlineAndShadow = function() end,
}
-- PlaterAPI as in Plater_ImportExport.lua (GetProfiles returns an array of names)
local PlaterAPI = {
  GetProfileKeys = function(self) local r = {} for i, n in ipairs(S.profiles) do r[i] = n end return r end,
  GetCurrentProfileKey = function(self) return S.current end,
  SetProfile = function(self, key) log("SetProfile", key); S.current = key end,
}
local SPEC_ROLE = {[71] = "DAMAGER", [72] = "DAMAGER", [73] = "TANK"}
local function U(u) return S.units[u] end
local W = {
  Plater = Plater, PlaterAPI = PlaterAPI, print = function(...) log("print", ...) end,
  string = string, math = math, table = table, tonumber = tonumber, tostring = tostring, type = type,
  pairs = pairs, ipairs = ipairs, select = select, unpack = unpack, next = next,
  GetTime = function() return S.t end,
  UnitClass = function() return "Class", S.class end,
  C_SpecializationInfo = {
    GetSpecialization = function() return S.spec and (S.spec - 70) or 0 end,
    GetSpecializationInfo = function(i) local id = 70 + i; return id, "name", "", 0, SPEC_ROLE[id] end,
  },
  C_Timer = {After = function(d, f) timers[#timers + 1] = f end},
  C_EventUtils = {IsEventValid = function(e) return not S.invalidEvents[e] end},
  CreateFrame = function(kind)
    local f = {events = {}}
    function f:RegisterEvent(e) assert(not S.invalidEvents[e], "registered invalid event " .. e); self.events[e] = true end
    function f:SetScript(name, fn) self.script = fn end
    frames[#frames + 1] = f; log("CreateFrame")
    return f
  end,
  InCombatLockdown = function() return S.lockdown end,
  UnitPower = function(u, t) return S.rage end,
  GetNumShapeshiftForms = function() return #S.forms end,
  GetShapeshiftFormInfo = function(i) local f = S.forms[i]; return "tex", f.active, true, f.spellID end,
  AuraUtil = {FindAuraByName = function(name) if S.defAura and name == "Defensive Stance" then return name end end},
  UnitGroupRolesAssigned = function() return S.role end,
  UnitAffectingCombat = function(u) if u == "player" then return S.playerCombat end return U(u) and U(u).combat end,
  IsInGroup = function() return S.inGroup end,
  UnitIsUnit = function(a, b) local x = U(a); return x and ((b == "target" and x.target) or (b == "focus" and x.focus)) or false end,
  UnitExists = function(u) return U(u) ~= nil end,
  UnitCanAttack = function(_, u) return U(u) and U(u).hostile end,
  UnitIsDead = function(u) return U(u) and U(u).hp <= 0 end,
  UnitIsPlayer = function(u) return U(u) and U(u).player end,
  UnitHealth = function(u) return U(u).hp end,
  UnitHealthMax = function(u) if u == "player" then return S.playerMax end return U(u).max end,
  IsPlayerSpell = function(id) return S.known[id] or false end,
  IsSpellKnown = function(id) return S.known[id] or false end,
  C_Spell = {
    GetSpellCooldown = function(id) local c = S.cd[id]; if c then return {startTime = c[1], duration = c[2]} end return {startTime = 0, duration = 0} end,
    IsSpellInRange = function(id, u) local r = S.range[u]; if r == "nil" then return nil end return r end,
  },
}
local env = setmetatable({}, {
  __index = function(_, k) local v = W[k]; if v == nil and not tostring(k):match("^Schizzle") then error("sandbox: undefined global '" .. tostring(k) .. "'", 2) end return v end,
  __newindex = function(_, k, v) if tostring(k):match("^Schizzle") then W[k] = v else error("sandbox: mod wrote global '" .. tostring(k) .. "'", 2) end end,
})

local function loadMod(t, values)
  local mod = {hooks = {}, modTable = {config = {}}}
  for _, o in ipairs(t.options) do if o.Type ~= 5 and o.Type ~= 6 then mod.modTable.config[o.Key] = o.Value end end
  for k, v in pairs(values or {}) do mod.modTable.config[k] = v end
  for name, code in pairs(t["9"]) do
    local f = assert(loadstring("return " .. code, name))
    setfenv(f, env)
    mod.hooks[name] = f()
  end
  if mod.hooks["Initialization"] then mod.hooks["Initialization"](mod.modTable) end
  mod.envs = {}
  function mod.run(hook, self, unit, uf)
    local fn = mod.hooks[hook]; if not fn then return end
    mod.envs[uf] = mod.envs[uf] or {}
    return fn(self, unit, uf, mod.envs[uf], mod.modTable)
  end
  function mod.deinit() if mod.hooks["Deinitialization"] then mod.hooks["Deinitialization"](mod.modTable) end end
  return mod
end
local byName = {}
for _, m in ipairs(VERIFY_MODS) do byName[m.t["1"]] = m.t end
local function run(name, fn) reset(); W.SchizzleWarriorSpecSwitch = nil; local okk, err = pcall(fn); ok(okk, name .. ": " .. tostring(err)); if okk then print("  sim ok: " .. name) end end

-- ===== Spec switcher =====
local SW = byName["Schizzle's Warrior Spec Switcher"]
run("switch: login as Fury on the Arms profile -> Fury profile", function()
  S.spec = 72; S.playerCombat = false
  loadMod(SW); assert(count("SetProfile") == 0, "deferred"); runTimers()
  assert(count("SetProfile") == 1 and S.current == "Schizzle's Warrior Fury", "switched to fury")
end)
run("switch: already on the right profile -> nothing", function()
  S.spec = 71; S.playerCombat = false; loadMod(SW); runTimers(); fire("PLAYER_ENTERING_WORLD"); runTimers()
  assert(count("SetProfile") == 0)
end)
run("switch: dual-spec swap Arms -> Protection (talent group change)", function()
  S.playerCombat = false; local a = loadMod(SW); runTimers(); assert(count("SetProfile") == 0)
  S.spec = 73; fire("ACTIVE_TALENT_GROUP_CHANGED"); runTimers()
  assert(count("SetProfile") == 1 and S.current == "Schizzle's Warrior Protection")
  -- Plater recompiles: old copy deinits, the Protection profile's copy inits; no ping-pong
  a.deinit(); S.t = S.t + 10; loadMod(SW); runTimers()
  assert(count("SetProfile") == 1 and count("CreateFrame") == 1, "one frame, no second switch")
end)
run("switch: respec at a trainer (PLAYER_SPECIALIZATION_CHANGED), other units ignored", function()
  S.playerCombat = false; loadMod(SW); runTimers()
  S.spec = 72; fire("PLAYER_SPECIALIZATION_CHANGED", "party1"); runTimers(); assert(count("SetProfile") == 0, "party1 ignored")
  fire("PLAYER_SPECIALIZATION_CHANGED", "player"); runTimers(); assert(count("SetProfile") == 1)
end)
run("switch: waits for combat to end", function()
  S.spec = 73; S.playerCombat = true; loadMod(SW); runTimers(); assert(count("SetProfile") == 0, "in combat")
  fire("PLAYER_REGEN_ENABLED"); assert(#timers == 1, "scheduled"); S.playerCombat = false; runTimers()
  assert(count("SetProfile") == 1 and S.current == "Schizzle's Warrior Protection")
  fire("PLAYER_REGEN_ENABLED"); assert(#timers == 0, "regen ignored when nothing pending")
end)
run("switch: missing profile warns once, never switches", function()
  S.spec = 72; S.playerCombat = false; S.profiles = {"Default", "Schizzle's Warrior Arms"}
  loadMod(SW); runTimers(); fire("PLAYER_TALENT_UPDATE"); runTimers()
  assert(count("SetProfile") == 0 and count("print") == 1, "one warning")
end)
run("switch: auto off -> hint only; disabled; non-warrior", function()
  S.spec = 72; S.playerCombat = false
  local m = loadMod(SW, {autoSwitch = false}); runTimers(); fire("PLAYER_TALENT_UPDATE"); runTimers()
  assert(count("SetProfile") == 0 and count("print") == 1, "hint once")
  m.modTable.config.enabled = false; m.modTable.config.autoSwitch = true; fire("PLAYER_TALENT_UPDATE"); runTimers()
  assert(count("SetProfile") == 0, "disabled")
  m.modTable.config.enabled = true; S.class = "MONK"; fire("PLAYER_TALENT_UPDATE"); runTimers()
  assert(count("SetProfile") == 0, "non-warrior")
end)
run("switch: custom profile names, deinit stops it, invalid event not registered", function()
  S.invalidEvents.PLAYER_SPECIALIZATION_CHANGED = true; S.playerCombat = false
  S.profiles[#S.profiles + 1] = "My Fury"; S.spec = 72
  local m = loadMod(SW, {furyProfile = "My Fury"}); runTimers()
  assert(S.current == "My Fury", "custom name"); assert(not frames[1].events.PLAYER_SPECIALIZATION_CHANGED)
  m.deinit(); S.spec = 73; S.t = S.t + 10; fire("ACTIVE_TALENT_GROUP_CHANGED"); runTimers()
  assert(count("SetProfile") == 1, "inactive after deinit")
end)
run("switch: no more than one switch per 5 seconds", function()
  S.playerCombat = false; loadMod(SW); runTimers()
  S.spec = 72; fire("ACTIVE_TALENT_GROUP_CHANGED"); runTimers(); assert(count("SetProfile") == 1)
  S.spec = 71; S.t = S.t + 1; fire("ACTIVE_TALENT_GROUP_CHANGED"); runTimers(); assert(count("SetProfile") == 1, "throttled")
  S.t = S.t + 5; fire("ACTIVE_TALENT_GROUP_CHANGED"); runTimers(); assert(count("SetProfile") == 2)
end)

-- ===== Threat mode =====
local TH = byName["Schizzle's Warrior Threat Mode"]
local DPSV, PROTV = {useProtSpec = true, useDefensive = false}, {useProtSpec = true, useDefensive = true}
run("threat: Protection spec -> tank colours, immediate recolour once", function()
  S.spec = 73; local m = loadMod(TH, PROTV); local uf = newUnitFrame("nameplate1")
  m.run("Nameplate Updated", uf, "nameplate1", uf)
  assert(Plater.PlayerIsTank == true and count("UpdateNameplateThread") == 1)
  m.run("Nameplate Updated", uf, "nameplate1", uf); assert(count("UpdateNameplateThread") == 1, "no repeat")
end)
run("threat: Arms in Defensive Stance -> DPS on DPS profile, tank if option on", function()
  S.spec = 71; S.forms = {{spellID = 2457, active = false}, {spellID = 71, active = true}}
  Plater.PlayerIsTank = true; local m = loadMod(TH, DPSV); local uf = newUnitFrame("nameplate1")
  m.run("Nameplate Updated", uf, "nameplate1", uf); assert(Plater.PlayerIsTank == false, "dps profile")
  m.modTable.config.useDefensive = true; S.t = S.t + 1; m.run("Nameplate Updated", uf, "nameplate1", uf)
  assert(Plater.PlayerIsTank == true, "defensive = tank")
  S.forms[2].active = false; S.t = S.t + 0.1; m.run("Nameplate Updated", uf, "nameplate1", uf); assert(Plater.PlayerIsTank == true, "cached 0.2s")
  S.t = S.t + 0.2; m.run("Nameplate Updated", uf, "nameplate1", uf); assert(Plater.PlayerIsTank == false, "battle stance = dps")
end)
run("threat: aura fallback, force options, group role, non-warrior", function()
  S.spec = 71; S.defAura = true; local m = loadMod(TH, PROTV); local uf = newUnitFrame("nameplate1")
  m.run("Nameplate Updated", uf, "nameplate1", uf); assert(Plater.PlayerIsTank == true, "aura fallback")
  m.modTable.config.forceDps = true; S.t = S.t + 1; m.run("Nameplate Updated", uf, "nameplate1", uf); assert(Plater.PlayerIsTank == false, "forceDps")
  m.modTable.config.forceTank = true; S.t = S.t + 1; m.run("Nameplate Updated", uf, "nameplate1", uf); assert(Plater.PlayerIsTank == true, "forceTank wins")
  m.modTable.config.forceTank = false; m.modTable.config.forceDps = false; S.defAura = false
  m.modTable.config.useGroupRole = true; S.role = "TANK"; S.t = S.t + 1; m.run("Nameplate Updated", uf, "nameplate1", uf); assert(Plater.PlayerIsTank == true, "group role")
  S.class = "PALADIN"; Plater.PlayerIsTank = false; S.t = S.t + 1; local n = count("UpdateNameplateThread")
  m.run("Nameplate Updated", uf, "nameplate1", uf); assert(Plater.PlayerIsTank == false and count("UpdateNameplateThread") == n, "left alone")
end)

-- ===== Pummel ready =====
local KR = byName["Schizzle's Warrior Pummel Ready"]
local function cast(interruptible) return {casting = true, canInterrupt = interruptible} end
run("pummel: ready + in range -> glow; stop on cast end", function()
  local m = loadMod(KR); local uf = newUnitFrame("nameplate1"); S.units.nameplate1 = {}; S.range.nameplate1 = true
  local cb = cast(true)
  m.run("Cast Start", cb, "nameplate1", uf); assert(count("StartPixelGlow") == 1 and cb.schizzleWarKickState == "ready")
  S.t = S.t + 0.2; m.run("Cast Update", cb, "nameplate1", uf); assert(count("StartPixelGlow") == 1, "no restart")
  m.run("Cast Stop", cb, "nameplate1", uf); assert(count("StopPixelGlow") == 1)
end)
run("pummel: on cooldown -> tint; Disrupting Shout backup -> glow", function()
  local m = loadMod(KR); local uf = newUnitFrame("nameplate1"); S.units.nameplate1 = {}; S.range.nameplate1 = true
  S.cd[6552] = {S.t - 5, 15}
  local cb = cast(true); m.run("Cast Start", cb, "nameplate1", uf)
  assert(count("StartPixelGlow") == 0 and last("SetCastBarColor").args[2] == m.modTable.config.cdColor, "tinted (no backup known)")
  S.known[102060] = true; S.t = S.t + 0.2; m.run("Cast Update", cb, "nameplate1", uf)
  assert(count("StartPixelGlow") == 1 and last("SetCastBarColor").args[2] == nil, "backup ready -> glow, colour restored")
  S.cd[102060] = {S.t - 1, 40}; S.t = S.t + 0.2; m.run("Cast Update", cb, "nameplate1", uf)
  assert(count("StopPixelGlow") == 1 and cb.schizzleWarKickState == "cd", "both down -> cd")
  S.cd[6552] = nil; S.t = S.t + 0.2; m.run("Cast Update", cb, "nameplate1", uf); assert(count("StartPixelGlow") == 2, "pummel back")
end)
run("pummel: out of range / unknown range / not interruptible / GCD / target only", function()
  local m = loadMod(KR); local uf = newUnitFrame("nameplate1"); S.units.nameplate1 = {}
  S.range.nameplate1 = false; local cb = cast(true)
  m.run("Cast Start", cb, "nameplate1", uf); assert(count("StartPixelGlow") == 0 and cb.schizzleWarKickState == "none", "out of range")
  S.range.nameplate1 = "nil"; S.t = S.t + 0.2; m.run("Cast Update", cb, "nameplate1", uf); assert(count("StartPixelGlow") == 1, "nil range -> glow")
  local cb2 = cast(false); m.run("Cast Start", cb2, "nameplate1", uf); assert(count("StartPixelGlow") == 1, "not interruptible")
  S.range.nameplate1 = true; S.cd[6552] = {S.t, 1.0}; m.run("Cast Start", cast(true), "nameplate1", uf); assert(count("StartPixelGlow") == 2, "gcd ignored")
  m.modTable.config.onlyTargetFocus = true; m.run("Cast Start", cast(true), "nameplate1", uf); assert(count("StartPixelGlow") == 2, "not target")
  S.units.nameplate1.target = true; m.run("Cast Start", cast(true), "nameplate1", uf); assert(count("StartPixelGlow") == 3, "target")
  S.known[6552] = nil; m.run("Cast Start", cast(true), "nameplate1", uf); assert(count("StartPixelGlow") == 3, "pummel unknown")
end)

-- ===== Execute =====
local EX = byName["Schizzle's Warrior Execute"]
run("execute: 25% nothing, 15% red text + glow + tag, back up restores", function()
  local m = loadMod(EX); local uf = newUnitFrame("nameplate1")
  S.units.nameplate1 = {hostile = true, combat = true, hp = 25, max = 100}
  m.run("Nameplate Added", uf, "nameplate1", uf); assert(count("StartPixelGlow") == 0 and uf.healthBar.lifePercent.color[1] == 0.9)
  S.units.nameplate1.hp = 20; m.run("Health Update", uf, "nameplate1", uf)
  assert(count("StartPixelGlow") == 1 and uf.SchizzleExeTag.shown and uf.SchizzleExeTag.text == "EXE", "20% is execute range")
  assert(uf.healthBar.lifePercent.color[1] == 1 and uf.healthBar.lifePercent.color[2] == 0.25, "red text")
  S.units.nameplate1.hp = 10; m.run("Health Update", uf, "nameplate1", uf); assert(count("StartPixelGlow") == 1, "no restart")
  S.units.nameplate1.hp = 60; m.run("Health Update", uf, "nameplate1", uf)
  assert(uf.healthBar.lifePercent.color[1] == 0.9 and not uf.SchizzleExeTag.shown and count("StopPixelGlow") == 1, "restored")
end)
run("execute: rage gate, out of combat, unknown spell, friendly, dead", function()
  local m = loadMod(EX, {needRage = true}); local uf = newUnitFrame("nameplate1")
  S.units.nameplate1 = {hostile = true, combat = true, hp = 5, max = 100}
  S.rage = 10; m.run("Nameplate Updated", uf, "nameplate1", uf); assert(count("StartPixelGlow") == 0 and uf.healthBar.lifePercent.color[1] == 1, "low rage: text only")
  S.rage = 30; S.t = S.t + 0.3; m.run("Nameplate Updated", uf, "nameplate1", uf); assert(count("StartPixelGlow") == 1, "30 rage")
  S.units.nameplate1.combat = false; m.run("Nameplate Updated", uf, "nameplate1", uf); assert(count("StopPixelGlow") == 1, "ooc")
  S.units.nameplate1.combat = true; S.known[5308] = nil; S.t = S.t + 0.3; m.run("Nameplate Updated", uf, "nameplate1", uf); assert(count("StartPixelGlow") == 1, "unknown")
  S.known[5308] = true; S.t = S.t + 0.3; m.run("Nameplate Updated", uf, "nameplate1", uf); assert(count("StartPixelGlow") == 2)
  S.units.nameplate1.hostile = false; m.run("Nameplate Updated", uf, "nameplate1", uf); assert(count("StopPixelGlow") == 2, "friendly clears")
  S.units.nameplate1.hostile = true; S.units.nameplate1.hp = 0; m.run("Nameplate Updated", uf, "nameplate1", uf); assert(count("StartPixelGlow") == 2, "dead")
end)
run("execute: optional bar recolour", function()
  local m = loadMod(EX, {lowBar = true}); local uf = newUnitFrame("nameplate1")
  S.units.nameplate1 = {hostile = true, combat = true, hp = 10, max = 100}
  m.run("Nameplate Updated", uf, "nameplate1", uf); assert(count("SetNameplateColor") == 1)
  S.units.nameplate1.hp = 90; m.run("Nameplate Updated", uf, "nameplate1", uf); assert(count("RefreshNameplateColor") == 1)
  m.run("Nameplate Removed", uf, "nameplate1", uf)
end)

-- ===== Threat % =====
local TP = byName["Schizzle's Warrior Threat %"]
run("threat %: DPS warning, tank not-secure, solo", function()
  local m = loadMod(TP); local uf = newUnitFrame("nameplate1")
  Plater.PlayerIsTank = false; uf.namePlateThreatStatus = 1; uf.namePlateThreatPercent = 85.4
  m.run("Nameplate Updated", uf, "nameplate1", uf); assert(uf.SchizzleThreatText.shown and uf.SchizzleThreatText.text == "85%")
  uf.namePlateThreatPercent = 50; m.run("Nameplate Updated", uf, "nameplate1", uf); assert(not uf.SchizzleThreatText.shown)
  Plater.PlayerIsTank = true; uf.namePlateThreatStatus = 3; uf.namePlateThreatPercent = 100
  m.run("Nameplate Updated", uf, "nameplate1", uf); assert(not uf.SchizzleThreatText.shown, "secure tank hidden")
  uf.namePlateThreatStatus = 0; uf.namePlateThreatPercent = 92
  m.run("Nameplate Updated", uf, "nameplate1", uf); assert(uf.SchizzleThreatText.shown and uf.SchizzleThreatText.text == "92%")
  S.inGroup = false; m.run("Nameplate Updated", uf, "nameplate1", uf); assert(not uf.SchizzleThreatText.shown, "solo hidden")
end)
print(("simulation: %d passed, %d failed"):format(passed, SIM_FAILS))
