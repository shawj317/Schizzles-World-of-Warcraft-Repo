-- Ashen Trail tracker. Original addon code for WoW Forever.
-- Does not load or call RestedXP. Rules live in Logic.lua.

AshenTrail = AshenTrail or {}
local AT = AshenTrail
local L = AshenTrailLogic

BINDING_HEADER_ASHENTRAIL = "Ashen Trail"
BINDING_NAME_ASHENTRAIL_TOGGLE = "Toggle tracker"
BINDING_NAME_ASHENTRAIL_NEXT = "Next step"

local DEFAULTS = {
  scale = 1,
  alpha = 0.94,
  locked = false,
  showArrow = true,
  arrowMode = "builtin",
  showMinimap = true,
  showNameplates = true,
  showObjectiveCount = true,
  trackTownsfolk = true,
  autoAdvance = true,
  autoRoute = true,
  autoAccept = false,
  autoTurnIn = false,
  autoReward = false,
  guideQuestsOnly = true,
  autoRepair = false,
  skipGossip = false,
  skullMark = false,
  compact = false,
  font = "med",
  fontSize = 13,
  page = "guide",
  theme = "dark",
  chapterMode = "auto",
  showJunk = false,
  autoSellJunk = false,
  discardJunk = false,
  flightTimer = true,
  skipOverleveled = false,
  overlevelGap = 0,
  drownWarn = true,
  drownSeconds = 10,
  arrowScale = 1,
  updateInterval = 0.2,
  routeMode = "speed",
  soundStep = false,
  soundTurnIn = false,
  soundLevel = false,
  skipElites = false,
  eliteWarn = true,
  logHints = true,
  supplyHints = true,
  trainHints = true,
  hearthHints = true,
  rareHints = true,
  gatherHints = true,
}

local function copyDefaults(target)
  for key, value in pairs(DEFAULTS) do
    if target[key] == nil then
      if type(value) == "table" then
        local copy = {}
        for inner, innerValue in pairs(value) do copy[inner] = innerValue end
        target[key] = copy
      else
        target[key] = value
      end
    end
  end
  return target
end

local function cloneOptions(source)
  local copy = {}
  for key, value in pairs(source or {}) do
    if type(value) == "table" then
      local inner = {}
      for innerKey, innerValue in pairs(value) do inner[innerKey] = innerValue end
      copy[key] = inner
    else
      copy[key] = value
    end
  end
  return copy
end

function AT.DB()
  if not AshenTrailChar then AshenTrailChar = {} end
  if not AshenTrailAccount then AshenTrailAccount = {} end
  local db = AshenTrailChar
  db.turnedIn = db.turnedIn or {}
  db.flights = db.flights or {}
  db.history = db.history or { order = {}, byId = {} }
  db.history.order = db.history.order or {}
  db.history.byId = db.history.byId or {}
  if db.useAccount ~= false then
    if not AshenTrailAccount.options then
      AshenTrailAccount.options = cloneOptions(db.options)
    end
    db.options = copyDefaults(AshenTrailAccount.options)
    AshenTrailAccount.options = db.options
  else
    db.options = copyDefaults(db.options or {})
  end
  db.skipped = db.skipped or {}
  db.junkList = db.junkList or {}
  db.junkKeep = db.junkKeep or {}
  db.flightTimes = db.flightTimes or {}
  db.point = db.point or { "CENTER", "CENTER", 0, 0 }
  db.minimapAngle = db.minimapAngle or 220
  db.levels = db.levels or {}
  db.best = db.best or {}
  return db
end

function AT.ExportText()
  local db = AT.DB()
  local skips = {}
  for key, value in pairs(db.skipped or {}) do
    if value then skips[#skips + 1] = key end
  end
  table.sort(skips)
  return L.ExportRoute(db.race, db.chapterIndex or 1, db.step or 1, skips)
end

function AT.ImportText(text)
  local parsed = L.ImportRoute(text)
  if not parsed then
    AT.Say("That route string is not an Ashen Trail export.")
    return
  end
  if parsed.race and AshenTrailData and AshenTrailData.routes and not AshenTrailData.routes[parsed.race] then
    AT.Say("That route is not in this pack.")
    return
  end
  local db = AT.DB()
  if parsed.race then db.race = parsed.race end
  db.chapterIndex = parsed.chapter or 1
  db.step = parsed.step or 1
  local ids = AT.RouteIds()
  if #ids > 0 then
    if db.chapterIndex < 1 then db.chapterIndex = 1 end
    if db.chapterIndex > #ids then db.chapterIndex = #ids end
    local chapter = AshenTrailData.chapters[ids[db.chapterIndex]]
    local steps = chapter and L.VisibleSteps(chapter, db.race, db.class, AT.RaceToken()) or {}
    if db.step < 1 then db.step = 1 end
    if #steps > 0 and db.step > #steps then db.step = #steps end
  end
  db.skipped = {}
  for i = 1, #parsed.skips do db.skipped[parsed.skips[i]] = true end
  db.holdStep = nil
  db.finished = false
  AT.focus = nil
  AT.planKey = nil
  AT.Say("Imported the route position.")
  if AshenTrailUI and AshenTrailUI.Refresh then AshenTrailUI.Refresh() end
end

function AT.SetUseAccount(enabled)
  if not AshenTrailChar then AshenTrailChar = {} end
  if not AshenTrailAccount then AshenTrailAccount = {} end
  local db = AshenTrailChar
  if enabled then
    db.useAccount = true
    if not AshenTrailAccount.options then
      AshenTrailAccount.options = cloneOptions(db.options)
    end
  else
    db.useAccount = false
    db.options = cloneOptions(AshenTrailAccount.options or db.options)
  end
  AT.DB()
end

function AT.Say(text)
  DEFAULT_CHAT_FRAME:AddMessage("|cffff5522Ashen Trail|r " .. tostring(text))
end

function AT.Route()
  local db = AT.DB()
  local routes = AshenTrailData and AshenTrailData.routes
  if not routes or not db.race then return nil end
  return routes[db.race]
end

function AT.RouteIds()
  local route = AT.Route()
  if route and route.chapters then return route.chapters end
  return {}
end

function AT.Chapter()
  local ids = AT.RouteIds()
  local db = AT.DB()
  local id = ids[db.chapterIndex or 1]
  if not id or not AshenTrailData then return nil end
  return AshenTrailData.chapters[id], id
end

function AT.Steps()
  local chapter = AT.Chapter()
  local db = AT.DB()
  if not chapter then return {} end
  return L.VisibleSteps(chapter, db.race, db.class, AT.RaceToken())
end

function AT.CurrentStep()
  local steps = AT.Steps()
  local db = AT.DB()
  return steps[db.step or 1], steps
end

function AT.Context()
  local db = AT.DB()
  local level = UnitLevel and UnitLevel("player") or 1
  local xp, xpMax = 0, 1
  if UnitXP then xp = UnitXP("player") or 0 end
  if UnitXPMax then xpMax = UnitXPMax("player") or 1 end
  return {
    turnedIn = db.turnedIn,
    quests = AT.quests or {},
    level = level,
    xp = xp,
    xpMax = xpMax,
  }
end

function AT.Nodes()
  if AT.nodes then return AT.nodes end
  local places = AshenTrailData and AshenTrailData.places or {}
  local staticNodes = AshenTrailServices and AshenTrailServices.nodes or {}
  AT.nodes = L.MergeNodes(staticNodes, places)
  return AT.nodes
end

local function clampIndex()
  local db = AT.DB()
  local ids = AT.RouteIds()
  if #ids == 0 then return end
  if not db.chapterIndex or db.chapterIndex < 1 then db.chapterIndex = 1 end
  if db.chapterIndex > #ids then db.chapterIndex = #ids end
  local steps = AT.Steps()
  if not db.step or db.step < 1 then db.step = 1 end
  if #steps > 0 and db.step > #steps then db.step = #steps end
end

function AT.SetChapterIndex(index)
  local db = AT.DB()
  db.chapterIndex = index or 1
  db.step = 1
  db.pendingRace = nil
  AT.focus = nil
  AT.planKey = nil
  clampIndex()
  AT.Refresh()
end

function AT.ApplyRace(raceId, resetProgress)
  local db = AT.DB()
  local route = AshenTrailData and AshenTrailData.routes and AshenTrailData.routes[raceId]
  if not route then return end
  local changed = db.race ~= raceId
  db.race = raceId
  db.pendingRace = nil
  AT.focus = nil
  if changed or resetProgress or not db.chapterIndex then
    db.chapterIndex = 1
    db.step = 1
    if resetProgress or changed then
      db.turnedIn = {}
      db.history = { order = {}, byId = {} }
    end
  end
  AT.planKey = nil
  clampIndex()
  if AT.booted then
    AT.PrimeCompleted()
    AT.Sync(true)
  end
  AT.Refresh()
end

function AT.RequestRace(raceId)
  local db = AT.DB()
  if not db.race or db.race == raceId then
    AT.ApplyRace(raceId, false)
    return
  end
  if db.pendingRace == raceId then
    AT.ApplyRace(raceId, true)
    AT.Say("Route switched. Quest progress for the old path was cleared.")
    return
  end
  db.pendingRace = raceId
  AT.Say("Click the race again to switch. That clears tracked turn-ins and restarts the path.")
  AT.Refresh()
end

local function questIdsInRoute()
  local ids = {}
  local seen = {}
  local chapters = AshenTrailData and AshenTrailData.chapters or {}
  local route = AT.RouteIds()
  for ci = 1, #route do
    local chapter = chapters[route[ci]]
    if chapter then
      for si = 1, #(chapter.steps or {}) do
        local lines = chapter.steps[si].lines or {}
        for li = 1, #lines do
          local id = lines[li].id
          if id and not seen[id] then
            seen[id] = true
            ids[#ids + 1] = id
          end
        end
      end
    end
  end
  return ids
end

local function flagged(questId)
  if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
    local ok, result = pcall(C_QuestLog.IsQuestFlaggedCompleted, questId)
    if ok then return result and true or false end
  end
  if IsQuestFlaggedCompleted then
    local ok, result = pcall(IsQuestFlaggedCompleted, questId)
    if ok then return result and true or false end
  end
  return false
end

function AT.PrimeCompleted()
  local db = AT.DB()
  local ids = questIdsInRoute()
  for i = 1, #ids do
    if flagged(ids[i]) then db.turnedIn[ids[i]] = true end
  end
end

local function rememberQuest(questId, title, state)
  AT.quests = AT.quests or {}
  AT.questNames = AT.questNames or {}
  if questId then
    AT.quests[questId] = state
    if title and title ~= "" then AT.questNames[questId] = title end
  end
end

local function scanRetail()
  if not (C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo) then
    return false
  end
  local count = C_QuestLog.GetNumQuestLogEntries()
  for i = 1, count do
    local info = C_QuestLog.GetInfo(i)
    if info and not info.isHeader and info.questID and info.questID > 0 then
      local complete = false
      if C_QuestLog.IsComplete then
        complete = C_QuestLog.IsComplete(info.questID) and true or false
      elseif info.isComplete then
        complete = true
      end
      rememberQuest(info.questID, info.title, complete and "complete" or "active")
    end
  end
  return true
end

local function scanClassic()
  if not GetNumQuestLogEntries or not GetQuestLogTitle then return end
  local selected = GetQuestLogSelection and GetQuestLogSelection() or nil
  local num = GetNumQuestLogEntries()
  for i = 1, num do
    local title, _, _, isHeader, _, isComplete, _, questID = GetQuestLogTitle(i)
    if not isHeader and questID and questID > 0 then
      local state = (isComplete == 1 or isComplete == true) and "complete" or "active"
      rememberQuest(questID, title, state)
    end
  end
  if selected and SelectQuestLogEntry then SelectQuestLogEntry(selected) end
end

function AT.ScanQuests()
  local previous = AT.quests or {}
  AT.quests = {}
  local usedRetail = scanRetail()
  if not usedRetail then scanClassic() end
  local db = AT.DB()
  for questId, state in pairs(previous) do
    if state == "complete" and not AT.quests[questId] then
      AT.MarkTurnedIn(questId, AT.questNames and AT.questNames[questId])
    end
  end
  db.questsSeen = true
end

function AT.MarkTurnedIn(questId, name)
  if not questId then return end
  local db = AT.DB()
  local already = db.turnedIn[questId]
  db.turnedIn[questId] = true
  local history = db.history
  local row = history.byId[questId]
  if not row then
    row = { name = name or ("Quest " .. tostring(questId)), turned = time and time() or 0 }
    history.byId[questId] = row
    history.order[#history.order + 1] = questId
    while #history.order > 200 do
      local old = table.remove(history.order, 1)
      history.byId[old] = nil
    end
  elseif name and name ~= "" then
    row.name = name
  end
  if not already then AT.planKey = nil end
end

function AT.RecordAccepted(questId, name)
  if not questId then return end
  local db = AT.DB()
  local history = db.history
  local row = history.byId[questId]
  if not row then
    history.byId[questId] = { name = name or ("Quest " .. tostring(questId)), accepted = time and time() or 0 }
  elseif name then
    row.name = name
  end
end

local function stepIsBehind(index, steps)
  local ctx = AT.Context()
  local status = L.StepStatus(steps[index], ctx)
  if status == "done" then return true end
  if status ~= "manual" then return false end
  local db = AT.DB()
  local chapter = AT.Chapter()
  local later = L.LaterHardDone(AT.RouteIds(), AshenTrailData.chapters, db.chapterIndex or 1, index, db.race, db.class, ctx, AT.RaceToken())
  local level = UnitLevel and UnitLevel("player") or 1
  return L.ManualIsBehind(level, L.ChapterEndLevel(chapter and chapter.levelRange), later)
end

local function leaveChapter(db)
  if L.MayLeaveChapter(db.options.chapterMode) then
    AT.toldChapterEnd = nil
    return true
  end
  if not AT.toldChapterEnd then
    AT.toldChapterEnd = true
    AT.Say("This chapter is finished. Choose the next chapter, or set Chapters back to Auto.")
  end
  return false
end

function AT.AdvanceDone(aggressive)
  local db = AT.DB()
  local auto = aggressive or (db.options and db.options.autoAdvance ~= false)
  if not auto and not (db.options and db.options.skipOverleveled) then return end
  local guard = 0
  local cuedStep = false
  while guard < 80 do
    guard = guard + 1
    local steps = AT.Steps()
    local index = db.step or 1
    local step = steps[index]
    if not step then
      local ids = AT.RouteIds()
      if (db.chapterIndex or 1) < #ids and leaveChapter(db) then
        db.chapterIndex = (db.chapterIndex or 1) + 1
        db.step = 1
        AT.focus = nil
        AT.planKey = nil
      else
        if L.MayLeaveChapter(db.options.chapterMode) then db.finished = true end
        break
      end
    else
      db.finished = false
      local chapter, chapterId = AT.Chapter()
      local skipped = AT.IsSkipped(chapterId, step)
      local ctx = AT.Context()
      local status = L.StepStatus(step, ctx)
      local over = false
      if db.options.skipOverleveled then
        over = L.Overleveled(ctx.level, L.ChapterEndLevel(chapter and chapter.levelRange), db.options.overlevelGap)
          and not L.StepHoldsQuest(step, ctx)
      end
      if db.holdStep then
        break
      end
      local eliteMove = false
      if db.options.skipElites and AT.StepThreat then
        local elite, group = AT.StepThreat(step)
        eliteMove = elite or (group and group > 1)
      end
      local move = (auto and status == "done") or skipped or over or eliteMove or (aggressive and stepIsBehind(index, steps))
      if move then
        if auto and status == "done" and not cuedStep then
          cuedStep = true
          AT.Cue("step")
        end
        db.holdStep = nil
        if index < #steps then
          db.step = index + 1
        else
          local ids = AT.RouteIds()
          if (db.chapterIndex or 1) < #ids and leaveChapter(db) then
            db.chapterIndex = db.chapterIndex + 1
            db.step = 1
          else
            db.step = index
            if L.MayLeaveChapter(db.options.chapterMode) then db.finished = true end
            break
          end
        end
        AT.focus = nil
        AT.planKey = nil
        AT.announced = {}
      else
        break
      end
    end
  end
  clampIndex()
end

function AT.Sync(aggressive)
  if not AT.DB().race then
    AT.Refresh()
    return
  end
  AT.ScanQuests()
  AT.AdvanceDone(aggressive and true or false)
  AT.questItemDirty = true
  AT.UpdateTargetMacro()
  AT.Refresh()
end

function AT.Next()
  local db = AT.DB()
  local steps = AT.Steps()
  local index = db.step or 1
  if index < #steps then
    db.step = index + 1
  else
    local ids = AT.RouteIds()
    if (db.chapterIndex or 1) < #ids and leaveChapter(db) then
      db.chapterIndex = db.chapterIndex + 1
      db.step = 1
    elseif L.MayLeaveChapter(db.options.chapterMode) then
      db.finished = true
    end
  end
  db.holdStep = nil
  AT.focus = nil
  AT.planKey = nil
  AT.announced = {}
  AT.questItemDirty = true
  AT.UpdateTargetMacro()
  AT.Refresh()
end

function AT.GoToStep(index)
  local db = AT.DB()
  local steps = AT.Steps()
  index = tonumber(index)
  if not index or not steps[index] then return end
  db.finished = false
  db.step = index
  db.holdStep = true
  AT.focus = nil
  AT.planKey = nil
  AT.announced = {}
  AT.questItemDirty = true
  AT.UpdateTargetMacro()
  AT.Refresh()
end

function AT.ToggleStep(index)
  local db = AT.DB()
  local steps = AT.Steps()
  index = tonumber(index)
  local step = index and steps[index]
  if not step then return end
  db.finished = false
  local _, chapterId = AT.Chapter()
  db.skipped = db.skipped or {}
  local key = L.StepKey(chapterId, step)
  AT.focus = nil
  AT.planKey = nil
  if db.skipped[key] then
    db.skipped[key] = nil
    if (db.step or 1) >= index then
      db.step = index
      db.holdStep = true
    end
    AT.Say("Step " .. index .. " is not complete.")
    AT.questItemDirty = true
    AT.UpdateTargetMacro()
    AT.Refresh()
    return
  end
  db.skipped[key] = true
  db.holdStep = nil
  AT.Say("Skipped step " .. index .. ".")
  if (db.step or 1) == index then
    AT.Next()
    return
  end
  AT.UpdateTargetMacro()
  AT.Refresh()
end

function AT.Prev()
  local db = AT.DB()
  db.finished = false
  local index = db.step or 1
  if index > 1 then
    db.step = index - 1
  elseif (db.chapterIndex or 1) > 1 then
    db.chapterIndex = db.chapterIndex - 1
    local steps = AT.Steps()
    db.step = math.max(1, #steps)
  end
  AT.focus = nil
  AT.planKey = nil
  db.holdStep = true
  AT.questItemDirty = true
  AT.UpdateTargetMacro()
  AT.Refresh()
end

function AT.IsSkipped(chapterId, step)
  local db = AT.DB()
  if not step or not db.skipped then return false end
  return db.skipped[L.StepKey(chapterId, step)] and true or false
end

function AT.Skip()
  local db = AT.DB()
  local _, chapterId = AT.Chapter()
  local step = AT.CurrentStep()
  if not step or db.finished then
    AT.Say("Nothing to skip.")
    return
  end
  db.skipped[L.StepKey(chapterId, step)] = true
  db.holdStep = nil
  AT.Say("Skipped this step.")
  AT.Next()
end

function AT.Unskip()
  local db = AT.DB()
  local _, chapterId = AT.Chapter()
  local step = AT.CurrentStep()
  if not step then return end
  db.skipped[L.StepKey(chapterId, step)] = nil
  db.holdStep = true
  AT.Say("This step is active again.")
  AT.Refresh()
end

function AT.PlayerPos()
  local zone = GetZoneText and GetZoneText() or nil
  if not zone or zone == "" then zone = GetRealZoneText and GetRealZoneText() or nil end
  local x, y, mapID
  if C_Map and C_Map.GetBestMapForUnit then
    mapID = C_Map.GetBestMapForUnit("player")
    if mapID and C_Map.GetPlayerMapPosition then
      local pos = C_Map.GetPlayerMapPosition(mapID, "player")
      if pos then
        local px = pos.x or pos:GetXY()
        local py = pos.y
        if pos.GetXY and not pos.x then px, py = pos:GetXY() end
        if px and px > 0 then x, y = px * 100, (py or 0) * 100 end
      end
    end
  end
  if not x and GetPlayerMapPosition then
    if SetMapToCurrentZone then pcall(SetMapToCurrentZone) end
    local px, py = GetPlayerMapPosition("player")
    if px and px > 0 then x, y = px * 100, py * 100 end
  end
  local hearthBind = GetBindLocation and GetBindLocation() or nil
  local hearthReady = false
  if GetItemCooldown then
    local start, duration = GetItemCooldown(6948)
    hearthReady = start ~= nil and (start == 0 or duration == 0)
  else
    hearthReady = true
  end
  return {
    zone = zone,
    x = x,
    y = y,
    mapID = mapID,
    hearthBind = hearthBind,
    hearthReady = hearthReady,
  }
end

function AT.KnownFlights()
  local db = AT.DB()
  local known = {}
  for key, value in pairs(db.flights or {}) do
    if value then known[key] = true end
  end
  local chapters = AshenTrailData.chapters
  local route = AT.RouteIds()
  local dbIndex = db.chapterIndex or 1
  local dbStep = db.step or 1
  for ci = 1, #route do
    if ci > dbIndex then break end
    local chapter = chapters[route[ci]]
    if chapter then
      local steps = L.VisibleSteps(chapter, db.race, db.class, AT.RaceToken())
      local last = (ci == dbIndex) and (dbStep - 1) or #steps
      for si = 1, last do
        local lines = steps[si] and steps[si].lines or {}
        for li = 1, #lines do
          if lines[li].k == "fp" and lines[li].place then
            known[string.lower(lines[li].place)] = true
          end
        end
      end
    end
  end
  return known
end

function AT.Destination()
  if AT.focus and AT.focus.zone then
    return { zone = AT.focus.zone, x = AT.focus.x, y = AT.focus.y, name = AT.focus.name or AT.focus.zone }
  end
  local step = AT.CurrentStep()
  local pin = L.ActivePin(step, AT.Context())
  if pin then
    return { zone = pin.zone, x = pin.x, y = pin.y, name = pin.name or pin.zone }
  end
  local chapter = AT.Chapter()
  if chapter then return { zone = chapter.zone, name = chapter.name } end
  return nil
end

function AT.PlanCurrent()
  local db = AT.DB()
  if not db.options.autoRoute then return nil end
  local dest = AT.Destination()
  local origin = AT.PlayerPos()
  if not dest or not origin.zone then return nil end
  local now = GetTime and GetTime() or 0
  local key = table.concat({
    tostring(origin.mapID or origin.zone or ""),
    dest.zone or "",
    string.format("%.1f", dest.x or -1),
    string.format("%.1f", dest.y or -1),
    origin.hearthBind or "",
    origin.hearthReady and "1" or "0",
    tostring(db.chapterIndex or 1),
    tostring(db.step or 1),
  }, "|")
  if AT.plan and AT.planKey == key then return AT.plan end
  if AT.plan and AT.planAt and not AT.planForce and (now - AT.planAt) < 2 then
    return AT.plan
  end
  AT.planForce = nil
  AT.planKey = key
  AT.planAt = now
  AT.plan = L.Plan(
    AT.Nodes(),
    AshenTrailServices and AshenTrailServices.links,
    AshenTrailServices and AshenTrailServices.borders,
    origin,
    dest,
    AT.KnownFlights()
  )
  return AT.plan
end

function AT.LearnFlights()
  if not NumTaxiNodes or not TaxiNodeName or not TaxiNodeGetType then return end
  local db = AT.DB()
  local count = NumTaxiNodes()
  for i = 1, count do
    local kind = TaxiNodeGetType(i)
    if kind == "CURRENT" or kind == "REACHABLE" or kind == 0 or kind == 1 then
      local name = TaxiNodeName(i)
      if name and name ~= "" then db.flights[string.lower(name)] = true end
    end
  end
  AT.planKey = nil
end

local function macroText(name)
  return L.TargetMacro(name, AT.DB().options.skullMark)
end

function AT.GuidePins()
  local _, steps = AT.CurrentStep()
  return L.GuidePins(steps, AT.DB().step or 1)
end

local function itemFromLink(link, texture)
  if type(link) ~= "string" or link == "" then return nil end
  local name = string.match(link, "%[(.-)%]")
  if not name or name == "" then return nil end
  return { name = name, link = link, texture = texture }
end

function AT.ActiveQuestItem()
  local step = AT.CurrentStep()
  if not step then return nil end
  local wanted = {}
  local any = false
  for i = 1, #(step.lines or {}) do
    local id = step.lines[i].id
    if id then
      wanted[id] = true
      wanted[tostring(id)] = true
      any = true
    end
  end
  if not any then return nil end
  local function wantedId(id)
    return id and (wanted[id] or wanted[tostring(id)])
  end
  if GetNumQuestLogEntries and GetQuestLogTitle and GetQuestLogSpecialItemInfo then
    local count = GetNumQuestLogEntries() or 0
    for i = 1, count do
      local results = { pcall(GetQuestLogTitle, i) }
      if results[1] and not results[5] and wantedId(results[9]) then
        local ok, link, texture = pcall(GetQuestLogSpecialItemInfo, i)
        local item = ok and itemFromLink(link, texture)
        if item then return item end
      end
    end
  end
  if C_Container and C_Container.GetContainerNumSlots then
    for bag = 0, 4 do
      local slots = C_Container.GetContainerNumSlots(bag) or 0
      for slot = 1, slots do
        local link = C_Container.GetContainerItemLink(bag, slot)
        local questId
        if C_Container.GetContainerItemQuestInfo then
          local ok, info = pcall(C_Container.GetContainerItemQuestInfo, bag, slot)
          if ok and type(info) == "table" then questId = info.questID or info.questId end
        end
        if wantedId(questId) then
          local item = itemFromLink(link)
          if item then return item end
        end
      end
    end
  elseif GetContainerItemQuestInfo and GetContainerNumSlots and GetContainerItemLink then
    local maxBag = NUM_BAG_SLOTS or 4
    for bag = 0, maxBag do
      local slots = GetContainerNumSlots(bag) or 0
      for slot = 1, slots do
        local link = GetContainerItemLink(bag, slot)
        local ok, _, questId = pcall(GetContainerItemQuestInfo, bag, slot)
        if ok and wantedId(questId) then
          local item = itemFromLink(link)
          if item then return item end
        end
      end
    end
  end
end

function AT.UpdateQuestItemButton()
  local button = _G.AshenTrailQuestItemButton
  if not button or not button.SetAttribute then return end
  if InCombatLockdown and InCombatLockdown() then
    AT.pendingItem = true
    return
  end
  local now = GetTime and GetTime() or 0
  if not AT.questItemDirty and AT.questItemAt and (now - AT.questItemAt) < 2 then
    return
  end
  AT.questItemDirty = false
  AT.questItemAt = now
  AT.pendingItem = false
  local item = AT.ActiveQuestItem()
  local holder = button.holder or button:GetParent()
  if not item or AT.DB().hidden then
    button:SetAttribute("item", nil)
    if holder then holder:Hide() end
    AT.questItem = nil
    return
  end
  AT.questItem = item
  button:SetAttribute("type", "item")
  button:SetAttribute("item", item.name)
  button:SetText(item.name)
  if holder then holder:Show() end
end

function AT.TalentLine()
  if InCombatLockdown and InCombatLockdown() then return AT.talentText end
  if not UnitLevel or not UnitCharacterPoints then
    AT.talentText = nil
    return nil
  end
  local okL, level = pcall(UnitLevel, "player")
  local okP, points = pcall(UnitCharacterPoints, "player")
  if not okL or not okP then return AT.talentText end
  local advice = L.NextTalent(AT.DB().class, level, points)
  if not advice then
    AT.talentText = nil
    return nil
  end
  if advice.done then
    AT.talentText = tostring(advice.unspent) .. " points unspent"
  else
    AT.talentText = "Next: " .. advice.name
  end
  return AT.talentText
end

function AT.UpdateTargetMacro()
  local button = _G.AshenTrailTargetButton
  if not button or not button.SetAttribute then return end
  if InCombatLockdown and InCombatLockdown() then
    AT.pendingMacro = true
    return
  end
  AT.pendingMacro = false
  local step = AT.CurrentStep()
  local name = L.TargetName(step)
  AT.targetName = name
  if not name then
    button:SetAttribute("macrotext", "")
    return
  end
  button:SetAttribute("macrotext", macroText(name))
end

function AT.ObjectiveWatch()
  local step = AT.CurrentStep()
  local objectives = {}
  if not step then return objectives end
  local wanted = {}
  for _, line in ipairs(step.lines or {}) do
    if line.id and (line.k == "complete" or line.k == "mob") then wanted[line.id] = true end
  end
  local function push(text)
    local parsed = L.ParseObjective(text)
    if parsed then
      parsed.kind = "spawn"
      objectives[#objectives + 1] = parsed
    end
  end
  if C_QuestLog and C_QuestLog.GetQuestObjectives then
    for questId in pairs(wanted) do
      local ok, rows = pcall(C_QuestLog.GetQuestObjectives, questId)
      if ok and rows then
        for i = 1, #rows do
          if rows[i].text then push(rows[i].text) end
        end
      end
    end
    return objectives
  end
  if not GetNumQuestLogEntries or not GetQuestLogTitle then return objectives end
  local selected = GetQuestLogSelection and GetQuestLogSelection() or nil
  local num = GetNumQuestLogEntries()
  for i = 1, num do
    local _, _, _, isHeader, _, _, _, questID = GetQuestLogTitle(i)
    if not isHeader and questID and wanted[questID] and SelectQuestLogEntry and GetNumQuestLeaderBoards then
      SelectQuestLogEntry(i)
      local boards = GetNumQuestLeaderBoards(i) or GetNumQuestLeaderBoards() or 0
      for b = 1, boards do
        local text = GetQuestLogLeaderBoard(b, i) or GetQuestLogLeaderBoard(b)
        if text then push(text) end
      end
    end
  end
  if selected and SelectQuestLogEntry then SelectQuestLogEntry(selected) end
  return objectives
end

function AT.Watch()
  local step = AT.CurrentStep()
  local watch = { exact = {}, objectives = AT.ObjectiveWatch(), services = {} }
  local name = L.TargetName(step)
  if name then
    local kind = "spawn"
    for _, line in ipairs(step and step.lines or {}) do
      if line.k == "turnin" then kind = "turnin" end
      if line.k == "accept" and kind ~= "turnin" then kind = "giver" end
    end
    watch.exact[string.lower(name)] = { kind = kind, name = name }
  end
  for _, line in ipairs(step and step.lines or {}) do
    if (line.k == "unitscan" or line.k == "mob" or line.k == "target") and line.name then
      watch.exact[string.lower(line.name)] = watch.exact[string.lower(line.name)] or { kind = "spawn", name = line.name }
    end
  end
  local db = AT.DB()
  if db.options.trackTownsfolk then
    local zone = GetZoneText and GetZoneText() or nil
    local nodes = AT.Nodes()
    for i = 1, #nodes do
      local node = nodes[i]
      if node.zone == zone and node.name and (node.kind == "trainer" or node.kind == "inn" or node.kind == "fp") then
        watch.services[#watch.services + 1] = node
      end
    end
  end
  return watch
end

local plateOverlays = {}

local function plateFrame(unit)
  if C_NamePlate and C_NamePlate.GetNamePlateForUnit then
    local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, unit)
    if ok then return plate end
  end
  local base = _G[unit]
  return base
end

local function iconFor(kind)
  if kind == "giver" then return "Interface\\GossipFrame\\AvailableQuestIcon" end
  if kind == "turnin" then return "Interface\\GossipFrame\\ActiveQuestIcon" end
  if kind == "fp" then return "Interface\\Minimap\\Tracking\\FlightMaster" end
  if kind == "inn" then return "Interface\\Minimap\\Tracking\\Innkeeper" end
  if kind == "trainer" then return "Interface\\Minimap\\Tracking\\Profession" end
  if kind == "repair" then return "Interface\\Minimap\\Tracking\\Repair" end
  return "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8"
end

local function overlayFor(plate)
  local overlay = plateOverlays[plate]
  if overlay then return overlay end
  overlay = CreateFrame("Frame", nil, UIParent)
  overlay:SetSize(26, 26)
  overlay:SetFrameStrata("HIGH")
  overlay.icon = overlay:CreateTexture(nil, "OVERLAY")
  overlay.icon:SetAllPoints()
  overlay.text = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  overlay.text:SetPoint("LEFT", overlay, "RIGHT", 2, 0)
  overlay.text:SetJustifyH("LEFT")
  plateOverlays[plate] = overlay
  return overlay
end

local function placeOverlay(overlay, plate)
  overlay:ClearAllPoints()
  local parented = false
  if plate then
    parented = pcall(function()
      overlay:SetParent(plate)
      overlay:SetPoint("BOTTOM", plate, "TOP", 0, 4)
    end)
  end
  if not parented and plate and plate.GetCenter then
    overlay:SetParent(UIParent)
    local x, y = plate:GetCenter()
    if x and y then
      overlay:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y + 28)
    end
  end
end

function AT.RefreshNameplates()
  local db = AT.DB()
  local seen = {}
  if InCombatLockdown and InCombatLockdown() then return end
  if not db.options.showNameplates or db.hidden then
    for _, overlay in pairs(plateOverlays) do overlay:Hide() end
    return
  end
  local watch = AT.Watch()
  local function consider(unit)
    if not UnitExists or not UnitExists(unit) then return end
    local okName, unitName = pcall(UnitName, unit)
    if not okName or not unitName or unitName == "" then return end
    local match = L.MatchPlate(unitName, watch)
    local plate = plateFrame(unit)
    if not plate then return end
    seen[plate] = true
    local overlay = overlayFor(plate)
    if not match then
      overlay:Hide()
      return
    end
    overlay.icon:SetTexture(iconFor(match.kind))
    local text = ""
    if db.options.showObjectiveCount and match.text then text = match.text end
    overlay.text:SetText(text)
    placeOverlay(overlay, plate)
    overlay:Show()
    local step = AT.CurrentStep()
    if step then
      for _, line in ipairs(step.lines or {}) do
        if line.k == "unitscan" and L.NamesMatch(unitName, line.name) then
          AT.announced = AT.announced or {}
          local key = string.lower(line.name)
          if not AT.announced[key] then
            AT.announced[key] = true
            AT.Say(line.name .. " is on your screen.")
          end
        end
      end
    end
  end
  local usedPlates = false
  if C_NamePlate and C_NamePlate.GetNamePlates then
    local okPlates, plates = pcall(C_NamePlate.GetNamePlates)
    if okPlates and type(plates) == "table" then
      usedPlates = true
      for i = 1, #plates do
        local plate = plates[i]
        local unit = plate.namePlateUnitToken or plate.unitToken
        if unit then consider(unit) end
      end
    end
  end
  if not usedPlates then
    for i = 1, 40 do
      consider("nameplate" .. i)
    end
  end
  for plate, overlay in pairs(plateOverlays) do
    if not seen[plate] then overlay:Hide() end
  end
end

local function worldPos(mapID, x, y)
  if not mapID or not x or not y or not C_Map or not C_Map.GetWorldPosFromMapPos then return nil end
  local vec = { x = x / 100, y = y / 100 }
  if CreateVector2D then
    local okVec, made = pcall(CreateVector2D, x / 100, y / 100)
    if okVec and made then vec = made end
  end
  local ok, first, second, third = pcall(C_Map.GetWorldPosFromMapPos, mapID, vec)
  if not ok then return nil end
  if type(second) == "number" and type(third) == "number" then return second, third end
  if type(second) == "table" and second.x then return second.x, second.y end
  if type(first) == "table" and first.x then return first.x, first.y end
  return nil
end

function AT.WorldDistance(mapID, ax, ay, bx, by)
  local axw, ayw = worldPos(mapID, ax, ay)
  local bxw, byw = worldPos(mapID, bx, by)
  if not axw or not bxw then return nil end
  return L.Distance(axw, ayw, bxw, byw)
end

function AT.WorldDelta(mapID, ax, ay, bx, by)
  local axw, ayw = worldPos(mapID, ax, ay)
  local bxw, byw = worldPos(mapID, bx, by)
  if not axw or not bxw then return nil end
  return bxw - axw, byw - ayw
end

function AT.ArrowGoal()
  local origin = AT.PlayerPos()
  local dest = AT.Destination()
  if not dest then return nil end
  if origin.zone and dest.zone and origin.zone == dest.zone and dest.x then
    return { zone = dest.zone, x = dest.x, y = dest.y, label = dest.name or "Step", mapID = origin.mapID, kind = "pin" }
  end
  local plan = AT.PlanCurrent()
  local hop = L.FirstWaypoint(plan)
  if hop and hop.zone then
    return {
      zone = hop.zone,
      x = hop.x,
      y = hop.y,
      label = hop.label or hop.kind,
      here = origin.zone == hop.zone,
      mapID = origin.mapID,
      kind = hop.kind,
    }
  end
  return { zone = dest.zone, label = dest.name or dest.zone, kind = "text" }
end

function AT.ClearTomTom()
  if AT.tomtomWp and TomTom and TomTom.RemoveWaypoint then
    pcall(function() TomTom:RemoveWaypoint(AT.tomtomWp) end)
  end
  AT.tomtomWp = nil
  AT.tomtomKey = nil
end

function AT.TomTomReady()
  return TomTom and type(TomTom.AddWaypoint) == "function"
end

local function tomtom(goal)
  if not AT.TomTomReady() then return end
  if not goal or not goal.x then
    AT.ClearTomTom()
    return
  end
  if not goal.here and goal.kind ~= "pin" then
    AT.ClearTomTom()
    return
  end
  local origin = AT.PlayerPos()
  if not origin.mapID then return end
  local key = tostring(origin.mapID) .. ":" .. string.format("%.2f", goal.x) .. ":" .. string.format("%.2f", goal.y)
  if AT.tomtomKey == key then return end
  AT.ClearTomTom()
  local title = "Ashen Trail: " .. (goal.label or "Step")
  local ok, wp = pcall(function()
    return TomTom:AddWaypoint(origin.mapID, goal.x / 100, goal.y / 100, {
      title = title,
      persistent = false,
      minimap = true,
      world = true,
      from = "Ashen Trail",
      crazy = true,
    })
  end)
  if ok and wp then
    AT.tomtomWp = wp
    AT.tomtomKey = key
    if TomTom.SetCrazyArrow then
      pcall(function() TomTom:SetCrazyArrow(wp, 0, title) end)
    end
  end
end

function AT.RefreshArrow()
  local goal = AT.ArrowGoal()
  local db = AT.DB()
  local useTom = db.options.showArrow ~= false and db.options.arrowMode == "tomtom" and AT.TomTomReady()
  if useTom then
    tomtom(goal)
  else
    AT.ClearTomTom()
  end
  if AshenTrailUI and AshenTrailUI.UpdateArrow then
    AshenTrailUI.UpdateArrow(goal, AT.PlayerPos())
  end
end

function AT.OnRoute(kind, questId, title)
  local db = AT.DB()
  if db.options.guideQuestsOnly == false then return true end
  if not AshenTrailData then return false end
  return L.QuestOnRoute(AshenTrailData.chapters, AT.RouteIds(), db.race, db.class, kind, questId, title, AT.RaceToken())
end

function AT.WantsQuest(kind, questId, title)
  local opt = AT.DB().options
  if kind == "accept" and not opt.autoAccept then return false end
  if kind == "turnin" and not opt.autoTurnIn then return false end
  return AT.OnRoute(kind, questId, title)
end

function AT.TitleComplete(title, questId)
  if questId and AT.quests and AT.quests[questId] == "complete" then return true end
  if not title or not AT.questNames or not AT.quests then return false end
  local want = string.lower(title)
  for id, name in pairs(AT.questNames) do
    if AT.quests[id] == "complete" and name and string.lower(name) == want then return true end
  end
  return false
end

function AT.HandleQuestDetail()
  local id = GetQuestID and GetQuestID() or nil
  local title = GetTitleText and GetTitleText() or nil
  if not AT.WantsQuest("accept", id, title) then return end
  if AcceptQuest then pcall(AcceptQuest) end
end

function AT.HandleQuestProgress()
  if not IsQuestCompletable or not IsQuestCompletable() then return end
  local id = GetQuestID and GetQuestID() or nil
  local title = GetTitleText and GetTitleText() or nil
  if not AT.WantsQuest("turnin", id, title) then return end
  AT.expectReward = true
  if CompleteQuest then pcall(CompleteQuest) end
end

function AT.HandleQuestReward()
  if not AT.DB().options.autoReward then return end
  local id = GetQuestID and GetQuestID() or nil
  local title = GetTitleText and GetTitleText() or nil
  local guided = AT.DB().options.guideQuestsOnly ~= false
  if guided and not AT.expectReward and not AT.OnRoute("turnin", id, title) then return end
  AT.expectReward = nil
  local num = GetNumQuestChoices and GetNumQuestChoices() or 0
  local best = AT.RewardAdvice()
  local slot = L.RewardSlot(num, best and best.index)
  if not GetQuestReward then return end
  local ok = pcall(GetQuestReward, slot)
  if not ok then return end
  if best and best.name and num > 1 then
    AT.Say("Took reward: " .. best.name .. ".")
  elseif title and title ~= "" then
    AT.Say("Turned in: " .. title .. ".")
  end
end

local function gossipClickAllowed()
  local now = GetTime and GetTime() or 0
  if AT.lastGossip and (now - AT.lastGossip) < 0.15 then return false end
  if (AT.gossipClicks or 0) > 6 then return false end
  AT.lastGossip = now
  AT.gossipClicks = (AT.gossipClicks or 0) + 1
  return true
end

function AT.GossipOptions()
  if C_GossipInfo and C_GossipInfo.GetOptions then
    local ok, list = pcall(C_GossipInfo.GetOptions)
    if ok and type(list) == "table" and #list > 0 then
      local out = {}
      for i = 1, #list do
        local opt = list[i]
        if type(opt) == "table" then
          out[#out + 1] = {
            index = i,
            id = opt.gossipOptionID or opt.orderIndex,
            name = opt.name,
            type = opt.type,
            modern = true,
          }
        end
      end
      if #out > 0 then return out end
    end
  end
  if not GetGossipOptions then return {} end
  local data = { GetGossipOptions() }
  local out = {}
  local n = 0
  for i = 1, #data, 2 do
    if type(data[i]) == "string" then
      n = n + 1
      out[#out + 1] = { index = n, name = data[i], type = data[i + 1] or "gossip", modern = false }
    end
  end
  return out
end

local function gossipQuestCount()
  local modern, classic = 0, 0
  local sawModern = false
  if C_GossipInfo and C_GossipInfo.GetNumAvailableQuests then
    local okA, available = pcall(C_GossipInfo.GetNumAvailableQuests)
    local okB, active = pcall(C_GossipInfo.GetNumActiveQuests)
    if okA and type(available) == "number" then
      sawModern = true
      modern = modern + available
    end
    if okB and type(active) == "number" then
      sawModern = true
      modern = modern + active
    end
  end
  if GetNumGossipAvailableQuests then classic = classic + (GetNumGossipAvailableQuests() or 0) end
  if GetNumGossipActiveQuests then classic = classic + (GetNumGossipActiveQuests() or 0) end
  if sawModern and classic > 0 then return math.max(modern, classic) end
  if sawModern then return modern end
  return classic
end

local function flatQuests(reader, strideGuess)
  local out = {}
  if not reader then return out end
  local data = { reader() }
  if #data == 0 then return out end
  local stride = strideGuess
  if #data % stride ~= 0 then
    if #data % 8 == 0 then stride = 8
    elseif #data % 6 == 0 then stride = 6
    elseif #data % 7 == 0 then stride = 7 end
  end
  local n = 0
  for i = 1, #data, stride do
    if type(data[i]) == "string" then
      n = n + 1
      out[#out + 1] = { index = n, title = data[i] }
    end
  end
  return out
end

function AT.GossipAvailable()
  if C_GossipInfo and C_GossipInfo.GetAvailableQuests then
    local ok, list = pcall(C_GossipInfo.GetAvailableQuests)
    if ok and type(list) == "table" then
      local out = {}
      for i = 1, #list do
        local quest = list[i]
        if type(quest) == "table" then
          out[#out + 1] = { id = quest.questID or quest.questId, title = quest.title or quest.name, modern = true }
        end
      end
      return out
    end
  end
  return flatQuests(GetGossipAvailableQuests, 7)
end

function AT.GossipActive()
  if C_GossipInfo and C_GossipInfo.GetActiveQuests then
    local ok, list = pcall(C_GossipInfo.GetActiveQuests)
    if ok and type(list) == "table" then
      local out = {}
      for i = 1, #list do
        local quest = list[i]
        if type(quest) == "table" then
          out[#out + 1] = {
            id = quest.questID or quest.questId,
            title = quest.title or quest.name,
            complete = quest.isComplete and true or false,
            modern = true,
          }
        end
      end
      return out
    end
  end
  local rows = flatQuests(GetGossipActiveQuests, 6)
  for i = 1, #rows do
    rows[i].complete = AT.TitleComplete(rows[i].title)
  end
  return rows
end

local function clickGossipQuest(quest, which)
  if quest.modern and quest.id and C_GossipInfo then
    if which == "active" and C_GossipInfo.SelectActiveQuest then
      pcall(C_GossipInfo.SelectActiveQuest, quest.id)
      return
    end
    if which == "available" and C_GossipInfo.SelectAvailableQuest then
      pcall(C_GossipInfo.SelectAvailableQuest, quest.id)
      return
    end
  end
  if which == "active" and SelectGossipActiveQuest then
    pcall(SelectGossipActiveQuest, quest.index)
  elseif which == "available" and SelectGossipAvailableQuest then
    pcall(SelectGossipAvailableQuest, quest.index)
  end
end

function AT.SelectGossipQuest()
  local active = AT.GossipActive()
  for i = 1, #active do
    local quest = active[i]
    local complete = quest.complete or AT.TitleComplete(quest.title, quest.id)
    if complete and AT.WantsQuest("turnin", quest.id, quest.title) and gossipClickAllowed() then
      clickGossipQuest(quest, "active")
      return true
    end
  end
  local available = AT.GossipAvailable()
  for i = 1, #available do
    local quest = available[i]
    if AT.WantsQuest("accept", quest.id, quest.title) and gossipClickAllowed() then
      clickGossipQuest(quest, "available")
      return true
    end
  end
  return false
end

function AT.SkipLoneGossip()
  if not AT.DB().options.skipGossip then return end
  if gossipQuestCount() > 0 then return end
  local options = AT.GossipOptions()
  local index = L.LoneGossip(options)
  if not index or not gossipClickAllowed() then return end
  local choice = options[index]
  if choice.modern and choice.id and C_GossipInfo and C_GossipInfo.SelectOption then
    pcall(C_GossipInfo.SelectOption, choice.id)
  elseif SelectGossipOption and choice.index then
    pcall(SelectGossipOption, choice.index)
  end
end

function AT.HandleGreeting()
  if AT.DB().options.autoTurnIn and GetNumActiveQuests and GetActiveTitle and SelectActiveQuest then
    for i = 1, (GetNumActiveQuests() or 0) do
      local title = GetActiveTitle(i)
      if AT.TitleComplete(title) and AT.WantsQuest("turnin", nil, title) and gossipClickAllowed() then
        pcall(SelectActiveQuest, i)
        return
      end
    end
  end
  if AT.DB().options.autoAccept and GetNumAvailableQuests and GetAvailableTitle and SelectAvailableQuest then
    for i = 1, (GetNumAvailableQuests() or 0) do
      local title = GetAvailableTitle(i)
      if AT.WantsQuest("accept", nil, title) and gossipClickAllowed() then
        pcall(SelectAvailableQuest, i)
        return
      end
    end
  end
end

function AT.HandleGossip(kind)
  if kind == "QUEST_GREETING" then
    AT.HandleGreeting()
    return
  end
  if AT.SelectGossipQuest() then return end
  AT.SkipLoneGossip()
end

function AT.TryRepair()
  if not AT.DB().options.autoRepair or AT.repairedThisVisit then return end
  if not CanMerchantRepair or not CanMerchantRepair() then return end
  local cost = GetRepairAllCost and GetRepairAllCost() or 0
  local money = GetMoney and GetMoney() or 0
  local paid, why = L.CanPayRepair(cost, money)
  if why == "none" then return end
  if not paid then
    AT.repairedThisVisit = true
    AT.Say("Repair costs " .. L.CoinText(cost) .. ", more than you are carrying.")
    return
  end
  if RepairAllItems and pcall(RepairAllItems) then
    AT.repairedThisVisit = true
    AT.Say("Repaired for " .. L.CoinText(cost) .. ".")
  end
end

local function itemTuple(link)
  if C_Item and C_Item.GetItemInfo then
    local ok, a, _, c, d, _, f, _, _, i, _, k = pcall(C_Item.GetItemInfo, link)
    if ok and type(a) == "table" then
      return a.itemName or a.name, a.itemQuality or a.quality, a.itemLevel or a.ilvl, a.itemEquipLoc or a.equipLoc, a.itemType or a.class, a.sellPrice or a.price
    end
    if ok and a then return a, c, d, i, f, k end
  end
  if GetItemInfo then
    local a, _, c, d, _, f, _, _, i, _, k = GetItemInfo(link)
    return a, c, d, i, f, k
  end
end

local function itemStats(link)
  if C_Item and C_Item.GetItemStats then
    local ok, stats = pcall(C_Item.GetItemStats, link)
    if ok and type(stats) == "table" then return stats end
  end
  if GetItemStats then
    local stats = GetItemStats(link)
    if type(stats) == "table" then return stats end
  end
  return {}
end

local function itemInfo(link)
  if not link then return nil end
  local name, _, ilvl, equipLoc = itemTuple(link)
  if not name then return nil end
  local raw = itemStats(link)
  local stats = L.NormalizeStats(raw, ilvl or 0)
  return {
    name = name,
    ilvl = ilvl or 0,
    equipLoc = equipLoc,
    score = L.Score(stats, AT.DB().class or "Warrior"),
  }
end

function AT.EquippedScore(equipLoc)
  local slots = L.EquipSlots(equipLoc)
  if not slots or not GetInventoryItemLink then return 0 end
  local lowest
  for i = 1, #slots do
    local link = GetInventoryItemLink("player", slots[i])
    local score = 0
    if link then
      local info = itemInfo(link)
      score = info and info.score or 0
    end
    if not lowest or score < lowest then lowest = score end
  end
  return lowest or 0
end

function AT.RewardAdvice()
  if not GetNumQuestChoices or not GetQuestItemLink then return nil end
  local count = GetNumQuestChoices() or 0
  if count <= 0 then return nil end
  local choices = {}
  for i = 1, count do
    local link = GetQuestItemLink("choice", i)
    local info = itemInfo(link)
    if info and info.equipLoc and info.equipLoc ~= "" then
      choices[#choices + 1] = {
        name = info.name,
        score = info.score,
        equipped = AT.EquippedScore(info.equipLoc),
        slot = info.equipLoc,
      }
    elseif info then
      choices[#choices + 1] = { name = info.name, score = info.score, equipped = info.score, slot = info.equipLoc }
    end
  end
  return L.PickReward(choices, AT.DB().class), choices
end

local function bagSlots()
  local bags = {}
  local function add(bag, slot, link)
    if link then bags[#bags + 1] = link end
  end
  if C_Container and C_Container.GetContainerNumSlots then
    for bag = 0, 4 do
      local slots = C_Container.GetContainerNumSlots(bag) or 0
      for slot = 1, slots do
        add(bag, slot, C_Container.GetContainerItemLink(bag, slot))
      end
    end
    return bags
  end
  if not GetContainerNumSlots or not GetContainerItemLink then return bags end
  local maxBag = NUM_BAG_SLOTS or 4
  for bag = 0, maxBag do
    local slots = GetContainerNumSlots(bag) or 0
    for slot = 1, slots do
      add(bag, slot, GetContainerItemLink(bag, slot))
    end
  end
  return bags
end

function AT.BagUpgrades()
  local rows = {}
  local links = bagSlots()
  for i = 1, #links do
    local info = itemInfo(links[i])
    if info and info.equipLoc and L.EquipSlots(info.equipLoc) then
      local equipped = AT.EquippedScore(info.equipLoc)
      if info.score > equipped + 0.05 then
        rows[#rows + 1] = { name = info.name, score = info.score, equipped = equipped, delta = info.score - equipped }
      end
    end
  end
  table.sort(rows, function(a, b) return a.delta > b.delta end)
  while #rows > 6 do table.remove(rows) end
  return rows
end

function AT.Nearest(filterKind)
  local origin = AT.PlayerPos()
  local classTag = AT.DB().class
  local ranked = L.Nearest(AT.Nodes(), origin.zone, origin.x or 0, origin.y or 0, function(node)
    if filterKind == "trainer" then return node.kind == "trainer" end
    if filterKind == "inn" then return node.kind == "inn" end
    if filterKind == "flight" then return node.kind == "fp" end
    if filterKind == "repair" then return node.repair or node.kind == "inn" end
    if filterKind == "boat" then return node.kind == "boat" end
    if filterKind == "zeppelin" then return node.kind == "zep" end
    return node.kind == "trainer" or node.kind == "inn" or node.kind == "fp" or node.kind == "boat" or node.kind == "zep"
  end)
  if filterKind == "trainer" and classTag then
    table.sort(ranked, function(a, b)
      local aClass = a.node.class == classTag
      local bClass = b.node.class == classTag
      if aClass ~= bClass then return aClass end
      if a.same ~= b.same then return a.same end
      return a.dist < b.dist
    end)
  end
  return ranked
end

function AT.FocusNode(node)
  if not node then return end
  AT.focus = { zone = node.zone, x = node.x, y = node.y, name = node.name, kind = node.kind }
  AT.planKey = nil
  local button = _G.AshenTrailTargetButton
  if button and button.SetAttribute and node.kind == "trainer" and node.name and not (InCombatLockdown and InCombatLockdown()) then
    button:SetAttribute("macrotext", macroText(node.name))
    AT.targetName = node.name
  end
  AT.Refresh()
end

function AT.EnableQuestPOI()
  if SetCVar then
    pcall(SetCVar, "questPOI", "1")
    pcall(SetCVar, "showQuestTrackingTooltips", "1")
  end
end

function AT.ApplyTheme(themeId)
  local db = AT.DB()
  local colors = L.ThemeColors(themeId or db.options.theme or "dark", db.class)
  local options = db.options
  options.theme = colors.id or themeId or "dark"
  local function copy(color)
    return { color[1], color[2], color[3] }
  end
  options.titleColor = copy(colors.title)
  options.textColor = copy(colors.text)
  options.mutedColor = copy(colors.muted)
  options.accentColor = copy(colors.accent)
  options.doneColor = copy(colors.done)
  options.openColor = copy(colors.open)
  options.arrowColor = copy(colors.arrow)
  options.edgeColor = copy(colors.edge)
  options.bgColor = copy(colors.bg)
end

function AT.EnsureTheme()
  local options = AT.DB().options
  if not options.theme or not options.textColor or not options.bgColor then
    AT.ApplyTheme(options.theme or "dark")
  end
end

function AT.DetectCharacter()
  local db = AT.DB()
  local previous = db.class
  if UnitClass then
    local _, classFile = UnitClass("player")
    db.class = L.ClassTagFromFile(classFile) or db.class
  end
  if db.options and db.options.theme == "class" and db.class ~= previous then
    AT.ApplyTheme("class")
  end
  local faction = UnitFactionGroup and UnitFactionGroup("player") or nil
  db.faction = faction
  if faction == "Alliance" and not db.forceHorde then
    return
  end
  if UnitRace then
    local _, token = UnitRace("player")
    if token and token ~= "" then db.raceToken = token end
    if not db.race then
      local raceId = L.RaceIdFromToken(token)
      if raceId then AT.ApplyRace(raceId, false) end
    end
  end
end

function AT.RaceToken()
  local db = AT.DB()
  if UnitRace then
    local _, token = UnitRace("player")
    if token and token ~= "" then
      db.raceToken = token
      return token
    end
  end
  return db.raceToken
end

function AT.Refresh()
  if AshenTrailUI and AshenTrailUI.Refresh then AshenTrailUI.Refresh() end
  AT.RefreshArrow()
end

function AT.Toggle()
  local db = AT.DB()
  if InCombatLockdown and InCombatLockdown() then
    AT.Say("Finish combat, then toggle the window.")
    return
  end
  db.hidden = not db.hidden
  AT.Refresh()
end

function AT.Show()
  if InCombatLockdown and InCombatLockdown() then return end
  AT.DB().hidden = false
  AT.Refresh()
end

function AshenTrail_Toggle()
  if AshenTrail and AshenTrail.Toggle then AshenTrail.Toggle() end
end

function AshenTrail_Next()
  if AshenTrail and AshenTrail.Next then AshenTrail.Next() end
end

function AT.ReadItem(link)
  if not link then return nil end
  local name, quality, itemType, price, id
  id = tonumber(string.match(link, "item:(%d+)"))
  name = string.match(link, "%[(.-)%]")
  local infoName, infoQuality, _, _, infoType, infoPrice = itemTuple(link)
  if infoName then
    name = infoName
    quality = infoQuality
    itemType = infoType
    price = infoPrice or 0
  end
  return name, quality, itemType, price or 0, id
end

function AT.ClassifyItem(link)
  local name, quality, itemType, price, id = AT.ReadItem(link)
  if not name and not id then return false, nil, 0, nil end
  local db = AT.DB()
  local junk = L.IsJunk(quality, itemType, id, name, db.junkList, db.junkKeep)
  return junk, name, price or 0, id
end

function AT.EachBagSlot(fn)
  for bag = 0, 4 do
    local num = 0
    if C_Container and C_Container.GetContainerNumSlots then
      num = C_Container.GetContainerNumSlots(bag) or 0
    elseif GetContainerNumSlots then
      num = GetContainerNumSlots(bag) or 0
    end
    for slot = 1, num do
      local link, locked, count
      if C_Container and C_Container.GetContainerItemInfo then
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if type(info) == "table" then
          link = info.hyperlink or info.itemLink
          locked = info.isLocked
          count = info.stackCount or info.stack
        end
      end
      if not link and GetContainerItemLink then link = GetContainerItemLink(bag, slot) end
      if GetContainerItemInfo then
        local _, itemCount, itemLocked = GetContainerItemInfo(bag, slot)
        if itemLocked ~= nil then locked = itemLocked end
        if itemCount then count = itemCount end
      end
      if link then fn(bag, slot, link, locked and true or false, count or 1) end
    end
  end
end

function AT.JunkSummary()
  local function names(list)
    local out = {}
    for _, label in pairs(list or {}) do
      if type(label) == "string" then out[#out + 1] = label end
    end
    table.sort(out)
    if #out == 0 then return "none" end
    if #out > 8 then
      local shown = {}
      for i = 1, 8 do shown[i] = out[i] end
      return table.concat(shown, ", ") .. " +" .. tostring(#out - 8)
    end
    return table.concat(out, ", ")
  end
  local db = AT.DB()
  return "Junk: " .. names(db.junkList) .. "\nKeep: " .. names(db.junkKeep)
end

function AT.SetJunk(text, keep)
  text = text or ""
  if text == "" then
    AT.Say(AT.JunkSummary())
    return
  end
  local id = tonumber(string.match(text, "item:(%d+)"))
  local name = string.match(text, "%[(.-)%]") or text
  name = string.gsub(name, "^%s+", "")
  name = string.gsub(name, "%s+$", "")
  local key = L.ItemKey(id, name)
  if not key then return end
  local db = AT.DB()
  local list = keep and db.junkKeep or db.junkList
  local other = keep and db.junkList or db.junkKeep
  list[key] = name
  other[key] = nil
  AT.Say((keep and "Whitelisted " or "Marked as junk: ") .. name)
  AT.Refresh()
end

function AT.ClearJunk(text)
  text = text or ""
  if text == "" then
    AT.Say("Name the item to remove from the junk list and the whitelist.")
    return
  end
  local id = tonumber(string.match(text, "item:(%d+)"))
  local name = string.match(text, "%[(.-)%]") or text
  local key = L.ItemKey(id, name)
  local db = AT.DB()
  if key then
    db.junkList[key] = nil
    db.junkKeep[key] = nil
  end
  local want = string.lower(name or "")
  local function sweep(list)
    for itemKey, label in pairs(list) do
      if type(label) == "string" and string.lower(label) == want then list[itemKey] = nil end
    end
  end
  sweep(db.junkList)
  sweep(db.junkKeep)
  AT.Say("Removed " .. (name or "that item") .. " from junk and the whitelist.")
  AT.Refresh()
end

function AT.SellJunk()
  local db = AT.DB()
  if not db.options.autoSellJunk then return end
  AT.sellPasses = (AT.sellPasses or 0) + 1
  if AT.sellPasses > 3 then return end
  local use = (C_Container and C_Container.UseContainerItem) or UseContainerItem
  if not use then return end
  local sold, copper = 0, 0
  AT.EachBagSlot(function(bag, slot, link, locked, count)
    if locked or sold >= 20 then return end
    local junk, _, price = AT.ClassifyItem(link)
    if junk and price and price > 0 then
      if pcall(use, bag, slot) then
        sold = sold + 1
        copper = copper + price * (count or 1)
      end
    end
  end)
  if sold > 0 then
    AT.Say("Sold " .. sold .. " junk items for " .. L.CoinText(copper) .. ".")
  end
end

function AT.FreeSlots()
  local free, known = 0, false
  for bag = 0, 4 do
    local n
    if C_Container and C_Container.GetContainerNumFreeSlots then
      n = C_Container.GetContainerNumFreeSlots(bag)
      known = true
    elseif GetContainerNumFreeSlots then
      n = GetContainerNumFreeSlots(bag)
      known = true
    end
    free = free + (n or 0)
  end
  if not known then return nil end
  return free
end

function AT.CheapestJunk()
  local best
  AT.EachBagSlot(function(bag, slot, link, locked)
    if locked then return end
    local junk, name, price, id = AT.ClassifyItem(link)
    if junk and price and price > 0 and (not best or price < best.price) then
      best = { bag = bag, slot = slot, name = name, price = price, id = id }
    end
  end)
  return best
end

function AT.DiscardJunkItem(entry)
  if not entry then return false end
  local pickup = (C_Container and C_Container.PickupContainerItem) or PickupContainerItem
  if not pickup or not DeleteCursorItem then return false end
  if ClearCursor then pcall(ClearCursor) end
  local picked = pcall(pickup, entry.bag, entry.slot)
  if not picked then return false end
  return pcall(DeleteCursorItem)
end

function AT.TryDiscardJunk()
  local db = AT.DB()
  if not db.options.discardJunk or not AT.lootOpen then return end
  local free = AT.FreeSlots()
  if free and free > 0 then
    AT.discardPrompt = nil
    return
  end
  local now = GetTime and GetTime() or 0
  if AT.discardTried and (now - AT.discardTried) < 0.8 then return end
  AT.discardTried = now
  local item = AT.CheapestJunk()
  if not item then
    if not AT.toldNoJunk then
      AT.toldNoJunk = true
      AT.Say("Bags are full, and there is no junk safe to drop.")
    end
    return
  end
  AT.toldNoJunk = nil
  if AT.DiscardJunkItem(item) then
    AT.discardPrompt = nil
    AT.Say("Dropped " .. (item.name or "junk") .. " to make room.")
  else
    AT.discardPrompt = item
    AT.Say("Bags are full. Click Drop on the tracker to delete " .. (item.name or "junk") .. ".")
  end
  AT.Refresh()
end

function AT.FlightNode(name)
  if not name or name == "" then return nil end
  local want = string.lower(name)
  local nodes = AT.Nodes()
  for i = 1, #nodes do
    local node = nodes[i]
    local label = node.name and string.lower(node.name) or ""
    if node.x and node.zone and string.len(label) >= 4 then
      if label == want or string.find(want, label, 1, true) or string.find(label, want, 1, true) then
        return node
      end
    end
  end
end

function AT.UpdateFlight()
  local db = AT.DB()
  if not db.options.flightTimer then
    AT.flight = nil
    return
  end
  local onTaxi = UnitOnTaxi and UnitOnTaxi("player")
  if not onTaxi then
    if AT.flight and AT.flight.started and AT.flight.key then
      local duration = (GetTime and GetTime() or 0) - AT.flight.started
      if duration > 8 and duration < 3600 then
        db.flightTimes[AT.flight.key] = duration
      end
    end
    AT.flight = nil
    return
  end
  local now = GetTime and GetTime() or 0
  if not AT.flight then
    local pos = AT.PlayerPos()
    local dest = AT.taxiDest
    AT.flight = {
      started = now,
      dest = dest,
      key = string.lower((pos.zone or "?") .. "|" .. (dest or "?")),
      lastX = pos.x,
      lastY = pos.y,
      lastT = now,
      zone = pos.zone,
    }
  end
  local flight = AT.flight
  local pos = AT.PlayerPos()
  if pos.x and flight.lastX and pos.zone == flight.zone then
    local dt = now - (flight.lastT or now)
    if dt >= 0.45 then
      local dist = L.Distance(flight.lastX, flight.lastY, pos.x, pos.y)
      if dist > 0.05 then flight.speed = dist / dt end
      flight.lastX, flight.lastY, flight.lastT = pos.x, pos.y, now
    end
  elseif pos.zone and pos.zone ~= flight.zone then
    flight.zone = pos.zone
    flight.lastX, flight.lastY, flight.lastT = pos.x, pos.y, now
  end
  local elapsed = now - flight.started
  local remain
  local node = AT.FlightNode(flight.dest)
  if node and pos.x and pos.zone == node.zone and flight.speed then
    remain = L.FlightRemain(L.Distance(pos.x, pos.y, node.x, node.y), flight.speed)
  end
  if not remain and db.flightTimes[flight.key] then
    remain = math.max(0, db.flightTimes[flight.key] - elapsed)
  end
  local text = "Flying"
  if flight.dest and flight.dest ~= "" then text = text .. " to " .. flight.dest end
  text = text .. "  " .. L.FormatClock(elapsed)
  if remain then text = text .. "  /  " .. L.FormatClock(elapsed + remain) end
  flight.text = text
end

function AT.ReadBreath()
  if not GetMirrorTimerInfo then return nil end
  for i = 1, 3 do
    local timer, value = GetMirrorTimerInfo(i)
    if timer == "BREATH" then return L.BreathSeconds(value) end
  end
end

function AT.UpdateBreath()
  local db = AT.DB()
  if not db.options.drownWarn then
    AT.breathWarn = nil
    return
  end
  local remain = AT.ReadBreath()
  local low = L.BreathLow(remain, db.options.drownSeconds or 10)
  if low and not AT.breathWarn then
    AT.Say("Breath is low (" .. L.FormatClock(remain or 0) .. ").")
    local sound = (SOUNDKIT and SOUNDKIT.RAID_WARNING) or "RaidWarning"
    if PlaySound then pcall(PlaySound, sound) end
  end
  if low then AT.breathWarn = remain else AT.breathWarn = nil end
  if AshenTrailUI and AshenTrailUI.SyncBreath then AshenTrailUI.SyncBreath() end
end

local function bagFullMessage(a, b)
  if ERR_INV_FULL and (a == ERR_INV_FULL or b == ERR_INV_FULL) then return true end
  if LE_GAME_ERR_INV_FULL and (a == LE_GAME_ERR_INV_FULL or b == LE_GAME_ERR_INV_FULL) then return true end
  local msg = type(a) == "string" and a or (type(b) == "string" and b or "")
  if msg == "" then return false end
  msg = string.lower(msg)
  if string.find(msg, "inventory is full", 1, true) then return true end
  if string.find(msg, "bags are full", 1, true) then return true end
  return false
end

local function slash(msg)
  local raw = msg or ""
  local cmd, rest = string.match(raw, "^(%S*)%s*(.*)$")
  cmd = string.lower(cmd or "")
  rest = rest or ""
  local arg = string.lower(rest)
  if cmd == "" or cmd == "toggle" or cmd == "show" then
    AT.Toggle()
  elseif cmd == "hide" then
    if not (InCombatLockdown and InCombatLockdown()) then
      AT.DB().hidden = true
      AT.Refresh()
    end
  elseif cmd == "next" then
    AT.Next()
  elseif cmd == "prev" then
    AT.Prev()
  elseif cmd == "skip" then
    AT.Skip()
  elseif cmd == "unskip" then
    AT.Unskip()
  elseif cmd == "sync" then
    AT.PrimeCompleted()
    AT.Sync(true)
    AT.Say("Caught up to the first unfinished step.")
  elseif cmd == "race" then
    if arg == "orc" or arg == "troll" or arg == "orc-troll" then AT.RequestRace("orc-troll")
    elseif arg == "tauren" then AT.RequestRace("tauren")
    elseif arg == "undead" or arg == "scourge" then AT.RequestRace("undead")
    elseif arg == "skyborne" or arg == "sky" then AT.RequestRace("skyborne")
    else AT.Say("Use /at race orc, tauren, undead, or skyborne.") end
  elseif cmd == "chapter" then
    local index = tonumber(rest)
    if index then AT.SetChapterIndex(index) else AT.Say("Use /at chapter 3") end
  elseif cmd == "target" then
    if AT.targetName then AT.Say("Target macro is set for " .. AT.targetName .. ". Click Target on the tracker.") end
  elseif cmd == "route" or cmd == "near" or cmd == "gear" or cmd == "options" or cmd == "log" or cmd == "pins" or cmd == "guide" then
    AT.DB().options.page = cmd == "log" and "log" or cmd
    AT.Show()
  elseif cmd == "reset" then
    local db = AT.DB()
    db.chapterIndex = 1
    db.step = 1
    db.turnedIn = {}
    db.history = { order = {}, byId = {} }
    db.finished = false
    AT.planKey = nil
    AT.Sync(true)
    AT.Say("Progress reset. Login sync ran again.")
  elseif cmd == "poi" then
    AT.EnableQuestPOI()
    AT.Say("Quest POI and tracking tooltips requested.")
  elseif cmd == "lock" then
    local db = AT.DB()
    db.options.locked = not db.options.locked
    AT.Refresh()
    AT.Say(db.options.locked and "Frame locked." or "Frame unlocked.")
  elseif cmd == "junk" then
    AT.SetJunk(rest, false)
  elseif cmd == "keep" then
    AT.SetJunk(rest, true)
  elseif cmd == "unjunk" or cmd == "unkeep" then
    AT.ClearJunk(rest)
  elseif cmd == "theme" then
    local theme = arg ~= "" and arg or "dark"
    AT.ApplyTheme(theme)
    AT.Say("Theme set to " .. (AT.DB().options.theme or theme) .. ".")
    AT.Refresh()
  elseif cmd == "chapters" then
    local mode = arg
    if mode ~= "auto" and mode ~= "manual" then
      mode = AT.DB().options.chapterMode == "manual" and "auto" or "manual"
    end
    AT.DB().options.chapterMode = mode
    AT.toldChapterEnd = nil
    AT.Say(mode == "manual" and "Chapters stay where you put them." or "Chapters advance on their own.")
    AT.Refresh()
  elseif cmd == "scale" then
    local value = tonumber(rest)
    if value then
      AT.DB().options.scale = math.max(0.7, math.min(1.4, value))
      AT.Refresh()
    end
  else
    AT.Say("Commands: toggle, next, prev, skip, unskip, sync, chapters auto|manual, theme blizzard|dark|vibrant|class|ashen, junk, keep, unjunk, race, chapter N, lock, scale, options.")
  end
end

function AT.Boot()
  if not AshenTrailData or not AshenTrailLogic then
    AT.Say("Addon files did not finish loading.")
    return
  end
  local db = AT.DB()
  if not db.chapterIndex then db.chapterIndex = 1 end
  if not db.step then db.step = 1 end
  AT.DetectCharacter()
  AT.EnsureTheme()
  if db.options.theme == "class" then AT.ApplyTheme("class") end
  if not AT.taxiHooked and hooksecurefunc and TakeTaxiNode then
    AT.taxiHooked = true
    hooksecurefunc("TakeTaxiNode", function(index)
      AT.taxiDest = TaxiNodeName and TaxiNodeName(index) or AT.taxiDest
    end)
  end
  if AshenTrailUI and AshenTrailUI.Build then AshenTrailUI.Build() end
  AT.EnableQuestPOI()
  if db.race then
    AT.PrimeCompleted()
    AT.Sync(true)
  else
    AT.Refresh()
  end
  AT.session = {
    started = time and time() or 0,
    gold = GetMoney and GetMoney() or 0,
    quests = 0,
  }
  local level = UnitLevel and UnitLevel("player") or 1
  local previous = db.levelOpen
  if previous and tostring(previous) ~= tostring(level) then
    local oldRow = db.levels[tostring(previous)]
    if oldRow then oldRow.started = nil end
  end
  local openRow = db.levels[tostring(level)]
  if openRow then openRow.started = nil end
  db.levelOpen = level
  AT.FlushLevel()
  AT.booted = true
  AT.UpdateTargetMacro()
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("QUEST_LOG_UPDATE")
events:RegisterEvent("QUEST_TURNED_IN")
events:RegisterEvent("QUEST_ACCEPTED")
events:RegisterEvent("QUEST_COMPLETE")
events:RegisterEvent("QUEST_DETAIL")
events:RegisterEvent("QUEST_PROGRESS")
events:RegisterEvent("QUEST_GREETING")
events:RegisterEvent("GOSSIP_SHOW")
events:RegisterEvent("GOSSIP_CLOSED")
events:RegisterEvent("MERCHANT_SHOW")
events:RegisterEvent("MERCHANT_CLOSED")
events:RegisterEvent("NAME_PLATE_UNIT_ADDED")
events:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_LEVEL_UP")
events:RegisterEvent("TAXIMAP_OPENED")
events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
events:RegisterEvent("ZONE_CHANGED")
events:RegisterEvent("BAG_UPDATE_DELAYED")
events:RegisterEvent("LOOT_OPENED")
events:RegisterEvent("LOOT_CLOSED")
events:RegisterEvent("UI_ERROR_MESSAGE")
events:RegisterEvent("MIRROR_TIMER_START")
events:RegisterEvent("MIRROR_TIMER_STOP")
events:RegisterEvent("PLAYER_CONTROL_LOST")
events:RegisterEvent("PLAYER_CONTROL_GAINED")
events:RegisterEvent("PLAYER_LOGOUT")
events:RegisterEvent("TRAINER_SHOW")
events:SetScript("OnEvent", function(_, event, arg1, arg2)
  if event == "PLAYER_LOGIN" or (event == "PLAYER_ENTERING_WORLD" and not AT.booted) then
    AT.Boot()
    return
  end
  if not AT.booted then return end
  if event == "PLAYER_ENTERING_WORLD" then
    AT.ScanQuests()
    AT.AdvanceDone(false)
    AT.planKey = nil
    AT.Refresh()
  elseif event == "QUEST_LOG_UPDATE" then
    local now = GetTime and GetTime() or 0
    if AT.questSyncAt and (now - AT.questSyncAt) < 0.5 then
      AT.questSyncPending = true
    else
      AT.questSyncAt = now
      AT.questSyncPending = false
      AT.Sync(false)
    end
  elseif event == "QUEST_TURNED_IN" then
    AT.MarkTurnedIn(arg1)
    if AT.session then AT.session.quests = (AT.session.quests or 0) + 1 end
    AT.Cue("turnin")
    AT.Sync(false)
  elseif event == "QUEST_ACCEPTED" then
    AT.RecordAccepted(arg1)
    AT.Sync(false)
  elseif event == "QUEST_COMPLETE" then
    AT.pendingReward = true
    AT.HandleQuestReward()
    if AshenTrailUI and AshenTrailUI.Refresh then AshenTrailUI.Refresh() end
  elseif event == "QUEST_DETAIL" then
    AT.HandleQuestDetail()
  elseif event == "QUEST_PROGRESS" then
    AT.HandleQuestProgress()
  elseif event == "QUEST_GREETING" or event == "GOSSIP_SHOW" then
    AT.HandleGossip(event)
  elseif event == "GOSSIP_CLOSED" then
    AT.gossipClicks = 0
  elseif event == "MERCHANT_SHOW" then
    AT.TryRepair()
    AT.sellPasses = 0
    AT.SellJunk()
  elseif event == "MERCHANT_CLOSED" then
    AT.repairedThisVisit = nil
    AT.sellPasses = 0
  elseif event == "NAME_PLATE_UNIT_ADDED" or event == "NAME_PLATE_UNIT_REMOVED" then
    AT.RefreshNameplates()
  elseif event == "PLAYER_REGEN_ENABLED" then
    if AT.pendingMacro then AT.UpdateTargetMacro() end
    if AT.pendingItem then AT.questItemDirty = true end
    if AT.UpdateQuestItemButton then AT.UpdateQuestItemButton() end
    if AshenTrailUI and AshenTrailUI.ApplyPendingLayout then AshenTrailUI.ApplyPendingLayout() end
    AT.RefreshNameplates()
  elseif event == "PLAYER_LEVEL_UP" then
    AT.CloseOpenLevel(arg1 or (UnitLevel and UnitLevel("player")) or 1)
    AT.Cue("level")
    if not (InCombatLockdown and InCombatLockdown()) then
      local line = AT.TalentLine()
      if line then AT.Say(line .. ". Vanilla opener. Forever may differ.") end
    end
  elseif event == "PLAYER_LOGOUT" then
    if AT.PauseLevel then AT.PauseLevel() end
  elseif event == "TRAINER_SHOW" then
    local level = UnitLevel and UnitLevel("player") or nil
    if level then AT.DB().trainNoted = level end
  elseif event == "TAXIMAP_OPENED" then
    AT.LearnFlights()
    AT.Refresh()
  elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" then
    AT.planKey = nil
    AT.planForce = true
    AT.Refresh()
  elseif event == "BAG_UPDATE_DELAYED" then
    AT.bagsDirty = true
    AT.questItemDirty = true
    if MerchantFrame and MerchantFrame.IsShown and MerchantFrame:IsShown() then AT.SellJunk() end
    if AshenTrailUI and AshenTrailUI.PaintJunk then AshenTrailUI.PaintJunk() end
    if AT.DB().options.page == "gear" and AshenTrailUI and AshenTrailUI.Refresh then
      AshenTrailUI.Refresh()
    end
  elseif event == "LOOT_OPENED" then
    AT.lootOpen = true
    AT.toldNoJunk = nil
    AT.TryDiscardJunk()
  elseif event == "LOOT_CLOSED" then
    AT.lootOpen = false
    AT.discardPrompt = nil
    AT.Refresh()
  elseif event == "UI_ERROR_MESSAGE" then
    if bagFullMessage(arg1, arg2) then AT.TryDiscardJunk() end
  elseif event == "MIRROR_TIMER_START" or event == "MIRROR_TIMER_STOP" then
    AT.UpdateBreath()
    AT.Refresh()
  elseif event == "PLAYER_CONTROL_LOST" or event == "PLAYER_CONTROL_GAINED" then
    AT.UpdateFlight()
    AT.Refresh()
  end
end)

function AT.Cue(kind)
  local options = AT.DB().options
  local allowed = false
  if kind == "step" then allowed = options.soundStep
  elseif kind == "turnin" then allowed = options.soundTurnIn
  elseif kind == "level" then allowed = options.soundLevel
  end
  if not allowed then return end
  local now = GetTime and GetTime() or 0
  if AT.cueAt and (now - AT.cueAt) < 0.4 then return end
  AT.cueAt = now
  local sound = (SOUNDKIT and SOUNDKIT.RAID_WARNING) or "RaidWarning"
  if PlaySound then pcall(PlaySound, sound) end
end

function AT.HearthRemain()
  if not GetItemCooldown or not GetTime then return nil, true end
  local start, duration = GetItemCooldown(6948)
  if not duration or duration == 0 or not start or start == 0 then return 0, true end
  local remain = duration - (GetTime() - start)
  if remain < 0 then remain = 0 end
  return remain, remain <= 0
end

function AT.RouteQuestIds()
  local ids = {}
  local chapters = AshenTrailData and AshenTrailData.chapters
  if not chapters then return ids end
  local db = AT.DB()
  local route = AT.RouteIds()
  for ci = 1, #route do
    local chapter = chapters[route[ci]]
    local steps = chapter and L.VisibleSteps(chapter, db.race, db.class, AT.RaceToken()) or {}
    for si = 1, #steps do
      local lines = steps[si].lines or {}
      for li = 1, #lines do
        local id = lines[li].id
        if id then ids[id] = true end
      end
    end
  end
  return ids
end

function AT.OffRouteQuests()
  if not GetNumQuestLogEntries or not GetQuestLogTitle then return 0, {} end
  local onRoute = AT.RouteQuestIds()
  local count, names = 0, {}
  local entries = GetNumQuestLogEntries() or 0
  for i = 1, entries do
    local title, _, _, isHeader, _, _, _, questID = GetQuestLogTitle(i)
    if not isHeader and questID and questID ~= 0 then
      count = count + 1
      if not onRoute[questID] then
        names[#names + 1] = title or ("Quest " .. tostring(questID))
      end
    end
  end
  return count, names
end

function AT.StepThreat(step)
  local lines = step and step.lines or {}
  for i = 1, #lines do
    local id = tonumber(lines[i].id)
    if id then
      local elite, group = false, 0
      if C_QuestLog and C_QuestLog.GetQuestTagInfo then
        local ok, info = pcall(C_QuestLog.GetQuestTagInfo, id)
        if ok and type(info) == "table" then
          elite = info.isElite and true or false
          if type(info.tagName) == "string" and string.find(string.lower(info.tagName), "group", 1, true) then
            group = math.max(group, 2)
          end
        end
      end
      if C_QuestLog and C_QuestLog.GetSuggestedGroupSize then
        local ok, size = pcall(C_QuestLog.GetSuggestedGroupSize, id)
        if ok and tonumber(size) and tonumber(size) > group then group = tonumber(size) end
      end
      if elite or group > 1 then return elite, group end
    end
  end
  return false, 0
end

function AT.RareLine()
  if AT.DB().options.rareHints == false then return nil end
  if not RareScanner and not _G.scanner_button then return nil end
  local button = _G.scanner_button
  if not button or not button.IsShown or not button:IsShown() then return nil end
  local title
  if button.title and button.title.GetText then title = button.title:GetText() end
  if title and title ~= "" then return "RareScanner: " .. title end
  return "RareScanner has a rare nearby."
end

function AT.GatherLine()
  if AT.DB().options.gatherHints == false then return nil end
  local GM = _G.GatherMate2
  if not GM or not GM.GetNodesForZone then return nil end
  local prof
  if GetNumSkillLines and GetSkillLineInfo then
    local lines = GetNumSkillLines() or 0
    for i = 1, lines do
      local name = GetSkillLineInfo(i)
      if name == "Mining" or name == "Herbalism" then
        prof = name
        break
      end
    end
  end
  if not prof then return nil end
  local mapID = AT.PlayerPos().mapID
  if not mapID then return nil end
  local zone = mapID
  if GM.GetZoneID then
    local ok, id = pcall(GM.GetZoneID, GM, mapID)
    if ok and id then zone = id end
  end
  local filter = prof == "Mining" and "Mining" or "Herb Gathering"
  local ok, nodes = pcall(GM.GetNodesForZone, GM, zone, filter)
  if not ok or type(nodes) ~= "table" then return nil end
  local count = 0
  for _ in pairs(nodes) do
    count = count + 1
    if count > 0 then break end
  end
  if count < 1 then return nil end
  return prof .. " nodes from GatherMate are saved for this map."
end

local function playerName()
  if UnitName then
    local name = UnitName("player")
    if name and name ~= "" then return name end
  end
  return nil
end

local function mirrorLevel(level, seconds)
  local name = playerName()
  if not name or not AshenTrailAccount then return end
  AshenTrailAccount.levelTimes = AshenTrailAccount.levelTimes or {}
  AshenTrailAccount.levelTimes[name] = AshenTrailAccount.levelTimes[name] or {}
  AshenTrailAccount.levelTimes[name][tostring(level)] = seconds
end

function AT.PauseLevel()
  local db = AT.DB()
  local level = db.levelOpen
  if not level then return end
  local row = db.levels[tostring(level)]
  if row and row.started then
    local total = L.CloseLevel(row, time and time() or 0)
    mirrorLevel(level, total)
  end
end

function AT.FlushLevel(now)
  local db = AT.DB()
  local level = db.levelOpen or (UnitLevel and UnitLevel("player"))
  if not level then return end
  now = now or (time and time() or 0)
  local key = tostring(level)
  local row = db.levels[key] or { seconds = 0 }
  if row.started then
    row.seconds = L.LevelSeconds(row, now)
    row.started = now
  else
    row.started = now
  end
  db.levels[key] = row
  db.levelOpen = level
  mirrorLevel(level, row.seconds or 0)
end

function AT.CloseOpenLevel(newLevel)
  local db = AT.DB()
  local old = db.levelOpen
  local now = time and time() or 0
  if old and tostring(old) ~= tostring(newLevel) then
    local key = tostring(old)
    local row = db.levels[key]
    if row then
      local total = L.CloseLevel(row, now)
      db.levels[key] = row
      if total > 0 then
        if not db.best[key] or total < db.best[key] then db.best[key] = total end
        mirrorLevel(old, total)
      end
    end
  end
  db.levelOpen = newLevel
  local key = tostring(newLevel)
  db.levels[key] = db.levels[key] or { seconds = 0 }
  db.levels[key].started = now
end

function AT.SessionLines()
  local session = AT.session
  if not session then return {} end
  local now = time and time() or session.started or 0
  local elapsed = math.max(0, now - (session.started or now))
  local rows = {}
  local xp = AT.xpText
  if xp and xp ~= "" then rows[#rows + 1] = xp end
  local questRate = L.PerHour(session.quests or 0, elapsed)
  if questRate then
    rows[#rows + 1] = string.format("%.1f quests/hr", questRate)
  elseif (session.quests or 0) > 0 then
    rows[#rows + 1] = tostring(session.quests) .. " quests this session"
  end
  if GetMoney and session.gold then
    rows[#rows + 1] = "Gold this session: " .. L.FormatMoney((GetMoney() or 0) - (session.gold or 0))
  end
  local level = UnitLevel and UnitLevel("player") or AT.DB().levelOpen
  if level then
    local row = AT.DB().levels[tostring(level)]
    local spent = L.LevelSeconds(row, now)
    if spent > 0 then
      local line = "This level: " .. L.FormatClock(spent)
      local best, who = L.BestOther(AshenTrailAccount and AshenTrailAccount.levelTimes, playerName(), level)
      if best then
        line = line .. ". Fastest alt (" .. who .. ") " .. L.FormatClock(best)
      end
      rows[#rows + 1] = line
    end
  end
  return rows
end

function AT.SampleXp()
  if InCombatLockdown and InCombatLockdown() then return end
  if not UnitXP or not UnitXPMax or not GetTime or not UnitLevel then
    AT.xpText = nil
    return
  end
  local okX, xp = pcall(UnitXP, "player")
  local okM, maxp = pcall(UnitXPMax, "player")
  local okL, level = pcall(UnitLevel, "player")
  if not okX or not okM or not okL or not xp or not maxp or maxp <= 0 then
    AT.xpText = nil
    return
  end
  local now = GetTime()
  local mark = AT.xpMark
  if not mark then
    AT.xpMark = { t = now, xp = xp, max = maxp, level = level, bank = 0 }
    AT.xpText = nil
    return
  end
  if level ~= mark.level then
    mark.bank = (mark.bank or 0) + math.max(0, (mark.max or 0) - (mark.xp or 0))
    mark.xp = 0
    mark.level = level
  end
  mark.max = maxp
  local gained = (mark.bank or 0) + (xp - (mark.xp or 0))
  local dt = now - (mark.t or now)
  if dt < 20 or gained < 1 then
    AT.xpText = nil
    return
  end
  local perHour = gained / dt * 3600
  local function compact(n)
    if n >= 1000 then return string.format("%.1fk", n / 1000) end
    return tostring(math.floor(n + 0.5))
  end
  local remain = math.max(0, maxp - xp)
  local text = compact(perHour) .. " XP/hr"
  if perHour > 1 then text = text .. "  " .. L.FormatClock(remain / perHour * 3600) end
  AT.xpText = text
end

local ticker = CreateFrame("Frame")
local nameElapsed, xpElapsed, miniElapsed, levelElapsed = 0, 0, 0, 0
ticker:SetScript("OnUpdate", function(_, elapsed)
  if not AT.booted then return end
  elapsed = elapsed or 0
  xpElapsed = xpElapsed + elapsed
  miniElapsed = miniElapsed + elapsed
  levelElapsed = levelElapsed + elapsed
  if xpElapsed >= 1 then
    xpElapsed = 0
    if AT.SampleXp then AT.SampleXp() end
    if AshenTrailUI and AshenTrailUI.SyncXpLabel then AshenTrailUI.SyncXpLabel() end
  end
  if miniElapsed >= 0.5 then
    miniElapsed = 0
    if AshenTrailUI and AshenTrailUI.UpdateMinimapPins then AshenTrailUI.UpdateMinimapPins() end
  end
  if levelElapsed >= 60 then
    levelElapsed = 0
    if AT.FlushLevel then AT.FlushLevel() end
  end
  local interval = tonumber(AT.DB().options.updateInterval) or 0.2
  if interval < 0.05 then interval = 0.05 end
  if interval > 2 then interval = 2 end
  nameElapsed = nameElapsed + elapsed
  if nameElapsed < interval then return end
  nameElapsed = 0
  if AT.questSyncPending then
    local now = GetTime and GetTime() or 0
    if not AT.questSyncAt or (now - AT.questSyncAt) >= 0.5 then
      AT.questSyncAt = now
      AT.questSyncPending = false
      AT.Sync(false)
    end
  end
  AT.RefreshNameplates()
  AT.UpdateFlight()
  AT.UpdateBreath()
  AT.RefreshArrow()
  if AshenTrailUI and AshenTrailUI.PaintJunk then AshenTrailUI.PaintJunk() end
end)

SLASH_ASHENTRAIL1 = "/at"
SLASH_ASHENTRAIL2 = "/ashentrail"
SlashCmdList = SlashCmdList or {}
SlashCmdList.ASHENTRAIL = slash
