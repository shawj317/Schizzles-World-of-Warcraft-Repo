-- Builds "../Schizzle's Warrior Essentials.txt", the Musca Auras import string, from pack.lua.
-- Run from this folder with Lua 5.1 (the same as the game):
--   MUSCA=/path/to/Musca-Auras lua build.lua          writes the file
--   MUSCA=/path/to/Musca-Auras lua build.lua --check  only compares it
-- MUSCA is a copy of the Musca Auras v1.14.0 source (the GitHub tag, or the release zip unpacked): the string is
-- made with the same LibSerialize and LibDeflate the addon reads it with, the way Musca's own AuraTool.lua does.
local musca = assert(os.getenv("MUSCA"), "set MUSCA to a Musca Auras v1.14.0 folder")
-- LibStub uses the game's strmatch.
strmatch = string.match
dofile(musca .. "/WeakAuras/Libs/LibStub/LibStub.lua")
dofile(musca .. "/WeakAuras/Libs/LibDeflate/LibDeflate.lua")
dofile(musca .. "/WeakAuras/Libs/LibSerialize/LibSerialize.lua")
local LibDeflate = LibStub("LibDeflate")
local LibSerialize = LibStub("LibSerialize")

local transmit = dofile("pack.lua")

-- Hard gate: compile every custom-code string the way Musca 1.14.0 LoadFunction wraps it.
-- Catches "return function() function()" (body fields that already contain function()) before import.
local function compile(src, label)
  local fn, err = loadstring(src, label)
  if not fn then
    return false, err
  end
  return true
end

local checked, failures = 0, {}

local function check(src, label)
  checked = checked + 1
  local ok, err = compile(src, label)
  if not ok then
    failures[#failures + 1] = label .. ": " .. tostring(err)
  end
end

-- action bodies: WeakAuras.lua LoadCustomActionFunctions
local function checkActionBody(code, label)
  if type(code) ~= "string" or code == "" then return end
  check("return function() " .. code .. "\n end", label)
end

-- expression / full function: "return " .. code (customText, trigger.custom, message_custom, …)
local function checkExpr(code, label)
  if type(code) ~= "string" or code == "" then return end
  check("return " .. code, label)
end

local function walkAura(data, id)
  id = id or (data and data.id) or "?"
  if type(data) ~= "table" then return end

  checkExpr(data.customText, id .. " customText")
  checkExpr(data.customAnchor, id .. " customAnchor")

  local actions = data.actions
  if type(actions) == "table" then
    for _, phase in ipairs({ "init", "start", "finish" }) do
      local a = actions[phase]
      if type(a) == "table" then
        if a.do_custom then checkActionBody(a.custom, id .. " actions." .. phase .. ".custom") end
        if phase == "init" then
          if a.do_custom_load then checkActionBody(a.customOnLoad, id .. " actions.init.customOnLoad") end
          if a.do_custom_unload then checkActionBody(a.customOnUnload, id .. " actions.init.customOnUnload") end
        end
        if a.do_message then checkExpr(a.message_custom, id .. " actions." .. phase .. ".message_custom") end
      end
    end
  end

  local triggers = data.triggers
  if type(triggers) == "table" then
    checkExpr(triggers.customTriggerLogic, id .. " triggers.customTriggerLogic")
    for i, entry in ipairs(triggers) do
      local tr = entry and entry.trigger
      local un = entry and entry.untrigger
      if type(tr) == "table" then
        checkExpr(tr.custom, id .. " trigger[" .. i .. "].custom")
        checkExpr(tr.customDuration, id .. " trigger[" .. i .. "].customDuration")
        checkExpr(tr.customName, id .. " trigger[" .. i .. "].customName")
        checkExpr(tr.customIcon, id .. " trigger[" .. i .. "].customIcon")
        checkExpr(tr.customTexture, id .. " trigger[" .. i .. "].customTexture")
        checkExpr(tr.customStacks, id .. " trigger[" .. i .. "].customStacks")
        if type(tr.customVariables) == "string" and tr.customVariables ~= "" then
          check("return function() return \n" .. tr.customVariables .. "\n end",
            id .. " trigger[" .. i .. "].customVariables")
        end
        for o = 1, 7 do
          local prop = "customOverlay" .. o
          checkExpr(tr[prop], id .. " trigger[" .. i .. "]." .. prop)
        end
      end
      if type(un) == "table" then
        checkExpr(un.custom, id .. " untrigger[" .. i .. "].custom")
      end
    end
  end

  -- conditions: customcheck values are LoadFunction("return " .. value)
  for ci, cond in ipairs(data.conditions or {}) do
    local function walkCheck(checkNode, path)
      if type(checkNode) ~= "table" then return end
      if checkNode.variable == "customcheck" then
        checkExpr(checkNode.value, id .. " " .. path .. " customcheck")
      end
      for _, nested in ipairs(checkNode.checks or {}) do
        walkCheck(nested, path .. ".checks")
      end
    end
    walkCheck(cond.check, "conditions[" .. ci .. "]")
  end

  -- animation custom funcs
  local anim = data.animation
  if type(anim) == "table" then
    for _, phase in ipairs({ "start", "main", "finish" }) do
      local a = anim[phase]
      if type(a) == "table" then
        for _, key in ipairs({ "translateFunc", "alphaFunc", "scaleFunc", "rotateFunc", "colorFunc" }) do
          checkExpr(a[key], id .. " animation." .. phase .. "." .. key)
        end
      end
    end
  end
end

walkAura(transmit.d, transmit.d and transmit.d.id)
for _, child in ipairs(transmit.c or {}) do
  walkAura(child, child.id)
end

if #failures > 0 then
  print(("FAIL custom-code compile gate: %d checked, %d failed"):format(checked, #failures))
  for _, line in ipairs(failures) do print("  " .. line) end
  os.exit(1)
end
print(("ok   custom-code compile gate: %d strings checked (Musca LoadFunction wraps)"):format(checked))

-- Musca 1.14.0 Forever compatibility scanner (Update.lua removedFunctions + triggerWarning keys).
-- (a) removedFunctions in custom code must be zero. (b) report remaining trigger secret warnings.
local removedFunctions = {
  "UnitAura", "UnitBuff", "UnitDebuff", "GetSpellInfo", "GetSpellCooldown", "GetSpellCharges",
  "GetSpellTexture", "IsUsableSpell", "IsSpellOverlayed", "CombatLogGetCurrentEventInfo", "GetTalentInfo",
  "GetNumTalentTabs", "GetSpecialization", "GetItemCooldown", "GetContainerItemInfo",
}
local function callsFunction(code, name)
  return ("\n" .. code):find("[^%w_%.:]" .. name .. "%s*%(") ~= nil
end
local function collectCodes(data, id, codes)
  id = id or (data and data.id) or "?"
  if type(data) ~= "table" then return end
  local function add(label, code)
    if type(code) == "string" and code:find("%S") then
      codes[#codes + 1] = { text = id .. " " .. label, code = code }
    end
  end
  add("customText", data.customText)
  add("customAnchor", data.customAnchor)
  local actions = data.actions
  if type(actions) == "table" then
    for _, phase in ipairs({ "init", "start", "finish" }) do
      local a = actions[phase]
      if type(a) == "table" then
        if a.do_custom then add("actions." .. phase .. ".custom", a.custom) end
        if phase == "init" then
          if a.do_custom_load then add("actions.init.customOnLoad", a.customOnLoad) end
          if a.do_custom_unload then add("actions.init.customOnUnload", a.customOnUnload) end
        end
        if a.do_message then add("actions." .. phase .. ".message_custom", a.message_custom) end
      end
    end
  end
  local triggers = data.triggers
  if type(triggers) == "table" then
    add("customTriggerLogic", triggers.customTriggerLogic)
    for i, entry in ipairs(triggers) do
      local tr = entry and entry.trigger
      if type(tr) == "table" then
        add("trigger[" .. i .. "].custom", tr.custom)
        add("trigger[" .. i .. "].customDuration", tr.customDuration)
      end
    end
  end
end

local codes = {}
collectCodes(transmit.d, transmit.d and transmit.d.id, codes)
for _, child in ipairs(transmit.c or {}) do collectCodes(child, child.id, codes) end

local removedHits = {}
for _, code in ipairs(codes) do
  for _, name in ipairs(removedFunctions) do
    if callsFunction(code.code, name) then
      removedHits[#removedHits + 1] = code.text .. " calls " .. name
    end
  end
end
if #removedHits > 0 then
  print(("FAIL Forever removedFunctions gate: %d hit(s)"):format(#removedHits))
  for _, line in ipairs(removedHits) do print("  " .. line) end
  os.exit(1)
end
print(("ok   Forever removedFunctions gate: 0 hits across %d custom strings"):format(#codes))

-- Offline trigger-warning triage (mirrors Update.lua triggerWarning + TriggerSecretWarnings keys).
-- Without live C_Secrets we can still flag structural cases Musca always warns about:
-- Health triggers (always), Power triggers (always candidate), Combat Log, aura2 secret-aura spell lists.
local secretWarn = {}
local function warnLine(id, msg) secretWarn[#secretWarn + 1] = id .. ": " .. msg end
for _, aura in ipairs(transmit.c or {}) do
  for _, triggerData in ipairs(aura.triggers or {}) do
    local trigger = triggerData.trigger
    if type(trigger) == "table" then
      if trigger.event == "Combat Log" or (trigger.type == "custom" and type(trigger.events) == "string"
          and trigger.events:find("COMBAT_LOG_EVENT", 1, true)) then
        warnLine(aura.id, "uses combat log (blocked on Forever)")
      end
      if trigger.event == "Health" then
        warnLine(aura.id, "Health value checks (Musca always warns for Health triggers)")
      end
      if trigger.event == "Power" or trigger.event == "Alternate Power" then
        warnLine(aura.id, "Power value checks (rage/power secrecy on Forever; %p draw still works)")
      end
      if trigger.type == "aura2" and trigger.unit == "target" then
        warnLine(aura.id, "aura2 on target (debuffs secret in combat; prefer Spell Cast Succeeded)")
      end
    end
  end
end
print(("ok   Forever trigger-warning triage: %d remaining structural note(s)"):format(#secretWarn))
for _, line in ipairs(secretWarn) do print("  note  " .. line) end

local serialized = LibSerialize:SerializeEx({ errorOnUnserializableType = false }, transmit)
local text = "!WA:2!" .. LibDeflate:EncodeForPrint(LibDeflate:CompressDeflate(serialized, { level = 9 }))

-- Round trip: the string must decode back to the same table.
local ok, back = LibSerialize:Deserialize(LibDeflate:DecompressDeflate(LibDeflate:DecodeForPrint(text:sub(7))))
assert(ok and back.d.id == transmit.d.id and #back.c == #transmit.c, "the string doesn't decode back")

local target = "../Schizzle's Warrior Essentials.txt"
if arg and arg[1] == "--check" then
  local f = io.open(target, "rb")
  local current = f and f:read("*a")
  if f then f:close() end
  if current ~= text .. "\n" then
    print("the import string is out of date: run lua build.lua")
    os.exit(1)
  end
  print("import string is up to date (" .. #transmit.c .. " auras)")
  return
end
local f = assert(io.open(target, "wb"))
f:write(text .. "\n")
f:close()
print(("wrote %s: %d auras, %d characters"):format(target, #transmit.c, #text))
