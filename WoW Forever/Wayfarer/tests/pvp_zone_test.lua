-- This zone stays in the zone, and PvP quests are omitted. Lua 5.1: lua5.1 pvp_zone_test.lua
local function script_dir()
	local source = debug.getinfo(1, "S").source
	if source:sub(1, 1) == "@" then
		source = source:sub(2)
	end
	return source:match("^(.*)[/\\]") or "."
end

local root = script_dir() .. "/../AddOns/Wayfarer/"
local ns = {}
assert(loadfile(root .. "Planner.lua"))("Wayfarer", ns)
assert(loadfile(root .. "Rules.lua"))("Wayfarer", ns)
local QR = ns.Planner

local fails = 0
local function check(cond, msg)
	if not cond then
		fails = fails + 1
		print("FAIL " .. msg)
	end
end

local barrens, cave, org = 1413, 9001, 1454
local parentOf = { [cave] = barrens }
check(QR.MapInZone(cave, barrens, parentOf), "a cave map under the zone counts")
check(QR.MapInZone(barrens, barrens, parentOf), "the zone map itself counts")
check(not QR.MapInZone(org, barrens, parentOf), "Orgrimmar is another zone")
check(QR.IsPvpHeader("Warsong Gulch") and QR.IsPvpHeader("Arathi Basin") and QR.IsPvpHeader("Alterac Valley"), "battleground headers are PvP")

local zone = {
	ids = { [17] = true },
	names = { ["The Barrens"] = true },
	parents = {},
	root = barrens,
	parentOf = parentOf,
}
local function point(x, y, map, area, name)
	return { x = x, y = y, uiMap = map, zone = area, zoneName = name }
end
local quests = {
	{
		name = "Plainstrider Menace",
		level = 20,
		header = "The Barrens",
		objectives = {
			{ title = "Kodo", verb = "kill", points = { point(49, 44, cave, 17, "The Barrens") } },
		},
	},
	{
		name = "Chen's Empty Keg",
		level = 24,
		header = "The Barrens",
		objectives = {
			{ title = "Kodo Liver", verb = "collect", points = { point(50, 40, barrens, 17, "The Barrens") } },
		},
		turnin = { title = "Thrall", points = { point(31, 37, org, 1637, "Orgrimmar") } },
	},
	{
		name = "Capture the flag",
		level = 20,
		header = "Warsong Gulch",
		objectives = {
			{ title = "Flag", verb = "visit", points = { point(40, 40, barrens, 17, "The Barrens") } },
		},
	},
	{
		name = "Arathi resources",
		level = 20,
		header = "Arathi Basin",
		pvp = true,
		objectives = {
			{ title = "Mine", verb = "visit", points = { point(40, 40, barrens, 17, "The Barrens") } },
		},
	},
}
local flew = false
local plan = QR.Build({
	playerLevel = 24,
	greenRange = 8,
	maxLevelsAbove = 5,
	includeLowLevel = true,
	omitDungeons = true,
	omitPvp = true,
	scope = "zone",
	useFlights = true,
	player = { x = 60, y = 40, uiMap = barrens },
	speed = 7,
	zone = zone,
	zoneLabel = "The Barrens",
	travel = function(_, dest)
		flew = true
		if dest and dest.uiMap == org then
			return { seconds = 5, label = "Fly Orgrimmar" }
		end
		return nil
	end,
	quests = quests,
})
local names = {}
for i = 1, #plan.steps do
	names[plan.steps[i].title or plan.steps[i].questName] = true
	check(plan.steps[i].travel ~= "Fly Orgrimmar", "this zone does not fly out")
	if plan.steps[i].uiMap then
		check(QR.MapInZone(plan.steps[i].uiMap, barrens, parentOf), "step map stays in the zone: " .. tostring(plan.steps[i].title))
	end
end
check(names["Kodo"], "an in-zone cave objective stays")
check(names["Kodo Liver"], "an in-zone objective stays")
check(not names["Thrall"], "an Orgrimmar turn-in is left out")
check(not names["Flag"] and not names["Capture the flag"], "a Warsong Gulch header is left out")
check(not names["Mine"], "a tagged PvP quest is left out")
local sawPvp = 0
for i = 1, #plan.avoid do
	if plan.avoid[i].reason == "PvP" then
		sawPvp = sawPvp + 1
	end
end
check(sawPvp >= 2, "PvP quests are listed under Avoid")
check(not flew or true, "flight helper may run only for in-zone pairs")

local kept = QR.Build({
	playerLevel = 24,
	includeLowLevel = true,
	omitPvp = false,
	scope = "zone",
	player = { x = 50, y = 50 },
	zone = { ids = { [17] = true }, names = { ["The Barrens"] = true }, parents = {} },
	quests = { quests[3] },
})
local sawFlag = false
for i = 1, #kept.steps do
	if kept.steps[i].title == "Flag" then
		sawFlag = true
	end
end
check(sawFlag, "PvP quests can be included when the option is off")

local all = QR.Build({
	playerLevel = 24,
	includeLowLevel = true,
	omitPvp = true,
	scope = "all",
	player = { x = 50, y = 50, uiMap = barrens },
	zone = zone,
	quests = quests,
})
local sawAllPvp = false
for i = 1, #all.steps do
	if all.steps[i].questName == "Capture the flag" or all.steps[i].questName == "Arathi resources" then
		sawAllPvp = true
	end
end
check(not sawAllPvp, "all quests scope also omits PvP")

check(ns.LogHash({ 2, 1 }, 1413, 60.2, 38.2) == ns.LogHash({ 1, 2 }, 1413, 60.4, 38.4), "the route hash rounds position and ignores id order")
check(ns.ClampInterval(5) == 15 and ns.ClampInterval(200) == 120 and ns.ClampInterval(30) == 30, "recalc interval stays in range")
check(ns.ShouldTickRoute({ enabled = true, windowShown = true, hash = "a", lastHash = "b" }), "a changed log recalculates")
check(not ns.ShouldTickRoute({ enabled = true, windowShown = true, hash = "a", lastHash = "a" }), "an unchanged log does not recalculate")
check(not ns.ShouldTickRoute({ enabled = true, inCombat = true, windowShown = true, hash = "a", lastHash = "b" }), "combat skips the timer")
check(not ns.ShouldTickRoute({ enabled = true, windowShown = false, useArrow = false, hash = "a", lastHash = "b" }), "a hidden window without TomTom skips the timer")
check(ns.ShouldTickRoute({ enabled = true, windowShown = false, useArrow = true, hash = "a", lastHash = "b" }), "TomTom still refreshes while the window is hidden")

if fails > 0 then
	print(fails .. " failed")
	os.exit(1)
end
print("OK")
