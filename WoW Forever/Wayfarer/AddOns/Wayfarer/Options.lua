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
	local frame = ns.Frame("Frame", "WayfarerConfigFrame", UIParent)
	frame:SetSize(420, 1140)
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
		table.insert(UISpecialFrames, "WayfarerConfigFrame")
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
	local scopeLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	scopeLabel:SetPoint("TOPLEFT", 16, -100)
	ns.Style(scopeLabel, 12, C.MUTED, "LEFT", false)
	scopeLabel:SetText(L.OPT_SCOPE)
	local scopeZone = ns.TextButton(frame, L.SCOPE_ZONE, function()
		ns.Settings().scope = "zone"
		if ns.mainFrame and ns.mainFrame:IsShown() then
			ns.Refresh(false)
		end
		if ns.SyncConfig then
			ns.SyncConfig()
		end
	end, 150)
	scopeZone:SetPoint("TOPLEFT", 16, -118)
	local scopeAll = ns.TextButton(frame, L.SCOPE_ALL, function()
		ns.Settings().scope = "all"
		if ns.mainFrame and ns.mainFrame:IsShown() then
			ns.Refresh(false)
		end
		if ns.SyncConfig then
			ns.SyncConfig()
		end
	end, 200)
	scopeAll:SetPoint("LEFT", scopeZone, "RIGHT", 8, 0)
	local low = Check("WayfarerLowCheck", L.OPT_LOW, -156, L.OPT_LOW_HINT)
	Hint(L.OPT_LOW_HINT, -182)
	local dungeon = Check("WayfarerDungeonCheck", L.OPT_DUNGEON, -224, L.OPT_DUNGEON_TIP)
	local flights = Check("WayfarerFlightCheck", L.OPT_FLIGHTS, -252, L.OPT_FLIGHTS_TIP)
	local above = Slider("WayfarerAboveSlider", -300, 0, 10)
	Hint(L.OPT_ABOVE_HINT, -332)
	local steps = Slider("WayfarerStepsSlider", -378, 1, 20)
	Hint(L.OPT_STEPS_HINT, -410)

	Section(L.SECTION_MAP, -458)
	local mapToggle = Check("WayfarerMapCheck", L.OPT_MAP, -480, L.OPT_MAP_TIP)
	local tomtomToggle = Check("WayfarerTomTomCheck", L.OPT_TOMTOM, -508, L.OPT_TOMTOM_TIP)
	local trailToggle = Check("WayfarerTrailCheck", L.OPT_TRAIL, -536, L.OPT_TRAIL_TIP)
	local animateToggle = Check("WayfarerAnimateCheck", L.OPT_ANIMATE, -564, L.OPT_ANIMATE_TIP)
	local pinSlider = Slider("WayfarerPinSlider", -610, 14, 32)
	local alphaSlider = Slider("WayfarerAlphaSlider", -662, 15, 100)
	local colorLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	colorLabel:SetPoint("TOPLEFT", 28, -704)
	ns.Style(colorLabel, 12, C.MUTED, "LEFT", false)
	colorLabel:SetText(L.OPT_TRAIL_COLOR)
	local swatches = {}
	local colors = {
		{ 1, 0.82, 0 },
		{ 0.72, 0.45, 0.2 },
		{ 1, 0.47, 0 },
		{ 0.78, 0.61, 0.43 },
		{ 0.98, 0.96, 0.93 },
	}
	for i = 1, #colors do
		local color = colors[i]
		local swatch = CreateFrame("Button", nil, frame)
		swatch:SetSize(22, 22)
		swatch:SetPoint("TOPLEFT", 28 + (i - 1) * 28, -722)
		local plate = swatch:CreateTexture(nil, "ARTWORK")
		plate:SetAllPoints()
		plate:SetTexture("Interface\\Buttons\\WHITE8X8")
		plate:SetVertexColor(color[1], color[2], color[3], 1)
		swatch.plate = plate
		swatch:SetScript("OnClick", function()
			local db = ns.Settings()
			db.trailR, db.trailG, db.trailB = color[1], color[2], color[3]
			db.trailCustom = true
			if ns.mainFrame and ns.mainFrame.plan then
				ns.SyncRoute(ns.mainFrame.plan, nil, false)
			end
			if ns.SyncConfig then
				ns.SyncConfig()
			end
		end)
		swatches[i] = swatch
	end

	Section(L.SECTION_APPEARANCE, -760)
	local themeLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	themeLabel:SetPoint("TOPLEFT", 16, -782)
	ns.Style(themeLabel, 12, C.MUTED, "LEFT", false)
	themeLabel:SetText(L.OPT_THEME)
	local themeButtons = {}
	local themeOrder = { "wayfarer", "blizzard", "class" }
	local themeText = { wayfarer = L.THEME_WAYFARER, blizzard = L.THEME_BLIZZARD, class = L.THEME_CLASS }
	for i, id in ipairs(themeOrder) do
		local button = ns.TextButton(frame, themeText[id], function()
			ns.Settings().theme = id
			if ns.ApplyAppearance then
				ns.ApplyAppearance()
			end
			if ns.SyncConfig then
				ns.SyncConfig()
			end
		end, 100)
		button:SetPoint("TOPLEFT", 16 + (i - 1) * 108, -800)
		themeButtons[id] = button
	end
	local backdropSlider = Slider("WayfarerBackdropSlider", -848, 0, 100)
	local borderToggle = Check("WayfarerBorderCheck", L.OPT_BORDER, -890, L.OPT_BORDER_TIP)
	local clearSkips = ns.TextButton(frame, L.UNSKIP, function()
		if ns.Unskip then
			ns.Unskip()
		end
	end, 140, L.UNSKIP_TIP)
	clearSkips:SetPoint("TOPLEFT", 16, -922)

	local fontLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	fontLabel:SetPoint("TOPLEFT", 28, -958)
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
	prevFont:SetPoint("TOPLEFT", 28, -978)
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

	local size = Slider("WayfarerFontSlider", -1026, 9, 22)
	Hint(L.OPT_SIZE_HINT, -1058)

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
	BindCheck(flights, function(value)
		ns.Settings().useFlights = value
		if ns.mainFrame and ns.mainFrame:IsShown() then
			ns.Refresh(false)
		end
	end)
	BindCheck(trailToggle, function(value)
		ns.Settings().showTrail = value
		if ns.mainFrame and ns.mainFrame.plan then
			ns.SyncRoute(ns.mainFrame.plan, nil, false)
		end
	end)
	BindCheck(animateToggle, function(value)
		ns.Settings().trailAnimated = value
		if ns.mainFrame and ns.mainFrame.plan then
			ns.SyncRoute(ns.mainFrame.plan, nil, false)
		end
	end)
	pinSlider:SetScript("OnValueChanged", function(self, value)
		local rounded = math.floor((tonumber(value) or 20) + 0.5)
		if rounded < 14 then
			rounded = 14
		elseif rounded > 32 then
			rounded = 32
		end
		SliderText(self, string.format(L.OPT_PIN, rounded))
		if lock then
			return
		end
		ns.Settings().pinSize = rounded
		if ns.mainFrame and ns.mainFrame.plan then
			ns.SyncRoute(ns.mainFrame.plan, nil, false)
		end
	end)
	alphaSlider:SetScript("OnValueChanged", function(self, value)
		local rounded = math.floor((tonumber(value) or 90) + 0.5)
		if rounded < 15 then
			rounded = 15
		elseif rounded > 100 then
			rounded = 100
		end
		SliderText(self, string.format(L.OPT_ALPHA, rounded))
		if lock then
			return
		end
		ns.Settings().trailAlpha = rounded / 100
		if ns.mainFrame and ns.mainFrame.plan then
			ns.SyncRoute(ns.mainFrame.plan, nil, false)
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
		if not lock and ns.mainFrame and ns.mainFrame:IsShown() and ns.mainFrame.plan and ns.Redisplay then
			ns.Settings().stepsShown = rounded
			ns.Redisplay()
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
	backdropSlider:SetScript("OnValueChanged", function(self, value)
		local rounded = math.floor((tonumber(value) or 85) + 0.5)
		if rounded < 0 then
			rounded = 0
		elseif rounded > 100 then
			rounded = 100
		end
		SliderText(self, string.format(L.OPT_BACKDROP, rounded))
		if lock then
			return
		end
		ns.Settings().backdropAlpha = rounded / 100
		if ns.ApplyAppearance then
			ns.ApplyAppearance()
		end
	end)
	BindCheck(borderToggle, function(value)
		ns.Settings().showBorder = value
		if ns.ApplyAppearance then
			ns.ApplyAppearance()
		end
	end)

	local function Sync()
		local db = ns.Settings()
		lock = true
		Checked(low, db.includeLowLevel)
		Checked(dungeon, db.omitDungeons)
		Checked(mapToggle, db.showOnMap)
		Checked(tomtomToggle, db.useTomTom)
		Checked(flights, db.useFlights)
		Checked(trailToggle, db.showTrail)
		Checked(animateToggle, db.trailAnimated)
		Checked(borderToggle, db.showBorder ~= false)
		above:SetValue(db.maxLevelsAbove)
		steps:SetValue(db.stepsShown)
		size:SetValue(db.fontSize)
		pinSlider:SetValue(db.pinSize)
		alphaSlider:SetValue(math.floor(db.trailAlpha * 100 + 0.5))
		backdropSlider:SetValue(math.floor((db.backdropAlpha or 0.85) * 100 + 0.5))
		SliderText(above, string.format(L.OPT_ABOVE, db.maxLevelsAbove))
		SliderText(steps, string.format(L.OPT_STEPS, db.stepsShown))
		SliderText(size, string.format(L.OPT_SIZE, db.fontSize))
		SliderText(pinSlider, string.format(L.OPT_PIN, db.pinSize))
		SliderText(alphaSlider, string.format(L.OPT_ALPHA, math.floor(db.trailAlpha * 100 + 0.5)))
		SliderText(backdropSlider, string.format(L.OPT_BACKDROP, math.floor((db.backdropAlpha or 0.85) * 100 + 0.5)))
		local function paintChoice(button, on)
			local face = button.GetFontString and button:GetFontString()
			if face then
				face:SetTextColor(on and C.GOLD[1] or C.MUTED[1], on and C.GOLD[2] or C.MUTED[2], on and C.GOLD[3] or C.MUTED[3])
			end
		end
		paintChoice(scopeZone, db.scope ~= "all")
		paintChoice(scopeAll, db.scope == "all")
		for id, button in pairs(themeButtons) do
			paintChoice(button, db.theme == id)
		end
		for i = 1, #swatches do
			local color = colors[i]
			local on = math.abs(db.trailR - color[1]) < 0.02 and math.abs(db.trailG - color[2]) < 0.02 and math.abs(db.trailB - color[3]) < 0.02
			swatches[i]:SetAlpha(on and 1 or 0.45)
		end
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
	if ns.ApplyAppearance then
		ns.ApplyAppearance()
	end
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
		if key == "showBorder" then
			if ns.ApplyAppearance then
				ns.ApplyAppearance()
			end
		elseif key == "showOnMap" or key == "showTrail" or key == "trailAnimated" or key == "pinSize" or key == "trailAlpha" then
			if ns.Redisplay then
				ns.Redisplay()
			elseif ns.mainFrame and ns.mainFrame.plan then
				ns.SyncRoute(ns.mainFrame.plan, nil, false)
			end
		elseif key == "useTomTom" then
			ns.InvalidateRoute()
			if ns.Redisplay then
				ns.Redisplay()
			elseif ns.mainFrame and ns.mainFrame.plan then
				local plan = ns.mainFrame.plan
				ns.SyncRoute(plan, plan.steps and plan.steps[1], false)
			end
		elseif key == "stepsShown" then
			if ns.mainFrame and ns.mainFrame:IsShown() and ns.mainFrame.plan and ns.Redisplay then
				ns.Redisplay()
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
		Checkbox("useFlights", L.OPT_FLIGHTS, L.OPT_FLIGHTS_TIP)
		Checkbox("showTrail", L.OPT_TRAIL, L.OPT_TRAIL_TIP)
		Checkbox("trailAnimated", L.OPT_ANIMATE, L.OPT_ANIMATE_TIP)
		Checkbox("showBorder", L.OPT_BORDER, L.OPT_BORDER_TIP)
		Slider("maxLevelsAbove", L.OPT_ABOVE_HINT, L.OPT_ABOVE_HINT, 0, 10, 1, "+%d")
		Slider("stepsShown", L.OPT_STEPS_HINT, L.OPT_STEPS_HINT, 1, 20, 1, "%d")
		Slider("pinSize", L.OPT_PIN_TT, L.OPT_PIN_TT, 14, 32, 1, "%d")
		Slider("trailAlpha", L.OPT_ALPHA_TT, L.OPT_ALPHA_TT, 0.15, 1, 0.05, "%.2f")
		Slider("fontSize", L.OPT_SIZE_HINT, L.OPT_SIZE_HINT, 9, 22, 1, "%d")
		Settings.RegisterAddOnCategory(category)
		ns.settingsCategory = category
	end)
	if not ok then
		ns.settingsCategory = nil
	end
end

function Wayfarer_OnAddonCompartmentClick(_, buttonName)
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

function Wayfarer_OnAddonCompartmentEnter(_, menuButtonFrame)
	if not GameTooltip or not menuButtonFrame then
		return
	end
	GameTooltip:SetOwner(menuButtonFrame, "ANCHOR_LEFT")
	GameTooltip:SetText(L.TITLE, C.GOLD[1], C.GOLD[2], C.GOLD[3])
	GameTooltip:AddLine(L.COMPARTMENT, 1, 1, 1, true)
	GameTooltip:Show()
end

function Wayfarer_OnAddonCompartmentLeave()
	if GameTooltip then
		GameTooltip:Hide()
	end
end
