-- Saved-variable compatibility. Run with Lua 5.1:
--   lua5.1 saved_test.lua
local function script_dir()
	local source = debug.getinfo(1, "S").source
	if source:sub(1, 1) == "@" then
		source = source:sub(2)
	end
	return source:match("^(.*)[/\\]") or "."
end

local root = script_dir() .. "/../AddOns/QuestRoute/"
local ns = {}

local function load(name)
	local chunk = assert(loadfile(root .. name))
	chunk("QuestRoute", ns)
end

load("Planner.lua")
load("Saved.lua")

local fails = 0
local function check(cond, msg)
	if not cond then
		fails = fails + 1
		print("FAIL " .. msg)
	end
end

local legacy = {
	includeLowLevel = true,
	omitDungeons = false,
	showOnMap = false,
	useTomTom = false,
	maxLevelsAbove = 5,
	stepsShown = 12,
	font = 3,
	fontSize = 16,
	point = { "TOPRIGHT", "TOPRIGHT", -40, -160 },
	configPoint = { "CENTER", "CENTER", 40, 40 },
	userSized = true,
	width = 400,
	height = 320,
}
local kept = ns.HealSettings(ns.PrepareDB(legacy))
check(kept.schema == 1, "legacy file is schema 1")
check(kept.includeLowLevel == true, "include low level stays")
check(kept.omitDungeons == false, "omit dungeons stays off")
check(kept.showOnMap == false, "map pins stay off")
check(kept.useTomTom == false, "tomtom stays off")
check(kept.maxLevelsAbove == 5, "levels above stays")
check(kept.stepsShown == 12, "steps stay")
check(kept.font == 3, "font index stays")
check(kept.fontSize == 16, "font size stays")
check(kept.point[1] == "TOPRIGHT" and kept.width == 400 and kept.userSized == true, "window position stays")
check(kept.configPoint[3] == 40, "options position stays")

local broken = ns.HealSettings(ns.PrepareDB({
	font = 99,
	fontSize = 100,
	stepsShown = -1,
	maxLevelsAbove = 50,
}))
check(broken.font == 1, "font index is clamped")
check(broken.fontSize == 22, "font size is clamped")
check(broken.stepsShown == 1, "steps are clamped")
check(broken.maxLevelsAbove == 15, "levels above are clamped")
check(broken.includeLowLevel == false, "missing low-level default")
check(broken.omitDungeons == true, "missing dungeon default")

local fresh = ns.HealSettings(ns.PrepareDB({}))
check(fresh.schema == 1, "new file is schema 1")
check(fresh.stepsShown == 7 and fresh.maxLevelsAbove == 3 and fresh.font == 1, "1.0.5 defaults")

local newer = ns.PrepareDB({ schema = 5, stepsShown = 4, future = true })
check(newer.schema == 5, "a newer schema is not downgraded")
check(newer.future == true, "unknown keys stay")
check(newer.includeLowLevel == false, "missing keys are filled")

if fails > 0 then
	print(fails .. " failed")
	os.exit(1)
end
print("OK")
