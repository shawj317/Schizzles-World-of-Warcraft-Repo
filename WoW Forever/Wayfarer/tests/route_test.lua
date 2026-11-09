-- Planner tests. Run with Lua 5.1 from this folder, or from anywhere:
--   lua5.1 route_test.lua
local function script_dir()
	local source = debug.getinfo(1, "S").source
	if source:sub(1, 1) == "@" then
		source = source:sub(2)
	end
	return source:match("^(.*)[/\\]") or "."
end

QUESTROUTE_TEST = true
local QR = dofile(script_dir() .. "/../AddOns/Wayfarer/Planner.lua")

local fails = 0
local function check(cond, msg)
	if not cond then
		fails = fails + 1
		print("FAIL " .. msg)
	end
end

check(QR.FormatXP(33000) == "33K", "format 33K")
check(QR.FormatXP(800) == "800", "format small xp")
check(QR.FormatClock(30) == "under a min", "short clock")
check(QR.FormatClock(60) == "1 min", "one minute")
check(QR.IsLowLevel(11, 20, 8) == true, "gray quest")
check(QR.IsLowLevel(12, 20, 8) == false, "still green")
check(QR.IsTooHigh(23, 20, 2) == true, "too high")
check(QR.IsTooHigh(22, 20, 2) == false, "at the cap")
check(QR.IsLowLevel(nil, 20, 8) == false, "unknown level is kept")
check(QR.EstimateXP(10, 10) == 680, "anchor xp")
check(QR.ClampSteps(0) == 1, "steps floor")
check(QR.ClampSteps(99) == 20, "steps cap")
check(QR.ClampAbove(-2) == 0, "above floor")

local spawns = QR.PointsFromSpawns({ [17] = { { 45.2, 60.5 }, { 46, 61 } } })
check(#spawns == 2, "spawn count")
check(spawns[1].zone == 17, "spawn zone")
check(math.abs(spawns[1].x - 45.2) < 0.01, "spawn x")

local fraction = QR.PointsFromSpawns({ { 0.5, 0.25, 12 } })
check(math.abs(fraction[1].x - 50) < 0.01 and fraction[1].zone == 12, "fraction coords")

local zone = { ids = { [17] = true }, names = { ["The Barrens"] = true }, parents = { [57] = 17 } }

local function point(x, y, id, name)
	return { x = x, y = y, zone = id, zoneName = name or "The Barrens" }
end

local quests = {
	{
		id = 1,
		name = "Plainstrider Menace",
		level = 18,
		header = "The Barrens",
		xp = 1000,
		objectives = {
			{ title = "Plainstrider", verb = "kill", points = { point(10, 0) } },
			{ title = "Swoop", verb = "kill", points = { point(200, 0) } },
		},
		turnin = { title = "Sergra Darkthorn", points = { point(12, 0) } },
		next = {
			id = 99,
			name = "The Zhevra",
			level = 19,
			xp = 800,
			xpEstimated = true,
			pickup = { title = "Sergra Darkthorn", atPrevious = true, points = {} },
			objectives = {
				{ title = "Zhevra", verb = "kill", points = { point(80, 0) } },
			},
			turnin = { title = "Sergra Darkthorn", points = { point(12, 0) } },
		},
	},
	{
		id = 2,
		name = "Chen's Empty Keg",
		level = 10,
		header = "The Barrens",
		xp = 200,
		complete = true,
		turnin = { title = "Brewmaster Drohn", points = { point(30, 30) } },
	},
	{
		id = 3,
		name = "The Stagnant Oasis",
		level = 24,
		header = "The Barrens",
		xp = 1500,
		objectives = {
			{ title = "Oasis", verb = "visit", points = { point(15, 15) } },
		},
		turnin = { title = "Tonga Runetotem", points = { point(16, 16) } },
	},
	{
		id = 4,
		name = "The Defias Brotherhood",
		level = 18,
		header = "Westfall",
		complete = true,
		xp = 2000,
		turnin = { title = "Gryan Stoutmantle", points = { { x = 56, y = 47, zone = 40, zoneName = "Westfall" } } },
	},
	{
		id = 5,
		name = "The People's Militia",
		level = 12,
		header = "Westfall",
		xp = 500,
		objectives = {
			{ title = "Defias", verb = "kill", points = { { x = 40, y = 40, zone = 40, zoneName = "Westfall" } } },
		},
		turnin = { title = "Gryan Stoutmantle", points = { { x = 56, y = 47, zone = 40, zoneName = "Westfall" } } },
	},
	{
		id = 6,
		name = "A Cave Thing",
		level = 18,
		header = "The Barrens",
		xp = 400,
		objectives = {
			{ title = "Kobold", verb = "kill", points = { { x = 20, y = 20, zone = 57, zoneName = "A Cave" } } },
		},
		turnin = { title = "Scout", points = { point(22, 22) } },
	},
}

local plan = QR.Build({
	playerLevel = 20,
	greenRange = 8,
	maxLevelsAbove = 3,
	includeLowLevel = false,
	player = { x = 0, y = 0 },
	speed = 7,
	zone = zone,
	zoneLabel = "The Barrens",
	parents = zone.parents,
	quests = quests,
	questie = true,
	tomtom = true,
})

local seenTurn, seenPick, seenObj = false, false, false
local turnAt, pickAt, zhevraAt
for i, step in ipairs(plan.steps) do
	if step.questName == "Plainstrider Menace" and step.verb == "turn in" then
		seenTurn = true
		turnAt = i
	end
	if step.verb == "pick up" and step.title == "Sergra Darkthorn" then
		seenPick = true
		pickAt = i
	end
	if step.title == "Zhevra" then
		seenObj = true
		zhevraAt = i
	end
	if step.title == "Swoop" then
		check(i < (turnAt or 99), "second objective before turn-in")
	end
end
check(seenTurn and seenPick and seenObj, "chain has turn-in, pickup, and follow-up")
check(turnAt < pickAt and pickAt < zhevraAt, "follow-up waits for the turn-in")

local avoidedLow, avoidedHigh = false, false
for _, row in ipairs(plan.avoid) do
	if row.name == "Chen's Empty Keg" and row.reason == "below your level" then avoidedLow = true end
	if row.name == "The Stagnant Oasis" and row.reason == "leave it for later" then avoidedHigh = true end
end
check(avoidedLow, "low quest avoided")
check(avoidedHigh, "high quest avoided")
check(plan.elsewhereCount == 2, "two quests sit in other zones")
check(plan.bestZone and plan.bestZone.name == "Westfall", "westfall is the move")
check(plan.bestZone.xpPerHour > 0, "other zone has a rate")
check(plan.xp > 0 and plan.xpPerHour > 0, "current zone has a rate")
check(plan.fromPlayer == true, "eta uses the player")
check(plan.arriveSec and plan.arriveSec > 0, "arrive time")

local names = {}
for _, step in ipairs(plan.steps) do
	names[step.title] = true
end
check(names["Kobold"], "cave objective counts as this zone")
check(not names["Brewmaster Drohn"], "low turn-in is not routed")
check(not names["Gryan Stoutmantle"], "other zone is not in this route")

local near = QR.Build({
	playerLevel = 20,
	greenRange = 8,
	maxLevelsAbove = 3,
	includeLowLevel = false,
	player = { x = 0, y = 0 },
	speed = 7,
	zone = zone,
	quests = {
		{
			name = "Near First",
			level = 20,
			header = "The Barrens",
			xp = 100,
			objectives = {
				{ title = "Close", verb = "kill", points = { point(5, 0) } },
				{ title = "Far", verb = "kill", points = { point(80, 0) } },
			},
			turnin = { title = "Giver", points = { point(90, 0) } },
		},
	},
})
check(near.steps[1].title == "Close", "nearest ready objective is first")
check(near.steps[2].title == "Far", "far objective is second")
check(near.steps[3].verb == "turn in", "turn-in is last")

local withLow = QR.Build({
	playerLevel = 20,
	greenRange = 8,
	maxLevelsAbove = 3,
	includeLowLevel = true,
	player = { x = 0, y = 0 },
	speed = 7,
	zone = zone,
	parents = zone.parents,
	quests = quests,
})
local keptLow = false
for _, step in ipairs(withLow.steps) do
	if step.title == "Brewmaster Drohn" then keptLow = true end
end
check(keptLow, "low quests can be included")

local noPins = QR.Build({
	playerLevel = 20,
	greenRange = 8,
	maxLevelsAbove = 3,
	includeLowLevel = false,
	speed = 7,
	zone = zone,
	quests = {
		{
			id = 8,
			name = "Report to the Crossroads",
			level = 20,
			header = "The Barrens",
			xp = 450,
			objectives = { { title = "Speak with Thork", verb = "visit" } },
		},
	},
})
check(#noPins.steps >= 1, "header quest still gets a step")
check(noPins.steps[#noPins.steps].verb == "turn in", "header quest ends at the turn-in")

local dungeon = {
	id = 70,
	name = "Leaders of the Fang",
	level = 18,
	header = "The Barrens",
	dungeon = true,
	xp = 1800,
	objectives = {
		{ title = "Serpentis", verb = "kill", points = { point(18, 4) } },
	},
	turnin = { title = "Nara Wildmane", points = { point(19, 5) } },
}
local omitted = QR.Build({
	playerLevel = 20,
	greenRange = 8,
	maxLevelsAbove = 3,
	includeLowLevel = false,
	omitDungeons = true,
	player = { x = 0, y = 0 },
	speed = 7,
	zone = zone,
	quests = { dungeon },
})
local sawDungeonStep = false
for _, step in ipairs(omitted.steps) do
	if step.questName == "Leaders of the Fang" then sawDungeonStep = true end
end
check(not sawDungeonStep, "dungeon quest is left out of the route")
check(omitted.omittedDungeons == 1, "dungeon quest is counted")
local sawAvoid = false
for _, row in ipairs(omitted.avoid) do
	if row.name == "Leaders of the Fang" and row.reason == "dungeon" then sawAvoid = true end
end
check(sawAvoid, "dungeon quest is listed under avoid")

local keptDungeon = QR.Build({
	playerLevel = 20,
	greenRange = 8,
	maxLevelsAbove = 3,
	includeLowLevel = false,
	omitDungeons = false,
	player = { x = 0, y = 0 },
	speed = 7,
	zone = zone,
	quests = { dungeon },
})
local keptStep = false
for _, step in ipairs(keptDungeon.steps) do
	if step.title == "Serpentis" then keptStep = true end
end
check(keptStep, "dungeon quest can be included")


local missing = QR.Build({
	playerLevel = 20,
	zone = zone,
	quests = {},
	questie = false,
})
local sawMissing = false
for _, text in ipairs(missing.notices) do
	if text == "Questie is not installed, so pins and follow-ups are missing." then
		sawMissing = true
	end
end
check(sawMissing, "missing questie keeps the 1.0.5 notice")

local unreadable = QR.Build({
	playerLevel = 20,
	zone = zone,
	quests = {},
	questie = false,
	questiePresent = true,
})
local sawUnreadable = false
for _, text in ipairs(unreadable.notices) do
	if string.find(text, "could not be read", 1, true) then
		sawUnreadable = true
	end
end
check(sawUnreadable, "loaded questie with no database says so")

local order = QR.OrderZones({ "The Barrens", "Redridge Mountains", "Westfall" }, "Westfall")
check(order[1] == "Westfall" and order[2] == "Redridge Mountains" and order[3] == "The Barrens", "one continent is finished before the next")

local westfall = { ids = { [40] = true }, names = { ["Westfall"] = true }, parents = {} }
local function zpoint(x, y, id, name)
	return { x = x, y = y, zone = id, zoneName = name }
end
local scopeQuests = {
	{
		name = "Westfall Work",
		level = 18,
		header = "Westfall",
		xp = 500,
		objectives = { { title = "Defias", verb = "kill", points = { zpoint(40, 40, 40, "Westfall") } } },
		turnin = { title = "Gryan", points = { zpoint(56, 47, 40, "Westfall") } },
	},
	{
		name = "Redridge Work",
		level = 20,
		header = "Redridge Mountains",
		xp = 600,
		objectives = { { title = "Gnoll", verb = "kill", points = { zpoint(30, 30, 44, "Redridge Mountains") } } },
		turnin = { title = "Magistrate", points = { zpoint(32, 32, 44, "Redridge Mountains") } },
	},
	{
		name = "Barrens Work",
		level = 20,
		header = "The Barrens",
		xp = 700,
		objectives = { { title = "Plainstrider", verb = "kill", points = { zpoint(50, 50, 17, "The Barrens") } } },
		turnin = { title = "Sergra", points = { zpoint(52, 30, 17, "The Barrens") } },
	},
	{
		name = "Gray Elsewhere",
		level = 5,
		header = "Duskwood",
		xp = 50,
		objectives = { { title = "Spider", verb = "kill", points = { zpoint(20, 20, 10, "Duskwood") } } },
	},
	dungeon,
}
local function scopeBuild(useFlights)
	return QR.Build({
		scope = "all",
		useFlights = useFlights,
		travel = function()
			return { seconds = 120, label = "Fly Crossroads → Orgrimmar, ~2m" }
		end,
		playerLevel = 20,
		greenRange = 8,
		maxLevelsAbove = 3,
		includeLowLevel = false,
		omitDungeons = false,
		player = { x = 56, y = 47 },
		speed = 7,
		zone = westfall,
		zoneLabel = "Westfall",
		quests = scopeQuests,
	})
end
local flown = scopeBuild(true)
local walked = scopeBuild(false)
local zonesSeen = {}
for _, step in ipairs(flown.steps) do
	if #zonesSeen == 0 or zonesSeen[#zonesSeen] ~= step.routeZone then
		zonesSeen[#zonesSeen + 1] = step.routeZone
	end
end
check(zonesSeen[1] == "Westfall" and zonesSeen[2] == "Redridge Mountains" and zonesSeen[3] == "The Barrens", "all-log order is zone by zone")
local sawDungeon, sawGray, sawFly = false, false, false
for _, step in ipairs(flown.steps) do
	if step.questName == "Leaders of the Fang" then sawDungeon = true end
	if step.questName == "Gray Elsewhere" then sawGray = true end
	if step.travel and string.find(step.travel, "Fly Crossroads", 1, true) then sawFly = true end
end
check(not sawDungeon, "all-log mode leaves dungeon quests out")
check(not sawGray, "all-log mode still skips gray quests")
check(sawFly, "a flight is shown on the cross-zone step")
check(flown.totalSec > walked.totalSec + 100, "the flight time is added and beats leaving the trip out")
check(flown.scope == "all" and walked.scope == "all", "scope is recorded")

local zoneOnly = QR.Build({
	scope = "zone",
	playerLevel = 20,
	greenRange = 8,
	maxLevelsAbove = 3,
	includeLowLevel = false,
	player = { x = 56, y = 47 },
	speed = 7,
	zone = westfall,
	zoneLabel = "Westfall",
	quests = scopeQuests,
})
local leftTheZone = false
for _, step in ipairs(zoneOnly.steps) do
	if step.title == "Plainstrider" or step.title == "Gnoll" then leftTheZone = true end
end
check(not leftTheZone, "zone scope stays in the current zone")
check(zoneOnly.scope == "zone", "default scope marker")

local longRide = QR.Build({
	useFlights = true,
	travel = function()
		return { seconds = 30, label = "Fly Crossroads → Ratchet, ~1m" }
	end,
	playerLevel = 20,
	greenRange = 8,
	maxLevelsAbove = 3,
	includeLowLevel = false,
	player = { x = 0, y = 0 },
	speed = 7,
	zone = zone,
	quests = {
		{
			name = "Long Ride",
			level = 20,
			header = "The Barrens",
			xp = 100,
			objectives = {
				{ title = "Near", verb = "kill", points = { point(1, 0) } },
				{ title = "Far", verb = "kill", points = { point(50, 0) } },
			},
		},
	},
})
local sawLongFly = false
for _, step in ipairs(longRide.steps) do
	if step.travel and string.find(step.travel, "Ratchet", 1, true) then sawLongFly = true end
end
check(sawLongFly, "a flight beats a long walk")

if fails > 0 then
	print(fails .. " failed")
	os.exit(1)
end
print("OK")
