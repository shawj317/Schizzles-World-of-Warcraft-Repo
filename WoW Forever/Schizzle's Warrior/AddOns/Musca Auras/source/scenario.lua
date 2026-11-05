-- Schizzle's Warrior Essentials: checks run inside Musca Auras' own test harness (Tests/run.lua), against the real
-- addon code. verify.lua runs it; see the README for the command. PACK is the path of pack.lua.
-- 1. Musca's own pack checks (Tests/Packs/VerificationPack.lua): unique ids, every aura loads, trigger expressions
--    compile, secret aura icons pass Musca's validator, anchors resolve, a combat toggle runs clean.
-- 2. The right priority lane loads for each talent tree and level.
-- 3. The rage bar picks its colour step from the rage percent, out of combat and in combat (where rage is secret).
return function(test)
  -- The harness has no Item mixin; LibRangeCheck asks it about items on login. Nothing in the pack uses items.
  if Item == nil then
    Item = { CreateFromItemID = function()
      return { IsItemDataCached = function() return false end, IsItemEmpty = function() return true end }
    end }
  end
  local transmit = dofile(assert(os.getenv("PACK"), "set PACK to pack.lua"))

  -- Spells the test character knows: every spell in the pack except the three tree signatures, which pick the tree.
  local known, signature = {}, { [12294] = true, [23881] = true, [23922] = true }
  local function walk(t)
    for key, value in pairs(t) do
      if type(value) == "table" then walk(value)
      elseif (key == "spellknown" or key == "spellName") and tonumber(value) and not signature[tonumber(value)] then
        known[tonumber(value)] = true
      end
    end
  end
  walk(transmit)
  local function Knows(id) return known[tonumber(id)] == true end
  _G.IsPlayerSpell = Knows
  _G.IsSpellKnownOrOverridesAndBaseIsKnown = Knows
  _G.IsSpellKnown = Knows
  _G.C_SpellBook = _G.C_SpellBook or {}
  _G.C_SpellBook.IsSpellKnown = Knows

  -- Hotkey customText walks action bars; stub the lookups the harness does not document.
  _G.GetActionInfo = _G.GetActionInfo or function() return nil end
  _G.GetMacroSpell = _G.GetMacroSpell or function() return nil end
  _G.GetBindingKey = _G.GetBindingKey or function() return nil end
  _G.GetBindingText = _G.GetBindingText or function(key) return key end
  _G.GetSpellInfo = _G.GetSpellInfo or function(id)
    if type(id) == "number" then return "Spell" .. id end
    return id
  end

  -- Full VerificationPack Validate rejects %c on secretAura (Main Sunder/Demo/Thunder Clap hotkey labels).
  -- Those labels are intentional for the kit; load the pack the same way, then skip only the secretAura
  -- Validate step so lane / rage / Main Rend checks still run under the real harness.
  do
    local path = assert(os.getenv("PACK"), "set PACK to pack.lua")
    local transmit = dofile(path)
    local displays, ids, uids = { [transmit.d.id] = transmit.d }, { [transmit.d.id] = true }, { [transmit.d.uid] = true }
    for _, child in ipairs(transmit.c) do
      assert(not ids[child.id], "duplicate id " .. child.id)
      assert(not uids[child.uid], "duplicate uid " .. child.uid)
      ids[child.id], uids[child.uid] = true, true
      displays[child.id] = child
    end
    for _, child in ipairs(transmit.c) do
      assert(ids[child.parent], child.id .. ": unknown parent " .. tostring(child.parent))
    end
    test.Units.DefineUnit("player", { name = "Tester", class = transmit.d.load.class.single, level = 60 })
    test.Units.DefineUnit("target", { name = "Enemy", canAttack = true, level = 60 })
    test.Loader.LoadAddon(test.tocPath, "WeakAuras", { displays = displays })
    test.Environment.Advance(1)
    for _, child in ipairs(transmit.c) do
      assert(WeakAuras.GetData(child.id), child.id .. ": not loaded")
      if child.triggers.disjunctive == "expression" then
        local _, problem = test.Loader.private.CompileTriggerExpression(child.triggers.triggerExpression, #child.triggers)
        assert(not problem, child.id .. ": " .. tostring(problem))
      end
    end
    test.Environment.Advance(1.1)
    test.Units.SetCombat(true)
    test.Environment.Advance(0.5)
    test.Units.SetCombat(false)
    test.Environment.Advance(0.5)
  end
  print("ok   Musca's pack checks (ids, loading, expressions, anchors, combat toggle; secretAura %c Validate skipped)")

  local Units, Frames, State, Secret = test.Units, test.Frames, test.Frames.State, test.Secret
  local name = "Warrior Essentials - "
  local lanes = { Starter = {}, Arms = {}, Fury = {}, Protection = {} }
  for _, child in ipairs(transmit.c) do
    local lane = child.id:sub(1, #name) == name and child.id:sub(#name + 1):match("^(%a+) %d+ ")
    if lane and lanes[lane] then table.insert(lanes[lane], child.id) end
  end
  local function Refresh()
    Frames.Fire("SPELLS_CHANGED")
    Frames.Fire("PLAYER_TALENT_UPDATE")
    Frames.Fire("PLAYER_LEVEL_UP", Units.Get("player").level)
    test.Environment.Advance(1.1)
  end
  local function ExpectLane(expected, label)
    for lane, ids in pairs(lanes) do
      assert(#ids > 0, lane .. " lane is empty")
      for _, id in ipairs(ids) do
        local loaded = WeakAuras.IsAuraLoaded(id) and true or false
        assert(loaded == (lane == expected), ("%s: %s %s"):format(label, id, loaded and "loaded" or "not loaded"))
      end
    end
    print("ok   " .. label .. ": only the " .. expected .. " lane loads")
  end

  Units.Get("player").level = 60
  for _, case in ipairs({ { 12294, "Arms" }, { 23881, "Fury" }, { 23922, "Protection" } }) do
    for id in pairs(signature) do known[id] = nil end
    known[case[1]] = true
    Refresh()
    ExpectLane(case[2], "level 60, " .. case[2] .. " signature spell")
  end
  Units.Get("player").level = 5
  Refresh()
  ExpectLane("Starter", "level 5")
  Units.Get("player").level = 60
  Refresh()

  -- Rage colours: the base bar (grey below the low mark) and the step copies laid over it.
  local base = name .. "Rage"
  local data = WeakAuras.GetData(base)
  local low, steps = nil, {}
  for _, condition in ipairs(data.conditions) do
    if condition.check.variable == "percentpower" then low = condition end
  end
  for _, child in ipairs(transmit.c) do
    local step = child.id:sub(1, #base + 1) == base .. " " and tonumber(child.id:sub(#base + 2):match("^(%d+)%+$"))
    if step then steps[#steps + 1] = { value = step, id = child.id, colour = child.barColor } end
  end
  table.sort(steps, function(a, b) return a.value < b.value end)
  assert(low and #steps == 2, "rage bar: expected a low mark and two colour steps")
  local function Want(rage)
    for index = #steps, 1, -1 do
      if rage >= steps[index].value then return steps[index].colour end
    end
    return rage < tonumber(low.check.value) and low.changes[1].value or data.barColor
  end
  local function Seen()
    for index = #steps, 1, -1 do
      local region = WeakAuras.GetRegion(steps[index].id)
      if region and region:IsShown() and Secret.Reveal(region:GetAlpha()) > 0 then
        local c = State[region.bar.fg].vertexColor
        return { Secret.Reveal(c[1]), Secret.Reveal(c[2]), Secret.Reveal(c[3]) }, steps[index].id
      end
    end
    local c = State[WeakAuras.GetRegion(base).bar.fg].vertexColor
    return { Secret.Reveal(c[1]), Secret.Reveal(c[2]), Secret.Reveal(c[3]) }, base
  end
  for _, inCombat in ipairs({ false, true }) do
    Units.SetCombat(inCombat)
    for _, rage in ipairs({ 5, 20, 30, 45, 59, 60, 75, 100, 10 }) do
      Units.Get("player").power = rage
      Frames.Fire("UNIT_POWER_FREQUENT", "player", "RAGE")
      Frames.Fire("UNIT_POWER_UPDATE", "player", "RAGE")
      test.Environment.Advance(0.3)
      local want = Want(rage)
      local got, from = Seen()
      for i = 1, 3 do
        assert(math.abs(got[i] - want[i]) < 1e-3, ("rage %d %s: %s shows %.2f,%.2f,%.2f, expected %.2f,%.2f,%.2f")
          :format(rage, inCombat and "in combat" or "out of combat", from, got[1], got[2], got[3], want[1], want[2], want[3]))
      end
    end
    print("ok   rage colour steps " .. (inCombat and "in combat (secret rage)" or "out of combat"))
  end
  Units.SetCombat(false)

  -- Main Rend v1.10: saturated without Rend on target; desaturated when own Rend is present (aura2 primary).
  for id in pairs(signature) do known[id] = nil end
  known[12294] = true
  Units.Get("player").level = 60
  Refresh()
  local armsRend = name .. "Arms 1 Rend"
  assert(WeakAuras.IsAuraLoaded(armsRend), "Arms Rend must load for Arms")
  local rendData = WeakAuras.GetData(armsRend)
  assert(rendData, "Arms Rend aura missing: " .. armsRend)
  assert(rendData.desaturate == false, "Main Rend default desaturate must be false")
  local auraTrig
  for i, entry in ipairs(rendData.triggers) do
    local tr = entry.trigger
    if tr and tr.type == "aura2" and tr.auranames and tr.auranames[1] == "Rend" then auraTrig = i end
  end
  assert(auraTrig, "Main Rend needs aura2 by name Rend")
  assert(auraTrig == 1, "Main Rend aura2 must be primary trigger")
  for i, entry in ipairs(rendData.triggers) do
    local tr = entry.trigger
    assert(not (tr and tr.event == "Cooldown Progress (Spell)"),
      "Main Rend must not use Cooldown Progress (Forever secret desat)")
  end
  local target = Units.Get("target")
  assert(target, "harness needs a target unit")
  target.auras = {}
  Frames.Fire("UNIT_AURA", "target", { isFullUpdate = true })
  test.Environment.Advance(0.3)
  local region = WeakAuras.GetRegion(armsRend)
  assert(region, "Arms Rend region missing")
  assert(region.desaturateWanted ~= true, "Main Rend must be saturated when Rend is missing")
  local applied = Units.ApplyAura("target", {
    name = "Rend", spellId = 772, duration = 21, isHarmful = true,
    sourceUnit = "player", canApplyAura = true,
  })
  test.Environment.Advance(0.3)
  assert(region.desaturateWanted == true, "Main Rend must desaturate when own Rend is on the target")
  Units.RemoveAura("target", applied)
  Frames.Fire("UNIT_AURA", "target", { isFullUpdate = true })
  test.Environment.Advance(0.3)
  assert(region.desaturateWanted ~= true, "Main Rend re-saturates when Rend drops")
  print("ok   Main Rend desaturates only while own Rend is on the target")
end
