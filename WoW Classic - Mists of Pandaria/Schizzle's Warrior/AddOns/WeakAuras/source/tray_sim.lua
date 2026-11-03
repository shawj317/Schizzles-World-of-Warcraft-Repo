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
check(data.id == "Schizzle's XP & Rep Tray v1.3", "group name carries v1.3")
check((data.desc or ""):find("v1%.3%.$") ~= nil, "description ends with v1.3")
check(#t.c == 3, "three bars")
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
local XP, REP, GUILD = by["Schizzle Tray XP"], by["Schizzle Tray Rep"], by["Schizzle Tray Guild"]
check(t.c[1] == XP and t.c[2] == REP and t.c[3] == GUILD, "XP on top, watched Rep under it, Guild at the bottom")
check(XP.overlays and #XP.overlays == 2 and XP.overlayclip == true, "two overlay colours, clipped to the bar end")
local function isBlue(c) return c[3] > c[1] and c[3] > c[2] end
local function isGreen(c) return c[2] > c[1] and c[2] > c[3] end
local function isPurple(c) return c[1] > c[2] and c[3] > c[2] end
check(isBlue(XP.barColor) and XP.barColor[4] == 1, "earned XP fill is blue")
check(isGreen(XP.overlays[1]), "overlay 1 (completed quests) is green")
check(isPurple(XP.overlays[2]), "overlay 2 (rested) is purple")
-- draw order (AuraBar.lua): the blue fill is ARTWORK sublevel 0 and overlay n is ARTWORK sublevel min(n, 7) on the same
-- bar frame, so green (1) draws over blue and purple (2) over green
check(XP.overlayclip and #XP.overlays == 2, "green is overlay 1 (above the fill), purple overlay 2 (above green)")

---------------- layout: replay WeakAuras' DOWN grower (DynamicGroup.lua) ----------------
check(data.grow == "DOWN" and data.align == "RIGHT" and data.space == 2 and data.sort == "none" and (data.stagger or 0) == 0, "grow down, right aligned, 2 px apart, list order")
check(data.selfPoint == "TOPRIGHT" and data.anchorPoint == "BOTTOMRIGHT" and data.anchorFrameType == "SCREEN", "group TOPRIGHT on the screen's BOTTOMRIGHT")
check(data.xOffset == -4 and data.yOffset == 38 and (data.scale or 1) == 1, "group at -4, +38, scale 1")
local function layout(visible)
  local y, boxes = 0, {}
  for _, c in ipairs(visible) do
    boxes[#boxes + 1] = { id = c.id, right = data.xOffset, left = data.xOffset - c.width, top = data.yOffset + y, bottom = data.yOffset + y - c.height }
    y = y - c.height - data.space
  end
  return boxes
end
local all = layout({ XP, REP, GUILD })
check(all[1].top == 38 and all[1].bottom == 28 and all[2].top == 26 and all[2].bottom == 16 and all[3].top == 14 and all[3].bottom == 4, "XP 28..38, Rep 16..26, Guild 4..14 px up")
check(all[1].right == -4 and all[1].left == -504 and all[2].left == -504 and all[3].left == -504, "all bars span 4..504 px in from the right (500 wide)")
local H = all[1].top - all[3].bottom
check(H == 34, "tray height 34 px (3 x 10 + 2 x 2)")
-- Details! windows (250 x 141 each, side by side) start at the tray's top edge: same width, no gap, no overlap
check(all[1].top == 4 + 34 and -4 - 2 * 250 == all[1].left, "Details! pair (500 wide, bottom 38 px up) sits exactly on the tray")
check(38 + 141 + 20 == 199, "Details! title bars still top out 199 px up")
local solo = layout({ REP, GUILD })
check(solo[1].top == 38 and solo[2].top == 26, "XP hidden (level 90): Rep and Guild move up, no hole under Details!")
solo = layout({ XP, GUILD })
check(solo[1].top == 38 and solo[2].top == 26, "Rep hidden: Guild moves up under XP")
solo = layout({ XP, REP })
check(solo[1].top == 38 and solo[2].bottom == 16, "Guild hidden (no guild): XP and Rep stay under Details!, strip at the bottom empty")
solo = layout({ GUILD })
check(solo[1].top == 38, "only Guild: it sits right under Details!")

---------------- mock game ----------------
local W = {}
_G.UnitLevel = function() return W.level end
_G.UnitXP = function() return W.xp end
_G.UnitXPMax = function() return W.xpMax end
_G.GetXPExhaustion = function() return W.rested end
_G.IsXPUserDisabled = function() return W.xpOff or false end
_G.GetMaxLevelForPlayerExpansion = function() return 90 end
-- quest log, MoP-style: title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID.
-- GetQuestLogRewardXP behaves like the 5.5 client's quest panel uses it (Wrath/QuestInfo.lua, loaded for mists):
-- it reads the *selected* quest-log entry and ignores any argument. (The v1.1 mock looked the questID up, which is
-- why the v1.1 sim passed while the green overlay stayed empty in game.)
W.log, W.sel, W.selects = {}, 0, 0
_G.GetNumQuestLogEntries = function() return #W.log, #W.log end
_G.GetQuestLogTitle = function(i) local q = W.log[i] if not q then return nil end
  return q.title, 40, 0, q.header or false, false, q.complete, 0, q.id end
_G.GetQuestLogSelection = function() return W.sel end
_G.SelectQuestLogEntry = function(i) W.sel = i W.selects = W.selects + 1 end
_G.GetQuestLogRewardXP = function() local q = W.log[W.sel] return q and not q.header and q.xp or 0 end
_G.BreakUpLargeNumbers = function(n) local s = tostring(math.floor(n)) local r = s:reverse():gsub("(%d%d%d)", "%1,"):reverse() return (r:gsub("^,", "")) end
for i, l in ipairs({ "Hated", "Hostile", "Unfriendly", "Neutral", "Friendly", "Honored", "Revered", "Exalted" }) do _G["FACTION_STANDING_LABEL" .. i] = l end
_G.C_Reputation = { GetWatchedFactionData = function() return W.watch end, GetGuildFactionData = function() return W.guildFaction end }
_G.IsInGuild = function() return W.guildName ~= nil end
_G.GetGuildInfo = function() return W.guildName, "Member", 3 end
_G.C_GuildInfo = { IsGuildReputationEnabled = function() return not W.guildRepOff end }
_G.C_GossipInfo = { GetFriendshipReputation = function(id) return W.friend and W.friend[id] or { friendshipFactionID = 0 } end }

T.loadAddonFile("WeakAuras/AuraEnvironment.lua", "WeakAuras", Private)
local fns = {}
for _, c in ipairs(t.c) do
  local tr = c.triggers[1].trigger
  check(tr.type == "custom" and tr.custom_type == "stateupdate" and tr.check == "event", "event-driven custom trigger " .. c.id)
  fns[c.id] = assert(WeakAuras.LoadFunction("return " .. tr.custom, c.id), "tsu " .. c.id)
  assert(WeakAuras.LoadFunction("return function() return \n" .. tr.customVariables .. "\n end", c.id))()
end
do local ev = " " .. XP.triggers[1].trigger.events .. " "
  check(ev:find(" QUEST_LOG_UPDATE ", 1, true) and ev:find(" UNIT_QUEST_LOG_CHANGED:player ", 1, true) and ev:find(" QUEST_TURNED_IN ", 1, true), "quest log events (unit event carries :player, or WeakAuras registers nothing)")
  check(not ev:find(" UNIT_QUEST_LOG_CHANGED ", 1, true), "no bare UNIT_ event") end
check(XP.triggers[1].trigger.events:find("PLAYER_XP_UPDATE") and XP.triggers[1].trigger.events:find("UPDATE_EXHAUSTION") and XP.triggers[1].trigger.events:find("PLAYER_LEVEL_UP"), "XP events")
check(REP.triggers[1].trigger.events:find("UPDATE_FACTION"), "Rep events")
local states = { [XP.id] = {}, [REP.id] = {}, [GUILD.id] = {} }
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
check(s.additionalProgress[1].direction == "forward" and s.additionalProgress[1].width == 0, "no completed quests: empty green overlay")
check(s.additionalProgress[2].direction == "forward" and (s.additionalProgress[2].offset or 0) == 0 and s.additionalProgress[2].width == 17500, "rested overlay starts at the fill")
check(s.lefttext == "Level 42   Rested 35%" and s.righttext == "12,345 / 50,000   24.7%", "XP text: " .. tostring(s.lefttext) .. " | " .. tostring(s.righttext))
local function tipText(st) local o = { st.tipTitle } for _, l in ipairs(st.tip or {}) do o[#o + 1] = l[1] .. " = " .. l[2] end return table.concat(o, " | ") end
check(tipText(s) == "Level 42 | Experience = 12,345 / 50,000  (24.7%) | To level 43 = 37,655  (75.3%) | Rested = 17,500  (35.0% of the level)", "XP tooltip: " .. tipText(s))
-- completed-but-not-turned-in quests: only complete (1) quest entries count; headers, unfinished and failed (-1) don't
W.log = { { title = "Kun-Lai Summit", header = true, id = 0 },
  { title = "Done A", complete = 1, id = 101, xp = 2400 }, { title = "Not done", complete = nil, id = 102, xp = 9000 },
  { title = "Failed", complete = -1, id = 103, xp = 5000 }, { title = "Done B", complete = 1, id = 104, xp = 1100 } }
r, s = run(XP, "QUEST_LOG_UPDATE")
check(r and s.quest == 3500, "pending quest XP = sum of completed quests (" .. tostring(s.quest) .. ")")
check(s.nq == 2, "two completed quests counted")
check(W.sel == 0, "player's quest-log selection put back (none)")
local g, p = s.additionalProgress[1], s.additionalProgress[2]
check(g.direction == "forward" and (g.offset or 0) == 0 and g.width == 3500, "green overlay right after the blue fill")
check(p.direction == "forward" and p.offset == 3500 and p.width == 17500, "purple rested overlay after the green one")
check(s.righttext == "12,345 / 50,000   24.7%   +3,500 quest", "right text adds the pending quest XP: " .. tostring(s.righttext))
check(tipText(s):find("Completed quests = +3,500  (2 quests) | After turn-ins = 15,845 / 50,000  (31.7%)", 1, true) ~= nil, "XP tooltip lists pending quest XP: " .. tipText(s))
W.xp = 48000
r, s = run(XP, "QUEST_LOG_UPDATE")
check(tipText(s):find("After turn-ins = level 43 +1,500", 1, true) ~= nil, "turn-ins that level you up: " .. tipText(s))
W.xp = 12345
-- the bug: with a different quest selected in the log, the v1.1 read returned that quest's XP for every entry (or 0)
W.sel = 3
W.log[2].complete = 1
r, s = run(XP, "QUEST_LOG_UPDATE")
check(s.quest == 3500 and W.sel == 3, "another quest selected: still the right sum, selection restored to it")
W.sel = 0
W.log[2].complete = nil
r, s = run(XP, "UNIT_QUEST_LOG_CHANGED", "player")
check(r and s.quest == 1100 and s.additionalProgress[2].offset == 1100, "quest log change updates the green overlay")
W.log = {}
r, s = run(XP, "QUEST_TURNED_IN", 104, 1100, 0)
check(r and s.quest == 0 and s.righttext == "12,345 / 50,000   24.7%", "turned in: green overlay gone")
local keepX = _G.GetQuestLogRewardXP
_G.GetQuestLogRewardXP = nil
W.log = { { title = "Done A", complete = 1, id = 101, xp = 2400 } }
r, s = run(XP, "QUEST_LOG_UPDATE")
check(s.show and s.quest == 0, "missing quest API: XP bar still works, no green overlay")
_G.GetQuestLogRewardXP = keepX
-- client without the selection API: falls back to the questID form
local keepS, keepG = _G.SelectQuestLogEntry, _G.GetQuestLogSelection
_G.SelectQuestLogEntry, _G.GetQuestLogSelection = nil, nil
_G.GetQuestLogRewardXP = function(id) for _, q in ipairs(W.log) do if q.id == id then return q.xp end end return 0 end
r, s = run(XP, "QUEST_LOG_UPDATE")
check(s.quest == 2400, "no SelectQuestLogEntry: questID form used")
_G.SelectQuestLogEntry, _G.GetQuestLogSelection, _G.GetQuestLogRewardXP = keepS, keepG, keepX
-- nothing completed: no selection churn
W.log = { { title = "Not done", complete = nil, id = 102, xp = 9000 } }
W.selects = 0
r, s = run(XP, "QUEST_LOG_UPDATE")
check(s.quest == 0 and W.selects == 0, "no completed quests: quest-log selection never touched")
W.log = {}
r, s = run(XP, "QUEST_LOG_UPDATE")
check(run(XP, "PLAYER_XP_UPDATE") == false, "no redraw when nothing changed")
W.rested = nil
r, s = run(XP, "UPDATE_EXHAUSTION")
check(r and s.lefttext == "Level 42" and s.additionalProgress[2].width == 0, "no rested: plain level, empty overlay")
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
check(tipText(s) == "Shado-Pan | Standing = Honored | Progress = 3,000 / 12,000  (25.0%) | To Revered = 9,000  (75.0%)", "Rep tooltip: " .. tipText(s))
W.watch = { factionID = 1341, name = "The August Celestials", reaction = 8, currentReactionThreshold = 42000, nextReactionThreshold = 42999, currentStanding = 42999 }
r, s = run(REP, "UPDATE_FACTION")
check(s.tier == 8 and s.value == 999 and s.total == 999, "Exalted shows a full bar")
check(tipText(s):find("Progress = 999 / 999", 1, true) and tipText(s):find("To next standing = 0", 1, true), "Exalted tooltip: " .. tipText(s))
W.watch = { factionID = 1273, name = "Jogu the Drunk", reaction = 5, currentReactionThreshold = 0, nextReactionThreshold = 0, currentStanding = 9000 }
W.friend = { [1273] = { friendshipFactionID = 1273, reaction = "Buddy", standing = 9000, reactionThreshold = 8400, nextThreshold = 16800 } }
r, s = run(REP, "UPDATE_FACTION")
check(s.show and s.lefttext == "Jogu the Drunk   Buddy" and s.value == 600 and s.total == 8400 and s.tier == 5, "friendship rank and progress")
check(tipText(s) == "Jogu the Drunk | Friendship rank = Buddy | Progress = 600 / 8,400  (7.1%) | To next rank = 7,800  (92.9%)", "friendship tooltip: " .. tipText(s))
W.friend[1273] = { friendshipFactionID = 1273, reaction = "Best Friend", standing = 42999, reactionThreshold = 42000 }
r, s = run(REP, "UPDATE_FACTION")
check(s.righttext == "Best Friend" and s.value == 1 and s.total == 1, "max friendship rank: full bar, rank name")
check(tipText(s) == "Jogu the Drunk | Friendship rank = Best Friend | Progress = highest rank", "max friendship tooltip: " .. tipText(s))
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
-- watched faction is the guild: the Rep bar shows it under the guild's own name
W.guildName = "Example Guild"
W.watch = { factionID = 1168, name = "Guild", reaction = 5, currentReactionThreshold = 3000, nextReactionThreshold = 9000, currentStanding = 4500 }
r, s = run(REP, "UPDATE_FACTION")
check(s.show and s.lefttext == "Example Guild   Friendly" and s.value == 1500 and s.total == 6000, "watched guild faction: Rep bar uses the guild name")
W.watch = nil

-- guild reputation
W.guildName, W.guildFaction = nil, nil
r, s = run(GUILD, "STATUS")
check(not (s and s.show), "not in a guild: Guild hidden")
W.guildName = "Example Guild"
W.guildFaction = { factionID = 1168, name = "Guild", reaction = 6, currentReactionThreshold = 9000, nextReactionThreshold = 21000, currentStanding = 15000 }
r, s = run(GUILD, "PLAYER_GUILD_UPDATE")
check(r and s.show and s.value == 6000 and s.total == 12000 and s.tier == 6, "guild faction progress inside the standing")
check(s.lefttext == "Example Guild   Honored" and s.righttext == "6,000 / 12,000   50.0%", "Guild text: " .. tostring(s.lefttext) .. " | " .. tostring(s.righttext))
check(tipText(s) == "Example Guild | Guild standing = Honored | Progress = 6,000 / 12,000  (50.0%) | To Revered = 6,000  (50.0%)", "Guild tooltip: " .. tipText(s))
check(not tipText(s):lower():find("cap", 1, true), "no cap line (MoP Classic has no guild reputation cap API)")
check(run(GUILD, "UPDATE_FACTION") == false, "no redraw when nothing changed")
W.guildFaction.currentStanding = 16500
r, s = run(GUILD, "UPDATE_FACTION")
check(r and s.value == 7500, "guild rep gain updates the bar")
W.watch = { factionID = 1270, name = "Shado-Pan", reaction = 6, currentReactionThreshold = 9000, nextReactionThreshold = 21000, currentStanding = 12000 }
r, s = run(GUILD, "UPDATE_FACTION")
check(s.show, "another faction watched: Guild still shown")
W.watch = { factionID = 1168, name = "Guild", reaction = 6, currentReactionThreshold = 9000, nextReactionThreshold = 21000, currentStanding = 16500 }
r, s = run(GUILD, "UPDATE_FACTION")
check(r and not s.show, "watching the guild faction: Guild bar hides (the Rep bar shows it)")
W.watch = nil
r, s = run(GUILD, "UPDATE_FACTION")
check(r and s.show, "unwatching the guild: Guild bar back")
W.guildFaction = { factionID = 1168, name = "Guild", reaction = 8, currentReactionThreshold = 42000, nextReactionThreshold = 42000, currentStanding = 42999 }
r, s = run(GUILD, "UPDATE_FACTION")
check(s.tier == 8 and s.value == 1 and s.total == 1 and s.righttext == "Exalted" and tipText(s):find("Progress = maxed", 1, true), "Exalted guild: full bar")
W.guildFaction = { factionID = 1168, name = "Guild", reaction = 4, currentReactionThreshold = 0, nextReactionThreshold = 3000, currentStanding = 0 }
r, s = run(GUILD, "UPDATE_FACTION")
check(s.show and s.tier == 4 and s.value == 0 and s.lefttext == "Example Guild   Neutral", "new guild member: Neutral 0 / 3,000")
W.guildRepOff = true
r, s = run(GUILD, "UPDATE_FACTION")
check(not s.show, "client says guild reputation is off: hidden")
W.guildRepOff = nil
W.guildName = nil
r, s = run(GUILD, "PLAYER_GUILD_UPDATE")
check(not s.show, "leaving the guild hides it")
W.guildName = "Example Guild"
run(GUILD, "UPDATE_FACTION")
W.guildName = nil
r, s = run(GUILD, "PLAYER_GUILD_UPDATE")
check(r and not s.show, "leaving the guild while the bar shows: hidden on PLAYER_GUILD_UPDATE")
W.guildName = "Example Guild"
local keepGF = C_Reputation.GetGuildFactionData
C_Reputation.GetGuildFactionData = function() return nil end
r, s = run(GUILD, "UPDATE_FACTION")
check(not s.show, "guild data not loaded yet: hidden, no error")
C_Reputation.GetGuildFactionData = keepGF
-- older client: GetGuildFactionInfo fallback (guildName, description, standingID, barMin, barMax, barValue)
local keepC = _G.C_Reputation
_G.C_Reputation = nil
_G.GetGuildFactionInfo = function() return "Example Guild", "", 5, 3000, 9000, 6000 end
_G.GetWatchedFactionInfo = function() return nil end
r, s = run(GUILD, "UPDATE_FACTION")
check(s.show and s.value == 3000 and s.total == 6000 and s.tier == 5, "GetGuildFactionInfo fallback")
_G.GetWatchedFactionInfo = function() return "Example Guild", 5, 3000, 9000, 6000, 1168 end
r, s = run(GUILD, "UPDATE_FACTION")
check(not s.show, "fallback: watched guild hides the Guild bar too")
_G.C_Reputation, _G.GetGuildFactionInfo, _G.GetWatchedFactionInfo = keepC, nil, nil
W.guildFaction = { factionID = 1168, name = "Guild", reaction = 6, currentReactionThreshold = 9000, nextReactionThreshold = 21000, currentStanding = 15000 }
r, s = run(GUILD, "UPDATE_FACTION")
check(#GUILD.conditions == 8, "Guild: 8 standing colours")
for i, c in ipairs(GUILD.conditions) do
  check(c.check.variable == "tier" and tonumber(c.check.value) == i and c.changes[1].property == "barColor", "Guild standing colour " .. i)
end
do local ev = " " .. GUILD.triggers[1].trigger.events .. " "
  check(ev:find(" UPDATE_FACTION ", 1, true) and ev:find(" PLAYER_GUILD_UPDATE ", 1, true) and ev:find(" PLAYER_ENTERING_WORLD ", 1, true), "Guild events") end

-- one colour condition per standing, each a real bar colour change
check(#REP.conditions == 8, "8 standing colours")
for i, c in ipairs(REP.conditions) do
  check(c.check.variable == "tier" and c.check.op == "==" and tonumber(c.check.value) == i and c.changes[1].property == "barColor" and #c.changes[1].value == 4, "standing colour " .. i)
end

---------------- mouseover tooltip: run each bar's On Show action in the real sandbox ----------------
local frames, TT = {}, { lines = {} }
local function newFrame(parent)
  local fr = { parent = parent, scripts = {}, level = 1, calls = {} }
  function fr:SetAllPoints(o) self.allPoints = o end
  function fr:SetFrameLevel(n) self.level = n end
  function fr:GetFrameLevel() return self.level end
  function fr:EnableMouseMotion(v) self.motion = v end
  function fr:SetMouseClickEnabled(v) self.click = v end
  function fr:EnableMouse(v) self.mouse = v end
  function fr:SetScript(k, fn) self.scripts[k] = fn end
  return fr
end
_G.CreateFrame = function(kind, name, parent) local fr = newFrame(parent) fr.kind = kind frames[#frames + 1] = fr return fr end
function TT:SetOwner(o, a) self.owner, self.anchor, self.lines, self.shown = o, a, {}, false end
function TT:GetOwner() return self.owner end
function TT:ClearAllPoints() self.point = nil end
function TT:SetPoint(...) self.point = { ... } end
function TT:ClearLines() self.lines = {} end
function TT:AddLine(t, r, g, b) self.lines[#self.lines + 1] = { t, nil, r, g, b } end
function TT:AddDoubleLine(l, rt, ...) self.lines[#self.lines + 1] = { l, rt, ... } end
function TT:Show() self.shown = true end
function TT:Hide() self.shown = false end
_G.GameTooltip = TT
local regionsById = {}
for _, c in ipairs(t.c) do regionsById[c.id] = newFrame() end
local keepGD, keepGR, keepER = WeakAuras.GetData, WeakAuras.GetRegion, Private.EnsureRegion
local dataById = {} for _, c in ipairs(t.c) do dataById[c.id] = c end
WeakAuras.GetData = function(id) return dataById[id] end
WeakAuras.GetRegion = function(id) return regionsById[id] end
Private.EnsureRegion = function(id) return regionsById[id] end
for _, c in ipairs(t.c) do
  local a = c.actions.start
  check(a.do_custom and type(a.custom) == "string", "On Show action sets up the hover frame " .. c.id)
  local fn = assert(WeakAuras.LoadFunction("return function() " .. a.custom .. "\n end", c.id), "compile hover " .. c.id)
  local reg = regionsById[c.id]
  reg.state = states[c.id][""]
  local n0 = #frames
  Private.ActivateAuraEnvironment(c.id, nil, reg.state, states[c.id]) fn() Private.ActivateAuraEnvironment()
  Private.ActivateAuraEnvironment(c.id, nil, reg.state, states[c.id]) fn() Private.ActivateAuraEnvironment()
  check(#frames == n0 + 1, "one hover frame per bar, even when shown again " .. c.id)
  local hf = frames[#frames]
  check(hf.parent == reg and hf.allPoints == reg and reg.schizTip == hf, "hover frame covers the bar " .. c.id)
  check(hf.motion == true and hf.click == false and hf.mouse == nil, "mouse motion only, clicks pass through " .. c.id)
  check(type(hf.scripts.OnEnter) == "function" and type(hf.scripts.OnLeave) == "function", "OnEnter / OnLeave set " .. c.id)
end
-- XP hover with pending quests
W.level, W.xp, W.xpMax, W.rested = 42, 12345, 50000, 17500
W.log = { { title = "Done A", complete = 1, id = 101, xp = 2400 } }
run(XP, "QUEST_LOG_UPDATE")
local xr = regionsById[XP.id] xr.state = states[XP.id][""]
xr.schizTip.scripts.OnEnter(xr.schizTip)
check(TT.shown and TT.owner == xr.schizTip and TT.anchor == "ANCHOR_NONE", "hovering XP shows the GameTooltip")
check(TT.point and TT.point[1] == "BOTTOMRIGHT" and TT.point[3] == "BOTTOMLEFT" and TT.point[4] < 0, "tooltip sits left of the tray, not over Details!")
check(TT.lines[1][1] == "Level 42" and TT.lines[1][3] > TT.lines[1][5], "bronze title line")
local found = false for _, l in ipairs(TT.lines) do if l[1] == "Completed quests" and l[2] == "+2,400  (1 quest)" then found = true end end
check(found and #TT.lines == 6, "XP tooltip lines incl. completed quests (" .. #TT.lines .. ")")
xr.schizTip.scripts.OnLeave(xr.schizTip)
check(not TT.shown, "leaving hides it")
local rr = regionsById[REP.id]
W.watch = { factionID = 1270, name = "Shado-Pan", reaction = 6, currentReactionThreshold = 9000, nextReactionThreshold = 21000, currentStanding = 12000 }
run(REP, "UPDATE_FACTION") rr.state = states[REP.id][""]
rr.schizTip.scripts.OnEnter(rr.schizTip)
check(TT.shown and TT.lines[1][1] == "Shado-Pan" and #TT.lines == 4 and TT.lines[4][1] == "To Revered", "hovering Rep shows faction lines")
TT.owner = {} rr.schizTip.scripts.OnLeave(rr.schizTip)
check(TT.shown, "leaving doesn't hide a tooltip someone else owns")
rr.state = nil TT.shown = false
rr.schizTip.scripts.OnEnter(rr.schizTip)
check(not TT.shown, "no state (bar hidden): no tooltip, no error")
local gr = regionsById[GUILD.id] gr.state = states[GUILD.id][""]
gr.schizTip.scripts.OnEnter(gr.schizTip)
check(TT.shown and TT.lines[1][1] == "Example Guild" and TT.lines[2][1] == "Guild standing" and #TT.lines == 4, "hovering Guild shows guild lines")
check(TT.point[1] == "BOTTOMRIGHT" and TT.point[3] == "BOTTOMLEFT", "Guild tooltip left of the tray too")
gr.schizTip.scripts.OnLeave(gr.schizTip)
-- client without EnableMouseMotion: plain EnableMouse fallback
do local reg = newFrame() local fr0 = newFrame
  _G.CreateFrame = function(_, _, parent) local fr = fr0(parent) fr.EnableMouseMotion = nil frames[#frames + 1] = fr return fr end
  regionsById[XP.id] = reg
  local fn = WeakAuras.LoadFunction("return function() " .. XP.actions.start.custom .. "\n end", XP.id)
  Private.ActivateAuraEnvironment(XP.id, nil, nil, states[XP.id]) fn() Private.ActivateAuraEnvironment()
  check(reg.schizTip and reg.schizTip.mouse == true, "no EnableMouseMotion: EnableMouse fallback") end
WeakAuras.GetData, WeakAuras.GetRegion, Private.EnsureRegion = keepGD, keepGR, keepER

---------------- every game API the tray calls exists in the 5.5 client ----------------
if UISRC then
  local function grep(pat, path) local p = io.popen("grep -rqs -- '" .. pat .. "' '" .. UISRC .. "/" .. path .. "' && echo y") local o = p:read("*a") p:close() return o:find("y") ~= nil end
  local doc = "Interface/AddOns/Blizzard_APIDocumentationGenerated"
  for _, api in ipairs({ "GetWatchedFactionData", "GetGuildFactionData", "IsGuildReputationEnabled", "IsInGuild", "GetFriendshipReputation", "GetMaxLevelForPlayerExpansion", "IsXPUserDisabled" }) do
    check(grep('Name = "' .. api .. '"', doc), "5.5 API documented: " .. api)
  end
  check(grep('LiteralName = "PLAYER_GUILD_UPDATE"', doc) and grep('LiteralName = "UPDATE_FACTION"', doc), "5.5 events documented: PLAYER_GUILD_UPDATE, UPDATE_FACTION")
  check(not grep("Cap", doc .. "/ReputationInfoDocumentation.lua"), "5.5 C_Reputation has no reputation cap field (so no cap line)")
  check(grep("C_Reputation.GetGuildFactionData()", "Interface/AddOns/Blizzard_Communities/GuildRewards.lua"), "5.5 guild UI reads C_Reputation.GetGuildFactionData()")
  check(grep('GetGuildInfo("player")', "Interface/AddOns"), "used by the 5.5 FrameXML: GetGuildInfo(\"player\")")
  check(grep('LiteralName = "QUEST_LOG_UPDATE"', doc) and grep('LiteralName = "UNIT_QUEST_LOG_CHANGED"', doc) and grep('LiteralName = "QUEST_TURNED_IN"', doc), "5.5 events documented: QUEST_LOG_UPDATE, UNIT_QUEST_LOG_CHANGED, QUEST_TURNED_IN")
  check(grep("xp = GetQuestLogRewardXP();", "Interface/AddOns/Blizzard_UIPanels_Game/Wrath/QuestInfo.lua"), "5.5 quest panel reads quest XP with GetQuestLogRewardXP() on the selected entry")
  check(grep("Wrath\\\\QuestInfo.lua \\[AllowLoadGameType wrath, cata, mists\\]", "Interface/AddOns/Blizzard_UIPanels_Game/Blizzard_UIPanels_Game_Classic.toc"), "that quest panel is the one MoP Classic loads")
  check(grep("SelectQuestLogEntry(", "Interface/AddOns/Blizzard_UIPanels_Game") and grep("GetQuestLogSelection()", "Interface/AddOns/Blizzard_UIPanels_Game"), "5.5 client has SelectQuestLogEntry / GetQuestLogSelection")
  for _, api in ipairs({ "EnableMouseMotion", "SetMouseClickEnabled" }) do check(grep(api, "Interface/AddOns"), "5.5 FrameXML uses " .. api) end
  check(not grep('Name = "GetNumQuestLogEntries"', doc .. "/QuestLogDocumentation.lua"), "5.5 C_QuestLog has no GetNumQuestLogEntries (so the legacy globals are used)")
  for _, api in ipairs({ "UnitXP(\"player\")", "UnitXPMax(\"player\")", "GetXPExhaustion()", "BreakUpLargeNumbers(" }) do
    check(grep(api, "Interface/AddOns"), "used by the 5.5 FrameXML: " .. api)
  end
  -- FACTION_STANDING_LABEL1..8 are GlobalStrings, which the source dump doesn't carry; WeakAuras' own list of
  -- client globals (.luacheckrc) has them, and the trigger falls back to English labels if one is ever missing.
  local rc = io.open(WA_TESTS .. "/../.luacheckrc")
  if rc then local body = rc:read("*a") rc:close() check(body:find('"FACTION_STANDING_LABEL8"', 1, true) ~= nil, "FACTION_STANDING_LABELn are known client globals")
    for _, g in ipairs({ "GetNumQuestLogEntries", "GetQuestLogTitle", "GetQuestLogRewardXP" }) do check(body:find('"' .. g .. '"', 1, true) ~= nil, "known client global: " .. g) end end
end

do local n = 0 for _, w in ipairs(warnings) do if w.key == "SandboxForbidden" then n = n + 1 end end
  check(n == 0, "no WeakAuras sandbox violations (" .. n .. ")") end
print(("\n%d passed, %d failed; sandbox warnings: %d"):format(P, F, #warnings))
for _, w in ipairs(warnings) do print("  warning", w.key, w.message) end
if F > 0 then os.exit(1) end
