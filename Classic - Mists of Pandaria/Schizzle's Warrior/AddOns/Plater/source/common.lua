-- shared helpers: Plater's profile/mod string format (AceSerializer -> LibDeflate level 9 -> EncodeForPrint)
-- paths can be overridden with env vars; defaults match the build box
PLATER_DIR = os.getenv("PLATER_DIR") or "/workspace/platerbuild/plater"
LIBDEFLATE = os.getenv("LIBDEFLATE") or "/workspace/LibDeflate/LibDeflate.lua"
LUAC = os.getenv("LUAC") or "luac"
LibStub = nil
dofile(PLATER_DIR .. "/libs/LibStub/LibStub.lua")
strbyte, strchar, strsub, gsub, gmatch, format = string.byte, string.char, string.sub, string.gsub, string.gmatch, string.format
strmatch = string.match
tinsert, tconcat = table.insert, table.concat
dofile(PLATER_DIR .. "/libs/AceSerializer-3.0/AceSerializer-3.0.lua")
AceSer = LibStub("AceSerializer-3.0")
LD = dofile(LIBDEFLATE)
function decode(s)
  local c = assert(LD:DecodeForPrint(s), "DecodeForPrint failed")
  local d = assert(LD:DecompressDeflate(c), "Decompress failed")
  local ok, t = AceSer:Deserialize(d)
  assert(ok, "Deserialize failed: " .. tostring(t))
  return t
end
function encode(t)
  return LD:EncodeForPrint(LD:CompressDeflate(AceSer:Serialize(t), { level = 9 }))
end
function readf(p) local f = assert(io.open(p, "rb")); local s = f:read("*a"); f:close(); return s end
function writef(p, s) local f = assert(io.open(p, "wb")); f:write(s); f:close() end
function deepcopy(t) if type(t) ~= "table" then return t end local r = {} for k, v in pairs(t) do r[k] = deepcopy(v) end return r end
function deepeq(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end
  for k, v in pairs(a) do if not deepeq(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end
SPECS = {
  {key = "arms", file = "Arms Profile.txt",       name = "Schizzle's Warrior Arms",       specId = 71},
  {key = "fury", file = "Fury Profile.txt",       name = "Schizzle's Warrior Fury",       specId = 72},
  {key = "prot", file = "Protection Profile.txt", name = "Schizzle's Warrior Protection", specId = 73},
}
MOD_FILES = {"01_spec_switcher", "02_threat_mode", "03_pummel_ready", "04_execute", "05_threat_percent"}
