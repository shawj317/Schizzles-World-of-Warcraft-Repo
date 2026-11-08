-- Loads GSE 3.3.37-a and runs its import and compiler on ProtWar24.txt.
-- Nothing from GSE is copied here. Run from anywhere:
--   GSE_SRC=/path/to/tag-3.3.37-a lua gse_sim.lua
-- The default GSE_SRC is a local checkout of that tag, not a path inside this repo.
local HERE = (arg and arg[0] and arg[0]:match("^(.*)/[^/]*$")) or "."
local F = dofile(HERE .. "/gse_format.lua")
local S = dofile(HERE .. "/sequence.lua")
local GSE_SRC = os.getenv("GSE_SRC") or "/tmp/gse-src/gse-3337a"

local pass, fail = 0, 0
local function check(ok, what)
  if ok then pass = pass + 1 else fail = fail + 1; print("FAIL: " .. what) end
end

-- The release zip comments out --@debug@ blocks. A raw git checkout of the same
-- commit leaves them executable. Apply the packager's brackets so this runs
-- the code 3.3.37-a actually ships.
local function loadGSE(path)
  local fh = assert(io.open(GSE_SRC .. "/" .. path, "rb"), "missing " .. path)
  local src = fh:read("*a"):gsub("\r\n", "\n"):gsub("\r", "\n")
  fh:close()
  src = src:gsub("\n%-%-@debug@\n", "\n--[==[@debug@\n")
  src = src:gsub("\n%-%-@end%-debug@\n", "\n--@end-debug@]==]\n")
  local chunk, err = loadstring(src, path)
  if not chunk then error(err) end
  local result = chunk("GSE", GSE)
  if GSE.deferred then
    local pending = GSE.deferred
    GSE.deferred = nil
    for _, fn in ipairs(pending) do fn() end
  end
  return result
end

-- Enough of the WoW client for GSE's startup and for a Forever Warrior.
function GetBuildInfo()
  return "1.60.1", "70755", "Nov 8 2026", 16001
end
C_AddOns = {
  GetAddOnMetadata = function() return "3.3.37-a" end,
  IsAddOnLoaded = function() return false end,
}
local locale = setmetatable({}, {__index = function(_, k) return k end})
function LibStub(name)
  if name == "AceLocale-3.0" then
    return {GetLocale = function() return locale end}
  elseif name == "WagoAnalytics" then
    return {Register = function() return {Switch = function() end, SetCounter = function() end} end}
  end
  return {Embed = function() end}
end
function UnitClass() return "Warrior", "WARRIOR", 1 end
function UnitName() return "Schizzle" end
function GetUnitName() return "Schizzle" end
function GetSpecializationInfoByID() return nil end
C_CreatureInfo = {
  GetClassInfo = function(id)
    local names = {[1] = {"Warrior", "WARRIOR"}, [8] = {"Mage", "MAGE"}}
    local row = names[id]
    return row and {className = row[1], classFile = row[2]} or nil
  end,
}
C_SpecializationInfo = {}
function date(fmt) return os.date(fmt) end
strmatch = string.match
tinsert = table.insert
function strtrim(s) return (tostring(s):gsub("^%s+", ""):gsub("%s+$", "")) end
function string.join(sep, ...) return table.concat({...}, sep) end
function string.split(delim, s)
  local out = {}
  for part in tostring(s):gmatch("([^" .. delim .. "]+)") do out[#out + 1] = part end
  return unpack(out)
end
function hooksecurefunc() end
function debugprofilestop() return 0 end
function debugprofilestart() end
function InCombatLockdown() return false end
C_Timer = {After = function() end}
function CreateFrame()
  return {RegisterEvent = function() end, SetScript = function() end, Execute = function() end,
    SetAttribute = function(self, k, v) self.attrs = self.attrs or {}; self.attrs[k] = v end,
    GetAttribute = function(self, k) return self.attrs and self.attrs[k] end}
end
GSEOptions = {}
IndentationLib = {tokens = setmetatable({}, {__index = function() return 0 end})}
SlashCmdList = {}
GSE = {L = locale, Static = {}, GSE = nil}
GSE.GSE = GSE
function GSE:SendMessage() end
function GSE:RegisterEvent() end
function GSE:UnregisterEvent() end
function GSE:RegisterComm() end

F.install()
loadGSE("GSE/API/Init.lua")
check(GSE.VersionString == "3.3.37-a", "Init.lua read the addon version 3.3.37-a")
check(GSE.VersionNumber == 3337, "ParseVersion(3.3.37-a) == 3337, got " .. tostring(GSE.VersionNumber))
check(GSE.IsForever == true, "version 1.60.1 is Forever")
check(GSE.GameMode == 12, "Forever reports API generation 12, got " .. tostring(GSE.GameMode))
check(GSE.TOCFlavour(16001) == "forever", "TOC 16001 is the forever flavour")
check(GSE.TOCFlavour(11509) ~= GSE.TOCFlavour(16001), "Era 11509 is not the forever flavour")
check(GSE.DirectKeybindsRetired == true, "Forever does not honour GSE's own SetBindingClick keybinds")

loadGSE("GSE/API/Statics.lua")
loadGSE("GSE/API/InitialOptions.lua")
loadGSE("GSE/API/StringFunctions.lua")
loadGSE("GSE/API/CharacterFunctions.lua")
loadGSE("GSE/API/Checksum.lua")
loadGSE("GSE/API/Serialisation.lua")
loadGSE("GSE/API/translator.lua")
loadGSE("GSE/API/Storage.lua")
loadGSE("GSE_Utils/Utils.lua")

-- Class ids, from the loaded tables and from GetClassIDforSpec, not from a comment.
check(GSE.SpecIDClassList[1] == 1, "SpecIDClassList[1] is class 1")
check(GSE.SpecIDClassList[8] == 8, "SpecIDClassList[8] is class 8")
check(GSE.SpecIDClassList[71] == 1 and GSE.SpecIDClassList[72] == 1 and GSE.SpecIDClassList[73] == 1,
  "Arms 71, Fury 72 and Protection 73 all map to class 1")
check(GSE.GetClassIDforSpec(1) == 1, "GetClassIDforSpec(1) == 1 on Forever (GameMode " .. tostring(GSE.GameMode) .. ")")
check(GSE.GetClassIDforSpec(8) == 8, "GetClassIDforSpec(8) == 8, which is Mage, not Warrior")
check(GSE.GetClassIDforSpec(73) == 1, "GetClassIDforSpec(73) falls back to class 1 when the client has no retail spec")
check(GSE.GetClassIcon(1) ~= GSE.GetClassIcon(8), "class icons for 1 and 8 differ")
check(GSE.GetCurrentClassID() == 1, "the mocked player is class 1")

-- Spell lookup stays empty, so the compiler keeps the English names we stored.
GSE.GetSpellInfo = function() return nil end
GSE.GetSpellId = function() return nil end
GSE.Print = function() end
GSE.PrintDebugMessage = function() end
GSE.GUICall = function(name) end

local f = assert(io.open(HERE .. "/../ProtWar24.txt", "rb"))
local export = f:read("*a"):gsub("%s+$", "")
f:close()

local ok, decoded = GSE.DecodeMessage(export)
check(ok == true, "GSE.DecodeMessage accepts the string (its slice keeps the prefix '!')")
check(type(decoded) == "table" and decoded.type == "COLLECTION", "decoded type is COLLECTION")
local seq = ok and decoded.payload and decoded.payload.Sequences and decoded.payload.Sequences[S.name]
check(type(seq) == "table", "ProtWar24 is a sequence table inside the collection, not a sealed !GSE3!+ blob")
check(seq and seq.MetaData and seq.MetaData.SpecID == 1, "imported SpecID is 1")
check(seq and seq.MetaData and seq.MetaData.TOC == 16001, "imported TOC is 16001")
check(seq and seq.MetaData and seq.MetaData.GSEVersion == 3337, "imported GSEVersion is 3337")
check(seq and seq.Versions and seq.Macros == nil, "current Versions schema, no legacy Macros table")
check(GSE.VerifySequenceChecksum(seq) == "no_checksum",
  "no checksum is stored, so GSE reports no_checksum rather than a failed (altered) check")

local accepted = GSE.ImportSerialisedSequence(export, false)
check(accepted == true, "GSE.ImportSerialisedSequence accepts the collection, got " .. tostring(accepted))
-- Import queues a Save. Out of combat, Events.lua ProcessOOCQueue runs
-- OOCAddSequenceToCollection for that action. Events.lua is the frame layer;
-- this calls the same Storage function the queue drains into.
check(type(GSE.OOCQueue) == "table" and #GSE.OOCQueue >= 1, "import queued work for out of combat")
local queued = GSE.OOCQueue or {}
GSE.OOCQueue = {}
for _, v in ipairs(queued) do
  if v.action == "Save" then
    GSE.OOCAddSequenceToCollection(v.sequencename, v.sequence, v.classid, v.id)
  elseif v.action == "MergeSequence" and GSE.OOCPerformMergeAction then
    GSE.OOCPerformMergeAction(v.mergeaction, v.classid, v.id, v.newSequence, v.newname)
  end
end
for _, v in ipairs(GSE.OOCQueue or {}) do
  if v.action == "MergeSequence" and GSE.OOCPerformMergeAction then
    GSE.OOCPerformMergeAction(v.mergeaction, v.classid, v.id, v.newSequence, v.newname)
  elseif v.action == "Save" then
    GSE.OOCAddSequenceToCollection(v.sequencename, v.sequence, v.classid, v.id)
  end
end

local filed
if GSE.Library and GSE.Library[1] then
  for _, body in pairs(GSE.Library[1]) do
    if type(body) == "table" and body.MetaData and body.MetaData.Name == S.name then filed = body end
  end
end
check(filed ~= nil, "the sequence is filed under class library 1")
check(filed and filed.MetaData.SpecID == 1, "filed SpecID stays 1")

local version = filed and filed.Versions and filed.Versions[filed.MetaData.Default]
local compiled = version and GSE.CompileTemplate(version) or {}
check(#compiled == 2, "compiler returns two presses, got " .. tostring(#compiled))
for i, macro in ipairs(S.blocks) do
  local step = compiled[i] or {}
  check(step.macrotext == macro, "press " .. i .. " macrotext is the stored block")
  check(step.type == "macro", "press " .. i .. " is a macro action for the secure button")
  check(GSE.IsMacroTextBody(step.macrotext or "") == true, "press " .. i .. " starts with a slash command")
  check(#(step.macrotext or "") <= 255, "press " .. i .. " is within 255 characters (" .. #(step.macrotext or "") .. ")")
end
check(compiled[1] and compiled[2] and compiled[1].macrotext ~= compiled[2].macrotext,
  "the two presses are not the same block")

-- One re-encode through the real function matches the file. Map key order is
-- this writer's order; the game reads the map either way.
local again = GSE.EncodeMessage(decoded)
check(again == export, "GSE.EncodeMessage(GSE.DecodeMessage(export)) == export")

print(("%d checks, %d failures"):format(pass + fail, fail))
os.exit(fail == 0 and 0 or 1)
