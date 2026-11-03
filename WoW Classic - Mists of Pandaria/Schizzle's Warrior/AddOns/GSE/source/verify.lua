-- Checks the GSE import string against sequence.lua, GSE's own source and the MoP Classic client's spell data.
-- Usage: lua verify.lua
--   GSE_SRC  GSE source checkout (default /workspace/gse), read only: GSE is All Rights Reserved, nothing is copied.
--   DB2_DIR  MoP Classic 5.5.4 DB2 tables as CSV from wago.tools (SpellName, SpellLevels, SpellCategories,
--            SpellCooldowns, SpellPower, SkillLineAbility; default /workspace/db2).
local HERE = (arg and arg[0] and arg[0]:match("^(.*)/[^/]*$")) or "."
local F = dofile(HERE .. "/gse_format.lua")
local S = dofile(HERE .. "/sequence.lua")
local GSE_SRC = os.getenv("GSE_SRC") or "/workspace/gse"
local DB2 = os.getenv("DB2_DIR") or "/workspace/db2"

local pass, fail = 0, 0
local function check(ok, what)
  if ok then pass = pass + 1 else fail = fail + 1; print("FAIL: " .. what) end
end
local function readFile(p) local f = assert(io.open(p, "rb"), "missing " .. p); local s = f:read("*a"); f:close(); return s end

-- 1. The string itself
local export = readFile(HERE .. "/../Schizzle's Warrior Level 8.txt")
check(export:sub(1, 6) == "!GSE3!", "starts with !GSE3!")
check(export:sub(7, 7) ~= "+", "plain string, not a sealed !GSE3!+ one")
check(not export:find("[\r\n ]"), "one line, no spaces")
check(export:sub(7):match("^[%w%+/]+=?=?$") ~= nil, "standard Base64 body")
check((#export - 6) % 4 == 0, "Base64 is padded")
local data = F.decode(export)
check(F.encode(data) == export, "re-encoding the decoded table gives the same string")

-- 2. GSE's own rules, read from its source
local statics = readFile(GSE_SRC .. "/GSE/API/Statics.lua")
local validTypes = {}
for name in statics:gmatch('Statics%.Actions%.(%w+) = "%w+"') do validTypes[name] = true end
check(validTypes.Action and validTypes.Loop, "found GSE's action block types")
local minChecksum = tonumber(statics:match("Statics%.ChecksumMinVersion%s*=%s*(%d+)"))
check(minChecksum ~= nil, "found GSE's ChecksumMinVersion")
local toc = readFile(GSE_SRC .. "/GSE/GSE.toc")
local interfaces = toc:match("## Interface:%s*([^\n]+)") or ""
check((" " .. interfaces:gsub(",", " ") .. " "):find(" " .. S.toc .. " ", 1, true) ~= nil,
  "GSE.toc lists the MoP Classic interface " .. S.toc)
local utils = readFile(GSE_SRC .. "/GSE_Utils/Utils.lua")
check(utils:find('actiontable.type == "COLLECTION"', 1, true) ~= nil, "GSE imports COLLECTION payloads")
check(utils:find("input.Macros ~= nil and input.Versions == nil", 1, true) ~= nil,
  "GSE refuses the old Macros schema (so we must ship Versions)")
check(utils:find("v.MetaData.GSEVersion > 3200", 1, true) ~= nil, "GSE needs GSEVersion above 3200")
local storage = readFile(GSE_SRC .. "/GSE/API/Storage.lua")
check(storage:find("node.macro = node.macrotext", 1, true) ~= nil, "GSE stores macro text under 'macro'")

check(data.type == "COLLECTION" and type(data.payload) == "table", "COLLECTION wrapper")
local p = data.payload or {}
local n = 0
for _ in pairs(p.Sequences or {}) do n = n + 1 end
check(n == #S.sequences and p.ElementCount == n, "ElementCount matches the sequence count")
check(type(p.Macros) == "table" and next(p.Macros) == nil and type(p.Variables) == "table" and next(p.Variables) == nil,
  "no macros or variables ride along")

-- 3. Spell data from the MoP Classic client
local function csv(name, key, fields)
  local rows, header = {}, nil
  for line in io.lines(DB2 .. "/" .. name .. ".csv") do
    local cells, pos = {}, 1
    while pos <= #line + 1 do
      local cell, nextPos
      if line:sub(pos, pos) == '"' then
        local close = line:find('"', pos + 1, true)
        cell, nextPos = line:sub(pos + 1, close - 1), close + 2
      else
        local comma = line:find(",", pos, true) or (#line + 1)
        cell, nextPos = line:sub(pos, comma - 1), comma + 1
      end
      cells[#cells + 1] = cell
      pos = nextPos
    end
    if not header then header = {}; for j, h in ipairs(cells) do header[h] = j end
    else
      local r = {}
      for _, fld in ipairs(fields) do r[fld] = cells[header[fld]] end
      if not rows[cells[header[key]]] or r.DifficultyID == "0" then rows[cells[header[key]]] = r end
    end
  end
  return rows
end
local names = csv("SpellName", "ID", {"Name_lang"})
local levels = csv("SpellLevels", "SpellID", {"BaseLevel", "DifficultyID"})
local cats = csv("SpellCategories", "SpellID", {"StartRecoveryCategory", "DifficultyID"})
local cds = csv("SpellCooldowns", "SpellID", {"StartRecoveryTime", "RecoveryTime", "DifficultyID"})
local skill = {}
for line in io.lines(DB2 .. "/SkillLineAbility.csv") do
  local _, line_, spell = line:match("^(%d+),(%d+),(%d+),")
  if spell then skill[spell] = skill[spell] or {}; skill[spell][line_] = true end
end

-- name -> spell ID used by the macros; 840 = Warrior class skill line, 125 = Orc racial skill line
local SPELLS = {
  ["Heroic Strike"] = {id = "78", line = "840", gcd = false},
  ["Charge"] = {id = "100", line = "840", gcd = false},
  ["Victory Rush"] = {id = "34428", line = "840", gcd = true},
  ["Execute"] = {id = "5308", line = "840", gcd = true},
  ["Blood Fury"] = {id = "20572", line = "125", gcd = false},
}
for name, sp in pairs(SPELLS) do
  check(names[sp.id] and names[sp.id].Name_lang == name, name .. " is spell " .. sp.id)
  check(levels[sp.id] and tonumber(levels[sp.id].BaseLevel) <= 8, name .. " is learned by level 8")
  check(skill[sp.id] and skill[sp.id][sp.line], name .. " belongs to skill line " .. sp.line)
  local onGCD = (cats[sp.id] and cats[sp.id].StartRecoveryCategory == "133")
    or (cds[sp.id] and tonumber(cds[sp.id].StartRecoveryTime) > 0)
  check(onGCD == sp.gcd, name .. (sp.gcd and " is on the GCD" or " is off the GCD"))
end
check(tonumber(cds["20572"].RecoveryTime) == 120000, "Blood Fury has a 2 minute cooldown")
-- Abilities people expect from older expansions that a MoP Warrior does not have yet at level 8
for id, name in pairs({["6673"] = "Battle Shout", ["6343"] = "Thunder Clap", ["7386"] = "Sunder Armor",
                       ["57755"] = "Heroic Throw", ["71"] = "Defensive Stance"}) do
  check(tonumber(levels[id].BaseLevel) > 8, name .. " comes after level 8 (" .. levels[id].BaseLevel .. ")")
end

-- 4. Each sequence matches sequence.lua and keeps to the hardware-event rules
local sheet = readFile(HERE .. "/../Level 8 Sequences (readable).md")
for _, def in ipairs(S.sequences) do
  local seq = (p.Sequences or {})[def.name] or {}
  local md = seq.MetaData or {}
  check(seq.Macros == nil and type(seq.Versions) == "table" and #seq.Versions == 1, def.name .. ": one Version, no Macros")
  check(md.Name == def.name and md.SpecID == S.specID and md.TOC == S.toc and md.Default == 1, def.name .. ": MetaData")
  check(md.GSEVersion == S.gseVersion and md.GSEVersion > 3200 and md.GSEVersion >= (minChecksum or 0),
    def.name .. ": GSEVersion is current-format")
  check(md.Checksum == nil, def.name .. ": no forged checksum")
  check(md.Author == "Jon Shaw (Schizzle)", def.name .. ": author credit")
  check(#def.name <= 16 and def.name:match("^[%u%d_]+$"), def.name .. ": unique button-safe name")
  local v = seq.Versions and seq.Versions[1] or {}
  check(v.Label == def.label and type(v.InbuiltVariables) == "table", def.name .. ": version label")
  check(#(v.Actions or {}) == #def.blocks, def.name .. ": block count")
  for i, b in ipairs(def.blocks) do
    local a = (v.Actions or {})[i] or {}
    local where = def.name .. " block " .. i
    check(validTypes[a.Type] and a.type == "macro" and a.macro == b.macro, where .. ": macro Action matches source")
    check(#b.macro <= 255, where .. ": " .. #b.macro .. " of 255 characters")
    check(sheet:find("```\n" .. b.macro .. "\n```", 1, true) ~= nil, where .. ": readable sheet is current")
    local gcdCasts = 0
    for line in (b.macro .. "\n"):gmatch("([^\n]*)\n") do
      check(line:match("^/%a+") ~= nil, where .. ": '" .. line .. "' is a slash command")
      local spell = line:match("^/cast%s*%b[]%s*(.+)$") or line:match("^/cast%s+(.+)$")
      if spell then
        check(SPELLS[spell] ~= nil, where .. ": " .. spell .. " is a known level 8 spell")
        if SPELLS[spell] and SPELLS[spell].gcd and not line:match("^/cast%s*%[") then gcdCasts = gcdCasts + 1 end
      end
    end
    check(gcdCasts <= 1, where .. ": at most one GCD ability per press")
  end
end

-- 5. Nothing personal in what ships
for _, path in ipairs({"/../Schizzle's Warrior Level 8.txt", "/../Level 8 Sequences (readable).md", "/sequence.lua"}) do
  local s = readFile(HERE .. path)
  check(not s:find("REDACTED") and not s:find("Peanut"), path .. ": no personal names")
end
local decodedText = F.cbor(data)
check(not decodedText:find("@", 1, true), "no Name@Realm inside the export")

print(("%d checks, %d failures"):format(pass + fail, fail))
os.exit(fail == 0 and 0 or 1)
