-- Historical (v5.2): usage: lua tray.lua RELEASE (already applied; it refuses to run twice) : adds the ready-only cooldown tray (engine code, option, 8 SMR Tray icons),
-- renames the group to "Schizzle's Monk Rotation v<RELEASE>", re-encodes, verifies round trip and that old children are unchanged.
local HERE = (arg and arg[0] and arg[0]:match("^(.*)/[^/]*$")) or "."
local LIBDIR = os.getenv("WA_LIBS") or "/workspace"
local LS = dofile(LIBDIR .. "/LibSerialize/LibSerialize.lua")
local LD = dofile(LIBDIR .. "/LibDeflate/LibDeflate.lua")
local P, REL = os.getenv("WA_EXPORT") or (HERE .. "/../All-in-One Rotation.txt"), assert(arg[1], "usage: lua tray.lua RELEASE")
local function decode(s) local ok, t = LS:Deserialize(LD:DecompressDeflate(LD:DecodeForPrint(s:gsub("%s+$", ""):match("^!WA:2!(.*)$")))) assert(ok) return t end
local function copy(v) if type(v) ~= "table" then return v end local o = {} for k, x in pairs(v) do o[k] = copy(x) end return o end
local function rep(s, a, b) local i, j = s:find(a, 1, true) assert(i, "missing: " .. a) assert(not s:find(a, j + 1, true), "twice: " .. a) return s:sub(1, i - 1) .. b .. s:sub(j + 1) end
local f = assert(io.open(P)); local src = f:read("*a"); f:close()
local t = decode(src); local OLD = t.d.id; local NEW = "Schizzle's Monk Rotation v" .. REL
local n0 = #t.c
assert(t.c[1].id == "SMR Next")
for _, c in ipairs(t.c) do assert(not c.id:find("Tray"), "tray already present") end

-- 1. engine
local eng = t.c[1].actions.init.custom
eng = rep(eng, "local VERSION = 5\n", "local VERSION = 6\n")
eng = rep(eng, "enbrew=115288, shs=116705, tok=122470, bmtrain=117967,\n",
  "enbrew=115288, shs=116705, tok=122470, bmtrain=117967,\n  zen=115176, avert=115213, nimble=137562, ring=116844,\n")
local TRAY = [==[
-- v6: cooldown tray. Small ready-only row at the bottom right: racials and big cooldowns the rotation doesn't call for.
-- Shown only when known and off cooldown (GCD ignored). Racials first, then the spec list, packed from slot 1 (right edge), max 8.
-- Anything Next / Next+1 / Interrupt / Defensive / Cooldown already shows is left out at that moment.
local TRAY_SLOTS = 8
local RACIALS = { 20572, 33697, 33702, 26297, 59752, 20594, 7744, 20577, 20549,
  69179, 129597, 28730, 25046, 50613, 80483, 28880, 121093, 59542, 59543, 59544, 59545, 59547, 59548,
  20589, 58984, 68992, 69041, 69070, 107079 }
local TRAY = {
  [1] = { ID.fort, ID.dampen, ID.diffuse, ID.zen, ID.avert, ID.xuen, ID.nimble, ID.legsweep, ID.ring, ID.oxwave, ID.tlust },
  [3] = { ID.tok, ID.fort, ID.enbrew, ID.xuen, ID.dampen, ID.diffuse, ID.zen, ID.nimble, ID.legsweep, ID.ring, ID.oxwave, ID.tlust },
}
E.TRAY, E.RACIALS, E.TRAY_SLOTS = TRAY, RACIALS, TRAY_SLOTS
local function tray(S, R)
  local out = {}
  if E.cfg.showTray == false then return out end
  local shown = {}
  for _, e in ipairs({ R.next, R.next2, R.int }) do if e then shown[e.id] = true end end
  for _, l in ipairs({ R.left or {}, R.right or {} }) do for _, e in ipairs(l) do shown[e.id] = true end end
  local function add(id)
    if #out >= TRAY_SLOTS or shown[id] or not known(id) or cd(id, S.now) > 0 then return end
    shown[id] = true
    local e = entry({ id = id }, S, true)
    e.waiting, e.wait, e.glow, e.tag, e.start, e.duration = false, false, false, "", 0, 0
    out[#out + 1] = e
  end
  for _, id in ipairs(RACIALS) do add(id) end
  for _, id in ipairs(TRAY[S.spec] or {}) do add(id) end
  return out
end
E.tray = tray

-- one evaluation per 0.1 s shared by every aura
]==]
eng = rep(eng, "-- one evaluation per 0.1 s shared by every aura\n", TRAY)
eng = rep(eng, "  for i, e in ipairs(right) do R.right[i] = entry(e, S, true) end\n",
  "  for i, e in ipairs(right) do R.right[i] = entry(e, S, true) end\n  R.tray = tray(S, R)\n")
assert(loadstring(eng), "engine compile")
t.c[1].actions.init.custom = eng

-- 2. author option (after "Show offensive cooldowns (right)") + default config
local ao = t.c[1].authorOptions
local pos; for i, o in ipairs(ao) do if o.key == "showCDs" then pos = i + 1 end end
local opt = copy(ao[pos - 1]); opt.key, opt.name, opt.default = "showTray", "Show cooldown tray", true
opt.useDesc, opt.desc = true, "Small icons at the bottom right for racials and big cooldowns outside the rotation, shown only when known and off cooldown."
table.insert(ao, pos, opt)
t.c[1].config.showTray = true

-- 3. eight tray icons, copied from SMR Cooldown 1
local base; for _, c in ipairs(t.c) do if c.id == "SMR Cooldown 1" then base = c end end
assert(base.triggers[1].trigger.custom:find("R.right[1]", 1, true))
for i = 1, 8 do
  local c = copy(base)
  c.id, c.uid = "SMR Tray " .. i, "SMRTray" .. i
  c.width, c.height, c.xOffset, c.yOffset = 32, 32, 150 - 16 - 36 * (i - 1), -122
  c.cooldownTextDisabled = true
  c.triggers[1].trigger.custom = rep(c.triggers[1].trigger.custom, "R.show and R.right and R.right[1]", "R.show and R.tray and R.tray[" .. i .. "]")
  assert(loadstring("return " .. c.triggers[1].trigger.custom), "trigger compile")
  for _, s in ipairs(c.subRegions) do
    if s.type == "subtext" then s.text_font = "Fira Sans Condensed Medium"; s.text_fontSize = math.max(8, (s.text_fontSize or 12) - 2) end
  end
  c.subRegions[#c.subRegions + 1] = { type = "subborder", border_visible = true, border_edge = "Square Full White",
    border_color = { 0, 0, 0, 0.8 }, border_offset = 0, border_size = 1, anchor_area = "bar" }
  t.c[#t.c + 1] = c
  t.d.controlledChildren[#t.d.controlledChildren + 1] = c.id
end

-- 4. group name / description / parent links
t.d.id = NEW
t.d.desc = t.d.desc:gsub(" v[%d%.]+%.$", "") .. " v" .. REL .. "."
for _, c in ipairs(t.c) do c.parent = NEW end

local out = "!WA:2!" .. LD:EncodeForPrint(LD:CompressDeflate(LS:Serialize(t), { level = 9 }))
local t2 = decode(out)
local diffs = {}
local function walk(a, b, path)
  if type(a) ~= "table" or type(b) ~= "table" then if a ~= b then diffs[#diffs + 1] = path end return end
  for k, v in pairs(a) do walk(v, b[k], path .. "." .. tostring(k)) end
  for k in pairs(b) do if a[k] == nil then diffs[#diffs + 1] = path .. "." .. tostring(k) end end
end
walk(t, t2, "t"); assert(#diffs == 0, "round trip: " .. table.concat(diffs, ","))
diffs = {}
local old = decode(src)
for i = 1, n0 do walk(old.c[i], t2.c[i], "c." .. i) end
local other = {}
for _, d in ipairs(diffs) do if not d:match("^c%.%d+%.parent$") then other[#other + 1] = d end end
print("old-children changes:", table.concat(other, ", "))
for i = 1, n0 do assert(old.c[i].uid == t2.c[i].uid and old.c[i].id == t2.c[i].id) end
assert(t2.d.uid == "SchizzleMonkGroup" and t2.d.xOffset == 0 and t2.d.yOffset == -40)
local w = assert(io.open(P, "w")); w:write(out); w:close()
print("OK", t2.d.id, #t2.c, "children", #out, "chars", t2.d.desc)
