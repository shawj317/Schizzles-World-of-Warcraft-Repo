-- Zone route planner for QuestRoute. Plain Lua 5.1, no client API, so tests can run it offline.
-- Independent of RutaMisiones (Fastest Quest Route) by Nico: this planner does not copy that
-- addon's code. The MIT license still credits Nico because QuestRoute is an improved take on it.

local _, ns = ...
if type(ns) ~= "table" then
	ns = {}
end

local QuestRoute = {}
ns.Planner = QuestRoute

local YARDS_PER_PERCENT = 42
QuestRoute.YARDS_PER_PERCENT = YARDS_PER_PERCENT

local DWELL = {
	kill = 40,
	collect = 35,
	visit = 20,
	use = 20,
	["turn in"] = 15,
	["pick up"] = 10,
}

local CLASS_HEADERS = {
	Warrior = true,
	Paladin = true,
	Hunter = true,
	Rogue = true,
	Priest = true,
	Shaman = true,
	Mage = true,
	Warlock = true,
	Druid = true,
}

-- Full experience for a normal quest at that level, before the vanilla
-- level-difference reduction. Used only when the client does not report a reward.
local XP_ANCHOR = {
	{ 1, 80 }, { 5, 275 }, { 10, 680 }, { 15, 1000 }, { 20, 1550 }, { 25, 2050 },
	{ 30, 2700 }, { 35, 3400 }, { 40, 4200 }, { 45, 5100 }, { 50, 6100 }, { 55, 7200 }, { 60, 8500 },
}

local function Hypot(dx, dy)
	return math.sqrt(dx * dx + dy * dy)
end

function QuestRoute.ClampSteps(n)
	n = math.floor((tonumber(n) or 7) + 0.5)
	if n < 1 then
		return 1
	end
	if n > 20 then
		return 20
	end
	return n
end

function QuestRoute.ClampAbove(n)
	n = math.floor((tonumber(n) or 3) + 0.5)
	if n < 0 then
		return 0
	end
	if n > 15 then
		return 15
	end
	return n
end

function QuestRoute.FormatXP(n)
	n = math.floor((tonumber(n) or 0) + 0.5)
	if n < 0 then
		n = 0
	end
	if n >= 1000000 then
		local millions = n / 1000000
		if millions >= 10 then
			return string.format("%dM", math.floor(millions + 0.5))
		end
		return string.format("%.1fM", millions)
	end
	if n >= 1000 then
		return string.format("%dK", math.floor(n / 1000 + 0.5))
	end
	return tostring(n)
end

function QuestRoute.FormatClock(seconds)
	seconds = tonumber(seconds) or 0
	if seconds < 45 then
		return "under a min"
	end
	local minutes = math.floor(seconds / 60 + 0.5)
	if minutes < 1 then
		minutes = 1
	end
	if minutes < 60 then
		return minutes .. " min"
	end
	local hours = math.floor(minutes / 60)
	local rest = minutes - hours * 60
	if rest == 0 then
		return hours .. " h"
	end
	return hours .. " h " .. rest .. " min"
end

function QuestRoute.Summary(plan)
	local rate = QuestRoute.FormatXP(plan.xpPerHour or 0)
	if plan.xpEstimated then
		rate = rate .. " XP/h est."
	else
		rate = rate .. " XP/h"
	end
	return (plan.totalSteps or 0) .. " steps · " .. QuestRoute.FormatClock(plan.totalSec or 0) .. " · " .. rate
end

function QuestRoute.IsLowLevel(questLevel, playerLevel, greenRange)
	questLevel = tonumber(questLevel) or 0
	if questLevel < 1 then
		return false
	end
	playerLevel = tonumber(playerLevel) or 1
	greenRange = tonumber(greenRange) or 8
	return (playerLevel - questLevel) > greenRange
end

function QuestRoute.IsTooHigh(questLevel, playerLevel, maxAbove)
	questLevel = tonumber(questLevel) or 0
	if questLevel < 1 then
		return false
	end
	playerLevel = tonumber(playerLevel) or 1
	maxAbove = tonumber(maxAbove) or 0
	return questLevel > (playerLevel + maxAbove)
end

local function FullXP(level)
	level = tonumber(level) or 1
	if level < 1 then
		level = 1
	end
	if level >= XP_ANCHOR[#XP_ANCHOR][1] then
		return XP_ANCHOR[#XP_ANCHOR][2]
	end
	local prev = XP_ANCHOR[1]
	for i = 1, #XP_ANCHOR do
		local row = XP_ANCHOR[i]
		if level == row[1] then
			return row[2]
		end
		if level < row[1] then
			local span = row[1] - prev[1]
			local t = (level - prev[1]) / span
			return math.floor(prev[2] + (row[2] - prev[2]) * t + 0.5)
		end
		prev = row
	end
	return prev[2]
end

function QuestRoute.EstimateXP(questLevel, playerLevel)
	local full = FullXP(questLevel)
	local diff = (tonumber(playerLevel) or 1) - (tonumber(questLevel) or 1)
	local mult = 1
	if diff >= 10 then
		mult = 0.1
	elseif diff == 9 then
		mult = 0.2
	elseif diff == 8 then
		mult = 0.4
	elseif diff == 7 then
		mult = 0.6
	elseif diff == 6 then
		mult = 0.8
	end
	local xp = math.floor(full * mult / 5 + 0.5) * 5
	if xp < 5 then
		xp = 5
	end
	return xp
end

local function IsCoord(node)
	return type(node) == "table" and type(node[1]) == "number" and type(node[2]) == "number"
end

function QuestRoute.PointsFromSpawns(spawns, defaultZone)
	local points = {}
	local function add(zone, x, y)
		if type(x) ~= "number" or type(y) ~= "number" then
			return
		end
		if x == 0 and y == 0 then
			return
		end
		if math.abs(x) <= 1 and math.abs(y) <= 1 then
			x = x * 100
			y = y * 100
		end
		points[#points + 1] = { x = x, y = y, zone = tonumber(zone) or defaultZone }
	end
	local function walk(node, zone)
		if type(node) ~= "table" then
			return
		end
		if IsCoord(node) then
			add(node[3] or zone, node[1], node[2])
			return
		end
		local nx = node.x or node.X
		local ny = node.y or node.Y
		if type(nx) == "number" and type(ny) == "number" then
			local point = { x = nx, y = ny, zone = tonumber(node.zone or node.Zone or node.Area or zone) or zone }
			if math.abs(point.x) <= 1 and math.abs(point.y) <= 1 then
				point.x = point.x * 100
				point.y = point.y * 100
			end
			if point.x == 0 and point.y == 0 then
				return
			end
			point.uiMap = tonumber(node.uiMap or node.UiMapID or node.Map or node.map)
			point.zoneName = node.zoneName or node.ZoneName
			points[#points + 1] = point
			return
		end
		local any = false
		local allCoords = true
		for _, value in pairs(node) do
			any = true
			if not IsCoord(value) then
				allCoords = false
				break
			end
		end
		if any and allCoords then
			for _, value in pairs(node) do
				add(value[3] or zone, value[1], value[2])
			end
			return
		end
		for key, value in pairs(node) do
			if type(value) == "table" then
				local childZone = zone
				if type(key) == "number" and not IsCoord(value) then
					childZone = key
				end
				walk(value, childZone)
			end
		end
	end
	walk(spawns, defaultZone)
	return points
end

local function PointMatches(point, zone)
	if type(point) ~= "table" or type(zone) ~= "table" then
		return false
	end
	local id = tonumber(point.zone)
	local ids = zone.ids
	local parents = zone.parents or {}
	if id and ids and ids[id] then
		return true
	end
	if id and parents[id] and ids and ids[parents[id]] then
		return true
	end
	if point.zoneName and zone.names and zone.names[point.zoneName] then
		return true
	end
	return false
end

local function FilterPoints(points, zone)
	local out = {}
	if type(points) ~= "table" then
		return out
	end
	for i = 1, #points do
		if PointMatches(points[i], zone) then
			out[#out + 1] = points[i]
		end
	end
	return out
end

local function AnyMatch(points, zone)
	return #FilterPoints(points, zone) > 0
end

local function HeaderMatch(quest, zone)
	local header = quest and quest.header
	if type(header) ~= "string" or header == "" then
		return false
	end
	return zone.names and zone.names[header] and true or false
end

local function HasGeo(quest)
	local function scan(points)
		return type(points) == "table" and #points > 0
	end
	for _, obj in ipairs(quest.objectives or {}) do
		if scan(obj.points) then
			return true
		end
	end
	if quest.turnin and scan(quest.turnin.points) then
		return true
	end
	if quest.pickup and scan(quest.pickup.points) then
		return true
	end
	return false
end

function QuestRoute.Touches(quest, zone)
	if type(quest) ~= "table" then
		return false
	end
	if quest.complete then
		if quest.turnin and AnyMatch(quest.turnin.points, zone) then
			return true
		end
		if not HasGeo(quest) and HeaderMatch(quest, zone) then
			return true
		end
		return false
	end
	local remaining = 0
	local remainingWithPoints = 0
	local matched = false
	for _, obj in ipairs(quest.objectives or {}) do
		if not obj.done then
			remaining = remaining + 1
			if obj.points and #obj.points > 0 then
				remainingWithPoints = remainingWithPoints + 1
				if AnyMatch(obj.points, zone) then
					matched = true
				end
			end
		end
	end
	if matched then
		return true
	end
	if remaining > 0 and remainingWithPoints == 0 then
		if quest.turnin and AnyMatch(quest.turnin.points, zone) then
			return true
		end
		if HeaderMatch(quest, zone) then
			return true
		end
	end
	if remaining == 0 then
		if quest.turnin and AnyMatch(quest.turnin.points, zone) then
			return true
		end
		if not HasGeo(quest) and HeaderMatch(quest, zone) then
			return true
		end
	end
	return false
end

function QuestRoute.PrimaryZone(quest, namesById, parents)
	namesById = namesById or {}
	parents = parents or {}
	local counts = {}
	local ids = {}
	local function consider(point)
		if type(point) ~= "table" then
			return
		end
		local id = tonumber(point.zone)
		local name = point.zoneName
		if id and parents[id] and namesById[parents[id]] then
			name = namesById[parents[id]]
			id = parents[id]
		elseif id and (type(name) ~= "string" or name == "") and namesById[id] then
			name = namesById[id]
		end
		if type(name) ~= "string" or name == "" then
			if id then
				name = "zone:" .. id
			else
				return
			end
		end
		counts[name] = (counts[name] or 0) + 1
		if id then
			ids[name] = id
		end
	end
	if not quest.complete then
		for _, obj in ipairs(quest.objectives or {}) do
			if not obj.done then
				for _, point in ipairs(obj.points or {}) do
					consider(point)
				end
			end
		end
	end
	if quest.turnin then
		for _, point in ipairs(quest.turnin.points or {}) do
			consider(point)
		end
	end
	local bestName, bestCount
	for name, count in pairs(counts) do
		if not bestName or count > bestCount or (count == bestCount and name < bestName) then
			bestName = name
			bestCount = count
		end
	end
	if bestName then
		return bestName, ids[bestName], true
	end
	if type(quest.header) == "string" and quest.header ~= "" then
		return quest.header, nil, false
	end
	return "Unknown", nil, false
end

local function AddNotice(list, text)
	if not text or text == "" then
		return
	end
	for i = 1, #list do
		if list[i] == text then
			return
		end
	end
	list[#list + 1] = text
end

local function NewStop(fields)
	fields.preds = fields.preds or {}
	fields.points = fields.points or {}
	fields.dwell = DWELL[fields.verb] or 20
	return fields
end

-- A point copied from the player (or standing on the same spot) is not an objective.
-- player at 0,0 is the offline test origin and is ignored.
function QuestRoute.IsPlayerPoint(point, player)
	if type(point) ~= "table" or type(player) ~= "table" then
		return false
	end
	if point.fromPlayer then
		return true
	end
	local px, py = tonumber(player.x), tonumber(player.y)
	local x, y = tonumber(point.x), tonumber(point.y)
	if not px or not py or not x or not y then
		return false
	end
	if px <= 0 and py <= 0 then
		return false
	end
	if player.uiMap and point.uiMap and player.uiMap ~= point.uiMap then
		return false
	end
	local dx, dy = x - px, y - py
	return dx * dx + dy * dy < (0.2 * 0.2)
end

function QuestRoute.WithoutPlayer(points, player)
	local out = {}
	for i = 1, #(points or {}) do
		if not QuestRoute.IsPlayerPoint(points[i], player) then
			out[#out + 1] = points[i]
		end
	end
	return out
end

-- Largest group of spawns within 12 map-percent of each other. The target is
-- that group's centroid, so walking does not move the pin to the next spawn.
function QuestRoute.ClusterCentroid(points)
	local list = {}
	for i = 1, #(points or {}) do
		local point = points[i]
		if type(point) == "table" and tonumber(point.x) and tonumber(point.y) then
			list[#list + 1] = point
		end
	end
	if #list == 0 then
		return nil
	end
	table.sort(list, function(a, b)
		if a.x == b.x then
			return (a.y or 0) < (b.y or 0)
		end
		return a.x < b.x
	end)
	local radius = 12
	local used = {}
	local best
	for i = 1, #list do
		if not used[i] then
			local cluster = { list[i] }
			used[i] = true
			local grew = true
			while grew do
				grew = false
				for j = 1, #list do
					if not used[j] then
						for k = 1, #cluster do
							local dx = list[j].x - cluster[k].x
							local dy = list[j].y - cluster[k].y
							if dx * dx + dy * dy <= radius * radius then
								used[j] = true
								cluster[#cluster + 1] = list[j]
								grew = true
								break
							end
						end
					end
				end
			end
			local sumX, sumY = 0, 0
			for k = 1, #cluster do
				sumX = sumX + cluster[k].x
				sumY = sumY + cluster[k].y
			end
			local sample = cluster[1]
			local centroid = {
				x = sumX / #cluster,
				y = sumY / #cluster,
				uiMap = sample.uiMap,
				zone = sample.zone,
				zoneName = sample.zoneName,
				areaId = sample.areaId or sample.zone,
				count = #cluster,
			}
			local better = not best or centroid.count > best.count
			if best and centroid.count == best.count then
				better = centroid.x < best.x or (centroid.x == best.x and centroid.y < best.y)
			end
			if better then
				best = centroid
			end
		end
	end
	return best
end

local function IdList(into, list)
	local function add(id)
		id = tonumber(id)
		if not id or id < 1 or id ~= math.floor(id) then
			return
		end
		for i = 1, #into do
			if into[i] == id then
				return
			end
		end
		into[#into + 1] = id
	end
	if type(list) ~= "table" then
		return
	end
	if #list == 2 and tonumber(list[1]) and tonumber(list[2]) and tonumber(list[1]) <= 100 and tonumber(list[2]) <= 100 then
		return
	end
	for key, value in pairs(list) do
		if type(value) == "number" then
			add(value)
		elseif value == true and type(key) == "number" then
			add(key)
		elseif type(value) == "table" then
			if type(value.id) == "number" or type(value.Id) == "number" then
				add(value.id or value.Id)
			elseif type(value[1]) == "number" and type(value[2]) ~= "number" then
				add(value[1])
			end
		end
	end
end

-- Item records name the creatures and objects that drop them. A coordinate
-- pair is not an id. The lookup returns spawn points for one id.
function QuestRoute.CollectDropIds(record)
	local npcs, objects = {}, {}
	if type(record) ~= "table" then
		return npcs, objects
	end
	IdList(npcs, record.npcDrops)
	IdList(npcs, record.NPCDrops)
	IdList(npcs, record.npcDrop)
	IdList(objects, record.objectDrops)
	IdList(objects, record.ObjectDrops)
	IdList(objects, record.objectDrop)
	if type(record.Sources) == "table" then
		IdList(npcs, record.Sources.NPC)
		IdList(objects, record.Sources.GameObject)
		IdList(objects, record.Sources.Object)
	end
	table.sort(npcs)
	table.sort(objects)
	return npcs, objects
end

function QuestRoute.PointsFromDropIds(npcIds, objectIds, lookup)
	local points = {}
	local function pull(ids, kind)
		for i = 1, #(ids or {}) do
			local spawns = lookup and lookup(kind, ids[i])
			for j = 1, #(spawns or {}) do
				points[#points + 1] = spawns[j]
			end
		end
	end
	pull(npcIds, "npc")
	pull(objectIds, "object")
	return points
end

local function PickPoint(stop, cursor, player)
	local points = QuestRoute.WithoutPlayer(stop.points, player)
	if stop.anchor and #points == 0 and stop.anchor.x and not QuestRoute.IsPlayerPoint(stop.anchor, player) then
		local point = {
			x = stop.anchor.x,
			y = stop.anchor.y,
			uiMap = stop.anchor.uiMap,
			zone = stop.anchor.areaId,
			zoneName = stop.anchor.zoneName,
		}
		local distance = 0
		if cursor and cursor.x then
			distance = Hypot(cursor.x - point.x, cursor.y - point.y)
		end
		return distance, point
	end
	local target = QuestRoute.ClusterCentroid(points)
	if not target then
		return 1e9, nil
	end
	local distance = 0
	if cursor and cursor.x then
		distance = Hypot(cursor.x - target.x, cursor.y - target.y)
	end
	return distance, target
end

local function ApplyPoint(stop, point)
	if not point then
		stop.x, stop.y, stop.uiMap, stop.areaId, stop.zoneName = nil, nil, nil, nil, nil
		return
	end
	stop.x = point.x
	stop.y = point.y
	stop.uiMap = point.uiMap
	stop.areaId = point.zone or point.areaId
	stop.zoneName = point.zoneName
end

local function LegYards(a, b, yardsFn)
	if not a or not b or not a.x or not b.x then
		return 0
	end
	if yardsFn then
		local yards = yardsFn(a, b)
		if type(yards) == "number" and yards >= 0 then
			return yards
		end
	end
	return Hypot(a.x - b.x, a.y - b.y) * YARDS_PER_PERCENT
end

local function Realize(order, cursor, yardsFn, player)
	local cost = 0
	local have = cursor and cursor.x and true or false
	local x = have and cursor.x or nil
	local y = have and cursor.y or nil
	local map = have and cursor.uiMap or nil
	for i = 1, #order do
		local stop = order[i]
		local _, point = PickPoint(stop, have and { x = x, y = y, uiMap = map } or nil, player)
		ApplyPoint(stop, point)
		if have and stop.x then
			cost = cost + LegYards({ x = x, y = y, uiMap = map }, stop, yardsFn)
		end
		if stop.x then
			have = true
			x, y, map = stop.x, stop.y, stop.uiMap
		end
	end
	return cost
end

local function Ready(stop, done)
	for i = 1, #stop.preds do
		if not done[stop.preds[i]] then
			return false
		end
	end
	return true
end

local function BuildOrder(stops, player, origin)
	local done = {}
	local order = {}
	local cursor = player
	local guard = 0
	while #order < #stops and guard <= #stops + 1 do
		guard = guard + 1
		local best, bestDistance, bestPoint
		local fallback
		for i = 1, #stops do
			local stop = stops[i]
			if not done[stop] then
				if not fallback then
					fallback = stop
				end
				if Ready(stop, done) then
					local distance, point = PickPoint(stop, cursor, origin)
					if not best or distance < bestDistance then
						best = stop
						bestDistance = distance
						bestPoint = point
					end
				end
			end
		end
		if not best then
			best = fallback
			if best then
				local _, point = PickPoint(best, cursor, origin)
				bestPoint = point
			end
		end
		if not best then
			break
		end
		ApplyPoint(best, bestPoint)
		if best.x then
			cursor = { x = best.x, y = best.y, uiMap = best.uiMap }
		end
		done[best] = true
		order[#order + 1] = best
	end
	return order
end

local function IndexOf(order, stop)
	for i = 1, #order do
		if order[i] == stop then
			return i
		end
	end
end

local function CanPlace(orderWithout, stop, index)
	for i = 1, #stop.preds do
		local at = IndexOf(orderWithout, stop.preds[i])
		if at and at >= index then
			return false
		end
	end
	for i = 1, #orderWithout do
		local other = orderWithout[i]
		for j = 1, #other.preds do
			if other.preds[j] == stop and i < index then
				return false
			end
		end
	end
	return true
end

local function Improve(order, player, yardsFn, origin)
	for _ = 1, 4 do
		local changed = false
		local index = 1
		while index <= #order do
			local stop = order[index]
			local without = {}
			for i = 1, #order do
				if order[i] ~= stop then
					without[#without + 1] = order[i]
				end
			end
			local bestList = order
			local bestCost = Realize(order, player, yardsFn, origin)
			for place = 1, #without + 1 do
				if CanPlace(without, stop, place) then
					local trial = {}
					for i = 1, place - 1 do
						trial[#trial + 1] = without[i]
					end
					trial[#trial + 1] = stop
					for i = place, #without do
						trial[#trial + 1] = without[i]
					end
					local cost = Realize(trial, player, yardsFn, origin)
					if cost + 0.001 < bestCost then
						bestCost = cost
						bestList = trial
					end
				end
			end
			if bestList ~= order then
				order = bestList
				changed = true
			end
			index = index + 1
		end
		if not changed then
			break
		end
	end
	Realize(order, player, yardsFn, origin)
	return order
end

local function CopyStep(stop)
	return {
		title = stop.title or stop.questName or "Quest",
		verb = stop.verb,
		questName = stop.questName,
		questLevel = stop.questLevel,
		questId = stop.questId,
		x = stop.x,
		y = stop.y,
		uiMap = stop.uiMap,
		areaId = stop.areaId,
		zoneName = stop.zoneName,
		xp = stop.xp or 0,
		xpEstimated = stop.xpEstimated and true or false,
		dwell = stop.dwell,
		travel = stop.travel,
		routeZone = stop.routeZone,
		crossZone = stop.crossZone and true or false,
	}
end

local function FollowupTouches(quest, zone)
	if quest.pickup and quest.pickup.atPrevious then
		return true
	end
	if quest.pickup and AnyMatch(quest.pickup.points, zone) then
		return true
	end
	return QuestRoute.Touches(quest, zone)
end

local function RouteQuest(quest, zone, stops, notices, anchor, depth, seen, input)
	if depth > 6 or type(quest) ~= "table" then
		return
	end
	if quest.id and seen[quest.id] then
		return
	end
	if quest.id then
		seen[quest.id] = true
	end
	if input.omitDungeons and quest.dungeon then
		return
	end

	local pickupStop
	if quest.pickup then
		local points = FilterPoints(quest.pickup.points, zone)
		local atPrevious = quest.pickup.atPrevious and anchor
		if #points > 0 or atPrevious then
			local preds = {}
			if anchor then
				preds[1] = anchor
			end
			pickupStop = NewStop({
				title = quest.pickup.title or quest.name,
				verb = "pick up",
				questName = quest.name,
				questLevel = quest.level,
				questId = quest.id,
				points = points,
				anchor = (#points == 0) and anchor or nil,
				preds = preds,
			})
			stops[#stops + 1] = pickupStop
		end
	end

	local objStops = {}
	if not quest.complete then
		for _, obj in ipairs(quest.objectives or {}) do
			if not obj.done then
				local stripped = QuestRoute.WithoutPlayer(obj.points, input and input.player)
				local points = FilterPoints(stripped, zone)
				local pinless = not obj.points or #obj.points == 0 or #stripped == 0
				local include = #points > 0 or (pinless and HeaderMatch(quest, zone))
				if include then
					local preds = {}
					if pickupStop then
						preds[1] = pickupStop
					end
					local stop = NewStop({
						title = obj.title or quest.name,
						verb = obj.verb or "visit",
						questName = quest.name,
						questLevel = quest.level,
						questId = quest.id,
						points = points,
						preds = preds,
					})
					stops[#stops + 1] = stop
					objStops[#objStops + 1] = stop
				end
			end
		end
	end

	local canTurnIn = true
	if not quest.complete then
		for _, obj in ipairs(quest.objectives or {}) do
			if not obj.done and obj.points and #obj.points > 0 and #FilterPoints(obj.points, zone) == 0 then
				canTurnIn = false
			end
		end
	end

	local turnPoints = FilterPoints(quest.turnin and quest.turnin.points, zone)
	local outside = quest.turnin and quest.turnin.points and #quest.turnin.points > 0 and #turnPoints == 0
	local turninStop
	if canTurnIn then
		local include = #turnPoints > 0
		if not include and not outside and (HeaderMatch(quest, zone) or pickupStop or #objStops > 0) then
			if HeaderMatch(quest, zone) or #turnPoints > 0 then
				include = true
			end
			if pickupStop and not outside and (not quest.turnin or not quest.turnin.points or #quest.turnin.points == 0) then
				include = true
			end
		end
		if include then
			local preds = {}
			for i = 1, #objStops do
				preds[i] = objStops[i]
			end
			if #preds == 0 and pickupStop then
				preds[1] = pickupStop
			end
			turninStop = NewStop({
				title = (quest.turnin and quest.turnin.title) or quest.name,
				verb = "turn in",
				questName = quest.name,
				questLevel = quest.level,
				questId = quest.id,
				points = turnPoints,
				preds = preds,
				xp = quest.xp or 0,
				xpEstimated = quest.xpEstimated and true or false,
			})
			if #turnPoints == 0 and anchor and pickupStop and pickupStop.anchor == anchor then
				turninStop.anchor = nil
			end
			stops[#stops + 1] = turninStop
		elseif outside then
			local where = quest.turnin.points[1].zoneName or "another zone"
			AddNotice(notices, "Turn in " .. (quest.name or "a quest") .. " in " .. where .. ".")
		end
	elseif outside then
		local where = quest.turnin.points[1].zoneName or "another zone"
		AddNotice(notices, "Turn in " .. (quest.name or "a quest") .. " in " .. where .. ".")
	end

	local nextQuest = quest.next
	if nextQuest and turninStop then
		local required = tonumber(nextQuest.requiredLevel)
		if required and required > (tonumber(input.playerLevel) or 1) then
			AddNotice(notices, (nextQuest.name or "The next quest") .. " requires level " .. required .. ".")
		elseif QuestRoute.IsTooHigh(nextQuest.level, input.playerLevel, input.maxLevelsAbove) then
			AddNotice(notices, (nextQuest.name or "The next quest") .. " is above your level.")
		elseif not input.includeLowLevel and QuestRoute.IsLowLevel(nextQuest.level, input.playerLevel, input.greenRange) then
			AddNotice(notices, (nextQuest.name or "The next quest") .. " is below your level.")
		elseif input.omitDungeons and nextQuest.dungeon then
			AddNotice(notices, (nextQuest.name or "The next quest") .. " is a dungeon quest.")
		elseif FollowupTouches(nextQuest, zone) then
			RouteQuest(nextQuest, zone, stops, notices, turninStop, depth + 1, seen, input)
		else
			AddNotice(notices, (nextQuest.name or "The next quest") .. " continues outside this zone.")
		end
	end
end

local function StartPoint(stops, player)
	if player and player.x then
		return player, true
	end
	local sumX, sumY, count, map = 0, 0, 0, nil
	for i = 1, #stops do
		for j = 1, #stops[i].points do
			local point = stops[i].points[j]
			sumX = sumX + point.x
			sumY = sumY + point.y
			count = count + 1
			map = map or point.uiMap
		end
	end
	if count > 0 then
		return { x = sumX / count, y = sumY / count, uiMap = map, synthetic = true }, false
	end
	return nil, false
end

local function PlanZone(quests, zone, input)
	local stops = {}
	local notices = {}
	local avoid = {}
	local seen = {}
	for i = 1, #(quests or {}) do
		local quest = quests[i]
		if quest.failed and QuestRoute.Touches(quest, zone) then
			avoid[#avoid + 1] = { name = quest.name or "Quest", reason = "failed" }
		elseif input.omitDungeons and quest.dungeon then
			if QuestRoute.Touches(quest, zone) then
				avoid[#avoid + 1] = { name = quest.name or "Quest", reason = "dungeon" }
			end
		elseif not QuestRoute.Touches(quest, zone) then
			-- Another zone. The caller counts these.
		elseif QuestRoute.IsTooHigh(quest.level, input.playerLevel, input.maxLevelsAbove) then
			avoid[#avoid + 1] = { name = quest.name or "Quest", reason = "leave it for later" }
		elseif not input.includeLowLevel and QuestRoute.IsLowLevel(quest.level, input.playerLevel, input.greenRange) then
			avoid[#avoid + 1] = { name = quest.name or "Quest", reason = "below your level" }
		else
			RouteQuest(quest, zone, stops, notices, nil, 1, seen, input)
		end
	end

	local start, fromPlayer = StartPoint(stops, input.player)
	local order = BuildOrder(stops, start, input.player)
	if #order <= 24 then
		order = Improve(order, start, input.yards, input.player)
	end

	local speed = tonumber(input.speed) or 7
	if speed < 1 then
		speed = 7
	end
	local total = 0
	local prev = (fromPlayer and start) or nil
	local arrive
	local xp = 0
	local estimated = false
	local steps = {}
	for i = 1, #order do
		local stop = order[i]
		local leg = 0
		if prev and prev.x and stop.x then
			leg = LegYards(prev, stop, input.yards) / speed
		end
		if input.useFlights ~= false and type(input.travel) == "function" and prev and prev.x and stop.x and leg >= 180 then
			local okHop, hop = pcall(input.travel, prev, stop)
			if okHop and type(hop) == "table" and type(hop.seconds) == "number" and hop.seconds >= 0 and hop.seconds + 5 < leg then
				leg = hop.seconds
				stop.travel = hop.label
			end
		end
		if i == 1 and fromPlayer and stop.x and not QuestRoute.IsPlayerPoint(stop, input.player) then
			arrive = leg
		end
		total = total + leg + (stop.dwell or 0)
		if stop.verb == "turn in" then
			xp = xp + (stop.xp or 0)
			if stop.xpEstimated then
				estimated = true
			end
		end
		if stop.x then
			prev = stop
		end
		local step = CopyStep(stop)
		if QuestRoute.IsPlayerPoint(step, input.player) then
			step.x, step.y, step.uiMap, step.areaId = nil, nil, nil, nil
			step.unknown = true
		elseif not step.x then
			step.unknown = true
		end
		steps[#steps + 1] = step
	end

	table.sort(avoid, function(a, b)
		if a.name == b.name then
			return a.reason < b.reason
		end
		return a.name < b.name
	end)

	local hours = math.max(total, 10) / 3600
	return {
		steps = steps,
		totalSteps = #steps,
		totalSec = total,
		arriveSec = arrive,
		fromPlayer = fromPlayer,
		xp = xp,
		xpPerHour = xp / hours,
		xpEstimated = estimated,
		notices = notices,
		avoid = avoid,
	}
end

local BuildAll

function QuestRoute.Build(input)
	input = input or {}
	input.playerLevel = tonumber(input.playerLevel) or 1
	input.greenRange = tonumber(input.greenRange) or 8
	input.maxLevelsAbove = QuestRoute.ClampAbove(input.maxLevelsAbove or 3)
	input.includeLowLevel = input.includeLowLevel and true or false
	input.omitDungeons = input.omitDungeons and true or false
	if input.scope == "all" then
		return BuildAll(input)
	end
	local zone = input.zone or { ids = {}, names = {}, parents = {} }
	zone.parents = zone.parents or input.parents or {}
	local plan = PlanZone(input.quests or {}, zone, input)

	local buckets = {}
	local bucketId = {}
	local elsewhere = 0
	local parents = input.parents or zone.parents or {}
	local namesById = input.namesById or {}
	for i = 1, #(input.quests or {}) do
		local quest = input.quests[i]
		if input.omitDungeons and quest.dungeon then
			-- Counted with the omitted dungeon quests.
		elseif not QuestRoute.Touches(quest, zone) then
			elsewhere = elsewhere + 1
			if not quest.failed then
				local name, id, hasPins = QuestRoute.PrimaryZone(quest, namesById, parents)
				if hasPins and name and not CLASS_HEADERS[name] and string.sub(name, 1, 5) ~= "zone:" then
					local list = buckets[name]
					if not list then
						list = {}
						buckets[name] = list
						bucketId[name] = id
					end
					list[#list + 1] = quest
				end
			end
		end
	end

	local omitted = 0
	for i = 1, #(input.quests or {}) do
		if input.omitDungeons and input.quests[i].dungeon then
			omitted = omitted + 1
		end
	end

	local plannable = 0
	local best
	for name, list in pairs(buckets) do
		plannable = plannable + #list
		local other = {
			ids = {},
			names = { [name] = true },
			parents = parents,
		}
		if bucketId[name] then
			other.ids[bucketId[name]] = true
		end
		local sub = PlanZone(list, other, input)
		if sub.totalSteps > 0 and sub.xp > 0 then
			local better = not best
			if best then
				if sub.xpPerHour > best.xpPerHour + 1 then
					better = true
				elseif math.abs(sub.xpPerHour - best.xpPerHour) <= 1 and sub.xp > best.xp then
					better = true
				end
			end
			if better then
				best = {
					name = name,
					quests = #list,
					xpPerHour = sub.xpPerHour,
					xp = sub.xp,
					steps = sub.totalSteps,
					seconds = sub.totalSec,
				}
			end
		end
	end

	plan.elsewhereCount = elsewhere
	plan.elsewherePlannable = plannable
	plan.omittedDungeons = omitted
	plan.bestZone = best
	plan.zoneLabel = input.zoneLabel or "this zone"
	plan.scope = "zone"

	local notices = {}
	if input.questie == false then
		if input.questiePresent then
			AddNotice(notices, "Questie is loaded, but its database could not be read, so pins and follow-ups are missing.")
		else
			AddNotice(notices, "Questie is not installed, so pins and follow-ups are missing.")
		end
	end
	if input.tomtom == false then
		AddNotice(notices, "TomTom is not installed, so there is no arrow.")
	end
	local pinless = 0
	for i = 1, #plan.steps do
		if not plan.steps[i].x then
			pinless = pinless + 1
		end
	end
	if pinless == 1 then
		AddNotice(notices, "1 step has no map pin. Its location is unknown.")
	elseif pinless > 1 then
		AddNotice(notices, pinless .. " steps have no map pin. Their locations are unknown.")
	end
	if plan.xpEstimated and plan.xp > 0 then
		AddNotice(notices, "Experience is estimated from quest level.")
	end
	for i = 1, #plan.notices do
		AddNotice(notices, plan.notices[i])
	end
	plan.notices = notices
	return plan
end

-- Rough positions so a route finishes one continent before it starts the other.
-- x/y are only for ordering zones. They are not map coordinates.
local ZONE_LAYOUT = {
	["Tirisfal Glades"] = { c = 0, x = 8, y = 8 },
	["Undercity"] = { c = 0, x = 8, y = 6 },
	["Silverpine Forest"] = { c = 0, x = 12, y = 16 },
	["Alterac Mountains"] = { c = 0, x = 22, y = 14 },
	["Hillsbrad Foothills"] = { c = 0, x = 20, y = 22 },
	["Western Plaguelands"] = { c = 0, x = 28, y = 12 },
	["Eastern Plaguelands"] = { c = 0, x = 36, y = 14 },
	["The Hinterlands"] = { c = 0, x = 32, y = 22 },
	["Arathi Highlands"] = { c = 0, x = 30, y = 30 },
	["Wetlands"] = { c = 0, x = 24, y = 36 },
	["Dun Morogh"] = { c = 0, x = 16, y = 42 },
	["Ironforge"] = { c = 0, x = 16, y = 40 },
	["Loch Modan"] = { c = 0, x = 26, y = 44 },
	["Badlands"] = { c = 0, x = 30, y = 52 },
	["Searing Gorge"] = { c = 0, x = 20, y = 52 },
	["Burning Steppes"] = { c = 0, x = 24, y = 58 },
	["Elwynn Forest"] = { c = 0, x = 18, y = 66 },
	["Stormwind City"] = { c = 0, x = 18, y = 62 },
	["Redridge Mountains"] = { c = 0, x = 28, y = 66 },
	["Westfall"] = { c = 0, x = 12, y = 72 },
	["Duskwood"] = { c = 0, x = 20, y = 76 },
	["Deadwind Pass"] = { c = 0, x = 28, y = 74 },
	["Swamp of Sorrows"] = { c = 0, x = 32, y = 80 },
	["Blasted Lands"] = { c = 0, x = 30, y = 88 },
	["Stranglethorn Vale"] = { c = 0, x = 16, y = 90 },
	["Teldrassil"] = { c = 1, x = 70, y = 8 },
	["Darnassus"] = { c = 1, x = 70, y = 6 },
	["Darkshore"] = { c = 1, x = 68, y = 18 },
	["Moonglade"] = { c = 1, x = 76, y = 16 },
	["Winterspring"] = { c = 1, x = 80, y = 12 },
	["Felwood"] = { c = 1, x = 72, y = 20 },
	["Ashenvale"] = { c = 1, x = 74, y = 28 },
	["Azshara"] = { c = 1, x = 90, y = 30 },
	["Durotar"] = { c = 1, x = 88, y = 36 },
	["Orgrimmar"] = { c = 1, x = 88, y = 32 },
	["Stonetalon Mountains"] = { c = 1, x = 66, y = 36 },
	["The Barrens"] = { c = 1, x = 78, y = 40 },
	["Mulgore"] = { c = 1, x = 84, y = 48 },
	["Thunder Bluff"] = { c = 1, x = 84, y = 46 },
	["Desolace"] = { c = 1, x = 66, y = 48 },
	["Dustwallow Marsh"] = { c = 1, x = 84, y = 58 },
	["Thousand Needles"] = { c = 1, x = 78, y = 62 },
	["Feralas"] = { c = 1, x = 68, y = 68 },
	["Tanaris"] = { c = 1, x = 80, y = 78 },
	["Un'Goro Crater"] = { c = 1, x = 74, y = 86 },
	["Silithus"] = { c = 1, x = 66, y = 90 },
}

local function ZoneSpot(name)
	return ZONE_LAYOUT[name] or { c = 9, x = 0, y = 0 }
end

function QuestRoute.OrderZones(names, anchor)
	local remaining = {}
	for i = 1, #(names or {}) do
		remaining[#remaining + 1] = names[i]
	end
	table.sort(remaining)
	local ordered = {}
	local function take(name)
		for i = 1, #remaining do
			if remaining[i] == name then
				table.remove(remaining, i)
				ordered[#ordered + 1] = name
				return
			end
		end
	end
	if anchor then
		take(anchor)
	end
	while #remaining > 0 do
		local fromName = ordered[#ordered] or anchor
		local from = fromName and ZoneSpot(fromName) or nil
		local best, bestD, bestI
		for i = 1, #remaining do
			local name = remaining[i]
			local spot = ZoneSpot(name)
			local penalty = 0
			if from and spot.c ~= from.c then
				penalty = 100000
			end
			local dx = from and (spot.x - from.x) or 0
			local dy = from and (spot.y - from.y) or 0
			local d = penalty + dx * dx + dy * dy
			if not best or d < bestD - 0.001 or (math.abs(d - bestD) <= 0.001 and name < best) then
				best, bestD, bestI = name, d, i
			end
		end
		ordered[#ordered + 1] = best
		table.remove(remaining, bestI)
	end
	return ordered
end

local function StampZone(steps, zoneName, current)
	for i = 1, #steps do
		steps[i].routeZone = zoneName
		steps[i].crossZone = zoneName ~= current and true or false
	end
end

local function SortAvoid(list)
	table.sort(list, function(a, b)
		if a.name == b.name then
			return a.reason < b.reason
		end
		return a.name < b.name
	end)
end

BuildAll = function(input)
	local zone = input.zone or { ids = {}, names = {}, parents = {} }
	zone.parents = zone.parents or input.parents or {}
	local parents = input.parents or zone.parents or {}
	local namesById = input.namesById or {}
	local label = input.zoneLabel or "this zone"
	local function routedInput(dropPlayer)
		local copy = {}
		for key, value in pairs(input) do
			copy[key] = value
		end
		copy.omitDungeons = true
		if dropPlayer then
			copy.player = nil
			copy.yards = nil
		end
		return copy
	end
	local open, avoid = {}, {}
	local omitted = 0
	for i = 1, #(input.quests or {}) do
		local quest = input.quests[i]
		if type(quest) == "table" and quest.dungeon then
			omitted = omitted + 1
			avoid[#avoid + 1] = { name = quest.name or "Quest", reason = "dungeon" }
		else
			open[#open + 1] = quest
		end
	end
	local hereQuests = {}
	local buckets, bucketId = {}, {}
	for i = 1, #open do
		local quest = open[i]
		if QuestRoute.Touches(quest, zone) then
			hereQuests[#hereQuests + 1] = quest
		else
			local name, id, hasPins = QuestRoute.PrimaryZone(quest, namesById, parents)
			if hasPins and name and not CLASS_HEADERS[name] and string.sub(name, 1, 5) ~= "zone:" then
				local list = buckets[name]
				if not list then
					list = {}
					buckets[name] = list
					bucketId[name] = id
				end
				list[#list + 1] = quest
			end
		end
	end
	local here = PlanZone(hereQuests, zone, routedInput(false))
	StampZone(here.steps, label, label)
	for i = 1, #here.avoid do
		avoid[#avoid + 1] = here.avoid[i]
	end
	local names = {}
	for name in pairs(buckets) do
		names[#names + 1] = name
	end
	local order = QuestRoute.OrderZones(names, label)
	local steps = {}
	for i = 1, #here.steps do
		steps[#steps + 1] = here.steps[i]
	end
	local notices = {}
	for i = 1, #here.notices do
		AddNotice(notices, here.notices[i])
	end
	local total = here.totalSec or 0
	local xp = here.xp or 0
	local estimated = here.xpEstimated and true or false
	local otherZones = 0
	local nextZone
	local lastPoint
	for i = #steps, 1, -1 do
		if steps[i].x then
			lastPoint = steps[i]
			break
		end
	end
	for i = 1, #order do
		local name = order[i]
		local other = {
			ids = {},
			names = { [name] = true },
			parents = parents,
		}
		if bucketId[name] then
			other.ids[bucketId[name]] = true
		end
		local sub = PlanZone(buckets[name], other, routedInput(true))
		StampZone(sub.steps, name, label)
		for j = 1, #sub.avoid do
			avoid[#avoid + 1] = sub.avoid[j]
		end
		for j = 1, #sub.notices do
			AddNotice(notices, sub.notices[j])
		end
		if sub.totalSteps > 0 then
			otherZones = otherZones + 1
			if not nextZone then
				nextZone = {
					name = name,
					quests = #buckets[name],
					xpPerHour = sub.xpPerHour,
					xp = sub.xp,
					steps = sub.totalSteps,
					seconds = sub.totalSec,
				}
			end
			local first
			for j = 1, #sub.steps do
				if sub.steps[j].x then
					first = sub.steps[j]
					break
				end
			end
			if input.useFlights ~= false and type(input.travel) == "function" and lastPoint and first then
				local okHop, hop = pcall(input.travel, lastPoint, first)
				if okHop and type(hop) == "table" and type(hop.seconds) == "number" and hop.seconds >= 0 then
					total = total + hop.seconds
					sub.steps[1].travel = hop.label or sub.steps[1].travel
				end
			end
			for j = 1, #sub.steps do
				steps[#steps + 1] = sub.steps[j]
				if sub.steps[j].x then
					lastPoint = sub.steps[j]
				end
			end
			total = total + (sub.totalSec or 0)
			xp = xp + (sub.xp or 0)
			if sub.xpEstimated then
				estimated = true
			end
		end
	end
	if otherZones > 0 then
		AddNotice(notices, "Times inside each zone are included. A flight or boat is added when it is faster than walking.")
	end
	SortAvoid(avoid)
	local hours = math.max(total, 10) / 3600
	local plan = {
		steps = steps,
		totalSteps = #steps,
		totalSec = total,
		arriveSec = here.arriveSec,
		fromPlayer = here.fromPlayer,
		xp = xp,
		xpPerHour = xp / hours,
		xpEstimated = estimated,
		notices = notices,
		avoid = avoid,
		elsewhereCount = 0,
		elsewherePlannable = 0,
		omittedDungeons = omitted,
		bestZone = nil,
		nextZone = nextZone,
		otherZoneCount = otherZones,
		zoneLabel = label,
		scope = "all",
	}
	local wrapped = {}
	if input.questie == false then
		if input.questiePresent then
			AddNotice(wrapped, "Questie is loaded, but its database could not be read, so pins and follow-ups are missing.")
		else
			AddNotice(wrapped, "Questie is not installed, so pins and follow-ups are missing.")
		end
	end
	if input.tomtom == false then
		AddNotice(wrapped, "TomTom is not installed, so there is no arrow.")
	end
	local pinless = 0
	for i = 1, #plan.steps do
		if not plan.steps[i].x then
			pinless = pinless + 1
		end
	end
	if pinless == 1 then
		AddNotice(wrapped, "1 step has no map pin. Its location is unknown.")
	elseif pinless > 1 then
		AddNotice(wrapped, pinless .. " steps have no map pin. Their locations are unknown.")
	end
	if plan.xpEstimated and plan.xp > 0 then
		AddNotice(wrapped, "Experience is estimated from quest level.")
	end
	for i = 1, #plan.notices do
		AddNotice(wrapped, plan.notices[i])
	end
	plan.notices = wrapped
	return plan
end

if QUESTROUTE_TEST then
	return QuestRoute
end
