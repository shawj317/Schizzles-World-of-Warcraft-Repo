-- Release edit for "Schizzle's Monk Rotation" (the export string is the source of truth; there is no full build script).
-- Usage: lua release.lua RELEASE        e.g. lua release.lua 5.3
-- Decodes ../All-in-One Rotation.txt, then:
--   * renames the group to "Schizzle's Monk Rotation v<RELEASE>" and ends the description with " v<RELEASE>.",
--     re-pointing every child's parent link (the group uid SchizzleMonkGroup and every child id/uid stay the same);
--   * sets every font to Fira Sans Condensed Medium (text_font on subtexts, font on text regions), the same
--     SharedMedia name the Warrior aura uses (it ships with WeakAuras). Sizes and outlines are left alone.
-- Re-encodes, checks the round trip, checks that only those fields changed, and writes the file.
-- Env: WA_LIBS = folder holding LibSerialize/ and LibDeflate/ (default /workspace); WA_EXPORT = file to edit.
local HERE = (arg and arg[0] and arg[0]:match("^(.*)/[^/]*$")) or "."
local LIBDIR = os.getenv("WA_LIBS") or "/workspace"
local LS = dofile(LIBDIR .. "/LibSerialize/LibSerialize.lua")
local LD = dofile(LIBDIR .. "/LibDeflate/LibDeflate.lua")
local P = os.getenv("WA_EXPORT") or (HERE .. "/../All-in-One Rotation.txt")
local REL = assert(arg[1] and arg[1]:match("^%d+%.%d+[%.%d]*$") and arg[1], "usage: lua release.lua RELEASE")
local FONT = "Fira Sans Condensed Medium"
local function decode(s) local ok, t = LS:Deserialize(LD:DecompressDeflate(LD:DecodeForPrint(s:gsub("%s+$", ""):match("^!WA:2!(.*)$")))) assert(ok) return t end
local f = assert(io.open(P)); local src = f:read("*a"); f:close()
local t = decode(src)
assert(t.d.uid == "SchizzleMonkGroup", "not the Monk group")
local NEW = "Schizzle's Monk Rotation v" .. REL
t.d.id = NEW
t.d.desc = t.d.desc:gsub(" v[%d%.]+%.$", "") .. " v" .. REL .. "."
local fonts = 0
for _, c in ipairs(t.c) do
  c.parent = NEW
  if c.regionType == "text" and c.font ~= FONT then c.font = FONT; fonts = fonts + 1 end
  for _, s in ipairs(c.subRegions or {}) do
    if s.type == "subtext" and s.text_font ~= FONT then s.text_font = FONT; fonts = fonts + 1 end
  end
end
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
local count = {}
for _, d in ipairs(diffs) do
  local kind = (d == "t.d.id" or d == "t.d.desc") and d
    or d:match("^t%.c%.%d+%.(parent)$")
    or d:match("^t%.c%.%d+%.subRegions%.%d+%.(text_font)$")
    or d:match("^t%.c%.%d+%.(font)$")
  assert(kind, "unexpected change: " .. d)
  count[kind] = (count[kind] or 0) + 1
end
for k, n in pairs(count) do print("changed", k, n) end
local w = assert(io.open(P, "w")); w:write(out); w:close()
print("OK", t2.d.id, #t2.c .. " children", #out .. " chars", fonts .. " font fields set", t2.d.desc)
