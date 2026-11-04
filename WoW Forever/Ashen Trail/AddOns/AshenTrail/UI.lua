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

local frame, arrow, pages, hint, progressBar, stepLabel, chapterLabel, minimapButton, discardButton, breath
local linePool, rowPool, pinPool, markPool = {}, {}, {}, {}
local mapPins = {}
local nearFilter = "all"

local function fontPath()
  local path = GameFontNormal and GameFontNormal:GetFont()
  return path or "Fonts\\FRIZQT__.TTF"
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
end

local function backdrop(widget, r, g, b, a)
  if not widget.SetBackdrop then return end
  local colors = theme()
  widget:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
  })
  widget:SetBackdropColor(r or colors.bg[1], g or colors.bg[2], b or colors.bg[3], a or 0.94)
  widget:SetBackdropBorderColor(colors.edge[1], colors.edge[2], colors.edge[3], 0.95)
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

local function layoutFrame()
  local db = AT.DB()
  local compact = db.options.compact
  frame:SetSize(460, compact and 430 or 560)
  frame:SetScale(db.options.scale or 1)
  frame:SetAlpha(db.options.alpha or 0.94)
  frame:SetMovable(not db.options.locked)
  if db.hidden then frame:Hide() else frame:Show() end
end

local function lineColor(state)
  local colors = theme()
  if state == "done" then return colors.done end
  if state == "open" then return colors.open end
  if state == "note" then return colors.muted end
  return colors.text
end

local function ensureMark(parent, index)
  local widget = markPool[index]
  if widget then return widget end
  widget = button(parent, "Mark", 52, 18)
  markPool[index] = widget
  return widget
end

local function fillWrapped(parent, rows, onClick)
  local width = parent:GetWidth()
  if width < 40 then width = 400 end
  local y = -4
  local marks = 0
  for i = 1, #rows do
    local row = rows[i]
    local fs = ensureLine(parent, i)
    fs:SetParent(parent)
    paint(fs, row.color[1], row.color[2], row.color[3])
    local markWidth = 0
    if row.mark then
      marks = marks + 1
      local pin = row.mark
      local mark = ensureMark(parent, marks)
      mark:SetParent(parent)
      mark:ClearAllPoints()
      mark:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, y)
      mark:SetScript("OnClick", function()
        AT.FocusNode({ zone = pin.zone, x = pin.x, y = pin.y, name = pin.name, kind = "goto" })
        AT.Say("Arrow set to " .. (pin.name or "that spot") .. ".")
      end)
      mark:Show()
      markWidth = 58
    end
    fs:SetWidth(width - 16 - markWidth)
    fs:SetText(row.text)
    fs:ClearAllPoints()
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, y)
    fs:Show()
    local height = fs:GetStringHeight()
    if not height or height < 8 then height = fontSize() + 2 end
    if row.mark and height < 18 then height = 18 end
    y = y - height - 6
  end
  hidePool(linePool, #rows + 1)
  hidePool(markPool, marks + 1)
  parent:SetHeight(math.max(24, -y + 8))
  if onClick then onClick(rows) end
end

local function guideRows()
  local db = AT.DB()
  local chapter = AT.Chapter()
  local step, steps = AT.CurrentStep()
  local rows = {}
  if db.finished then
    rows[#rows + 1] = { text = "Ashen Trail is finished. Bank heirlooms, lock Dual Spec, and claim the Legacy Point.", color = MOSS }
    return rows
  end
  if not step then
    rows[#rows + 1] = { text = "This chapter has no steps for your race and class.", color = MUTED }
    return rows
  end
  local ctx = AT.Context()
  for i = 1, #(step.lines or {}) do
    local line = step.lines[i]
    if line.k ~= "goto" then
      local state = L.LineState(line, ctx)
      local text = L.FormatLine(line)
      if text and text ~= "" then
        local row = { text = text, color = lineColor(state) }
        if line.zone and line.x and line.y and (line.k == "dungeon" or line.k == "accept" or line.k == "turnin" or line.k == "trainer") then
          row.mark = { zone = line.zone, x = line.x, y = line.y, name = line.npc or line.mark or line.name }
        end
        rows[#rows + 1] = row
      end
    end
  end
  if chapter and chapter.notes and chapter.notes[1] and db.step == 1 then
    rows[#rows + 1] = { text = chapter.notes[1], color = MUTED }
  end
  return rows
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
  if step then
    for i = 1, #(step.lines or {}) do
      local line = step.lines[i]
      if line.k == "dungeon" and line.x and line.zone then
        parts[#parts + 1] = "Press Mark beside a line to point the arrow at that NPC."
        break
      end
    end
  end
  return table.concat(parts, "\n")
end

local function renderGuide()
  local db = AT.DB()
  local chapter = AT.Chapter()
  local _, steps = AT.CurrentStep()
  local index = db.step or 1
  local total = #steps
  local manual = db.options.chapterMode == "manual"
  if chapter then
    chapterLabel:SetText((manual and "Manual  " or "") .. (chapter.name or "Ashen Trail"))
  else
    chapterLabel:SetText(manual and "Manual" or "Ashen Trail")
  end
  if db.finished then
    stepLabel:SetText("Route complete")
  else
    stepLabel:SetText(string.format("Step %d / %d", math.min(index, math.max(total, 1)), math.max(total, 1)))
  end
  local pct = 0
  if total > 0 then pct = math.min(1, (index - 1) / total) end
  if db.finished then pct = 1 end
  local width = progressBar.bg:GetWidth()
  progressBar.bar:SetWidth(math.max(1, width * pct))
  local child = pages.guide.child
  fillWrapped(child, guideRows())
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
  hint:SetText("Click a pin to point the arrow at it. Mark on a dungeon line does the same thing. Step changes clear that override.")
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
  end
  fillWrapped(child, rows)
  hint:SetText("Hearth, flight, boat, and zeppelin hops are suggestions. The addon cannot take them for you.")
end

local function renderGear()
  local child = pages.gear.child
  local db = AT.DB()
  local rows = {}
  local role = ROLE[db.class or ""] or "your class stats"
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
  if #order == 0 then
    rows[1] = { text = "Turn-ins you complete while Ashen Trail is running show up here.", color = MUTED }
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
  hint:SetText("History is saved per character. Reset clears it.")
end

local function renderOptions()
  hint:SetText("Themes and these switches are saved on this character. Auto chapters are the default. Junk never sells or drops a whitelisted item.")
  if pages.options.sync then pages.options.sync() end
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
  if stepLabel then
    stepLabel:SetFont(fontPath(), math.max(10, size - 1), "")
    stepLabel:SetTextColor(colors.muted[1], colors.muted[2], colors.muted[3])
  end
  if hint then
    hint:SetFont(fontPath(), math.max(10, size - 2), "")
    hint:SetTextColor(colors.muted[1], colors.muted[2], colors.muted[3])
  end
  if progressBar and progressBar.bar and progressBar.bar.SetColorTexture then
    progressBar.bar:SetColorTexture(colors.accent[1], colors.accent[2], colors.accent[3], 1)
  end
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

function UI.Refresh()
  if not frame then return end
  if AT.EnsureTheme then AT.EnsureTheme() end
  local db = AT.DB()
  layoutFrame()
  UI.ApplyChrome()
  UI.ApplyMinimap()
  UI.SyncDiscard()
  UI.SyncBreath()
  local blocked = renderGate()
  local page = db.options.page or "guide"
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
    elseif page == "options" then renderOptions()
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
  local step = AT.CurrentStep()
  local pois = step and step.pois or {}
  for i = 1, #pois do
    if not zoneName or pois[i].zone == zoneName then
      pins[#pins + 1] = pois[i]
    end
  end
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
    { key = "compact", label = "Compact window" },
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
  }, y)

  y = addSection("Window", y)
  y = addSlider("AshenTrailScaleSlider", "Window scale", y, 0.7, 1.4, 0.05, function(value)
    if InCombatLockdown and InCombatLockdown() then return end
    AT.DB().options.scale = value
    if frame then frame:SetScale(value) end
  end, "0.7", "1.4")
  y = addSlider("AshenTrailAlphaSlider", "Opacity", y, 0.55, 1, 0.05, function(value)
    AT.DB().options.alpha = value
    if frame then frame:SetAlpha(value) end
  end, "55%", "100%")

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
  backdrop(frame)
  local point = AT.DB().point
  frame:SetPoint(point[1] or "CENTER", UIParent, point[2] or "CENTER", point[3] or 0, point[4] or 0)

  local title = frame:CreateFontString(nil, "OVERLAY")
  title:SetFont(fontPath(), 18, "")
  title:SetPoint("TOPLEFT", 14, -12)
  title:SetTextColor(EMBER[1], EMBER[2], EMBER[3])
  title:SetText("Ashen Trail")
  frame.title = title

  local close = button(frame, "Hide", 52, 20)
  close:SetPoint("TOPRIGHT", -10, -10)
  close:SetScript("OnClick", function() AT.Toggle() end)

  local race = button(frame, "Race", 52, 20)
  race:SetPoint("RIGHT", close, "LEFT", -4, 0)
  race:SetScript("OnClick", function()
    local db = AT.DB()
    db.racePicker = not db.racePicker
    if db.racePicker then
      pages.gate:Show()
      pages.gate.title:SetText("Switch route")
      pages.gate.body:SetText(db.pendingRace and "Click the same race again to reset progress." or "Pick a start. Switching clears tracked turn-ins.")
      pages.gate.force:Hide()
      for i = 1, #pages.gate.races do pages.gate.races[i]:Show() end
    else
      UI.Refresh()
    end
  end)

  local sync = button(frame, "Catch up", 78, 20)
  sync:SetPoint("RIGHT", race, "LEFT", -4, 0)
  sync:SetScript("OnClick", function()
    AT.PrimeCompleted()
    AT.Sync(true)
    AT.Say("Caught up to the first unfinished step.")
  end)

  chapterLabel = frame:CreateFontString(nil, "OVERLAY")
  chapterLabel:SetPoint("TOPLEFT", 14, -40)
  chapterLabel:SetPoint("TOPRIGHT", -14, -40)
  chapterLabel:SetJustifyH("LEFT")
  chapterLabel:SetFont(fontPath(), 14, "")
  chapterLabel:SetTextColor(BONE[1], BONE[2], BONE[3])

  local chapterButton = button(frame, "Chapters", 80, 18)
  chapterButton:SetPoint("TOPRIGHT", -12, -58)
  local skip = button(frame, "Skip", 52, 18)
  skip:SetPoint("TOPRIGHT", chapterButton, "TOPLEFT", -6, 0)
  skip:SetScript("OnClick", function() AT.Skip() end)
  skip:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Skip this step")
    GameTooltip:AddLine("Moves past a stuck step. Prev, then /at unskip, tries it again.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  skip:SetScript("OnLeave", function() GameTooltip:Hide() end)
  chapterButton:SetScript("OnClick", function()
    local list = frame.chapters
    if list:IsShown() then list:Hide() else list:Show() UI.FillChapters() end
  end)

  stepLabel = frame:CreateFontString(nil, "OVERLAY")
  stepLabel:SetPoint("TOPLEFT", 14, -62)
  stepLabel:SetFont(fontPath(), 12, "")
  stepLabel:SetTextColor(MUTED[1], MUTED[2], MUTED[3])

  progressBar = CreateFrame("Frame", nil, frame)
  progressBar:SetPoint("TOPLEFT", 14, -82)
  progressBar:SetPoint("TOPRIGHT", -12, -82)
  progressBar:SetHeight(8)
  progressBar.bg = progressBar:CreateTexture(nil, "BACKGROUND")
  progressBar.bg:SetAllPoints()
  progressBar.bg:SetColorTexture(0.2, 0.16, 0.12, 1)
  progressBar.bar = progressBar:CreateTexture(nil, "ARTWORK")
  progressBar.bar:SetPoint("LEFT")
  progressBar.bar:SetHeight(8)
  progressBar.bar:SetWidth(1)
  progressBar.bar:SetColorTexture(EMBER[1], EMBER[2], EMBER[3], 1)

  local body = CreateFrame("Frame", nil, frame)
  body:SetPoint("TOPLEFT", 10, -98)
  body:SetPoint("BOTTOMRIGHT", -10, 118)
  backdrop(body, 0.05, 0.04, 0.04, 0.6)

  pages = {}
  pages.guide = makeScroll(body)
  pages.pins = makeScroll(body)
  pages.near = makeScroll(body)
  pages.route = makeScroll(body)
  pages.gear = makeScroll(body)
  pages.log = makeScroll(body)
  pages.options = makeScroll(body)
  pages.gate = CreateFrame("Frame", nil, body)
  pages.gate:SetAllPoints()
  buildOptions(pages.options.child)
  pages.options.sync = pages.options.child.sync
  pages.options:SetScript("OnShow", function()
    if pages.options.sync then pages.options.sync() end
  end)
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

  hint = frame:CreateFontString(nil, "OVERLAY")
  hint:SetPoint("BOTTOMLEFT", 14, 78)
  hint:SetPoint("BOTTOMRIGHT", -14, 78)
  hint:SetHeight(36)
  hint:SetJustifyH("LEFT")
  hint:SetJustifyV("TOP")
  hint:SetWordWrap(true)
  hint:SetFont(fontPath(), 11, "")
  hint:SetTextColor(MUTED[1], MUTED[2], MUTED[3])

  local prev = button(frame, "Prev", 90, 24)
  prev:SetPoint("BOTTOMLEFT", 14, 46)
  prev:SetScript("OnClick", function() AT.Prev() end)

  local target = CreateFrame("Button", "AshenTrailTargetButton", frame, "SecureActionButtonTemplate,UIPanelButtonTemplate")
  target:SetSize(140, 24)
  target:SetPoint("BOTTOM", 0, 46)
  target:SetText("Target")
  target:SetAttribute("type", "macro")
  target:SetAttribute("macrotext", "")
  target:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(AT.targetName and ("Target " .. AT.targetName) or "No NPC on this step")
    GameTooltip:Show()
  end)
  target:SetScript("OnLeave", function() GameTooltip:Hide() end)

  local nextButton = button(frame, "Next", 90, 24)
  nextButton:SetPoint("BOTTOMRIGHT", -14, 46)
  nextButton:SetScript("OnClick", function() AT.Next() end)

  local tabX = 10
  for i = 1, #PAGES do
    local spec = PAGES[i]
    local tab = button(frame, spec.label, 60, 20)
    tab:SetPoint("BOTTOMLEFT", tabX, 14)
    tab:SetScript("OnClick", function()
      AT.DB().options.page = spec.id
      AT.DB().racePicker = false
      UI.Refresh()
    end)
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
