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
	local calls = { n = 0, opened = 0, args = nil }
	local Settings = {
		VarType = { Boolean = "bool", Number = "num", String = "str" },
	}
	function Settings.RegisterVerticalLayoutCategory(name)
		local cat = { name = name, id = 42 }
		function cat:GetID()
			return self.id
		end
		return cat, { AddInitializer = function() end }
	end
	function Settings.RegisterVerticalLayoutSubcategory(parent, name)
		local cat = { name = name, id = 100 + (calls.subs or 0) }
		calls.subs = (calls.subs or 0) + 1
		function cat:GetID()
			return self.id
		end
		return cat, { AddInitializer = function() end }
	end
	function Settings.GetSetting(variable)
		return registered[variable]
	end
	function Settings.RegisterAddOnSetting(...)
		local category, variable, key, db, varType, name, default = ...
		calls.n = calls.n + 1
		if not calls.args then
			calls.args = { category, variable, key, db, varType, name, default }
			calls.nparams = select("#", ...)
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
		calls.opened = calls.opened + 1
		calls.lastId = id
	end
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
check(calls.opened == 3, "each open only shows the category")
check(#ns.printed == 0, "a clean register stays quiet")

local nsFail = {}
loadInto(nsFail)
local SettingsFail, callsFail = modernSettings()
local realRegister = SettingsFail.RegisterAddOnSetting
SettingsFail.RegisterAddOnSetting = function(...)
	if callsFail.n >= 1 then
		error("Setting variable 'Wayfarer_showOnLogin' was previously registered.")
	end
	return realRegister(...)
end
_G.Settings = SettingsFail
nsFail.RegisterSettings()
local failedAt = callsFail.n
nsFail.OpenConfig()
nsFail.OpenConfig()
nsFail.OpenConfig()
nsFail.RegisterSettings()
check(callsFail.n == failedAt, "a failed register is not attempted again from the cog")
check(#nsFail.printed == 1, "the registration error is printed once")
check(string.find(nsFail.printed[1], "previously registered", 1, true) ~= nil, "the chat line includes the Blizzard error")

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

_G.Settings = nil

if fails > 0 then
	print(fails .. " failed")
	os.exit(1)
end
print("OK")
