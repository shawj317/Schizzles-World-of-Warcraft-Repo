-- Offline test for "Schizzle's XP & Rep Tray": decodes the export exactly like WeakAuras' Transmission.lua, checks the
-- layout, compiles both triggers inside WeakAuras' real aura sandbox (AuraEnvironment.lua) and runs them against a
-- mocked WoW API. Needs a WeakAuras2 checkout with tests/helpers.lua + tests/wow_stubs.lua (run from that tests dir).
-- Optional WOW_UI_SOURCE: a Gethe/wow-ui-source checkout of the 5.5 client, to confirm every game API the tray calls exists.
local WA_TESTS = os.getenv("WA_TESTS") or "/workspace/wa2/tests"
local LIBDIR = os.getenv("WA_LIBS") or "/workspace"
local EXPORT = os.getenv("WA_EXPORT") or "/workspace/XP & Rep Tray.txt"
local UISRC = os.getenv("WOW_UI_SOURCE")
package.path = WA_TESTS .. "/?.lua;" .. package.path
local LibSerialize = dofile(LIBDIR .. "/LibSerialize/LibSerialize.lua")
local LibDeflate = dofile(LIBDIR .. "/LibDeflate/LibDeflate.lua")
local T = require("helpers")
local stubs = require("wow_stubs")
stubs.install()
_G.WeakAuras = stubs.newWeakAuras()
local WeakAuras = _G.WeakAuras
local Private, warnings = stubs.newPrivate()

local P, F = 0, 0
local function check(cond, msg) if cond then P = P + 1 else F = F + 1; print("FAIL " .. msg) end end

---------------- decode ----------------
local f = assert(io.open(EXPORT)) local str = f:read("*a") f:close()
local _, _, encVersion, encoded = str:find("^(!WA:%d+!)(.+)$")
assert(encVersion == "!WA:2!", "header")
local decompressed = assert(LibDeflate:DecompressDeflate(assert(LibDeflate:DecodeForPrint(encoded))))
local ok, t = LibSerialize:Deserialize(decompressed)
assert(ok and type(t) == "table" and t.m == "d" and t.d and t.c and t.v == 1421, "transmit shape")
local data = t.d
print(("decoded OK: group %q uid=%s, %d children"):format(data.id, data.uid, #t.c))
check(not decompressed:lower():find("peanut"), "no Peanut naming")
check(data.id == "Schizzle's XP & Rep Tray v1.0", "group name carries v1.0")
check((data.desc or ""):find("v1%.0%.$") ~= nil, "description ends with v1.0")
check(data.uid == "SchizzleXPRepTray" and data.regionType == "dynamicgroup", "standalone dynamic group, own uid")
local by = {}
for i, c in ipairs(t.c) do
  by[c.id] = c
  check(c.parent == data.id and data.controlledChildren[i] == c.id, "child listed under the group " .. c.id)
  check(c.regionType == "aurabar" and c.width == 500 and c.height == 10, "500 x 10 bar " .. c.id)
  check(not c.load.use_class and not c.load.use_spec and not c.load.use_class_and_spec and not c.load.use_level, "no class/spec/level load " .. c.id)
  for _, s in ipairs(c.subRegions) do
    if s.type == "subtext" then check(s.text_font == "Fira Sans Condensed Medium" and s.text_fontSize <= c.height, "kit font fits the bar " .. c.id) end
    if s.type == "subborder" then check(s.border_offset == 0 and s.border_size == 1, "border drawn inside the bar " .. c.id) end
  end
end
local XP, REP = by["Schizzle Tray XP"], by["Schizzle Tray Rep"]
check(t.c[1] == XP and t.c[2] == REP, "XP on top, Rep under it")
check(XP.overlays and #XP.overlays == 1 and XP.overlayclip == true, "rested overlay colour, clipped to the bar")

---------------- layout: replay WeakAuras' DOWN grower (DynamicGroup.lua) ----------------
check(data.grow == "DOWN" and data.align == "RIGHT" and data.space == 2 and data.sort == "none" and (data.stagger or 0) == 0, "grow down, right aligned, 2 px apart, list order")
check(data.selfPoint == "TOPRIGHT" and data.anchorPoint == "BOTTOMRIGHT" and data.anchorFrameType == "SCREEN", "group TOPRIGHT on the screen's BOTTOMRIGHT")
check(data.xOffset == -4 and data.yOffset == 26 and (data.scale or 1) == 1, "group at -4, +26, scale 1")
local function layout(visible)
  local y, boxes = 0, {}
  for _, c in ipairs(visible) do
    boxes[#boxes + 1] = { id = c.id, right = data.xOffset, left = data.xOffset - c.width, top = data.yOffset + y, bottom = data.yOffset + y - c.height }
    y = y - c.height - data.space
  end
  return boxes
end
local both = layout({ XP, REP })
check(both[1].top == 26 and both[1].bottom == 16 and both[2].top == 14 and both[2].bottom == 4, "XP 16..26, Rep 4..14 px up")
check(both[1].right == -4 and both[1].left == -504 and both[2].left == -504, "both bars span 4..504 px in from the right (500 wide)")
local H = both[1].top - both[2].bottom
check(H == 22, "tray height 22 px")
-- Details! windows (250 x 153 each, side by side) start at the tray's top edge: same width, no gap, no overlap
check(both[1].top == 4 + 22 and -4 - 2 * 250 == both[1].left, "Details! pair (500 wide, bottom 26 px up) sits exactly on the tray")
local solo = layout({ REP })
check(solo[1].top == 26, "XP hidden (level 90): Rep moves up to sit right under Details!")
solo = layout({ XP })
check(solo[1].top == 26 and solo[1].bottom == 16, "Rep hidden (no watched faction): XP stays under Details!")

---------------- mock game ----------------
local W = {}
_G.UnitLevel = function() return W.level end
_G.UnitXP = function() return W.xp end
_G.UnitXPMax = function() return W.xpMax end
_G.GetXPExhaustion = function() return W.rested end
_G.IsXPUserDisabled = function() return W.xpOff or false end
_G.GetMaxLevelForPlayerExpansion = function() return 90 end
_G.BreakUpLargeNumbers = function(n) local s = tostring(math.floor(n)) local r = s:reverse():gsub("(%d%d%d)", "%1,"):reverse() return (r:gsub("^,", "")) end
for i, l in ipairs({ "Hated", "Hostile", "Unfriendly", "Neutral", "Friendly", "Honored", "Revered", "Exalted" }) do _G["FACTION_STANDING_LABEL" .. i] = l end
_G.C_Reputation = { GetWatchedFactionData = function() return W.watch end }
_G.C_GossipInfo = { GetFriendshipReputation = function(id) return W.friend and W.friend[id] or { friendshipFactionID = 0 } end }

T.loadAddonFile("WeakAuras/AuraEnvironment.lua", "WeakAuras", Private)
local fns = {}
for _, c in ipairs(t.c) do
  local tr = c.triggers[1].trigger
  check(tr.type == "custom" and tr.custom_type == "stateupdate" and tr.check == "event", "event-driven custom trigger " .. c.id)
  fns[c.id] = assert(WeakAuras.LoadFunction("return " .. tr.custom, c.id), "tsu " .. c.id)
  assert(WeakAuras.LoadFunction("return function() return \n" .. tr.customVariables .. "\n end", c.id))()
end
check(XP.triggers[1].trigger.events:find("PLAYER_XP_UPDATE") and XP.triggers[1].trigger.events:find("UPDATE_EXHAUSTION") and XP.triggers[1].trigger.events:find("PLAYER_LEVEL_UP"), "XP events")
check(REP.triggers[1].trigger.events:find("UPDATE_FACTION"), "Rep events")
local states = { [XP.id] = {}, [REP.id] = {} }
local function run(c, event, ...)
  Private.ActivateAuraEnvironment(c.id, nil, nil, states[c.id])
  local r = fns[c.id](states[c.id], event, ...)
  Private.ActivateAuraEnvironment()
  return r, states[c.id][""]
end

-- XP mid level with rested
W.level, W.xp, W.xpMax, W.rested = 42, 12345, 50000, 17500
local r, s = run(XP, "STATUS")
check(r and s.show and s.value == 12345 and s.total == 50000 and s.progressType == "static", "XP mid level shows current / max")
check(s.additionalProgress[1].direction == "forward" and s.additionalProgress[1].width == 17500, "rested overlay starts at the fill")
check(s.lefttext == "Level 42   Rested 35%" and s.righttext == "12,345 / 50,000   24.7%", "XP text: " .. tostring(s.lefttext) .. " | " .. tostring(s.righttext))
check(run(XP, "PLAYER_XP_UPDATE") == false, "no redraw when nothing changed")
W.rested = nil
r, s = run(XP, "UPDATE_EXHAUSTION")
check(r and s.lefttext == "Level 42" and s.additionalProgress[1].width == 0, "no rested: plain level, empty overlay")
W.level, W.xp = 89, 0
r, s = run(XP, "PLAYER_LEVEL_UP", 89)
check(s.show and s.lefttext == "Level 89", "level 89 still shows XP")
W.level = 89
r, s = run(XP, "PLAYER_LEVEL_UP", 90)
check(r and not s.show, "reaching 90 hides the XP bar (event carries the new level)")
W.level = 90
r, s = run(XP, "PLAYER_ENTERING_WORLD")
check(not s.show, "level 90 keeps XP hidden")
W.level, W.xpOff = 50, true
r, s = run(XP, "STATUS")
check(s.show == false or s.show == nil, "XP gain switched off hides the bar")
W.xpOff = false

-- reputation
W.watch = nil
r, s = run(REP, "STATUS")
check(not (s and s.show), "no watched faction: Rep hidden")
W.watch = { factionID = 1270, name = "Shado-Pan", reaction = 6, currentReactionThreshold = 9000, nextReactionThreshold = 21000, currentStanding = 12000 }
r, s = run(REP, "UPDATE_FACTION")
check(r and s.show and s.value == 3000 and s.total == 12000 and s.tier == 6, "watched faction progress inside the standing")
check(s.lefttext == "Shado-Pan   Honored" and s.righttext == "3,000 / 12,000   25.0%", "Rep text: " .. tostring(s.lefttext) .. " | " .. tostring(s.righttext))
W.watch = { factionID = 1341, name = "The August Celestials", reaction = 8, currentReactionThreshold = 42000, nextReactionThreshold = 42999, currentStanding = 42999 }
r, s = run(REP, "UPDATE_FACTION")
check(s.tier == 8 and s.value == 999 and s.total == 999, "Exalted shows a full bar")
W.watch = { factionID = 1273, name = "Jogu the Drunk", reaction = 5, currentReactionThreshold = 0, nextReactionThreshold = 0, currentStanding = 9000 }
W.friend = { [1273] = { friendshipFactionID = 1273, reaction = "Buddy", standing = 9000, reactionThreshold = 8400, nextThreshold = 16800 } }
r, s = run(REP, "UPDATE_FACTION")
check(s.show and s.lefttext == "Jogu the Drunk   Buddy" and s.value == 600 and s.total == 8400 and s.tier == 5, "friendship rank and progress")
W.friend[1273] = { friendshipFactionID = 1273, reaction = "Best Friend", standing = 42999, reactionThreshold = 42000 }
r, s = run(REP, "UPDATE_FACTION")
check(s.righttext == "Best Friend" and s.value == 1 and s.total == 1, "max friendship rank: full bar, rank name")
W.friend = nil
W.watch = { factionID = 0, name = "", reaction = 4 }
r, s = run(REP, "UPDATE_FACTION")
check(r and not s.show, "unwatching hides Rep again")
-- older clients: GetWatchedFactionInfo fallback
local keep = _G.C_Reputation
_G.C_Reputation = nil
_G.GetWatchedFactionInfo = function() return "Golden Lotus", 3, -3000, 0, -1500, 1269 end
r, s = run(REP, "UPDATE_FACTION")
check(s.show and s.lefttext == "Golden Lotus   Unfriendly" and s.value == 1500 and s.total == 3000 and s.tier == 3, "GetWatchedFactionInfo fallback")
_G.C_Reputation = keep
-- one colour condition per standing, each a real bar colour change
check(#REP.conditions == 8, "8 standing colours")
for i, c in ipairs(REP.conditions) do
  check(c.check.variable == "tier" and c.check.op == "==" and tonumber(c.check.value) == i and c.changes[1].property == "barColor" and #c.changes[1].value == 4, "standing colour " .. i)
end

---------------- every game API the tray calls exists in the 5.5 client ----------------
if UISRC then
  local function grep(pat, path) local p = io.popen("grep -rqs -- '" .. pat .. "' '" .. UISRC .. "/" .. path .. "' && echo y") local o = p:read("*a") p:close() return o:find("y") ~= nil end
  local doc = "Interface/AddOns/Blizzard_APIDocumentationGenerated"
  for _, api in ipairs({ "GetWatchedFactionData", "GetFriendshipReputation", "GetMaxLevelForPlayerExpansion", "IsXPUserDisabled" }) do
    check(grep('Name = "' .. api .. '"', doc), "5.5 API documented: " .. api)
  end
  for _, api in ipairs({ "UnitXP(\"player\")", "UnitXPMax(\"player\")", "GetXPExhaustion()", "BreakUpLargeNumbers(" }) do
    check(grep(api, "Interface/AddOns"), "used by the 5.5 FrameXML: " .. api)
  end
  -- FACTION_STANDING_LABEL1..8 are GlobalStrings, which the source dump doesn't carry; WeakAuras' own list of
  -- client globals (.luacheckrc) has them, and the trigger falls back to English labels if one is ever missing.
  local rc = io.open(WA_TESTS .. "/../.luacheckrc")
  if rc then local body = rc:read("*a") rc:close() check(body:find('"FACTION_STANDING_LABEL8"', 1, true) ~= nil, "FACTION_STANDING_LABELn are known client globals") end
end

do local n = 0 for _, w in ipairs(warnings) do if w.key == "SandboxForbidden" then n = n + 1 end end
  check(n == 0, "no WeakAuras sandbox violations (" .. n .. ")") end
print(("\n%d passed, %d failed; sandbox warnings: %d"):format(P, F, #warnings))
for _, w in ipairs(warnings) do print("  warning", w.key, w.message) end
if F > 0 then os.exit(1) end
