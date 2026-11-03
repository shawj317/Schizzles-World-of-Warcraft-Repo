-- Builds the "Schizzle's Warrior Rotation" import (!WA:2!) from engine.lua.
-- Run: lua build.lua. Writes "../All-in-One Rotation.txt". Paths are relative to this folder. LibSerialize and LibDeflate have to be on disk.
local HERE = (arg and arg[0] and arg[0]:match("^(.*)/[^/]*$")) or "."
local LIBDIR = os.getenv("WA_LIBS") or "/workspace"
local LibSerialize = dofile(LIBDIR .. "/LibSerialize/LibSerialize.lua")
local LibDeflate = dofile(LIBDIR .. "/LibDeflate/LibDeflate.lua")
local function read(p) local f = assert(io.open(p)) local s = f:read("*a") f:close() return s end
local ENGINE = read(HERE .. "/engine.lua")
local OUT = os.getenv("WA_OUT") or (HERE .. "/../All-in-One Rotation.txt")
local TOC, INTERNAL, VER = 50504, 90, "5.22.1"
-- RELEASE is the only version number. It goes into the in-game group name and the description. Change it here and nowhere else.
-- The group uid ("SchizzleWarriorGroup") and the child ids and uids never include it, so importing again updates the same aura.
local RELEASE = "1.7.1"
local GROUP = "Schizzle's Warrior Rotation v" .. RELEASE
local FONT = "Fira Sans Condensed Medium"

local function hide()
  return [[
    local st = allstates[""]
    if st and st.show then st.show = false; st.changed = true; return true end
    return false]]
end
local HEAD = [[
function(allstates)
  -- luacheck: globals SchizzleWarrior
  local E = SchizzleWarrior
  if not E or not E.Tick then return false end
  local R = E:Tick()
  if not R or R == aura_env.lastR then return false end
  aura_env.lastR = R
]]

local function iconTSU(pick)
  return HEAD .. [[
  local e = R.show and ]] .. pick .. [[

  if not e then
]] .. hide() .. [[

  end
  local dur = e.duration or 0
  allstates[""] = {
    show = true, changed = true, icon = e.icon, name = e.name,
    keybind = e.key or "", glow = e.glow and true or false, waiting = e.waiting and true or false, flash = R.flash and true or false,
    oor = e.oor and true or false, oorTint = e.oorTint and true or false, tag = e.tag or "",
    mode = R.mode or "", progressType = "timed", duration = dur,
    expirationTime = dur > 0 and ((e.start or 0) + dur) or 0, autoHide = false,
  }
  return true
end]]
end

local function textTSU(field)
  return HEAD .. [[
  if not R.show or not R.]] .. field .. [[ then
]] .. hide() .. [[

  end
  allstates[""] = { show = true, changed = true, ]] .. field .. [[ = R.]] .. field .. [[ }
  return true
end]]
end

-- Load: Warriors only, no spec requirement. Before level 10 you have no spec, so a spec load
-- would hide the whole HUD. The engine decides what each aura shows. Spec-only bars hide from their own triggers.
local function LOADFOR()
  return {
    use_class = true, class = { single = "WARRIOR", multi = { WARRIOR = true } },
    use_class_and_spec = nil, class_and_spec = { multi = {} },
    size = { multi = {} }, spec = { multi = {} }, talent = { multi = {} },
  }
end

local function trig(code, vars)
  return {
    activeTriggerMode = -10, disjunctive = "any",
    { trigger = { type = "custom", custom_type = "stateupdate", check = "update", custom = code,
                  customVariables = vars, events = "", debuffType = "HELPFUL", unit = "player",
                  names = {}, spellIds = {}, event = "Health", subeventPrefix = "SPELL", subeventSuffix = "_CAST_START" },
      untrigger = {} },
  }
end
local ICONVARS = "{ tag = 'string', glow = 'bool', flash = 'bool', waiting = 'bool', oor = 'bool', oorTint = 'bool', keybind = 'string', mode = 'string', expirationTime = true, duration = true }"

local function text(t, point, size, x, y, color, flags)
  return { type = "subtext", text_text = t, text_color = color or { 1, 1, 1, 1 }, text_font = FONT,
    text_fontSize = size, text_fontType = flags or "OUTLINE", text_visible = true, text_justify = "CENTER",
    text_selfPoint = "AUTO", anchor_point = point, text_anchorXOffset = x or 0, text_anchorYOffset = y or 0,
    text_shadowColor = { 0, 0, 0, 1 }, text_shadowXOffset = 1, text_shadowYOffset = -1, rotateText = "NONE",
    text_automaticWidth = "Auto", text_fixedWidth = 64, text_wordWrap = "WordWrap" }
end
local function glowSub(gtype)
  return { type = "subglow", glow = false, glowType = gtype or "buttonOverlay", useGlowColor = false,
    glowColor = { 1, 1, 1, 1 }, glowLines = 8, glowFrequency = 0.25, glowLength = 10, glowThickness = 1,
    glowScale = 1, glowBorder = false, glowXOffset = 0, glowYOffset = 0 }
end
local ANIM = { start = { type = "none", duration_type = "seconds", easeType = "none", easeStrength = 3 },
               main = { type = "none", duration_type = "seconds", easeType = "none", easeStrength = 3 },
               finish = { type = "none", duration_type = "seconds", easeType = "none", easeStrength = 3 } }

-- Rage bar. v1.6 halved it (80 x 5 px, was 160 x 10) and removed the swing timer that sat under it.
local BAR_W = 80
local RAGE_Y, RAGE_H = 62, 5
local MODE_TOP = RAGE_Y - RAGE_H / 2
local function icon(id, size, x, y, pick, withMode)
  -- Glow sits right after the background, so the text draws on top of it.
  local subs = { { type = "subbackground" }, glowSub(size >= 50 and "buttonOverlay" or "Pixel") }
  local g = 2
  subs[#subs + 1] = text("%keybind", "INNER_BOTTOMRIGHT", size >= 50 and 16 or 12, -1, 1, nil, "THICKOUTLINE")
  if size >= 34 then subs[#subs + 1] = text("%tag", "INNER_TOPLEFT", size >= 50 and 10 or 8, 1, -1, { 0.6, 0.9, 1, 1 }, "OUTLINE") end
  if withMode then
    -- Centred in the gap between the icon top (+size/2) and the bottom of the rage bar.
    local m = text("%mode", "CENTER", 14, 0, (size / 2 + MODE_TOP) / 2, { 1, 0.82, 0, 1 }, "THICKOUTLINE")
    m.text_selfPoint = "CENTER"
    subs[#subs + 1] = m
    -- Cast just landed: autocast shine for 0.4 s after a suggested spell goes off (subregion 3).
    local shine = glowSub("ACShine")
    shine.useGlowColor = true; shine.glowColor = { 1, 1, 1, 1 }; shine.glowLines = 10; shine.glowFrequency = 0.6; shine.glowScale = 1.2
    table.insert(subs, 3, shine)
  end
  return {
    id = id, uid = id:gsub("%W", ""), parent = GROUP, regionType = "icon", internalVersion = INTERNAL, tocversion = TOC,
    width = size, height = size, xOffset = x, yOffset = y, selfPoint = "CENTER", anchorPoint = "CENTER",
    anchorFrameType = "SCREEN", frameStrata = 1, icon = true, iconSource = -1, desaturate = false, zoom = 0.1,
    keepAspectRatio = false, color = { 1, 1, 1, 1 }, alpha = 1, inverse = false, cooldown = true,
    cooldownTextDisabled = false, cooldownSwipe = true, cooldownEdge = false, useCooldownModRate = true,
    progressSource = { -1, "" }, adjustedMax = "", adjustedMin = "",
    subRegions = subs,
    triggers = trig(iconTSU(pick), ICONVARS),
    conditions = {
      { check = { trigger = 1, variable = "glow", value = 1 }, changes = { { property = "sub." .. g .. ".glow", value = true } } },
      { check = { trigger = 1, variable = "waiting", value = 1 }, changes = { { property = "desaturate", value = true } } },
      { check = { trigger = 1, variable = "oor", value = 1 }, changes = { { property = "desaturate", value = true } } },
      { check = { trigger = 1, variable = "oorTint", value = 1 }, changes = { { property = "color", value = { 1, 0.35, 0.35, 1 } } } },
      withMode and { check = { trigger = 1, variable = "flash", value = 1 }, changes = { { property = "sub.3.glow", value = true } } } or nil,
    },
    load = LOADFOR(), actions = { init = {}, start = {}, finish = {} },
    animation = ANIM, config = {}, authorOptions = {}, information = {},
  }
end

local children = {}
local nextIcon = icon("SWR Next", 56, 0, 0, "R.next", true)
nextIcon.actions.init = { do_custom = true, custom = ENGINE }
nextIcon.authorOptions = {
  { type = "number", key = "aoe", name = "AoE threshold (enemies)", default = 3, min = 2, max = 10, step = 1, width = 1, useDesc = true, desc = "Nameplate enemies within ~8 yd that switch the Next icon to AoE priority. Fury also adds Whirlwind / Cleave at 2+." },
  { type = "select", key = "protMode", name = "Protection mode", values = { "Auto", "Tank", "DPS" }, default = 1, width = 1, useDesc = true, desc = "Auto = Tank when in Defensive Stance, grouped as TANK or holding threat on the target. Tank mode adds Shield Block / Barrier, Demoralizing Shout and the Weakened Blows check." },
  { type = "select", key = "amMode", name = "Prot active mitigation", values = { "Auto (Block first)", "Block only", "Barrier first (magic)" }, default = 1, width = 1, useDesc = true, desc = "Auto: Shield Block when it is down, Shield Barrier with 90+ rage once Block is covered. Barrier first: for magic-heavy fights." },
  { type = "select", key = "fuMode", name = "Fury weapons", values = { "Auto (read weapons)", "Titan's Grip", "Single-Minded Fury" }, default = 1, width = 1, useDesc = true, desc = "Auto reads your off hand: two-hander = Titan's Grip, one-hander = Single-Minded Fury. SMF ranks Bloodsurge Wild Strike above Raging Blow." },
  { type = "select", key = "shout", name = "Shout for rage", values = { "Battle Shout", "Commanding Shout" }, default = 1, width = 1, useDesc = true, desc = "Which shout the rotation suggests as a rage generator (both share one 60 s cooldown). Pick the one your group is missing." },
  { type = "select", key = "dpsStance", name = "Arms/Fury stance", values = { "Battle Stance", "Berserker Stance" }, default = 1, width = 1, useDesc = true, desc = "Stance the left side reminds you to use as Arms or Fury." },
  { type = "number", key = "dumpMargin", name = "Rage dump margin", default = 20, min = 0, max = 60, step = 5, width = 1, useDesc = true, desc = "Heroic Strike / Cleave is suggested when rage is within this much of max rage." },
  { type = "number", key = "slamRage", name = "Arms: Slam outside CS at rage", default = 80, min = 30, max = 120, step = 5, width = 1 },
  { type = "number", key = "wildRage", name = "Fury: Wild Strike filler at rage", default = 70, min = 30, max = 120, step = 5, width = 1 },
  { type = "toggle", key = "sunder", name = "Track Sunder Armor (Weakened Armor)", default = true, width = 1, useDesc = true, desc = "On: you keep Weakened Armor up (you're tanking, or you're the one assigned to it). Sunder Armor is suggested when the target's Weakened Armor (from anyone) is missing, under 3 stacks or under 5 s left, and the Sunder icon next to the trackers shows its stacks and time. Off: someone else applies it (tank, Feral druid, Rogue), so you never get a Sunder prompt." },
  { type = "toggle", key = "showOff", name = "Show off-GCD icon (Heroic Strike / Cleave)", default = true, width = 1 },
  { type = "toggle", key = "showDef", name = "Show defensives / stance (left)", default = true, width = 1 },
  { type = "toggle", key = "showCDs", name = "Show offensive cooldowns (right)", default = true, width = 1 },
  { type = "toggle", key = "showKeys", name = "Show keybinds", default = true, width = 1 },
  { type = "toggle", key = "tintOOR", name = "Red tint when out of range", default = true, width = 1, useDesc = true, desc = "Out-of-range icons are always desaturated; this also tints them red so they differ from GCD/rage grey." },
  { type = "toggle", key = "showLast", name = "Show last cast", default = true, width = 1, useDesc = true, desc = "Small icon left of Next+1 showing the spell that just went off (green border = it was the suggested spell)." },
  { type = "toggle", key = "showTray", name = "Show cooldown tray", default = true, width = 1, useDesc = true, desc = "Small icons under the HUD (bottom right, filling leftward) for racials and big cooldowns that are learned and off cooldown. They hide while on cooldown, and never repeat a spell the rotation is already showing." },
  { type = "toggle", key = "showInt", name = "Show interrupts", default = true, width = 1 },
  { type = "toggle", key = "intCC", name = "Include stuns/CC as fallback", default = true, width = 1, useDesc = true, desc = "Storm Bolt, Shockwave, Heroic Throw (Glyph of Gag Order), Quaking Palm, Arcane Torrent, War Stomp when Pummel / Disrupting Shout are on cooldown or out of range." },
  { type = "toggle", key = "intMain", name = "Interrupt in main icon", default = false, width = 1, useDesc = true, desc = "Off = dedicated red interrupt icon above the rage bar. On = the interrupt takes over the Next icon." },
  { type = "toggle", key = "intFocus", name = "Also watch focus casts", default = false, width = 1 },
}
nextIcon.config = { aoe = 3, protMode = 1, amMode = 1, fuMode = 1, shout = 1, dpsStance = 1, dumpMargin = 20, slamRage = 80, wildRage = 70, sunder = true,
  showOff = true, showDef = true, showCDs = true, showKeys = true, tintOOR = true, showLast = true, showTray = true, showInt = true, intCC = true, intMain = false, intFocus = false }
children[#children + 1] = nextIcon
children[#children + 1] = icon("SWR Next+1", 34, 0, -50, "R.next2", false)
local off = icon("SWR Off-GCD", 34, 40, -50, "R.off", false)
off.subRegions[#off.subRegions + 1] = text("off-GCD", "OUTER_BOTTOM", 8, 0, -1, { 0.8, 0.8, 0.8, 1 }, "OUTLINE")
children[#children + 1] = off
local lastIcon = icon("SWR Last Cast", 26, -40, -50, "R.last", false)
lastIcon.subRegions[#lastIcon.subRegions + 1] = text("last", "OUTER_BOTTOM", 8, 0, -1, { 0.8, 0.8, 0.8, 1 }, "OUTLINE")
lastIcon.subRegions[#lastIcon.subRegions + 1] = { type = "subborder", border_visible = false, border_edge = "Square Full White",
  border_color = { 0.2, 1, 0.3, 1 }, border_offset = 1, border_size = 2 }
lastIcon.cooldownTextDisabled = true
lastIcon.conditions = { { check = { trigger = 1, variable = "glow", value = 1 }, changes = { { property = "sub." .. #lastIcon.subRegions .. ".border_visible", value = true } } } }
children[#children + 1] = lastIcon
for i = 1, 3 do children[#children + 1] = icon("SWR Defensive " .. i, 36, -12 - 40 * i, 0, "R.left and R.left[" .. i .. "]", false) end
for i = 1, 3 do children[#children + 1] = icon("SWR Cooldown " .. i, 36, 12 + 40 * i, 0, "R.right and R.right[" .. i .. "]", false) end


local function textAura(id, field, x, y, size)
  return {
    id = id, uid = id:gsub("%W", ""), parent = GROUP, regionType = "text", internalVersion = INTERNAL, tocversion = TOC,
    displayText = "%" .. field, outline = "OUTLINE", color = { 1, 1, 1, 1 }, justify = "CENTER",
    selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN", xOffset = x, yOffset = y,
    font = FONT, fontSize = size, frameStrata = 1, customTextUpdate = "event",
    automaticWidth = "Auto", fixedWidth = 200, wordWrap = "WordWrap", shadowColor = { 0, 0, 0, 1 }, shadowXOffset = 1, shadowYOffset = -1,
    subRegions = { { type = "subbackground" } },
    triggers = trig(textTSU(field), "{ " .. field .. " = 'string' }"),
    conditions = {}, load = LOADFOR(), actions = { init = {}, start = {}, finish = {} },
    animation = ANIM, config = {}, authorOptions = {}, information = {},
  }
end
children[#children + 1] = textAura("SWR Resources", "res", 0, 76, 12)

local function bar(id, w, h, x, y, color, bg)
  return {
    id = id, uid = id:gsub("%W", ""), parent = GROUP, regionType = "aurabar", internalVersion = INTERNAL, tocversion = TOC,
    width = w, height = h, xOffset = x, yOffset = y, selfPoint = "CENTER", anchorPoint = "CENTER", anchorFrameType = "SCREEN",
    texture = "Blizzard", textureSource = "LSM", orientation = "HORIZONTAL", inverse = false, icon = false, iconSource = -1,
    barColor = color, barColor2 = { 1, 1, 0, 1 }, backgroundColor = bg or { 0, 0, 0, 0.5 }, enableGradient = false,
    gradientOrientation = "HORIZONTAL", spark = false, frameStrata = 1, zoom = 0, alpha = 1, desaturate = false,
    progressSource = { -1, "" }, adjustedMax = "", adjustedMin = "",
    subRegions = { { type = "subbackground" }, { type = "subforeground" } },
    conditions = {}, load = LOADFOR(), actions = { init = {}, start = {}, finish = {} },
    animation = ANIM, config = {}, authorOptions = {}, information = {},
  }
end
local function border(r, g, b) return { type = "subborder", border_visible = true, border_edge = "Square Full White",
  border_color = { r or 0, g or 0, b or 0, 1 }, border_offset = 1, border_size = 1, anchor_area = "bar" } end

-- Rage bar. Turns orange when Heroic Strike or Cleave should dump rage. Since v1.6 it only shows in combat, and only with rage above 0.
local RAGE_TSU = HEAD .. [[
  local r = R.show and R.rage
  if not r or not (R.S and R.S.combat) or not (r.v > 0) then -- luacheck: ignore 581
]] .. hide() .. [[

  end
  local st = allstates[""]
  if st and st.show and st.value == r.v and st.total == r.max and st.dump == r.dump then return false end
  allstates[""] = { show = true, changed = true, progressType = "static", value = r.v, total = r.max, autoHide = false,
    dump = r.dump and true or false, ragetext = tostring(r.v) }
  return true
end]]
local rb = bar("SWR Rage", BAR_W, RAGE_H, 0, RAGE_Y, { 0.85, 0.15, 0.1, 1 }, { 0.12, 0.12, 0.12, 0.85 })
rb.subRegions[#rb.subRegions + 1] = border()
-- The bar is too thin for text inside. The rage number sits just to the right of it. The red bar is the label.
rb.subRegions[#rb.subRegions + 1] = text("%ragetext", "OUTER_RIGHT", 8, 3, 0)
rb.triggers = trig(RAGE_TSU, "{ dump = 'bool', value = true, total = true, ragetext = 'string' }")
rb.conditions = { { check = { trigger = 1, variable = "dump", value = 1 }, changes = { { property = "barColor", value = { 1, 0.55, 0.05, 1 } } } } }
children[#children + 1] = rb

-- Interrupt icon (red pixel glow, red border, swipe for the cast time) and the cast bar.
local INT_TSU = HEAD .. [[
  local e = R.show and R.int and not (E.cfg and E.cfg.intMain) and R.int
  if not e then
]] .. hide() .. [[

  end
  allstates[""] = { show = true, changed = true, icon = e.icon, name = e.name, keybind = e.key or "",
    castName = e.castName or "", unit = e.unit, oor = e.oor and true or false, oorTint = e.oorTint and true or false, progressType = "timed", duration = e.castDur or 0,
    expirationTime = e.castEnd or 0, autoHide = false, glow = true, waiting = false }
  return true
end]]
local INTBAR_TSU = INT_TSU:gsub("icon = e.icon, name = e.name,", "icon = e.castIcon or e.icon, name = e.castName,")
local INT_Y = 126
local ii = icon("SWR Interrupt", 44, 0, INT_Y, "R.int", false)
ii.triggers = trig(INT_TSU, "{ castName = 'string', keybind = 'string', oor = 'bool', oorTint = 'bool', expirationTime = true, duration = true }")
ii.subRegions[2].glowType = "Pixel"; ii.subRegions[2].useGlowColor = true; ii.subRegions[2].glowColor = { 1, 0.1, 0.1, 1 }
ii.subRegions[2].glowLines = 10; ii.subRegions[2].glowThickness = 2; ii.subRegions[2].glowFrequency = 0.4
ii.subRegions[2].glow = true
ii.subRegions[#ii.subRegions + 1] = { type = "subborder", border_visible = true, border_edge = "Square Full White",
  border_color = { 1, 0.1, 0.1, 1 }, border_offset = 1, border_size = 2 }
ii.subRegions[#ii.subRegions + 1] = text("KICK", "OUTER_TOP", 12, 0, 2, { 1, 0.25, 0.25, 1 }, "THICKOUTLINE")
ii.conditions = { ii.conditions[3], ii.conditions[4] }
ii.cooldownTextDisabled = true
children[#children + 1] = ii
local ib = bar("SWR Interrupt Cast", 120, 10, 0, INT_Y - 28, { 1, 0.3, 0.2, 1 }, { 0, 0, 0, 0.6 })
ib.triggers = trig(INTBAR_TSU, "{ castName = 'string', expirationTime = true, duration = true }")
ib.subRegions[#ib.subRegions + 1] = text("%castName", "INNER_LEFT", 9, 2, 0)
ib.subRegions[#ib.subRegions + 1] = text("%p", "INNER_RIGHT", 9, -2, 0)
children[#children + 1] = ib

-- Buff and debuff trackers. Four small icons. What they show follows your spec (see the README).
local function trkTSU(i, pick)
  return HEAD .. [[
  local t = ]] .. (pick or ("R.show and R.trk and R.trk[" .. i .. "]")) .. [[

  if not t then
]] .. hide() .. [[

  end
  local st = allstates[""]
  if st and st.show and st.icon == t.icon and st.expirationTime == t.exp and st.stacks == t.stacks and st.alert == t.alert and st.inactive == not t.active then return false end
  allstates[""] = { show = true, changed = true, icon = t.icon, name = t.name, label = t.label, stacks = t.stacks,
    inactive = not t.active, alert = t.alert and true or false, progressType = "timed",
    duration = t.active and t.dur or 0, expirationTime = t.active and t.exp or 0, autoHide = false }
  return true
end]]
end
local TRK_Y, TRK_S = -90, 28
local TRK_LABEL = 9
local function trackerIcon(id, x, tsu)
  local t = icon(id, TRK_S, x, TRK_Y, "nil", false)
  t.subRegions = { { type = "subbackground" }, glowSub("Pixel"),
    text("%stacks", "INNER_BOTTOMRIGHT", 11, -1, 1, nil, "THICKOUTLINE"),
    text("%label", "OUTER_BOTTOM", TRK_LABEL, 0, -1, { 0.9, 0.9, 0.9, 1 }, "OUTLINE") }
  t.subRegions[2].useGlowColor = true; t.subRegions[2].glowColor = { 1, 0.15, 0.15, 1 }
  t.triggers = trig(tsu, "{ inactive = 'bool', alert = 'bool', stacks = 'string', label = 'string', expirationTime = true, duration = true }")
  t.conditions = {
    { check = { trigger = 1, variable = "inactive", value = 1 }, changes = { { property = "desaturate", value = true }, { property = "alpha", value = 0.45 } } },
    { check = { trigger = 1, variable = "alert", value = 1 }, changes = { { property = "sub.2.glow", value = true }, { property = "alpha", value = 1 } } },
  }
  return t
end
for i = 1, 4 do children[#children + 1] = trackerIcon("SWR Tracker " .. i, (i - 2.5) * (TRK_S + 4), trkTSU(i)) end
-- v1.7 layout. The tracker labels (OUTER_BOTTOM, 1 px under the icon, 9 pt) end about 12 px below the icons, and
-- the old bar row at y -118 (top edge -112) covered them in game. The bars now start GAP px under the label bottom.
-- Shield Barrier keeps its 3 px gap under Shield Block, and the tray moves down to stay GAP px under the lowest bar.
local GAP = 6
local LABEL_BOTTOM = TRK_Y - TRK_S / 2 - 1 - (TRK_LABEL + 3)  -- comes out to -117
local BAR_H = 12
local BAR1_Y = LABEL_BOTTOM - GAP - BAR_H / 2                  -- -129 (Colossus Smash or Shield Block)
local BAR2_Y = BAR1_Y - BAR_H - 3                              -- -144 (Shield Barrier)

-- Timed bars: the Colossus Smash window (Arms and Fury, once CS is learned), and Shield Block / Shield Barrier (Protection, once learned).
local function timedTSU(field, label, extra)
  return HEAD .. [[
  local s = R.show and R.]] .. field .. [[

  if not s then
]] .. hide() .. [[

  end
  local up = s.rem > 0
  local txt = ]] .. extra .. [[

  local st = allstates[""]
  local exp = up and s.exp or 0
  if st and st.show and st.expirationTime == exp and st.label == txt then return false end
  allstates[""] = { show = true, changed = true, name = "]] .. label .. [[", label = txt,
    progressType = up and "timed" or "static", value = 0, total = 1,
    duration = up and ((s.dur and s.dur > 0) and s.dur or 1) or 0, expirationTime = exp, autoHide = false, up = up }
  return true
end]]
end
local function timedBar(id, y, color, field, label, extra)
  local b = bar(id, 160, 12, 0, y, color, { 0, 0, 0, 0.5 })
  b.subRegions[#b.subRegions + 1] = border()
  b.subRegions[#b.subRegions + 1] = text("%label", "INNER_LEFT", 10, 2, 0)
  b.subRegions[#b.subRegions + 1] = text("%p", "INNER_RIGHT", 10, -2, 0)
  b.triggers = trig(timedTSU(field, label, extra), "{ up = 'bool', label = 'string', expirationTime = true, duration = true }")
  return b
end
children[#children + 1] = timedBar("SWR Colossus Smash", BAR1_Y, { 0.9, 0.2, 0.15, 1 }, "cs", "Colossus Smash",
  [[up and "Colossus Smash" or ((s.cd or 0) > 0.25 and string.format("CS in %.0fs", s.cd) or "CS READY")]])
children[#children + 1] = timedBar("SWR Shield Block", BAR1_Y, { 0.3, 0.55, 1, 1 }, "sblock", "Shield Block",
  [[string.format("Shield Block (%d)", s.charges or 0)]])
children[#children + 1] = timedBar("SWR Shield Barrier", BAR2_Y, { 0.95, 0.8, 0.2, 1 }, "sbar", "Shield Barrier",
  [[(up and s.amount) and string.format("Barrier %.1fk", s.amount / 1000) or "Shield Barrier"]])

-- Cooldown tray, added last so the children already there keep their order. 8 fixed slots of 32 px (57% of the 56 px Next icon), 36 px apart, in one row under the whole HUD.
-- Slot 1 lines up with the right edge of SWR Cooldown 3 (x +150) and the row fills to the left. The engine packs
-- only ready spells into slots 1..n, so the icons you can see always sit together from the right.
local TRAY_SIZE, TRAY_STEP, TRAY_RIGHT = 32, 36, 150
local TRAY_Y = BAR2_Y - BAR_H / 2 - GAP - TRAY_SIZE / 2         -- comes out to -172
for i = 1, 8 do
  local t = icon("SWR Tray " .. i, TRAY_SIZE, TRAY_RIGHT - TRAY_SIZE / 2 - TRAY_STEP * (i - 1), TRAY_Y, "R.tray and R.tray[" .. i .. "]", false)
  t.cooldownTextDisabled = true
  t.subRegions[#t.subRegions + 1] = { type = "subborder", border_visible = true, border_edge = "Square Full White",
    border_color = { 0, 0, 0, 0.8 }, border_offset = 0, border_size = 1 }
  children[#children + 1] = t
end

-- v1.7 Sunder Armor icon, added after the tray so every child already there keeps its order. One tracker-style icon
-- to the right of the four trackers, same row and same style. Arms, Fury, and Leveling only, and only while the option is on.
children[#children + 1] = trackerIcon("SWR Sunder", 2.5 * (TRK_S + 4), trkTSU(0, "R.show and R.sunder"))

-- Default position: CENTER of the group on the screen's CENTER, 0 px across, 40 px down.
-- Child offsets are relative to the group, so they don't move.
local group = {
  id = GROUP, uid = "SchizzleWarriorGroup", regionType = "group", internalVersion = INTERNAL, tocversion = TOC,
  controlledChildren = {}, anchorPoint = "CENTER", selfPoint = "CENTER", anchorFrameType = "SCREEN",
  xOffset = 0, yOffset = -40, frameStrata = 1, border = false, borderColor = { 0, 0, 0, 1 }, backdropColor = { 1, 1, 1, 0.5 },
  borderEdge = "Square Full White", borderOffset = 4, borderInset = 1, borderSize = 2, borderBackdrop = "Blizzard Tooltip",
  -- v1.6: group scale 0.8 and group alpha 0.8. Those are the group's own options. Children keep their sizes and scale with it.
  scale = 0.8, alpha = 0.8, subRegions = {},
  triggers = { activeTriggerMode = -10, { trigger = { type = "aura2", names = {}, event = "Health", subeventPrefix = "SPELL",
    subeventSuffix = "_CAST_START", spellIds = {}, unit = "player", debuffType = "HELPFUL" }, untrigger = {} } },
  conditions = {}, load = LOADFOR(), actions = { init = {}, start = {}, finish = {} }, animation = ANIM,
  config = {}, authorOptions = {},
  information = { saved = true },
  desc = "Schizzle's Warrior Rotation: all-in-one Arms / Fury (TG + SMF) / Protection rotation helper for MoP Classic. Switches with your spec automatically, with a Leveling mode before level 10 and a GCD swipe. v" .. RELEASE .. ".",
}
for _, c in ipairs(children) do group.controlledChildren[#group.controlledChildren + 1] = c.id end

local transmit = { m = "d", d = group, c = children, v = 1421, s = VER }
local ser = LibSerialize:SerializeEx({ errorOnUnserializableType = false }, transmit)
local comp = LibDeflate:CompressDeflate(ser, { level = 9 })
local out = "!WA:2!" .. LibDeflate:EncodeForPrint(comp)
local f = assert(io.open(OUT, "w")) f:write(out) f:close()
-- If WA_SNIP is set, dump each custom snippet so luac can check it.
local SNIP = os.getenv("WA_SNIP")
local n = 0
if SNIP then
  os.execute("mkdir -p '" .. SNIP .. "'")
  local function dump(name, code) n = n + 1 local h = assert(io.open(SNIP .. "/" .. name .. ".lua", "w")) h:write("return " .. code) h:close() end
  for _, c in ipairs(children) do
    local tag = c.id:gsub("%W", "")
    dump(tag .. "_tsu", c.triggers[1].trigger.custom)
    dump(tag .. "_vars", c.triggers[1].trigger.customVariables)
  end
end
print("wrote", OUT, "bytes", #out, "children", #children, "snippets", n)
