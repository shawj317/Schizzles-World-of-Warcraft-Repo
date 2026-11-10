-- Objective targets must not follow the player. Lua 5.1: lua5.1 target_test.lua
local function script_dir()
	local source = debug.getinfo(1, "S").source
	if source:sub(1, 1) == "@" then
		source = source:sub(2)
	end
	return source:match("^(.*)[/\\]") or "."
end

local ns = {}
assert(loadfile(script_dir() .. "/../AddOns/Wayfarer/Planner.lua"))("Wayfarer", ns)
local QR = ns.Planner

local fails = 0
local function check(cond, msg)
	if not cond then
		fails = fails + 1
		print("FAIL " .. msg)
	end
end

local player = { x = 60.8, y = 38.7, uiMap = 1413 }
local here = { x = 60.8, y = 38.7, uiMap = 1413, zone = 17, zoneName = "The Barrens", fromPlayer = true }
check(QR.IsPlayerPoint(here, player), "a copy of the player is not a target")
check(not QR.IsPlayerPoint({ x = 49.5, y = 44 }, player), "the kodo area is not the player")

local kodos = {
	{ x = 45.2, y = 40.1, zone = 17, uiMap = 1413, zoneName = "The Barrens" },
	{ x = 48.0, y = 43.5, zone = 17, uiMap = 1413, zoneName = "The Barrens" },
	{ x = 51.4, y = 46.2, zone = 17, uiMap = 1413, zoneName = "The Barrens" },
	{ x = 53.0, y = 42.0, zone = 17, uiMap = 1413, zoneName = "The Barrens" },
	here,
}
local kept = QR.WithoutPlayer(kodos, player)
check(#kept == 4, "the player point is dropped")
local centroid = QR.ClusterCentroid(kept)
check(centroid and centroid.x > 44 and centroid.x < 55 and centroid.y > 38 and centroid.y < 50, "centroid sits in the kodo area")
check(not QR.IsPlayerPoint(centroid, player), "centroid is not the player")

local npcIds, objectIds = QR.CollectDropIds({
	name = "Kodo Liver",
	npcDrops = { 3234, 3236, 3474 },
	objectDrops = {},
})
check(#npcIds == 3 and npcIds[1] == 3234, "item drops name the kodo npc ids")
check(#objectIds == 0, "kodo liver is not an object")
local drops = QR.PointsFromDropIds(npcIds, objectIds, function(kind, id)
	if kind == "npc" and id == 3234 then
		return kodos
	end
	return {}
end)
local aimed = QR.ClusterCentroid(QR.WithoutPlayer(drops, player))
check(aimed and not QR.IsPlayerPoint(aimed, player), "drop spawns do not aim at the player")

local zone = { ids = { [17] = true }, names = { ["The Barrens"] = true }, parents = {} }
local function planAt(where)
	return QR.Build({
		playerLevel = 24,
		greenRange = 8,
		maxLevelsAbove = 5,
		includeLowLevel = true,
		player = where,
		speed = 7,
		zone = zone,
		zoneLabel = "The Barrens",
		quests = {
			{
				id = 822,
				name = "Chen's Empty Keg",
				level = 24,
				header = "The Barrens",
				objectives = {
					{
						title = "Kodo Liver",
						verb = "collect",
						points = kodos,
					},
				},
				turnin = {
					title = "Brewmaster Drohn",
					points = { { x = 62.3, y = 38.4, zone = 17, uiMap = 1413, zoneName = "The Barrens" } },
				},
			},
		},
		questie = true,
		tomtom = false,
	})
end

local first = planAt(player)
local liver
for i = 1, #first.steps do
	if first.steps[i].title == "Kodo Liver" then
		liver = first.steps[i]
	end
end
check(liver and liver.x and not QR.IsPlayerPoint(liver, player), "kodo liver is not pinned on the player")
check(liver.x > 44 and liver.x < 55, "kodo liver points at the spawn cluster")
check(first.arriveSec == nil or first.arriveSec > 45 or first.steps[1].title ~= "Kodo Liver" or not QR.IsPlayerPoint(first.steps[1], player), "travel time is not zero at the player")

local moved = planAt({ x = 30, y = 70, uiMap = 1413 })
local liver2
for i = 1, #moved.steps do
	if moved.steps[i].title == "Kodo Liver" then
		liver2 = moved.steps[i]
	end
end
check(liver2 and math.abs(liver2.x - liver.x) < 0.001 and math.abs(liver2.y - liver.y) < 0.001, "the pin stays put when the player moves")

local lost = QR.Build({
	playerLevel = 24,
	greenRange = 8,
	maxLevelsAbove = 5,
	includeLowLevel = true,
	player = player,
	speed = 7,
	zone = zone,
	quests = {
		{
			name = "Chen's Empty Keg",
			level = 24,
			header = "The Barrens",
			objectives = {
				{ title = "Kodo Liver", verb = "collect", points = { here } },
			},
			turnin = { title = "Brewmaster Drohn", points = { { x = 62.3, y = 38.4, zone = 17, uiMap = 1413 } } },
		},
	},
	questie = true,
})
local unknown
for i = 1, #lost.steps do
	if lost.steps[i].title == "Kodo Liver" then
		unknown = lost.steps[i]
	end
end
check(unknown and not unknown.x and not unknown.y, "an unresolvable collect step has no pin")
check(unknown.unknown == true, "the step is marked location unknown")
check(not QR.IsPlayerPoint(unknown, player), "it is not given the player coordinates")
local sample = {
	{ x = 10, y = 10, uiMap = 1 },
	{ x = 11, y = 10, uiMap = 1 },
	{ x = 80, y = 80, uiMap = 1 },
}
local first = QR.ClusterCentroid(sample)
local second = QR.ClusterCentroid(sample)
check(first == second and first.count == 2, "a spawn cluster is computed once and reused")

if fails > 0 then
	print(fails .. " failed")
	os.exit(1)
end
print("OK")
