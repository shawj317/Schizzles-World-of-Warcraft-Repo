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
	if key == "showOnMap" or key == "showTrail" or key == "trailAnimated" or key == "pinSize" or key == "trailAlpha" or key == "useTomTom" or key == "stepsShown" then
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
		local ours = variable == "pinSize" or variable == "trailAlpha" or variable == "stepsShown"
			or variable == "maxLevelsAbove" or variable == "backdropAlpha" or variable == "windowScale"
			or variable == "fontSize" or (type(name) == "string" and string.find(name, "Wayfarer_", 1, true))
		if ours then
			HideSliderInputs(self, 0)
		end
	end)
end

local function AddControl(category, layout, item)
	local db = ns.Settings()
	local tip = TomTomTip(item)
	if item.kind == "button" then
		if not CreateSettingsButtonInitializer or not layout or not layout.AddInitializer then
			return nil
		end
		local initializer = CreateSettingsButtonInitializer(item.label, item.label, function()
			ns.EnsureUI()
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
	local varType = Settings.VarType and (item.kind == "slider" and Settings.VarType.Number or item.kind == "check" and Settings.VarType.Boolean or Settings.VarType.String)
	local setting = Settings.RegisterAddOnSetting(category, "Wayfarer_" .. item.key, item.key, db, varType, item.label, ns.DEFAULTS[item.key])
	if setting and setting.SetValueChangedCallback then
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
				if item.key == "backdropAlpha" or item.key == "trailAlpha" then
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

function ns.RegisterSettings()
	if ns.settingsCategory or not Settings or not Settings.RegisterVerticalLayoutCategory then
		return
	end
	HookSliders()
	local ok = pcall(function()
		local parent, parentLayout = Settings.RegisterVerticalLayoutCategory(L.TITLE)
		local useSubs = Settings.RegisterVerticalLayoutSubcategory ~= nil
		for i = 1, #ns.SETTINGS do
			local section = ns.SETTINGS[i]
			local category, layout = parent, parentLayout
			if useSubs then
				category, layout = Settings.RegisterVerticalLayoutSubcategory(parent, section.section)
			elseif parentLayout and parentLayout.AddInitializer and CreateSettingsListSectionHeaderInitializer then
				parentLayout:AddInitializer(CreateSettingsListSectionHeaderInitializer(section.section))
			end
			for j = 1, #section.items do
				AddControl(category, layout, section.items[j])
			end
		end
		if Settings.RegisterAddOnCategory then
			Settings.RegisterAddOnCategory(parent)
		end
		ns.settingsCategory = parent
	end)
	if not ok then
		ns.settingsCategory = nil
	end
end

function ns.OpenConfig()
	ns.EnsureUI()
	if not ns.settingsCategory then
		ns.RegisterSettings()
	end
	local category = ns.settingsCategory
	local id = category and category.GetID and category:GetID()
	if Settings and Settings.OpenToCategory and id ~= nil then
		local opened = pcall(Settings.OpenToCategory, id)
		if opened then
			pcall(Settings.OpenToCategory, id)
			return
		end
	end
	if Settings and Settings.OpenToCategory then
		pcall(Settings.OpenToCategory, L.TITLE)
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
