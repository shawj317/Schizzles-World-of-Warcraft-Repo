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
