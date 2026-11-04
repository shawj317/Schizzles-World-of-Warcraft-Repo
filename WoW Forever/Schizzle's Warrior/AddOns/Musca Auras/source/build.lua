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
