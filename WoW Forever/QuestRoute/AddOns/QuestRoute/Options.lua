local _, ns = ...

-- Options window, the Esc > Options > AddOns page when the client has it,
-- and the addon-compartment button. The compartment hooks follow
-- RutaMisiones (Fastest Quest Route) by Nico, MIT.

local L = ns.L
local C = ns.colors

local lock = false

local function Checked(button, value)
	button:SetChecked(value and true or false)
end

local function BindCheck(button, apply)
	button:SetScript("OnClick", function(self)
		if lock then
			return
		end
		apply(self:GetChecked() and true or false)
	end)
end

local function SliderText(slider, text)
	local label = _G[slider:GetName() .. "Text"]
	if label then
		label:SetText(text)
		ns.Style(label, 12, C.CREAM, "CENTER", false)
	end
	local lowLabel = _G[slider:GetName() .. "Low"]
	local highLabel = _G[slider:GetName() .. "High"]
	if lowLabel then
		lowLabel:SetText("")
	end
	if highLabel then
		highLabel:SetText("")
	end
end

function ns.BuildConfig()
	local frame = ns.Frame("Frame", "QuestRouteConfigFrame", UIParent)
	frame:SetSize(420, 700)
	frame:SetFrameStrata("HIGH")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetClampedToScreen(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		ns.SavePoint(self, "configPoint")
	end)
	ns.Paint(frame)
	frame:Hide()
	if UISpecialFrames then
		table.insert(UISpecialFrames, "QuestRouteConfigFrame")
	end
	ns.LoadPoint(frame, "configPoint", { "CENTER", "CENTER", 40, 40 })
	ns.CloseButton(frame)

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	title:SetPoint("TOPLEFT", 16, -14)
	ns.Style(title, 16, C.WHITE)
	title:SetText(L.TITLE)

	local sub = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	sub:SetPoint("TOPLEFT", 16, -36)
	sub:SetWidth(360)
	ns.Style(sub, 11, C.MUTED)
	sub:SetText(L.OPT_INTRO)

	local function Section(text, y)
		local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		label:SetPoint("TOPLEFT", 16, y)
		ns.Style(label, 12, C.GOLD, "LEFT", false)
		label:SetText(text)
		ns.Rule(frame, y - 16, 0.45)
	end

	local function Check(name, label, y, tip)
		local button = CreateFrame("CheckButton", name, frame, "UICheckButtonTemplate")
		button:SetPoint("TOPLEFT", 12, y)
		local text = _G[button:GetName() .. "Text"]
		if text then
			text:SetText(label)
			ns.Style(text, 13, C.CREAM, "LEFT", false)
		end
		if tip then
			button:SetScript("OnEnter", function(self)
				ns.Tip(self, label, tip)
			end)
			button:SetScript("OnLeave", function()
				GameTooltip:Hide()
			end)
		end
		return button
	end

	local function Hint(text, y)
		local font = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		font:SetPoint("TOPLEFT", 40, y)
		font:SetWidth(350)
		ns.Style(font, 11, C.MUTED)
		font:SetText(text)
		return font
	end

	local function Slider(name, y, minValue, maxValue)
		local slider = CreateFrame("Slider", name, frame, "OptionsSliderTemplate")
		slider:SetPoint("TOPLEFT", 28, y)
		slider:SetWidth(340)
		slider:SetMinMaxValues(minValue, maxValue)
		slider:SetValueStep(1)
		if slider.SetObeyStepOnDrag then
			pcall(slider.SetObeyStepOnDrag, slider, true)
		end
		return slider
	end

	Section(L.SECTION_ROUTE, -78)
	local low = Check("QuestRouteLowCheck", L.OPT_LOW, -100, L.OPT_LOW_HINT)
	Hint(L.OPT_LOW_HINT, -126)
	local dungeon = Check("QuestRouteDungeonCheck", L.OPT_DUNGEON, -168, L.OPT_DUNGEON_TIP)
	local above = Slider("QuestRouteAboveSlider", -214, 0, 10)
	Hint(L.OPT_ABOVE_HINT, -246)
	local steps = Slider("QuestRouteStepsSlider", -292, 1, 20)
	Hint(L.OPT_STEPS_HINT, -324)

	Section(L.SECTION_MAP, -372)
	local mapToggle = Check("QuestRouteMapCheck", L.OPT_MAP, -394, L.OPT_MAP_TIP)
	local tomtomToggle = Check("QuestRouteTomTomCheck", L.OPT_TOMTOM, -422, L.OPT_TOMTOM_TIP)

	Section(L.SECTION_TEXT, -460)
	local fontLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	fontLabel:SetPoint("TOPLEFT", 28, -482)
	ns.Style(fontLabel, 12, C.MUTED, "LEFT", false)
	fontLabel:SetText(L.OPT_FONT)

	local prevFont = ns.TextButton(frame, "<", function()
		local db = ns.Settings()
		db.font = db.font - 1
		if db.font < 1 then
			db.font = #ns.FONT_CHOICES
		end
		ns.ApplyTypography()
	end, 28)
	prevFont:SetPoint("TOPLEFT", 28, -500)
	local fontName = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	fontName:SetPoint("LEFT", prevFont, "RIGHT", 10, 0)
	fontName:SetWidth(220)
	ns.Style(fontName, 14, C.WHITE, "LEFT", false)
	fontName:SetText(ns.FontFile())
	ns.fontNameFS = fontName
	local nextFont = ns.TextButton(frame, ">", function()
		local db = ns.Settings()
		db.font = db.font + 1
		if db.font > #ns.FONT_CHOICES then
			db.font = 1
		end
		ns.ApplyTypography()
	end, 28)
	nextFont:SetPoint("LEFT", fontName, "RIGHT", 8, 0)

	local size = Slider("QuestRouteFontSlider", -548, 9, 22)
	Hint(L.OPT_SIZE_HINT, -580)

	BindCheck(low, function(value)
		ns.Settings().includeLowLevel = value
		if ns.mainFrame and ns.mainFrame:IsShown() then
			ns.Refresh(false)
		end
	end)
	BindCheck(dungeon, function(value)
		ns.Settings().omitDungeons = value
		if ns.mainFrame and ns.mainFrame:IsShown() then
			ns.Refresh(false)
		end
	end)
	BindCheck(mapToggle, function(value)
		ns.Settings().showOnMap = value
		if ns.mainFrame and ns.mainFrame.plan then
			ns.SyncRoute(ns.mainFrame.plan, nil, false)
		end
	end)
	BindCheck(tomtomToggle, function(value)
		ns.Settings().useTomTom = value
		ns.InvalidateRoute()
		if ns.mainFrame and ns.mainFrame.plan then
			local plan = ns.mainFrame.plan
			ns.SyncRoute(plan, plan.steps and plan.steps[1], false)
		end
	end)

	above:SetScript("OnValueChanged", function(self, value)
		SliderText(self, string.format(L.OPT_ABOVE, ns.Planner.ClampAbove(value)))
	end)
	above:SetScript("OnMouseUp", function(self)
		if lock then
			return
		end
		ns.Settings().maxLevelsAbove = ns.Planner.ClampAbove(self:GetValue())
		if ns.mainFrame and ns.mainFrame:IsShown() then
			ns.Refresh(false)
		end
	end)
	steps:SetScript("OnValueChanged", function(self, value)
		local rounded = ns.Planner.ClampSteps(value)
		SliderText(self, string.format(L.OPT_STEPS, rounded))
		if not lock and ns.mainFrame and ns.mainFrame:IsShown() and ns.mainFrame.plan then
			ns.Settings().stepsShown = rounded
			ns.Render(ns.mainFrame.plan)
		end
	end)
	steps:SetScript("OnMouseUp", function(self)
		ns.Settings().stepsShown = ns.Planner.ClampSteps(self:GetValue())
	end)
	size:SetScript("OnValueChanged", function(self, value)
		local rounded = math.floor((tonumber(value) or 13) + 0.5)
		if rounded < 9 then
			rounded = 9
		elseif rounded > 22 then
			rounded = 22
		end
		SliderText(self, string.format(L.OPT_SIZE, rounded))
		if lock then
			return
		end
		ns.Settings().fontSize = rounded
		ns.ApplyTypography()
	end)

	local function Sync()
		local db = ns.Settings()
		lock = true
		Checked(low, db.includeLowLevel)
		Checked(dungeon, db.omitDungeons)
		Checked(mapToggle, db.showOnMap)
		Checked(tomtomToggle, db.useTomTom)
		above:SetValue(db.maxLevelsAbove)
		steps:SetValue(db.stepsShown)
		size:SetValue(db.fontSize)
		SliderText(above, string.format(L.OPT_ABOVE, db.maxLevelsAbove))
		SliderText(steps, string.format(L.OPT_STEPS, db.stepsShown))
		SliderText(size, string.format(L.OPT_SIZE, db.fontSize))
		fontName:SetText(ns.FontFile())
		lock = false
	end

	local recalc = ns.TextButton(frame, L.RECALC, function()
		ns.mainFrame:Show()
		ns.Refresh(true)
	end, 118, L.RECALC_TIP)
	recalc:SetPoint("BOTTOMLEFT", 16, 14)
	local close = ns.TextButton(frame, L.CLOSE, function()
		frame:Hide()
	end, 88)
	close:SetPoint("BOTTOMRIGHT", -16, 14)

	frame:SetScript("OnShow", Sync)
	ns.configFrame = frame
	ns.SyncConfig = Sync
end

function ns.OpenConfig()
	ns.EnsureUI()
	if ns.configFrame then
		ns.configFrame:Show()
	end
end

local function OnPanelChanged(key)
	return function()
		local db = ns.Settings()
		if key == "showOnMap" then
			if ns.mainFrame and ns.mainFrame.plan then
				ns.SyncRoute(ns.mainFrame.plan, nil, false)
			end
		elseif key == "useTomTom" then
			ns.InvalidateRoute()
			if ns.mainFrame and ns.mainFrame.plan then
				local plan = ns.mainFrame.plan
				ns.SyncRoute(plan, plan.steps and plan.steps[1], false)
			end
		elseif key == "stepsShown" then
			if ns.mainFrame and ns.mainFrame:IsShown() and ns.mainFrame.plan then
				ns.Render(ns.mainFrame.plan)
			end
		elseif key == "fontSize" then
			ns.ApplyTypography()
		elseif ns.mainFrame and ns.mainFrame:IsShown() then
			ns.Refresh(false)
		end
		if ns.configFrame and ns.configFrame:IsShown() and ns.SyncConfig then
			ns.SyncConfig()
		end
		return db
	end
end

function ns.RegisterSettings()
	if ns.settingsCategory or not Settings or not Settings.RegisterVerticalLayoutCategory then
		return
	end
	local ok = pcall(function()
		local db = ns.Settings()
		local category = Settings.RegisterVerticalLayoutCategory(L.TITLE)
		local function Checkbox(key, label, tooltip)
			local setting = Settings.RegisterAddOnSetting(category, ns.name .. "_" .. key, key, db, Settings.VarType.Boolean, label, ns.DEFAULTS[key])
			setting:SetValueChangedCallback(OnPanelChanged(key))
			Settings.CreateCheckbox(category, setting, tooltip)
		end
		local function Slider(key, label, tooltip, minValue, maxValue, step, fmt)
			local setting = Settings.RegisterAddOnSetting(category, ns.name .. "_" .. key, key, db, Settings.VarType.Number, label, ns.DEFAULTS[key])
			setting:SetValueChangedCallback(OnPanelChanged(key))
			local options = Settings.CreateSliderOptions(minValue, maxValue, step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return string.format(fmt, value)
			end)
			Settings.CreateSlider(category, setting, options, tooltip)
		end
		Checkbox("includeLowLevel", L.OPT_LOW, L.OPT_LOW_HINT)
		Checkbox("omitDungeons", L.OPT_DUNGEON, L.OPT_DUNGEON_TIP)
		Checkbox("showOnMap", L.OPT_MAP, L.OPT_MAP_TIP)
		Checkbox("useTomTom", L.OPT_TOMTOM, L.OPT_TOMTOM_TIP)
		Slider("maxLevelsAbove", L.OPT_ABOVE_HINT, L.OPT_ABOVE_HINT, 0, 10, 1, "+%d")
		Slider("stepsShown", L.OPT_STEPS_HINT, L.OPT_STEPS_HINT, 1, 20, 1, "%d")
		Slider("fontSize", L.OPT_SIZE_HINT, L.OPT_SIZE_HINT, 9, 22, 1, "%d")
		Settings.RegisterAddOnCategory(category)
		ns.settingsCategory = category
	end)
	if not ok then
		ns.settingsCategory = nil
	end
end

function QuestRoute_OnAddonCompartmentClick(_, buttonName)
	ns.EnsureUI()
	if buttonName == "RightButton" then
		ns.OpenConfig()
		return
	end
	if ns.mainFrame:IsShown() then
		ns.mainFrame:Hide()
	else
		ns.mainFrame:Show()
	end
end

function QuestRoute_OnAddonCompartmentEnter(_, menuButtonFrame)
	if not GameTooltip or not menuButtonFrame then
		return
	end
	GameTooltip:SetOwner(menuButtonFrame, "ANCHOR_LEFT")
	GameTooltip:SetText(L.TITLE, C.GOLD[1], C.GOLD[2], C.GOLD[3])
	GameTooltip:AddLine(L.COMPARTMENT, 1, 1, 1, true)
	GameTooltip:Show()
end

function QuestRoute_OnAddonCompartmentLeave()
	if GameTooltip then
		GameTooltip:Hide()
	end
end
