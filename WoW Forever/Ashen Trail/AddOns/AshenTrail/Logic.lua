-- Pure guide, travel, gear, and nameplate rules. No WoW API.

AshenTrailLogic = AshenTrailLogic or {}
local L = AshenTrailLogic

L.CONTINENT = {
  Durotar = "Kalimdor",
  Orgrimmar = "Kalimdor",
  ["The Barrens"] = "Kalimdor",
  Mulgore = "Kalimdor",
  ["Thunder Bluff"] = "Kalimdor",
  ["Zephras Isle"] = "Kalimdor",
  ["Stonetalon Mountains"] = "Kalimdor",
  Ashenvale = "Kalimdor",
  ["Thousand Needles"] = "Kalimdor",
  Desolace = "Kalimdor",
  ["Dustwallow Marsh"] = "Kalimdor",
  Tanaris = "Kalimdor",
  Feralas = "Kalimdor",
  Felwood = "Kalimdor",
  Winterspring = "Kalimdor",
  Azshara = "Kalimdor",
  ["Un'Goro Crater"] = "Kalimdor",
  Silithus = "Kalimdor",
  ["Tirisfal Glades"] = "Eastern",
  Undercity = "Eastern",
  ["Silverpine Forest"] = "Eastern",
  ["Hillsbrad Foothills"] = "Eastern",
  ["Arathi Highlands"] = "Eastern",
  ["The Hinterlands"] = "Eastern",
  ["Stranglethorn Vale"] = "Eastern",
  ["Western Plaguelands"] = "Eastern",
  ["Eastern Plaguelands"] = "Eastern",
  Riverglades = "Riverglades",
  ["Mount Hyjal"] = "Hyjal",
}

function L.Continent(zone)
  return zone and L.CONTINENT[zone] or "Other"
end

local CLASS_TAGS = {
  Warrior = true, Hunter = true, Rogue = true, Priest = true,
  Shaman = true, Mage = true, Warlock = true, Druid = true, Paladin = true,
}

function L.RaceIdFromToken(token)
  if not token or token == "" then return nil end
  local lower = string.lower(token)
  if lower == "orc" or lower == "troll" then return "orc-troll" end
  if lower == "tauren" then return "tauren" end
  if lower == "scourge" or lower == "undead" or lower == "forsaken" then return "undead" end
  if string.find(lower, "sky", 1, true) or string.find(lower, "wind", 1, true) or string.find(lower, "zeph", 1, true) then
    return "skyborne"
  end
  return nil
end

function L.ClassTagFromFile(file)
  local map = {
    WARRIOR = "Warrior", HUNTER = "Hunter", ROGUE = "Rogue", PRIEST = "Priest",
    SHAMAN = "Shaman", MAGE = "Mage", WARLOCK = "Warlock", DRUID = "Druid", PALADIN = "Paladin",
  }
  return file and map[file] or nil
end

local function tagMatches(tag, raceId, classTag, raceToken)
  local neg = string.sub(tag, 1, 1) == "!"
  local name = neg and string.sub(tag, 2) or tag
  local ok
  if name == "Horde" then
    ok = true
  elseif name == "Orc" or name == "Troll" then
    if raceToken and raceToken ~= "" then
      ok = string.lower(raceToken) == string.lower(name)
    else
      ok = raceId == "orc-troll"
    end
  elseif name == "Tauren" then
    ok = raceId == "tauren"
  elseif name == "Undead" or name == "Scourge" then
    ok = raceId == "undead"
  elseif name == "Skyborne" then
    ok = raceId == "skyborne"
  elseif CLASS_TAGS[name] then
    ok = classTag == name
  else
    ok = true
  end
  if neg then return not ok end
  return ok
end

function L.StepVisible(step, raceId, classTag, raceToken)
  local only = step.only
  if not only or #only == 0 then return true end
  local hasNeg = false
  for i = 1, #only do
    if string.sub(only[i], 1, 1) == "!" then hasNeg = true break end
  end
  if hasNeg then
    for i = 1, #only do
      if not tagMatches(only[i], raceId, classTag, raceToken) then return false end
    end
    return true
  end
  for i = 1, #only do
    if tagMatches(only[i], raceId, classTag, raceToken) then return true end
  end
  return false
end

function L.VisibleSteps(chapter, raceId, classTag, raceToken)
  local out = {}
  if not chapter or not chapter.steps then return out end
  for i = 1, #chapter.steps do
    if L.StepVisible(chapter.steps[i], raceId, classTag, raceToken) then
      out[#out + 1] = chapter.steps[i]
    end
  end
  return out
end

function L.XpMet(value, level, xp, xpMax)
  local n = tonumber(value)
  if not n or not level then return false end
  local whole = math.floor(n)
  local frac = n - whole
  if level > whole then return true end
  if level < whole then return false end
  if frac <= 0.0001 then return true end
  if not xp or not xpMax or xpMax <= 0 then return false end
  return (xp / xpMax) + 0.001 >= frac
end

local function turnedIn(ctx, id)
  return ctx and ctx.turnedIn and id and ctx.turnedIn[id] and true or false
end

function L.LineState(line, ctx)
  local k = line.k
  ctx = ctx or {}
  if k == "note" or k == "sticky" then return "note" end
  if k == "accept" then
    if turnedIn(ctx, line.id) or (ctx.quests and ctx.quests[line.id]) then return "done" end
    return "open"
  end
  if k == "turnin" then
    if turnedIn(ctx, line.id) then return "done" end
    return "open"
  end
  if k == "complete" then
    if turnedIn(ctx, line.id) or (ctx.quests and ctx.quests[line.id] == "complete") then return "done" end
    return "open"
  end
  if k == "xp" then
    if L.XpMet(line.value, ctx.level, ctx.xp, ctx.xpMax) then return "done" end
    return "open"
  end
  return "info"
end

function L.StepStatus(step, ctx)
  local hard, open = false, false
  local lines = step.lines or {}
  for i = 1, #lines do
    local state = L.LineState(lines[i], ctx)
    if state == "open" or state == "done" then
      hard = true
      if state == "open" then open = true end
    end
  end
  if not hard then return "manual" end
  if open then return "open" end
  return "done"
end

function L.ChapterEndLevel(levelRange)
  if not levelRange then return 0 end
  local _, finish = string.match(levelRange, "(%d+)%D+(%d+)")
  if finish then return tonumber(finish) or 0 end
  return tonumber(string.match(levelRange, "(%d+)")) or 0
end

function L.LaterHardDone(route, chapters, chapterIndex, stepIndex, raceId, classTag, ctx, raceToken)
  for ci = chapterIndex, #route do
    local chapter = chapters[route[ci]]
    if chapter then
      local steps = L.VisibleSteps(chapter, raceId, classTag, raceToken)
      local startAt = (ci == chapterIndex) and (stepIndex + 1) or 1
      for si = startAt, #steps do
        if L.StepStatus(steps[si], ctx) == "done" then return true end
      end
    end
  end
  return false
end

function L.ManualIsBehind(level, chapterEnd, laterDone)
  if laterDone then return true end
  if chapterEnd and level and level > chapterEnd then return true end
  return false
end

function L.FormatLine(line)
  local k = line.k
  if k == "goto" then
    return ""
  elseif k == "accept" then
    local quest = line.name or ("quest " .. tostring(line.id or "?"))
    if line.npc and line.npc ~= "" then
      return "Talk to " .. line.npc .. ". Accept: " .. quest
    end
    return "Accept: " .. quest
  elseif k == "turnin" then
    local quest = line.name or ("quest " .. tostring(line.id or "?"))
    if line.npc and line.npc ~= "" then
      return "Talk to " .. line.npc .. ". Turn in: " .. quest
    end
    return "Turn in: " .. quest
  elseif k == "complete" then
    return "Complete " .. (line.objective or "the objective")
  elseif k == "xp" then
    return "Grind until level " .. tostring(line.value)
  elseif k == "fp" then
    return "Get the " .. (line.place or "flight path") .. " flight path"
  elseif k == "home" then
    return "Set Hearth to " .. (line.place or "the inn")
  elseif k == "trainer" then
    if line.npc and line.npc ~= "" then
      return "Talk to " .. line.npc .. ". " .. (line.note or "Train your class skills")
    end
    return line.note or "Train your class skills"
  elseif k == "vendor" then
    return line.note or "Sell junk and repair your gear"
  elseif k == "text" or k == "note" or k == "sticky" or k == "raw" or k == "link" then
    return line.text or ""
  elseif k == "target" then
    return "Target " .. (line.name or "")
  elseif k == "mob" then
    return "Kill " .. (line.name or "")
  elseif k == "unitscan" then
    return "Watch for " .. (line.name or "")
  elseif k == "hs" then
    return line.note or "Use your Hearthstone"
  elseif k == "fly" then
    return "Fly to " .. (line.place or "")
  elseif k == "deathskip" then
    return line.note or "Die on purpose and take the spirit healer"
  elseif k == "collect" then
    return "Collect " .. tostring(line.amount or 1) .. " " .. (line.item or "item")
  elseif k == "dungeon" then
    return line.text or ""
  elseif k == "maxlevel" then
    return "Stop this chapter at level " .. tostring(line.level or "?")
  elseif k == "zoneskip" then
    return "Leave for " .. (line.zone or "the next zone")
  end
  return line.text or ""
end

function L.TargetName(step)
  if not step then return nil end
  local fallback = nil
  for _, line in ipairs(step.lines or {}) do
    if line.k == "target" and line.name then return line.name end
    if not fallback and (line.k == "mob" or line.k == "unitscan") then fallback = line.name end
  end
  if fallback then return fallback end
  for _, poi in ipairs(step.pois or {}) do
    if poi.k == "giver" or poi.k == "turnin" or poi.k == "spawn" then
      if poi.name and poi.name ~= poi.zone then return poi.name end
    end
  end
  return nil
end

function L.PrimaryPin(step)
  if not step then return nil end
  local giver, turnin, markPin, trainer, spawn, service, gotoPin = nil, nil, nil, nil, nil, nil, nil
  for _, poi in ipairs(step.pois or {}) do
    if poi.k == "giver" then
      giver = giver or poi
    elseif poi.k == "turnin" then
      turnin = turnin or poi
    elseif poi.k == "mark" then
      markPin = markPin or poi
    elseif poi.k == "trainer" then
      trainer = trainer or poi
    elseif poi.k == "spawn" then
      spawn = spawn or poi
    elseif poi.k == "fp" or poi.k == "inn" then
      service = service or poi
    elseif poi.k == "goto" then
      gotoPin = gotoPin or poi
    end
  end
  return giver or turnin or markPin or trainer or spawn or service or gotoPin
end

function L.ActivePin(step, ctx)
  if not step then return nil end
  local carried = nil
  local first = nil
  ctx = ctx or {}
  for _, line in ipairs(step.lines or {}) do
    local here = nil
    if line.zone and line.x and line.y and (line.k == "goto" or line.k == "accept" or line.k == "turnin" or line.k == "trainer" or line.k == "dungeon") then
      here = {
        zone = line.zone,
        x = line.x,
        y = line.y,
        name = line.npc or line.mark or line.name or line.place or line.zone,
      }
      if line.k == "goto" then here.name = line.zone end
      carried = here
    elseif carried and (line.k == "fp" or line.k == "home") then
      here = { zone = carried.zone, x = carried.x, y = carried.y, name = line.place or carried.name }
    elseif carried and (line.k == "complete" or line.k == "mob" or line.k == "unitscan" or line.k == "target") then
      here = { zone = carried.zone, x = carried.x, y = carried.y, name = line.name or line.objective or carried.name }
    end
    if here and not first then first = here end
    if here and L.LineState(line, ctx) == "open" then return here end
  end
  local primary = L.PrimaryPin(step)
  if primary and primary.zone and primary.x then
    return { zone = primary.zone, x = primary.x, y = primary.y, name = primary.name or primary.zone }
  end
  return first
end

function L.NamesMatch(unitName, wanted)
  if not unitName or not wanted or wanted == "" then return false end
  local a, b = string.lower(unitName), string.lower(wanted)
  if a == b then return true end
  if string.len(a) < 4 or string.len(b) < 4 then return false end
  return string.find(b, a, 1, true) ~= nil or string.find(a, b, 1, true) ~= nil
end

function L.ParseObjective(text)
  if not text then return nil end
  local cur, max = string.match(text, "(%d+)%s*/%s*(%d+)")
  local name = string.gsub(text, "%s*:%s*%d+%s*/%s*%d+", "")
  name = string.gsub(name, "%s+[Ss]lain$", "")
  name = string.gsub(name, "^%s+", "")
  name = string.gsub(name, "%s+$", "")
  if name == "" then return nil end
  return { name = name, cur = tonumber(cur), max = tonumber(max) }
end

function L.MatchPlate(unitName, watch)
  if not unitName or unitName == "" or not watch then return nil end
  local exact = watch.exact and watch.exact[string.lower(unitName)]
  if exact then return exact end
  if watch.objectives then
    for i = 1, #watch.objectives do
      local obj = watch.objectives[i]
      if L.NamesMatch(unitName, obj.name) then
        local text = nil
        if obj.cur and obj.max then text = tostring(obj.cur) .. "/" .. tostring(obj.max) end
        return { kind = obj.kind or "spawn", text = text, name = unitName }
      end
    end
  end
  if watch.services then
    for i = 1, #watch.services do
      local npc = watch.services[i]
      if L.NamesMatch(unitName, npc.name) then
        return { kind = npc.kind or "town", text = nil, name = npc.name }
      end
    end
  end
  return nil
end

function L.Distance(ax, ay, bx, by)
  if not ax or not ay or not bx or not by then return 999 end
  local dx, dy = ax - bx, ay - by
  return math.sqrt(dx * dx + dy * dy)
end

function L.Nearest(nodes, zone, x, y, filter)
  local ranked = {}
  for i = 1, #nodes do
    local node = nodes[i]
    if node.x and node.y and (not filter or filter(node)) then
      local same = node.zone == zone
      local dist = same and L.Distance(x, y, node.x, node.y) or 1000 + i
      ranked[#ranked + 1] = { node = node, dist = dist, same = same }
    end
  end
  table.sort(ranked, function(a, b)
    if a.same ~= b.same then return a.same end
    return a.dist < b.dist
  end)
  return ranked
end

L.WEIGHTS = {
  Warrior = { str = 1.0, agi = 0.4, sta = 0.55, ap = 0.45, crit = 0.3, int = 0.05, spi = 0.05, sp = 0.05, ilvl = 0.35 },
  Hunter = { agi = 1.0, sta = 0.4, int = 0.15, ap = 0.4, crit = 0.45, str = 0.15, spi = 0.05, sp = 0.05, ilvl = 0.3 },
  Rogue = { agi = 1.0, sta = 0.4, ap = 0.4, crit = 0.45, str = 0.3, int = 0.02, spi = 0.05, sp = 0.02, ilvl = 0.3 },
  Priest = { int = 1.0, spi = 0.55, sta = 0.4, sp = 0.85, str = 0.02, agi = 0.02, ap = 0.02, crit = 0.15, ilvl = 0.25 },
  Mage = { int = 1.0, spi = 0.35, sta = 0.3, sp = 0.9, crit = 0.2, str = 0.02, agi = 0.02, ap = 0.02, ilvl = 0.25 },
  Warlock = { int = 1.0, sta = 0.5, sp = 0.85, spi = 0.3, crit = 0.15, str = 0.02, agi = 0.02, ap = 0.02, ilvl = 0.25 },
  Shaman = { int = 0.7, str = 0.55, agi = 0.45, sta = 0.5, sp = 0.55, ap = 0.3, spi = 0.25, crit = 0.2, ilvl = 0.3 },
  Druid = { int = 0.7, agi = 0.55, sta = 0.5, spi = 0.35, sp = 0.55, str = 0.35, ap = 0.25, crit = 0.2, ilvl = 0.3 },
  Paladin = { str = 0.9, sta = 0.6, int = 0.35, sp = 0.25, agi = 0.2, ap = 0.3, crit = 0.2, spi = 0.15, ilvl = 0.35 },
}

L.STAT_KEYS = {
  ITEM_MOD_STRENGTH_SHORT = "str",
  ITEM_MOD_AGILITY_SHORT = "agi",
  ITEM_MOD_STAMINA_SHORT = "sta",
  ITEM_MOD_INTELLECT_SHORT = "int",
  ITEM_MOD_SPIRIT_SHORT = "spi",
  ITEM_MOD_ATTACK_POWER_SHORT = "ap",
  ITEM_MOD_SPELL_POWER_SHORT = "sp",
  ITEM_MOD_CRIT_RATING_SHORT = "crit",
  ITEM_MOD_SPELL_CRIT_RATING_SHORT = "crit",
  Strength = "str", Agility = "agi", Stamina = "sta", Intellect = "int", Spirit = "spi",
}

function L.NormalizeStats(raw, ilvl)
  local stats = {}
  for key, amount in pairs(raw or {}) do
    local mapped = L.STAT_KEYS[key]
    if mapped then stats[mapped] = (stats[mapped] or 0) + amount end
  end
  if ilvl then stats.ilvl = ilvl end
  return stats
end

function L.Score(stats, classTag)
  local weights = L.WEIGHTS[classTag] or L.WEIGHTS.Warrior
  local total = 0
  for key, amount in pairs(stats or {}) do
    local weight = weights[key]
    if weight then total = total + amount * weight end
  end
  return total
end

L.SLOTS = {
  INVTYPE_HEAD = { 1 },
  INVTYPE_NECK = { 2 },
  INVTYPE_SHOULDER = { 3 },
  INVTYPE_BODY = { 4 },
  INVTYPE_CHEST = { 5 },
  INVTYPE_ROBE = { 5 },
  INVTYPE_WAIST = { 6 },
  INVTYPE_LEGS = { 7 },
  INVTYPE_FEET = { 8 },
  INVTYPE_WRIST = { 9 },
  INVTYPE_HAND = { 10 },
  INVTYPE_FINGER = { 11, 12 },
  INVTYPE_TRINKET = { 13, 14 },
  INVTYPE_CLOAK = { 15 },
  INVTYPE_WEAPON = { 16 },
  INVTYPE_2HWEAPON = { 16 },
  INVTYPE_WEAPONMAINHAND = { 16 },
  INVTYPE_WEAPONOFFHAND = { 17 },
  INVTYPE_SHIELD = { 17 },
  INVTYPE_HOLDABLE = { 17 },
  INVTYPE_RANGED = { 18 },
  INVTYPE_RANGEDRIGHT = { 18 },
}

function L.EquipSlots(equipLoc)
  return L.SLOTS[equipLoc]
end

function L.PickReward(choices, classTag)
  local best, bestScore = nil, nil
  for i = 1, #choices do
    local choice = choices[i]
    local score = choice.score or L.Score(choice.stats, classTag)
    local equipped = choice.equipped or 0
    local upgrade = score > equipped + 0.05
    if not best or score > bestScore then
      best = { index = i, name = choice.name, score = score, equipped = equipped, upgrade = upgrade, slot = choice.slot }
      bestScore = score
    end
  end
  if not best then return nil end
  if not best.upgrade then
    best.verdict = "vendor"
  else
    best.verdict = "equip"
  end
  return best
end

local function lowerName(value)
  return string.lower(value or "")
end

function L.MergeNodes(staticNodes, guidePlaces)
  local nodes = {}
  local index = {}
  for i = 1, #(staticNodes or {}) do
    local node = staticNodes[i]
    local copy = {}
    for k, v in pairs(node) do copy[k] = v end
    copy.continent = copy.continent or L.Continent(copy.zone)
    nodes[#nodes + 1] = copy
    index[copy.kind .. "|" .. lowerName(copy.name)] = copy
  end
  for i = 1, #(guidePlaces or {}) do
    local place = guidePlaces[i]
    local key = place.kind .. "|" .. lowerName(place.name)
    local existing = index[key]
    if existing then
      if not (place.zone and existing.zone and place.zone ~= existing.zone) then
        existing.zone = place.zone or existing.zone
        existing.x = place.x or existing.x
        existing.y = place.y or existing.y
        existing.continent = L.Continent(existing.zone)
      end
    else
      local created = {
        id = "guide-" .. place.kind .. "-" .. tostring(i),
        kind = place.kind,
        name = place.name,
        zone = place.zone,
        x = place.x,
        y = place.y,
        continent = L.Continent(place.zone),
      }
      nodes[#nodes + 1] = created
      index[key] = created
    end
  end
  return nodes
end

local function link(adj, fromId, toId, cost, kind, label, node)
  if not fromId or not toId or not cost then return end
  local list = adj[fromId]
  if not list then
    list = {}
    adj[fromId] = list
  end
  list[#list + 1] = {
    to = toId,
    cost = cost,
    kind = kind,
    label = label,
    zone = node and node.zone or nil,
    x = node and node.x or nil,
    y = node and node.y or nil,
    name = node and node.name or nil,
  }
end

function L.FlightKnown(node, known)
  if not known then return false end
  local name = lowerName(node.name)
  if known[name] or known[node.id] then return true end
  for key in pairs(known) do
    if type(key) == "string" then
      local sample = lowerName(key)
      if sample ~= "" and (string.find(name, sample, 1, true) or string.find(sample, name, 1, true)) then
        return true
      end
    end
  end
  return false
end

local function hubFor(byZone, zone)
  local list = byZone[zone]
  if not list then return nil end
  local prefer = { fp = 1, zep = 2, boat = 3, inn = 4 }
  local best, rank = nil, 99
  for i = 1, #list do
    local node = list[i]
    local r = prefer[node.kind] or 5
    if node.x and r < rank then best, rank = node, r end
  end
  return best or list[1]
end

function L.Plan(nodes, links, borders, origin, dest, known)
  if not origin or not origin.zone or not dest or not dest.zone then return nil end
  local adj = {}
  local byId = {}
  local byZone = {}
  for i = 1, #nodes do
    local node = nodes[i]
    if node.id and node.zone then
      node.continent = node.continent or L.Continent(node.zone)
      byId[node.id] = node
      byZone[node.zone] = byZone[node.zone] or {}
      byZone[node.zone][#byZone[node.zone] + 1] = node
    end
  end
  for zone, list in pairs(byZone) do
    for i = 1, #list do
      for j = i + 1, #list do
        local a, b = list[i], list[j]
        if a.x and b.x then
          local dist = L.Distance(a.x, a.y, b.x, b.y)
          if dist >= 0.4 then
            link(adj, a.id, b.id, dist, "run", "Run to " .. b.name, b)
            link(adj, b.id, a.id, dist, "run", "Run to " .. a.name, a)
          end
        end
      end
    end
  end
  local useKnown = false
  if known then
    for _ in pairs(known) do useKnown = true break end
  end
  for i = 1, #nodes do
    local a = nodes[i]
    if a.kind == "fp" and a.continent then
      for j = i + 1, #nodes do
        local b = nodes[j]
        if b.kind == "fp" and b.continent == a.continent and b.zone ~= a.zone then
          local aKnown = L.FlightKnown(a, known)
          local bKnown = L.FlightKnown(b, known)
          local allowed = (not useKnown) or (aKnown and bKnown)
          if allowed then
            -- 12 beats a zone crossing (16+) and loses to a city gate (6-8).
            link(adj, a.id, b.id, 12, "fly", "Fly to " .. b.name, b)
            link(adj, b.id, a.id, 12, "fly", "Fly to " .. a.name, a)
            if not (aKnown and bKnown) then
              adj[a.id][#adj[a.id]].unconfirmed = true
              adj[b.id][#adj[b.id]].unconfirmed = true
            end
          end
        end
      end
    end
  end
  for i = 1, #(links or {}) do
    local edge = links[i]
    local a, b = byId[edge[1]], byId[edge[2]]
    if a and b then
      local kind = edge[3]
      local cost = edge[4] or 16
      local verb = kind == "zep" and "Take the zeppelin toward " or "Take the boat toward "
      link(adj, a.id, b.id, cost, kind, verb .. b.name, b)
      link(adj, b.id, a.id, cost, kind, verb .. a.name, a)
    end
  end
  for i = 1, #(borders or {}) do
    local border = borders[i]
    local a = hubFor(byZone, border[1])
    local b = hubFor(byZone, border[2])
    if a and b and a.id ~= b.id then
      local cost = border[3] or 24
      link(adj, a.id, b.id, cost, "run", "Cross into " .. b.zone, b)
      link(adj, b.id, a.id, cost, "run", "Cross into " .. a.zone, a)
    end
  end

  local player = { id = "@player", zone = origin.zone, x = origin.x, y = origin.y, name = "you" }
  byId[player.id] = player
  local here = byZone[origin.zone]
  if here then
    for i = 1, #here do
      local node = here[i]
      local dist = (origin.x and node.x) and L.Distance(origin.x, origin.y, node.x, node.y) or 8
      link(adj, player.id, node.id, dist, "run", "Run to " .. node.name, node)
    end
  end
  if origin.hearthReady and origin.hearthBind then
    local bind = lowerName(origin.hearthBind)
    for i = 1, #nodes do
      local node = nodes[i]
      local names = node.bind or { node.name }
      for n = 1, #names do
        if lowerName(names[n]) == bind then
          link(adj, player.id, node.id, 3, "hearth", "Hearth to " .. (node.name or origin.hearthBind), node)
          break
        end
      end
    end
  end

  local goal = { id = "@dest", zone = dest.zone, x = dest.x, y = dest.y, name = dest.name or dest.zone }
  if dest.zone == origin.zone and origin.x and dest.x then
    link(adj, player.id, goal.id, L.Distance(origin.x, origin.y, dest.x, dest.y), "run", "Run to the step", goal)
  end
  local there = byZone[dest.zone]
  if there then
    for i = 1, #there do
      local node = there[i]
      local dist = (dest.x and node.x) and L.Distance(node.x, node.y, dest.x, dest.y) or 5
      link(adj, node.id, goal.id, dist, "run", "Run to the step", goal)
    end
  elseif not (dest.zone == origin.zone and origin.x and dest.x) then
    return nil
  end

  local hops, cost = L.Shortest(adj, player.id, goal.id)
  if not hops then return nil end
  return { hops = hops, cost = cost, dest = dest, origin = origin }
end

function L.Shortest(adj, startId, goalId)
  local dist = { [startId] = 0 }
  local prev = {}
  local used = {}
  local guard = 0
  while guard < 800 do
    guard = guard + 1
    local best, bestD = nil, nil
    for id, d in pairs(dist) do
      if not used[id] and (not bestD or d < bestD) then
        best, bestD = id, d
      end
    end
    if not best then return nil end
    if best == goalId then break end
    used[best] = true
    local edges = adj[best]
    if edges then
      for i = 1, #edges do
        local edge = edges[i]
        if not used[edge.to] then
          local nextD = bestD + edge.cost
          if not dist[edge.to] or nextD < dist[edge.to] then
            dist[edge.to] = nextD
            prev[edge.to] = { id = best, edge = edge }
          end
        end
      end
    end
  end
  if not dist[goalId] then return nil end
  local hops = {}
  local cur = goalId
  local safety = 0
  while cur ~= startId do
    safety = safety + 1
    if safety > 200 then return nil end
    local step = prev[cur]
    if not step then return nil end
    table.insert(hops, 1, step.edge)
    cur = step.id
  end
  return hops, dist[goalId]
end

function L.ShouldSuggest(plan)
  if not plan or not plan.hops or #plan.hops == 0 then return false end
  if plan.origin and plan.dest and plan.origin.zone == plan.dest.zone then
    if #plan.hops == 1 and plan.hops[1].kind == "run" and (plan.cost or 0) < 28 then
      return false
    end
  end
  return true
end

function L.RouteSummary(plan)
  if not plan or not plan.hops then return "" end
  local parts = {}
  for i = 1, #plan.hops do
    local hop = plan.hops[i]
    if hop.to ~= "@dest" then
      local text = hop.label or hop.kind or "Travel"
      if hop.unconfirmed then text = text .. " (flight not confirmed)" end
      parts[#parts + 1] = text
    end
  end
  return table.concat(parts, " -> ")
end

function L.FirstWaypoint(plan)
  if not plan then return nil end
  for i = 1, #plan.hops do
    local hop = plan.hops[i]
    if hop.x and hop.zone and hop.to ~= "@dest" then
      return hop
    end
  end
  if plan.dest and plan.dest.x then
    return { zone = plan.dest.zone, x = plan.dest.x, y = plan.dest.y, label = "Run to the step", kind = "run" }
  end
  return plan.hops[1]
end

function L.StepKey(chapterId, step)
  local parts = { tostring(chapterId or "") }
  local lines = step and step.lines or {}
  for i = 1, #lines do
    local line = lines[i]
    local label = line.name or line.objective or line.text or line.value or line.place or ""
    parts[#parts + 1] = tostring(line.k or "") .. ":" .. tostring(line.id or "") .. ":" .. tostring(label)
  end
  return table.concat(parts, "|")
end

function L.QuestOnRoute(chapters, routeIds, raceId, classTag, kind, questId, questName, raceToken)
  if not chapters or not routeIds or not kind then return false end
  for i = 1, #routeIds do
    local chapter = chapters[routeIds[i]]
    if chapter then
      local steps = L.VisibleSteps(chapter, raceId, classTag, raceToken)
      for s = 1, #steps do
        local lines = steps[s].lines or {}
        for n = 1, #lines do
          local line = lines[n]
          if line.k == kind then
            if questId and line.id and tonumber(questId) == tonumber(line.id) then return true end
            if questName and line.name and L.NamesMatch(questName, line.name) then return true end
          end
        end
      end
    end
  end
  return false
end

function L.CoinText(copper)
  copper = math.floor(tonumber(copper) or 0)
  if copper < 0 then copper = 0 end
  local gold = math.floor(copper / 10000)
  local silver = math.floor((copper % 10000) / 100)
  local coins = copper % 100
  if gold > 0 then return string.format("%dg %ds %dc", gold, silver, coins) end
  if silver > 0 then return string.format("%ds %dc", silver, coins) end
  return string.format("%dc", coins)
end

function L.CanPayRepair(cost, money)
  cost = tonumber(cost) or 0
  money = tonumber(money) or 0
  if cost <= 0 then return false, "none" end
  if money < cost then return false, "short" end
  return true, "ok"
end

function L.RewardSlot(numChoices, bestIndex)
  numChoices = tonumber(numChoices) or 0
  if numChoices <= 0 then return 0 end
  if numChoices == 1 then return 1 end
  bestIndex = tonumber(bestIndex)
  if bestIndex and bestIndex >= 1 and bestIndex <= numChoices then return bestIndex end
  return 1
end

-- Only a lone option marked as conversation text is safe to click.
-- A missing type stays manual so a vendor or flight button is never assumed.
function L.LoneGossip(options)
  if not options or #options ~= 1 then return nil end
  local kind = string.lower(tostring(options[1].type or ""))
  if kind == "gossip" then return 1 end
  return nil
end

L.CLASS_COLORS = {
  Warrior = { 0.78, 0.61, 0.43 },
  Paladin = { 0.96, 0.55, 0.73 },
  Hunter = { 0.67, 0.83, 0.45 },
  Rogue = { 1.00, 0.96, 0.41 },
  Priest = { 1.00, 1.00, 1.00 },
  Mage = { 0.41, 0.80, 0.94 },
  Warlock = { 0.58, 0.51, 0.79 },
  Shaman = { 0.00, 0.44, 0.87 },
  Druid = { 1.00, 0.49, 0.04 },
}

local THEMES = {
  blizzard = {
    id = "blizzard",
    name = "Blizzard",
    bg = { 0.08, 0.09, 0.14 },
    edge = { 1.00, 0.82, 0.00 },
    title = { 1.00, 0.82, 0.00 },
    text = { 1.00, 1.00, 1.00 },
    muted = { 0.66, 0.64, 0.55 },
    accent = { 0.00, 0.44, 0.87 },
    done = { 0.20, 0.85, 0.25 },
    open = { 1.00, 0.82, 0.00 },
    arrow = { 1.00, 0.82, 0.00 },
  },
  dark = {
    id = "dark",
    name = "Dark",
    bg = { 0.07, 0.07, 0.08 },
    edge = { 0.28, 0.30, 0.34 },
    title = { 0.93, 0.94, 0.96 },
    text = { 0.90, 0.90, 0.93 },
    muted = { 0.55, 0.56, 0.60 },
    accent = { 0.38, 0.62, 0.95 },
    done = { 0.42, 0.78, 0.58 },
    open = { 0.95, 0.74, 0.38 },
    arrow = { 0.45, 0.72, 1.00 },
  },
  vibrant = {
    id = "vibrant",
    name = "Vibrant",
    bg = { 0.11, 0.05, 0.08 },
    edge = { 1.00, 0.38, 0.32 },
    title = { 1.00, 0.48, 0.36 },
    text = { 1.00, 0.95, 0.90 },
    muted = { 0.78, 0.58, 0.58 },
    accent = { 0.22, 0.86, 0.74 },
    done = { 0.35, 0.92, 0.55 },
    open = { 1.00, 0.58, 0.22 },
    arrow = { 1.00, 0.36, 0.42 },
  },
  ashen = {
    id = "ashen",
    name = "Ashen",
    bg = { 0.07, 0.06, 0.05 },
    edge = { 0.77, 0.35, 0.17 },
    title = { 0.77, 0.35, 0.17 },
    text = { 0.94, 0.89, 0.82 },
    muted = { 0.62, 0.56, 0.48 },
    accent = { 0.77, 0.35, 0.17 },
    done = { 0.49, 0.61, 0.42 },
    open = { 0.77, 0.35, 0.17 },
    arrow = { 0.77, 0.35, 0.17 },
  },
}

function L.ThemeColors(themeId, classTag)
  if themeId == "class" then
    local classColor = L.CLASS_COLORS[classTag or ""] or L.CLASS_COLORS.Warrior
    return {
      id = "class",
      name = "Class",
      bg = { 0.06, 0.06, 0.07 },
      edge = { classColor[1], classColor[2], classColor[3] },
      title = { classColor[1], classColor[2], classColor[3] },
      text = { 0.96, 0.96, 0.97 },
      muted = { 0.62, 0.62, 0.66 },
      accent = { classColor[1], classColor[2], classColor[3] },
      done = { 0.42, 0.82, 0.48 },
      open = { classColor[1], classColor[2], classColor[3] },
      arrow = { classColor[1], classColor[2], classColor[3] },
    }
  end
  return THEMES[themeId] or THEMES.dark
end

function L.Overleveled(level, chapterEnd, gap)
  level = tonumber(level) or 1
  chapterEnd = tonumber(chapterEnd) or 0
  gap = tonumber(gap) or 0
  if chapterEnd <= 0 then return false end
  return level > chapterEnd + gap
end

function L.StepHoldsQuest(step, ctx)
  local lines = step and step.lines or {}
  local quests = ctx and ctx.quests or {}
  for i = 1, #lines do
    local id = lines[i].id
    if id and (quests[id] == "active" or quests[id] == "complete") then return true end
  end
  return false
end

function L.MayLeaveChapter(mode)
  return mode ~= "manual"
end

function L.ItemKey(itemId, name)
  itemId = tonumber(itemId)
  if itemId and itemId > 0 then return "id:" .. tostring(itemId) end
  if not name then return nil end
  name = string.lower(name)
  name = string.gsub(name, "^%s+", "")
  name = string.gsub(name, "%s+$", "")
  name = string.gsub(name, "%[", "")
  name = string.gsub(name, "%]", "")
  if name == "" then return nil end
  return "name:" .. name
end

function L.Listed(list, itemId, name)
  if not list then return false end
  local idKey = tonumber(itemId) and ("id:" .. tostring(tonumber(itemId))) or nil
  if idKey and list[idKey] then return true end
  local nameKey = L.ItemKey(nil, name)
  if nameKey and list[nameKey] then return true end
  if name and name ~= "" then
    local want = string.lower(name)
    for _, label in pairs(list) do
      if type(label) == "string" and string.lower(label) == want then return true end
    end
  end
  return false
end

function L.IsJunk(quality, itemType, itemId, name, junkList, keepList)
  if tonumber(itemId) == 6948 then return false end
  if L.Listed(keepList, itemId, name) then return false end
  if L.Listed(junkList, itemId, name) then return true end
  if itemType == "Quest" then return false end
  return tonumber(quality) == 0
end

function L.FormatClock(seconds)
  seconds = math.floor(tonumber(seconds) or 0)
  if seconds < 0 then seconds = 0 end
  return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

function L.FlightRemain(distance, speed)
  distance = tonumber(distance) or 0
  speed = tonumber(speed) or 0
  if speed <= 0.02 or distance < 0 then return nil end
  return distance / speed
end

function L.BreathSeconds(value)
  value = tonumber(value)
  if not value then return nil end
  if value > 3000 then value = value / 1000 end
  if value < 0 then value = 0 end
  return value
end

function L.BreathLow(remaining, threshold)
  remaining = tonumber(remaining)
  if not remaining then return false end
  threshold = tonumber(threshold) or 10
  return remaining <= threshold
end

-- Five-point openers checked against Talents Forever on questing.wiki
-- (export 2026-10-16, beta build 1.60.1.70425). The UI still says Forever may differ.
-- Cruelty is Fury row 1 slot 3, so it is legal at level 10. Improved Heroic Strike is also row 1, and only 3 ranks.
-- Deadly Aspects is the Beast Mastery row-1 talent that affects Aspect of the Hawk.
-- Improved Sinister Strike is 2 ranks. The next three points are Malice, also row 1.
local TALENT = {
  Warrior = { "Cruelty", "Cruelty", "Cruelty", "Cruelty", "Cruelty" },
  Hunter = { "Deadly Aspects", "Deadly Aspects", "Deadly Aspects", "Deadly Aspects", "Deadly Aspects" },
  Rogue = { "Improved Sinister Strike", "Improved Sinister Strike", "Malice", "Malice", "Malice" },
  Priest = { "Spirit Tap", "Spirit Tap", "Spirit Tap", "Spirit Tap", "Spirit Tap" },
  Mage = { "Improved Frostbolt", "Improved Frostbolt", "Improved Frostbolt", "Improved Frostbolt", "Improved Frostbolt" },
  Warlock = { "Improved Corruption", "Improved Corruption", "Improved Corruption", "Improved Corruption", "Improved Corruption" },
  Shaman = { "Concussion", "Concussion", "Concussion", "Concussion", "Concussion" },
  Druid = { "Ferocity", "Ferocity", "Ferocity", "Ferocity", "Ferocity" },
  Paladin = { "Benediction", "Benediction", "Benediction", "Benediction", "Benediction" },
}

function L.NextTalent(class, level, unspent)
  local list = TALENT[class or ""]
  if not list then return nil end
  unspent = tonumber(unspent) or 0
  if unspent <= 0 then return nil end
  local earned = math.max(0, (tonumber(level) or 1) - 9)
  local spent = earned - unspent
  if spent < 0 then spent = 0 end
  local name = list[spent + 1]
  if not name then return { done = true, unspent = unspent } end
  return { name = name, unspent = unspent, index = spent + 1, total = #list }
end

function L.GuidePins(steps, index)
  local out = {}
  local function take(step)
    if not step or not step.pois then return end
    for i = 1, #step.pois do
      local poi = step.pois[i]
      if (poi.k == "giver" or poi.k == "turnin") and poi.x and poi.zone then
        out[#out + 1] = poi
      end
    end
  end
  index = tonumber(index) or 1
  take(steps and steps[index])
  take(steps and steps[index + 1])
  return out
end

function L.TargetMacro(name, skull)
  if not name or name == "" then return "" end
  local quoted = name
  if string.find(name, " ", 1, true) and not string.find(name, '"', 1, true) then
    quoted = '"' .. name .. '"'
  end
  local body = "/targetexact " .. quoted .. "\n/targetexact " .. quoted
  if skull then body = body .. "\n/tm 8" end
  return body
end

function L.RouteEta(plan, saved)
  if not plan or not plan.hops then return nil end
  local seconds = 0
  local missingFlight = false
  for i = 1, #plan.hops do
    local hop = plan.hops[i]
    if hop.kind == "fly" then
      local found = false
      local destName = hop.name and string.lower(hop.name) or nil
      if saved and destName and destName ~= "" then
        local tail = "|" .. destName
        for key, value in pairs(saved) do
          if type(key) == "string" and string.sub(string.lower(key), -#tail) == tail and tonumber(value) then
            seconds = seconds + tonumber(value)
            found = true
            break
          end
        end
      end
      if not found then missingFlight = true end
    elseif hop.kind == "boat" or hop.kind == "zep" then
      seconds = seconds + (tonumber(hop.cost) or 15) * 60
    elseif hop.kind == "hearth" then
      seconds = seconds + 10
    elseif hop.kind == "run" then
      seconds = seconds + (tonumber(hop.cost) or 0) * 6
    end
  end
  return { seconds = seconds, missingFlight = missingFlight }
end

-- Outdoor radii match the usual minimap zoom yards. Indoor is the smaller set.
local MINIMAP_OUTDOOR = { 233.333, 200, 166.667, 133.333, 100, 66.667 }
local MINIMAP_INDOOR = { 150, 120, 90, 60, 40, 25 }

function L.MinimapRadius(zoom, indoors)
  local list = indoors and MINIMAP_INDOOR or MINIMAP_OUTDOOR
  zoom = math.floor(tonumber(zoom) or 0)
  if zoom < 0 then zoom = 0 end
  if zoom > 5 then zoom = 5 end
  return list[zoom + 1]
end

function L.MinimapOffset(dx, dy, radiusYards, edgePixels)
  dx = tonumber(dx) or 0
  dy = tonumber(dy) or 0
  radiusYards = tonumber(radiusYards) or 0
  edgePixels = tonumber(edgePixels) or 0
  local dist = math.sqrt(dx * dx + dy * dy)
  if radiusYards <= 0 or edgePixels <= 0 then return 0, 0, dist end
  local scale = edgePixels / radiusYards
  local px, py = dx * scale, dy * scale
  local hyp = math.sqrt(px * px + py * py)
  if hyp > edgePixels and hyp > 0 then
    px = px / hyp * edgePixels
    py = py / hyp * edgePixels
  end
  return px, py, dist
end

function L.RouteModeLabel(mode)
  if mode == "discover" then return "Discovery" end
  return "Speedrun"
end

function L.AbandonHint(count, cap, names)
  count = tonumber(count) or 0
  cap = tonumber(cap) or 40
  if count < cap - 8 or type(names) ~= "table" or #names == 0 then return nil end
  local shown = {}
  local limit = math.min(3, #names)
  for i = 1, limit do shown[i] = names[i] end
  local list = table.concat(shown, ", ")
  if #names > limit then list = list .. " +" .. tostring(#names - limit) end
  return "Quest log " .. count .. "/" .. cap .. ". Off the route: " .. list .. "."
end

function L.GroupWarning(elite, suggested)
  suggested = tonumber(suggested) or 0
  if elite and suggested > 1 then return "Elite group quest ahead." end
  if elite then return "Elite quest ahead." end
  if suggested > 1 then return "Group quest ahead (" .. suggested .. ")." end
  return nil
end

function L.SupplyReminder(leaving, class)
  if not leaving then return nil end
  local extra = "class reagents"
  if class == "Hunter" or class == "Warrior" or class == "Rogue" then extra = "ammo" end
  return "Before you leave town: bags, food, water, and " .. extra .. "."
end

function L.LeavingTown(step, nextStep)
  if not step or not nextStep then return false end
  local here, there, town
  local lines = step.lines or {}
  for i = 1, #lines do
    local line = lines[i]
    if line.k == "home" or line.k == "fp" or line.k == "vendor" then town = true end
    if line.zone and line.zone ~= "" then here = line.zone end
  end
  local nextLines = nextStep.lines or {}
  for i = 1, #nextLines do
    local zone = nextLines[i].zone
    if zone and zone ~= "" then there = zone end
  end
  if not town or not here or not there then return false end
  return here ~= there
end

function L.TrainReminder(level, notedLevel)
  level = tonumber(level) or 1
  notedLevel = tonumber(notedLevel) or 0
  if level < 4 then return false end
  return (level - notedLevel) >= 2
end

function L.HearthLabel(ready, remain)
  if ready then return "Hearthstone is ready." end
  remain = tonumber(remain)
  if remain and remain > 0 then return "Hearthstone " .. L.FormatClock(remain) .. "." end
  return nil
end

function L.PerHour(count, seconds)
  seconds = tonumber(seconds) or 0
  count = tonumber(count) or 0
  if seconds < 20 or count < 1 then return nil end
  return count / seconds * 3600
end

function L.FormatMoney(copper)
  copper = math.floor(tonumber(copper) or 0)
  if copper < 0 then copper = 0 end
  local gold = math.floor(copper / 10000)
  local silver = math.floor((copper % 10000) / 100)
  if gold > 0 then return gold .. "g " .. silver .. "s" end
  return silver .. "s"
end

function L.LevelSeconds(record, now)
  if not record then return 0 end
  local total = tonumber(record.seconds) or 0
  if record.started and now then
    total = total + math.max(0, now - record.started)
  end
  return total
end

function L.CloseLevel(record, now)
  if not record then return 0 end
  local total = L.LevelSeconds(record, now)
  record.seconds = total
  record.started = nil
  return total
end

function L.BestOther(timesByChar, selfName, level)
  local key = tostring(level)
  local best, who
  for name, levels in pairs(timesByChar or {}) do
    if name ~= selfName and type(levels) == "table" then
      local seconds = tonumber(levels[key])
      if seconds and seconds > 0 and (not best or seconds < best) then
        best = seconds
        who = name
      end
    end
  end
  return best, who
end

function L.ExportRoute(race, chapter, step, skips)
  local parts = {
    string.format("AT1\t%s\t%d\t%d", race or "", tonumber(chapter) or 1, tonumber(step) or 1),
  }
  for i = 1, #(skips or {}) do
    local key = tostring(skips[i])
    parts[#parts + 1] = string.format("%d:%s", #key, key)
  end
  return table.concat(parts, "\t")
end

function L.ImportRoute(text)
  if type(text) ~= "string" then return nil end
  local race, chapter, step, rest = string.match(text, "^AT1\t([^\t]*)\t(%d+)\t(%d+)\t?(.*)$")
  if not chapter then return nil end
  local skips = {}
  local cursor = rest or ""
  while cursor ~= "" do
    local lenText, tail = string.match(cursor, "^(%d+):(.*)$")
    local len = tonumber(lenText)
    if not len then return nil end
    local key = string.sub(tail, 1, len)
    if #key ~= len then return nil end
    skips[#skips + 1] = key
    cursor = string.sub(tail, len + 1)
    if string.sub(cursor, 1, 1) == "\t" then cursor = string.sub(cursor, 2) end
  end
  local raceId = race ~= "" and race or nil
  return {
    race = raceId,
    chapter = tonumber(chapter),
    step = tonumber(step),
    skips = skips,
  }
end

function L.CopyOptionTable(source)
  local copy = {}
  if type(source) ~= "table" then return copy end
  for key, value in pairs(source) do
    if type(value) == "table" then
      local inner = {}
      for innerKey, innerValue in pairs(value) do
        if type(innerValue) ~= "function" then inner[innerKey] = innerValue end
      end
      copy[key] = inner
    elseif type(value) ~= "function" then
      copy[key] = value
    end
  end
  return copy
end

-- Character options are the table the UI writes. The account copy is a separate
-- table, so a reload cannot alias the two saved files into one object.
function L.RememberSettings(character, account, defaults, useAccount)
  if type(character) ~= "table" then return nil end
  if type(character.options) ~= "table" then character.options = {} end
  if useAccount and type(account) == "table" then
    if type(account.options) ~= "table" then account.options = {} end
    for key, value in pairs(account.options) do
      if character.options[key] == nil then
        if type(value) == "table" then
          character.options[key] = L.CopyOptionTable(value)
        elseif type(value) ~= "function" then
          character.options[key] = value
        end
      end
    end
  end
  if type(defaults) == "table" then
    for key, value in pairs(defaults) do
      if character.options[key] == nil then
        if type(value) == "table" then
          character.options[key] = L.CopyOptionTable(value)
        else
          character.options[key] = value
        end
      end
    end
  end
  if useAccount and type(account) == "table" then
    account.options = L.CopyOptionTable(character.options)
  end
  return character.options
end
