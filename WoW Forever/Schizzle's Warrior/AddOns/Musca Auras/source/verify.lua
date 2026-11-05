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

check(root.id:find(" v1%.2$") ~= nil, "pack version is v1.2 (" .. root.id .. ")")
-- Next-swing dump: Queued Action by name (all ranks), glow, and NEXT SWING label near the priority lane.
local queued = {}
for _, child in ipairs(transmit.c) do
  if child.parent and child.parent:find(" %- Next Swing$") and child.regionType == "icon" then
    queued[#queued + 1] = child
    local trigger = child.triggers[1] and child.triggers[1].trigger
    check(trigger and trigger.event == "Queued Action" and trigger.use_exact_spellName == false,
      child.id .. ": Queued Action by spell name (every rank)")
    -- The hidden test Musca builds is C_Spell.IsCurrentSpell(spellname); keep that contract.
    local hasGlow, hasLabel = false, false
    for _, sub in ipairs(child.subRegions or {}) do
      if sub.type == "subglow" and sub.glow then hasGlow = true end
      if sub.type == "subtext" and sub.text_text == "NEXT SWING" then hasLabel = true end
    end
    check(hasGlow and hasLabel, child.id .. ": pixel glow and NEXT SWING label")
  end
end
check(#queued == 2, "Next Swing holds Heroic Strike and Cleave (" .. #queued .. ")")
local nextGroup
for _, child in ipairs(transmit.c) do
  if child.id:find(" %- Next Swing$") then nextGroup = child end
end
check(nextGroup and nextGroup.yOffset == 8, "Next Swing sits at group-relative y=8 (near the priority lane at 0,-55)")
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
