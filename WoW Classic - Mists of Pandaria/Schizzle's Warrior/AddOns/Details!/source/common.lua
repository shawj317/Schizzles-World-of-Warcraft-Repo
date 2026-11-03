-- Shared helpers for the Schizzle's Warrior Details! build (plain Lua 5.1).
-- DETAILS_SRC: a Details! Damage Meter checkout (Tercioo/Details-Damage-Meter). WA_TYPES: WeakAuras/Types.lua (font registry).
DETAILS_SRC = os.getenv("DETAILS_SRC") or "/workspace/details-src/"
if DETAILS_SRC:sub(-1) ~= "/" then DETAILS_SRC = DETAILS_SRC .. "/" end
WA_TYPES = os.getenv("WA_TYPES") or "/workspace/wa2/WeakAuras/Types.lua"
local L = DETAILS_SRC .. "Libs/"
LibStub = nil
dofile(L .. "LibStub/LibStub.lua")
strbyte, strchar, strsub, gsub, gmatch, format = string.byte, string.char, string.sub, string.gsub, string.gmatch, string.format
strmatch = string.match
tinsert, tconcat = table.insert, table.concat
dofile(L .. "AceSerializer-3.0/AceSerializer-3.0.lua")
AceSer = LibStub("AceSerializer-3.0")
LD = dofile(L .. "LibDeflate/LibDeflate.lua")
-- mirrors Details:CompressData(data, "print") / Details:DecompressData(data, "print")
function encode(t) return LD:EncodeForPrint(LD:CompressDeflate(AceSer:Serialize(t), {level = 9})) end
function decode(s)
  s = s:gsub("^%s+", ""):gsub("%s+$", "")
  local c = assert(LD:DecodeForPrint(s), "DecodeForPrint failed")
  local d = assert(LD:DecompressDeflate(c), "DecompressDeflate failed")
  local ok, t = AceSer:Deserialize(d)
  assert(ok, "Deserialize failed: " .. tostring(t))
  return t
end
function deepcopy(t) if type(t) ~= "table" then return t end local r = {} for k, v in pairs(t) do r[k] = deepcopy(v) end return r end
function merge(dst, src)
  for k, v in pairs(src) do
    if type(v) == "table" and type(dst[k]) == "table" then merge(dst[k], v) else dst[k] = deepcopy(v) end
  end
  return dst
end
function equal(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end
  for k, v in pairs(a) do if not equal(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end
function readfile(p) local f = assert(io.open(p, "rb")) local s = f:read("*a") f:close() return s end
function writefile(p, s) local f = assert(io.open(p, "wb")) f:write(s) f:close() end

-- spec key -> output file, in-game profile name, specialization ID, window 2 display {attribute, sub-attribute}
SPECS = {
  {key = "arms", file = "Arms Profile.txt", name = "Schizzle's Warrior Arms", specId = 71, w2 = {1, 3}},       -- Damage > Damage Taken (closest built-in to tank mitigation)
  {key = "fury", file = "Fury Profile.txt", name = "Schizzle's Warrior Fury", specId = 72, w2 = {1, 3}},       -- Damage > Damage Taken (closest built-in to tank mitigation)
  {key = "prot", file = "Protection Profile.txt", name = "Schizzle's Warrior Protection", specId = 73, w2 = {1, 3}}, -- Damage > Damage Taken (closest built-in to tank mitigation)
}
SWITCH_FILE = "Spec Switch Code.lua"
