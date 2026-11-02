-- Historical (v5.4): aligns the Monk aura's shared elements with the Warrior aura's style. Cosmetic / structural only:
-- no trigger, engine or condition code changes. Run before `lua release.lua 5.4`; it refuses to run twice.
--   * cooldown tray: keybind 12 pt (was 10), no tag text (the tray never sets a tag), border exactly as the Warrior tray;
--   * Shuffle and Stagger bars: the Warrior bars' 1 px black border (subRegions slot 3, like SWR Shield Block / Rage);
--   * load: drop the inactive spec filter left from v1 (use_class_and_spec = false + class_and_spec 268/269),
--     so group and children load on class only, exactly like the Warrior;
--   * Custom Options: Warrior order (class settings first, then the Show… toggles, then interrupts), the Warrior
--     label "Show defensives / stance (left)" and the Warrior wording for the tray option;
--   * group description in the Warrior's form.
-- Env: WA_LIBS, WA_EXPORT (see release.lua).
local HERE = (arg and arg[0] and arg[0]:match("^(.*)/[^/]*$")) or "."
local LIBDIR = os.getenv("WA_LIBS") or "/workspace"
local LS = dofile(LIBDIR .. "/LibSerialize/LibSerialize.lua")
local LD = dofile(LIBDIR .. "/LibDeflate/LibDeflate.lua")
local P = os.getenv("WA_EXPORT") or (HERE .. "/../All-in-One Rotation.txt")
local function decode(s) local ok, t = LS:Deserialize(LD:DecompressDeflate(LD:DecodeForPrint(s:gsub("%s+$", ""):match("^!WA:2!(.*)$")))) assert(ok) return t end
local f = assert(io.open(P)); local src = f:read("*a"); f:close()
local t = decode(src)
assert(t.d.uid == "SchizzleMonkGroup")
local by = {} for _, c in ipairs(t.c) do by[c.id] = c end
assert(#by["SMR Shuffle"].subRegions == 4, "already uniform")

local function barBorder() return { type = "subborder", border_visible = true, border_edge = "Square Full White",
  border_color = { 0, 0, 0, 1 }, border_offset = 1, border_size = 1, anchor_area = "bar" } end
-- tray
for i = 1, 8 do
  local c = by["SMR Tray " .. i]
  local s = c.subRegions
  assert(s[3].type == "subtext" and s[3].text_text == "%keybind" and s[4].text_text == "%tag" and s[5].type == "subborder")
  s[3].text_fontSize = 12
  table.remove(s, 4)
  s[4].anchor_area = nil
  for _, cd in ipairs(c.conditions) do for _, ch in ipairs(cd.changes) do assert(not tostring(ch.property):find("^sub%.[45]")) end end
end
-- bars
for _, id in ipairs({ "SMR Shuffle", "SMR Stagger" }) do
  local c = by[id]
  assert(c.subRegions[1].type == "subbackground" and c.subRegions[2].type == "subforeground" and c.subRegions[3].type == "subtext")
  for _, cd in ipairs(c.conditions or {}) do for _, ch in ipairs(cd.changes) do assert(not tostring(ch.property):find("^sub%.")) end end
  table.insert(c.subRegions, 3, barBorder())
end
-- load
for _, d in ipairs({ t.d, unpack(t.c) }) do
  assert(d.load.use_class_and_spec ~= true, "spec filter active on " .. d.id)
  d.load.use_class_and_spec, d.load.class_and_spec = nil, nil
end
-- options
local ao, byKey = t.c[1].authorOptions, {}
for _, o in ipairs(ao) do byKey[o.key] = o end
byKey.showDef.name = "Show defensives / stance (left)"
byKey.showTray.desc = "Small icons under the HUD (bottom right, filling leftward) for racials and big cooldowns that are learned and off cooldown. They hide while on cooldown, and never repeat a spell the rotation is already showing."
local ORDER = { "aoe", "bmMode", "tpWindow", "ebStacks", "tebStacks", "showDef", "showCDs", "showKeys", "tintOOR", "showTray",
  "showInt", "intCC", "intMain", "intFocus" }
assert(#ORDER == #ao)
for i, k in ipairs(ORDER) do ao[i] = assert(byKey[k], k) end
-- description (release.lua adds the " vX.Y." suffix)
t.d.desc = "Schizzle's Monk Rotation: all-in-one Brewmaster (Tank / DPS) / Windwalker rotation helper for MoP Classic. Switches with your spec automatically, with Chi pips, Stagger and Shuffle bars and a GCD swipe. " .. t.d.desc:match("v[%d%.]+%.$")

local out = "!WA:2!" .. LD:EncodeForPrint(LD:CompressDeflate(LS:Serialize(t), { level = 9 }))
local t2 = decode(out)
local diffs = {}
local function walk(a, b, path)
  if type(a) ~= "table" or type(b) ~= "table" then if a ~= b then diffs[#diffs + 1] = path end return end
  for k, v in pairs(a) do walk(v, b[k], path .. "." .. tostring(k)) end
  for k in pairs(b) do if a[k] == nil then diffs[#diffs + 1] = path .. "." .. tostring(k) end end
end
walk(t, t2, "t"); assert(#diffs == 0, "round trip: " .. table.concat(diffs, ","))
-- nothing outside the intended areas changed
local old = decode(src)
for i, c in ipairs(t2.c) do
  local o = old.c[i]
  assert(o.uid == c.uid and o.id == c.id)
  for _, k in ipairs({ "triggers", "actions", "conditions", "width", "height", "xOffset", "yOffset", "config" }) do
    diffs = {} walk(o[k], c[k], k) assert(#diffs == 0, c.id .. " changed " .. table.concat(diffs, ","))
  end
end
local w = assert(io.open(P, "w")); w:write(out); w:close()
print("OK", #out .. " chars")
