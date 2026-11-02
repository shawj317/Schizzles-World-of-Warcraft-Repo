-- Dumps the custom code from ../All-in-One Rotation.txt for reading or review: the engine (SMR Next -> On Init)
-- and every child's trigger function, into ./extracted/ (not committed). The export string stays the source of truth.
local HERE = (arg and arg[0] and arg[0]:match("^(.*)/[^/]*$")) or "."
local LIBDIR = os.getenv("WA_LIBS") or "/workspace"
local LS = dofile(LIBDIR .. "/LibSerialize/LibSerialize.lua")
local LD = dofile(LIBDIR .. "/LibDeflate/LibDeflate.lua")
local P = os.getenv("WA_EXPORT") or (HERE .. "/../All-in-One Rotation.txt")
local f = assert(io.open(P)); local s = f:read("*a"); f:close()
local ok, t = LS:Deserialize(LD:DecompressDeflate(LD:DecodeForPrint(s:gsub("%s+$", ""):match("^!WA:2!(.*)$")))) assert(ok)
local dir = HERE .. "/extracted"
os.execute('mkdir -p "' .. dir .. '"')
local function put(name, body) local w = assert(io.open(dir .. "/" .. name, "w")) w:write(body) w:close() print("wrote", name) end
put("engine.lua", t.c[1].actions.init.custom)
for _, c in ipairs(t.c) do local tr = c.triggers[1].trigger if tr.custom then put(c.uid .. "_trigger.lua", tr.custom) end end
