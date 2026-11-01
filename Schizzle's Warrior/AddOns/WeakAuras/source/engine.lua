-- Schizzle's Warrior Rotation engine (shared by every aura in the "Schizzle's Warrior Rotation" group)
-- Arms + Fury (Titan's Grip / Single-Minded Fury) + Protection, MoP Classic 5.5.x.
-- Every spell is gated by IsPlayerSpell, so talent tiers 4 (Bladestorm / Shockwave / Dragon Roar) and
-- 6 (Avatar / Bloodbath / Storm Bolt) only show the talent you actually picked.
-- Before level 10 (no specialisation yet) it runs a Leveling priority built from the spells you have learned.
-- Debug: /dump SchizzleWarrior.R.why
local VERSION = 2
if SchizzleWarrior and SchizzleWarrior.v and SchizzleWarrior.v >= VERSION then
  SchizzleWarrior.cfg = aura_env.config or SchizzleWarrior.cfg
  return
end
local E = { v = VERSION, cfg = aura_env.config or {}, last = 0, R = {}, keys = {}, keysByName = {}, keysrc = {}, keysAt = -99 }
SchizzleWarrior = E

-- spell IDs verified against MoP Classic client data (build 5.5.4.70631)
local ID = {
  -- Arms
  ms = 12294, op = 7384, slam = 1464, sweep = 12328,
  -- Fury
  bt = 23881, rb = 85288, wild = 100130, tg = 46917, smf = 81099,
  -- Protection
  sslam = 23922, rev = 6572, dev = 20243, sunder = 7386, sblock = 2565, sbarrier = 112048, lstand = 12975, demo = 1160,
  -- shared
  cs = 86346, exe = 5308, hs = 78, cleave = 845, ww = 1680, tc = 6343,
  reck = 1719, skull = 114207, bshout = 6673, cshout = 469, brage = 18499, leap = 6544, hthrow = 57755,
  pummel = 6552, sref = 23920, dbts = 118038, rcry = 97462, swall = 871, vr = 34428,
  battle = 2457, def = 71, bers = 2458,
  -- Charge: MoP Classic 5.5 uses 1250619 (level 3); 100 is the older ID, kept as a fallback
  charge = 1250619, chargeOld = 100,
  -- talents (tier 2 / 3 / 4 / 6)
  eregen = 55694, iv = 103840, dshout = 102060,
  bstorm = 46924, shock = 46968, droar = 118000,
  avatar = 107574, bbath = 12292, sbolt = 107570,
  -- glyphs
  gagOrder = 58357,
  -- racials
  quaking = 107079, warstomp = 20549,
  -- auras
  enrage = 12880, rbCharges = 131116, bsurge = 46916, tfb = 60503, sdeath = 52437, sexec = 139958,
  ult = 122510, snb = 50227, mcleaver = 85739, sblockBuff = 132404, incite = 122016,
  -- passives that unlock the trackers above
  sdeathTal = 29725, mcTal = 12950, bsTal = 46915, ultTal = 122509, snbTal = 46953,
  wblows = 115798, warmor = 113746, dwounds = 115767, victorious = 32216, skullBuff = 114206,
}
E.ID = ID

local function known(id)
  if not id then return false end
  if IsPlayerSpell and IsPlayerSpell(id) then return true end
  if C_SpellBook and C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(id) then return true end
  return false
end
E.known = known

local function spellName(id)
  if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
  return GetSpellInfo and (GetSpellInfo(id)) or tostring(id)
end
local function spellIcon(id)
  if C_Spell and C_Spell.GetSpellTexture then return C_Spell.GetSpellTexture(id) end
  return GetSpellTexture and GetSpellTexture(id) or 134400
end

-- cooldown remaining, ignoring the GCD; returns remaining, start, duration
local function cd(id, now)
  local info = C_Spell and C_Spell.GetSpellCooldown and C_Spell.GetSpellCooldown(id)
  if type(info) ~= "table" then return 0, 0, 0 end
  local s, d = info.startTime or 0, info.duration or 0
  if s == 0 or d == 0 or info.isOnGCD or d <= 1.5 then return 0, 0, 0 end
  local rem = s + d - now
  if rem < 0 then rem = 0 end
  return rem, s, d
end
local function charges(id)
  local c = C_Spell and C_Spell.GetSpellCharges and C_Spell.GetSpellCharges(id)
  if type(c) == "table" then return c.currentCharges or 0, c.maxCharges or 0 end
  return nil
end
local function usable(id)
  if C_Spell and C_Spell.IsSpellUsable then return (C_Spell.IsSpellUsable(id)) end
  if IsUsableSpell then return (IsUsableSpell(id)) end
  return true
end

-- aura scan by index (works on MoP Classic; GetPlayerAuraBySpellID does not)
local function scan(unit, filter, out, now)
  for k in pairs(out) do out[k] = nil end
  if not UnitExists(unit) then return out end
  local get = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
  for i = 1, 40 do
    local a = get and get(unit, i, filter)
    if not a then break end
    local rec = { rem = (a.expirationTime and a.expirationTime > 0) and (a.expirationTime - now) or 999,
                  exp = a.expirationTime or 0, dur = a.duration or 0, stacks = a.applications or 0,
                  points = type(a.points) == "table" and a.points[1] or nil }
    if a.spellId then out[a.spellId] = rec end
    if a.name and not out[a.name] then out[a.name] = rec end
  end
  return out
end
-- TDEBUFF = my debuffs on the target; TDEBUFF_ALL = anyone's (Weakened Blows / Weakened Armor are shared raid debuffs)
local BUFF, DEBUFF, TDEBUFF, TDEBUFF_ALL = {}, {}, {}, {}
local function auraId(tbl, id) return tbl[id] end
local function aura(tbl, id)
  local r = tbl[id]
  if r then return r end
  local n = spellName(id)
  if n then r = tbl[n] end
  if not r and tbl == BUFF and AuraUtil and AuraUtil.FindAuraByName and n then
    local _, _, count, _, duration, expirationTime = AuraUtil.FindAuraByName(n, "player", "HELPFUL")
    if expirationTime then
      r = { rem = expirationTime > 0 and (expirationTime - GetTime()) or 999, exp = expirationTime, dur = duration or 0, stacks = count or 0 }
    end
  end
  return r
end
local function rem(tbl, id) local r = aura(tbl, id) return r and r.rem or 0 end
local function stacks(tbl, id) local r = aura(tbl, id) return r and r.stacks or 0 end

-- keybinds ---------------------------------------------------------------
-- v2: read the action buttons that are actually on screen (Blizzard, Bartender4, ElvUI, Dominos),
-- prefer a direct spell over a macro, match by spell ID, base/override ID and name.
local function abbrev(k)
  if not k or k == "" then return nil end
  k = k:gsub("SHIFT%-", "S"):gsub("CTRL%-", "C"):gsub("ALT%-", "A"):gsub("META%-", "M")
  k = k:gsub("MOUSEWHEELUP", "WU"):gsub("MOUSEWHEELDOWN", "WD"):gsub("MIDDLEMOUSE", "M3")
  k = k:gsub("BUTTON(%d+)", "M%1"):gsub("NUMPAD", "N"):gsub("SPACE", "Spc")
  return k
end
local BLIZZ = {
  { "ActionButton", "ACTIONBUTTON" }, { "MultiBarBottomLeftButton", "MULTIACTIONBAR1BUTTON" },
  { "MultiBarBottomRightButton", "MULTIACTIONBAR2BUTTON" }, { "MultiBarRightButton", "MULTIACTIONBAR3BUTTON" },
  { "MultiBarLeftButton", "MULTIACTIONBAR4BUTTON" }, { "MultiBar5Button", "MULTIACTIONBAR5BUTTON" },
  { "MultiBar6Button", "MULTIACTIONBAR6BUTTON" }, { "MultiBar7Button", "MULTIACTIONBAR7BUTTON" },
}
-- page -> binding prefix for the raw fallback (5.5: MultiBar actionpage 6,5,3,4,13,14,15)
local PAGEBIND = { [6] = "MULTIACTIONBAR1BUTTON", [5] = "MULTIACTIONBAR2BUTTON", [3] = "MULTIACTIONBAR3BUTTON",
  [4] = "MULTIACTIONBAR4BUTTON", [13] = "MULTIACTIONBAR5BUTTON", [14] = "MULTIACTIONBAR6BUTTON", [15] = "MULTIACTIONBAR7BUTTON" }
local function mainPage()
  local AB = C_ActionBar
  if AB and AB.HasBonusActionBar and AB.HasBonusActionBar() and AB.GetBonusBarIndex then
    local b = AB.GetBonusBarIndex()
    if b and b > 0 then return b end
  end
  if AB and AB.GetActionBarPage then return AB.GetActionBarPage() or 1 end
  if GetActionBarPage then return GetActionBarPage() or 1 end
  return 1
end
local function slotSpell(slot)
  if not (slot and GetActionInfo) then return nil end
  local t, id, sub = GetActionInfo(slot)
  if t == "spell" and id then return id, "spell" end
  if t == "macro" then
    if sub == "spell" and id then return id, "macro" end
    local ms = GetMacroSpell and id and GetMacroSpell(id)
    if ms then return ms, "macro" end
  end
  return nil
end
local function bindingFor(btn, name, cmd)
  if not GetBindingKey then return nil end
  local key = cmd and GetBindingKey(cmd)
  key = key or GetBindingKey("CLICK " .. name .. ":LeftButton") or GetBindingKey("CLICK " .. name .. ":Keybind")
           or GetBindingKey("CLICK " .. name .. ":HOTKEY")
  if key then return abbrev(key), cmd or ("CLICK " .. name) end
  local hk = btn and btn.HotKey and btn.HotKey.GetText and btn.HotKey:GetText()
  if hk and hk ~= "" and hk ~= RANGE_INDICATOR and hk ~= "\226\151\143" then return hk, "HotKey text" end
  return nil
end
local function visible(btn) return btn and btn.IsVisible and btn:IsVisible() and true or false end
local function btnSlot(btn)
  if not btn then return nil end
  if btn.GetAction then
    local t, a = btn:GetAction()
    if t == "action" and type(a) == "number" then return a end
  end
  if type(btn._state_action) == "number" then return btn._state_action end
  if type(btn.action) == "number" then return btn.action end
  return nil
end

function E:RefreshKeys(now)
  local keys, keysrc, byName = {}, {}, {}
  local seenSlot = {}
  local function offer(spell, kind, slot, key, src, vis)
    if not (spell and key) then return end
    -- score: visible > hidden, spell > macro, earlier button wins ties
    local score = (vis and 4 or 0) + (kind == "spell" and 2 or 0)
    local nm = spellName(spell)
    local desc = string.format("slot %d %s via %s%s", slot or 0, kind, src, vis and "" or " (hidden)")
    local cur = keys[spell]
    if not cur or score > cur.score then keys[spell] = { key = key, score = score, desc = desc, slot = slot } end
    if nm then
      local c2 = byName[nm]
      if not c2 or score > c2.score then byName[nm] = { key = key, score = score, desc = desc, slot = slot } end
      keysrc[nm] = keysrc[nm] or { all = {} }
      local all = keysrc[nm].all
      all[#all + 1] = key .. " <- " .. desc
    end
  end
  local G = _G
  -- 1) Blizzard buttons, 12 per bar, using the slot each button really shows (paging/bonus bars included)
  for _, b in ipairs(BLIZZ) do
    for i = 1, 12 do
      local name = b[1] .. i
      local btn = G[name]
      local slot = btnSlot(btn)
      if slot then
        local spell, kind = slotSpell(slot)
        if spell then
          local key, src = bindingFor(btn, name, btn.bindingAction or (b[2] .. i))
          offer(spell, kind, slot, key, name .. (src and (" " .. src) or ""), visible(btn))
          if visible(btn) then seenSlot[slot] = true end
        end
      end
    end
  end
  -- 2) action bar addons (LibActionButton / Dominos)
  local addonButtons = {}
  for i = 1, 180 do addonButtons[#addonButtons + 1] = "BT4Button" .. i; addonButtons[#addonButtons + 1] = "DominosActionButton" .. i end
  for bar = 1, 15 do for i = 1, 12 do addonButtons[#addonButtons + 1] = "ElvUI_Bar" .. bar .. "Button" .. i end end
  for _, name in ipairs(addonButtons) do
    local btn = G[name]
    if btn then
      local slot = btnSlot(btn)
      if slot then
        local spell, kind = slotSpell(slot)
        if spell then
          local cmd = btn.config and btn.config.keyBoundTarget or btn.bindingAction or btn.commandName
          local key, src = bindingFor(btn, name, cmd)
          offer(spell, kind, slot, key, name .. (src and (" " .. src) or ""), visible(btn))
          if visible(btn) then seenSlot[slot] = true end
        end
      end
    end
  end
  -- 3) raw fallback for slots no visible button covered (uses current page / stance bar)
  local mp = mainPage()
  for slot = 1, 180 do
    if not seenSlot[slot] then
      local spell, kind = slotSpell(slot)
      if spell then
        local page = math.floor((slot - 1) / 12) + 1
        local i = (slot - 1) % 12 + 1
        local cmd = (page == mp and "ACTIONBUTTON" .. i) or (PAGEBIND[page] and PAGEBIND[page] .. i)
        if cmd and GetBindingKey then
          local key = abbrev(GetBindingKey(cmd))
          if key then offer(spell, kind, slot, key, cmd .. " (raw)", false) end
        end
      end
    end
  end
  for nm, rec in pairs(keysrc) do local best = byName[nm] if best then rec.key, rec.src, rec.slot = best.key, best.desc, best.slot end end
  self.keys, self.keysByName, self.keysrc = keys, byName, keysrc
  self.keysAt = now
end
function E:Key(id)
  if self.cfg.showKeys == false then return "" end
  local k = self.keys[id]
  if not k and C_Spell and C_Spell.GetOverrideSpell then local o = C_Spell.GetOverrideSpell(id) if o then k = self.keys[o] end end
  if not k and FindBaseSpellByID then local b = FindBaseSpellByID(id) if b then k = self.keys[b] end end
  local n = spellName(id)
  local kn = n and self.keysByName and self.keysByName[n]
  -- name match catches rank/override IDs; take it when it scores better (e.g. visible direct spell)
  if kn and (not k or kn.score > k.score) then k = kn end
  return k and k.key or ""
end

-- environment --------------------------------------------------------------
local function enemies(range)
  local n = 0
  local plates = C_NamePlate and C_NamePlate.GetNamePlates and C_NamePlate.GetNamePlates()
  if type(plates) == "table" then
    for _, p in ipairs(plates) do
      local u = p.namePlateUnitToken or (p.UnitFrame and p.UnitFrame.unit)
      if u and UnitCanAttack("player", u) and not UnitIsDead(u) and (UnitAffectingCombat(u) or UnitIsUnit(u, "target")) then
        local inRange = true
        if WeakAuras and WeakAuras.CheckRange then inRange = WeakAuras.CheckRange(u, range, "<=") end
        if inRange then n = n + 1 end
      end
    end
  end
  if n == 0 and UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target") then n = 1 end
  return n
end

-- stance: loop every stance button and compare spell ID and name (no fixed index)
local STANCES = { ID.battle, ID.def, ID.bers }
local function activeStance()
  local names = {}
  for _, s in ipairs(STANCES) do local nm = spellName(s) if nm then names[nm] = s end end
  if GetNumShapeshiftForms and GetShapeshiftFormInfo then
    for i = 1, (GetNumShapeshiftForms() or 0) do
      local _, active, _, id = GetShapeshiftFormInfo(i)
      if active then
        for _, s in ipairs(STANCES) do if id == s then return s, "loop" end end
        local nm = id and spellName(id)
        if nm and names[nm] then return names[nm], "loop name" end
        return id, "loop"
      end
    end
  end
  for _, s in ipairs(STANCES) do if aura(BUFF, s) then return s, "aura" end end
  return nil, "none"
end
E.activeStance = activeStance
local STANCE_NAME = { [ID.battle] = "Battle", [ID.def] = "Defensive", [ID.bers] = "Berserker" }

-- Fury weapon mode: Titan's Grip = a two-hander in the off hand, Single-Minded Fury = two one-handers
local function furyWeapons(cfg)
  local m = tonumber(cfg.fuMode) or 1
  if m == 2 then return "TG" elseif m == 3 then return "SMF" end
  local oh = GetInventoryItemID and GetInventoryItemID("player", 17)
  local mh = GetInventoryItemID and GetInventoryItemID("player", 16)
  local function loc(item)
    if not item then return nil end
    local f = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if not f then return nil end
    local _, _, _, equipLoc = f(item)
    return equipLoc
  end
  local ohLoc, mhLoc = loc(oh), loc(mh)
  if ohLoc == "INVTYPE_2HWEAPON" or (mhLoc == "INVTYPE_2HWEAPON" and ohLoc) then return "TG" end
  if ohLoc == "INVTYPE_WEAPON" or ohLoc == "INVTYPE_WEAPONOFFHAND" or ohLoc == "INVTYPE_WEAPONMAINHAND" then return "SMF" end
  if mhLoc == "INVTYPE_2HWEAPON" then return "2H" end -- Fury with one two-hander: play it like Titan's Grip
  return "TG"
end
E.furyWeapons = furyWeapons

-- interrupt candidates: Pummel first, then Disrupting Shout / stuns / racials as fallbacks
local ARCANE_TORRENT = { 69179, 129597, 28730, 25046, 50613, 80483 }
local function castInfo(unit)
  if not (UnitExists(unit) and UnitCanAttack("player", unit) and not UnitIsDead(unit)) then return nil end
  if UnitCastingInfo then
    local name, _, tex, st, en, _, _, notInt, sid = UnitCastingInfo(unit)
    if name then return { name = name, icon = tex, start = (st or 0) / 1000, finish = (en or 0) / 1000, interruptible = not notInt, unit = unit, spellId = sid } end
  end
  if UnitChannelInfo then
    local name, _, tex, st, en, _, notInt, sid = UnitChannelInfo(unit)
    if name then return { name = name, icon = tex, start = (st or 0) / 1000, finish = (en or 0) / 1000, interruptible = not notInt, unit = unit, spellId = sid, channel = true } end
  end
  return nil
end
local function inRange(id, unit, yards)
  if yards then
    if WeakAuras and WeakAuras.CheckRange then return WeakAuras.CheckRange(unit, yards, "<=") and true or false end
    return true
  end
  local r
  if C_Spell and C_Spell.IsSpellInRange then r = C_Spell.IsSpellInRange(id, unit)
  elseif IsSpellInRange then r = IsSpellInRange(spellName(id) or "", unit) end
  if r == false or r == 0 then return false end
  return true
end
local function pickInterrupt(S, cfg)
  if cfg.showInt == false then return nil end
  local units = { "target" }
  if cfg.intFocus then units[2] = "focus" end
  for _, u in ipairs(units) do
    local c = castInfo(u)
    if c and c.interruptible and c.finish > S.now then
      local list = { { ID.pummel } }
      -- Disrupting Shout shares Pummel's lockout; it only helps when Pummel is out of reach (10 yd AoE)
      list[#list + 1] = { ID.dshout, 10 }
      if cfg.intCC ~= false then
        list[#list + 1] = { ID.sbolt }
        list[#list + 1] = { ID.shock, 10 }
        if known(ID.gagOrder) then list[#list + 1] = { ID.hthrow } end
        list[#list + 1] = { ID.quaking }
        for _, a in ipairs(ARCANE_TORRENT) do list[#list + 1] = { a, 8 } end
        list[#list + 1] = { ID.warstomp, 8 }
      end
      local why = {}
      for _, l in ipairs(list) do
        local id = l[1]
        if known(id) then
          local r = cd(id, S.now)
          if r > 0.25 then why[#why + 1] = (spellName(id) or id) .. " on cd"
          elseif not inRange(id, u, l[2]) then why[#why + 1] = (spellName(id) or id) .. " out of range"
          else return { id = id, unit = u, cast = c, why = why } end
        end
      end
      E.intWhy = why
      return nil
    end
  end
  return nil
end

-- snapshot of everything the priorities read
function E:Snapshot(now)
  local S = {}
  local cfg = self.cfg
  S.now = now
  -- read every tick, so picking a spec at level 10 (or swapping specs) switches the priority straight away
  local spec = (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization and C_SpecializationInfo.GetSpecialization())
               or (GetSpecialization and GetSpecialization())
  spec = tonumber(spec) or 0
  if spec ~= 1 and spec ~= 2 and spec ~= 3 then spec = 0 end -- nil / 0 / 5 = no specialisation yet (levels 1-9)
  S.spec = spec
  S.arms, S.fury, S.prot = spec == 1, spec == 2, spec == 3
  S.leveling = spec == 0
  S.level = (UnitLevel and tonumber(UnitLevel("player"))) or 90
  if S.level < 1 then S.level = 90 end
  S.rage = UnitPower("player", 1) or 0
  S.rageMax = UnitPowerMax("player", 1) or 100
  if S.rageMax < 1 then S.rageMax = 100 end
  S.dump = S.rageMax - (tonumber(cfg.dumpMargin) or 20) -- Heroic Strike / Cleave rage-dump threshold
  local hpMax = UnitHealthMax("player") or 1
  S.hp = 100 * (UnitHealth("player") or 0) / (hpMax > 0 and hpMax or 1)
  scan("player", "HELPFUL", BUFF, now)
  scan("player", "HARMFUL", DEBUFF, now)
  scan("target", "HARMFUL|PLAYER", TDEBUFF, now)
  scan("target", "HARMFUL", TDEBUFF_ALL, now)
  S.gcdRem, S.gcdStart, S.gcdDur = E.gcd(now)
  S.combat = UnitAffectingCombat("player") and true or false
  S.hostile = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target")
  local thm = UnitExists("target") and UnitHealthMax("target") or 0
  S.thp = (thm and thm > 0) and (100 * (UnitHealth("target") or 0) / thm) or 100
  S.exec = S.hostile and S.thp <= 20 and known(ID.exe)
  S.n = enemies(8)
  S.aoe = S.n >= (tonumber(cfg.aoe) or 3)
  S.stance, S.stanceSrc = activeStance()
  S.boss = UnitExists("target") and UnitClassification and UnitClassification("target") ~= "normal" and UnitClassification("target") ~= "minus" and UnitClassification("target") ~= "trivial"
  S.cs = rem(TDEBUFF, ID.cs)
  S.csCd = known(ID.cs) and cd(ID.cs, now) or 99
  S.enraged = (aura(BUFF, ID.enrage) or auraId(BUFF, ID.brage)) and true or false
  S.tanking = UnitExists("target") and UnitDetailedThreatSituation and (UnitDetailedThreatSituation("player", "target")) and true or false
  if S.fury then S.weap = furyWeapons(cfg) end
  -- Protection mode: 1 Auto, 2 Tank, 3 DPS
  if S.prot then
    local mode = tonumber(cfg.protMode) or 1
    if mode == 2 then S.tank = true
    elseif mode == 3 then S.tank = false
    else
      local role = UnitGroupRolesAssigned and UnitGroupRolesAssigned("player")
      S.tank = (S.stance == ID.def or role == "TANK" or S.tanking) and true or false
    end
  else
    S.tank = false
  end
  S.int = pickInterrupt(S, cfg)
  return S
end

-- range. Self / no-range spells always count as in range; point-blank AoE uses an 8 or 10 yd check.
local NORANGE = { [ID.battle] = true, [ID.def] = true, [ID.bers] = true, [ID.bshout] = true, [ID.cshout] = true,
  [ID.reck] = true, [ID.avatar] = true, [ID.bbath] = true, [ID.skull] = true, [ID.brage] = true, [ID.sblock] = true,
  [ID.sbarrier] = true, [ID.swall] = true, [ID.lstand] = true, [ID.rcry] = true, [ID.dbts] = true, [ID.eregen] = true,
  [ID.sweep] = true, [ID.sref] = true }
local AOE8 = { [ID.tc] = true, [ID.ww] = true, [ID.bstorm] = true, [ID.droar] = true, [ID.warstomp] = true,
  [69179] = true, [129597] = true, [28730] = true, [25046] = true, [50613] = true, [80483] = true }
local AOE10 = { [ID.demo] = true, [ID.shock] = true, [ID.dshout] = true }
-- melee spells: used only when the API returns nil for them
local MELEE5 = { [ID.ms] = true, [ID.cs] = true, [ID.op] = true, [ID.slam] = true, [ID.exe] = true, [ID.hs] = true,
  [ID.cleave] = true, [ID.sslam] = true, [ID.rev] = true, [ID.dev] = true, [ID.sunder] = true, [ID.bt] = true,
  [ID.rb] = true, [ID.wild] = true, [ID.vr] = true, [ID.iv] = true, [ID.pummel] = true, [ID.quaking] = true }
local function meleeCheck(yards)
  if WeakAuras and WeakAuras.CheckRange then return WeakAuras.CheckRange("target", yards, "<=") and true or false end
  if CheckInteractDistance then local ok = CheckInteractDistance("target", 3) if ok ~= nil then return ok and true or false end end
  return true
end
local function outOfRange(id)
  if not id or NORANGE[id] then return false end
  if not (UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target")) then return false end
  if AOE8[id] then return not meleeCheck(8) end
  if AOE10[id] then return not meleeCheck(10) end
  local r
  local name = spellName(id)
  if IsSpellInRange and name then r = IsSpellInRange(name, "target") end
  if r == nil and C_Spell and C_Spell.IsSpellInRange then r = C_Spell.IsSpellInRange(id, "target") end
  if r == 0 or r == false then return true end
  if r == 1 or r == true then return false end
  if MELEE5[id] then return not meleeCheck(5) end
  return false
end
E.outOfRange = outOfRange

-- helpers used by priority lists
local function ready(id, S, lead) return known(id) and cd(id, S.now) <= (lead or 0.25) end
E.cd, E.aura, E.rem, E.stacks, E.BUFF, E.DEBUFF, E.TDEBUFF, E.TDEBUFF_ALL = cd, aura, rem, stacks, BUFF, DEBUFF, TDEBUFF, TDEBUFF_ALL
local function adder(out)
  return function(id, f, why) out[#out + 1] = { id = id, glow = f and f.glow, wait = f and f.wait, why = why, tag = f and f.tag } end
end
local function talent4(S, add, csOnly)
  -- tier 4: Bladestorm (AoE or CS window), Dragon Roar (on cooldown), Shockwave (AoE / cooldown)
  if ready(ID.droar, S) and S.hostile then add(ID.droar, nil, "Dragon Roar on cooldown (ignores armor)") return end
  if ready(ID.bstorm, S) and S.hostile and (S.aoe or not csOnly or S.cs > 4) then add(ID.bstorm, nil, S.aoe and "Bladestorm (AoE)" or "Bladestorm in CS window") return end
  if ready(ID.shock, S) and S.hostile and (S.n >= 2 or S.prot) then add(ID.shock, nil, "Shockwave") end
end
local function shout(S, add)
  -- Battle / Commanding Shout are rage generators (+20) on a shared 60 s cooldown
  if S.rage <= S.rageMax - 30 then
    local which = (tonumber(E.cfg.shout) or 1) == 2 and ID.cshout or ID.bshout
    if ready(which, S) then add(which, nil, "Shout for rage") end
  end
end
local function victory(S, add, hpLimit)
  if known(ID.iv) and ready(ID.iv, S) and S.hp < hpLimit and S.rage >= 10 then add(ID.iv, nil, "Impending Victory heal") return end
  if not known(ID.iv) and known(ID.vr) and aura(BUFF, ID.victorious) and S.hp < hpLimit then add(ID.vr, nil, "Victory Rush heal") end
end

-- Leveling (levels 1-9, no specialisation): Battle Stance, Heroic Strike as the main attack, Charge to pull (3),
-- Victory Rush (5), Execute (7). Every entry is gated by IsPlayerSpell, so it only shows what you have learned.
local function chargeId()
  if known(ID.charge) then return ID.charge end
  if known(ID.chargeOld) then return ID.chargeOld end
  return nil
end
local function gapCloser(S, add)
  if not S.hostile or meleeCheck(5) then return end
  local ch = chargeId()
  if ch and ready(ch, S) and not outOfRange(ch) then add(ch, { glow = true }, "Charge: target out of melee range") return end
  if ready(ID.hthrow, S) and not outOfRange(ID.hthrow) then add(ID.hthrow, nil, "Heroic Throw: target out of melee range") end
end
local function victorious(S) return known(ID.vr) and aura(BUFF, ID.victorious) ~= nil end
local function leveling(S, out)
  local add = adder(out)
  local vic = victorious(S)
  if known(ID.iv) and ready(ID.iv, S) and S.hp < 60 and S.rage >= 10 then add(ID.iv, { glow = true }, "Impending Victory heal") end
  if vic and S.hp < 70 then add(ID.vr, { glow = true }, "Victory Rush: heal") end
  gapCloser(S, add)
  if S.exec and S.rage >= 30 then add(ID.exe, { glow = true }, "Execute: target below 20%") end
  if vic and S.hostile then add(ID.vr, nil, "Victory Rush (free hit before the proc ends)") end
  if S.hostile and S.n >= 2 and ready(ID.tc, S) and S.rage >= 20 then add(ID.tc, nil, "2+ enemies: Thunder Clap") end
  if S.hostile and ready(ID.hs, S) and S.rage >= 30 then add(ID.hs, nil, "Heroic Strike: main attack while leveling") end
  if S.hostile and known(ID.sunder) and S.rage >= 15 and stacks(TDEBUFF_ALL, ID.warmor) < 3 then add(ID.sunder, nil, "Sunder Armor") end
  shout(S, add)
  if known(ID.hs) then add(ID.hs, { wait = true }, "waiting for rage (Heroic Strike at 30)") end
end
-- freshly specced (levels 10-19): few spec spells yet, so add the leveling basics around the spec priority
local function earlySpec(S, list)
  local pre = {}
  local add = adder(pre)
  gapCloser(S, add)
  if not list[1] or list[1].wait then
    if victorious(S) and S.hostile then add(ID.vr, nil, "Victory Rush (free hit)") end
    if S.hostile and ready(ID.hs, S) and S.rage >= 30 then add(ID.hs, nil, "Heroic Strike: spare rage while spec spells are on cooldown") end
  end
  for i = #pre, 1, -1 do table.insert(list, 1, pre[i]) end
end

-- each priority list: Icy Veins / Warcraft Tavern / Wowhead MoP Classic guides (see README)
local function arms(S, out)
  local add = adder(out)
  local tfb = stacks(BUFF, ID.tfb)
  local sd = aura(BUFF, ID.sdeath) ~= nil
  local inCS = S.cs > 0.5
  S.tfbStacks = tfb
  victory(S, add, 50)
  if S.aoe then
    if ready(ID.sweep, S) and not aura(BUFF, ID.sweep) and S.rage >= 30 then add(ID.sweep, { glow = true }, "AoE: Sweeping Strikes") end
    if ready(ID.tc, S) and S.rage >= 10 and rem(TDEBUFF, ID.dwounds) < 2 then add(ID.tc, nil, "AoE: Thunder Clap spreads Deep Wounds") end
    talent4(S, add, false)
    if ready(ID.cs, S) and S.cs < 1 then add(ID.cs, { glow = true }, "Colossus Smash") end
    if ready(ID.ms, S) then add(ID.ms, nil, "Mortal Strike") end
    if S.n >= 4 and known(ID.ww) and S.rage >= 30 then add(ID.ww, nil, "AoE 4+: Whirlwind") end
    if known(ID.op) and tfb > 0 and usable(ID.op) then add(ID.op, nil, "Overpower (Taste for Blood)") end
    if known(ID.slam) and S.rage >= 25 and aura(BUFF, ID.sweep) then add(ID.slam, nil, "Slam (cleaves with Sweeping Strikes)") end
  end
  if S.exec then
    if ready(ID.cs, S) and S.cs < 1 then add(ID.cs, { glow = true, tag = sd and "SD" or nil }, "Execute phase: Colossus Smash") end
    if ready(ID.ms, S) and S.rage < S.rageMax - 10 then add(ID.ms, nil, "Execute phase: Mortal Strike for rage") end
    if inCS and S.rage >= 30 then add(ID.exe, { glow = true }, "Execute in Colossus Smash") end
    if not inCS then talent4(S, add, true) end
    if ready(ID.sbolt, S) then add(ID.sbolt, nil, "Storm Bolt") end
    if known(ID.op) and tfb > 0 and usable(ID.op) then add(ID.op, { tag = aura(BUFF, ID.sexec) and "free" or nil }, "Overpower (Sudden Execute makes it free)") end
    if S.rage >= S.dump then add(ID.exe, nil, "Execute: rage near cap") end
    shout(S, add)
    if S.rage >= 30 then add(ID.exe, nil, "Execute") end
  else
    if ready(ID.cs, S) and S.cs < 1 then add(ID.cs, { glow = true, tag = sd and "SD" or nil }, sd and "Sudden Death: Colossus Smash reset" or "Colossus Smash") end
    if inCS then
      if ready(ID.ms, S) then add(ID.ms, nil, "CS window: Mortal Strike") end
      talent4(S, add, true)
      if ready(ID.sbolt, S) then add(ID.sbolt, nil, "CS window: Storm Bolt") end
      if known(ID.op) and tfb >= 2 and usable(ID.op) then add(ID.op, nil, "CS window: Overpower (2+ Taste for Blood)") end
      if known(ID.slam) and S.rage >= 25 then add(ID.slam, nil, "CS window: Slam") end
      if known(ID.op) and tfb > 0 and usable(ID.op) then add(ID.op, nil, "CS window: Overpower") end
      if ready(ID.hthrow, S) and S.cs > 1.5 then add(ID.hthrow, nil, "CS window: Heroic Throw filler") end
    else
      talent4(S, add, true)
      if ready(ID.ms, S) then add(ID.ms, nil, "Mortal Strike") end
      if known(ID.op) and tfb > 0 and usable(ID.op) then add(ID.op, nil, "Overpower (Taste for Blood)") end
      if ready(ID.sbolt, S) and S.csCd > 10 then add(ID.sbolt, nil, "Storm Bolt (CS far away)") end
      if known(ID.slam) and S.rage >= (tonumber(E.cfg.slamRage) or 80) then add(ID.slam, nil, "Slam outside CS only with high rage") end
      shout(S, add)
    end
  end
  if known(ID.ms) then add(ID.ms, { wait = true }, "waiting for Mortal Strike / rage") end
end

local function fury(S, out)
  local add = adder(out)
  local rbc = stacks(BUFF, ID.rbCharges)
  if rbc == 0 and aura(BUFF, ID.rbCharges) then rbc = 1 end
  local bs = aura(BUFF, ID.bsurge) ~= nil
  local mc = stacks(BUFF, ID.mcleaver)
  local inCS = S.cs > 0.5
  local smf = S.weap == "SMF"
  S.rbc, S.mc = rbc, mc
  local function RB(why) if known(ID.rb) and rbc > 0 and S.rage >= 10 then add(ID.rb, nil, why) end end
  local function BS(why) if known(ID.wild) and bs then add(ID.wild, { glow = true, tag = "BS" }, why) end end
  victory(S, add, 50)
  if S.n >= 4 then
    if ready(ID.bt, S) then add(ID.bt, nil, "AoE 4+: Bloodthirst") end
    talent4(S, add, false)
    if known(ID.ww) and S.rage >= 30 and mc < 3 then add(ID.ww, { tag = "MC" .. mc }, "AoE 4+: Whirlwind to 3 Meat Cleaver") end
    if mc >= 1 then RB("AoE: Raging Blow with Meat Cleaver") end
    if ready(ID.cs, S) and S.cs < 1 then add(ID.cs, nil, "Colossus Smash") end
    if known(ID.ww) and S.rage >= 30 then add(ID.ww, nil, "AoE: Whirlwind") end
  end
  if S.exec then
    if not inCS and ready(ID.droar, S) and S.hostile then add(ID.droar, nil, "Execute phase: Dragon Roar outside CS") end
    if ready(ID.cs, S) and S.cs < 1 then add(ID.cs, { glow = true }, "Execute phase: Colossus Smash") end
    if S.rage >= 30 and (inCS or S.rage >= S.dump) then add(ID.exe, { glow = inCS }, inCS and "Execute in Colossus Smash" or "Execute: rage near cap") end
    if ready(ID.bt, S) and S.rage < 30 then add(ID.bt, nil, "Execute phase: Bloodthirst for rage") end
    if inCS then talent4(S, add, true) end
    if ready(ID.sbolt, S) then add(ID.sbolt, nil, "Storm Bolt") end
    if rbc >= 2 then RB("Raging Blow at 2 charges") end
    BS("Wild Strike (Bloodsurge)")
    if S.rage >= 30 then add(ID.exe, nil, "Execute") end
    if ready(ID.bt, S) then add(ID.bt, nil, "Bloodthirst") end
    shout(S, add)
  elseif inCS then
    talent4(S, add, true)
    if ready(ID.sbolt, S) then add(ID.sbolt, nil, "CS window: Storm Bolt") end
    if rbc >= 2 then RB("CS window: Raging Blow at 2 charges") end
    if smf then BS("CS window: Wild Strike (Bloodsurge, SMF)") end
    if ready(ID.bt, S) then add(ID.bt, nil, "CS window: Bloodthirst") end
    RB("CS window: Raging Blow")
    BS("CS window: Wild Strike (Bloodsurge)")
    if known(ID.wild) and S.rage >= 30 then add(ID.wild, nil, "CS window: Wild Strike") end
    if S.n >= 2 and S.n < 4 and known(ID.ww) and S.rage >= 30 then add(ID.ww, nil, "2-3 targets: Whirlwind") end
  else
    if ready(ID.cs, S) and S.cs < 1 then add(ID.cs, { glow = true }, "Colossus Smash") end
    if ready(ID.bt, S) and (rbc < 2 or not S.enraged) then add(ID.bt, nil, "Bloodthirst (below 2 Raging Blow charges / no Enrage)") end
    if ready(ID.droar, S) and S.hostile then add(ID.droar, nil, "Dragon Roar on cooldown") end
    if S.n >= 2 and known(ID.ww) and S.rage >= 30 and mc < 1 then add(ID.ww, { tag = "MC" }, "2-3 targets: Whirlwind for Meat Cleaver") end
    if smf then BS("Wild Strike (Bloodsurge; SMF ranks it above Raging Blow)") end
    -- keep one Raging Blow charge for the next CS window when CS is close
    if rbc >= 2 or (rbc == 1 and S.csCd > 6) then RB(rbc >= 2 and "Raging Blow at 2 charges" or "Raging Blow (CS not close)") end
    BS("Wild Strike (Bloodsurge)")
    if ready(ID.bt, S) then add(ID.bt, nil, "Bloodthirst") end
    if ready(ID.sbolt, S) and S.csCd > 10 then add(ID.sbolt, nil, "Storm Bolt (CS far away)") end
    shout(S, add)
    if known(ID.wild) and S.rage >= (tonumber(E.cfg.wildRage) or 70) and S.csCd > 3 then add(ID.wild, nil, "Wild Strike filler (rage pooled above threshold)") end
  end
  if known(ID.bt) then add(ID.bt, { wait = true }, "waiting for Bloodthirst / rage") end
end

local function prot(S, out)
  local add = adder(out)
  local snb = aura(BUFF, ID.snb) ~= nil
  local wb = rem(TDEBUFF_ALL, ID.wblows)
  local wa = aura(TDEBUFF_ALL, ID.warmor)
  local dev = known(ID.dev) and ID.dev or ID.sunder
  if known(ID.def) and S.stance ~= ID.def and (S.tank or (tonumber(E.cfg.protMode) or 1) ~= 3) then
    add(ID.def, { glow = true }, "not in Defensive Stance") end
  victory(S, add, 60)
  if S.aoe then
    if ready(ID.tc, S) and S.rage >= 10 then add(ID.tc, nil, "AoE: Thunder Clap (Weakened Blows + Deep Wounds)") end
    if ready(ID.rev, S) then add(ID.rev, nil, "AoE: Revenge") end
    talent4(S, add, false)
  end
  if ready(ID.sslam, S) then add(ID.sslam, { glow = snb, tag = snb and "S&B" or nil }, snb and "Sword and Board: Shield Slam" or "Shield Slam") end
  if ready(ID.rev, S) then add(ID.rev, nil, "Revenge") end
  if S.tank and ready(ID.tc, S) and S.hostile and wb < 2 and S.rage >= 10 then add(ID.tc, { tag = "WB" }, "Weakened Blows missing on target") end
  if S.exec and S.rage >= 30 and (S.rage >= 90 or not S.tank) then add(ID.exe, nil, "Execute (rage to spare)") end
  if not S.aoe then talent4(S, add, false) end
  if ready(ID.sbolt, S) then add(ID.sbolt, nil, "Storm Bolt") end
  if known(dev) and (not wa or wa.stacks < 3 or wa.rem < 4) then add(dev, { tag = "WA" }, "Weakened Armor < 3 stacks / expiring") end
  shout(S, add)
  if known(dev) then add(dev, nil, "Devastate filler") end
  if known(ID.sslam) then add(ID.sslam, { wait = true }, "waiting for Shield Slam") end
end

-- off-GCD rage spender: Heroic Strike / Cleave
local function offGcd(S)
  local cfg = E.cfg
  if cfg.showOff == false or not S.hostile or S.leveling then return nil end
  local hs = (S.n >= 2 and known(ID.cleave)) and ID.cleave or ID.hs
  if not known(hs) then return nil end
  if cd(hs, S.now) > 0.25 then return nil end
  if S.prot and aura(BUFF, ID.ult) then return { id = hs, glow = true, tag = "ULT", why = "Ultimatum: free critical Heroic Strike / Cleave" } end
  if aura(BUFF, ID.incite) then return { id = hs, glow = true, tag = "free", why = "Incite: free Heroic Strike / Cleave" } end
  if S.rage < 30 then return nil end
  if S.prot then
    local sbUp = rem(BUFF, ID.sblockBuff) > 0 or rem(BUFF, ID.sbarrier) > 0
    local c = charges(ID.sblock)
    if not S.tank and S.rage >= 60 then return { id = hs, why = "Prot DPS: dump rage" } end
    if S.tank and S.rage >= S.dump and (sbUp or (c ~= nil and c == 0)) then return { id = hs, why = "rage near cap, mitigation covered" } end
    return nil
  end
  if S.exec then
    if S.rage >= S.rageMax - 5 then return { id = hs, why = "Execute phase: rage capped" } end
    return nil
  end
  if S.rage >= S.dump then return { id = hs, why = "rage near cap" } end
  if S.fury and S.cs > 0.5 and S.rage >= 60 then return { id = hs, why = "CS window: spare rage into Heroic Strike" } end
  return nil
end

-- Protection active mitigation: Shield Block (physical) / Shield Barrier (magic, or Block already up / no charges)
local function activeMitigation(S)
  if not (S.prot and S.tank and S.combat) then return nil end
  local am = tonumber(E.cfg.amMode) or 1
  local block, barrier = rem(BUFF, ID.sblockBuff), rem(BUFF, ID.sbarrier)
  local c = charges(ID.sblock)
  local canBlock = known(ID.sblock) and (c == nil and ready(ID.sblock, S) or (c and c >= 1)) and S.rage >= 60
  local canBarrier = known(ID.sbarrier) and ready(ID.sbarrier, S) and S.rage >= 20
  if am == 3 then
    if canBarrier and barrier < 0.5 and S.rage >= 60 then return { id = ID.sbarrier, glow = true, why = "Barrier-first: no Barrier up" } end
    if canBlock and block < 0.5 and c and c >= 2 then return { id = ID.sblock, why = "Shield Block at 2 charges" } end
    return nil
  end
  if canBlock and block < 0.5 then return { id = ID.sblock, glow = true, why = "Shield Block not up" } end
  if canBlock and c and c >= 2 and block < 1.5 then return { id = ID.sblock, glow = true, why = "Shield Block at 2 charges" } end
  if am == 1 and canBarrier and barrier < 0.5 and S.rage >= 90 and (block > 0 or (c ~= nil and c == 0)) then
    return { id = ID.sbarrier, why = "rage high and Block covered: Shield Barrier" } end
  return nil
end

local function sidePops(S, left, right)
  local cfg = E.cfg
  local function L(id, glow) if id and #left < 3 then left[#left + 1] = { id = id, glow = glow } end end
  local function R(id, glow) if id and #right < 3 then right[#right + 1] = { id = id, glow = glow } end end
  -- left: stance reminder, active mitigation, defensives
  if cfg.showDef ~= false then
    if not S.prot and S.stance ~= ID.battle and S.stance ~= ID.bers and known(ID.battle) then
      L((tonumber(cfg.dpsStance) or 1) == 2 and known(ID.bers) and ID.bers or ID.battle, S.combat) end
    local am = activeMitigation(S)
    if am then L(am.id, am.glow) end
    local tank = S.tank
    if S.combat then
      if ready(ID.swall, S) and S.hp < (tank and 40 or 30) then L(ID.swall, true) end
      if ready(ID.lstand, S) and S.hp < (tank and 30 or 25) then L(ID.lstand, true) end
      if ready(ID.dbts, S) and S.hp < 40 then L(ID.dbts, true) end
      if ready(ID.eregen, S) and S.hp < 50 then L(ID.eregen) end
      if ready(ID.rcry, S) and S.hp < 25 then L(ID.rcry) end
      if tank and ready(ID.demo, S) and S.hostile and (S.boss or S.n >= 3 or S.hp < 70) then L(ID.demo) end
    end
  end
  -- right: offensive cooldowns, lined up with Colossus Smash
  if cfg.showCDs ~= false and S.combat and S.hostile then
    local big = S.boss or S.aoe
    local csSoon = S.cs > 1 or S.csCd <= 3 or not known(ID.cs)
    -- priority: Recklessness > Avatar / Bloodbath > Skull Banner > Berserker Rage (only 3 slots)
    if big and not S.prot then
      if ready(ID.reck, S) and (csSoon or S.exec) then R(ID.reck, true) end
      if ready(ID.avatar, S) and (csSoon or S.exec) then R(ID.avatar, true) end
    elseif big and S.prot then
      if ready(ID.avatar, S) then R(ID.avatar) end
    end
    if ready(ID.bbath, S) then R(ID.bbath, true) end
    if big and not S.prot and ready(ID.skull, S) and (csSoon or S.exec) then R(ID.skull) end
    if S.fury and ready(ID.brage, S) and not S.enraged and S.cs < 0.5 then R(ID.brage, true) end
    if S.arms and ready(ID.brage, S) and not S.enraged and csSoon then R(ID.brage) end
  end
end


local function gcd(now)
  local info = C_Spell and C_Spell.GetSpellCooldown and C_Spell.GetSpellCooldown(61304)
  if type(info) ~= "table" then return 0, 0, 0 end
  local s, d = info.startTime or 0, info.duration or 0
  if s == 0 or d == 0 then return 0, 0, 0 end
  local rem = s + d - now
  if rem <= 0 then return 0, 0, 0 end
  return rem, s, d
end
E.gcd = gcd
local function entry(e, S, side)
  if not e then return nil end
  local r, s, d = cd(e.id, S.now)
  local gr, gs, gd = S.gcdRem or 0, S.gcdStart or 0, S.gcdDur or 0
  if side then gr = 0 end
  if gr > r then s, d = gs, gd end
  local noRes = false
  if C_Spell and C_Spell.IsSpellUsable then
    local u, noMana = C_Spell.IsSpellUsable(e.id)
    noRes = (not side) and noMana and true or false
  end
  local waiting = (e.wait or r > 0 or gr > 0 or noRes) and true or false
  local oor = outOfRange(e.id)
  return { id = e.id, icon = spellIcon(e.id), name = spellName(e.id), key = E:Key(e.id),
           glow = e.glow and true or false, waiting = waiting, wait = waiting,
           tag = e.tag, why = e.why,
           oor = oor, oorTint = (E.cfg.tintOOR ~= false) and oor or false,
           start = s, duration = d }
end

-- buff / debuff trackers: 4 small icons, contents depend on the spec
local function track(tbl, id, label, alertWhenMissing, minStacks, need)
  -- need = the spell that makes this tracker relevant; not learned yet (low level) -> tracker hidden
  if need and not known(need) then return nil end
  local a = aura(tbl, id)
  local st = a and a.stacks or 0
  local active = a ~= nil and (not minStacks or st >= minStacks)
  return { id = id, icon = spellIcon(id), name = spellName(id), active = a ~= nil, stacks = (a and st > 0) and tostring(st) or "",
           exp = a and a.exp or 0, dur = a and a.dur or 0, label = label or "",
           alert = (alertWhenMissing and not active) and true or false }
end
local function trackers(S)
  local t = {}
  if S.arms then
    t[1] = track(TDEBUFF, ID.cs, "CS", nil, nil, ID.cs)
    t[2] = track(BUFF, ID.tfb, "TfB", nil, nil, ID.op)
    t[3] = S.exec and track(BUFF, ID.sexec, "SE", nil, nil, ID.op) or track(BUFF, ID.sdeath, "SD", nil, nil, ID.sdeathTal)
    t[4] = track(BUFF, ID.enrage, "Enr", nil, nil, ID.brage)
  elseif S.fury then
    t[1] = track(TDEBUFF, ID.cs, "CS", nil, nil, ID.cs)
    t[2] = track(BUFF, ID.enrage, "Enr", S.combat and S.hostile, nil, ID.bt)
    t[3] = track(BUFF, ID.rbCharges, "RB", nil, nil, ID.rb)
    t[4] = (S.n >= 2 and known(ID.mcTal)) and track(BUFF, ID.mcleaver, "MC") or track(BUFF, ID.bsurge, "BS", nil, nil, ID.bsTal)
  elseif S.prot then
    local hostile = S.hostile and S.tank
    t[1] = track(TDEBUFF_ALL, ID.wblows, "WB", hostile, nil, ID.tc)
    t[2] = track(TDEBUFF_ALL, ID.warmor, "WA", hostile, 3, known(ID.dev) and ID.dev or ID.sunder)
    t[3] = track(BUFF, ID.ult, "Ult", nil, nil, ID.ultTal)
    t[4] = track(BUFF, ID.snb, "S&B", nil, nil, ID.snbTal)
  end
  return t
end

-- one evaluation per 0.1 s shared by every aura
function E:Tick()
  local now = GetTime()
  if now - self.last < 0.1 then return self.R, false end
  self.last = now
  if now - self.keysAt > 2 then self:RefreshKeys(now) end
  local S = self:Snapshot(now)
  local R = { S = S, show = (S.combat or S.hostile) and true or false }
  local list = {}
  if S.arms then arms(S, list) elseif S.fury then fury(S, list) elseif S.prot then prot(S, list) else leveling(S, list) end
  if not S.leveling and S.level < 20 then earlySpec(S, list) end
  if S.int then
    local c = S.int.cast
    local ie = entry({ id = S.int.id, glow = true }, S, true)
    ie.unit, ie.castName, ie.castIcon = S.int.unit, c.name, c.icon
    ie.castStart, ie.castDur, ie.castEnd = c.start, c.finish - c.start, c.finish
    R.int = ie
    if E.cfg.intMain then table.insert(list, 1, { id = S.int.id, glow = true, why = "interrupt " .. (c.name or "cast") }) end
  end
  R.next = entry(list[1], S)
  local specName = S.arms and "ARMS" or S.fury and ("FURY " .. (S.weap == "SMF" and "SMF" or "TG")) or S.prot and (S.tank and "PROT TANK" or "PROT DPS") or "LEVELING"
  local stanceName = STANCE_NAME[S.stance] or "no stance"
  local off = offGcd(S)
  if off and list[1] and list[1].id == off.id and not list[1].wait then off = nil end -- already the main suggestion
  R.off = off and entry(off, S, true) or nil
  R.why = {
    main = list[1] and ((spellName(list[1].id) or list[1].id) .. ": " .. (list[1].why or (S.int and E.cfg.intMain and "interrupt") or "?")) or "nothing",
    offGcd = off and ((spellName(off.id) or off.id) .. ": " .. off.why) or "none",
    mode = specName .. " stance=" .. stanceName .. " (" .. tostring(S.stanceSrc) .. ") rage=" .. S.rage .. "/" .. S.rageMax .. " target=" .. string.format("%.0f%%", S.thp),
  }
  for i = 2, math.min(#list, 6) do R.why[#R.why + 1] = (spellName(list[i].id) or list[i].id) .. ": " .. (list[i].why or "?") end
  for i = 2, #list do if list[i].id ~= list[1].id then R.next2 = entry(list[i], S) break end end
  local left, right = {}, {}
  sidePops(S, left, right)
  R.left, R.right = {}, {}
  for i, e in ipairs(left) do R.left[i] = entry(e, S, true) end
  for i, e in ipairs(right) do R.right[i] = entry(e, S, true) end
  local wrong = (S.prot and S.tank and S.stance ~= ID.def) or (not S.prot and S.stance == ID.def)
  R.mode = specName .. (S.aoe and (" AoE " .. S.n) or "") .. (S.exec and " EXEC" or "")
  R.rage = { v = S.rage, max = S.rageMax, dump = S.rage >= S.dump }
  local res
  if S.arms then res = string.format("%s  TfB %d", stanceName, stacks(BUFF, ID.tfb))
  elseif S.fury then res = string.format("%s  RB %d  MC %d", stanceName, S.rbc or 0, S.mc or 0)
  elseif S.prot then
    local c, mx
    if known(ID.sblock) then c, mx = charges(ID.sblock) end
    res = string.format("%s  Block %s", stanceName, c and (c .. "/" .. (mx or 2)) or "-")
  else
    res = string.format("%s  Lv %d", stanceName, S.level)
  end
  R.res = res and (wrong and ("! " .. res) or res) or nil
  R.trk = trackers(S)
  if not S.prot and known(ID.cs) then
    local a = aura(TDEBUFF, ID.cs)
    R.cs = { rem = a and a.rem or 0, exp = a and a.exp or 0, dur = a and a.dur or 6.5, cd = S.csCd }
  end
  if S.prot and known(ID.sblock) then
    local b = aura(BUFF, ID.sblockBuff)
    local c = charges(ID.sblock)
    R.sblock = { rem = b and b.rem or 0, exp = b and b.exp or 0, dur = b and b.dur or 6, charges = c or 0 }
  end
  if S.prot and known(ID.sbarrier) then
    local ba = aura(BUFF, ID.sbarrier)
    R.sbar = { rem = ba and ba.rem or 0, exp = ba and ba.exp or 0, dur = ba and ba.dur or 6, amount = ba and ba.points or nil }
  end
  self.R = R
  return R, true
end
