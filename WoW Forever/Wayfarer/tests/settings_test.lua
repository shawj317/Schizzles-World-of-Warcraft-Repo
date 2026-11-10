-- Blizzard settings catalog, hide rules, and escape. Lua 5.1: lua5.1 settings_test.lua
local function script_dir()
	local source = debug.getinfo(1, "S").source
	if source:sub(1, 1) == "@" then
		source = source:sub(2)
	end
	return source:match("^(.*)[/\\]") or "."
end

local root = script_dir() .. "/../AddOns/Wayfarer/"
local ns = {}
assert(loadfile(root .. "Rules.lua"))("Wayfarer", ns)

local fails = 0
local function check(cond, msg)
	if not cond then
		fails = fails + 1
		print("FAIL " .. msg)
	end
end

check(#ns.SETTINGS == 3, "three sections")
check(ns.SETTINGS[1].section == "General" and ns.SETTINGS[2].section == "Map" and ns.SETTINGS[3].section == "Appearance", "section order")

local seen = {}
for s = 1, #ns.SETTINGS do
	local items = ns.SETTINGS[s].items
	check(#items > 0, ns.SETTINGS[s].section .. " has rows")
	for i = 1, #items do
		local item = items[i]
		check(item.label and string.len(item.label) <= 24, "short label " .. tostring(item.label))
		check(item.tip and string.len(item.tip) > 10, "tooltip " .. tostring(item.label))
		if item.key then
			seen[item.key] = true
		end
	end
end
check(seen.rememberWindow and seen.showOnLogin and seen.hideInBattleground and seen.hideInInstance and seen.recalc, "general rows")
check(seen.useTomTom and seen.pinSize and seen.scope and not seen.showTrail and not seen.trailAnimated and not seen.trailAlpha, "map rows keep pins and omit the trail")
check(seen.theme and seen.showBorder and seen.backdropAlpha and seen.windowScale, "appearance rows")

local tomtom
for i = 1, #ns.SETTINGS[2].items do
	if ns.SETTINGS[2].items[i].key == "useTomTom" then
		tomtom = ns.SETTINGS[2].items[i]
	end
end
check(tomtom and tomtom.needs == "TomTom", "tomtom row knows it needs the addon")

check(ns.HideKind("pvp", { hideInBattleground = true }) == "battleground", "battleground hides")
check(ns.HideKind("arena", { hideInBattleground = true }) == "battleground", "arena hides")
check(ns.HideKind("party", { hideInInstance = true }) == "instance", "dungeon hides")
check(ns.HideKind("raid", { hideInInstance = true }) == "instance", "raid hides")
check(ns.HideKind("none", { hideInBattleground = true, hideInInstance = true }) == nil, "the open world stays")
check(ns.HideKind("party", { hideInInstance = false }) == nil, "instance hide can be off")

local frames = {}
check(not ns.ListedForEscape(frames), "a fresh list does not close on escape")
frames[1] = "WayfarerFrame"
check(ns.ListedForEscape(frames), "the detector sees the main frame name")

local function sourceHas(name)
	local handle = assert(io.open(root .. name, "r"))
	local text = handle:read("*a")
	handle:close()
	return text
end
local ui = sourceHas("UI.lua")
local options = sourceHas("Options.lua")
check(not string.find(ui, "UISpecialFrames", 1, true), "the route window is not registered for escape")
check(string.find(ui, 'SetFrameStrata("MEDIUM")', 1, true) ~= nil, "the route window uses medium strata")
check(not string.find(ui, 'SetFrameStrata("HIGH")', 1, true), "the route window is not high strata")
check(not string.find(ui, "SetToplevel(true)", 1, true), "the route window is not top level")
check(not string.find(ui, ":Raise()", 1, true), "the route window does not raise itself")
check(not string.find(options, "UISpecialFrames", 1, true), "there is no options window on the escape list")
check(string.find(options, "OpenToCategory", 1, true) ~= nil, "settings open the blizzard panel")
check(not string.find(options, "function ns.BuildConfig", 1, true), "the addon options window is gone")

if fails > 0 then
	print(fails .. " failed")
	os.exit(1)
end
print("OK")
