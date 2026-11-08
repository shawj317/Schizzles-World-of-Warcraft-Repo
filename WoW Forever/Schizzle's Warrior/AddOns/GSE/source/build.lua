-- Writes ProtWar24.txt by calling GSE.EncodeMessage from the GSE 3.3.37-a source.
-- GSE itself is not copied into this repository. Point GSE_SRC at a checkout of
-- tag 3.3.37-a (commit ad50d1ab6e6d754f0b1c49f06c320cf7788f27a4).
-- Usage: lua build.lua
local HERE = (arg and arg[0] and arg[0]:match("^(.*)/[^/]*$")) or "."
local F = dofile(HERE .. "/gse_format.lua")
local S = dofile(HERE .. "/sequence.lua")
local GSE_SRC = os.getenv("GSE_SRC") or "/tmp/gse-src/gse-3337a"
local OUT = HERE .. "/../ProtWar24.txt"

local function sequenceTable()
  local actions = {}
  for _, macro in ipairs(S.blocks) do
    actions[#actions + 1] = {Type = "Action", type = "macro", macro = macro}
  end
  return {
    LastUpdated = S.lastUpdated,
    MetaData = {
      Author = S.author,
      Default = 1,
      EnforceCompatability = true,
      GSEVersion = S.gseVersion,
      Help = S.help,
      Helplink = S.helplink,
      Name = S.name,
      SpecID = S.specID,
      TOC = S.toc,
      Talents = {},
    },
    Versions = {{Label = S.label, Actions = actions, InbuiltVariables = {}}},
    WeakAuras = {},
  }
end

-- The same wrapper GSE_GUI/Export.lua compileExport writes for one sequence:
-- a COLLECTION, with empty variable and macro lists, and no Collections
-- provenance (that is added only when the package has a name and 2 or more elements).
local function collection()
  return {
    type = "COLLECTION",
    payload = {
      ElementCount = 1,
      Macros = {},
      Sequences = {[S.name] = sequenceTable()},
      Variables = {},
    },
  }
end

F.install()
-- Serialisation.lua registers chat filters only when GameMode < 12. Forever's
-- Init.lua sets GameMode to 12, so that block does not run there either.
function hooksecurefunc() end
GSE = {L = {}, Static = {}, GameMode = 12}
function GSE:RegisterComm() end
local chunk, err = loadfile(GSE_SRC .. "/GSE/API/Serialisation.lua")
if not chunk then
  io.stderr:write("GSE 3.3.37-a source not found at " .. GSE_SRC .. " (" .. tostring(err) .. ")\n")
  io.stderr:write("Clone https://github.com/TimothyLuke/GSE-Advanced-Macro-Compiler at tag 3.3.37-a and set GSE_SRC.\n")
  os.exit(1)
end
chunk("GSE", GSE)
assert(type(GSE.EncodeMessage) == "function", "GSE.EncodeMessage was not defined by Serialisation.lua")

local export = GSE.EncodeMessage(collection())
assert(export:sub(1, 6) == "!GSE3!" and export:sub(7, 7) ~= "+", "EncodeMessage did not return a plain !GSE3! string")
local f = assert(io.open(OUT, "wb"))
f:write(export)
f:write("\n")
f:close()
print(("wrote %d chars via GSE.EncodeMessage to %s"):format(#export, OUT))
