-- Builds "Schizzle's XP & Rep Tray" (!WA:2! export): a 500 px wide stack of three slim bars, experience on top, the
-- watched reputation under it and guild reputation at the bottom, in the bottom-right corner directly under the
-- side-by-side Details! windows.
-- Usage: lua tray_build.lua   (writes "../XP & Rep Tray.txt"; LibSerialize / LibDeflate must be on disk)
local HERE = (arg and arg[0] and arg[0]:match("^(.*)/[^/]*$")) or "."
local LIBDIR = os.getenv("WA_LIBS") or "/workspace"
local LibSerialize = dofile(LIBDIR .. "/LibSerialize/LibSerialize.lua")
local LibDeflate = dofile(LIBDIR .. "/LibDeflate/LibDeflate.lua")
local OUT = os.getenv("WA_OUT") or (HERE .. "/../XP & Rep Tray.txt")
local TOC, INTERNAL, VER = 50504, 90, "5.22.1"
-- RELEASE goes into the group name and the description only; the uids never carry it, so re-importing updates in place.
local RELEASE = "1.3"
local GROUP = "Schizzle's XP & Rep Tray v" .. RELEASE
local FONT = "Fira Sans Condensed Medium"

-- Geometry. Three 500 x 10 bars, 2 px apart: the tray is 34 px tall (TRAY_H). Its top edge is fixed at 38 px up
-- (4 px screen margin + 34), which is where the Details! windows' bottom edge sits, so the windows rest on it.
local BAR_W, BAR_H, GAP, MARGIN, BARS = 500, 10, 2, 4, 3
local TRAY_H = BAR_H * BARS + GAP * (BARS - 1)
local TOP_Y = MARGIN + TRAY_H

local XP_BLUE, QUEST_GREEN, RESTED_PURPLE = { 0.25, 0.5, 1, 1 }, { 0.25, 0.8, 0.3, 0.6 }, { 0.6, 0.35, 0.9, 0.6 }
local CHARCOAL = { 0.06, 0.06, 0.06, 0.85 }
local ANIM = { start = { type = "none", duration_type = "seconds", easeType = "none", easeStrength = 3 },
               main = { type = "none", duration_type = "seconds", easeType = "none", easeStrength = 3 },
               finish = { type = "none", duration_type = "seconds", easeType = "none", easeStrength = 3 } }
-- no class, spec or level restriction: the tray suits any character (each bar hides itself when it has nothing to show)
local function LOAD()
  return { size = { multi = {} }, spec = { multi = {} }, talent = { multi = {} }, class = { multi = {} },
           class_and_spec = { multi = {} } }
end
local function text(t, point, x)
  return { type = "subtext", text_text = t, text_color = { 1, 1, 1, 1 }, text_font = FONT, text_fontSize = 9,
    text_fontType = "OUTLINE", text_visible = true, text_justify = "CENTER", text_selfPoint = "AUTO",
    anchor_point = point, text_anchorXOffset = x, text_anchorYOffset = 0,
    text_shadowColor = { 0, 0, 0, 1 }, text_shadowXOffset = 1, text_shadowYOffset = -1, rotateText = "NONE",
    text_automaticWidth = "Auto", text_fixedWidth = 64, text_wordWrap = "WordWrap" }
end
-- custom event trigger: WeakAuras runs it once on load ("STATUS") and on every listed event
local function trig(code, events, vars)
  return {
    activeTriggerMode = -10, disjunctive = "any",
    { trigger = { type = "custom", custom_type = "stateupdate", check = "event", events = events, custom = code,
                  customVariables = vars, debuffType = "HELPFUL", unit = "player",
                  names = {}, spellIds = {}, event = "Health", subeventPrefix = "SPELL", subeventSuffix = "_CAST_START" },
      untrigger = {} },
  }
end
local HIDE = [[
    local st = allstates[""]
    if st and st.show then st.show = false; st.changed = true; return true end
    return false]]

-- Mouseover tooltip (v1.2). On Show, each bar gets one invisible child frame covering it that takes mouse *motion* only
-- (EnableMouseMotion + SetMouseClickEnabled(false)), so clicks still go through to the world. Hovering shows a
-- GameTooltip with the lines the trigger keeps in its state (tipTitle, tip = { { left, right }, ... }), anchored to the
-- left of the tray so it never covers the Details! windows above it. Uses only calls the WeakAuras sandbox allows.
local HOVER = [[
local r = aura_env.region
if not r or r.schizTip or type(CreateFrame) ~= "function" then return end
local f = CreateFrame("Frame", nil, r)
f:SetAllPoints(r)
f:SetFrameLevel(r:GetFrameLevel() + 5)
if f.EnableMouseMotion then
  f:EnableMouseMotion(true)
  if f.SetMouseClickEnabled then f:SetMouseClickEnabled(false) end
else
  f:EnableMouse(true)
end
local function show(self)
  local st, tt = r.state, GameTooltip
  if not tt or not st or type(st.tip) ~= "table" then return end
  tt:SetOwner(self, "ANCHOR_NONE")
  tt:ClearAllPoints()
  tt:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", -6, 0)
  tt:ClearLines()
  tt:AddLine(st.tipTitle or "", 0.85, 0.6, 0.3)
  for _, l in ipairs(st.tip) do tt:AddDoubleLine(l[1], l[2], 0.75, 0.75, 0.75, 1, 1, 1) end
  tt:Show()
end
f:SetScript("OnEnter", show)
f:SetScript("OnLeave", function(self) if GameTooltip and GameTooltip:GetOwner() == self then GameTooltip:Hide() end end)
r.schizTip = f
]]

local function bar(id, color)
  return {
    id = id, uid = id:gsub("%W", ""), parent = GROUP, regionType = "aurabar", internalVersion = INTERNAL, tocversion = TOC,
    width = BAR_W, height = BAR_H, xOffset = 0, yOffset = 0, selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    texture = "Clean", textureSource = "LSM", orientation = "HORIZONTAL", inverse = false, icon = false, iconSource = -1,
    barColor = color, barColor2 = { 1, 1, 0, 1 }, backgroundColor = CHARCOAL, enableGradient = false,
    gradientOrientation = "HORIZONTAL", spark = false, frameStrata = 1, zoom = 0, alpha = 1, desaturate = false,
    progressSource = { -1, "" }, adjustedMax = "", adjustedMin = "", useAdjustededMax = false, useAdjustededMin = false,
    subRegions = { { type = "subbackground" }, { type = "subforeground" },
      text("%lefttext", "INNER_LEFT", 4), text("%righttext", "INNER_RIGHT", -4),
      -- 1 px bronze frame drawn inside the bar (offset 0), so it never spills into the gap or onto Details!
      { type = "subborder", border_visible = true, border_edge = "Square Full White", border_color = { 0.72, 0.45, 0.2, 0.9 },
        border_offset = 0, border_size = 1, anchor_area = "bar" } },
    conditions = {}, load = LOAD(), actions = { init = {}, start = { do_custom = true, custom = HOVER }, finish = {} },
    animation = ANIM, config = {}, authorOptions = {}, information = {},
  }
end

local children = {}


-- XP: current / needed for this level as a blue fill. In front of it, clipped to the bar end: a green overlay for the XP
-- waiting in completed quests that haven't been turned in yet, then a purple overlay for rested XP.
-- Quest XP: the 5.5 client's quest log API is the legacy one (C_QuestLog there has no GetInfo/GetNumQuestLogEntries):
-- GetNumQuestLogEntries, GetQuestLogTitle (isHeader 4th, isComplete 6th = 1 when ready to turn in, -1 failed, questID 8th)
-- and GetQuestLogRewardXP. v1.1 called GetQuestLogRewardXP(questID) because the 5.5.4 alert frames do that for world
-- quests, but for the quest log the function reads the *selected* entry: the MoP quest panel (Wrath/QuestInfo.lua, loaded
-- for mists) calls SelectQuestLogEntry(i) and then GetQuestLogRewardXP() with no argument. With nothing (or another quest)
-- selected the v1.1 sum came out 0, so the green overlay never drew. v1.2 selects each completed quest, reads its XP,
-- then puts the player's own selection back. Quests under a collapsed quest-log header aren't listed by the client, so
-- they can't be counted (expanding headers would change the quest log for the player).
-- Hidden at the level cap (90 in MoP; read from the client when it says so) and when XP gain is switched off.
local XP_TSU = [[
function(allstates, event, arg1)
  local lvl = UnitLevel("player") or 0
  if event == "PLAYER_LEVEL_UP" and type(arg1) == "number" then lvl = arg1 end
  local cap = 90
  if type(GetMaxLevelForPlayerExpansion) == "function" then
    local m = GetMaxLevelForPlayerExpansion()
    if type(m) == "number" and m > 0 then cap = m end
  end
  local off = lvl >= cap
  if not off and type(IsXPUserDisabled) == "function" and IsXPUserDisabled() then off = true end
  local total = UnitXPMax("player") or 0
  if off or total <= 0 then
]] .. HIDE .. [[

  end
  local cur = UnitXP("player") or 0
  local rested = GetXPExhaustion() or 0
  local quest, nq = 0, 0
  if type(GetNumQuestLogEntries) == "function" and type(GetQuestLogTitle) == "function" and type(GetQuestLogRewardXP) == "function" then
    local canSelect = type(SelectQuestLogEntry) == "function" and type(GetQuestLogSelection) == "function"
    local keep = canSelect and GetQuestLogSelection() or 0
    local moved = false
    local n = GetNumQuestLogEntries() or 0
    for i = 1, n do
      local title, _, _, isHeader, _, isComplete, _, questID = GetQuestLogTitle(i)
      if title and not isHeader and (isComplete == 1 or isComplete == true) then
        if canSelect then SelectQuestLogEntry(i); moved = true end
        local x = GetQuestLogRewardXP(questID)
        if type(x) == "number" and x > 0 then quest, nq = quest + x, nq + 1 end
      end
    end
    if moved and GetQuestLogSelection() ~= keep then SelectQuestLogEntry(keep or 0) end
  end
  local fmt = type(BreakUpLargeNumbers) == "function" and BreakUpLargeNumbers or tostring
  local left = "Level " .. lvl
  if rested > 0 then left = left .. string.format("   Rested %d%%", math.floor(rested / total * 100 + 0.5)) end
  local right = string.format("%s / %s   %.1f%%", fmt(cur), fmt(total), cur / total * 100)
  if quest > 0 then right = right .. "   +" .. fmt(quest) .. " quest" end
  local function pct(v) return string.format("%.1f%%", v / total * 100) end
  local tip = { { "Experience", fmt(cur) .. " / " .. fmt(total) .. "  (" .. pct(cur) .. ")" },
    { "To level " .. (lvl + 1), fmt(total - cur) .. "  (" .. pct(total - cur) .. ")" },
    { "Rested", rested > 0 and (fmt(rested) .. "  (" .. pct(rested) .. " of the level)") or "none" } }
  if quest > 0 then
    tip[#tip + 1] = { "Completed quests", "+" .. fmt(quest) .. "  (" .. nq .. (nq == 1 and " quest)" or " quests)") }
    local after = cur + quest
    if after >= total then tip[#tip + 1] = { "After turn-ins", "level " .. (lvl + 1) .. " +" .. fmt(after - total) }
    else tip[#tip + 1] = { "After turn-ins", fmt(after) .. " / " .. fmt(total) .. "  (" .. pct(after) .. ")" } end
  end
  local st = allstates[""]
  if st and st.show and st.value == cur and st.total == total and st.rested == rested and st.quest == quest and st.nq == nq and st.lefttext == left then return false end
  allstates[""] = { show = true, changed = true, progressType = "static", value = cur, total = total, autoHide = false,
    rested = rested, quest = quest, nq = nq, tipTitle = "Level " .. lvl, tip = tip,
    additionalProgress = { { direction = "forward", width = quest }, { direction = "forward", offset = quest, width = rested } },
    lefttext = left, righttext = right, level = lvl }
  return true
end]]
local xp = bar("Schizzle Tray XP", XP_BLUE)
xp.overlays = { QUEST_GREEN, RESTED_PURPLE }
xp.overlayclip = true
xp.triggers = trig(XP_TSU, -- UNIT_ events need a unit after the colon, or WeakAuras registers nothing for them (GenericTrigger.lua)
  "PLAYER_XP_UPDATE PLAYER_LEVEL_UP UPDATE_EXHAUSTION PLAYER_UPDATE_RESTING PLAYER_ENTERING_WORLD QUEST_LOG_UPDATE UNIT_QUEST_LOG_CHANGED:player QUEST_TURNED_IN",
  "{ value = true, total = true, rested = 'number', quest = 'number', nq = 'number', level = 'number', lefttext = 'string', righttext = 'string', additionalProgress = 2 }")
children[#children + 1] = xp

-- Reputation: the faction picked with "Show as Experience Bar" in the reputation panel. MoP Classic 5.5 has
-- C_Reputation.GetWatchedFactionData; GetWatchedFactionInfo is the older fallback. Friendship factions (the Tillers
-- farmers and so on) show their own rank name and progress. Hidden when no faction is watched.
local LABELS = '{ "Hated", "Hostile", "Unfriendly", "Neutral", "Friendly", "Honored", "Revered", "Exalted" }'
local REP_TSU = [[
function(allstates, event)
  local name, reaction, lo, hi, val, fid
  if C_Reputation and type(C_Reputation.GetWatchedFactionData) == "function" then
    local d = C_Reputation.GetWatchedFactionData()
    if type(d) == "table" and d.factionID and d.factionID ~= 0 then
      name, reaction, lo, hi, val, fid = d.name, d.reaction, d.currentReactionThreshold, d.nextReactionThreshold, d.currentStanding, d.factionID
    end
  elseif type(GetWatchedFactionInfo) == "function" then
    name, reaction, lo, hi, val, fid = GetWatchedFactionInfo()
  end
  if not name or name == "" or type(reaction) ~= "number" then
]] .. HIDE .. [[

  end
  -- the guild faction (1168) as the watched one: show the guild's own name
  if fid == 1168 and type(GetGuildInfo) == "function" then
    local g = GetGuildInfo("player")
    if g and g ~= "" then name = g end
  end
  local labels = ]] .. LABELS .. [[

  local label = _G["FACTION_STANDING_LABEL" .. reaction] or labels[reaction] or ""
  local tier = reaction
  local maxed, friend = false, false
  if fid and C_GossipInfo and type(C_GossipInfo.GetFriendshipReputation) == "function" then
    local f = C_GossipInfo.GetFriendshipReputation(fid)
    if type(f) == "table" and (f.friendshipFactionID or 0) > 0 then
      label, tier, friend = f.reaction or label, 5, true
      if f.nextThreshold then lo, hi, val = f.reactionThreshold, f.nextThreshold, f.standing
      else lo, hi, val, maxed = 0, 1, 1, true end
    end
  end
  lo, hi, val = lo or 0, hi or 0, val or 0
  local total, cur = hi - lo, val - lo
  if total <= 0 then total, cur, maxed = 1, 1, true end
  if cur > total then cur = total end
  if cur < 0 then cur = 0 end
  local fmt = type(BreakUpLargeNumbers) == "function" and BreakUpLargeNumbers or tostring
  local left = name .. "   " .. label
  local right = maxed and label or string.format("%s / %s   %.1f%%", fmt(cur), fmt(total), cur / total * 100)
  local tip = { { friend and "Friendship rank" or "Standing", label } }
  if maxed then tip[#tip + 1] = { "Progress", friend and "highest rank" or "maxed" }
  else
    local nextLabel = friend and "next rank" or (_G["FACTION_STANDING_LABEL" .. (reaction + 1)] or labels[reaction + 1] or "next standing")
    tip[#tip + 1] = { "Progress", fmt(cur) .. " / " .. fmt(total) .. "  (" .. string.format("%.1f%%", cur / total * 100) .. ")" }
    tip[#tip + 1] = { "To " .. nextLabel, fmt(total - cur) .. "  (" .. string.format("%.1f%%", (total - cur) / total * 100) .. ")" }
  end
  local st = allstates[""]
  if st and st.show and st.value == cur and st.total == total and st.tier == tier and st.lefttext == left and st.righttext == right then return false end
  allstates[""] = { show = true, changed = true, progressType = "static", value = cur, total = total, autoHide = false,
    tier = tier, lefttext = left, righttext = right, tipTitle = name, tip = tip }
  return true
end]]
-- colour by standing: red / orange / yellow like Blizzard up to Neutral, then a distinct colour per higher standing
local STANDING = {
  { 0.8, 0.13, 0.13, 1 }, { 0.8, 0.13, 0.13, 1 }, { 1, 0.47, 0, 1 }, { 1, 0.82, 0, 1 },
  { 0.25, 0.7, 0.25, 1 }, { 0.1, 0.65, 0.5, 1 }, { 0.15, 0.6, 0.8, 1 }, { 0.65, 0.4, 0.95, 1 },
}
local rep = bar("Schizzle Tray Rep", STANDING[4])
rep.triggers = trig(REP_TSU, "UPDATE_FACTION PLAYER_ENTERING_WORLD",
  "{ value = true, total = true, tier = 'number', lefttext = 'string', righttext = 'string' }")
for i, c in ipairs(STANDING) do
  rep.conditions[i] = { check = { trigger = 1, variable = "tier", op = "==", value = tostring(i) },
                        changes = { { property = "barColor", value = c } } }
end
children[#children + 1] = rep

-- Guild reputation (v1.3): the player's guild faction (faction 1168, "Guild") from C_Reputation.GetGuildFactionData,
-- which the 5.5.4 guild UI itself reads (Blizzard_Communities/GuildRewards.lua, GuildInviteFrame.lua); the older
-- GetGuildFactionInfo is a fallback. Hidden when not in a guild, when the client says guild reputation is off, and when
-- the watched faction already is the guild (the Rep bar above shows it then, so it isn't drawn twice). MoP Classic's
-- API has no guild reputation cap (no weekly-cap field or function), so the tooltip has no cap line.
local GUILD_TSU = [[
function(allstates, event)
  local inGuild = type(IsInGuild) ~= "function" or IsInGuild()
  if inGuild and C_GuildInfo and type(C_GuildInfo.IsGuildReputationEnabled) == "function" and not C_GuildInfo.IsGuildReputationEnabled() then inGuild = false end
  local name, reaction, lo, hi, val, fid
  if inGuild then
    if C_Reputation and type(C_Reputation.GetGuildFactionData) == "function" then
      local d = C_Reputation.GetGuildFactionData()
      if type(d) == "table" and d.factionID and d.factionID ~= 0 then
        name, reaction, lo, hi, val, fid = d.name, d.reaction, d.currentReactionThreshold, d.nextReactionThreshold, d.currentStanding, d.factionID
      end
    elseif type(GetGuildFactionInfo) == "function" then
      local _desc
      name, _desc, reaction, lo, hi, val = GetGuildFactionInfo()
      fid = 1168
    end
  end
  local dup = false
  if fid then
    local wid
    if C_Reputation and type(C_Reputation.GetWatchedFactionData) == "function" then
      local w = C_Reputation.GetWatchedFactionData()
      if type(w) == "table" then wid = w.factionID end
    elseif type(GetWatchedFactionInfo) == "function" then
      wid = select(6, GetWatchedFactionInfo())
    end
    dup = wid ~= nil and wid ~= 0 and (wid == fid or wid == 1168)
  end
  if dup or not name or type(reaction) ~= "number" then
]] .. HIDE .. [[

  end
  local guild = type(GetGuildInfo) == "function" and GetGuildInfo("player") or nil
  if not guild or guild == "" then guild = name end
  local labels = ]] .. LABELS .. [[

  local label = _G["FACTION_STANDING_LABEL" .. reaction] or labels[reaction] or ""
  lo, hi, val = lo or 0, hi or 0, val or 0
  local total, cur, maxed = hi - lo, val - lo, false
  if total <= 0 then total, cur, maxed = 1, 1, true end
  if cur > total then cur = total end
  if cur < 0 then cur = 0 end
  local fmt = type(BreakUpLargeNumbers) == "function" and BreakUpLargeNumbers or tostring
  local left = guild .. "   " .. label
  local right = maxed and label or string.format("%s / %s   %.1f%%", fmt(cur), fmt(total), cur / total * 100)
  local tip = { { "Guild standing", label } }
  if maxed then tip[#tip + 1] = { "Progress", "maxed" }
  else
    local nextLabel = _G["FACTION_STANDING_LABEL" .. (reaction + 1)] or labels[reaction + 1] or "next standing"
    tip[#tip + 1] = { "Progress", fmt(cur) .. " / " .. fmt(total) .. "  (" .. string.format("%.1f%%", cur / total * 100) .. ")" }
    tip[#tip + 1] = { "To " .. nextLabel, fmt(total - cur) .. "  (" .. string.format("%.1f%%", (total - cur) / total * 100) .. ")" }
  end
  local st = allstates[""]
  if st and st.show and st.value == cur and st.total == total and st.tier == reaction and st.lefttext == left and st.righttext == right then return false end
  allstates[""] = { show = true, changed = true, progressType = "static", value = cur, total = total, autoHide = false,
    tier = reaction, lefttext = left, righttext = right, tipTitle = guild, tip = tip }
  return true
end]]
local guildBar = bar("Schizzle Tray Guild", STANDING[4])
guildBar.triggers = trig(GUILD_TSU, "UPDATE_FACTION PLAYER_GUILD_UPDATE PLAYER_ENTERING_WORLD",
  "{ value = true, total = true, tier = 'number', lefttext = 'string', righttext = 'string' }")
for i, c in ipairs(STANDING) do
  guildBar.conditions[i] = { check = { trigger = 1, variable = "tier", op = "==", value = tostring(i) },
                             changes = { { property = "barColor", value = c } } }
end
children[#children + 1] = guildBar

-- Dynamic group: grows down from its top-right corner, right aligned, 2 px between bars, in list order (XP, Rep, Guild).
-- The group's TOPRIGHT sits on the screen's BOTTOMRIGHT at (-4, +38): the top edge never moves, so the bars stay
-- tucked under Details! and a hidden bar just leaves the bottom strip empty.
local group = {
  id = GROUP, uid = "SchizzleXPRepTray", regionType = "dynamicgroup", internalVersion = INTERNAL, tocversion = TOC,
  controlledChildren = {}, grow = "DOWN", align = "RIGHT", space = GAP, stagger = 0, sort = "none", animate = false,
  selfPoint = "TOPRIGHT", anchorPoint = "BOTTOMRIGHT", anchorFrameType = "SCREEN", xOffset = -MARGIN, yOffset = TOP_Y,
  frameStrata = 1, scale = 1, alpha = 1, useLimit = false, limit = 5, constantFactor = "RADIUS", radius = 200,
  rotation = 0, stepAngle = 15, fullCircle = true, arcLength = 360, gridType = "RD", centerType = "LR", gridWidth = 5,
  rowSpace = 1, columnSpace = 1, border = false, borderColor = { 0, 0, 0, 1 }, backdropColor = { 1, 1, 1, 0.5 },
  borderEdge = "Square Full White", borderOffset = 4, borderInset = 1, borderSize = 2, borderBackdrop = "Blizzard Tooltip",
  subRegions = {},
  triggers = { activeTriggerMode = -10, { trigger = { type = "aura2", names = {}, event = "Health", subeventPrefix = "SPELL",
    subeventSuffix = "_CAST_START", spellIds = {}, unit = "player", debuffType = "HELPFUL" }, untrigger = {} } },
  conditions = {}, load = LOAD(), actions = { init = {}, start = {}, finish = {} }, animation = ANIM,
  config = {}, authorOptions = {}, information = { saved = true },
  desc = "Schizzle's XP & Rep Tray: three slim 500 px bars (experience in blue with completed-quest XP in green and rested XP in purple, your watched reputation and your guild reputation) in the bottom-right corner, under the Details! windows. Hover a bar for details. v" .. RELEASE .. ".",
}
for _, c in ipairs(children) do group.controlledChildren[#group.controlledChildren + 1] = c.id end

local transmit = { m = "d", d = group, c = children, v = 1421, s = VER }
local ser = LibSerialize:SerializeEx({ errorOnUnserializableType = false }, transmit)
local comp = LibDeflate:CompressDeflate(ser, { level = 9 })
local out = "!WA:2!" .. LibDeflate:EncodeForPrint(comp)
local f = assert(io.open(OUT, "w")) f:write(out) f:close()
print("wrote", OUT, "bytes", #out, "children", #children, "tray height", TRAY_H)
