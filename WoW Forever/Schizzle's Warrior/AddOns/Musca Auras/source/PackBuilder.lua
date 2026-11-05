-- Pack builder for Schizzle's Warrior Essentials (Musca Auras on WoW Forever).
--
-- Derived from Tests/Packs/PackBuilder.lua in Musca Auras v1.14.0 by dldvlpr and the WeakAuras Team
-- (https://github.com/dldvlpr-addons-wow/Musca-Auras), which is licensed under the GNU General Public License v2.
-- This file is a modified copy and stays under the same licence: see ../LICENSE-GPL-2.0.txt.
--
-- Changes by Jon Shaw (Schizzle), Nov 2026:
--   * the ForeverAuras variant is removed (this pack is for Musca Auras only)
--   * the root group's name, place and font come from the spec (the repo's layout rules: centre 0,-55,
--     Fira Sans Condensed Medium, version in the group name)
--   * the row heights come from the spec, so the whole pack stays inside the HUD box
--   * "lanes": one priority row per talent tree; corner labels show the real action-bar keybind (dynamic lookup), dimmed while the spell can't be used
--   * debuffs in a lane glow while they are missing from the target
--   * rage colour steps: a grey low mark on the bar and coloured copies laid over it at higher percents
--   * target debuffs and the stance get their own row, and the aura rows can be capped
--   * a sound on proc alerts, and a "below this level" load option
local Pack = {}
local FOREVER_AURAS = false

local RED = {1, 0.3, 0.3, 1}
local BLUE = {0.4, 0.5, 1, 1}
local FULL = {0.7, 0.3, 1, 1}
local POWER_COLORS = {
  [0] = {0, 0.44, 0.87, 1}, [1] = {0.78, 0.25, 0.25, 1}, [2] = {1, 0.5, 0.25, 1},
  [3] = {1, 0.96, 0.41, 1}, [4] = {1, 0.82, 0, 1},
}
local SEGMENT_COLORS = {
  {1, 1, 0.2, 1}, {1, 0.8, 0.1, 1}, {1, 0.6, 0.1, 1}, {1, 0.4, 0.1, 1}, {1, 0.15, 0.1, 1},
}

local BORDER = { type = "subborder", border_visible = true, border_size = 1, border_color = {0, 0, 0, 1},
  border_edge = "Square Full White", border_offset = 0 }
local GLOW = { type = "subglow", glow = true, glowType = "Pixel", useGlowColor = false, glowColor = {1, 1, 1, 1},
  glowLines = 8, glowFrequency = 0.25, glowDuration = 1, glowLength = 10, glowThickness = 1, glowScale = 1,
  glowBorder = false, glowXOffset = 0, glowYOffset = 0 }
-- Red pulse lit by the last seconds of an aura.
local BLINK = { type = "subglow", glow = false, glowType = "Proc", useGlowColor = true, glowColor = {1, 0, 0, 1},
  glowLines = 8, glowFrequency = 0.25, glowDuration = 0.5, glowLength = 10, glowThickness = 1, glowScale = 1,
  glowBorder = false, glowXOffset = 0, glowYOffset = 0 }

-- HUD width: 8 main icons of 40 with 2 px gaps. Bars and resource pips use it too.
local WIDTH = 334
local SIZES = {
  reminder = {34, 28}, proc = {30, 22}, aura = {30, 22}, main = {40, 30}, utility = {34, 26}, totem = {30, 22},
}

local TOTEM_ICONS = {
  "Interface\\Icons\\Spell_Fire_SearingTotem", "Interface\\Icons\\Spell_Nature_StoneSkinTotem",
  "Interface\\Icons\\INV_Spear_04", "Interface\\Icons\\Spell_Nature_Windfury",
}

local FONT = "Friz Quadrata TT"

local function Text(text, point, size)
  return {
    type = "subtext", text_text = text, text_color = {1, 1, 1, 1}, text_font = FONT,
    text_fontSize = size or 14, text_fontType = "OUTLINE", text_visible = true, text_justify = "CENTER",
    text_selfPoint = "AUTO", anchor_point = point, anchorXOffset = 0, anchorYOffset = 0,
    text_shadowColor = {0, 0, 0, 1}, text_shadowXOffset = 0, text_shadowYOffset = 0, rotateText = "NONE",
    text_automaticWidth = "Auto", text_fixedWidth = 64, text_wordWrap = "WordWrap",
  }
end

-- Countdown on an icon (Battle Shout remaining, etc.). Built-in timed format: 1:45 | 45 | 5.
-- On secretAura, Musca binds %p through the native duration text; if Forever secrets the value in combat
-- the text stays blank rather than erroring.
local function RemainingText(point, size)
  local text = Text("%p", point or "INNER_BOTTOM", size or 11)
  text.text_text_format_p_format = "timed"
  text.text_text_format_p_time_format = 0
  text.text_text_format_p_time_precision = 1
  text.text_text_format_p_time_dynamic_threshold = 60
  text.text_text_format_p_time_legacy_floor = false
  return text
end

-- Main-lane corner labels: look up the key currently bound to whichever action-bar slot
-- holds this spell (any rank, macros included). Not the priority index. One shared frame
-- marks the cache dirty on ACTIONBAR_SLOT_CHANGED / UPDATE_BINDINGS; rebuild skips secret
-- values and retries out of combat.
local HOTKEY_INIT = [=[
function()
  if _G.SchizzleWA_HotkeyFrame then return end
  local f = CreateFrame("Frame")
  _G.SchizzleWA_HotkeyFrame = f
  _G.SchizzleWA_Hotkeys = { dirty = true }
  f:RegisterEvent("PLAYER_ENTERING_WORLD")
  f:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
  f:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
  f:RegisterEvent("UPDATE_BINDINGS")
  f:RegisterEvent("PLAYER_REGEN_ENABLED")
  f:SetScript("OnEvent", function()
    local c = _G.SchizzleWA_Hotkeys
    if c then c.dirty = true end
  end)
end
]=]

local function HotkeyCustomText(spellId)
  return string.format([=[
function()
  local want = %d
  local cache = _G.SchizzleWA_Hotkeys
  if not cache then return "" end
  if cache.dirty or not cache.map then
    local map, ok = {}, true
    local function firstKey(cmds)
      for i = 1, #cmds do
        local key = GetBindingKey(cmds[i])
        if key and key ~= "" and not (issecretvalue and issecretvalue(key)) then
          return GetBindingText(key, "KEY_", true) or key
        end
      end
    end
    local function cmdsForSlot(slot)
      if slot >= 1 and slot <= 12 then
        return { "ACTIONBUTTON" .. slot, ("CLICK BT4Button%%d:Keybind"):format(slot) }
      elseif slot >= 13 and slot <= 24 then
        return { ("CLICK BT4Button%%d:Keybind"):format(slot) }
      elseif slot >= 25 and slot <= 36 then
        local i = slot - 24
        return { "MULTIACTIONBAR3BUTTON" .. i, ("CLICK BT4Button%%d:Keybind"):format(slot) }
      elseif slot >= 37 and slot <= 48 then
        local i = slot - 36
        return { "MULTIACTIONBAR4BUTTON" .. i, ("CLICK BT4Button%%d:Keybind"):format(slot) }
      elseif slot >= 49 and slot <= 60 then
        local i = slot - 48
        return { "MULTIACTIONBAR2BUTTON" .. i, ("CLICK BT4Button%%d:Keybind"):format(slot) }
      elseif slot >= 61 and slot <= 72 then
        local i = slot - 60
        return { "MULTIACTIONBAR1BUTTON" .. i, ("CLICK BT4Button%%d:Keybind"):format(slot) }
      elseif slot >= 73 and slot <= 120 then
        return { ("CLICK BT4Button%%d:Keybind"):format(slot) }
      end
      return {}
    end
    local function note(spell, slot)
      if not spell or spell == 0 then return end
      if issecretvalue and issecretvalue(spell) then ok = false; return end
      local text = firstKey(cmdsForSlot(slot))
      if not text then return end
      map[spell] = text
      local name = GetSpellInfo(spell)
      if name and not (issecretvalue and issecretvalue(name)) then map[name] = text end
    end
    for slot = 1, 120 do
      local actionType, id = GetActionInfo(slot)
      if issecretvalue and (issecretvalue(actionType) or issecretvalue(id)) then
        ok = false
        break
      end
      if actionType == "spell" then
        note(id, slot)
      elseif actionType == "macro" and id then
        local sid = GetMacroSpell(id)
        if sid then note(sid, slot) end
      end
    end
    if ok then
      cache.map, cache.dirty = map, false
    end
  end
  local hit = cache.map and cache.map[want]
  if hit then return hit end
  local name = GetSpellInfo(want)
  if name and cache.map then return cache.map[name] or "" end
  return ""
end
]=], spellId)
end

local function ApplyHotkeyLabel(data, spellId)
  if not spellId then return data end
  data.customText = HotkeyCustomText(spellId)
  data.customTextUpdate = "update"
  data.customTextUpdateThrottle = 0.25
  data.actions = data.actions or { start = {}, finish = {}, init = {} }
  data.actions.init = { do_custom = true, custom = HOTKEY_INIT }
  return data
end

local function Animation()
  local step = { duration_type = "seconds", easeStrength = 3, easeType = "none", type = "none" }
  return { start = step, main = step, finish = step }
end

local function Ids(ids)
  local list = {}
  for index, spellId in ipairs(ids) do list[index] = tostring(spellId) end
  return list
end

local function Condition(variable, value, property, change, op)
  return { check = { trigger = 1, variable = variable, value = value, op = op },
    changes = { { property = property, value = change } } }
end

local function Generic(fields)
  fields.names, fields.spellIds, fields.debuffType = {}, {}, "HELPFUL"
  fields.subeventPrefix, fields.subeventSuffix = "SPELL", "_CAST_START"
  fields.unit = fields.unit or "player"
  return fields
end

local function CooldownTrigger(spellId)
  local trigger = Generic({ type = "spell", event = "Cooldown Progress (Spell)", spellName = spellId,
    use_exact_spellName = false, genericShowOn = "showAlways", use_genericShowOn = true,
    use_showgcd = true, use_hidegcdtext = true,
    use_desaturateOnCooldown = true, desaturateOnCooldown = true })
  if FOREVER_AURAS then trigger.use_desaturateOnCooldown, trigger.desaturateOnCooldown = nil, nil end
  return trigger
end

local function AuraTrigger(ids, showOn, unit, kind)
  return { type = "secretAura", unit = unit or "player", debuffType = kind or "HELPFUL",
    useExactSpellId = true, auraspellids = Ids(ids), secretUseSpellIDs = true,
    nativeFilters = { PLAYER = true }, secretShowOn = showOn }
end

local function PowerTrigger(powerType, threshold, above, unit)
  local trigger = Generic({ type = "unit", event = "Power", unit = unit or "player", use_unit = true,
    use_powertype = true, powertype = powerType })
  if threshold then
    trigger.use_nativeThreshold, trigger.nativeThreshold = true, tostring(threshold)
    if above then trigger.use_nativeThresholdAbove = true end
  end
  return trigger
end

local function GateTrigger(powerType)
  local trigger = PowerTrigger(powerType)
  trigger.use_requirePowerType = true
  return trigger
end

-- A number is one form; a list of form indexes loads in any of them.
local function FormTrigger(form)
  if type(form) == "table" then
    local multi = {}
    for _, index in ipairs(form) do multi[index] = true end
    return Generic({ type = "unit", event = "Stance/Form/Aura", use_form = false, form = { multi = multi } })
  end
  return Generic({ type = "unit", event = "Stance/Form/Aura", use_form = true, form = { single = form, multi = {} } })
end

local function OffhandTrigger()
  local weapons = {}
  for subclass = 0, 20 do
    if not ({ [9] = 1, [11] = 1, [12] = 1, [14] = 1, [17] = 1 })[subclass] then weapons[2 * 256 + subclass] = true end
  end
  return Generic({ type = "item", event = "Item Type Equipped", use_itemSlot = true, itemSlot = 17,
    use_itemTypeName = false, itemTypeName = { multi = weapons } })
end

local function TotemTrigger(fields)
  fields.type, fields.event = "spell", "Totem"
  return Generic(fields)
end

function Pack.Build(spec)
  local name, prefix = spec.name, spec.prefix
  local root = spec.root or (name .. " (Musca)")
  local children, groups, uids = {}, {}, {}
  FONT = spec.font or FONT
  local layout = spec.layout or {}
  local function Y(key, default) return layout[key] or default end

  -- Derived from the aura id, not from the creation order: a reimport matches the auras already installed
  -- and updates them in place, even after rows are added or reordered.
  local function Uid(id)
    local hash = 5381
    for index = 1, #id do hash = (hash * 33 + id:byte(index)) % 2147483647 end
    local uid = string.format("%s%08x", prefix, hash)
    assert(not uids[uid], id .. ": uid collides with " .. tostring(uids[uid]))
    uids[uid] = id
    return uid
  end

  local function Load(options)
    local load = { use_class = true, class = { single = spec.class, multi = {} },
      size = { multi = {} }, spec = { multi = {} }, talent = { multi = {} } }
    if options.outOfCombat then load.use_combat = false end
    if options.inCombat then load.use_combat = true end
    if options.known then load.use_spellknown = true load.spellknown = options.known end
    if options.unknown then load.use_not_spellknown = true load.not_spellknown = options.unknown end
    if options.level and options.levelBelow then
      load.use_level, load.level, load.level_operator = true, { tostring(options.level), tostring(options.levelBelow) }, { ">=", "<" }
    elseif options.level then
      load.use_level, load.level, load.level_operator = true, { tostring(options.level) }, { ">=" }
    elseif options.levelBelow then
      load.use_level, load.level, load.level_operator = true, { tostring(options.levelBelow) }, { "<" }
    end
    -- The ForeverAuras format of the specialization option is not verified: it loads in every specialization.
    if options.spec and not FOREVER_AURAS then load.use_forever_spec, load.forever_spec = true, { single = options.spec } end
    return load
  end

  local function Base(id, parent, regionType, trigger, options)
    local triggers = { { trigger = trigger, untrigger = {} }, activeTriggerMode = -10 }
    local required = {}
    if options.gate then required[#required + 1] = GateTrigger(options.gate) end
    if options.form then required[#required + 1] = FormTrigger(options.form) end
    if options.needsPet then required[#required + 1] = Generic({ type = "unit", event = "Conditions", use_HasPet = true }) end
    if options.notResting then required[#required + 1] = Generic({ type = "unit", event = "Conditions", use_resting = false }) end
    if options.offhand then required[#required + 1] = OffhandTrigger() end
    assert(not (FOREVER_AURAS and #required > 0 and options.fallback),
      id .. ": gate, form, pet, rest or offhand and fallback cannot be combined")
    if options.fallback and #required > 0 then
      -- The aura or its cooldown, but only under the requirements; the secret aura falls back on the cooldown only.
      triggers[2] = { trigger = options.fallback, untrigger = {} }
      local terms = {}
      for index, extra in ipairs(required) do
        triggers[index + 2] = { trigger = extra, untrigger = {} }
        terms[index] = tostring(index + 2)
      end
      triggers.disjunctive, triggers.activeTriggerMode = "expression", 1
      triggers.triggerExpression = "(1 or 2) and " .. table.concat(terms, " and ")
      triggers.secretFallback = 2
      required = {}
    elseif options.fallback then
      triggers[2] = { trigger = options.fallback, untrigger = {} }
      triggers.disjunctive, triggers.activeTriggerMode = "any", 1
    end
    -- Second trigger supplies progress (cooldown swirl) only; expression "1" keeps visibility on trigger 1.
    if options.progressTrigger then
      assert(not options.fallback and #required == 0,
        id .. ": progressTrigger cannot combine with gate, form, pet, rest, offhand or fallback")
      triggers[2] = { trigger = options.progressTrigger, untrigger = {} }
      triggers.disjunctive, triggers.activeTriggerMode = "expression", 1
      triggers.triggerExpression = "1"
    end
    for index, extra in ipairs(required) do triggers[index + 1] = { trigger = extra, untrigger = {} } end
    if #required > 0 then triggers.disjunctive, triggers.activeTriggerMode = "all", 1 end
    if trigger.type == "secretAura" and #required > 0 then triggers.secretFallback = "none" end
    local conditions = options.conditions or {}
    if FOREVER_AURAS and trigger.use_nativeThreshold then
      -- ForeverAuras reads an alpha condition on the power percent in combat through a curve.
      local copy = {}
      for index, condition in ipairs(conditions) do copy[index] = condition end
      conditions = copy
      conditions[#conditions + 1] = Condition("percentpower", trigger.nativeThreshold, "alpha", 0,
        trigger.use_nativeThresholdAbove and "<" or ">=")
      trigger.use_nativeThreshold, trigger.nativeThreshold, trigger.use_nativeThresholdAbove = nil, nil, nil
    end
    return {
      id = id, uid = Uid(id), parent = parent, regionType = regionType, internalVersion = 91, tocversion = 16001,
      triggers = triggers, load = Load(options), conditions = conditions, config = {},
      authorOptions = {}, actions = { start = {}, finish = {}, init = {} }, animation = Animation(),
      subRegions = options.subRegions or {},
      information = { forceEvents = true, ignoreOptionsEventErrors = true, showNilIsFalse = true },
    }
  end

  local function Group(label, regionType, yOffset, grow, columns)
    local group = Base(name .. " - " .. label, root, regionType,
      { type = "aura2", unit = "player", debuffType = "HELPFUL", names = {} }, {})
    group.controlledChildren, group.anchorPoint, group.selfPoint = {}, "CENTER", "CENTER"
    group.xOffset, group.yOffset = 0, yOffset
    if grow == "GRID" then
      group.grow, group.gridType, group.gridWidth, group.rowSpace, group.columnSpace = "GRID", "HD", columns, 2, 2
      group.selfPoint, group.sort, group.useLimit = "TOP", "none", false
    elseif regionType == "dynamicgroup" then
      group.grow, group.align, group.space, group.stagger, group.sort = grow or "HORIZONTAL", "CENTER", 3, 0, "none"
    elseif grow ~= "FIXED" then
      group.blizzardFlow, group.blizzardFlowGrowth, group.blizzardFlowSpacing = true, grow or "CENTER_HORIZONTAL", 3
    end
    groups[#groups + 1] = { group = group, members = {} }
    return groups[#groups]
  end

  -- Hangs a row under another one: the row follows when the target grows a second line.
  -- A target without members is not exported, so the row keeps its fixed place.
  local function Below(holder, target, yOffset)
    if #target.members == 0 then return end
    local group = holder.group
    group.anchorFrameType, group.anchorFrameFrame = "SELECTFRAME", "WeakAuras:" .. target.group.id
    group.anchorFrameParent, group.anchorPoint, group.selfPoint, group.yOffset = false, "BOTTOM", "TOP", yOffset
  end

  local function Add(holder, data)
    data.parent = holder.group.id
    holder.group.controlledChildren[#holder.group.controlledChildren + 1] = data.id
    holder.members[#holder.members + 1] = data
    return data
  end

  local outOfRange = Condition("spellInRange", 0, "color", RED)
  local noMana = Condition("insufficientResources", 1, "color", BLUE)
  local idle = { check = { trigger = -2, variable = "AND", checks = {
      { trigger = -1, variable = "incombat", value = 0 }, { trigger = -1, variable = "hastarget", value = 0 } } },
    changes = { { property = "alpha", value = 0.4 } } }

  local function Requirements(entry, options)
    options.known = options.known or entry.known or entry.spell
    options.unknown, options.form, options.level, options.warn = entry.unknown, entry.form, entry.level, entry.warn
    options.levelBelow = options.levelBelow or entry.levelBelow
    options.gate, options.offhand, options.flash = options.gate or entry.gate, entry.offhand, entry.flash
    options.needsPet = entry.needsPet
    options.texture, options.spec = entry.texture, entry.spec
    return options
  end

  local function Icon(holder, label, trigger, options)
    local subRegions, conditions = {}, {}
    for index, subRegion in ipairs(options.subRegions or {}) do subRegions[index] = subRegion end
    for index, condition in ipairs(options.conditions or {}) do conditions[index] = condition end
    subRegions[#subRegions + 1] = BORDER
    if options.missing then
      local missing = Condition("faAuraMissing", nil, "desaturate", true)
      missing.changes[2] = { property = "color", value = {1, 1, 1, 0.5} }
      conditions[#conditions + 1] = missing
    end
    if trigger.type == "secretAura" and trigger.secretShowOn ~= "showOnMissing" then
      -- Flash and blink both glow on a time window, and an aura holds only one such glow: the blink wins.
      local flash = not options.warn and options.flash
      if options.missingGlow and not options.pandemic then
        -- A debuff in a priority lane: the glow lights while it is missing from the target, a call to put it up.
        local glow = {}
        for key, value in pairs(GLOW) do glow[key] = value end
        glow.glow = false
        subRegions[#subRegions + 1] = glow
        conditions[#conditions + 1] = Condition("faAuraMissing", nil, "sub." .. #subRegions .. ".glow", true)
      elseif options.pandemic then
        -- Off by default: lit by the refresh window, and by a missing DoT when the icon allows it.
        local glow = {}
        for key, value in pairs(GLOW) do glow[key] = value end
        glow.glow = false
        subRegions[#subRegions + 1] = glow
        conditions[#conditions + 1] = Condition("faAuraPandemic", nil, "sub." .. #subRegions .. ".glow", true)
        if options.missing or options.missingGlow then
          conditions[#conditions + 1] = Condition("faAuraMissing", nil, "sub." .. #subRegions .. ".glow", true)
        end
      elseif flash or (options.glow ~= false and not options.flash) then
        subRegions[#subRegions + 1] = GLOW
        -- ForeverAuras rejects an Elapsed Time condition on a glow: the glow stays on while the aura is up.
        if flash and not FOREVER_AURAS then
          conditions[#conditions + 1] = Condition("faAuraElapsed", flash, "sub." .. #subRegions .. ".glow", true, "<")
        end
        if options.fallback or options.missing then
          conditions[#conditions + 1] = Condition("faAuraMissing", nil, "sub." .. #subRegions .. ".glow", false)
        end
      end
      if options.warn then
        subRegions[#subRegions + 1] = BLINK
        conditions[#conditions + 1] = Condition("faAuraRemaining", options.warn, "sub." .. #subRegions .. ".glow", true, "<")
      end
    end
    if options.idle then conditions[#conditions + 1] = idle end
    if FOREVER_AURAS and trigger.event == "Cooldown Progress (Spell)" then
      conditions[#conditions + 1] = Condition("onCooldown", 1, "desaturate", true)
    end
    options.subRegions, options.conditions = subRegions, conditions
    local data = Base(name .. " - " .. label, nil, "icon", trigger, options)
    data.width, data.height, data.keepAspectRatio = options.size[1], options.size[2], true
    data.iconSource, data.displayIcon = -1, options.texture
    data.cooldown, data.cooldownTextDisabled, data.cooldownSwipe = true, true, true
    data.desaturate, data.color, data.zoom = false, {1, 1, 1, 1}, 0.3
    if options.progressTrigger then
      -- Dynamic info from trigger 2 (Swing Timer): radial countdown over the icon.
      data.progressSource = { 2, "expirationTime" }
    end
    return Add(holder, data)
  end

  local function SpellIcon(holder, entry, size)
    -- ForeverAuras cannot combine a requirement with the fallback: its buff stays a separate icon (foreverAurasOnly).
    local required = entry.gate or entry.form or entry.needsPet or entry.offhand
    if entry.aura and not (FOREVER_AURAS and required) then
      local unit = entry.unit or "player"
      assert(({ player = 1, target = 1, focus = 1, pet = 1, targettarget = 1, focustarget = 1 })[unit],
        entry.name .. ": unit without fallback")
      assert(not (entry.kind == "HARMFUL" and (unit == "player" or unit == "pet")), entry.name .. ": debuff on self")
      return Icon(holder, entry.name, AuraTrigger(entry.aura, "showAlways", entry.unit, entry.kind),
        Requirements(entry, { size = size, fallback = CooldownTrigger(entry.spell),
        idle = true }))
    end
    return Icon(holder, entry.name, CooldownTrigger(entry.spell),
      Requirements(entry, { size = size, conditions = { noMana, outOfRange }, idle = true }))
  end

  local function AuraIcon(holder, label, entry, unit, kind, noGlow)
    local subRegions = {}
    if entry.stacks then subRegions[#subRegions + 1] = Text("%s", "INNER_BOTTOMRIGHT", 12) end
    if entry.remaining then subRegions[#subRegions + 1] = RemainingText("INNER_BOTTOM", 11) end
    local options = Requirements(entry, { size = SIZES.aura, subRegions = subRegions, missing = entry.missing,
      glow = not noGlow and entry.glow })
    -- A flash aura (a proc) blinks only when asked: it is spent before it expires.
    options.warn = options.warn or not options.flash and 3 or nil
    -- A DoT glows when it can be refreshed. A tracked missing DoT loads in combat only:
    -- native aura conditions cannot be combined with the combat state.
    options.pandemic = kind == "HARMFUL" and not noGlow and entry.dot
    assert(not entry.missing or options.pandemic, label .. ": a tracked missing debuff must be a DoT")
    assert(not entry.missing or options.known ~= nil or options.level, label .. ": a tracked missing DoT needs known or level")
    -- Other debuffs (Sunder Armor, Judgements, curses) do not glow.
    if kind == "HARMFUL" and not options.pandemic and entry.glow == nil then options.glow = false end
    options.inCombat = options.pandemic and entry.missing
    if entry.totem then
      local data = Icon(holder, label, TotemTrigger({ use_totemType = true, totemType = entry.slot,
        use_totemName = true, totemName = tostring(entry.totem) }), options)
      data.xOffset = -(SIZES.totem[1] + 2)
      return data
    end
    local trigger = AuraTrigger(entry.aura, entry.missing and "showAlways" or "showOnActive", unit, kind)
    if kind == "HARMFUL" and (unit or "player") == "player" then trigger.nativeFilters = nil end
    return Icon(holder, label, trigger, options)
  end

  local function TotemIcon(holder, slot)
    local data = Icon(holder, "Totem " .. slot, TotemTrigger({ use_totemType = true, totemType = slot }),
      { size = SIZES.totem })
    data.triggers[2] = { trigger = TotemTrigger({ use_totemType = true, totemType = slot, use_inverse = true }),
      untrigger = {} }
    data.triggers.disjunctive, data.triggers.activeTriggerMode = "any", 1
    data.displayIcon = TOTEM_ICONS[slot]
    data.conditions[#data.conditions + 1] = { check = { trigger = 2, variable = "show", value = 1 },
      changes = { { property = "desaturate", value = true }, { property = "alpha", value = 0.5 } } }
    return data
  end

  local function Bar(holder, label, trigger, options, color, text, height)
    local data = Base(name .. " - " .. label, nil, "aurabar", trigger, {
      gate = options.gate, known = options.known, offhand = options.offhand, conditions = options.conditions,
      subRegions = { { type = "subbackground" }, { type = "subforeground" },
        Text(text or "%p", "INNER_RIGHT", 11), Text(options.title or label, "INNER_LEFT", 11) },
    })
    data.width, data.height = WIDTH, height
    data.barColor, data.backgroundColor = color, {0, 0, 0, 0.5}
    data.texture, data.orientation, data.icon = "Blizzard", "HORIZONTAL", false
    return Add(holder, data)
  end

  local function Label(holder, label, trigger, text, color, options)
    local data = Base(name .. " - " .. label, nil, "text", trigger, options)
    data.displayText, data.font, data.fontSize, data.outline = text, FONT, spec.reminderSize or 30, "OUTLINE"
    data.color, data.justify = color or {1, 0.82, 0, 1}, "CENTER"
    return Add(holder, data)
  end

  local reminders = Group("Reminders", "dynamicgroup", Y("reminders", 120), "UP")
  for _, entry in ipairs(spec.reminders or {}) do
    -- combat = "in" loads a reminder in combat only, "always" in and out of combat.
    local options = Requirements(entry, { size = SIZES.reminder,
      outOfCombat = not entry.lowPower and not entry.pet and not entry.combat, notResting = not entry.lowPower })
    options.inCombat = entry.combat == "in"
    assert(entry.lowPower or options.known ~= nil or options.level, entry.name .. ": a reminder needs known or level")
    local label, trigger, text, color = "Missing " .. entry.name, nil, "Missing: " .. entry.name, nil
    if entry.aura then
      trigger = AuraTrigger(entry.aura, "showOnMissing")
      trigger.nativeFilters = nil
    elseif entry.enchant then
      trigger = Generic({ type = "item", event = "Weapon Enchant", weapon = entry.enchant, use_weapon = true,
        showOn = "showOnMissing", use_showOn = true })
    elseif entry.item then
      label, text = "Low " .. entry.name, entry.name .. ": %s"
      trigger = Generic({ type = "item", event = "Item Count", itemName = entry.item, use_itemName = true,
        use_count = true, count = tostring(entry.below), count_operator = "<" })
      if entry.icon then options.subRegions = { Text("%s", "INNER_BOTTOMRIGHT", 12) } end
    elseif entry.pet then
      trigger = Generic({ type = "unit", event = "Conditions", use_HasPet = false, use_vehicle = false })
    elseif entry.lowPower then
      label, text, color = entry.name, entry.name, BLUE
      trigger = PowerTrigger(entry.lowPower, entry.below)
    end
    local data = entry.icon and Icon(reminders, label, trigger, options) or Label(reminders, label, trigger, text, color, options)
    -- Display.Validate rejects any animation on a secretAura, and a pulse on the alpha would override the native
    -- threshold of a low power reminder: only the other reminders pulse. A text has no scale, it flashes.
    if not entry.aura and not entry.lowPower then
      data.animation.main = { type = "preset", preset = entry.icon and "pulse" or "alphaPulse", duration_type = "seconds" }
    end
  end

  -- In range reads secret in combat: the text stays shown without alpha, and the condition lights it out of range.
  -- ForeverAuras has no secret range test, its condition never fires: no range text for it.
  local range = Group("Range", "group", Y("range", 160), "FIXED")
  for _, entry in ipairs(not FOREVER_AURAS and spec.meleeRange or {}) do
    local trigger = Generic({ type = "spell", event = "Cooldown Progress (Spell)", spellName = entry.spell,
      use_exact_spellName = false, genericShowOn = "showAlways", use_genericShowOn = true })
    local data = Label(range, "Not in melee range (" .. entry.name .. ")", trigger, "Not in melee range", RED,
      Requirements(entry, { inCombat = true, conditions = { Condition("spellInRange", 0, "alpha", 1) } }))
    data.alpha, data.fontSize = 0, 20
  end

  local procs = Group("Procs", "dynamicgroup", Y("procs", 92))
  for _, entry in ipairs(spec.procs or {}) do
    if entry.usable then
      local data = Icon(procs, entry.name, Generic({ type = "spell", event = "Action Usable", spellName = entry.usable,
        use_exact_spellName = false }), Requirements(entry, { size = SIZES.proc, known = entry.usable, subRegions = { GLOW } }))
      if entry.sound then
        data.actions.start = { do_sound = true, sound = entry.sound, sound_channel = "Master" }
      end
    end
  end

  -- Target debuffs and the stance share one row, your own buffs get the row above it. Each row is capped
  -- (spec.rowLimit icons) so a busy moment can't push it out of the HUD box.
  local target = Group("Target", "group", Y("target", 40))
  local effects = Group("Effects", "group", Y("effects", 66))
  for _, holder in ipairs({ target, effects }) do
    if spec.rowLimit then holder.group.blizzardFlowUseLimit, holder.group.blizzardFlowLimit = true, spec.rowLimit end
  end
  for _, entry in ipairs(spec.debuffs or {}) do
    AuraIcon(target, entry.name .. " (target)", entry, "target", "HARMFUL")
  end
  for _, entry in ipairs(spec.buffs or {}) do
    if FOREVER_AURAS or not entry.foreverAurasOnly then AuraIcon(effects, entry.name, entry, entry.unit, entry.kind) end
  end
  if spec.stance then
    -- Musca puts the stance icon left of the row, outside the HUD box: here it flows at the end of the target row.
    Icon(target, "Stance", Generic({ type = "unit", event = "Stance/Form/Aura" }), { size = SIZES.aura, known = spec.stance })
  end

  local function Pip(count)
    local width = (WIDTH - (count - 1) * 3) / count
    return width, function(index) return (index - (count + 1) / 2) * (width + 3) end
  end

  local segments = Group("Segments", "group", 46)
  if spec.segments then
    local width = Pip(spec.segments.count)
    for count = 1, spec.segments.count do
      local trigger = AuraTrigger(spec.segments.aura, "showOnActive")
      trigger.secretUseStacks, trigger.secretStacksOperator, trigger.secretStacks = true, ">=", count
      local segment = Icon(segments, spec.segments.name .. " " .. count, trigger,
        Requirements(spec.segments, { size = { width, 6 }, glow = false }))
      -- Native stack conditions only colour text: the last segment carries the "full" colour.
      if count == spec.segments.count then segment.color = FULL end
    end
  end

  local points = Group("Points", "group", 36, "FIXED")
  local resource = Group("Resource", "dynamicgroup", Y("resource", 20), "DOWN")
  for _, power in ipairs(spec.power or {}) do
    if power.segments then
      local width, column = Pip(power.segments)
      for point = 1, power.segments do
        local data = Base(name .. " - " .. power.label .. " " .. point, nil, "texture",
          PowerTrigger(power.type, (point - 0.5) * 100 / power.segments, true), { gate = power.gate })
        data.texture, data.color, data.blendMode = "Interface\\Buttons\\WHITE8X8", SEGMENT_COLORS[point], "BLEND"
        data.width, data.height, data.xOffset, data.yOffset = width, 6, column(point), 0
        Add(points, data)
      end
    else
      local bar = Bar(resource, power.label, PowerTrigger(power.type, nil, nil, power.unit), { gate = power.gate },
        POWER_COLORS[power.type] or POWER_COLORS[0], "%p", 12)
      if power.height then bar.height = power.height end
      if power.width then bar.width = power.width end
      -- Low strata, so the colour steps below can sit over it.
      if power.steps then bar.frameStrata = 3 end
      -- Below power.low the bar turns grey. One condition per property works on secret power; a second one on the
      -- same property would read the first one's secret result and give up, so the higher steps are copies instead.
      if power.low then
        bar.conditions[#bar.conditions + 1] = Condition("percentpower", tostring(power.low.value), "barColor",
          power.low.color, "<")
      end
      -- Each step is a copy of the bar in its own colour, laid over it, that the game shows only at or above its
      -- percent (the native threshold works in combat too). The highest step sits on top.
      for index, step in ipairs(power.steps or {}) do
        local holder = Group(power.label .. " step " .. index, "group", 0, "FIXED")
        holder.group.anchorFrameType, holder.group.anchorFrameFrame = "SELECTFRAME", "WeakAuras:" .. bar.id
        holder.group.anchorFrameParent = false
        local over = Bar(holder, power.label .. " " .. step.value .. "+", PowerTrigger(power.type, step.value, true,
          power.unit), { title = power.label }, step.color, "%p", bar.height)
        over.width, over.backgroundColor, over.frameStrata = bar.width, {0, 0, 0, 0}, 3 + index
        -- The base bar's text stays visible through the copy: the copy draws none.
        over.subRegions = { over.subRegions[1], over.subRegions[2] }
      end
      if power.type == 0 and not power.gate and not FOREVER_AURAS then
        -- A secret power percent picks the bar colour through a curve, in combat too.
        bar.conditions[#bar.conditions + 1] = Condition("percentpower", tostring(spec.manaWarning or 30), "barColor",
          RED, "<")
      elseif power.type == 0 and not power.gate then
        -- ForeverAuras: the native threshold drives the alpha of its whole aura, not a trigger state: a red copy
        -- laid over the mana bar is opaque below the value and transparent above, in combat too.
        local warning = Group(power.label .. " warning", "group", 0, "FIXED")
        warning.group.anchorFrameType, warning.group.anchorFrameFrame = "SELECTFRAME", "WeakAuras:" .. bar.id
        warning.group.anchorFrameParent = false
        local red = Bar(warning, power.label .. " low", PowerTrigger(0, spec.manaWarning or 30, nil, power.unit),
          { title = power.label }, RED, "%p", 12)
        red.frameStrata = 5
      end
    end
  end
  -- While Heroic Strike or Cleave is queued: Pixel glow (Battle Shout settings) + a circular main-hand
  -- swing overlay on every Main priority icon. Extra triggers do not affect visibility (expression stays
  -- on the original triggers). The overlay is separate from the icon's own cooldown swipe so spell/aura
  -- progress is unchanged; the swirl only appears under the queued condition.
  local function ApplyQueuedNextSwing(data)
    local spells = spec.queuedSwing or { 78, 845 }
    local triggers = data.triggers
    local n = #triggers
    local hs, cleave, swing = n + 1, n + 2, n + 3
    triggers[hs] = { trigger = Generic({ type = "spell", event = "Queued Action", spellName = spells[1],
      use_exact_spellName = false }), untrigger = {} }
    triggers[cleave] = { trigger = Generic({ type = "spell", event = "Queued Action", spellName = spells[2],
      use_exact_spellName = false }), untrigger = {} }
    triggers[swing] = { trigger = Generic({ type = "unit", event = "Swing Timer", hand = "main",
      use_hand = true }), untrigger = {} }
    if not triggers.disjunctive then
      triggers.disjunctive, triggers.triggerExpression, triggers.activeTriggerMode = "expression", "1", 1
    elseif triggers.disjunctive == "all" then
      local terms = {}
      for i = 1, n do terms[i] = tostring(i) end
      triggers.disjunctive, triggers.triggerExpression, triggers.activeTriggerMode =
        "expression", table.concat(terms, " and "), 1
    elseif triggers.disjunctive == "any" then
      local terms = {}
      for i = 1, n do terms[i] = tostring(i) end
      triggers.disjunctive, triggers.triggerExpression =
        "expression", table.concat(terms, " or ")
      triggers.activeTriggerMode = triggers.activeTriggerMode or 1
    else
      triggers.activeTriggerMode = triggers.activeTriggerMode or 1
    end
    local glow = {}
    for key, value in pairs(GLOW) do glow[key] = value end
    glow.glow = false
    data.subRegions[#data.subRegions + 1] = glow
    local glowIdx = #data.subRegions
    data.subRegions[#data.subRegions + 1] = {
      type = "subcirculartexture",
      circularTextureVisible = false,
      circularTextureTexture = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Circle_AlphaGradient_Out.tga",
      circularTextureDesaturate = false,
      circularTextureColor = {1, 1, 1, 0.9},
      circularTextureBlendMode = "BLEND",
      circularTextureStartAngle = 0, circularTextureEndAngle = 360,
      circularTextureClockwise = true,
      circularTextureCrop_x = 0.41, circularTextureCrop_y = 0.41,
      circularTextureRotation = 0, circularTextureAuraRotation = 0, circularTextureMirror = false,
      anchor_mode = "area", self_point = "CENTER", anchor_point = "CENTER", anchor_area = "ALL",
      width = 0, height = 0, scale = 1,
      progressSource = { swing, "expirationTime" },
    }
    local swirlIdx = #data.subRegions
    data.conditions[#data.conditions + 1] = {
      check = { trigger = -2, variable = "OR", checks = {
        { trigger = hs, variable = "show", value = 1 },
        { trigger = cleave, variable = "show", value = 1 },
      } },
      changes = {
        { property = "sub." .. glowIdx .. ".glow", value = true },
        { property = "sub." .. swirlIdx .. ".circularTextureVisible", value = true },
      },
    }
  end

  local main = Group("Main", "dynamicgroup", Y("main", 4), "GRID", 8)
  for _, entry in ipairs(spec.rotation or {}) do
    ApplyQueuedNextSwing(SpellIcon(main, entry, SIZES.main))
  end
  -- Priority lanes: one row per talent tree (or level range), in the order to press them. Only the lane that matches
  -- the character loads. The corner label is the real keybind from your action bars (dynamic lookup by spell),
  -- not the priority index; the icon dims while the spell can't be used (wrong stance, target too healthy for
  -- Execute, no proc yet), turns blue without the rage and red out of range.
  local usableDim = Condition("spellUsable", 0, "alpha", 0.45)
  for _, lane in ipairs(spec.lanes or {}) do
    for index, entry in ipairs(lane.entries) do
      local e = {}
      for key, value in pairs(entry) do e[key] = value end
      e.spec, e.level, e.levelBelow = lane.spec, lane.level, lane.levelBelow
      -- DoT refresh flash: Proc blink while remaining < 4s (Musca Remaining Time only offers <).
      -- Aura (Modern) rejects WA alphaPulse animation presets; BLINK glow is the Forever-safe flash.
      -- When Forever secrets duration in combat, faAuraRemaining fails closed (no flash, no error).
      -- The blink draws on top of a desaturated icon (visual override).
      if entry.dot then e.warn = 4 end
      local label = lane.name .. " " .. index .. " " .. entry.name
      local number = Text("%c", "INNER_TOPLEFT", 11)
      local data
      if entry.aura then
        local unit, kind = entry.unit or "target", entry.kind or "HARMFUL"
        data = Icon(main, label, AuraTrigger(entry.aura, "showAlways", unit, kind),
          Requirements(e, { size = SIZES.main, fallback = CooldownTrigger(entry.spell), idle = true,
            subRegions = { number }, missingGlow = kind == "HARMFUL", pandemic = entry.dot }))
      else
        data = Icon(main, label, CooldownTrigger(entry.spell), Requirements(e, { size = SIZES.main, subRegions = { number },
          conditions = { usableDim, noMana, outOfRange }, idle = true }))
      end
      ApplyHotkeyLabel(data, entry.spell)
      ApplyQueuedNextSwing(data)
    end
  end

  local utility = Group("Utility", "dynamicgroup", Y("utility", -30), "GRID", 9)
  for _, entry in ipairs(spec.cooldowns or {}) do
    SpellIcon(utility, entry, SIZES.utility)
  end
  -- "Is useable" leaves out an empty slot and a passive trinket: neither has a cooldown to show.
  for _, slot in ipairs(spec.noTrinkets and {} or { 13, 14 }) do
    Icon(utility, "Trinket " .. (slot - 12), Generic({ type = "item", event = "Cooldown Progress (Equipment Slot)",
      itemSlot = slot, use_itemSlot = true, genericShowOn = "showAlways", use_genericShowOn = true,
      use_testForCooldown = true }),
      { size = SIZES.utility, idle = true })
  end
  -- Racials load on the spell being known: each race sees its own, no race filter needed.
  -- Forever has one Berserking, 20554 (the 1.12 spell); Musca lists 26297, which Forever's game data lacks.
  for _, racial in ipairs({
    { "Perception", 20600 }, { "Stoneform", 20594 }, { "Shadowmeld", 20580 }, { "Escape Artist", 20589 },
    { "Blood Fury", 20572 }, { "Will of the Forsaken", 7744 }, { "Cannibalize", 20577 }, { "War Stomp", 20549 },
    { "Berserking", 20554 },
  }) do
    SpellIcon(utility, { name = racial[1], spell = racial[2], known = racial[2] }, SIZES.utility)
  end

  local bars = Group("Bars", "dynamicgroup", Y("bars", -96), "DOWN")
  if spec.castBar then
    Bar(bars, "Cast", Generic({ type = "unit", event = "Cast", unit = "player", use_unit = true }),
      { title = "%n", conditions = { Condition("interruptible", 0, "barColor", {0.5, 0.5, 0.5, 1}) } },
      RED, "%p", 20)
  end
  if spec.pet then
    Bar(bars, "Pet", Generic({ type = "unit", event = "Health", unit = "pet", use_unit = true }), {},
      {0.2, 0.8, 0.2, 1}, "%p", 10)
  end
  for _, hand in ipairs(spec.swing or {}) do
    local swing = FOREVER_AURAS and { type = "unit", event = "Swing Timer", swingType = ({ main = 0, off = 1, ranged = 2 })[hand] }
      or { type = "unit", event = "Swing Timer", hand = hand, use_hand = true }
    Bar(bars, "Swing " .. hand, Generic(swing),
      { known = spec.swingKnown, offhand = hand == "off" }, {0.8, 0.8, 0.8, 1}, "%p", 10)
  end
  if spec.fiveSecondRule then
    local trigger = Generic({ type = "event", event = "Spell Cast Succeeded", use_unit = true,
      use_spellNames = true, spellNames = Ids(spec.fiveSecondRule), duration = "5" })
    Bar(bars, "5 sec rule", trigger, {}, {0.6, 0.6, 1, 1}, "%p", 10)
  end

  local upkeep = Group("Upkeep", "dynamicgroup", -176)
  for _, entry in ipairs(spec.upkeep or {}) do
    AuraIcon(upkeep, entry.name, entry, entry.unit, entry.kind, true)
  end
  for _, weapon in ipairs(spec.enchants or {}) do
    Icon(upkeep, "Enchant " .. weapon, Generic({ type = "item", event = "Weapon Enchant", weapon = weapon,
      use_weapon = true, showOn = "showOnActive", use_showOn = true }),
      { size = SIZES.aura, offhand = weapon == "off" })
  end

  local totems = Group("Totems", "group", -204, "FIXED")
  local totemColumn = SIZES.totem[1] + 2
  for slot = 1, spec.totems and 4 or 0 do
    TotemIcon(totems, slot).xOffset = (slot - 2.5) * totemColumn
    local buffs = spec.totemBuffs and spec.totemBuffs[slot]
    if buffs then
      local trigger = AuraTrigger(buffs, "showOnActive")
      trigger.nativeFilters = nil
      local glow = Icon(totems, "Totem " .. slot .. " buff", trigger, { size = SIZES.totem })
      table.remove(glow.subRegions, 1)
      glow.blizzardAuraDisplay = { maxIcons = 1, sharedDisplay = true }
      glow.xOffset, glow.color, glow.cooldown, glow.inverse = (slot - 2.5) * totemColumn, {1, 1, 1, 0}, false, true
    end
  end

  -- Overflow: past 8 known spells the main grid opens a second line, and every row below moves down with it.
  -- Resource bars grow down from their top, so a druid's mana bar under the form bar pushes the main grid too.
  resource.group.selfPoint, resource.group.yOffset = "TOP", Y("resourceTop", 26)
  Below(main, resource, -10)
  Below(utility, main, -4)
  local offset = -6
  if #upkeep.members > 0 then
    Below(upkeep, utility, offset)
    offset = offset - SIZES.aura[2] - 4
  end
  if #totems.members > 0 then
    -- A plain group always anchors by its center.
    Below(totems, utility, offset - SIZES.totem[2] / 2)
    offset = offset - SIZES.totem[2] - 4
  end
  Below(bars, utility, offset)

  local rootData = Base(root, nil, "group", { type = "aura2", unit = "player", debuffType = "HELPFUL", names = {} }, {})
  rootData.controlledChildren = {}
  rootData.anchorFrameType, rootData.anchorPoint, rootData.selfPoint, rootData.xOffset, rootData.yOffset =
    "SCREEN", "CENTER", "CENTER", spec.x or 0, spec.y or -180

  for _, holder in ipairs(groups) do
    if #holder.members > 0 then
      rootData.controlledChildren[#rootData.controlledChildren + 1] = holder.group.id
      children[#children + 1] = holder.group
      for _, member in ipairs(holder.members) do children[#children + 1] = member end
    end
  end

  return { m = "d", s = "5.22.0", v = 2000, d = rootData, c = children }
end

return Pack
