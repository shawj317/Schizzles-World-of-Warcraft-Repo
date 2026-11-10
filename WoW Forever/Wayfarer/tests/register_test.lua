-- Settings register once. A stub that errors on a duplicate variable must survive
-- three OpenConfig calls. Lua 5.1: lua5.1 register_test.lua
local function script_dir()
	local source = debug.getinfo(1, "S").source
	if source:sub(1, 1) == "@" then
		source = source:sub(2)
	end
	return source:match("^(.*)[/\\]") or "."
end

local root = script_dir() .. "/../AddOns/Wayfarer/"

local fails = 0
local function check(cond, msg)
	if not cond then
		fails = fails + 1
		print("FAIL " .. msg)
	end
end

local function loadInto(ns)
	assert(loadfile(root .. "Locales/enUS.lua"))("Wayfarer", ns)
	assert(loadfile(root .. "Rules.lua"))("Wayfarer", ns)
	assert(loadfile(root .. "Options.lua"))("Wayfarer", ns)
	ns.DEFAULTS = { rememberWindow = true, showOnLogin = false, font = 1, theme = "wayfarer", scope = "zone" }
	ns.Settings = function()
		return ns.DEFAULTS
	end
	ns.EnsureUI = function() end
	ns.printed = {}
	function ns:Print(message)
		self.printed[#self.printed + 1] = message
	end
end

local function modernSettings()
	local registered = {}
	local known = {}
	local calls = { n = 0, opened = 0, rejected = 0, args = nil }
	local Settings = {
		VarType = { Boolean = "bool", Number = "num", String = "str" },
	}
	local function expect(varType, value, what)
		if varType == Settings.VarType.Boolean and type(value) ~= "boolean" then
			error(what .. " must be boolean")
		end
		if varType == Settings.VarType.Number and type(value) ~= "number" then
			error(what .. " must be number")
		end
		if varType == Settings.VarType.String and type(value) ~= "string" then
			error(what .. " must be string")
		end
	end
	function Settings.RegisterVerticalLayoutCategory(name)
		local cat = { name = name, id = 42 }
		known[42] = true
		function cat:GetID()
			return self.id
		end
		return cat, { AddInitializer = function() end }
	end
	function Settings.RegisterVerticalLayoutSubcategory(parent, name)
		local cat = { name = name, id = 100 + (calls.subs or 0) }
		calls.subs = (calls.subs or 0) + 1
		known[cat.id] = true
		function cat:GetID()
			return self.id
		end
		return cat, { AddInitializer = function() end }
	end
	function Settings.GetSetting(variable)
		return registered[variable]
	end
	function Settings.RegisterAddOnSetting(...)
		local nparams = select("#", ...)
		local category, variable, key, db, varType, name, default
		if nparams >= 7 then
			category, variable, key, db, varType, name, default = ...
			if type(db) ~= "table" then
				error("variableTbl must be a table")
			end
			expect(varType, default, "default")
			expect(varType, db[key], "saved value")
		else
			category, name, variable, varType, default = ...
			key = variable
			expect(varType, default, "default")
		end
		calls.n = calls.n + 1
		if not calls.args then
			calls.args = { ... }
			calls.nparams = nparams
		end
		if registered[variable] then
			error("Setting variable '" .. tostring(variable) .. "' was previously registered.")
		end
		local setting = { variable = variable, key = key }
		function setting:SetValueChangedCallback() end
		registered[variable] = setting
		return setting
	end
	function Settings.CreateCheckbox()
		return {}
	end
	function Settings.CreateSlider()
		return {}
	end
	function Settings.CreateSliderOptions()
		return { SetLabelFormatter = function() end }
	end
	function Settings.CreateControlTextContainer()
		return {
			Add = function() end,
			GetData = function()
				return {}
			end,
		}
	end
	function Settings.CreateDropdown()
		return {}
	end
	function Settings.RegisterAddOnCategory() end
	function Settings.OpenToCategory(id)
		if not known[id] then
			calls.rejected = calls.rejected + 1
			return
		end
		calls.opened = calls.opened + 1
		calls.lastId = id
	end
	Settings._known = known
	return Settings, calls, registered
end

local ns = {}
loadInto(ns)
local Settings, calls = modernSettings()
_G.Settings = Settings

ns.RegisterSettings()
local once = calls.n
check(once > 1, "settings were registered")
check(calls.args[2] == "Wayfarer_rememberWindow", "16001 variable is the Wayfarer_ key")
check(calls.args[3] == "rememberWindow", "saved key stays rememberWindow")
check(calls.nparams == 7, "modern registration passes seven arguments")
ns.OpenConfig()
ns.OpenConfig()
ns.OpenConfig()
ns.RegisterSettings()
check(calls.n == once, "three opens and a second register do not register again")
check(calls.opened == 3 and calls.lastId == 42, "each open shows the Wayfarer category id")
check(calls.rejected == 0, "a known category id is accepted")
check(#ns.printed == 0, "a clean register stays quiet")
check(#(ns.settingsErrors or {}) == 0, "typed defaults all passed")
Settings.OpenToCategory(9999)
check(calls.rejected == 1 and calls.opened == 3, "an unknown category id opens nothing")

local nsFail = {}
loadInto(nsFail)
local SettingsFail, callsFail = modernSettings()
local realCheck = SettingsFail.CreateCheckbox
SettingsFail.CreateCheckbox = function(category, setting, tip)
	if type(setting) ~= "table" then
		error("CreateCheckbox received " .. type(setting))
	end
	if setting.variable == "Wayfarer_showOnLogin" then
		error("show on login control failed")
	end
	return realCheck(category, setting, tip)
end
_G.Settings = SettingsFail
nsFail.RegisterSettings()
check(nsFail.settingsCategoryID == 42, "one bad control still leaves the category")
check(callsFail.n > 2, "the other settings still register")
local noted = false
for i = 1, #(nsFail.settingsErrors or {}) do
	if string.find(nsFail.settingsErrors[i], "show on login control failed", 1, true) then
		noted = true
	end
end
check(noted, "the bad control's error is kept")
local opened = callsFail.opened
nsFail.OpenConfig()
nsFail.OpenConfig()
nsFail.OpenConfig()
check(callsFail.opened == opened + 3 and callsFail.lastId == 42, "the cog opens the category after a skipped control")
check(callsFail.rejected == 0, "the cog does not pass an unknown id")

local nsOld = {}
loadInto(nsOld)
local SettingsOld, callsOld = modernSettings()
SettingsOld.GetSetting = nil
_G.Settings = SettingsOld
nsOld.RegisterSettings()
check(callsOld.args[2] == "Remember window", "legacy registration passes the label as the name")
check(callsOld.args[3] == "rememberWindow", "legacy registration passes the saved key")
check(callsOld.nparams == 5, "legacy registration passes five arguments")
local oldCount = callsOld.n
nsOld.OpenConfig()
nsOld.OpenConfig()
nsOld.OpenConfig()
check(callsOld.n == oldCount, "legacy opens do not register again")

local nsMissing = {}
loadInto(nsMissing)
local SettingsMissing, callsMissing = modernSettings()
SettingsMissing.RegisterVerticalLayoutCategory = function()
	error("vertical layout is unusable")
end
_G.Settings = SettingsMissing
nsMissing.RegisterSettings()
check(nsMissing.settingsCategoryID == nil, "a failed layout does not invent a category id")
nsMissing.OpenConfig()
check(callsMissing.opened == 0 and callsMissing.rejected == 0, "without a category the cog does not open the Game tab")
check(#nsMissing.printed >= 1, "the cog reports the registration errors")

_G.Settings = nil

if fails > 0 then
	print(fails .. " failed")
	os.exit(1)
end
print("OK")
