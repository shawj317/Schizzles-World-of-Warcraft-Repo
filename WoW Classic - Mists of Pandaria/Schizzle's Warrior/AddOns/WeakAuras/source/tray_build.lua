-- Builds "Schizzle's XP & Rep Tray" (!WA:2! export): a 500 px wide stack of two slim bars, experience on top and the
-- watched reputation under it, in the bottom-right corner directly under the side-by-side Details! windows.
-- Usage: lua tray_build.lua   (writes "../XP & Rep Tray.txt"; LibSerialize / LibDeflate must be on disk)
local HERE = (arg and arg[0] and arg[0]:match("^(.*)/[^/]*$")) or "."
local LIBDIR = os.getenv("WA_LIBS") or "/workspace"
local LibSerialize = dofile(LIBDIR .. "/LibSerialize/LibSerialize.lua")
local LibDeflate = dofile(LIBDIR .. "/LibDeflate/LibDeflate.lua")
local OUT = os.getenv("WA_OUT") or (HERE .. "/../XP & Rep Tray.txt")
local TOC, INTERNAL, VER = 50504, 90, "5.22.1"
-- RELEASE goes into the group name and the description only; the uids never carry it, so re-importing updates in place.
local RELEASE = "1.0"
local GROUP = "Schizzle's XP & Rep Tray v" .. RELEASE
local FONT = "Fira Sans Condensed Medium"

-- Geometry. Two 500 x 10 bars, 2 px apart: the tray is 22 px tall (TRAY_H). Its top edge is fixed at 26 px up
-- (4 px screen margin + 22), which is where the Details! windows' bottom edge sits, so the windows rest on it.
local BAR_W, BAR_H, GAP, MARGIN = 500, 10, 2, 4
local TRAY_H = BAR_H * 2 + GAP
local TOP_Y = MARGIN + TRAY_H

local BRONZE, CHARCOAL = { 0.72, 0.45, 0.2, 1 }, { 0.06, 0.06, 0.06, 0.85 }
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
    conditions = {}, load = LOAD(), actions = { init = {}, start = {}, finish = {} },
    animation = ANIM, config = {}, authorOptions = {}, information = {},
  }
end

local children = {}

-- XP: current / needed for this level, rested XP as a blue overlay in front of the fill (clipped to the bar).
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
  local fmt = type(BreakUpLargeNumbers) == "function" and BreakUpLargeNumbers or tostring
  local left = "Level " .. lvl
  if rested > 0 then left = left .. string.format("   Rested %d%%", math.floor(rested / total * 100 + 0.5)) end
  local right = string.format("%s / %s   %.1f%%", fmt(cur), fmt(total), cur / total * 100)
  local st = allstates[""]
  if st and st.show and st.value == cur and st.total == total and st.rested == rested and st.lefttext == left then return false end
  allstates[""] = { show = true, changed = true, progressType = "static", value = cur, total = total, autoHide = false,
    rested = rested, additionalProgress = { { direction = "forward", width = rested } },
    lefttext = left, righttext = right, level = lvl }
  return true
end]]
local xp = bar("Schizzle Tray XP", BRONZE)
xp.overlays = { { 0.3, 0.55, 1, 0.55 } }
xp.overlayclip = true
xp.triggers = trig(XP_TSU, "PLAYER_XP_UPDATE PLAYER_LEVEL_UP UPDATE_EXHAUSTION PLAYER_UPDATE_RESTING PLAYER_ENTERING_WORLD",
  "{ value = true, total = true, rested = 'number', level = 'number', lefttext = 'string', righttext = 'string', additionalProgress = 1 }")
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
  local labels = ]] .. LABELS .. [[

  local label = _G["FACTION_STANDING_LABEL" .. reaction] or labels[reaction] or ""
  local tier = reaction
  local maxed = false
  if fid and C_GossipInfo and type(C_GossipInfo.GetFriendshipReputation) == "function" then
    local f = C_GossipInfo.GetFriendshipReputation(fid)
    if type(f) == "table" and (f.friendshipFactionID or 0) > 0 then
      label, tier = f.reaction or label, 5
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
  local st = allstates[""]
  if st and st.show and st.value == cur and st.total == total and st.tier == tier and st.lefttext == left and st.righttext == right then return false end
  allstates[""] = { show = true, changed = true, progressType = "static", value = cur, total = total, autoHide = false,
    tier = tier, lefttext = left, righttext = right }
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

-- Dynamic group: grows down from its top-right corner, right aligned, 2 px between bars, in list order (XP, then Rep).
-- The group's TOPRIGHT sits on the screen's BOTTOMRIGHT at (-4, +26): the top edge never moves, so the bars stay
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
  desc = "Schizzle's XP & Rep Tray: two slim 500 px bars (experience with rested, and your watched reputation) in the bottom-right corner, under the Details! windows. v" .. RELEASE .. ".",
}
for _, c in ipairs(children) do group.controlledChildren[#group.controlledChildren + 1] = c.id end

local transmit = { m = "d", d = group, c = children, v = 1421, s = VER }
local ser = LibSerialize:SerializeEx({ errorOnUnserializableType = false }, transmit)
local comp = LibDeflate:CompressDeflate(ser, { level = 9 })
local out = "!WA:2!" .. LibDeflate:EncodeForPrint(comp)
local f = assert(io.open(OUT, "w")) f:write(out) f:close()
print("wrote", OUT, "bytes", #out, "children", #children, "tray height", TRAY_H)
