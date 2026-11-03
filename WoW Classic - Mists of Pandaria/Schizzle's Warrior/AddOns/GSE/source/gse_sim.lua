-- Imports the export into GSE's own code and compiles it, offline, to show what GSE 3.3.36-a does with it.
-- Usage: cd <GSE source checkout at tag 3.3.36-a> && lua "<this dir>/gse_sim.lua"
-- It loads GSE's files and its spec/mockGSE.lua from the current directory and runs them; nothing of GSE is copied
-- here (GSE is All Rights Reserved). It checks that:
--   - importing the collection files SCHIZ_TARGET as a variable and both sequences, with no older-version notice
--   - GSE's compiler turns every block into the same text F.expand gives (verify.lua checks that against v1.1)
--   - a block that started with the variable line would not be macro text, which is why /cleartarget stays first
local HERE = (arg and arg[0] and arg[0]:match("^(.*)/[^/]*$")) or "."
local F = dofile(HERE .. "/gse_format.lua")
local S = dofile(HERE .. "/sequence.lua")
local pass, fail = 0, 0
local function check(ok, what)
  if ok then pass = pass + 1 else fail = fail + 1; print("FAIL: " .. what) end
end

dofile("spec/mockGSE.lua")
GSE.V = GSE.V or {}
for _, m in ipairs({"Statics", "InitialOptions", "StringFunctions", "CharacterFunctions", "Storage", "translator"}) do
  require("../GSE/API/" .. m)
end
require("../GSE_Utils/Utils")
GSE.PrintDebugMessage = function() end
-- What GSE.ParseVersion makes of "3.3.36-a" (verify.lua checks the rule against GSE's source).
GSE.VersionString, GSE.VersionNumber = "3.3.36-a", 3336
GSE.GetGCD = function() return 1.5 end
GSE.GetClickRate = function() return 100 end
GSE.GetSpellInfo = function() return nil end
GSE.GetSpellId = function() return nil end
local queue, prints, dialogs = {}, {}, {}
GSE.EnqueueOOC = function(v) queue[#queue + 1] = v end
GSE.Print = function(m) prints[#prints + 1] = tostring(m) end
GSE.GUICall = function(name) dialogs[#dialogs + 1] = name end
GSE.SendMessage = function() end
local function printed(pattern)
  for _, p in ipairs(prints) do if p:find(pattern) then return p end end
end

-- 1. Import
local f = assert(io.open(HERE .. "/../Schizzle's Warrior Level 8.txt", "rb")); local export = f:read("*a"); f:close()
local data = F.decode(export)
check(GSE.ImportSerialisedSequence(data, false) == true, "GSE accepts the collection")
local varAt, saved = {}, {}
for i, q in ipairs(queue) do
  if q.action == "updatevariable" then varAt[q.name] = i end
  if q.action == "Save" then saved[q.sequencename] = {at = i, seq = q.sequence} end
end
for _, var in ipairs(S.variables) do
  local q = queue[varAt[var.name] or 0] or {}
  check(varAt[var.name] ~= nil, var.name .. ": GSE files it as a variable")
  local active = q.variable and q.variable.Versions and q.variable.Versions[1] or {}
  check(active.funct == var.funct, var.name .. ": its Lua arrives unchanged")
  -- GSE.V[name] is what the variable's Lua returns when run (compileVariable); run it the same way.
  local ok, fn = pcall(function() return loadstring("return " .. active.funct)() end)
  GSE.V[var.name] = ok and fn or nil
  check(type(GSE.V[var.name]) == "function" and GSE.V[var.name]() == var.returns, var.name .. ": returns " .. var.returns)
end
for _, def in ipairs(S.sequences) do
  local s = saved[def.name]
  check(s ~= nil, def.name .. ": GSE files it as a sequence")
  for _, var in ipairs(S.variables) do
    check(s and varAt[var.name] and varAt[var.name] < s.at, def.name .. ": " .. var.name .. " is filed before it")
  end
end
check(not printed("older version"), "no 'created with an older version' notice")
check(not printed("not compatible") and not printed("not available in this version"), "no compatibility refusal")
check(#dialogs == 0, "no dialogs during the collection import")

-- 2. Compile
for _, def in ipairs(S.sequences) do
  local seq = saved[def.name] and saved[def.name].seq or {}
  local compiled = GSE.CompileTemplate(seq.Versions and seq.Versions[seq.MetaData.Default] or {Actions = {}}) or {}
  check(#compiled == #def.blocks, def.name .. ": " .. #def.blocks .. " compiled press(es)")
  for i, b in ipairs(def.blocks) do
    local c = compiled[i] or {}
    local want = F.expand(b.macro, S.variables)
    check(c.macrotext == want, def.name .. " block " .. i .. ": GSE compiles it to the expanded text")
    check(#(c.macrotext or "") <= 255, def.name .. " block " .. i .. ": compiled text within 255 characters")
  end
end
check(not printed("Missing Variable"), "no missing-variable message")

-- 3. Why the variable is not the first line
local first = GSE.CompileTemplate({Actions = {{Type = "Action", type = "macro",
  macro = S.variables[1].call .. "\n/cast Charge"}}}) or {}
check(first[1] and first[1].macrotext == nil, "a block starting with the variable line is not run as macro text")

print(("%d checks, %d failures"):format(pass + fail, fail))
os.exit(fail == 0 and 0 or 1)
