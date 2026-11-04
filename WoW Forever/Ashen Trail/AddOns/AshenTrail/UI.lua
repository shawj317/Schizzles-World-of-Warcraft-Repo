-- Ashen Trail window, arrow, minimap button, and map pins.

AshenTrailUI = AshenTrailUI or {}
local UI = AshenTrailUI
local AT = AshenTrail
local L = AshenTrailLogic

local EMBER = { 0.77, 0.35, 0.17 }
local BONE = { 0.94, 0.89, 0.82 }
local MOSS = { 0.49, 0.61, 0.42 }
local MUTED = { 0.62, 0.56, 0.48 }
local INK = { 0.07, 0.06, 0.05 }

local FONT_SIZE = { small = 11, med = 13, large = 16 }
local ROLE = {
  Warrior = "Strength and stamina",
  Hunter = "Agility",
  Rogue = "Agility",
  Priest = "Intellect and spirit",
  Mage = "Intellect",
  Warlock = "Intellect and stamina",
  Shaman = "Intellect, strength, and agility",
  Druid = "Intellect or agility, depending on the piece",
  Paladin = "Strength and stamina",
}

local PAGES = {
  { id = "guide", label = "Guide" },
  { id = "pins", label = "Pins" },
  { id = "near", label = "Near" },
  { id = "route", label = "Route" },
  { id = "gear", label = "Gear" },
  { id = "log", label = "Log" },
  { id = "options", label = "Opts" },
}

local NEAR_FILTERS = {
  { id = "all", label = "All" },
  { id = "trainer", label = "Trainer" },
  { id = "inn", label = "Inn" },
  { id = "flight", label = "Flight" },
  { id = "repair", label = "Repair" },
  { id = "boat", label = "Boat" },
  { id = "zeppelin", label = "Zeppelin" },
}

local frame, arrow, pages, hint, progressBar, chapterLabel, activeTitle, activeBody, menu, optionsFrame, minimapButton, discardButton, breath, targetHolder, questItemHolder, xpLabel, dungeonFrame
local guideBody, tabButtons
local pendingLayout = false
local linePool, rowPool, stepPool, menuPool = {}, {}, {}, {}
local mapPins = {}
local nearFilter = "all"

local ADDON_FONT = "Interface\\AddOns\\AshenTrail\\Fonts\\FiraSansCondensed-Medium.ttf"
local fontChoice

local function fontPath()
  if fontChoice then return fontChoice end
  local game = (GameFontNormal and GameFontNormal:GetFont()) or "Fonts\\FRIZQT__.TTF"
  if UIParent and UIParent.CreateFontString then
    local probe = UIParent:CreateFontString(nil, "OVERLAY")
    local ok = probe:SetFont(ADDON_FONT, 12, "")
    local face = probe:GetFont()
    probe:Hide()
    if ok and face then
      fontChoice = ADDON_FONT
      return fontChoice
    end
  end
  fontChoice = game
  return fontChoice
end

local function fontSize()
  local db = AT.DB()
  local size = tonumber(db.options.fontSize)
  if size then
    if size < 10 then size = 10 end
    if size > 20 then size = 20 end
    return size
  end
  return FONT_SIZE[db.options.font] or 13
end

local function optColor(key, fallback)
  local color = AT.DB().options[key]
  if type(color) == "table" and color[1] then return color end
  return fallback
end

local function theme()
  return {
    title = optColor("titleColor", EMBER),
    text = optColor("textColor", BONE),
    muted = optColor("mutedColor", MUTED),
    accent = optColor("accentColor", EMBER),
    done = optColor("doneColor", MOSS),
    open = optColor("openColor", EMBER),
    arrow = optColor("arrowColor", EMBER),
    edge = optColor("edgeColor", EMBER),
    bg = optColor("bgColor", INK),
  }
end

local function paint(fs, r, g, b)
  fs:SetFont(fontPath(), fontSize(), "")
  fs:SetTextColor(r, g, b)
  if fs.SetShadowColor then
    fs:SetShadowColor(0, 0, 0, 1)
    fs:SetShadowOffset(1, -1)
  end
end

local function backdrop(widget, r, g, b, a)
  local colors = theme()
  if not widget.ashenEdge then
    local edge = widget:CreateTexture(nil, "BACKGROUND")
    edge:SetAllPoints()
    edge:SetTexture("Interface\\Buttons\\WHITE8x8")
    widget.ashenEdge = edge
    local bg = widget:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", widget, "TOPLEFT", 1, -1)
    bg:SetPoint("BOTTOMRIGHT", widget, "BOTTOMRIGHT", -1, 1)
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    widget.ashenPlate = bg
  end
  widget.ashenEdge:SetVertexColor(colors.edge[1], colors.edge[2], colors.edge[3], 1)
  local alpha = a
  if not alpha then alpha = tonumber(AT.DB().options.alpha) or 0.96 end
  widget.ashenPlate:SetVertexColor(r or colors.bg[1], g or colors.bg[2], b or colors.bg[3], alpha)
end

local function button(parent, text, width, height)
  local widget = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  widget:SetSize(width, height)
  widget:SetText(text)
  return widget
end

local function hidePool(pool, from)
  for i = from, #pool do
    if pool[i] then pool[i]:Hide() end
  end
end

local function ensureLine(parent, index)
  local fs = linePool[index]
  if fs then return fs end
  fs = parent:CreateFontString(nil, "OVERLAY")
  fs:SetJustifyH("LEFT")
  fs:SetJustifyV("TOP")
  fs:SetWordWrap(true)
  linePool[index] = fs
  return fs
end

local function ensureRow(parent, index)
  local row = rowPool[index]
  if row then return row end
  row = CreateFrame("Button", nil, parent)
  row:SetHeight(22)
  row.text = row:CreateFontString(nil, "OVERLAY")
  row.text:SetPoint("LEFT", 4, 0)
  row.text:SetPoint("RIGHT", -4, 0)
  row.text:SetJustifyH("LEFT")
  row:SetScript("OnEnter", function(self)
    self.text:SetTextColor(EMBER[1], EMBER[2], EMBER[3])
  end)
  row:SetScript("OnLeave", function(self)
    if self.base then self.text:SetTextColor(self.base[1], self.base[2], self.base[3]) end
  end)
  rowPool[index] = row
  return row
end

local function showPage(id)
  for key, page in pairs(pages) do
    if key == id then page:Show() else page:Hide() end
  end
end

local function applyHolder(holder, key, x, y)
  if not holder or holder.dragging then return end
  local saved = AT.DB()[key]
  holder:ClearAllPoints()
  if saved and saved[1] then
    holder:SetPoint(saved[1], UIParent, saved[2] or "CENTER", saved[3] or 0, saved[4] or 0)
  else
    holder:SetPoint("CENTER", UIParent, "CENTER", x, y)
  end
end

local function layoutFrame()
  if not frame then return end
  if InCombatLockdown and InCombatLockdown() then
    pendingLayout = true
    return
  end
  pendingLayout = false
  local db = AT.DB()
  local compact = db.options.compact and db.race
  local scale = db.options.scale or 1
  frame:SetSize(440, compact and 240 or 600)
  frame:SetScale(scale)
  frame:SetAlpha(1)
  frame:SetMovable(not db.options.locked)
  if db.hidden then frame:Hide() else frame:Show() end
  if activeTitle then
    activeTitle:ClearAllPoints()
    if compact then
      activeTitle:SetPoint("TOPLEFT", 14, -58)
    else
      activeTitle:SetPoint("BOTTOMLEFT", 14, 146)
    end
  end
  if activeBody then
    activeBody:ClearAllPoints()
    if compact then
      activeBody:SetPoint("TOPLEFT", 14, -78)
      activeBody:SetPoint("TOPRIGHT", -14, -78)
    else
      activeBody:SetPoint("BOTTOMLEFT", 14, 108)
      activeBody:SetPoint("BOTTOMRIGHT", -14, 108)
    end
    activeBody:SetHeight(compact and 44 or 36)
  end
  if hint then
    hint:ClearAllPoints()
    if compact then
      hint:SetPoint("TOPLEFT", 14, -126)
      hint:SetPoint("TOPRIGHT", -14, -126)
    else
      hint:SetPoint("BOTTOMLEFT", 14, 78)
      hint:SetPoint("BOTTOMRIGHT", -14, 78)
    end
    hint:SetHeight(compact and 36 or 28)
  end
  if guideBody then
    if compact then guideBody:Hide() else guideBody:Show() end
  end
  if tabButtons then
    for i = 1, #tabButtons do
      if compact then tabButtons[i]:Hide() else tabButtons[i]:Show() end
    end
  end
  if targetHolder then
    applyHolder(targetHolder, "targetPoint", 0, -220)
    if db.hidden then targetHolder:Hide() else targetHolder:Show() end
  end
  if questItemHolder then
    applyHolder(questItemHolder, "questItemPoint", 0, -190)
    if db.hidden then questItemHolder:Hide() end
  end
end

function UI.ApplyPendingLayout()
  if pendingLayout then layoutFrame() end
end

local function fillWrapped(parent, rows, onClick)
  local width = parent:GetWidth()
  if width < 40 then width = 400 end
  local y = -4
  for i = 1, #rows do
    local row = rows[i]
    local fs = ensureLine(parent, i)
    fs:SetParent(parent)
    paint(fs, row.color[1], row.color[2], row.color[3])
    fs:SetWidth(width - 16)
    fs:SetText(row.text)
    fs:ClearAllPoints()
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, y)
    fs:Show()
    local height = fs:GetStringHeight()
    if not height or height < 8 then height = fontSize() + 2 end
    y = y - height - 6
  end
  hidePool(linePool, #rows + 1)
  parent:SetHeight(math.max(24, -y + 8))
  if onClick then onClick(rows) end
end

local function hintText()
  local db = AT.DB()
  if not db.race then return "Pick the race you are leveling." end
  if db.finished then return "The route ends at 60. Raids open after the season date in the guide notes." end
  local step = AT.CurrentStep()
  local status = step and L.StepStatus(step, AT.Context()) or "manual"
  local plan = db.options.autoRoute and AT.PlanCurrent() or nil
  local parts = {}
  if status == "manual" then
    parts[#parts + 1] = "This step waits for you. Press Next when it is done, or Skip if it is stuck."
  elseif status == "open" then
    local name = AT.targetName or (step and L.TargetName(step))
    if name then
      parts[#parts + 1] = "Target marks " .. name .. ". A marker sits on their nameplate when they are in range."
    else
      parts[#parts + 1] = "Finish the highlighted objectives. The step advances when the quest log agrees."
    end
  end
  if plan and L.ShouldSuggest(plan) then
    parts[#parts + 1] = L.RouteSummary(plan)
  elseif plan and plan.origin and plan.dest and plan.origin.zone == plan.dest.zone then
    parts[#parts + 1] = "You can run to this pin. No hearth or flight is faster."
  elseif not plan and status ~= "manual" then
    parts[#parts + 1] = "No mapped road for this step. Follow the text."
  end
  local pin = step and L.ActivePin(step, AT.Context())
  if pin and pin.name and pin.name ~= pin.zone then
    parts[#parts + 1] = "Arrow: " .. pin.name .. "."
  elseif pin and pin.zone then
    parts[#parts + 1] = "Arrow: " .. pin.zone .. "."
  end
  if db.options.routeMode == "discover" then
    local chapter = AT.Chapter()
    local notes = chapter and chapter.notes
    if notes and notes[1] and notes[1] ~= "" then
      parts[#parts + 1] = notes[1]
    end
  end
  if db.options.hearthHints ~= false and AT.HearthRemain then
    local remain, ready = AT.HearthRemain()
    local hearth = L.HearthLabel(ready, remain)
    if hearth then parts[#parts + 1] = hearth end
  end
  if db.options.eliteWarn ~= false and step and AT.StepThreat then
    local elite, group = AT.StepThreat(step)
    local warning = L.GroupWarning(elite, group)
    if warning then
      if db.options.skipElites then warning = warning .. " Skip elites is on." end
      parts[#parts + 1] = warning
    end
  end
  if db.options.logHints ~= false and AT.OffRouteQuests then
    local count, names = AT.OffRouteQuests()
    local logHint = L.AbandonHint(count, 40, names)
    if logHint then parts[#parts + 1] = logHint end
  end
  if db.options.supplyHints ~= false then
    local _, steps = AT.CurrentStep()
    local nextStep = steps and steps[(db.step or 1) + 1]
    local supply = L.SupplyReminder(L.LeavingTown(step, nextStep), db.class)
    if supply then parts[#parts + 1] = supply end
  end
  local trainLevel = UnitLevel and UnitLevel("player") or 1
  if db.options.trainHints ~= false and L.TrainReminder(trainLevel, db.trainNoted) and AT.Nearest then
    local ranked = AT.Nearest("trainer")
    local nearest = ranked and ranked[1]
    if nearest and nearest.node then
      local where = nearest.node.name or "Trainer"
      if nearest.same and nearest.dist then
        local eta = nearest.dist * 6
        where = where .. ", about " .. L.FormatClock(eta)
      elseif nearest.node.zone then
        where = where .. " in " .. nearest.node.zone
      end
      parts[#parts + 1] = "New ranks may be available. Nearest trainer: " .. where .. "."
    end
  end
  if AT.RareLine then
    local rare = AT.RareLine()
    if rare then parts[#parts + 1] = rare end
  end
  if AT.GatherLine then
    local gather = AT.GatherLine()
    if gather then parts[#parts + 1] = gather end
  end
  return table.concat(parts, "\n")
end

local function stepBody(step)
  local parts = {}
  for i = 1, #(step.lines or {}) do
    local text = L.FormatLine(step.lines[i])
    if text and text ~= "" then parts[#parts + 1] = text end
  end
  if #parts == 0 then return "Follow the route." end
  return table.concat(parts, "\n")
end

local function ensureStep(parent, index)
  local row = stepPool[index]
  if row then return row end
  row = CreateFrame("Button", nil, parent)
  row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  row.bar = row:CreateTexture(nil, "BACKGROUND")
  row.bar:SetAllPoints()
  row.bar:SetTexture("Interface\\Buttons\\WHITE8x8")
  row.text = row:CreateFontString(nil, "OVERLAY")
  row.text:SetPoint("TOPLEFT", 8, -5)
  row.text:SetJustifyH("LEFT")
  row.text:SetJustifyV("TOP")
  row.text:SetWordWrap(true)
  row.num = row:CreateFontString(nil, "OVERLAY")
  row.num:SetPoint("TOPRIGHT", -6, -5)
  row.num:SetJustifyH("RIGHT")
  row:SetScript("OnEnter", function(self)
    if self.hot and self.bar then self.bar:SetVertexColor(self.hot[1], self.hot[2], self.hot[3], self.hot[4]) end
  end)
  row:SetScript("OnLeave", function(self)
    if self.idle and self.bar then self.bar:SetVertexColor(self.idle[1], self.idle[2], self.idle[3], self.idle[4]) end
  end)
  stepPool[index] = row
  return row
end

local guideScrollStep

local function renderGuide()
  local db = AT.DB()
  local chapter, chapterId = AT.Chapter()
  local _, steps = AT.CurrentStep()
  steps = steps or {}
  local index = db.step or 1
  local total = #steps
  local manual = db.options.chapterMode == "manual"
  local modeLabel = L.RouteModeLabel(db.options.routeMode)
  if chapter then
    chapterLabel:SetText((manual and "Manual  " or "") .. modeLabel .. "  " .. (chapter.name or "Ashen Trail"))
  else
    chapterLabel:SetText((manual and "Manual  " or "") .. modeLabel)
  end
  local pct = 0
  if total > 0 then pct = math.min(1, (index - 1) / total) end
  if db.finished then pct = 1 end
  if progressBar and progressBar.bg then
    progressBar.bar:SetWidth(math.max(1, (progressBar.bg:GetWidth() or 1) * pct))
  end
  local child = pages.guide.child
  local width = child:GetWidth()
  if width < 40 then width = 390 end
  local colors = theme()
  local y = -2
  local currentTop = 0
  for i = 1, total do
    local step = steps[i]
    local row = ensureStep(child, i)
    row:SetParent(child)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", child, "TOPLEFT", 2, y)
    row:SetWidth(width - 8)
    local skipped = AT.IsSkipped(chapterId, step)
    local current = (not db.finished) and i == index
    local textColor = colors.text
    if skipped then textColor = colors.muted
    elseif current then textColor = colors.open end
    paint(row.text, textColor[1], textColor[2], textColor[3])
    paint(row.num, current and colors.title[1] or colors.muted[1], current and colors.title[2] or colors.muted[2], current and colors.title[3] or colors.muted[3])
    row.text:SetWidth(width - 52)
    row.text:SetText(stepBody(step))
    row.num:SetText(tostring(i))
    local height = row.text:GetStringHeight()
    if not height or height < 8 then height = fontSize() + 2 end
    row:SetHeight(height + 10)
    local idleAlpha = 0
    if current then idleAlpha = 0.22
    elseif skipped then idleAlpha = 0.06 end
    row.idle = { colors.accent[1], colors.accent[2], colors.accent[3], idleAlpha }
    row.hot = { colors.accent[1], colors.accent[2], colors.accent[3], math.min(0.4, idleAlpha + 0.12) }
    row.bar:SetVertexColor(row.idle[1], row.idle[2], row.idle[3], row.idle[4])
    local captured = i
    row:SetScript("OnClick", function(_, button)
      if button == "RightButton" then
        UI.ShowMenu(captured)
      else
        AT.ToggleStep(captured)
      end
    end)
    row:Show()
    if current then currentTop = -y end
    y = y - (height + 12)
  end
  hidePool(stepPool, total + 1)
  child:SetHeight(math.max(24, -y + 8))
  if guideScrollStep ~= index and pages.guide.SetVerticalScroll then
    guideScrollStep = index
    local offset = currentTop - 12
    if offset < 0 then offset = 0 end
    pages.guide:SetVerticalScroll(offset)
  end
  local active = steps[index]
  if activeTitle then
    if db.finished then
      activeTitle:SetText("Route complete")
    else
      activeTitle:SetText(string.format("Step %d", math.min(index, math.max(total, 1))))
    end
    paint(activeTitle, colors.title[1], colors.title[2], colors.title[3])
  end
  if activeBody then
    local body = db.finished and "Bank heirlooms, lock Dual Spec, and claim the Legacy Point." or (active and stepBody(active) or "This chapter has no steps for your race and class.")
    paint(activeBody, colors.text[1], colors.text[2], colors.text[3])
    activeBody:SetText(body)
  end
  hint:SetText(hintText())
end

local function poiSentence(poi)
  local name = poi.name or "that spot"
  local where = string.format("(%.1f, %.1f) %s", poi.x or 0, poi.y or 0, poi.zone or "")
  if poi.k == "inn" then return "Set Hearth to " .. name .. " " .. where end
  if poi.k == "fp" then return "Get the " .. name .. " flight path " .. where end
  if poi.k == "giver" then return "Pick up " .. name .. " " .. where end
  if poi.k == "turnin" then return "Turn in " .. name .. " " .. where end
  if poi.k == "spawn" then return "Go to " .. name .. " " .. where end
  if poi.k == "mark" then return "Mark " .. name .. " " .. where end
  if poi.k == "goto" then return "Go to " .. (poi.zone or name) .. " " .. where end
  return name .. " " .. where
end

local function poiRows()
  local step = AT.CurrentStep()
  local rows = {}
  local pois = step and step.pois or {}
  if #pois == 0 then
    rows[#rows + 1] = { text = "This step has no map pin. Use Next, or open Near for a flight master.", color = MUTED }
    return rows
  end
  for i = 1, #pois do
    local poi = pois[i]
    rows[#rows + 1] = {
      text = poiSentence(poi),
      color = BONE,
      poi = poi,
    }
  end
  return rows
end

local function renderPins()
  local child = pages.pins.child
  local rows = poiRows()
  local y = -4
  local width = child:GetWidth()
  if width < 40 then width = 400 end
  for i = 1, #rows do
    local row = ensureRow(child, i)
    row:SetParent(child)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", child, "TOPLEFT", 4, y)
    row:SetPoint("RIGHT", child, "RIGHT", -8, 0)
    paint(row.text, rows[i].color[1], rows[i].color[2], rows[i].color[3])
    row.text:SetText(rows[i].text)
    row.base = rows[i].color
    row.poi = rows[i].poi
    row:SetScript("OnClick", function(self)
      if not self.poi then return end
      AT.FocusNode({ zone = self.poi.zone, x = self.poi.x, y = self.poi.y, name = self.poi.name, kind = self.poi.k })
      AT.Say("Arrow set to " .. (self.poi.name or self.poi.zone or "pin") .. ".")
    end)
    row:Show()
    y = y - 24
  end
  hidePool(rowPool, #rows + 1)
  child:SetHeight(math.max(24, -y))
  hint:SetText("Click a pin to aim the arrow there until the step changes. The guide aims the active step on its own.")
end

local function renderNear()
  local child = pages.near.child
  local ranked = AT.Nearest(nearFilter)
  local rows = {}
  if not AT.PlayerPos().zone then
    rows[1] = { text = "Zone not available yet.", color = MUTED }
  elseif #ranked == 0 then
    rows[1] = { text = "No matching NPC pins.", color = MUTED }
  else
    for i = 1, math.min(12, #ranked) do
      local entry = ranked[i]
      local node = entry.node
      local where = entry.same and string.format("%.0f map", entry.dist) or node.zone
      local note = node.note and (" - " .. node.note) or ""
      local classBit = node.class and (" (" .. node.class .. ")") or ""
      rows[#rows + 1] = {
        text = string.format("%s  %s%s%s  [%s]", node.kind, node.name, classBit, note, where),
        color = entry.same and BONE or MUTED,
        node = node,
      }
    end
  end
  local y = -28
  for i = 1, #rows do
    local row = ensureRow(child, i)
    row:SetParent(child)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", child, "TOPLEFT", 4, y)
    row:SetPoint("RIGHT", child, "RIGHT", -8, 0)
    paint(row.text, rows[i].color[1], rows[i].color[2], rows[i].color[3])
    row.text:SetText(rows[i].text)
    row.base = rows[i].color
    row.node = rows[i].node
    row:SetScript("OnClick", function(self)
      if not self.node then return end
      AT.FocusNode(self.node)
      AT.Say("Arrow set to " .. self.node.name .. ".")
    end)
    row:Show()
    y = y - 24
  end
  hidePool(rowPool, #rows + 1)
  child:SetHeight(math.max(40, -y))
  hint:SetText("Class trainers sort first. Click a row to point the arrow. Trainers also set the Target button.")
end

local function renderRoute()
  local child = pages.route.child
  local db = AT.DB()
  local rows = {}
  if not db.options.autoRoute then
    rows[1] = { text = "Auto route is off. Turn it on under Opts.", color = MUTED }
  else
    local plan = AT.PlanCurrent()
    if not plan then
      rows[1] = { text = "No mapped road from your position to this step.", color = MUTED }
    elseif not L.ShouldSuggest(plan) then
      rows[1] = { text = "Already in the zone. Run straight to the pin.", color = MOSS }
    else
      for i = 1, #plan.hops do
        local hop = plan.hops[i]
        if hop.to ~= "@dest" then
          local text = hop.label or hop.kind
          if hop.kind == "fly" and hop.name and db.flightTimes then
            local tail = "|" .. string.lower(hop.name)
            for key, value in pairs(db.flightTimes) do
              if type(key) == "string" and string.sub(string.lower(key), -#tail) == tail and tonumber(value) then
                text = text .. " (" .. L.FormatClock(value) .. " last time)"
                break
              end
            end
          end
          if hop.unconfirmed then text = text .. " (flight not confirmed)" end
          local color = BONE
          if hop.kind == "hearth" or hop.kind == "fly" or hop.kind == "boat" or hop.kind == "zep" then
            color = EMBER
          end
          rows[#rows + 1] = { text = tostring(i) .. ". " .. text, color = color }
        end
      end
      if #rows == 0 then
        rows[1] = { text = "Run to the step.", color = BONE }
      end
    end
    local eta = plan and L.RouteEta(plan, db.flightTimes)
    if eta and ((eta.seconds and eta.seconds >= 1) or eta.missingFlight) then
      local label = "Fastest route, about " .. L.FormatClock(eta.seconds)
      if eta.missingFlight then label = label .. ", plus an untimed flight" end
      table.insert(rows, 1, { text = label, color = EMBER })
    end
  end
  fillWrapped(child, rows)
  hint:SetText("Hearth, flight, boat, and zeppelin hops are suggestions. The addon cannot take them for you.")
end

local function renderGear()
  local child = pages.gear.child
  local db = AT.DB()
  local rows = {}
  local role = ROLE[db.class or ""] or "your class stats"
  rows[#rows + 1] = { text = "Upgrade finder. Rewards and bag items are scored against the weaker equipped slot.", color = MUTED }
  rows[#rows + 1] = { text = (db.class or "Class") .. " weights favor " .. role .. ".", color = BONE }
  local best, choices = nil, nil
  if AT.pendingReward or (QuestFrame and QuestFrame:IsShown()) then
    best, choices = AT.RewardAdvice()
  end
  if best and best.verdict == "equip" then
    rows[#rows + 1] = { text = "Equip " .. (best.name or "the reward") .. ". It scores higher than the piece in that slot.", color = MOSS }
  elseif best and best.verdict == "vendor" then
    rows[#rows + 1] = { text = "Vendor these rewards. None beat what you have equipped.", color = MUTED }
  elseif choices and #choices == 0 then
    rows[#rows + 1] = { text = "Reward links are still loading. Reopen the quest.", color = MUTED }
  else
    rows[#rows + 1] = { text = "No quest reward is open. Turn-in choices are scored when the reward window is up.", color = MUTED }
  end
  local upgrades = AT.BagUpgrades()
  if #upgrades == 0 then
    rows[#rows + 1] = { text = "Nothing in your bags beats the equipped score.", color = MUTED }
  else
    rows[#rows + 1] = { text = "Bag upgrades:", color = EMBER }
    for i = 1, #upgrades do
      rows[#rows + 1] = {
        text = string.format("%s  (+%.1f)", upgrades[i].name, upgrades[i].delta),
        color = BONE,
      }
    end
  end
  fillWrapped(child, rows)
  hint:SetText("Empty slots score as zero. Rings and trinkets compare against the weaker slot.")
end

local function renderLog()
  local child = pages.log.child
  local order = AT.DB().history.order or {}
  local byId = AT.DB().history.byId or {}
  local rows = {}
  local session = AT.SessionLines and AT.SessionLines() or {}
  for i = 1, #session do
    rows[#rows + 1] = { text = session[i], color = EMBER }
  end
  if #order == 0 then
    rows[#rows + 1] = { text = "Turn-ins you complete while Ashen Trail is running show up here.", color = MUTED }
  else
    local startAt = math.max(1, #order - 19)
    local n = 0
    for i = #order, startAt, -1 do
      n = n + 1
      local id = order[i]
      local row = byId[id]
      rows[#rows + 1] = { text = (row and row.name or ("Quest " .. tostring(id))), color = BONE }
    end
  end
  fillWrapped(child, rows)
  hint:SetText("History is saved per character. Level times are kept for alts. Reset clears the turn-in list.")
end

local function renderGate()
  local db = AT.DB()
  local gate = pages.gate
  if db.faction == "Alliance" and not db.forceHorde then
    gate:Show()
    gate.title:SetText("Ashen Trail is a Horde route.")
    gate.body:SetText("Alliance characters do not have chapters in this pack. You can still open the Horde steps.")
    gate.force:Show()
    for i = 1, #gate.races do gate.races[i]:Hide() end
    return true
  end
  if not db.race then
    gate:Show()
    gate.title:SetText("Which Horde start is this?")
    gate.body:SetText("The race on your character did not match a route. Pick one. You can change it later.")
    gate.force:Hide()
    for i = 1, #gate.races do gate.races[i]:Show() end
    return true
  end
  gate:Hide()
  return false
end

function UI.ApplyChrome()
  if not frame then return end
  local colors = theme()
  local size = fontSize()
  backdrop(frame)
  if frame.title then
    frame.title:SetFont(fontPath(), size + 5, "")
    frame.title:SetTextColor(colors.title[1], colors.title[2], colors.title[3])
  end
  if chapterLabel then
    chapterLabel:SetFont(fontPath(), size + 1, "")
    chapterLabel:SetTextColor(colors.text[1], colors.text[2], colors.text[3])
  end
  if activeTitle then
    activeTitle:SetFont(fontPath(), size, "")
    activeTitle:SetTextColor(colors.title[1], colors.title[2], colors.title[3])
  end
  if activeBody then
    activeBody:SetFont(fontPath(), math.max(11, size - 1), "")
    activeBody:SetTextColor(colors.text[1], colors.text[2], colors.text[3])
  end
  if hint then
    hint:SetFont(fontPath(), math.max(10, size - 2), "")
    hint:SetTextColor(colors.muted[1], colors.muted[2], colors.muted[3])
  end
  if progressBar and progressBar.bar and progressBar.bar.SetVertexColor then
    progressBar.bar:SetVertexColor(colors.accent[1], colors.accent[2], colors.accent[3], 1)
  end
  if optionsFrame then backdrop(optionsFrame) end
  if breath then backdrop(breath) end
end

function UI.SyncDiscard()
  if not discardButton then return end
  local item = AT.DB().options.discardJunk and AT.discardPrompt or nil
  if item then
    discardButton:Show()
    discardButton:SetText("Drop " .. (item.name or "junk"))
  else
    discardButton:Hide()
  end
end

function UI.SyncBreath()
  if not breath then return end
  if AT.breathWarn then
    breath:Show()
    breath.label:SetText("Breath low  " .. L.FormatClock(AT.breathWarn))
    local colors = theme()
    breath.label:SetTextColor(colors.title[1], colors.title[2], colors.title[3])
  else
    breath:Hide()
  end
end

function UI.PaintJunk()
  local show = AT.DB().options.showJunk
  local bagsOpen = ContainerFrame1 and ContainerFrame1.IsShown and ContainerFrame1:IsShown()
  if not show or not bagsOpen then
    if UI.junkPainted then
      local frames = NUM_CONTAINER_FRAMES or 13
      for bag = 1, frames do
        local bagFrame = _G["ContainerFrame" .. bag]
        if bagFrame then
          local slots = bagFrame.size or 36
          for slot = 1, slots do
            local buttonWidget = _G["ContainerFrame" .. bag .. "Item" .. slot]
            if buttonWidget and buttonWidget.ashenJunk then buttonWidget.ashenJunk:Hide() end
          end
        end
      end
      UI.junkPainted = false
    end
    return
  end
  UI.junkPainted = true
  local frames = NUM_CONTAINER_FRAMES or 13
  for bag = 1, frames do
    local bagFrame = _G["ContainerFrame" .. bag]
    if bagFrame then
      local bagID = bagFrame.GetID and bagFrame:GetID()
      local slots = bagFrame.size or 36
      for slot = 1, slots do
        local buttonWidget = _G["ContainerFrame" .. bag .. "Item" .. slot]
        if buttonWidget then
          if not buttonWidget.ashenJunk then
            local tex = buttonWidget:CreateTexture(nil, "OVERLAY")
            tex:SetTexture("Interface\\Buttons\\WHITE8x8")
            tex:SetPoint("TOPLEFT", 1, -1)
            tex:SetPoint("BOTTOMRIGHT", -1, 1)
            tex:SetVertexColor(0.72, 0.72, 0.76, 0.38)
            buttonWidget.ashenJunk = tex
          end
          local junk = false
          if show and bagFrame:IsShown() and bagID then
            local slotID = buttonWidget.GetID and buttonWidget:GetID() or slot
            local link
            if C_Container and C_Container.GetContainerItemLink then
              link = C_Container.GetContainerItemLink(bagID, slotID)
            elseif GetContainerItemLink then
              link = GetContainerItemLink(bagID, slotID)
            end
            if link then junk = AT.ClassifyItem(link) and true or false end
          end
          if junk then buttonWidget.ashenJunk:Show() else buttonWidget.ashenJunk:Hide() end
        end
      end
    end
  end
end

function UI.SyncXpLabel()
  if not xpLabel then return end
  local xp = AT.xpText or ""
  local talent = AT.TalentLine and AT.TalentLine() or nil
  if talent and talent ~= "" then
    if xp ~= "" then xp = xp .. "   " .. talent else xp = talent end
  end
  xpLabel:SetText(xp)
end

function UI.Refresh()
  if not frame then return end
  if AT.EnsureTheme then AT.EnsureTheme() end
  local db = AT.DB()
  layoutFrame()
  UI.ApplyChrome()
  UI.ApplyMinimap()
  UI.SyncDiscard()
  UI.SyncBreath()
  UI.SyncXpLabel()
  if AT.UpdateQuestItemButton then AT.UpdateQuestItemButton() end
  if UI.UpdateMinimapPins then UI.UpdateMinimapPins() end
  local blocked = renderGate()
  local page = db.options.page or "guide"
  if page == "options" then
    page = "guide"
    db.options.page = "guide"
  end
  if blocked then
    showPage("gate")
  else
    showPage(page)
    if page == "guide" then renderGuide()
    elseif page == "pins" then renderPins()
    elseif page == "near" then renderNear()
    elseif page == "route" then renderRoute()
    elseif page == "gear" then renderGear()
    elseif page == "log" then renderLog()
    else renderGuide() end
  end
  if pages.near and pages.near.filterLabel then
    pages.near.filterLabel:SetText("Showing: " .. nearFilter)
  end
  UI.UpdateMapPins()
end

function UI.UpdateArrow(goal, origin)
  if not arrow then return end
  local db = AT.DB()
  local colors = theme()
  local flying = db.options.flightTimer and AT.flight and AT.flight.text
  local showPointer = not db.hidden and db.options.showArrow and goal
  if not showPointer and not flying then
    arrow:Hide()
    return
  end
  local tomtomOn = db.options.arrowMode == "tomtom" and AT.TomTomReady and AT.TomTomReady()
  local sameZone = goal and goal.x and origin and origin.x and (goal.here or goal.kind == "pin")
  if showPointer and tomtomOn and sameZone and not flying then
    arrow:Hide()
    return
  end
  arrow:Show()
  arrow:SetScale(tonumber(db.options.arrowScale) or 1)
  if arrow.tex.SetVertexColor then arrow.tex:SetVertexColor(colors.arrow[1], colors.arrow[2], colors.arrow[3]) end
  arrow.label:SetTextColor(colors.text[1], colors.text[2], colors.text[3])
  if not showPointer or (tomtomOn and sameZone) then
    arrow.tex:Hide()
    arrow.label:SetText("")
  else
    local same = goal.x and origin and origin.x and (goal.here or goal.kind == "pin")
    if same then
      arrow.tex:Show()
      local dx = (goal.x or 0) - (origin.x or 0)
      local dy = (goal.y or 0) - (origin.y or 0)
      local facing = GetPlayerFacing and GetPlayerFacing() or 0
      local angle = math.atan2(dx, -dy) - facing
      if arrow.tex.SetRotation then arrow.tex:SetRotation(angle) end
      local yards = AT.WorldDistance(origin.mapID, origin.x, origin.y, goal.x, goal.y)
      if yards then
        arrow.label:SetText(string.format("%d yd  %s", yards, goal.label or ""))
      else
        arrow.label:SetText(string.format("%.1f map  %s", L.Distance(origin.x, origin.y, goal.x, goal.y), goal.label or ""))
      end
    else
      arrow.tex:Hide()
      local where = goal.zone and ("Next: " .. (goal.label or goal.zone)) or "No pin"
      if goal.zone and origin and origin.zone and goal.zone ~= origin.zone then
        where = where .. "  (" .. goal.zone .. ")"
      end
      arrow.label:SetText(where)
    end
  end
  if flying and arrow.flight then
    arrow.flight:SetText(AT.flight.text)
    arrow.flight:SetTextColor(colors.accent[1], colors.accent[2], colors.accent[3])
    arrow.flight:Show()
  elseif arrow.flight then
    arrow.flight:Hide()
  end
end

local function mapZoneName()
  if WorldMapFrame and WorldMapFrame.GetMapID and C_Map and C_Map.GetMapInfo then
    local id = WorldMapFrame:GetMapID()
    local info = id and C_Map.GetMapInfo(id)
    if info and info.name then return info.name, id end
  end
  if GetCurrentMapAreaID and GetMapNameByID then
    local id = GetCurrentMapAreaID()
    if id then return GetMapNameByID(id), id end
  end
  return nil, nil
end

local function canvas()
  if WorldMapFrame and WorldMapFrame.ScrollContainer and WorldMapFrame.ScrollContainer.Child then
    return WorldMapFrame.ScrollContainer.Child
  end
  if WorldMapDetailFrame then return WorldMapDetailFrame end
  return nil
end

local function takePin(index)
  local pin = mapPins[index]
  if pin then return pin end
  pin = CreateFrame("Frame", nil, UIParent)
  pin:SetSize(16, 16)
  pin.icon = pin:CreateTexture(nil, "OVERLAY")
  pin.icon:SetAllPoints()
  pin.icon:SetTexture("Interface\\Minimap\\Tracking\\QuestBlob")
  mapPins[index] = pin
  return pin
end

function UI.UpdateMapPins()
  local parent = canvas()
  local shown = WorldMapFrame and WorldMapFrame.IsShown and WorldMapFrame:IsShown()
  if not shown or not parent then
    for i = 1, #mapPins do mapPins[i]:Hide() end
    return
  end
  local zoneName, mapID = mapZoneName()
  local pins = {}
  local guide = AT.GuidePins and AT.GuidePins() or {}
  for i = 1, #guide do
    if not zoneName or guide[i].zone == zoneName then
      pins[#pins + 1] = guide[i]
    end
  end
  local step = AT.CurrentStep()
  if C_QuestLog and C_QuestLog.GetNextWaypoint and step then
    for _, line in ipairs(step.lines or {}) do
      if line.id then
        local ok, wpMap, x, y = pcall(C_QuestLog.GetNextWaypoint, line.id)
        if ok and wpMap and x and y and (not mapID or wpMap == mapID) then
          pins[#pins + 1] = { k = "spawn", name = line.objective or line.name or "Objective", x = x * 100, y = y * 100, zone = zoneName }
        end
      end
    end
  end
  local width, height = parent:GetWidth(), parent:GetHeight()
  if not width or width < 20 then
    for i = 1, #mapPins do mapPins[i]:Hide() end
    return
  end
  for i = 1, #pins do
    local pin = takePin(i)
    local poi = pins[i]
    local px = ((poi.x or 50) / 100 - 0.5) * width
    local py = (0.5 - (poi.y or 50) / 100) * height
    local placed = pcall(function()
      pin:SetParent(parent)
      pin:ClearAllPoints()
      pin:SetPoint("CENTER", parent, "CENTER", px, py)
    end)
    if placed then pin:Show() else pin:Hide() end
  end
  for i = #pins + 1, #mapPins do mapPins[i]:Hide() end
end

local miniPins = {}

local function takeMini(index)
  local pin = miniPins[index]
  if pin then return pin end
  if not Minimap then return nil end
  pin = CreateFrame("Frame", nil, Minimap)
  pin:SetSize(12, 12)
  pin:SetFrameStrata("MEDIUM")
  pin.icon = pin:CreateTexture(nil, "OVERLAY")
  pin.icon:SetAllPoints()
  pin.icon:SetTexture("Interface\\Buttons\\WHITE8X8")
  pin:SetScript("OnEnter", function(self)
    if not GameTooltip then return end
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText(self.tip or "Step")
    GameTooltip:Show()
  end)
  pin:SetScript("OnLeave", function()
    if GameTooltip then GameTooltip:Hide() end
  end)
  miniPins[index] = pin
  return pin
end

function UI.UpdateMinimapPins()
  if not Minimap or not AT.GuidePins then
    for i = 1, #miniPins do miniPins[i]:Hide() end
    return
  end
  local pins = AT.GuidePins()
  local origin = AT.PlayerPos()
  local shown = 0
  local zoom = Minimap.GetZoom and Minimap:GetZoom() or 0
  local indoors = IsIndoors and IsIndoors()
  local radius = L.MinimapRadius(zoom, indoors)
  local edge = (Minimap:GetWidth() or 140) / 2 - 12
  if edge < 20 then edge = 50 end
  for i = 1, #pins do
    local poi = pins[i]
    if origin.zone and poi.zone == origin.zone and origin.x and poi.x then
      shown = shown + 1
      local pin = takeMini(shown)
      if pin then
        local px, py
        local dx, dy
        if origin.mapID and AT.WorldDelta then
          dx, dy = AT.WorldDelta(origin.mapID, origin.x, origin.y, poi.x, poi.y)
        end
        if dx then
          px, py = L.MinimapOffset(dx, dy, radius, edge)
        else
          local mdx = poi.x - origin.x
          local mdy = origin.y - poi.y
          local dist = math.sqrt(mdx * mdx + mdy * mdy)
          local scale = 1
          if dist < 12 then scale = dist / 12 end
          if dist < 0.05 then scale = 0 end
          local angle = math.atan2(mdy, mdx)
          px = math.cos(angle) * edge * scale
          py = math.sin(angle) * edge * scale
        end
        pin:ClearAllPoints()
        pin:SetPoint("CENTER", Minimap, "CENTER", px, py)
        if poi.k == "turnin" then
          pin.icon:SetVertexColor(0.45, 0.75, 0.45)
        else
          pin.icon:SetVertexColor(0.95, 0.78, 0.25)
        end
        pin.tip = (poi.k == "turnin" and "Turn in " or "Talk to ") .. (poi.name or "NPC")
        pin:Show()
      end
    end
  end
  for i = shown + 1, #miniPins do miniPins[i]:Hide() end
end

local function makeScroll(parent)
  local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 8, -8)
  scroll:SetPoint("BOTTOMRIGHT", -28, 8)
  local child = CreateFrame("Frame", nil, scroll)
  child:SetSize(400, 40)
  scroll:SetScrollChild(child)
  scroll.child = child
  return scroll
end

local function buildOptions(parent)
  parent.labels = {}
  parent.sections = {}
  parent.toggles = {}
  parent.sliders = {}
  parent.themeButtons = {}

  local function remember(fs)
    parent.labels[#parent.labels + 1] = fs
    return fs
  end

  local function addSection(text, y)
    local fs = remember(parent:CreateFontString(nil, "OVERLAY"))
    fs:SetPoint("TOPLEFT", 4, y)
    fs:SetFont(fontPath(), 12, "")
    fs:SetText(text)
    fs.section = true
    parent.sections[#parent.sections + 1] = fs
    return y - 18
  end

  local function addToggle(spec, x, y)
    local box = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    box:SetPoint("TOPLEFT", x, y)
    box:SetSize(22, 22)
    local label = remember(parent:CreateFontString(nil, "OVERLAY"))
    label:SetPoint("LEFT", box, "RIGHT", 2, 0)
    label:SetFont(fontPath(), 11, "")
    label:SetWidth(168)
    label:SetJustifyH("LEFT")
    label:SetText(spec.label)
    box.optionKey = spec.key
    box:SetScript("OnClick", function(self)
      AT.DB().options[spec.key] = self:GetChecked() and true or false
      UI.Refresh()
    end)
    parent.toggles[#parent.toggles + 1] = box
  end

  local function addPairs(list, y)
    for i = 1, #list, 2 do
      addToggle(list[i], 2, y)
      if list[i + 1] then addToggle(list[i + 1], 196, y) end
      y = y - 24
    end
    return y - 4
  end

  local function addSlider(globalName, text, y, minV, maxV, step, apply, low, high)
    local slider = CreateFrame("Slider", globalName, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 16, y)
    slider:SetWidth(340)
    slider:SetMinMaxValues(minV, maxV)
    slider:SetValueStep(step)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
    slider:SetScript("OnValueChanged", function(_, value)
      if parent.syncing then return end
      apply(value)
    end)
    _G[globalName .. "Low"]:SetText(low)
    _G[globalName .. "High"]:SetText(high)
    _G[globalName .. "Text"]:SetText(text)
    parent.sliders[#parent.sliders + 1] = slider
    return y - 32
  end

  local function pick(key, fallback)
    local current = optColor(key, fallback)
    local function apply(r, g, b)
      AT.DB().options[key] = { r, g, b }
      UI.Refresh()
    end
    if not ColorPickerFrame then return end
    if ColorPickerFrame.SetupColorPickerAndShow then
      ColorPickerFrame:SetupColorPickerAndShow({
        r = current[1], g = current[2], b = current[3],
        hasOpacity = false,
        swatchFunc = function()
          local r, g, b = ColorPickerFrame:GetColorRGB()
          apply(r, g, b)
        end,
        cancelFunc = function(prev)
          if prev then apply(prev.r or prev[1], prev.g or prev[2], prev.b or prev[3]) end
        end,
      })
      return
    end
    ColorPickerFrame.previousValues = { current[1], current[2], current[3] }
    ColorPickerFrame.hasOpacity = false
    ColorPickerFrame.func = function()
      local r, g, b = ColorPickerFrame:GetColorRGB()
      apply(r, g, b)
    end
    ColorPickerFrame.cancelFunc = function(prev)
      if type(prev) == "table" then apply(prev[1], prev[2], prev[3]) end
    end
    ColorPickerFrame:SetColorRGB(current[1], current[2], current[3])
    ColorPickerFrame:Hide()
    ColorPickerFrame:Show()
  end

  local y = -6
  y = addSection("Theme", y)
  local themes = {
    { "blizzard", "Blizzard" },
    { "dark", "Dark" },
    { "vibrant", "Vibrant" },
    { "class", "Class" },
    { "ashen", "Ashen" },
  }
  for i = 1, #themes do
    local spec = themes[i]
    local themeButton = button(parent, spec[2], 74, 20)
    themeButton:SetPoint("TOPLEFT", 4 + (i - 1) * 78, y)
    themeButton:SetScript("OnClick", function()
      AT.ApplyTheme(spec[1])
      AT.Say(spec[2] .. " theme.")
      UI.Refresh()
    end)
    themeButton.themeId = spec[1]
    parent.themeButtons[i] = themeButton
  end
  y = y - 28

  y = addSection("Appearance", y)
  y = addPairs({
    { key = "showMinimap", label = "Minimap button" },
    { key = "locked", label = "Lock frame" },
    { key = "compact", label = "Compact step only" },
  }, y)
  y = addSlider("AshenTrailFontSlider", "Font size", y, 10, 18, 1, function(value)
    AT.DB().options.fontSize = value
    UI.Refresh()
  end, "10", "18")
  local textColor = button(parent, "Text color", 110, 20)
  textColor:SetPoint("TOPLEFT", 8, y)
  textColor:SetScript("OnClick", function() pick("textColor", BONE) end)
  local titleColor = button(parent, "Title color", 110, 20)
  titleColor:SetPoint("LEFT", textColor, "RIGHT", 8, 0)
  titleColor:SetScript("OnClick", function() pick("titleColor", EMBER) end)
  y = y - 28

  y = addSection("Guide", y)
  y = addPairs({
    { key = "autoAdvance", label = "Auto-complete steps" },
    { key = "skipOverleveled", label = "Skip overleveled steps" },
    { key = "skipElites", label = "Skip elite and group steps" },
    { key = "eliteWarn", label = "Warn on elite and group steps" },
    { key = "logHints", label = "Suggest off-route quests" },
    { key = "supplyHints", label = "Town supply reminder" },
    { key = "trainHints", label = "Trainer reminder" },
    { key = "hearthHints", label = "Hearthstone cooldown" },
  }, y)
  local chapterButton = button(parent, "Chapters: Auto", 160, 20)
  chapterButton:SetPoint("TOPLEFT", 8, y)
  chapterButton:SetScript("OnClick", function()
    local db = AT.DB()
    db.options.chapterMode = db.options.chapterMode == "manual" and "auto" or "manual"
    AT.toldChapterEnd = nil
    UI.Refresh()
  end)
  parent.chapterButton = chapterButton
  local routeButton = button(parent, "Route: Speedrun", 160, 20)
  routeButton:SetPoint("LEFT", chapterButton, "RIGHT", 8, 0)
  routeButton:SetScript("OnClick", function()
    local options = AT.DB().options
    if options.routeMode == "discover" then options.routeMode = "speed" else options.routeMode = "discover" end
    UI.Refresh()
  end)
  parent.routeButton = routeButton
  y = y - 26
  y = addSlider("AshenTrailGapSlider", "Levels past the chapter", y, 0, 8, 1, function(value)
    AT.DB().options.overlevelGap = value
  end, "0", "8")

  y = addSection("Quests", y)
  y = addPairs({
    { key = "autoAccept", label = "Auto accept quests" },
    { key = "autoTurnIn", label = "Auto turn in quests" },
    { key = "autoReward", label = "Auto take quest reward" },
    { key = "guideQuestsOnly", label = "Route quests only" },
    { key = "skipGossip", label = "Skip single gossip" },
    { key = "skullMark", label = "Skull marker on Target" },
  }, y)

  y = addSection("Bags", y)
  y = addPairs({
    { key = "showJunk", label = "Show junk on bags" },
    { key = "autoSellJunk", label = "Sell junk at vendors" },
    { key = "discardJunk", label = "Drop junk if bags fill" },
    { key = "autoRepair", label = "Auto repair at vendors" },
  }, y)
  local junkBox = CreateFrame("EditBox", "AshenTrailJunkInput", parent, "InputBoxTemplate")
  junkBox:SetAutoFocus(false)
  junkBox:SetSize(180, 20)
  junkBox:SetPoint("TOPLEFT", 14, y)
  junkBox:SetFont(fontPath(), 12, "")
  junkBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  parent.junkBox = junkBox
  local addJunk = button(parent, "Junk", 64, 20)
  addJunk:SetPoint("LEFT", junkBox, "RIGHT", 8, 0)
  addJunk:SetScript("OnClick", function()
    AT.SetJunk(junkBox:GetText(), false)
    junkBox:SetText("")
    junkBox:ClearFocus()
  end)
  local keepJunk = button(parent, "Keep", 64, 20)
  keepJunk:SetPoint("LEFT", addJunk, "RIGHT", 4, 0)
  keepJunk:SetScript("OnClick", function()
    AT.SetJunk(junkBox:GetText(), true)
    junkBox:SetText("")
    junkBox:ClearFocus()
  end)
  y = y - 26
  local clearJunk = button(parent, "Remove", 80, 20)
  clearJunk:SetPoint("TOPLEFT", 8, y)
  clearJunk:SetScript("OnClick", function()
    AT.ClearJunk(junkBox:GetText())
    junkBox:SetText("")
    junkBox:ClearFocus()
  end)
  y = y - 22
  local junkList = remember(parent:CreateFontString(nil, "OVERLAY"))
  junkList:SetPoint("TOPLEFT", 8, y)
  junkList:SetWidth(380)
  junkList:SetJustifyH("LEFT")
  junkList:SetFont(fontPath(), 11, "")
  junkList:SetText("Junk: none\nKeep: none")
  parent.junkList = junkList
  y = y - 36

  y = addSection("Arrow and travel", y)
  y = addPairs({
    { key = "showArrow", label = "Show direction arrow" },
    { key = "autoRoute", label = "Suggest hearth and flight" },
    { key = "flightTimer", label = "Flight timer" },
    { key = "drownWarn", label = "Drowning warning" },
  }, y)
  local arrowButton = button(parent, "Arrow: Built-in", 150, 20)
  arrowButton:SetPoint("TOPLEFT", 8, y)
  arrowButton:SetScript("OnClick", function()
    local db = AT.DB()
    if db.options.arrowMode == "tomtom" then
      db.options.arrowMode = "builtin"
    else
      db.options.arrowMode = "tomtom"
      if not (AT.TomTomReady and AT.TomTomReady()) then
        AT.Say("TomTom is not installed. The built-in arrow stays on.")
      end
    end
    UI.Refresh()
  end)
  parent.arrowButton = arrowButton
  local arrowColor = button(parent, "Arrow color", 110, 20)
  arrowColor:SetPoint("LEFT", arrowButton, "RIGHT", 8, 0)
  arrowColor:SetScript("OnClick", function() pick("arrowColor", EMBER) end)
  y = y - 26
  y = addSlider("AshenTrailArrowSlider", "Arrow size", y, 0.6, 1.8, 0.05, function(value)
    AT.DB().options.arrowScale = value
    UI.Refresh()
  end, "0.6", "1.8")
  y = addSlider("AshenTrailIntervalSlider", "Update interval", y, 0.05, 1.5, 0.05, function(value)
    AT.DB().options.updateInterval = value
  end, "0.05s", "1.5s")
  y = addSlider("AshenTrailBreathSlider", "Breath warning", y, 3, 30, 1, function(value)
    AT.DB().options.drownSeconds = value
  end, "3s", "30s")

  y = addSection("Markers", y)
  y = addPairs({
    { key = "showNameplates", label = "Nameplate icons" },
    { key = "showObjectiveCount", label = "Objective counter" },
    { key = "trackTownsfolk", label = "Townsfolk markers" },
    { key = "rareHints", label = "RareScanner nearby" },
    { key = "gatherHints", label = "GatherMate nodes" },
  }, y)

  y = addSection("Cues", y)
  y = addPairs({
    { key = "soundStep", label = "Sound when a step finishes" },
    { key = "soundTurnIn", label = "Sound when a quest turns in" },
    { key = "soundLevel", label = "Sound on level up" },
  }, y)

  y = addSection("Share", y)
  local shareBox = CreateFrame("EditBox", "AshenTrailShareInput", parent, "InputBoxTemplate")
  shareBox:SetAutoFocus(false)
  shareBox:SetSize(250, 20)
  shareBox:SetPoint("TOPLEFT", 14, y)
  shareBox:SetFont(fontPath(), 11, "")
  shareBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  parent.shareBox = shareBox
  local exportRoute = button(parent, "Export", 70, 20)
  exportRoute:SetPoint("LEFT", shareBox, "RIGHT", 8, 0)
  exportRoute:SetScript("OnClick", function()
    shareBox:SetText(AT.ExportText())
    shareBox:HighlightText()
  end)
  local importRoute = button(parent, "Import", 70, 20)
  importRoute:SetPoint("TOPLEFT", exportRoute, "BOTTOMLEFT", 0, -4)
  importRoute:SetScript("OnClick", function()
    AT.ImportText(shareBox:GetText())
    shareBox:ClearFocus()
  end)
  y = y - 48

  y = addSection("Window", y)
  y = addSlider("AshenTrailScaleSlider", "Window scale", y, 0.7, 1.4, 0.05, function(value)
    if InCombatLockdown and InCombatLockdown() then return end
    AT.DB().options.scale = value
    if frame then frame:SetScale(value) end
  end, "0.7", "1.4")
  y = addSlider("AshenTrailAlphaSlider", "Opacity", y, 0.55, 1, 0.05, function(value)
    AT.DB().options.alpha = value
    if frame then backdrop(frame) end
    if optionsFrame then backdrop(optionsFrame) end
  end, "55%", "100%")
  local accountButton = button(parent, "Account options: On", 180, 20)
  accountButton:SetPoint("TOPLEFT", 8, y)
  accountButton:SetScript("OnClick", function()
    local db = AT.DB()
    AT.SetUseAccount(db.useAccount == false)
    UI.Refresh()
  end)
  parent.accountButton = accountButton
  y = y - 28

  local function sync()
    parent.syncing = true
    local options = AT.DB().options
    for i = 1, #parent.toggles do
      local box = parent.toggles[i]
      box:SetChecked(options[box.optionKey] and true or false)
    end
    local colors = theme()
    for i = 1, #parent.labels do
      local label = parent.labels[i]
      if label.section then
        label:SetTextColor(colors.accent[1], colors.accent[2], colors.accent[3])
      else
        label:SetTextColor(colors.text[1], colors.text[2], colors.text[3])
      end
    end
    for i = 1, #parent.themeButtons do
      local themeButton = parent.themeButtons[i]
      local active = options.theme == themeButton.themeId
      local caption = themes[i][2]
      themeButton:SetText(active and ("[" .. caption .. "]") or caption)
    end
    chapterButton:SetText(options.chapterMode == "manual" and "Chapters: Manual" or "Chapters: Auto")
    if parent.routeButton then
      parent.routeButton:SetText("Route: " .. L.RouteModeLabel(options.routeMode))
    end
    if parent.accountButton then
      local shared = AT.DB().useAccount ~= false
      parent.accountButton:SetText(shared and "Account options: On" or "Account options: Off")
    end
    arrowButton:SetText(options.arrowMode == "tomtom" and "Arrow: TomTom" or "Arrow: Built-in")
    if parent.junkList then parent.junkList:SetText(AT.JunkSummary()) end
    local values = {
      AshenTrailFontSlider = options.fontSize or 13,
      AshenTrailGapSlider = options.overlevelGap or 0,
      AshenTrailArrowSlider = options.arrowScale or 1,
      AshenTrailIntervalSlider = options.updateInterval or 0.2,
      AshenTrailBreathSlider = options.drownSeconds or 10,
      AshenTrailScaleSlider = options.scale or 1,
      AshenTrailAlphaSlider = options.alpha or 0.94,
    }
    for i = 1, #parent.sliders do
      local slider = parent.sliders[i]
      local value = values[slider:GetName()]
      if value then slider:SetValue(value) end
    end
    parent.syncing = false
  end
  parent.sync = sync
  parent:SetHeight(math.max(40, math.abs(y) + 28))
end


local function buildGate(parent)
  parent.title = parent:CreateFontString(nil, "OVERLAY")
  parent.title:SetFont(fontPath(), 16, "")
  parent.title:SetPoint("TOP", 0, -28)
  parent.title:SetTextColor(BONE[1], BONE[2], BONE[3])
  parent.body = parent:CreateFontString(nil, "OVERLAY")
  parent.body:SetFont(fontPath(), 13, "")
  parent.body:SetPoint("TOPLEFT", 24, -64)
  parent.body:SetPoint("TOPRIGHT", -24, -64)
  parent.body:SetJustifyH("LEFT")
  parent.body:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
  parent.body:SetWordWrap(true)
  parent.force = button(parent, "Show the Horde route anyway", 220, 24)
  parent.force:SetPoint("TOP", parent.body, "BOTTOM", 0, -16)
  parent.force:SetScript("OnClick", function()
    AT.DB().forceHorde = true
    AT.DetectCharacter()
    UI.Refresh()
  end)
  parent.races = {}
  local labels = {
    { "orc-troll", "Orc and Troll" },
    { "tauren", "Tauren" },
    { "undead", "Undead" },
    { "skyborne", "Skyborne" },
  }
  for i = 1, #labels do
    local raceButton = button(parent, labels[i][2], 180, 24)
    raceButton:SetPoint("TOP", parent.body, "BOTTOM", 0, -12 - (i * 28))
    raceButton:SetScript("OnClick", function()
      AT.RequestRace(labels[i][1])
    end)
    parent.races[i] = raceButton
  end
end

local function buildMinimap()
  if not Minimap then return end
  local buttonWidget = CreateFrame("Button", "AshenTrailMinimapButton", Minimap)
  buttonWidget:SetSize(31, 31)
  buttonWidget:SetFrameStrata("MEDIUM")
  buttonWidget:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  local icon = buttonWidget:CreateTexture(nil, "BACKGROUND")
  icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")
  icon:SetSize(20, 20)
  icon:SetPoint("CENTER")
  local border = buttonWidget:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetSize(54, 54)
  border:SetPoint("TOPLEFT", -1, 1)
  local function place()
    local angle = math.rad(AT.DB().minimapAngle or 220)
    buttonWidget:ClearAllPoints()
    buttonWidget:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * 80, math.sin(angle) * 80)
  end
  place()
  buttonWidget:RegisterForDrag("LeftButton")
  buttonWidget:SetScript("OnDragStart", function(self) self.dragging = true end)
  buttonWidget:SetScript("OnDragStop", function(self) self.dragging = false end)
  buttonWidget:SetScript("OnUpdate", function(self)
    if not self.dragging or not Minimap:GetCenter() then return end
    local mx, my = Minimap:GetCenter()
    local cx, cy = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    cx, cy = cx / scale, cy / scale
    local angle = math.deg(math.atan2(cy - my, cx - mx))
    AT.DB().minimapAngle = angle
    place()
  end)
  buttonWidget:SetScript("OnClick", function()
    AT.Toggle()
  end)
  buttonWidget:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Ashen Trail")
    GameTooltip:AddLine("Left click toggles the tracker.", 1, 1, 1)
    GameTooltip:Show()
  end)
  buttonWidget:SetScript("OnLeave", function() GameTooltip:Hide() end)
  minimapButton = buttonWidget
  UI.ApplyMinimap()
end

function UI.ApplyMinimap()
  if not minimapButton then return end
  if AT.DB().options.showMinimap == false then
    minimapButton:Hide()
  else
    minimapButton:Show()
  end
end

function UI.ShowRoutePicker()
  local db = AT.DB()
  db.racePicker = true
  if not pages or not pages.gate then return end
  pages.gate:Show()
  pages.gate.title:SetText("Switch route")
  pages.gate.body:SetText(db.pendingRace and "Click the same race again to reset progress." or "Pick a start. Switching clears tracked turn-ins.")
  pages.gate.force:Hide()
  for i = 1, #pages.gate.races do pages.gate.races[i]:Show() end
end

function UI.OpenOptions()
  if not optionsFrame then return end
  if optionsFrame:IsShown() then
    optionsFrame:Hide()
    return
  end
  optionsFrame:Show()
  if optionsFrame.sync then optionsFrame.sync() end
end

function UI.OpenDungeons()
  if not dungeonFrame then
    dungeonFrame = CreateFrame("Frame", "AshenTrailDungeons", UIParent)
    dungeonFrame:SetSize(440, 480)
    dungeonFrame:SetPoint("CENTER", 240, 20)
    dungeonFrame:SetFrameStrata("DIALOG")
    dungeonFrame:SetMovable(true)
    dungeonFrame:EnableMouse(true)
    dungeonFrame:RegisterForDrag("LeftButton")
    dungeonFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    dungeonFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    backdrop(dungeonFrame)
    local title = dungeonFrame:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOPLEFT", 14, -12)
    title:SetFont(fontPath(), 14, "")
    title:SetText("Forever dungeons")
    local close = button(dungeonFrame, "Close", 70, 22)
    close:SetPoint("TOPRIGHT", -10, -8)
    close:SetScript("OnClick", function() dungeonFrame:Hide() end)
    dungeonFrame.scroll = makeScroll(dungeonFrame)
    dungeonFrame.scroll:ClearAllPoints()
    dungeonFrame.scroll:SetPoint("TOPLEFT", 8, -40)
    dungeonFrame.scroll:SetPoint("BOTTOMRIGHT", -8, 8)
  end
  local child = dungeonFrame.scroll.child
  local rows = {}
  local list = AshenTrailData and AshenTrailData.dungeons or {}
  if #list == 0 then
    rows[1] = { text = "No dungeon list is loaded.", color = MUTED }
  else
    for i = 1, #list do
      local dungeon = list[i]
      rows[#rows + 1] = { text = (dungeon.name or "Dungeon") .. "   " .. (dungeon.levels or ""), color = EMBER }
      if dungeon.where and dungeon.where ~= "" then
        rows[#rows + 1] = { text = "Entrance: " .. dungeon.where, color = BONE }
      end
      local quests = dungeon.quests or {}
      if #quests == 0 then
        rows[#rows + 1] = { text = "No published world quest.", color = MUTED }
      else
        rows[#rows + 1] = { text = "Quests: " .. table.concat(quests, ", "), color = BONE }
      end
      if dungeon.prep and dungeon.prep ~= "" then
        rows[#rows + 1] = { text = dungeon.prep, color = MUTED }
      end
      rows[#rows + 1] = { text = " ", color = MUTED }
    end
  end
  fillWrapped(child, rows)
  dungeonFrame:Show()
end

function UI.ShowMenu(stepIndex)
  if not menu then return end
  local items = {}
  if stepIndex then
    items[#items + 1] = { "Go to step " .. tostring(stepIndex), function() AT.GoToStep(stepIndex) end }
  end
  items[#items + 1] = { "Chapters", function()
    if frame.chapters:IsShown() then frame.chapters:Hide() else frame.chapters:Show() UI.FillChapters() end
  end }
  items[#items + 1] = { "Reload guide", function()
    AT.PrimeCompleted()
    AT.Sync(true)
    AT.Say("Reloaded the guide from your quest log.")
  end }
  items[#items + 1] = { "Switch route", function() UI.ShowRoutePicker() end }
  items[#items + 1] = { "Dungeons", function() UI.OpenDungeons() end }
  items[#items + 1] = { "Options", function() UI.OpenOptions() end }
  items[#items + 1] = { "Close", function()
    if not AT.DB().hidden then AT.Toggle() end
  end }
  local y = -6
  for i = 1, #items do
    local row = menuPool[i]
    if not row then
      row = button(menu, "", 168, 20)
      menuPool[i] = row
    end
    row:SetParent(menu)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", 6, y)
    row:SetText(items[i][1])
    row:SetScript("OnClick", function()
      menu:Hide()
      if menu.catcher then menu.catcher:Hide() end
      items[i][2]()
    end)
    row:Show()
    y = y - 22
  end
  for i = #items + 1, #menuPool do menuPool[i]:Hide() end
  menu:SetHeight(math.max(28, -y + 8))
  menu:SetWidth(180)
  local x, yPos = GetCursorPosition()
  local scale = UIParent:GetEffectiveScale()
  if not scale or scale == 0 then scale = 1 end
  menu:ClearAllPoints()
  menu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", (x / scale) , (yPos / scale))
  if menu.catcher then menu.catcher:Show() end
  menu:Show()
end

function UI.Build()
  if frame then
    UI.Refresh()
    return
  end
  frame = CreateFrame("Frame", "AshenTrailFrame", UIParent)
  frame:SetSize(460, 560)
  frame:SetFrameStrata("MEDIUM")
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function(self)
    if AT.DB().options.locked then return end
    if InCombatLockdown and InCombatLockdown() then return end
    self:StartMoving()
  end)
  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, rel, x, y = self:GetPoint()
    AT.DB().point = { point, rel, x, y }
  end)
  frame:SetScript("OnMouseUp", function(_, button)
    if button == "RightButton" then UI.ShowMenu(nil) end
  end)
  backdrop(frame)
  local point = AT.DB().point
  frame:SetPoint(point[1] or "CENTER", UIParent, point[2] or "CENTER", point[3] or 0, point[4] or 0)

  local title = frame:CreateFontString(nil, "OVERLAY")
  title:SetFont(fontPath(), 12, "")
  title:SetPoint("TOPLEFT", 14, -8)
  title:SetTextColor(EMBER[1], EMBER[2], EMBER[3])
  title:SetText("Ashen Trail")
  frame.title = title

  local close = button(frame, "Hide", 52, 18)
  close:SetPoint("TOPRIGHT", -8, -6)
  close:SetScript("OnClick", function() AT.Toggle() end)

  xpLabel = frame:CreateFontString(nil, "OVERLAY")
  xpLabel:SetPoint("RIGHT", close, "LEFT", -8, 0)
  xpLabel:SetJustifyH("RIGHT")
  xpLabel:SetFont(fontPath(), 11, "")
  xpLabel:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
  xpLabel:SetText("")

  chapterLabel = frame:CreateFontString(nil, "OVERLAY")
  chapterLabel:SetPoint("TOPLEFT", 14, -26)
  chapterLabel:SetPoint("TOPRIGHT", -70, -26)
  chapterLabel:SetJustifyH("LEFT")
  chapterLabel:SetFont(fontPath(), 15, "")
  chapterLabel:SetTextColor(BONE[1], BONE[2], BONE[3])
  if chapterLabel.SetShadowColor then
    chapterLabel:SetShadowColor(0, 0, 0, 1)
    chapterLabel:SetShadowOffset(1, -1)
  end

  progressBar = CreateFrame("Frame", nil, frame)
  progressBar:SetPoint("TOPLEFT", 14, -48)
  progressBar:SetPoint("TOPRIGHT", -12, -48)
  progressBar:SetHeight(4)
  progressBar.bg = progressBar:CreateTexture(nil, "BACKGROUND")
  progressBar.bg:SetAllPoints()
  progressBar.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
  progressBar.bg:SetVertexColor(0.2, 0.16, 0.12, 1)
  progressBar.bar = progressBar:CreateTexture(nil, "ARTWORK")
  progressBar.bar:SetPoint("LEFT")
  progressBar.bar:SetHeight(4)
  progressBar.bar:SetWidth(1)
  progressBar.bar:SetTexture("Interface\\Buttons\\WHITE8x8")
  progressBar.bar:SetVertexColor(EMBER[1], EMBER[2], EMBER[3], 1)

  guideBody = CreateFrame("Frame", nil, frame)
  local body = guideBody
  body:SetPoint("TOPLEFT", 8, -56)
  body:SetPoint("BOTTOMRIGHT", -8, 168)
  backdrop(body, 0.04, 0.04, 0.05, 1)

  pages = {}
  pages.guide = makeScroll(body)
  pages.pins = makeScroll(body)
  pages.near = makeScroll(body)
  pages.route = makeScroll(body)
  pages.gear = makeScroll(body)
  pages.log = makeScroll(body)
  pages.gate = CreateFrame("Frame", nil, body)
  pages.gate:SetAllPoints()
  buildGate(pages.gate)

  pages.near.filterLabel = pages.near:CreateFontString(nil, "OVERLAY")
  pages.near.filterLabel:SetPoint("TOPLEFT", pages.near, "TOPLEFT", 8, 16)
  pages.near.filterLabel:SetFont(fontPath(), 11, "")
  pages.near.filterLabel:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
  local fx = 8
  for i = 1, #NEAR_FILTERS do
    local spec = NEAR_FILTERS[i]
    local filterButton = button(body, spec.label, 58, 16)
    filterButton:SetPoint("BOTTOMLEFT", body, "BOTTOMLEFT", fx, 6)
    filterButton:SetScript("OnClick", function()
      nearFilter = spec.id
      AT.DB().options.page = "near"
      UI.Refresh()
    end)
    filterButton:Hide()
    pages.near["filter" .. i] = filterButton
    fx = fx + 60
  end
  pages.near:ClearAllPoints()
  pages.near:SetPoint("TOPLEFT", body, "TOPLEFT", 8, -8)
  pages.near:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", -28, 28)
  pages.near:SetScript("OnShow", function()
    for i = 1, #NEAR_FILTERS do pages.near["filter" .. i]:Show() end
  end)
  pages.near:SetScript("OnHide", function()
    for i = 1, #NEAR_FILTERS do pages.near["filter" .. i]:Hide() end
  end)

  activeTitle = frame:CreateFontString(nil, "OVERLAY")
  activeTitle:SetPoint("BOTTOMLEFT", 14, 146)
  activeTitle:SetFont(fontPath(), 13, "")
  activeTitle:SetTextColor(EMBER[1], EMBER[2], EMBER[3])
  activeTitle:SetText("Step")

  activeBody = frame:CreateFontString(nil, "OVERLAY")
  activeBody:SetPoint("BOTTOMLEFT", 14, 108)
  activeBody:SetPoint("BOTTOMRIGHT", -14, 108)
  activeBody:SetHeight(36)
  activeBody:SetJustifyH("LEFT")
  activeBody:SetJustifyV("TOP")
  activeBody:SetWordWrap(true)
  activeBody:SetFont(fontPath(), 12, "")
  activeBody:SetTextColor(BONE[1], BONE[2], BONE[3])

  hint = frame:CreateFontString(nil, "OVERLAY")
  hint:SetPoint("BOTTOMLEFT", 14, 78)
  hint:SetPoint("BOTTOMRIGHT", -14, 78)
  hint:SetHeight(28)
  hint:SetJustifyH("LEFT")
  hint:SetJustifyV("TOP")
  hint:SetWordWrap(true)
  hint:SetFont(fontPath(), 11, "")
  hint:SetTextColor(MUTED[1], MUTED[2], MUTED[3])

  local prev = button(frame, "Prev", 90, 24)
  prev:SetPoint("BOTTOMLEFT", 14, 46)
  prev:SetScript("OnClick", function() AT.Prev() end)

  local function dragHolder(holder, key, secure)
    holder:SetMovable(true)
    holder:SetClampedToScreen(true)
    secure:RegisterForDrag("LeftButton")
    secure:SetScript("OnDragStart", function()
      if InCombatLockdown and InCombatLockdown() then return end
      holder.dragging = true
      holder:StartMoving()
    end)
    secure:SetScript("OnDragStop", function()
      holder:StopMovingOrSizing()
      holder.dragging = nil
      local point, _, rel, x, y = holder:GetPoint(1)
      AT.DB()[key] = { point or "CENTER", rel or "CENTER", x or 0, y or 0 }
    end)
  end

  targetHolder = CreateFrame("Frame", "AshenTrailTargetHolder", UIParent)
  targetHolder:SetSize(140, 24)
  targetHolder:SetFrameStrata("MEDIUM")
  local target = CreateFrame("Button", "AshenTrailTargetButton", targetHolder, "SecureActionButtonTemplate,UIPanelButtonTemplate")
  target:SetAllPoints(targetHolder)
  target:SetText("Target")
  target:SetAttribute("type", "macro")
  target:SetAttribute("macrotext", "")
  target:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(AT.targetName and ("Target " .. AT.targetName) or "No NPC on this step")
    GameTooltip:Show()
  end)
  target:SetScript("OnLeave", function() GameTooltip:Hide() end)
  dragHolder(targetHolder, "targetPoint", target)

  questItemHolder = CreateFrame("Frame", "AshenTrailQuestItemHolder", UIParent)
  questItemHolder:SetSize(140, 24)
  questItemHolder:SetFrameStrata("MEDIUM")
  questItemHolder:Hide()
  local questItem = CreateFrame("Button", "AshenTrailQuestItemButton", questItemHolder, "SecureActionButtonTemplate,UIPanelButtonTemplate")
  questItem:SetAllPoints(questItemHolder)
  questItem:SetText("Use")
  questItem:SetAttribute("type", "item")
  questItem.holder = questItemHolder
  questItem:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(AT.questItem and ("Use " .. AT.questItem.name) or "No quest item on this step")
    GameTooltip:Show()
  end)
  questItem:SetScript("OnLeave", function() GameTooltip:Hide() end)
  dragHolder(questItemHolder, "questItemPoint", questItem)

  local nextButton = button(frame, "Next", 90, 24)
  nextButton:SetPoint("BOTTOMRIGHT", -14, 46)
  nextButton:SetScript("OnClick", function() AT.Next() end)

  tabButtons = {}
  local tabX = 10
  for i = 1, #PAGES do
    local spec = PAGES[i]
    local tab = button(frame, spec.label, 60, 20)
    tab:SetPoint("BOTTOMLEFT", tabX, 14)
    tab:SetScript("OnClick", function()
      if spec.id == "options" then
        UI.OpenOptions()
        return
      end
      AT.DB().options.page = spec.id
      AT.DB().racePicker = false
      UI.Refresh()
    end)
    tabButtons[i] = tab
    tabX = tabX + 64
  end

  frame.chapters = CreateFrame("Frame", nil, frame)
  frame.chapters:SetPoint("TOPLEFT", 14, -80)
  frame.chapters:SetSize(250, 280)
  frame.chapters:SetFrameStrata("HIGH")
  backdrop(frame.chapters)
  frame.chapters:Hide()
  frame.chapters.rows = {}

  arrow = CreateFrame("Frame", "AshenTrailArrow", UIParent)
  arrow:SetSize(180, 70)
  arrow:SetPoint("TOP", UIParent, "TOP", 0, -70)
  arrow.tex = arrow:CreateTexture(nil, "ARTWORK")
  arrow.tex:SetTexture("Interface\\Minimap\\MinimapArrow")
  arrow.tex:SetSize(42, 42)
  arrow.tex:SetPoint("TOP")
  arrow.label = arrow:CreateFontString(nil, "OVERLAY")
  arrow.label:SetPoint("TOP", arrow.tex, "BOTTOM", 0, -2)
  arrow.label:SetFont(fontPath(), 12, "")
  arrow.label:SetTextColor(BONE[1], BONE[2], BONE[3])
  arrow.label:SetJustifyH("CENTER")
  arrow.label:SetWidth(240)
  arrow.flight = arrow:CreateFontString(nil, "OVERLAY")
  arrow.flight:SetPoint("TOP", arrow.label, "BOTTOM", 0, -2)
  arrow.flight:SetFont(fontPath(), 12, "")
  arrow.flight:SetJustifyH("CENTER")
  arrow.flight:SetWidth(280)
  arrow.flight:Hide()

  discardButton = button(frame, "Drop junk", 160, 20)
  discardButton:SetPoint("BOTTOM", 0, 74)
  discardButton:Hide()
  discardButton:SetScript("OnClick", function()
    local item = AT.discardPrompt
    if item and AT.DiscardJunkItem(item) then
      AT.discardPrompt = nil
      AT.Say("Dropped " .. (item.name or "junk") .. ".")
      UI.Refresh()
    end
  end)

  breath = CreateFrame("Frame", "AshenTrailBreath", UIParent)
  breath:SetSize(240, 32)
  breath:SetPoint("TOP", UIParent, "TOP", 0, -150)
  breath:SetFrameStrata("HIGH")
  backdrop(breath)
  breath.label = breath:CreateFontString(nil, "OVERLAY")
  breath.label:SetPoint("CENTER")
  breath.label:SetFont(fontPath(), 14, "")
  breath:Hide()

  optionsFrame = CreateFrame("Frame", "AshenTrailOptions", UIParent)
  optionsFrame:SetSize(440, 540)
  optionsFrame:SetPoint("TOPLEFT", frame, "TOPRIGHT", 10, 0)
  optionsFrame:SetFrameStrata("HIGH")
  optionsFrame:SetClampedToScreen(true)
  optionsFrame:SetMovable(true)
  optionsFrame:EnableMouse(true)
  optionsFrame:RegisterForDrag("LeftButton")
  optionsFrame:SetScript("OnDragStart", function(self)
    if InCombatLockdown and InCombatLockdown() then return end
    self:StartMoving()
  end)
  optionsFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
  backdrop(optionsFrame)
  local optTitle = optionsFrame:CreateFontString(nil, "OVERLAY")
  optTitle:SetPoint("TOPLEFT", 14, -12)
  optTitle:SetFont(fontPath(), 16, "")
  optTitle:SetText("Options")
  optTitle:SetTextColor(EMBER[1], EMBER[2], EMBER[3])
  local optClose = button(optionsFrame, "Close", 64, 20)
  optClose:SetPoint("TOPRIGHT", -8, -8)
  optClose:SetScript("OnClick", function() optionsFrame:Hide() end)
  local optBody = CreateFrame("Frame", nil, optionsFrame)
  optBody:SetPoint("TOPLEFT", 8, -40)
  optBody:SetPoint("BOTTOMRIGHT", -8, 8)
  local optScroll = makeScroll(optBody)
  optScroll:ClearAllPoints()
  optScroll:SetPoint("TOPLEFT", optBody, "TOPLEFT", 0, 0)
  optScroll:SetPoint("BOTTOMRIGHT", optBody, "BOTTOMRIGHT", 0, 0)
  buildOptions(optScroll.child)
  optionsFrame.sync = optScroll.child.sync
  optionsFrame:Hide()

  menu = CreateFrame("Frame", "AshenTrailMenu", UIParent)
  menu:SetFrameStrata("TOOLTIP")
  menu:SetSize(180, 150)
  menu:EnableMouse(true)
  menu:Hide()
  backdrop(menu, nil, nil, nil, 0.98)
  menu.catcher = CreateFrame("Button", nil, UIParent)
  menu.catcher:SetAllPoints(UIParent)
  menu.catcher:SetFrameStrata("DIALOG")
  menu.catcher:SetScript("OnClick", function()
    menu:Hide()
    menu.catcher:Hide()
  end)
  menu.catcher:Hide()

  buildMinimap()
  if WorldMapFrame and WorldMapFrame.HookScript then
    WorldMapFrame:HookScript("OnShow", function() UI.UpdateMapPins() end)
    WorldMapFrame:HookScript("OnHide", function() UI.UpdateMapPins() end)
  end
  UI.Refresh()
  AT.UpdateTargetMacro()
end

function UI.FillChapters()
  local list = frame.chapters
  local ids = AT.RouteIds()
  local y = -8
  for i = 1, #ids do
    local chapter = AshenTrailData.chapters[ids[i]]
    local row = list.rows[i]
    if not row then
      row = button(list, "", 230, 22)
      list.rows[i] = row
    end
    row:SetPoint("TOPLEFT", 10, y)
    row:SetText(string.format("%d. %s", i, chapter and chapter.levelRange or ids[i]))
    row:SetScript("OnClick", function()
      AT.SetChapterIndex(i)
      list:Hide()
    end)
    row:Show()
    y = y - 24
  end
  for i = #ids + 1, #list.rows do list.rows[i]:Hide() end
  list:SetHeight(math.min(320, math.max(40, -y + 8)))
end
