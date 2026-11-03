-- Historical (v5.5): Group Scale 0.8 and Group Alpha 0.8 on the top-level group, carried over from the Warrior aura's
-- v1.6 (class kit uniformity: the Monk simulator compares the group fields with the Warrior export).
-- Only t.d.scale and t.d.alpha change; children, triggers and positions are untouched. Run before `lua release.lua 5.5`.
-- Env: WA_LIBS, WA_EXPORT (see release.lua).
local HERE = (arg and arg[0] and arg[0]:match("^(.*)/[^/]*$")) or "."
local LIBDIR = os.getenv("WA_LIBS") or "/workspace"
local LS = dofile(LIBDIR .. "/LibSerialize/LibSerialize.lua")
local LD = dofile(LIBDIR .. "/LibDeflate/LibDeflate.lua")
local P = os.getenv("WA_EXPORT") or (HERE .. "/../All-in-One Rotation.txt")
local function decode(s) local ok, t = LS:Deserialize(LD:DecompressDeflate(LD:DecodeForPrint(s:gsub("%s+$", ""):match("^!WA:2!(.*)$")))) assert(ok) return t end
local f = assert(io.open(P)); local src = f:read("*a"); f:close()
local t = decode(src)
assert(t.d.uid == "SchizzleMonkGroup", "not the Monk group")
assert(not (t.d.scale == 0.8 and t.d.alpha == 0.8), "already applied")
t.d.scale, t.d.alpha = 0.8, 0.8
local out = "!WA:2!" .. LD:EncodeForPrint(LD:CompressDeflate(LS:Serialize(t), { level = 9 }))
local t2 = decode(out)
local diffs = {}
local function walk(a, b, path)
  if type(a) ~= "table" or type(b) ~= "table" then if a ~= b then diffs[#diffs + 1] = path end return end
  for k, v in pairs(a) do walk(v, b[k], path .. "." .. tostring(k)) end
  for k in pairs(b) do if a[k] == nil then diffs[#diffs + 1] = path .. "." .. tostring(k) end end
end
walk(t, t2, "t"); assert(#diffs == 0, "round trip: " .. table.concat(diffs, ","))
walk(decode(src), t2, "t")
for _, d in ipairs(diffs) do assert(d == "t.d.scale" or d == "t.d.alpha", "unexpected change: " .. d) end
local w = assert(io.open(P, "w")); w:write(out); w:close()
print("OK", "scale", t2.d.scale, "alpha", t2.d.alpha, #diffs .. " fields changed")
