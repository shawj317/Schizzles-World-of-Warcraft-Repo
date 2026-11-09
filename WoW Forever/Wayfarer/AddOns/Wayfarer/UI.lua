local _, ns = ...

-- The route window. Step text, clicks, and the auto-height rules match 1.0.5.

local L = ns.L
local C = ns.colors

local showNotices = false
local linePool = {}
local lineCount = 0
local CHROME = 40

local function HideLines()
	for i = 1, lineCount do
		linePool[i]:Hide()
		linePool[i]:SetScript("OnClick", nil)
		linePool[i]:SetScript("OnEnter", nil)
		linePool[i]:SetScript("OnLeave", nil)
	end
end

local function TakeLine(parent)
	lineCount = lineCount + 1
	local line = linePool[lineCount]
	if not line then
		line = CreateFrame("Button", nil, parent)
		line.text = line:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		line.text:SetPoint("TOPLEFT", 0, 0)
		line.text:SetPoint("TOPRIGHT", 0, 0)
		local highlight = line:CreateTexture(nil, "HIGHLIGHT")
		highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
		highlight:SetBlendMode("ADD")
		highlight:SetAllPoints()
		line.highlight = highlight
		linePool[lineCount] = line
	end
	line:SetParent(parent)
	line:Show()
	line.highlight:Hide()
	return line
end

local function PlaceLine(parent, y, indent, width, text, size, color, click, tip)
	local line = TakeLine(parent)
	line:ClearAllPoints()
	line:SetPoint("TOPLEFT", parent, "TOPLEFT", indent, y)
	line:SetWidth(width - indent)
	ns.Style(line.text, size, color)
	line.text:SetWidth(width - indent)
	line.text:SetText(text)
	local height = math.max(line.text:GetStringHeight(), size)
	line:SetHeight(height)
	if click then
		line:EnableMouse(true)
		line:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		line:SetScript("OnClick", click)
		line:SetScript("OnEnter", function(self)
			self.highlight:Show()
			if tip then
				ns.Tip(self, tip.title or "", tip.body)
			end
		end)
		line:SetScript("OnLeave", function(self)
			self.highlight:Hide()
			if GameTooltip then
				GameTooltip:Hide()
			end
		end)
	else
		line:EnableMouse(false)
	end
	return y - height - 3, height
end

local function StepTip(step)
	local body = ns.Cap(step.verb or "go")
	if step.questLevel and step.questLevel > 0 then
		body = body .. " · " .. L.LEVEL_WORD .. " " .. step.questLevel
	end
	if step.verb == "turn in" and step.xp and step.xp > 0 then
		body = body .. " · " .. step.xp .. (step.xpEstimated and L.XP_EST or L.XP)
	end
	body = body .. "\n" .. L.CLICK_TOMTOM
	body = body .. "\n" .. L.CLICK_HINT
	return { title = step.questName or step.title, body = body }
end

local function StepClick(step)
	return function(_, button)
		if button == "RightButton" then
			ns.OpenConfig()
			return
		end
		if IsShiftKeyDown and IsShiftKeyDown() then
			ns.SkipShown(step)
			return
		end
		ns.FocusArrow(step, true)
	end
end

local function Render(plan)
	plan = plan or {}
	local frame = ns.mainFrame
	local scroll = frame.scroll
	local child = frame.child
	local width = math.floor(frame:GetWidth() - 32)
	if width < 200 then
		width = 200
	end
	local chars = math.max(22, math.floor((width - 16) / 7))
	HideLines()
	lineCount = 0
	local y = -4
	local shown = ns.Planner.ClampSteps(ns.Settings().stepsShown)
	local steps = plan.steps or {}
	local visible = math.min(shown, #steps)
	if frame.zoneText then
		if plan.scope == "all" then
			frame.zoneText:SetText(L.SCOPE_ALL)
		else
			frame.zoneText:SetText(plan.zoneLabel or "")
		end
	end

	local lastZone
	local function BeforeStep(y, step)
		if plan.scope == "all" and step.routeZone and step.routeZone ~= lastZone then
			lastZone = step.routeZone
			local text = step.crossZone and (step.routeZone .. "  ·  other zone") or step.routeZone
			y = PlaceLine(child, y, 8, width, text, 12, step.crossZone and C.GOLD or C.TAN)
		end
		if step.travel then
			y = PlaceLine(child, y, 8, width, step.travel, 11, C.MUTED)
		end
		return y
	end

	if #steps == 0 then
		y = PlaceLine(child, y, 8, width, L.NO_STEPS, 14, C.WHITE)
		y = PlaceLine(child, y, 8, width, string.format(L.NOTHING_IN, plan.zoneLabel or "this zone"), 15, C.WHITE)
		y = PlaceLine(child, y, 8, width, L.OPEN_OPTIONS, 12, C.MUTED)
		y = y - 6
	else
		local current = steps[1]
		y = BeforeStep(y, current)
		y = PlaceLine(child, y, 8, width, string.format(L.STEP_OF, 1, #steps), 14, C.GOLD, StepClick(current), StepTip(current))
		y = PlaceLine(child, y, 22, width, ns.Ellipsize(current.title or current.questName, chars), 16, C.WHITE, StepClick(current), StepTip(current))
		local subtitle = ns.Cap(current.verb or "go")
		if plan.fromPlayer and plan.arriveSec then
			subtitle = subtitle .. " · " .. L.ARRIVE .. ns.Planner.FormatClock(plan.arriveSec)
		elseif not current.x then
			subtitle = subtitle .. " · " .. L.NO_PIN
		end
		y = PlaceLine(child, y, 22, width, subtitle, 12, C.MUTED, StepClick(current), StepTip(current))
		y = y - 6
		if #steps > 1 then
			y = PlaceLine(child, y, 8, width, L.THEN, 12, C.MUTED)
			local last = visible
			if last < 2 then
				last = 1
			end
			for i = 2, last do
				local step = steps[i]
				y = BeforeStep(y, step)
				y = PlaceLine(child, y, 8, width, ns.Ellipsize(step.title or step.questName, chars - 8) .. " (" .. step.verb .. ")", 13, C.CREAM, StepClick(step), StepTip(step))
			end
			local hidden = #steps - math.max(visible, 1)
			if hidden > 0 then
				y = PlaceLine(child, y, 8, width, string.format(L.MORE_STEPS, hidden), 12, C.MUTED)
			end
			y = y - 4
		end
		y = PlaceLine(child, y, 8, width, ns.Planner.Summary(plan), 13, C.GOLD)
		y = y - 4
	end

	if plan.scope == "all" then
		if (plan.otherZoneCount or 0) == 0 then
			y = PlaceLine(child, y, 8, width, L.ALL_HERE, 12, C.CREAM)
		else
			y = PlaceLine(child, y, 8, width, string.format(L.ALL_CONTINUE, plan.otherZoneCount), 12, C.CREAM)
		end
		if plan.nextZone then
			local nxt = plan.nextZone
			local questWord = nxt.quests == 1 and L.QUEST_ONE or string.format(L.QUESTS, nxt.quests)
			y = PlaceLine(child, y, 8, width, L.NEXT_ZONE .. nxt.name .. " · " .. questWord, 12, C.GOLD)
		end
	else
		local elsewhere = plan.elsewhereCount or 0
		if elsewhere == 0 then
			y = PlaceLine(child, y, 8, width, L.ELSEWHERE_NONE, 12, C.CREAM)
		elseif elsewhere == 1 then
			y = PlaceLine(child, y, 8, width, L.ELSEWHERE_ONE, 12, C.CREAM)
		else
			y = PlaceLine(child, y, 8, width, string.format(L.ELSEWHERE_MANY, elsewhere), 12, C.CREAM)
		end
		if plan.bestZone then
			local best = plan.bestZone
			local questWord = best.quests == 1 and L.QUEST_ONE or string.format(L.QUESTS, best.quests)
			y = PlaceLine(child, y, 8, width, L.BEST_MOVE .. best.name .. " · " .. questWord .. " · " .. ns.Planner.FormatXP(best.xpPerHour) .. L.XP_HOUR, 12, C.GOLD)
		elseif elsewhere > 0 and (plan.elsewherePlannable or 0) > 0 then
			y = PlaceLine(child, y, 8, width, L.NONE_FIT, 12, C.MUTED)
		elseif elsewhere > 0 then
			y = PlaceLine(child, y, 8, width, L.NO_ZONE_PIN, 12, C.MUTED)
		end
	end
	local omitted = plan.omittedDungeons or 0
	if omitted == 1 then
		y = PlaceLine(child, y, 8, width, L.DUNGEON_ONE, 12, C.MUTED)
	elseif omitted > 1 then
		y = PlaceLine(child, y, 8, width, string.format(L.DUNGEON_MANY, omitted), 12, C.MUTED)
	end
	y = y - 6

	local notices = plan.notices or {}
	if #notices > 0 then
		local label = #notices == 1 and L.NOTICE_ONE or string.format(L.NOTICE_MANY, #notices)
		y = PlaceLine(child, y, 8, width, "|cffff9e47!|r " .. label, 12, C.EMBER, function()
			showNotices = not showNotices
			Render(plan)
		end)
		if showNotices then
			local capNotes = math.min(#notices, 8)
			for i = 1, capNotes do
				y = PlaceLine(child, y, 18, width, ns.Ellipsize(notices[i], 70), 11, C.MUTED)
			end
			if #notices > capNotes then
				y = PlaceLine(child, y, 18, width, string.format(L.MORE_NOTES, #notices - capNotes), 11, C.MUTED)
			end
		end
		y = y - 4
	end

	local avoid = plan.avoid or {}
	if #avoid > 0 then
		y = PlaceLine(child, y, 8, width, string.format(L.AVOID, #avoid), 13, C.TAN)
		local capAvoid = math.min(#avoid, 8)
		for i = 1, capAvoid do
			local row = avoid[i]
			local text = "|cffe04838x|r " .. ns.Ellipsize(row.name, 28) .. ": " .. row.reason
			y = PlaceLine(child, y, 8, width, text, 12, C.TAN)
		end
		if #avoid > capAvoid then
			y = PlaceLine(child, y, 8, width, string.format(L.MORE, #avoid - capAvoid), 12, C.MUTED)
		end
	end

	local contentHeight = math.max(8 - y, 40)
	child:SetWidth(width)
	child:SetHeight(contentHeight)
	local db = ns.Settings()
	local frameHeight = frame:GetHeight()
	if not db.userSized then
		frameHeight = contentHeight + CHROME
		if frameHeight < 210 then
			frameHeight = 210
		end
		if frameHeight > 640 then
			frameHeight = 640
		end
		frame:SetHeight(frameHeight)
	end
	local maxScroll = contentHeight - (frameHeight - CHROME)
	if maxScroll < 0 then
		maxScroll = 0
	end
	if scroll:GetVerticalScroll() > maxScroll then
		scroll:SetVerticalScroll(maxScroll)
	end
end

ns.Render = Render

function ns.ShowError(err)
	HideLines()
	lineCount = 0
	local frame = ns.mainFrame
	local width = math.floor(frame:GetWidth() - 32)
	PlaceLine(frame.child, -8, 8, width, L.ERROR_TITLE, 14, C.WHITE)
	PlaceLine(frame.child, -28, 8, width, ns.Ellipsize(tostring(err), 180), 11, C.RED)
	frame.child:SetHeight(80)
	frame:SetHeight(220)
end

ns.skipped = {}

local function ViewPlan(plan)
	if not plan then
		return nil
	end
	local view = {}
	for key, value in pairs(plan) do
		view[key] = value
	end
	view.steps = ns.WithoutSkips(plan.steps, ns.skipped)
	view.totalSteps = #view.steps
	return view
end

function ns.Redisplay()
	local plan = ns.mainFrame and ns.mainFrame.plan
	if not plan then
		return
	end
	local view = ViewPlan(plan)
	if ns.mainFrame:IsShown() then
		Render(view)
	end
	if ns.SyncRoute then
		ns.SyncRoute(view, nil, false)
	end
end

function ns.ShowRoute(plan, setArrow)
	ns.skipped = ns.skipped or {}
	local key = ns.QuestSetKey(plan and plan.steps)
	if setArrow or key ~= ns.skipQuestSig then
		ns.ClearSkips(ns.skipped)
		ns.skipQuestSig = key
	end
	ns.mainFrame.plan = plan
	local view = ViewPlan(plan)
	Render(view)
	local focus = setArrow and view.steps and view.steps[1] or nil
	ns.SyncRoute(view, focus, setArrow)
end

function ns.SkipShown(step)
	ns.skipped = ns.skipped or {}
	ns.SkipStep(ns.skipped, step)
	local plan = ns.mainFrame and ns.mainFrame.plan
	if not plan then
		return
	end
	local view = ViewPlan(plan)
	Render(view)
	ns.SyncRoute(view, view.steps and view.steps[1], false)
end

function ns.Unskip()
	ns.ClearSkips(ns.skipped)
	local plan = ns.mainFrame and ns.mainFrame.plan
	if plan then
		local view = ViewPlan(plan)
		Render(view)
		ns.SyncRoute(view, view.steps and view.steps[1], false)
	end
end

function ns.Refresh(setArrow)
	if ns.scanning then
		return
	end
	ns.scanning = true
	local ok, plan = pcall(ns.ScanQuests)
	ns.scanning = false
	if GetTime then
		ns.quietUntil = GetTime() + 3
	end
	if not ok then
		ns.ShowError(plan)
		return
	end
	ns.mainFrame.plan = plan
	ns.ShowRoute(plan, setArrow)
end

function ns.BuildMain()
	local frame = ns.Frame("Frame", "WayfarerFrame", UIParent)
	frame:SetSize(336, 280)
	local savedSize = ns.Settings()
	if tonumber(savedSize.width) and tonumber(savedSize.height) then
		frame:SetSize(savedSize.width, savedSize.height)
		savedSize.userSized = true
	end
	frame:SetResizable(true)
	if frame.SetResizeBounds then
		frame:SetResizeBounds(280, 200, 720, 900)
	elseif frame.SetMinResize then
		frame:SetMinResize(280, 200)
		frame:SetMaxResize(720, 900)
	end
	frame:SetFrameStrata("HIGH")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:EnableMouseWheel(true)
	frame:SetClampedToScreen(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		ns.SavePoint(self, "point")
	end)
	ns.Paint(frame)
	frame:Hide()
	if UISpecialFrames then
		table.insert(UISpecialFrames, "WayfarerFrame")
	end
	ns.LoadPoint(frame, "point", { "TOPRIGHT", "TOPRIGHT", -40, -160 })

	local bar = frame:CreateTexture(nil, "BACKGROUND")
	bar:SetPoint("TOPLEFT", 4, -4)
	bar:SetPoint("TOPRIGHT", -4, -4)
	bar:SetHeight(22)
	bar:SetTexture("Interface\\Buttons\\WHITE8X8")
	bar:SetVertexColor(0.10, 0.08, 0.06, 0.95)
	frame.headerBar = bar

	local scroll = CreateFrame("ScrollFrame", nil, frame)
	scroll:SetPoint("TOPLEFT", 12, -32)
	scroll:SetPoint("BOTTOMRIGHT", -10, 8)
	scroll:EnableMouse(true)
	scroll:EnableMouseWheel(true)
	scroll:RegisterForDrag("LeftButton")
	scroll:SetScript("OnDragStart", function()
		frame:StartMoving()
	end)
	scroll:SetScript("OnDragStop", function()
		frame:StopMovingOrSizing()
		ns.SavePoint(frame, "point")
	end)
	local child = CreateFrame("Frame", nil, scroll)
	child:SetSize(304, 200)
	scroll:SetScrollChild(child)
	local function Wheel(_, delta)
		local height = child:GetHeight() - scroll:GetHeight()
		if height < 0 then
			height = 0
		end
		local nextScroll = scroll:GetVerticalScroll() - delta * 28
		if nextScroll < 0 then
			nextScroll = 0
		end
		if nextScroll > height then
			nextScroll = height
		end
		scroll:SetVerticalScroll(nextScroll)
	end
	scroll:SetScript("OnMouseWheel", Wheel)
	frame:SetScript("OnMouseWheel", Wheel)

	local function OpenSettings(_, button)
		if button == "RightButton" then
			ns.OpenConfig()
		end
	end
	frame:SetScript("OnMouseUp", OpenSettings)
	scroll:SetScript("OnMouseUp", OpenSettings)

	local close = ns.CloseButton(frame)
	frame.closeButton = close
	local function HeaderIcon(texture, tip, onClick)
		local button = CreateFrame("Button", nil, frame)
		button:SetSize(16, 16)
		local icon = button:CreateTexture(nil, "ARTWORK")
		icon:SetAllPoints()
		icon:SetTexture(texture)
		button:SetScript("OnClick", onClick)
		button:SetScript("OnEnter", function(self)
			ns.Tip(self, tip, nil)
		end)
		button:SetScript("OnLeave", function()
			if GameTooltip then
				GameTooltip:Hide()
			end
		end)
		return button
	end
	local cog = HeaderIcon("Interface\\Icons\\INV_Misc_Gear_01", L.COG_TIP, function()
		ns.OpenConfig()
	end)
	cog:SetPoint("RIGHT", close, "LEFT", -2, 0)
	local refresh = HeaderIcon("Interface\\Buttons\\UI-RefreshButton", L.REFRESH_TIP, function()
		ns.Refresh(true)
	end)
	refresh:SetPoint("RIGHT", cog, "LEFT", -2, 0)
	local header = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	header:SetPoint("TOPLEFT", 14, -8)
	ns.Style(header, 14, C.GOLD, "LEFT", false)
	header:SetText(L.TITLE)
	local zoneText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	zoneText:SetPoint("RIGHT", refresh, "LEFT", -6, 0)
	zoneText:SetWidth(120)
	zoneText:SetJustifyH("RIGHT")
	ns.Style(zoneText, 11, C.TAN, "RIGHT", false)
	frame.zoneText = zoneText

	local grip = CreateFrame("Button", nil, frame)
	grip:SetSize(16, 16)
	grip:SetPoint("BOTTOMRIGHT", -4, 4)
	grip:SetFrameLevel((frame:GetFrameLevel() or 1) + 30)
	grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	grip:RegisterForClicks("LeftButtonUp")
	grip:SetScript("OnMouseDown", function()
		frame:StartSizing("BOTTOMRIGHT")
	end)
	grip:SetScript("OnMouseUp", function()
		frame:StopMovingOrSizing()
		local db = ns.Settings()
		db.userSized = true
		db.width = frame:GetWidth()
		db.height = frame:GetHeight()
		if frame.plan and ns.Redisplay then
			ns.Redisplay()
		end
	end)
	grip:SetScript("OnEnter", function(self)
		ns.Tip(self, L.RESIZE, nil)
	end)
	grip:SetScript("OnLeave", function()
		if GameTooltip then
			GameTooltip:Hide()
		end
	end)

	frame.scroll = scroll
	frame.child = child
	frame:SetScript("OnShow", function()
		ns.Refresh(false)
	end)
	ns.mainFrame = frame
	if ns.ApplyAppearance then
		ns.ApplyAppearance()
	end
end
