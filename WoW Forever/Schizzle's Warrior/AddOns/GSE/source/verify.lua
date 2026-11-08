-- Checks ProtWar24.txt against sequence.lua, a zlib inflate, and GSE 3.3.37-a's own code.
-- Usage: lua verify.lua
--   GSE_SRC   checkout of TimothyLuke/GSE-Advanced-Macro-Compiler tag 3.3.37-a
--             (default /tmp/gse-src/gse-3337a). GSE is All Rights Reserved and is not copied here.
--   WA_LIBS   directory that contains LibDeflate/LibDeflate.lua (default /opt/wow-addon-deps)
local HERE = (arg and arg[0] and arg[0]:match("^(.*)/[^/]*$")) or "."
local F = dofile(HERE .. "/gse_format.lua")
local S = dofile(HERE .. "/sequence.lua")
local GSE_SRC = os.getenv("GSE_SRC") or "/tmp/gse-src/gse-3337a"
local EXPECTED_COMMIT = "ad50d1ab6e6d754f0b1c49f06c320cf7788f27a4"

local EXPECTED = {
  "/startattack\n/cast [mod:alt,mod:shift] Cleave; [mod:shift] Thunder Clap; [mod:ctrl] Shield Block; [mod:alt] Heroic Strike; [stance:2] Revenge",
  "/startattack\n/cast [mod:alt,mod:shift] Cleave; [mod:shift] Thunder Clap; [mod:ctrl] Shield Block; [mod:alt] Heroic Strike; [stance:2] Sunder Armor",
}

local pass, fail = 0, 0
local function check(ok, what)
  if ok then pass = pass + 1 else fail = fail + 1; print("FAIL: " .. what) end
end
local function readFile(path)
  local f = assert(io.open(path, "rb"), "missing " .. path)
  local s = f:read("*a")
  f:close()
  return s
end

-- 1. The file is one import string and nothing else.
local rawFile = readFile(HERE .. "/../ProtWar24.txt")
check(rawFile:sub(-1) == "\n" and not rawFile:sub(1, -2):find("\n", 1, true), "one line, then a newline")
local export = rawFile:gsub("%s+$", "")
check(export:sub(1, 6) == "!GSE3!" and export:sub(7, 7) ~= "+", "plain !GSE3! prefix, not the sealed !GSE3!+ envelope")
check(not export:find("[%s]"), "no spaces inside the string")
local body = F.strictPayload(export)
check(#body % 4 == 0, "Base64 length is a multiple of 4")

-- 2. Strict payload (from character 7) and GSE's own slice (from character 6, which
-- keeps the prefix "!") inflate to the same CBOR. Python's zlib is a second inflater.
F.install()
local strictTable, strictRaw = F.decodeStrict(export)
local gseSlice = C_EncodingUtil.DecompressString(C_EncodingUtil.DecodeBase64(export:sub(6)))
check(gseSlice == strictRaw, "GSE.DecodeMessage's slice and the strict payload are the same deflate stream")

local tmp = os.tmpname()
local tf = assert(io.open(tmp, "wb")); tf:write(F.unb64(body)); tf:close()
local py = io.popen(string.format(
  "python3 -c 'import zlib,sys; sys.stdout.buffer.write(zlib.decompress(open(%q,\"rb\").read(), -15))'", tmp))
local inflated = py:read("*a")
local pyOk = py:close()
os.remove(tmp)
check(pyOk and inflated == strictRaw, "Python zlib (wbits -15) inflates the payload to the same CBOR")

local function same(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end
  local keys = {}
  for k in pairs(a) do keys[k] = true end
  for k in pairs(b) do if not keys[k] then return false end end
  for k in pairs(keys) do if not same(a[k], b[k]) then return false end end
  return true
end
check(same(C_EncodingUtil.DeserializeCBOR(strictRaw), strictTable), "CBOR decode matches")
check(same(strictTable, C_EncodingUtil.DeserializeCBOR(gseSlice)), "both slices decode to the same table")

-- 3. The table is the current collection schema and the two blocks are exact.
check(strictTable.type == "COLLECTION", "COLLECTION wrapper")
local payload = strictTable.payload or {}
check(payload.ElementCount == 1, "one element")
check(type(payload.Macros) == "table" and next(payload.Macros) == nil, "no WoW macros in the collection")
check(type(payload.Variables) == "table" and next(payload.Variables) == nil, "no variables in the collection")
check(payload.Collections == nil, "a one-element export has no collection-provenance list")
local seq = (payload.Sequences or {})[S.name]
check(type(seq) == "table", "sequence key is ProtWar24")
check(seq and seq.Macros == nil and type(seq.Versions) == "table" and #seq.Versions == 1,
  "Versions schema, one version, no legacy Macros table")
local md = seq and seq.MetaData or {}
check(md.Name == "ProtWar24" and md.SpecID == 1 and md.TOC == 16001 and md.GSEVersion == 3337
  and md.EnforceCompatability == true and md.Default == 1 and md.Author == S.author,
  "metadata name, Warrior SpecID 1, TOC 16001, GSEVersion 3337")
check(md.Checksum == nil, "no checksum, so a wrong client salt cannot fail as tampered")
local actions = seq and seq.Versions[1].Actions or {}
check(#actions == 2, "two actions")
for i, want in ipairs(EXPECTED) do
  check(S.blocks[i] == want, "sequence.lua block " .. i .. " is the requested text")
  local action = actions[i] or {}
  check(action.Type == "Action" and action.type == "macro" and action.macro == want,
    "stored block " .. i .. " is an Action macro with that text (" .. #(action.macro or "") .. " chars)")
  check(#want <= 255, "block " .. i .. " is within 255 characters")
  check(want:sub(1, 12) == "/startattack", "block " .. i .. " starts with /startattack")
  check(not want:find("/cast Heroic Strike", 1, true), "block " .. i .. " does not cast Heroic Strike unconditionally")
  for _, banned in ipairs({"Taunt", "Shield Bash", "Last Stand", "Shield Wall", "Bloodrage", "Shield Slam", "Demoralizing"}) do
    check(not want:find(banned, 1, true), "block " .. i .. " does not contain " .. banned)
  end
end
local cast1 = EXPECTED[1]:match("\n(.+)$")
local cast2 = EXPECTED[2]:match("\n(.+)$")
check(cast1:gsub("Revenge$", "") == cast2:gsub("Sunder Armor$", ""), "block 2 is block 1 with Sunder Armor in place of Revenge")
local function pos(s, needle) local n = s:find(needle, 1, true); return n end
local orderNeedles = {"[mod:alt,mod:shift] Cleave", "[mod:shift] Thunder Clap", "[mod:ctrl] Shield Block",
  "[mod:alt] Heroic Strike", "[stance:2] "}
local last = 0
local ordered = true
for _, needle in ipairs(orderNeedles) do
  local n = pos(cast1, needle)
  if not n or n <= last then ordered = false end
  last = n or last
end
check(ordered, "cast conditions are Alt-Shift, Shift, Ctrl, Alt, then stance 2")
check(cast1:sub(-7) == "Revenge" and cast2:sub(-12) == "Sunder Armor", "the final spells are Revenge and Sunder Armor")

-- 4. GSE 3.3.37-a source, read only.
local function gse(path) return readFile(GSE_SRC .. "/" .. path) end
local commit = io.popen("git -C " .. string.format("%q", GSE_SRC) .. " rev-parse HEAD"):read("*l")
check(commit == EXPECTED_COMMIT, "GSE_SRC is tag 3.3.37-a commit " .. EXPECTED_COMMIT .. ", got " .. tostring(commit))
local serial = gse("GSE/API/Serialisation.lua")
check(serial:find('"!GSE3!" .. C_EncodingUtil.EncodeBase64(C_EncodingUtil.CompressString(C_EncodingUtil.SerializeCBOR(tab)))', 1, true) ~= nil,
  "EncodeMessage is the !GSE3! Base64(Deflate(CBOR)) wrapper")
check(serial:find('local message = string.sub(data, 6, #data)', 1, true) ~= nil,
  "DecodeMessage slices from character 6")
local statics = gse("GSE/API/Statics.lua")
check(statics:find("[1]  = {71, 72, 73},    -- Warrior", 1, true) ~= nil, "class 1's trees are Warrior")
check(statics:find("[8]  = {62, 63, 64},    -- Mage", 1, true) ~= nil, "class 8's trees are Mage")
check(statics:find("[1] = 1,", 1, true) ~= nil and statics:find("[8] = 8,", 1, true) ~= nil,
  "SpecIDClassList maps 1 to class 1 and 8 to class 8")
check(statics:find("[73] = 1,", 1, true) ~= nil, "Protection spec 73 maps to class 1")
local chars = gse("GSE/API/CharacterFunctions.lua")
check(chars:find("classicon[1] = 626008 -- Warrior", 1, true) ~= nil, "class icon 1 is commented Warrior")
check(chars:find("classicon[8] = 626001 -- Mage", 1, true) ~= nil, "class icon 8 is commented Mage")
check(chars:find("if specid <= 13 then", 1, true) ~= nil, "GetClassIDforSpec treats an id of 13 or less as that class id")
local init = gse("GSE/API/Init.lua")
check(init:find("(tonumber(numbers[1]) * 1000) + (tonumber(numbers[2]) * 100) + (tonumber(numbers[3]))", 1, true) ~= nil,
  "ParseVersion encodes a.b.c as a*1000 + b*100 + c")
check(init:find('local parts = GSE.split(version, "-")', 1, true) ~= nil, "ParseVersion drops a -suffix such as -a")
local toc = gse("GSE/GSE.toc")
check(toc:find("16001", 1, true) ~= nil, "GSE.toc lists interface 16001")
local utils = gse("GSE_Utils/Utils.lua")
check(utils:find('actiontable.type == "COLLECTION"', 1, true) ~= nil, "import accepts a COLLECTION")
check(utils:find("input.Macros ~= nil and input.Versions == nil", 1, true) ~= nil,
  "import refuses a sequence that still uses the old Macros field")
check(utils:find("v.MetaData.GSEVersion > 3200", 1, true) ~= nil, "import requires GSEVersion above 3200")
local storage = gse("GSE/API/Storage.lua")
check(storage:find('gsebutton:SetAttribute("type", "spell")', 1, true) ~= nil, "the executor is a secure button")
check(storage:find('gsebutton:SetAttribute(k, v)', 1, true) ~= nil, "macrotext is copied onto the secure button")
check(storage:find("step = step % #spelllist[iteration] + 1", 1, true) ~= nil,
  "each press advances one step, with no test of whether the cast succeeded")
local options = gse("GSE/API/InitialOptions.lua")
check(options:find("GSEOptions.ShiftPause = false", 1, true) ~= nil
  and options:find("GSEOptions.AltPause = false", 1, true) ~= nil
  and options:find("GSEOptions.CtrlPause = false", 1, true) ~= nil,
  "Shift, Alt and Ctrl pause default off, so those modifiers reach the macro")

-- 5. The real addon import and compiler. gse_sim.lua loads this same checkout.
local sim = os.execute(string.format("lua %q", HERE .. "/gse_sim.lua"))
check(sim == 0 or sim == true, "gse_sim.lua passed")

print(("%d checks, %d failures"):format(pass + fail, fail))
os.exit(fail == 0 and 0 or 1)
