-- Loads every addon file in TOC order under stubs and fails if a new global appears.
-- Run with Lua 5.1: lua5.1 load_test.lua
local function script_dir()
	local source = debug.getinfo(1, "S").source
	if source:sub(1, 1) == "@" then
		source = source:sub(2)
	end
	return source:match("^(.*)[/\\]") or "."
end

local root = script_dir() .. "/../AddOns/Wayfarer/"

local any
any = setmetatable({}, {
	__index = function()
		return any
	end,
	__call = function()
		return nil
	end,
	__concat = function(left, right)
		return tostring(left) .. tostring(right)
	end,
	__tostring = function()
		return ""
	end,
})

local function frame()
	return setmetatable({}, {
		__index = function()
			return function()
				return nil
			end
		end,
	})
end

function CreateFrame()
	return frame()
end

local allowed = {
	SLASH_WAYFARER1 = true,
	SLASH_WAYFARER2 = true,
	SLASH_WAYFARER3 = true,
	SLASH_WAYFARER4 = true,
	Wayfarer_OnAddonCompartmentClick = true,
	Wayfarer_OnAddonCompartmentEnter = true,
	Wayfarer_OnAddonCompartmentLeave = true,
}

local leaks = {}
setmetatable(_G, {
	__index = function(_, key)
		return any
	end,
	__newindex = function(table, key, value)
		if not allowed[key] then
			leaks[#leaks + 1] = key
		end
		rawset(table, key, value)
	end,
})

local ns = {}
local order = {
	"Locales/enUS.lua",
	"Secrets.lua",
	"Detect.lua",
	"Theme.lua",
	"Skip.lua",
	"Planner.lua",
	"Travel.lua",
	"FlightData.lua",
	"Saved.lua",
	"Rules.lua",
	"Core.lua",
	"QuestLog.lua",
	"Waypoints.lua",
	"MapPins.lua",
	"Widgets.lua",
	"UI.lua",
	"Options.lua",
	"Slash.lua",
}

for i = 1, #order do
	local path = root .. order[i]
	local chunk, err = loadfile(path)
	if not chunk then
		print("LOAD FAIL " .. path .. " " .. tostring(err))
		os.exit(1)
	end
	local ok, runErr = pcall(chunk, "QuestRoute", ns)
	if not ok then
		print("RUN FAIL " .. order[i] .. " " .. tostring(runErr))
		os.exit(1)
	end
end

if #leaks > 0 then
	print("GLOBAL LEAKS " .. table.concat(leaks, ", "))
	os.exit(1)
end

if type(ns.Planner.Build) ~= "function" then
	print("planner missing")
	os.exit(1)
end
if type(ns.ScanQuests) ~= "function" or type(ns.Refresh) ~= "function" then
	print("client entry points missing")
	os.exit(1)
end
if SlashCmdList == nil then
	print("slash list missing")
	os.exit(1)
end

print("OK")
