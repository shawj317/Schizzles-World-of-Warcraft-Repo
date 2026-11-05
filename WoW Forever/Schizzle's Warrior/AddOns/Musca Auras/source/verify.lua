-- Offline checks for Schizzle's Warrior Essentials. Run from this folder with Lua 5.1:
--   MUSCA=/path/to/Musca-Auras lua verify.lua
-- Optional:
--   WOW_UI_SOURCE=<Blizzard UI source for Forever>  runs the pack inside Musca's own test harness (scenario.lua)
--   DB2=<folder of DB2 CSV exports>                 checks every spell ID against the game data (SpellName.csv,
--                                                   SpellEffect.csv from wago.tools/db2, build 1.60.1.70755)
--   LUACHECK=<luacheck command>                     lints the source files
--   PRIVATE_WORDS="a,b"                             words that must not appear anywhere in the folder
-- 1. The import string is current (build.lua --check).
-- 2. The pack loads and works in the harness: Musca's own pack checks, the lanes per tree and level, the rage colours.
-- 3. Every spell ID exists; aura IDs carry an aura; lane and proc icons are named after their spell.
-- 4. Everything sits inside the HUD box (AGENTS.md): 170 px either side of the screen centre, from 235 px below it
--    to 120 px above it. The group's centre is at 0,-55.
-- 5. Kit rules: font, group name with the version, no private words.
local MUSCA = assert(os.getenv("MUSCA"), "set MUSCA to a Musca Auras v1.14.0 folder")
local fails = 0
local function check(cond, what)
  if cond then print("ok   " .. what) else fails = fails + 1; print("FAIL " .. what) end
end
local function sh(s) return "'" .. s:gsub("'", "'\\''") .. "'" end
local lua = arg[-1] or "lua"
local here = io.popen("pwd"):read("*l")

-- 1. -------------------------------------------------------------------------------------------------------------
check(os.execute("MUSCA=" .. sh(MUSCA) .. " " .. sh(lua) .. " build.lua --check > /dev/null") == 0,
  "the import string is up to date")

local transmit = dofile("pack.lua")
local byId = {}
for _, child in ipairs(transmit.c) do byId[child.id] = child end
local root = transmit.d

-- 2. -------------------------------------------------------------------------------------------------------------
if os.getenv("WOW_UI_SOURCE") then
  local out = io.popen("cd " .. sh(MUSCA) .. " && PACK=" .. sh(here .. "/pack.lua") .. " TEMP=" ..
    sh(os.getenv("TMPDIR") or "/tmp") .. " " .. sh(lua) .. " Tests/run.lua --scenario " ..
    sh(here .. "/scenario.lua") .. " 2>&1")
  local text = out:read("*a")
  out:close()
  local ok = text:find("^OK ") ~= nil
  if not ok then print(text) end
  check(ok, "harness: Musca's pack checks, the lane for each tree and level, rage colours in and out of combat")
else
  print("skip harness run (set WOW_UI_SOURCE)")
end

-- 3. -------------------------------------------------------------------------------------------------------------
local spells, auras = {}, {}
local function walk(t, owner)
  for key, value in pairs(t) do
    if type(value) == "table" then
      walk(value, owner)
    elseif (key == "spellName" or key == "spellknown") and tonumber(value) then
      spells[tonumber(value)] = owner
    end
  end
  for _, id in ipairs(t.auraspellids or {}) do auras[tonumber(id)] = owner; spells[tonumber(id)] = owner end
end
for _, child in ipairs(transmit.c) do walk(child, child.id) end

local DB2 = os.getenv("DB2")
if DB2 then
  local names = {}
  for line in io.lines(DB2 .. "/SpellName.csv") do
    local id, name = line:match('^(%d+),"(.*)"$')
    if not id then id, name = line:match("^(%d+),(.*)$") end
    if id then names[tonumber(id)] = name end
  end
  local hasAura = {}
  for line in io.lines(DB2 .. "/SpellEffect.csv") do
    local fields = {}
    for field in (line .. ","):gmatch("([^,]*),") do fields[#fields + 1] = field end
    local aura, spell = tonumber(fields[2]), tonumber(fields[#fields])
    if aura and spell and aura ~= 0 then hasAura[spell] = true end
  end
  local missing, noAura = {}, {}
  for id, owner in pairs(spells) do
    if not names[id] then missing[#missing + 1] = id .. " (" .. owner .. ")" end
  end
  for id, owner in pairs(auras) do
    if not hasAura[id] then noAura[#noAura + 1] = id .. " (" .. owner .. ")" end
  end
  table.sort(missing); table.sort(noAura)
  check(#missing == 0, "every spell ID is in Forever's SpellName table" ..
    (#missing > 0 and (": missing " .. table.concat(missing, ", ")) or ""))
  check(#noAura == 0, "every aura ID applies an aura in SpellEffect" ..
    (#noAura > 0 and (": none on " .. table.concat(noAura, ", ")) or ""))
  -- Lane and proc icons carry the spell's own name.
  local wrong = {}
  for _, child in ipairs(transmit.c) do
    local parent = child.parent or ""
    local label = parent:find(" %- Main$") and child.id:match(" %d+ (.+)$")
      or parent:find(" %- Procs$") and child.id:match(" %- (.+)$")
    local trigger = child.triggers and child.triggers[1] and child.triggers[1].trigger
    local id = trigger and tonumber(trigger.spellName or trigger.realSpellName)
    if label and id and names[id] ~= label then wrong[#wrong + 1] = child.id .. " = " .. tostring(names[id]) end
  end
  check(#wrong == 0, "lane and proc icons are named after their spell" ..
    (#wrong > 0 and (": " .. table.concat(wrong, "; ")) or ""))
  local count = 0
  for _ in pairs(spells) do count = count + 1 end
  print("     " .. count .. " spell IDs checked")
else
  print("skip game data check (set DB2)")
end

-- 4. -------------------------------------------------------------------------------------------------------------
-- Rows measured from the group's centre. A dynamic row's worst case is every member shown at once; aura rows stop
-- at their limit.
local BOX = { left = -170, right = 170, bottom = -235, top = 120 }
check(root.xOffset == 0 and root.yOffset == -55 and root.anchorPoint == "CENTER" and root.selfPoint == "CENTER"
  and (root.anchorFrameType or "SCREEN") == "SCREEN", "the group is centred at 0,-55 on the screen")
local rows = {}
for _, child in ipairs(transmit.c) do
  if child.parent == root.id then rows[#rows + 1] = child end
end
local function members(group)
  local list = {}
  for _, id in ipairs(group.controlledChildren) do list[#list + 1] = byId[id] end
  return list
end
local function size(data)
  if data.regionType == "text" then return #data.displayText * data.fontSize * 0.5, data.fontSize end
  return data.width, data.height
end
-- The stances an icon shows in (nil: all of them).
local function forms(data)
  for _, t in ipairs(data.triggers) do
    local trigger = t.trigger
    if trigger and trigger.event == "Stance/Form/Aura" then
      if trigger.use_form then return { [trigger.form.single] = true } end
      return trigger.form.multi
    end
  end
end
-- How many icons of a grid can be on screen together: one stance at a time, one race's racial, and the lanes of
-- one level band (Starter alone; up to all three trees when their talent points tie).
local RACIALS = { [20600] = 1, [20594] = 1, [20580] = 1, [20589] = 1, [20572] = 1, [7744] = 1, [20577] = 1,
  [20549] = 1, [20554] = 1 }
local function together(list)
  local most = 0
  for stance = 1, 3 do
    for _, lanes in ipairs({ { Starter = true }, { Arms = true, Fury = true, Protection = true } }) do
      local count, racial = 0, false
      for _, data in ipairs(list) do
        local f = forms(data)
        local lane = data.id:match(" %- (%a+) %d+ ")
        if (not f or f[stance]) and (not lane or lanes[lane]) then
          if RACIALS[tonumber(data.load.spellknown)] then racial = true else count = count + 1 end
        end
      end
      most = math.max(most, count + (racial and 1 or 0))
    end
  end
  return most
end
-- Width and height of a row's worst case.
local function extent(group)
  local list, w, h = members(group), 0, 0
  if group.grow == "GRID" then
    local cw, ch = size(list[1])
    local shown = together(list)
    local columns, lines = math.min(group.gridWidth, shown), math.ceil(shown / group.gridWidth)
    return columns * cw + (columns - 1) * group.columnSpace, lines * ch + (lines - 1) * group.rowSpace
  end
  local shown = #list
  if group.blizzardFlowUseLimit then shown = math.min(shown, group.blizzardFlowLimit) end
  for index = 1, shown do
    local mw, mh = size(list[index])
    if group.grow == "DOWN" or group.grow == "UP" then
      w, h = math.max(w, mw), h + mh + (index > 1 and group.space or 0)
    elseif group.blizzardFlow or group.grow == "HORIZONTAL" then
      w, h = w + mw + (index > 1 and (group.blizzardFlowSpacing or group.space) or 0), math.max(h, mh)
    else
      w, h = math.max(w, mw), math.max(h, mh)
    end
  end
  return w, h
end
-- Rows hung under another row (SELECTFRAME) stack downwards from it; the rest sit at their offset.
local placed = {}
local function place(group)
  if placed[group.id] then return placed[group.id] end
  local w, h = extent(group)
  local top
  if group.anchorFrameType == "SELECTFRAME" then
    local target = byId[group.anchorFrameFrame:gsub("^WeakAuras:", "")]
    local holder = target.parent == root.id and target or byId[target.parent]
    local above = place(holder)
    if holder == target then
      top = above.bottom + group.yOffset
    else
      -- Laid over one aura inside a row: same place as that row.
      top = above.top
    end
  elseif group.selfPoint == "TOP" then
    top = group.yOffset
  elseif group.grow == "UP" then
    top = group.yOffset + h
  else
    top = group.yOffset + h / 2
  end
  placed[group.id] = { left = -w / 2, right = w / 2, top = top, bottom = top - h }
  return placed[group.id]
end
local outside = {}
for _, group in ipairs(rows) do
  local p = place(group)
  local screen = { left = p.left, right = p.right, top = p.top + root.yOffset, bottom = p.bottom + root.yOffset }
  print(("     %-34s x %4d..%-4d y %4d..%-4d"):format(group.id:gsub("^.- %- ", ""), screen.left, screen.right,
    screen.bottom, screen.top))
  if screen.left < BOX.left or screen.right > BOX.right or screen.bottom < BOX.bottom or screen.top > BOX.top then
    outside[#outside + 1] = group.id
  end
end
check(#outside == 0, "every row stays inside the HUD box" ..
  (#outside > 0 and (": " .. table.concat(outside, ", ")) or ""))

-- 5. -------------------------------------------------------------------------------------------------------------
check(root.id:find(" v%d+%.%d+$") ~= nil, "the group's name carries the version (" .. root.id .. ")")

check(root.id:find(" v1%.14$") ~= nil, "pack version is v1.14 (" .. root.id .. ")")

-- Find Minerals reminder: Tracking inverse (spell 2580), icon + Track Minerals text, OOC + alive.
do
  local track
  for _, child in ipairs(transmit.c) do
    if child.id:find("Track Minerals") or child.id:find("Find Minerals") then track = child break end
  end
  check(track ~= nil, "Track Minerals reminder exists")
  if track then
    local t1 = track.triggers[1] and track.triggers[1].trigger
    check(t1 and t1.event == "Tracking" and t1.use_inverse and t1.use_trackingSpell
      and type(t1.trackingSpell) == "table" and tonumber(t1.trackingSpell[1]) == 2580,
      "Track Minerals uses Tracking inverse spell 2580")
    check(track.regionType == "icon", "Track Minerals is an icon")
    check(track.load and track.load.use_combat == false, "Track Minerals loads out of combat")
    check(track.load and track.load.use_spellknown and track.load.spellknown == 2580,
      "Track Minerals requires Find Minerals known")
    local hasText, hasAlive
    for _, sub in ipairs(track.subRegions or {}) do
      if sub.type == "subtext" and sub.text_text == "Track Minerals" then hasText = true end
    end
    for _, entry in ipairs(track.triggers) do
      local tr = entry.trigger
      if tr and tr.event == "Conditions" and tr.use_alive == true then hasAlive = true end
    end
    check(hasText, "Track Minerals shows Track Minerals text")
    check(hasAlive, "Track Minerals requires alive (not dead/ghost)")
    check(track.parent and track.parent:find("Reminders"), "Track Minerals sits in Reminders")
  end
end

-- Every leaf aura unloads in Forever 1.60.1 classic capitals (zone name + uiMapID child-maps).
local CAPITAL_NAMES = {
  "Stormwind City", "Ironforge", "Darnassus", "Orgrimmar", "Thunder Bluff", "Undercity",
}
local CAPITAL_MAPS = { "1453", "1455", "1457", "1454", "1456", "1458" }
local badCapital = {}
for _, child in ipairs(transmit.c) do
  if child.regionType ~= "group" and child.regionType ~= "dynamicgroup" then
    local load = child.load or {}
    local reasons = {}
    if not load.use_zone or type(load.zone) ~= "string" then
      reasons[#reasons + 1] = "use_zone"
    else
      for _, name in ipairs(CAPITAL_NAMES) do
        if not load.zone:find("-" .. name, 1, true) then
          reasons[#reasons + 1] = "zone-missing-" .. name
        end
      end
    end
    if not load.use_zoneIds or type(load.zoneIds) ~= "string" then
      reasons[#reasons + 1] = "use_zoneIds"
    else
      for _, id in ipairs(CAPITAL_MAPS) do
        if not load.zoneIds:find("-c" .. id, 1, true) then
          reasons[#reasons + 1] = "map-missing-" .. id
        end
      end
    end
    if load.use_resting ~= nil then reasons[#reasons + 1] = "no-resting-load" end
    if #reasons > 0 then
      badCapital[#badCapital + 1] = child.id:gsub("^.- %- ", "") .. "[" .. table.concat(reasons, ",") .. "]"
    end
  end
end
check(#badCapital == 0, "every leaf aura hides in classic capitals (zone + zoneIds, not resting)"
  .. (#badCapital > 0 and (": " .. table.concat(badCapital, ", ")) or ""))


-- No Next Swing row; no standalone HS/Cleave in Procs (those grew above Battle Shout).
local nextGroup
for _, child in ipairs(transmit.c) do
  if child.id:find(" %- Next Swing$") then nextGroup = child end
end
check(nextGroup == nil, "Next Swing group is gone")
local procsQueued = {}
for _, child in ipairs(transmit.c) do
  if child.parent and child.parent:find(" %- Procs$") and child.regionType == "icon"
    and (child.id:find(" %- Heroic Strike$") or child.id:find(" %- Cleave$")) then
    procsQueued[#procsQueued + 1] = child.id
  end
end
check(#procsQueued == 0, "Procs has no standalone Heroic Strike / Cleave auras"
  .. (#procsQueued > 0 and (": " .. table.concat(procsQueued, ", ")) or ""))

local function pixelGlow(sub)
  return sub.type == "subglow" and sub.glowType == "Pixel"
    and sub.glowLines == 8 and sub.glowFrequency == 0.25 and sub.glowLength == 10
    and sub.glowThickness == 1 and sub.useGlowColor == false
end
local battleShout
for _, child in ipairs(transmit.c) do
  if child.id:find(" %- Battle Shout$") and child.parent and child.parent:find(" %- Effects$") then
    battleShout = child
  end
end
check(battleShout ~= nil, "Battle Shout buff icon is in Effects")
local shoutGlow
for _, sub in ipairs(battleShout.subRegions or {}) do
  if pixelGlow(sub) and sub.glow then shoutGlow = sub break end
end
check(shoutGlow ~= nil, "Battle Shout has Pixel moving-border glow")
local hasRemaining = false
for _, sub in ipairs(battleShout.subRegions or {}) do
  if sub.type == "subtext" and sub.text_text == "%p"
    and sub.text_text_format_p_format == "timed" then
    hasRemaining = true
  end
  check(not (sub.type == "subtext" and sub.text_text == "NEXT SWING"), "no NEXT SWING text anywhere")
end
check(hasRemaining, "Battle Shout shows remaining-time text (%p timed)")

-- Main HS / Cleave icons only: Queued Action for THAT spell + Swing Timer, Pixel glow + swirl
-- when IsCurrentSpell matches. Other Main icons must not inherit the queue border.
local mainIcons, badMain, badQueueLeak = {}, {}, {}
for _, child in ipairs(transmit.c) do
  if child.parent and child.parent:find(" %- Main$") and child.regionType == "icon" then
    mainIcons[#mainIcons + 1] = child
    local isHS = child.id:find(" Heroic Strike$") ~= nil
    local isCleave = child.id:find(" Cleave$") ~= nil
    local wantQueue = isHS or isCleave
    local n = #child.triggers
    local hasOwn, hasOther, hasSwing = false, false, false
    for i = 1, n do
      local tr = child.triggers[i] and child.triggers[i].trigger
      if tr and tr.event == "Queued Action" then
        if (isHS and tr.spellName == 78) or (isCleave and tr.spellName == 845) then
          hasOwn = i
        else
          hasOther = true
        end
      end
      if tr and tr.event == "Swing Timer" and (tr.hand == "main" or tr.hand == 0) then hasSwing = i end
    end
    if not wantQueue then
      if hasOwn or hasOther or hasSwing then
        badQueueLeak[#badQueueLeak + 1] = child.id:gsub("^.- %- ", "")
      end
    else
      local swirlIdx, glowIdx, hasShow
      for i, sub in ipairs(child.subRegions or {}) do
        if sub.type == "subcirculartexture" and sub.progressSource and sub.progressSource[1] == hasSwing
          and sub.progressSource[2] == "expirationTime" and sub.circularTextureVisible == false then
          swirlIdx = i
        end
      end
      for _, cond in ipairs(child.conditions or {}) do
        local c = cond.check
        if c and c.variable == "show" and c.value == 1 and c.trigger == hasOwn then
          local changes = {}
          for _, ch in ipairs(cond.changes or {}) do changes[ch.property] = ch.value end
          for prop, val in pairs(changes) do
            local gi = prop:match("^sub%.(%d+)%.glow$")
            if gi and val == true then
              local sub = child.subRegions[tonumber(gi)]
              if sub and pixelGlow(sub) and sub.glow == false then glowIdx = tonumber(gi) end
            end
          end
          if glowIdx and swirlIdx and changes["sub." .. glowIdx .. ".glow"] == true
            and changes["sub." .. swirlIdx .. ".circularTextureVisible"] == true then
            hasShow = true
          end
        end
      end
      local expr = child.triggers.triggerExpression or ""
      local exprOk = child.triggers.disjunctive == "expression" and type(expr) == "string" and #expr > 0
      if not (hasOwn and not hasOther and hasSwing and glowIdx and swirlIdx and hasShow and exprOk) then
        badMain[#badMain + 1] = child.id:gsub("^.- %- ", "")
      end
    end
  end
end
check(#mainIcons > 0, "Main holds priority icons (" .. #mainIcons .. ")")
check(#badMain == 0, "HS/Cleave Main icons have own-spell queued Pixel + swing swirl"
  .. (#badMain > 0 and (": " .. table.concat(badMain, ", ")) or ""))
check(#badQueueLeak == 0, "non-HS/Cleave Main icons have no queued Pixel / swing swirl"
  .. (#badQueueLeak > 0 and (": " .. table.concat(badQueueLeak, ", ")) or ""))

-- Main corner labels: dynamic keybind via %c + customText (GetActionInfo / GetBindingKey), not hard-coded priority index.
local badHotkey = {}
for _, child in ipairs(mainIcons) do
  local hasC
  for _, sub in ipairs(child.subRegions or {}) do
    if sub.type == "subtext" and sub.text_text == "%c" and sub.anchor_point == "INNER_TOPLEFT" then
      hasC = true
    end
    if sub.type == "subtext" and type(sub.text_text) == "string" and sub.text_text:match("^%d+$")
      and sub.anchor_point == "INNER_TOPLEFT" then
      badHotkey[#badHotkey + 1] = child.id:gsub("^.- %- ", "") .. " hard-coded " .. sub.text_text
    end
  end
  local ct = child.customText or ""
  local init = child.actions and child.actions.init and child.actions.init.custom or ""
  local bareGetSpellInfo = ct:find("[^%w_%.]GetSpellInfo%s*%(", 1) or ct:find("^GetSpellInfo%s*%(", 1)
  if not hasC or not ct:find("GetActionInfo", 1, true) or not ct:find("GetBindingKey", 1, true)
    or not ct:find("C_Spell", 1, true)
    or not ct:find("BT4Button", 1, true)
    or not ct:find("LeftButton", 1, true)
    or not ct:find("Keybind", 1, true)
    or bareGetSpellInfo
    or child.customTextUpdate ~= "update"
    or not (child.actions and child.actions.init and child.actions.init.do_custom)
    or not init:find("UPDATE_BINDINGS", 1, true)
    or not init:find("ACTIONBAR_SLOT_CHANGED", 1, true)
    or not init:find("f.cache", 1, true) then
    badHotkey[#badHotkey + 1] = child.id:gsub("^.- %- ", "") .. " missing dynamic hotkey lookup"
  end
end
-- actions.init.custom must be a BODY (Musca wraps return function() .. custom .. end).
local badInit = {}
for _, child in ipairs(mainIcons) do
  local custom = child.actions and child.actions.init and child.actions.init.custom
  if type(custom) == "string" and custom:match("^%s*function%s*%(") then
    badInit[#badInit + 1] = child.id:gsub("^.- %- ", "")
  end
end
check(#badInit == 0, "Main actions.init.custom is body-only (no leading function())"
  .. (#badInit > 0 and (": " .. table.concat(badInit, ", ")) or ""))

check(#badHotkey == 0, "every Main icon labels the real keybind (%c + GetActionInfo/GetBindingKey)"
  .. (#badHotkey > 0 and (": " .. table.concat(badHotkey, ", ")) or ""))

-- Harness: run one Main customText with mocked action bars / bindings (Blizzard + Bartender4).
do
  local sample
  for _, child in ipairs(mainIcons) do
    if child.customText and child.customText:find("GetActionInfo", 1, true) then
      sample = child
      break
    end
  end
  check(sample ~= nil, "hotkey harness has a Main customText sample")
  if sample then
    local want = tonumber(sample.customText:match("local want = (%d+)"))
    check(want ~= nil, "hotkey harness parsed want spell id")

    local function runLookup(actions, bindings, spells)
      local env = {
        _G = {},
        C_Spell = {
          GetSpellName = function(id)
            if type(id) == "number" then return spells[id] end
          end,
          GetSpellInfo = function(id)
            if type(id) == "number" and spells[id] then
              return { name = spells[id], spellID = id }
            end
            if type(id) == "string" then
              for sid, name in pairs(spells) do
                if name == id then return { name = name, spellID = sid } end
              end
            end
          end,
        },
        GetActionInfo = function(slot)
          local a = actions[slot]
          if not a then return nil end
          return a[1], a[2]
        end,
        GetMacroSpell = function() return nil end,
        GetBindingKey = function(cmd) return bindings[cmd] end,
        GetBindingText = function(key) return key end,
        issecretvalue = function() return false end,
      }
      env._G = env
      local frame = { cache = { dirty = true } }
      env.SchizzleWA_HotkeyFrame = frame
      env.SchizzleWA_Hotkeys = frame.cache
      env._G.SchizzleWA_HotkeyFrame = frame
      env._G.SchizzleWA_Hotkeys = frame.cache
      local fn, err = loadstring("return " .. sample.customText, "hotkey")
      assert(fn, err)
      setfenv(fn, env)
      local body = fn()
      setfenv(body, env)
      return body()
    end

    -- Blizzard-style: MULTIACTIONBAR3BUTTON1 = Q, spell on slot 25 (bar 3 button 1).
    local blizzard = runLookup(
      { [25] = { "spell", want } },
      { ["MULTIACTIONBAR3BUTTON1"] = "Q" },
      { [want] = "TestSpell", [want + 1] = "TestSpell" }
    )
    check(blizzard == "Q", "hotkey harness Blizzard MULTIACTIONBAR3 -> Q (got " .. tostring(blizzard) .. ")")

    -- Cross-rank: bar has want+1, label still resolves via spell name.
    local rank = runLookup(
      { [25] = { "spell", want + 1 } },
      { ["MULTIACTIONBAR3BUTTON1"] = "E" },
      { [want] = "TestSpell", [want + 1] = "TestSpell" }
    )
    check(rank == "E", "hotkey harness cross-rank by name -> E (got " .. tostring(rank) .. ")")

    -- Bartender4 bar 2: CLICK BT4Button13:Keybind = SHIFT-Q (no Blizzard bind).
    local bt4 = runLookup(
      { [13] = { "spell", want } },
      { ["CLICK BT4Button13:Keybind"] = "SHIFT-Q" },
      { [want] = "TestSpell" }
    )
    check(bt4 == "SHIFT-Q", "hotkey harness BT4 Keybind -> SHIFT-Q (got " .. tostring(bt4) .. ")")

    -- Older Bartender4 LeftButton fallback when Keybind is empty.
    local left = runLookup(
      { [13] = { "spell", want } },
      { ["CLICK BT4Button13:LeftButton"] = "SHIFT-E" },
      { [want] = "TestSpell" }
    )
    check(left == "SHIFT-E", "hotkey harness BT4 LeftButton -> SHIFT-E (got " .. tostring(left) .. ")")

    -- Bar 1 Blizzard ACTIONBUTTON still works alongside BT4 candidates.
    local bar1 = runLookup(
      { [1] = { "spell", want } },
      { ["ACTIONBUTTON1"] = "1" },
      { [want] = "TestSpell" }
    )
    check(bar1 == "1", "hotkey harness ACTIONBUTTON1 -> 1 (got " .. tostring(bar1) .. ")")
  end
end

-- Main DoT (Rend) v1.10: no remaining-time flash / Proc blink / rage desat extras.
local badFlash = {}
for _, child in ipairs(mainIcons) do
  if child.id:find(" Rend$") then
    for _, sub in ipairs(child.subRegions or {}) do
      if sub.type == "subglow" and sub.glowType == "Proc" then
        badFlash[#badFlash + 1] = child.id:gsub("^.- %- ", "") .. " still-has-Proc-blink"
      end
    end
    for _, cond in ipairs(child.conditions or {}) do
      local c = cond.check
      if c and (c.variable == "faAuraRemaining" or c.variable == "insufficientResources"
        or c.variable == "spellUsable") then
        -- insufficientResources / spellUsable may still colour the icon via noMana/outOfRange/usableDim;
        -- those change color/alpha, not desaturate. Flag only desaturate from those variables.
        for _, ch in ipairs(cond.changes or {}) do
          if ch.property == "desaturate" or ch.property == "conditionAnimation"
            or (type(ch.property) == "string" and ch.property:match("^sub%.%d+%.glow$")
              and c.variable == "faAuraRemaining") then
            badFlash[#badFlash + 1] = child.id:gsub("^.- %- ", "") .. " leftover-" .. tostring(c.variable)
          end
        end
      end
    end
  end
end
check(#badFlash == 0, "Main Rend has no <4s flash / rage-desat leftovers"
  .. (#badFlash > 0 and (": " .. table.concat(badFlash, ", ")) or ""))

-- Target row no longer carries a Rend tracker (timer moved to Main).
local targetRend = {}
for _, child in ipairs(transmit.c) do
  if child.parent and child.parent:find(" %- Target$") and child.id:find("Rend") then
    targetRend[#targetRend + 1] = child.id
  end
end
check(#targetRend == 0, "Target row has no Rend (target) duplicate"
  .. (#targetRend > 0 and (": " .. table.concat(targetRend, ", ")) or ""))

-- Main Rend v1.12: Cooldown Progress primary (always visible) + Spell Cast Succeeded companion
-- (Forever tutorial §5 self-timer). Desaturate only while trigger 2 is showing. No aura2 target
-- scan (secret in combat). No onCooldown→desaturate on the CD primary. No remaining timer / Proc flash.
local badDot = {}
for _, child in ipairs(mainIcons) do
  if child.id:find(" Rend$") then
    local reasons = {}
    if child.desaturate ~= false then reasons[#reasons + 1] = "desaturate-default-false" end
    for _, sub in ipairs(child.subRegions or {}) do
      if sub.type == "subtext" and sub.text_text == "%p"
        and sub.text_text_format_p_format == "timed" then
        reasons[#reasons + 1] = "remaining-timer-removed"
      end
      if sub.type == "subglow" and sub.glowType == "ACShine" then
        reasons[#reasons + 1] = "ACShine-removed"
      end
      if sub.type == "subglow" and sub.glowType == "buttonOverlay" then
        reasons[#reasons + 1] = "buttonOverlay-removed"
      end
    end

    local cdIdx, castIdx, aura2Target, rendQ, otherDesat
    for i, entry in ipairs(child.triggers) do
      local tr = entry.trigger
      if tr and tr.event == "Cooldown Progress (Spell)" then cdIdx = i end
      if tr and tr.event == "Spell Cast Succeeded" and tr.use_spellId
        and tr.use_hideOnTargetDeath and tr.use_hideOnTargetChange then
        castIdx = i
      end
      if tr and tr.type == "aura2" and tr.unit == "target" then aura2Target = i end
      if tr and tr.event == "Queued Action" and tr.spellName == 772 then rendQ = i end
    end
    if cdIdx ~= 1 then reasons[#reasons + 1] = "cd-primary" end
    if castIdx ~= 2 then reasons[#reasons + 1] = "cast-succeeded-companion" end
    if aura2Target then reasons[#reasons + 1] = "no-aura2-target" end
    if rendQ then reasons[#reasons + 1] = "rend-queued-trigger-removed" end
    local expr = child.triggers.triggerExpression or ""
    -- Visibility must include trigger 1 and must NOT require companion trigger 2.
    if not expr:find("1", 1, true) or expr:find("2", 1, true) then
      reasons[#reasons + 1] = "visibility-excludes-companion"
    end

    local hasCastDesat, greyWhileUp, rageDesat, onCdDesat
    for _, cond in ipairs(child.conditions or {}) do
      local c = cond.check
      if c and c.variable == "show" and c.value == 1 and c.trigger == 2 then
        for _, ch in ipairs(cond.changes or {}) do
          if ch.property == "desaturate" and ch.value == true then hasCastDesat = true end
        end
      end
      if c and c.variable == "faAuraMissing" then
        for _, ch in ipairs(cond.changes or {}) do
          if ch.property == "desaturate" then greyWhileUp = true end
        end
      end
      if c and c.variable == "insufficientResources" then
        for _, ch in ipairs(cond.changes or {}) do
          if ch.property == "desaturate" then rageDesat = true end
        end
      end
      if c and c.variable == "onCooldown" then
        for _, ch in ipairs(cond.changes or {}) do
          if ch.property == "desaturate" then onCdDesat = true end
        end
      end
      if c and c.variable == "show" and c.value == 1 and c.trigger == rendQ then
        reasons[#reasons + 1] = "rend-queue-border-removed"
      end
      for _, ch in ipairs(cond.changes or {}) do
        if ch.property == "desaturate" then
          local ok = c and c.variable == "show" and c.value == 1 and c.trigger == 2 and ch.value == true
          if not ok then otherDesat = tostring(c and c.variable) end
        end
      end
    end
    if not hasCastDesat then reasons[#reasons + 1] = "cast-show-desaturate" end
    if greyWhileUp then reasons[#reasons + 1] = "old-grey-while-up" end
    if rageDesat then reasons[#reasons + 1] = "rage-desaturate-removed" end
    if onCdDesat then reasons[#reasons + 1] = "onCooldown-desaturate-removed" end
    if otherDesat then reasons[#reasons + 1] = "extra-desaturate:" .. otherDesat end
    local t1 = child.triggers[1] and child.triggers[1].trigger
    if t1 and t1.use_desaturateOnCooldown then reasons[#reasons + 1] = "desaturateOnCooldown-off" end
    if #reasons > 0 then
      badDot[#badDot + 1] = child.id:gsub("^.- %- ", "") .. " [" .. table.concat(reasons, ",") .. "]"
    end
  end
end
check(#badDot == 0, "Main Rend: CD primary + Spell Cast Succeeded companion, only show→desaturate"
  .. (#badDot > 0 and (": " .. table.concat(badDot, ", ")) or ""))

-- Sibling content rows must not overlap (the old Next Swing row sat on Rage / Main).
-- Rage colour steps intentionally stack on the Resource bar; Reminders (OOC) and Range (combat) share the top band by design.
local function ignoreOverlap(a, b)
  local an, bn = a.id, b.id
  if an:find("Rage step") or bn:find("Rage step") then return true end
  if (an:find(" %- Reminders$") and bn:find(" %- Range$"))
    or (an:find(" %- Range$") and bn:find(" %- Reminders$")) then
    return true
  end
  return false
end
local overlaps = {}
for i = 1, #rows do
  local a = place(rows[i])
  for j = i + 1, #rows do
    if not ignoreOverlap(rows[i], rows[j]) then
      local b = place(rows[j])
      local xOverlap = a.left < b.right and a.right > b.left
      local yOverlap = a.bottom < b.top and a.top > b.bottom
      if xOverlap and yOverlap then
        overlaps[#overlaps + 1] = rows[i].id:gsub("^.- %- ", "") .. " x " .. rows[j].id:gsub("^.- %- ", "")
      end
    end
  end
end
check(#overlaps == 0, "no overlapping row boxes" ..
  (#overlaps > 0 and (": " .. table.concat(overlaps, ", ")) or ""))

local rageBar
for _, child in ipairs(transmit.c) do
  if child.regionType == "aurabar" and child.id:find(" %- Rage$") then rageBar = child end
end
check(rageBar and rageBar.width == 100 and rageBar.height == 14, "Rage bar is 100x14 (was 334 wide)")


local badFont = {}
for _, child in ipairs(transmit.c) do
  local function scan(t)
    for key, value in pairs(t) do
      if type(value) == "table" then scan(value)
      elseif (key == "font" or key == "text_font") and value ~= "Fira Sans Condensed Medium" then
        badFont[#badFont + 1] = child.id
      end
    end
  end
  scan(child)
end
check(#badFont == 0, "every text uses Fira Sans Condensed Medium" ..
  (#badFont > 0 and (": " .. table.concat(badFont, ", ")) or ""))

local words = os.getenv("PRIVATE_WORDS")
if words and words ~= "" then
  local found = {}
  local files = io.popen("find .. -type f")
  for file in files:lines() do
    local f = io.open(file, "rb")
    local body = f:read("*a"):lower()
    f:close()
    for word in words:gmatch("[^,]+") do
      if body:find(word:lower(), 1, true) then found[#found + 1] = file end
    end
  end
  files:close()
  check(#found == 0, "no private words in the folder" .. (#found > 0 and (": " .. table.concat(found, ", ")) or ""))
else
  print("skip private word check (set PRIVATE_WORDS)")
end

local luacheck = os.getenv("LUACHECK")
if luacheck then
  check(os.execute(luacheck .. " --no-color -q --std lua51 --globals strmatch Item IsPlayerSpell " ..
    "IsSpellKnownOrOverridesAndBaseIsKnown IsSpellKnown C_SpellBook WeakAuras LibStub --max-line-length 140 " ..
    "PackBuilder.lua pack.lua build.lua scenario.lua verify.lua") == 0, "luacheck is clean")
else
  print("skip luacheck (set LUACHECK)")
end

print(fails == 0 and "ALL CHECKS PASSED" or (fails .. " CHECK(S) FAILED"))
os.exit(fails == 0 and 0 or 1)
