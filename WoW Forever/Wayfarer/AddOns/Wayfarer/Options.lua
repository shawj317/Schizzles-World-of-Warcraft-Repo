local _, ns = ...

local L = ns.L

local function TomTomTip(item)
	if item.needs == "TomTom" and not ns.TomTomLoaded() then
		return "TomTom is not installed. The arrow stays off until it is."
	end
	return item.tip
end

local function ApplyKey(key)
	local db = ns.Settings()
	if key == "font" then
		db.font = tonumber(db.font) or 1
	end
	if key == "showBorder" or key == "theme" or key == "backdropAlpha" or key == "windowScale" or key == "font" or key == "fontSize" then
		if ns.ApplyAppearance then
			ns.ApplyAppearance()
		end
		return
	end
	if key == "hideInBattleground" or key == "hideInInstance" or key == "showOnLogin" then
		if ns.ApplyPlaceRules then
			ns.ApplyPlaceRules("zone")
		end
		return
	end
	if key == "showOnMap" or key == "pinSize" or key == "useTomTom" or key == "stepsShown" then
		if key == "useTomTom" and ns.InvalidateRoute then
			ns.InvalidateRoute()
		end
		if ns.Redisplay then
			ns.Redisplay()
		end
		return
	end
	if ns.mainFrame and ns.mainFrame:IsShown() and ns.Refresh then
		ns.Refresh(false)
	end
end

local function OnChanged(key)
	return function()
		ApplyKey(key)
	end
end

local function HideSliderInputs(root, depth)
	if not root or not root.GetChildren or (depth or 0) > 4 then
		return
	end
	local children = { root:GetChildren() }
	for i = 1, #children do
		local child = children[i]
		local kind = child.GetObjectType and child:GetObjectType()
		if kind == "EditBox" then
			child:Hide()
			child:ClearAllPoints()
			child:SetSize(1, 1)
			if child.EnableMouse then
				child:EnableMouse(false)
			end
		else
			HideSliderInputs(child, (depth or 0) + 1)
		end
	end
end

local sliderHooked = false
local function HookSliders()
	if sliderHooked or type(SettingsSliderMixin) ~= "table" or type(SettingsSliderMixin.Init) ~= "function" or not hooksecurefunc then
		return
	end
	sliderHooked = true
	hooksecurefunc(SettingsSliderMixin, "Init", function(self)
		local data = self.GetElementData and self:GetElementData()
		local setting = data and data.GetSetting and data:GetSetting()
		local variable = setting and (setting.variable or (setting.GetVariable and setting:GetVariable()))
		local name = setting and (setting.GetName and setting:GetName())
		local ours = variable == "pinSize" or variable == "stepsShown"
			or variable == "maxLevelsAbove" or variable == "backdropAlpha" or variable == "windowScale"
			or variable == "fontSize" or (type(name) == "string" and string.find(name, "Wayfarer_", 1, true))
		if ours then
			HideSliderInputs(self, 0)
		end
	end)
end

-- 16001: RegisterAddOnSetting(category, variable, variableKey, variableTbl, variableType, name, default).
-- Older clients: RegisterAddOnSetting(category, name, variable, type, default).
function ns.SettingsForm()
	if ns.settingsForm then
		return ns.settingsForm
	end
	if Settings and Settings.GetSetting then
		ns.settingsForm = "modern"
	else
		ns.settingsForm = "legacy"
	end
	return ns.settingsForm
end

function ns.NoteSettingsError(err)
	ns.settingsErrors = ns.settingsErrors or {}
	ns.settingsErrors[#ns.settingsErrors + 1] = tostring(err)
end

function ns.ChoiceValueType(item)
	local sample = item.choices and item.choices[1] and item.choices[1][1]
	if type(sample) == "number" then
		return "number"
	end
	return "string"
end

function ns.FitSettingValue(item, value)
	if item.kind == "check" then
		if value == nil then
			value = ns.DEFAULTS[item.key]
		end
		return value and true or false
	end
	if item.kind == "slider" then
		local n = tonumber(value)
		if n == nil then
			n = tonumber(ns.DEFAULTS[item.key]) or item.min or 0
		end
		return n
	end
	if item.kind == "menu" then
		if ns.ChoiceValueType(item) == "number" then
			local n = tonumber(value)
			if n == nil then
				n = tonumber(ns.DEFAULTS[item.key]) or item.choices[1][1]
			end
			return n
		end
		if value == nil then
			value = ns.DEFAULTS[item.key] or item.choices[1][1]
		end
		return tostring(value)
	end
	return value
end

function ns.VarTypeFor(item)
	if not Settings or not Settings.VarType then
		return nil
	end
	if item.kind == "check" then
		return Settings.VarType.Boolean
	end
	if item.kind == "slider" then
		return Settings.VarType.Number
	end
	if ns.ChoiceValueType(item) == "number" then
		return Settings.VarType.Number
	end
	return Settings.VarType.String
end

function ns.LookupSetting(variable, key)
	local handle = ns.settingHandles and ns.settingHandles[variable]
	if type(handle) == "table" then
		return handle
	end
	if not Settings or not Settings.GetSetting then
		return nil
	end
	local ok, found = pcall(Settings.GetSetting, variable)
	if ok and type(found) == "table" then
		return found
	end
	if key and key ~= variable then
		ok, found = pcall(Settings.GetSetting, key)
		if ok and type(found) == "table" then
			return found
		end
	end
	return nil
end

local function RememberSetting(variable, setting)
	if type(setting) ~= "table" then
		return nil
	end
	ns.settingHandles = ns.settingHandles or {}
	ns.settingHandles[variable] = setting
	return setting
end

local function RegisterAddonSetting(category, variable, key, db, varType, label, default)
	if type(db) ~= "table" then
		error("variableTbl must be a table")
	end
	local existing = ns.LookupSetting(variable, key)
	if existing then
		return existing
	end
	local setting
	if ns.SettingsForm() == "modern" then
		setting = Settings.RegisterAddOnSetting(category, variable, key, db, varType, label, default)
	else
		setting = Settings.RegisterAddOnSetting(category, label, key, varType, default)
	end
	if type(setting) ~= "table" then
		error("RegisterAddOnSetting did not return a setting")
	end
	return RememberSetting(variable, setting)
end

local function AddControl(category, layout, item, db)
	local tip = TomTomTip(item)
	if item.kind == "button" then
		if not CreateSettingsButtonInitializer or not layout or not layout.AddInitializer then
			return nil
		end
		local initializer = CreateSettingsButtonInitializer(item.label, item.label, function()
			if ns.EnsureUI then
				ns.EnsureUI()
			end
			if ns.mainFrame then
				ns.mainFrame:Show()
				ns.Refresh(true)
			end
		end, tip)
		layout:AddInitializer(initializer)
		return initializer
	end
	if not Settings or not Settings.RegisterAddOnSetting then
		return nil
	end
	local value = ns.FitSettingValue(item, db[item.key])
	db[item.key] = value
	local setting = RegisterAddonSetting(category, "Wayfarer_" .. item.key, item.key, db, ns.VarTypeFor(item), item.label, value)
	if type(setting) ~= "table" then
		return nil
	end
	if setting.SetValueChangedCallback then
		setting:SetValueChangedCallback(OnChanged(item.key))
	end
	local initializer
	if item.kind == "check" and Settings.CreateCheckbox then
		initializer = Settings.CreateCheckbox(category, setting, tip)
		if item.needs == "TomTom" and not ns.TomTomLoaded() and initializer then
			function initializer:IsEnabled()
				return false
			end
		end
	elseif item.kind == "slider" and Settings.CreateSlider and Settings.CreateSliderOptions then
		local options = Settings.CreateSliderOptions(item.min, item.max, item.step)
		if options and options.SetLabelFormatter and MinimalSliderWithSteppersMixin and MinimalSliderWithSteppersMixin.Label then
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				if item.key == "backdropAlpha" then
					return string.format("%d%%", math.floor((tonumber(value) or 0) * 100 + 0.5))
				end
				if item.key == "windowScale" then
					return string.format("%.2f", tonumber(value) or 1)
				end
				return tostring(math.floor((tonumber(value) or 0) + 0.5))
			end)
		end
		initializer = Settings.CreateSlider(category, setting, options, tip)
	elseif item.kind == "menu" and Settings.CreateDropdown and Settings.CreateControlTextContainer then
		local function options()
			local container = Settings.CreateControlTextContainer()
			for i = 1, #item.choices do
				container:Add(item.choices[i][1], item.choices[i][2])
			end
			return container:GetData()
		end
		initializer = Settings.CreateDropdown(category, setting, options, tip)
	end
	return initializer
end

local function AddSectionControls(category, layout, section, db)
	for j = 1, #section.items do
		local item = section.items[j]
		local ok, err = pcall(AddControl, category, layout, item, db)
		if not ok then
			ns.NoteSettingsError((item.key or item.label or "control") .. ": " .. tostring(err))
		end
	end
end

local function AddHeader(layout, title)
	if layout and layout.AddInitializer and CreateSettingsListSectionHeaderInitializer then
		pcall(layout.AddInitializer, layout, CreateSettingsListSectionHeaderInitializer(title))
	end
end

local function FillVertical(parent, parentLayout, db)
	ns.settingsPageIDs = {}
	local subsWork = Settings.RegisterVerticalLayoutSubcategory ~= nil
	for i = 1, #ns.SETTINGS do
		local section = ns.SETTINGS[i]
		local category, layout = parent, parentLayout
		local usedSub = false
		if subsWork then
			local ok, sub, subLayout = pcall(Settings.RegisterVerticalLayoutSubcategory, parent, section.section)
			if ok and type(sub) == "table" then
				category = sub
				layout = subLayout or parentLayout
				usedSub = true
				if sub.GetID then
					local idOk, id = pcall(sub.GetID, sub)
					if idOk then
						ns.settingsPageIDs[section.section] = id
					end
				end
			else
				subsWork = false
				ns.NoteSettingsError("subcategory " .. section.section .. ": " .. tostring(sub))
			end
		end
		if not usedSub then
			AddHeader(parentLayout, section.section)
			category, layout = parent, parentLayout
		end
		AddSectionControls(category, layout, section, db)
	end
end

local function CanvasRow(parent, item, db, y)
	local value = ns.FitSettingValue(item, db[item.key])
	if item.key then
		db[item.key] = value
	end
	if item.kind == "check" then
		local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
		check:SetPoint("TOPLEFT", 16, y)
		if check.SetChecked then
			check:SetChecked(value)
		end
		local text = check.Text or parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		if not check.Text then
			text:SetPoint("LEFT", check, "RIGHT", 4, 0)
		end
		text:SetText(item.label)
		check:SetScript("OnClick", function(self)
			db[item.key] = self:GetChecked() and true or false
			ApplyKey(item.key)
		end)
		return y - 28
	end
	if item.kind == "slider" then
		local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		label:SetPoint("TOPLEFT", 16, y)
		label:SetText(item.label)
		local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
		slider:SetPoint("TOPLEFT", 180, y)
		slider:SetWidth(180)
		slider:SetMinMaxValues(item.min, item.max)
		slider:SetValueStep(item.step)
		if slider.SetObeyStepOnDrag then
			slider:SetObeyStepOnDrag(true)
		end
		slider:SetValue(value)
		slider:SetScript("OnValueChanged", function(_, newValue)
			db[item.key] = newValue
			ApplyKey(item.key)
		end)
		return y - 32
	end
	if item.kind == "menu" then
		local index = 1
		for i = 1, #item.choices do
			if item.choices[i][1] == value then
				index = i
			end
		end
		local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
		button:SetPoint("TOPLEFT", 16, y)
		button:SetSize(220, 22)
		button:SetText(item.label .. ": " .. item.choices[index][2])
		button:SetScript("OnClick", function(self)
			index = index % #item.choices + 1
			db[item.key] = item.choices[index][1]
			self:SetText(item.label .. ": " .. item.choices[index][2])
			ApplyKey(item.key)
		end)
		return y - 28
	end
	if item.kind == "button" then
		local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
		button:SetPoint("TOPLEFT", 16, y)
		button:SetSize(140, 22)
		button:SetText(item.label)
		button:SetScript("OnClick", function()
			if ns.EnsureUI then
				ns.EnsureUI()
			end
			if ns.mainFrame then
				ns.mainFrame:Show()
				ns.Refresh(true)
			end
		end)
		return y - 28
	end
	return y
end

local function TryCanvas(db)
	if not Settings.RegisterCanvasLayoutCategory or not CreateFrame then
		ns.NoteSettingsError("canvas layout is unavailable")
		return false
	end
	local ok, err = pcall(function()
		local frame = CreateFrame("Frame", "WayfarerSettingsCanvas", nil)
		frame:SetSize(520, 40)
		local y = -12
		for i = 1, #ns.SETTINGS do
			local section = ns.SETTINGS[i]
			local header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			header:SetPoint("TOPLEFT", 16, y)
			header:SetText(section.section)
			y = y - 24
			for j = 1, #section.items do
				local rowOk, rowY = pcall(CanvasRow, frame, section.items[j], db, y)
				if rowOk then
					y = rowY
				else
					ns.NoteSettingsError((section.items[j].key or "row") .. ": " .. tostring(rowY))
				end
			end
			y = y - 8
		end
		frame:SetHeight(math.abs(y) + 24)
		local category = Settings.RegisterCanvasLayoutCategory(frame, L.TITLE)
		if Settings.RegisterAddOnCategory then
			Settings.RegisterAddOnCategory(category)
		end
		local id = category.GetID and category:GetID()
		if not id then
			error("canvas category has no id")
		end
		ns.settingsCategory = category
		ns.settingsCategoryID = id
		ns.settingsRegistered = true
		ns.settingsLayout = "canvas"
	end)
	if not ok then
		ns.NoteSettingsError("canvas: " .. tostring(err))
		return false
	end
	return true
end

local function TryVertical(db)
	if not Settings.RegisterVerticalLayoutCategory then
		return false
	end
	local parent, parentLayout
	local created, createErr = pcall(function()
		parent, parentLayout = Settings.RegisterVerticalLayoutCategory(L.TITLE)
	end)
	if not created or type(parent) ~= "table" then
		ns.NoteSettingsError("vertical category: " .. tostring(createErr))
		return false
	end
	if Settings.RegisterAddOnCategory then
		local listed, listErr = pcall(Settings.RegisterAddOnCategory, parent)
		if not listed then
			ns.NoteSettingsError("RegisterAddOnCategory: " .. tostring(listErr))
		end
	end
	local id
	if parent.GetID then
		local idOk, idValue = pcall(parent.GetID, parent)
		if idOk then
			id = idValue
		end
	end
	if id == nil then
		ns.NoteSettingsError("vertical category has no id")
		return false
	end
	ns.settingsCategory = parent
	ns.settingsCategoryID = id
	ns.settingsRegistered = true
	ns.settingsLayout = "vertical"
	local filled, fillErr = pcall(FillVertical, parent, parentLayout, db)
	if not filled then
		ns.NoteSettingsError("controls: " .. tostring(fillErr))
	end
	return true
end

function ns.RegisterSettings()
	if ns.settingsCategoryID ~= nil then
		return
	end
	if not Settings then
		ns.NoteSettingsError("Settings API is missing")
		return
	end
	local db = ns.Settings and ns.Settings()
	if type(db) ~= "table" then
		ns.NoteSettingsError("WayfarerDB is not ready")
		return
	end
	pcall(HookSliders)
	if not TryVertical(db) then
		TryCanvas(db)
	end
end

function ns.PrintSettingsReport()
	local function say(text)
		if ns.Print then
			ns:Print(text)
		else
			print(text)
		end
	end
	say("Settings category id: " .. tostring(ns.settingsCategoryID) .. " layout: " .. tostring(ns.settingsLayout))
	local caps = {}
	local function flag(name, present)
		caps[#caps + 1] = name .. "=" .. (present and "yes" or "no")
	end
	flag("Settings", Settings ~= nil)
	flag("Vertical", Settings and Settings.RegisterVerticalLayoutCategory ~= nil)
	flag("Subcategory", Settings and Settings.RegisterVerticalLayoutSubcategory ~= nil)
	flag("Canvas", Settings and Settings.RegisterCanvasLayoutCategory ~= nil)
	flag("GetSetting", Settings and Settings.GetSetting ~= nil)
	flag("Checkbox", Settings and Settings.CreateCheckbox ~= nil)
	flag("Slider", Settings and Settings.CreateSlider ~= nil)
	flag("Dropdown", Settings and Settings.CreateDropdown ~= nil)
	flag("Button", CreateSettingsButtonInitializer ~= nil)
	flag("VarType", Settings and Settings.VarType ~= nil)
	say(table.concat(caps, " "))
	local errors = ns.settingsErrors or {}
	if #errors == 0 then
		say("No settings registration errors.")
		return
	end
	say(#errors .. " settings registration errors:")
	for i = 1, #errors do
		say(errors[i])
	end
end

function ns.OpenConfig()
	if ns.EnsureUI then
		ns.EnsureUI()
	end
	if ns.settingsCategoryID == nil and ns.RegisterSettings then
		ns.RegisterSettings()
	end
	local id = ns.settingsCategoryID
	if Settings and Settings.OpenToCategory and id ~= nil then
		pcall(Settings.OpenToCategory, id)
		return
	end
	if ns.Print then
		ns:Print("Wayfarer settings are not in the AddOns list. /wayfarer debugsettings prints why.")
	end
	if ns.PrintSettingsReport then
		ns.PrintSettingsReport()
	end
end

function Wayfarer_OnAddonCompartmentClick()
	ns.OpenConfig()
end

function Wayfarer_OnAddonCompartmentEnter(_, menuButtonFrame)
	if not GameTooltip or not menuButtonFrame then
		return
	end
	GameTooltip:SetOwner(menuButtonFrame, "ANCHOR_LEFT")
	GameTooltip:SetText(L.TITLE, 1, 0.82, 0)
	GameTooltip:AddLine(L.COMPARTMENT, 1, 1, 1, true)
	GameTooltip:Show()
end

function Wayfarer_OnAddonCompartmentLeave()
	if GameTooltip then
		GameTooltip:Hide()
	end
end
