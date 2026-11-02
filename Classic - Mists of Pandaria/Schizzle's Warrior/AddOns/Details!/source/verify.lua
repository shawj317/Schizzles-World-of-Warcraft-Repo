-- Verifies the Schizzle's Warrior Details! profiles and the spec-switch snippet.
-- Usage (from this folder):  lua verify.lua     env: DETAILS_SRC, WA_TYPES (see common.lua)
local HERE = (arg and arg[0] or ""):match("^(.*[/\\])") or "./"
dofile(HERE .. "common.lua")
local R = dofile(HERE .. "defaults.lua")
local SRC, OUT = DETAILS_SRC, os.getenv("OUT_DIR") or (HERE .. "../")
local FONT = os.getenv("DETAILS_FONT") or "Fira Sans Condensed Medium"
local fails, checks = 0, 0
local function check(cond, msg) checks = checks + 1 if not cond then fails = fails + 1 print("FAIL: " .. msg) end end
check(R.skinsOk, "Details skins.lua loaded: " .. tostring(R.skinsErr))

-- media registered by Details (boot.lua) and by WeakAuras (Types.lua)
local media = {font = {}, statusbar = {}, background = {}, border = {}}
for kind, name, file in readfile(SRC .. "boot.lua"):gmatch('SharedMedia:Register%s*%(%s*"(%a+)",%s*"([^"]+)",%s*%[%[([^%]]+)%]%]') do
  if media[kind] then media[kind][name] = file end
end
for name, file in readfile(WA_TYPES):gmatch('LSM:Register%("font", "([^"]+)", "([^"]+)"') do
  media.font[name] = media.font[name] or file:gsub("\\\\", "\\")
end

local allowNested = {fixed = 1}
local function keyCheck(t, def, path, allowExtra)
  for k, v in pairs(t) do
    local d = def[k]
    if d == nil then
      if not (allowExtra and allowExtra[k]) then check(false, "unknown key " .. path .. "." .. tostring(k)) end
    else
      check(type(v) == type(d), ("type mismatch %s.%s (%s vs default %s)"):format(path, tostring(k), type(v), type(d)))
      if type(v) == "table" and type(d) == "table" and next(d) ~= nil and type(next(d)) == "string" then
        keyCheck(v, d, path .. "." .. tostring(k), allowNested)
      end
    end
  end
end
local instExtra = {posicao = 1, __pos = 1, __was_opened = 1, __locked = 1, __snap = 1, __snapH = 1, __snapV = 1,
  atributo = 1, sub_atributo = 1, sub_atributo_last = 1, segmento = 1, modo = 1, mostrando = 1, version = 1}
local defTexts = R.defaultTexts()
R.Details.table = R.Details.table or {}
table.wipe = table.wipe or function(t) for k in pairs(t) do t[k] = nil end end
local deploy = function(t1, t2)
  local function d(a, b) for k, v in pairs(b) do if type(v) == "table" then if a[k] == nil or type(a[k]) == "table" then a[k] = a[k] or {} d(a[k], v) end elseif a[k] == nil then a[k] = v end end return a end
  return d(t1, t2)
end
R.Details.table.deploy = deploy

local strings = {}
for _, spec in ipairs(SPECS) do
  local tag = spec.file .. ": "
  local raw = readfile(OUT .. spec.file)
  local pstr = raw:gsub("%s+$", "")
  strings[spec.key] = pstr
  ---------------------------------------------------------------- 1. round trip
  check(not pstr:find("[\r\n ]"), tag .. "no whitespace inside the string")
  local P = decode(pstr)
  check(equal(decode(encode(P)), P), tag .. "decode/encode round trip")
  check(type(P.profile) == "table" and type(P.playerData) == "table" and type(P.globaData) == "table" and P.version == 1, tag .. "export envelope shape")
  ---------------------------------------------------------------- 2. keys/types vs Details defaults
  local prof = P.profile
  local flat = {} for k, v in pairs(prof) do if k ~= "instances" then flat[k] = v end end
  keyCheck(flat, R.profile, tag .. "profile")
  keyCheck(P.globaData, R.global, tag .. "globaData")
  check(P.globaData.run_code == nil, tag .. "no run_code in the import")
  if spec.key == "prot" then
    check(P.globaData.parser_options and P.globaData.parser_options.tank_avoidance == true, tag .. "tank_avoidance on")
  else
    check(next(P.globaData) == nil, tag .. "DPS profiles change no account-wide settings")
  end
  check(#prof.instances == 2, tag .. "exactly 2 windows")
  for i, w in ipairs(prof.instances) do
    local base = {} for k, v in pairs(w) do if k ~= "row_info" then base[k] = v end end
    keyCheck(base, R.instance, tag .. "instances[" .. i .. "]", instExtra)
    local ri = {} for k, v in pairs(w.row_info) do if k ~= "texts" then ri[k] = v end end
    local riDef = deepcopy(R.instance.row_info) riDef.backdrop.texture = R.skins.Minimalistic.instance_cprops.row_info.backdrop.texture
    keyCheck(ri, riDef, tag .. "instances[" .. i .. "].row_info")
    for j = 1, 4 do keyCheck(w.row_info.texts[j], defTexts[j], ("%sinstances[%d].row_info.texts[%d]"):format(tag, i, j), {width = 1}) end
    ------------------------------------------------------------ 3. fonts, sizes, media
    check(w.row_info.font_face == FONT and w.attribute_text.text_face == FONT, tag .. "window font " .. FONT)
    check(w.row_info.font_size == 9, tag .. "bar text size 9")
    check(w.attribute_text.text_size == 11, tag .. "title size 11")
    check(media.font[w.row_info.font_face] ~= nil and media.font[w.row_info.font_face]:lower() == w.row_info.font_face_file:lower(), tag .. "font registered with matching file")
    check(media.statusbar[w.row_info.texture] == w.row_info.texture_file, tag .. "bar texture registered")
    check(w.row_info.height == 18 and w.row_info.textR_show_data[2] and w.row_info.textR_show_data[3], tag .. "bar height 18, DPS and percent shown")
    check(w.sub_atributo_last[w.atributo] == w.sub_atributo, tag .. "remembered sub-display matches")
  end
  check(prof.tooltip.fontface == FONT and prof.tooltip.fontsize == 11 and prof.font_faces.menus == FONT, tag .. "tooltip and menu font")
  ---------------------------------------------------------------- 4. displays
  local w1, w2 = prof.instances[1], prof.instances[2]
  check(w1.atributo == 1 and w1.sub_atributo == 1, tag .. "window 1 = Damage Done")
  check(w2.atributo == spec.w2[1] and w2.sub_atributo == spec.w2[2], tag .. "window 2 display")
  ---------------------------------------------------------------- 5. simulate ImportProfile + ApplyProfile
  local D = {}
  local data = decode(pstr)
  local newProfile = deepcopy(R.profile) newProfile.instances = {}
  for key in pairs(R.global) do local v = data.globaData[key] if v ~= nil then D[key] = deepcopy(v) end end
  for key in pairs(R.profile) do local v = data.profile[key] if v ~= nil then newProfile[key] = deepcopy(v) end end
  newProfile.instances = deepcopy(data.profile.instances)
  for key, value in pairs(R.profile) do
    if type(value) == "table" then
      if type(newProfile[key]) ~= "table" then newProfile[key] = deepcopy(value) else deploy(newProfile[key], value) end
    elseif newProfile[key] == nil then newProfile[key] = value end
  end
  for key in pairs(R.profile) do D[key] = newProfile[key] end
  check(D.tooltip.fontface == FONT and D.tooltip.line_height == R.profile.tooltip.line_height, tag .. "tooltip merged and backfilled")
  local windows = {}
  for index, skin in ipairs(newProfile.instances) do
    local inst = deepcopy(R.instance)
    inst.meu_id = index
    for k, v in pairs(skin) do inst[k] = deepcopy(v) end
    for key, value in pairs(R.instance) do
      if inst[key] == nil then inst[key] = deepcopy(value)
      elseif type(value) == "table" then for k2, v2 in pairs(value) do if inst[key][k2] == nil then inst[key][k2] = deepcopy(v2) end end end
    end
    R.RowTexts.Migrate(inst, inst.row_info)
    inst.ativa = skin.__was_opened and true or false
    inst.posicao = deepcopy(skin.__pos)
    inst.snap = deepcopy(skin.__snap)
    windows[index] = inst
  end
  check(windows[1].ativa and windows[2].ativa, tag .. "both windows open after import")
  check(windows[1].snap[3] == 2 and windows[2].snap[1] == 1, tag .. "windows snapped 1<->2")
  check(windows[2].atributo == spec.w2[1] and windows[2].sub_atributo == spec.w2[2], tag .. "window 2 display survives merge")
  local lw1, lw2 = windows[1].libwindow, windows[2].libwindow
  check(lw1.x == lw2.x - windows[2].posicao.normal.w and lw1.y == lw2.y, tag .. "windows touch edge to edge")
end
check(strings.arms == strings.fury, "Arms and Fury strings are identical (same layout; the name is typed at import)")

-------------------------------------------------------------------- 6. spec switch snippet
local code = readfile(OUT .. SWITCH_FILE)
check(loadstring(code, "switch") ~= nil, "snippet compiles")
local block = readfile(SRC .. "Libs/DF/fw.lua"):match("local forbiddenFunction = (%b{})")
local forbidden = {}
for name in block:gmatch('%["([%w_]+)"%]%s*=%s*true') do forbidden[name] = true end
check(forbidden.pcall and forbidden.loadstring and forbidden.setmetatable, "parsed Details' forbidden-name list")
for word in code:gsub("%-%-[^\n]*", ""):gmatch("[%a_][%w_]*") do if forbidden[word] then check(false, "snippet uses forbidden " .. word) end end
for _, spec in ipairs(SPECS) do check(code:find('%[' .. spec.specId .. '%] = "' .. spec.name:gsub("'", "'") .. '"') ~= nil, "snippet maps " .. spec.specId .. " -> " .. spec.name) end

-- mocked WoW + Details runtime
local function newWorld(opts)
  local W = {now = 100, timers = {}, applied = {}, prints = {}, combat = false, specIndex = opts.specIndex or 1,
             profiles = opts.profiles or {["Schizzle's Warrior Arms"] = {}, ["Schizzle's Warrior Fury"] = {}, ["Schizzle's Warrior Protection"] = {}},
             current = opts.current or "Schizzle's Warrior Arms", class = opts.class or "WARRIOR"}
  local frame = {events = {}}
  function frame:RegisterEvent(e) self.events[e] = true end
  function frame:SetScript(_, fn) self.handler = fn end
  W.frame = frame
  W.Details = {
    GetCurrentProfileName = function() return W.current end,
    GetProfile = function(_, name) return W.profiles[name] or false end,
    ApplyProfile = function(_, name) W.applied[#W.applied + 1] = name W.current = name end,
  }
  local G = {
    Details = W.Details, print = function(...) W.prints[#W.prints + 1] = table.concat({...}, " ") end,
    UnitClass = function() return "Warrior", W.class end,
    GetSpecialization = function() return W.specIndex end,
    GetSpecializationInfo = function(i) return ({71, 72, 73})[i] end,
    InCombatLockdown = function() return W.combat end,
    GetTime = function() return W.now end,
    C_Timer = {After = function(d, fn) W.timers[#W.timers + 1] = {at = W.now + d, fn = fn} end},
    CreateFrame = function() return frame end,
    C_EventUtils = {IsEventValid = function(e) return e ~= "PLAYER_SPECIALIZATION_CHANGED" or opts.specEvent ~= false end},
    pairs = pairs, ipairs = ipairs, type = type, tostring = tostring,
  }
  local env = setmetatable({}, {__index = function(env, k)
    if forbidden[k] then return nil end
    if k == "_G" then return env end
    local v = G[k]
    if v == nil and k ~= "C_SpecializationInfo" then error("snippet read unexpected global " .. tostring(k), 2) end
    return v
  end})
  function W.advance(sec)
    local target = W.now + sec
    while true do
      table.sort(W.timers, function(a, b) return a.at < b.at end)
      local t = W.timers[1]
      if not t or t.at > target then break end
      table.remove(W.timers, 1)
      W.now = t.at
      t.fn()
    end
    W.now = target
  end
  function W.fire(event, unit) if frame.handler and frame.events[event] then frame.handler(frame, event, unit) end end
  function W.run() local fn = assert(loadstring(code, "switch")) setfenv(fn, env) fn() end -- Details pcalls it; errors would surface here
  return W
end

-- login as Prot while the Arms profile is active -> switches to Prot
local W = newWorld{specIndex = 3}
W.run() W.advance(2)
check(W.applied[1] == "Schizzle's Warrior Protection" and #W.applied == 1, "login: Arms profile -> Protection")
check(W.frame.events.ACTIVE_TALENT_GROUP_CHANGED and W.frame.events.PLAYER_REGEN_ENABLED, "events registered")
-- second dispatch in the same session does nothing
W.run() W.advance(2) check(#W.applied == 1, "guard: running twice does not double up")
-- dual-spec swap to Arms (no PLAYER_SPECIALIZATION_CHANGED on this client)
W.advance(10) W.specIndex = 1 W.fire("ACTIVE_TALENT_GROUP_CHANGED") W.fire("PLAYER_TALENT_UPDATE") W.advance(3)
check(W.applied[2] == "Schizzle's Warrior Arms" and #W.applied == 2, "dual-spec swap -> Arms, event burst coalesced")
-- respec to Fury in combat -> waits for combat end
W.advance(10) W.specIndex = 2 W.combat = true W.fire("PLAYER_SPECIALIZATION_CHANGED", "player") W.advance(3)
check(#W.applied == 2, "no switch in combat")
W.combat = false W.fire("PLAYER_REGEN_ENABLED") W.advance(2)
check(W.applied[3] == "Schizzle's Warrior Fury", "switches after combat ends")
-- other units' spec changes are ignored
W.advance(10) W.specIndex = 3 W.fire("PLAYER_SPECIALIZATION_CHANGED", "party1") W.advance(3)
check(#W.applied == 3, "party member spec change ignored")
-- throttle: two quick swaps settle on the last spec
W.fire("ACTIVE_TALENT_GROUP_CHANGED") W.advance(2)
W.specIndex = 1 W.fire("ACTIVE_TALENT_GROUP_CHANGED") W.advance(1.6)
check(W.applied[#W.applied] == "Schizzle's Warrior Protection", "throttle: first swap applied")
W.advance(10)
check(W.applied[#W.applied] == "Schizzle's Warrior Arms" and W.current == "Schizzle's Warrior Arms", "throttle: ends on the latest spec")
-- user's own profile left alone
W = newWorld{specIndex = 3, current = "Jon Raid"} W.run() W.advance(5)
check(#W.applied == 0, "own profile untouched")
-- missing profile warns once
W = newWorld{specIndex = 2, profiles = {["Schizzle's Warrior Arms"] = {}}} W.run() W.advance(3)
W.fire("ACTIVE_TALENT_GROUP_CHANGED") W.advance(3)
check(#W.applied == 0 and #W.prints == 1 and W.prints[1]:find("not found"), "missing profile: one warning, no switch")
-- non-Warrior does nothing
W = newWorld{class = "MONK", current = "Schizzle's Warrior Arms", specIndex = 3} W.run() W.advance(5)
check(#W.applied == 0 and W.frame.handler == nil, "non-Warrior: no frame, no switch")
-- client without PLAYER_SPECIALIZATION_CHANGED
W = newWorld{specIndex = 2, specEvent = false} W.run() W.advance(3)
check(W.applied[1] == "Schizzle's Warrior Fury" and not W.frame.events.PLAYER_SPECIALIZATION_CHANGED, "invalid events skipped")

print(("%d checks, %d failures"):format(checks, fails))
os.exit(fails == 0 and 0 or 1)
