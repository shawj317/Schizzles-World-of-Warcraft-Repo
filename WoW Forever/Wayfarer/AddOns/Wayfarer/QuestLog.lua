-- Quest log, Questie pins, and the scan that feeds the planner.
-- QuestRoute by Jon Shaw (Schizzle). Reads Questie through QuestieLoader when that addon is loaded.

local _, ns = ...

local function Hypot(dx, dy)
	return math.sqrt(dx * dx + dy * dy)
end

local YARDS_PER_PERCENT = ns.Planner.YARDS_PER_PERCENT

local function QuestieModule(name)
	if type(QuestieLoader) ~= "table" or type(QuestieLoader.ImportModule) ~= "function" then
		return nil
	end
	local ok, mod = pcall(QuestieLoader.ImportModule, QuestieLoader, name)
	if ok and type(mod) == "table" then
		return mod
	end
	return nil
end

local function QCall(mod, method, a, b, c)
	if type(mod) ~= "table" then
		return nil
	end
	local fn = mod[method]
	if type(fn) ~= "function" then
		return nil
	end
	local ok, result = pcall(fn, a, b, c)
	if ok and result ~= nil then
		return result
	end
	ok, result = pcall(fn, mod, a, b, c)
	if ok then
		return result
	end
	return nil
end

local function EachId(list, fn)
	if list == nil or ns.IsSecret(list) then
		return
	end
	if type(list) == "number" then
		fn(list)
		return
	end
	if type(list) ~= "table" then
		return
	end
	for key, value in pairs(list) do
		if ns.IsSecret(key) or ns.IsSecret(value) then
			-- A secret cannot be a table key or a boolean test.
		elseif type(value) == "number" then
			fn(value)
		elseif value == true and type(key) == "number" then
			fn(key)
		elseif type(value) == "table" and not ns.IsSecret(value[1]) and type(value[1]) == "number" and type(value[2]) ~= "number" then
			fn(value[1])
		end
	end
end

local namesById = {}
local parents = {}
local zoneDB

local function RememberZone(id)
	id = tonumber(id)
	if not id or namesById[id] or namesById[id] == false then
		return
	end
	local name
	if C_Map and C_Map.GetAreaInfo then
		local ok, value = pcall(C_Map.GetAreaInfo, id)
		if ok then
			name = ns.Text(value, nil)
		end
	end
	namesById[id] = name or false
	if zoneDB and type(zoneDB.GetParentZoneId) == "function" and not parents[id] then
		local ok, parent = pcall(zoneDB.GetParentZoneId, zoneDB, id)
		parent = ok and tonumber(parent) or nil
		if parent and parent ~= id and parent > 0 then
			parents[id] = parent
			RememberZone(parent)
		end
	end
end

local function MapFor(area)
	area = tonumber(area)
	if not area or not zoneDB or type(zoneDB.GetUiMapIdByAreaId) ~= "function" then
		return nil
	end
	local ok, map = pcall(zoneDB.GetUiMapIdByAreaId, zoneDB, area)
	if ok and type(map) == "number" and map > 0 then
		return map
	end
	return nil
end

local function Decorate(points, playerMap, zoneIds)
	for i = 1, #points do
		local point = points[i]
		local id = tonumber(point.zone)
		if id then
			RememberZone(id)
			local stored = namesById[id]
			if stored and stored ~= false and not point.zoneName then
				point.zoneName = stored
			end
			point.uiMap = MapFor(id)
			if not point.uiMap and playerMap and zoneIds and (zoneIds[id] or (parents[id] and zoneIds[parents[id]])) then
				point.uiMap = playerMap
			end
		end
	end
	return points
end

local function NpcInfo(db, id)
	local record = QCall(db, "GetNPC", id)
	if type(record) == "table" then
		return record.name, record.spawns
	end
	return QCall(db, "QueryNPCSingle", id, "name"), QCall(db, "QueryNPCSingle", id, "spawns")
end

local function ObjectInfo(db, id)
	local record = QCall(db, "GetObject", id)
	if type(record) == "table" then
		return record.name, record.spawns
	end
	return QCall(db, "QueryObjectSingle", id, "name"), QCall(db, "QueryObjectSingle", id, "spawns")
end

local rawNpcPoints = {}
local rawObjectPoints = {}
local rawItemPoints = {}
local scanPlayer
local scanZoneIds

local function ZoneHere(id, zoneIds)
	id = tonumber(id)
	if not id or not zoneIds then
		return false
	end
	if zoneIds[id] then
		return true
	end
	local parent = parents[id]
	return parent and zoneIds[parent] and true or false
end

local function ThinPoints(points, zoneIds, player)
	if type(points) ~= "table" or #points <= 8 then
		return points
	end
	local byZone = {}
	local order = {}
	for i = 1, #points do
		local point = points[i]
		local id = tonumber(point.zone) or 0
		local list = byZone[id]
		if not list then
			list = {}
			byZone[id] = list
			order[#order + 1] = id
		end
		list[#list + 1] = point
	end
	local out = {}
	for i = 1, #order do
		local id = order[i]
		local list = byZone[id]
		local cap = ZoneHere(id, zoneIds) and 6 or 2
		if player and player.x and #list > cap then
			table.sort(list, function(a, b)
				local dax = a.x - player.x
				local day = a.y - player.y
				local dbx = b.x - player.x
				local dby = b.y - player.y
				return (dax * dax + day * day) < (dbx * dbx + dby * dby)
			end)
		end
		local keep = #list
		if keep > cap then
			keep = cap
		end
		for j = 1, keep do
			out[#out + 1] = list[j]
		end
	end
	return out
end

local function PointsForNpc(db, id, playerMap, zoneIds)
	local points = rawNpcPoints[id]
	if not points then
		local _, spawns = NpcInfo(db, id)
		points = Decorate(ns.Planner.PointsFromSpawns(spawns), playerMap, zoneIds)
		rawNpcPoints[id] = points
	end
	return ThinPoints(points, zoneIds or scanZoneIds, scanPlayer)
end

local function PointsForObject(db, id, playerMap, zoneIds)
	local points = rawObjectPoints[id]
	if not points then
		local _, spawns = ObjectInfo(db, id)
		points = Decorate(ns.Planner.PointsFromSpawns(spawns), playerMap, zoneIds)
		rawObjectPoints[id] = points
	end
	return ThinPoints(points, zoneIds or scanZoneIds, scanPlayer)
end

local function AppendPoints(into, extra)
	for i = 1, #extra do
		into[#into + 1] = extra[i]
	end
end

local function PointsForItem(db, itemId, playerMap, zoneIds)
	local cached = rawItemPoints[itemId]
	if cached then
		return ThinPoints(cached, zoneIds or scanZoneIds, scanPlayer)
	end
	local points = {}
	local npcs = QCall(db, "QueryItemSingle", itemId, "npcDrops")
	local objects = QCall(db, "QueryItemSingle", itemId, "objectDrops")
	EachId(npcs, function(id)
		local raw = rawNpcPoints[id]
		if not raw then
			local _, spawns = NpcInfo(db, id)
			raw = Decorate(ns.Planner.PointsFromSpawns(spawns), playerMap, zoneIds)
			rawNpcPoints[id] = raw
		end
		AppendPoints(points, raw)
	end)
	EachId(objects, function(id)
		local raw = rawObjectPoints[id]
		if not raw then
			local _, spawns = ObjectInfo(db, id)
			raw = Decorate(ns.Planner.PointsFromSpawns(spawns), playerMap, zoneIds)
			rawObjectPoints[id] = raw
		end
		AppendPoints(points, raw)
	end)
	rawItemPoints[itemId] = points
	return ThinPoints(points, zoneIds or scanZoneIds, scanPlayer)
end

local VERB = {
	monster = "kill",
	npc = "kill",
	kill = "kill",
	killcredit = "kill",
	item = "collect",
	object = "collect",
	event = "visit",
	log = "visit",
	reputation = "visit",
	player = "visit",
	spell = "use",
}

local function CleanText(text)
	if text == nil or ns.IsSecret(text) or type(text) ~= "string" then
		return nil
	end
	text = string.gsub(text, "^%s+", "")
	text = string.gsub(text, "%s+$", "")
	text = string.gsub(text, ":%s*%d+%s*/%s*%d+%s*$", "")
	text = string.gsub(text, "%s+%d+%s*/%s*%d+%s*$", "")
	if text == "" then
		return nil
	end
	return text
end

local function StarterBuckets(record)
	local npcs, objects = {}, {}
	if type(record.Starts) == "table" then
		EachId(record.Starts.NPC, function(id) npcs[#npcs + 1] = id end)
		EachId(record.Starts.GameObject, function(id) objects[#objects + 1] = id end)
	end
	if #npcs == 0 and #objects == 0 and type(record.startedBy) == "table" then
		EachId(record.startedBy[1], function(id) npcs[#npcs + 1] = id end)
		EachId(record.startedBy[2], function(id) objects[#objects + 1] = id end)
	end
	return npcs, objects
end

local function FinisherBuckets(record)
	local npcs, objects = {}, {}
	if type(record.Finisher) == "table" then
		EachId(record.Finisher.NPC, function(id) npcs[#npcs + 1] = id end)
		EachId(record.Finisher.GameObject, function(id) objects[#objects + 1] = id end)
	end
	if #npcs == 0 and #objects == 0 and type(record.finishedBy) == "table" then
		EachId(record.finishedBy[1], function(id) npcs[#npcs + 1] = id end)
		EachId(record.finishedBy[2], function(id) objects[#objects + 1] = id end)
	end
	return npcs, objects
end

local function ObjectiveFromData(db, data, playerMap, zoneIds)
	if type(data) ~= "table" then
		return nil, nil
	end
	local verb = VERB[data.Type] or "visit"
	local title = data.Text
	local points = {}
	if data.Type == "monster" or data.Type == "npc" then
		local name = NpcInfo(db, data.Id)
		title = name or title
		points = PointsForNpc(db, data.Id, playerMap, zoneIds)
	elseif data.Type == "object" then
		local name = ObjectInfo(db, data.Id)
		title = name or title
		points = PointsForObject(db, data.Id, playerMap, zoneIds)
	elseif data.Type == "item" then
		title = QCall(db, "QueryItemSingle", data.Id, "name") or title
		points = PointsForItem(db, data.Id, playerMap, zoneIds)
	elseif data.Type == "killcredit" then
		local count = 0
		local only
		EachId(data.IdList, function(id)
			count = count + 1
			only = id
			AppendPoints(points, PointsForNpc(db, id, playerMap, zoneIds))
		end)
		if count == 1 then
			title = NpcInfo(db, only) or title
		end
	elseif data.Type == "event" then
		points = Decorate(ns.Planner.PointsFromSpawns(data.Coordinates), playerMap, zoneIds)
	elseif data.Type == "spell" and data.ItemSourceId then
		points = PointsForItem(db, data.ItemSourceId, playerMap, zoneIds)
	end
	return verb, title, points
end

local function TurninFor(db, record, playerMap, zoneIds, fallback)
	local npcs, objects = FinisherBuckets(record)
	local points = {}
	local title
	for i = 1, #npcs do
		local name = NpcInfo(db, npcs[i])
		if not title then
			title = name
		elseif name and name ~= title then
			title = fallback
		end
		AppendPoints(points, PointsForNpc(db, npcs[i], playerMap, zoneIds))
	end
	for i = 1, #objects do
		local name = ObjectInfo(db, objects[i])
		if not title then
			title = name
		elseif name and name ~= title then
			title = fallback
		end
		AppendPoints(points, PointsForObject(db, objects[i], playerMap, zoneIds))
	end
	return { title = title or fallback, points = points }
end

local function PickupFor(db, record, prevFinishers, playerMap, zoneIds, fallback)
	local npcs, objects = StarterBuckets(record)
	local points = {}
	local title
	local atPrevious = #npcs == 0 and #objects == 0
	for i = 1, #npcs do
		if prevFinishers and prevFinishers[npcs[i]] then
			atPrevious = true
		end
		local name = NpcInfo(db, npcs[i])
		if not title then
			title = name
		end
		AppendPoints(points, PointsForNpc(db, npcs[i], playerMap, zoneIds))
	end
	for i = 1, #objects do
		if prevFinishers and prevFinishers[objects[i]] then
			atPrevious = true
		end
		local name = ObjectInfo(db, objects[i])
		if not title then
			title = name
		end
		AppendPoints(points, PointsForObject(db, objects[i], playerMap, zoneIds))
	end
	return { title = title or fallback, points = points, atPrevious = atPrevious }
end

local completedCache

local function IsCompleted(questId)
	questId = ns.Num(questId, nil)
	if not questId then
		return false
	end
	if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
		local ok, done = pcall(C_QuestLog.IsQuestFlaggedCompleted, questId)
		if ok and ns.Flag(done) then
			return true
		end
	end
	if IsQuestFlaggedCompleted then
		local ok, done = pcall(IsQuestFlaggedCompleted, questId)
		if ok and ns.Flag(done) then
			return true
		end
	end
	if not completedCache and GetQuestsCompleted then
		local ok, value = pcall(GetQuestsCompleted)
		completedCache = (ok and type(value) == "table") and value or {}
	end
	local flagged = completedCache and completedCache[questId]
	if ns.IsSecret(flagged) then
		return false
	end
	return flagged and true or false
end

local function IdSetFrom(...)
	local set = {}
	for i = 1, select("#", ...) do
		local list = select(i, ...)
		if type(list) == "table" then
			for j = 1, #list do
				set[list[j]] = true
			end
		end
	end
	return set
end

local DUNGEON_TAG = {
	[62] = true,
	[81] = true,
	[88] = true,
	[89] = true,
}

local function TagMeansDungeon(first, second)
	if type(first) == "number" and DUNGEON_TAG[first] then
		return true
	end
	if type(second) == "number" and DUNGEON_TAG[second] then
		return true
	end
	local text = ""
	if type(first) == "string" then
		text = first
	end
	if type(second) == "string" then
		text = text .. " " .. second
	end
	text = string.lower(text)
	if string.find(text, "dungeon", 1, true) or string.find(text, "raid", 1, true) then
		return true
	end
	return false
end

local function MarkDungeon(quest, db)
	if type(quest) ~= "table" or quest.dungeon then
		return
	end
	local id = tonumber(quest.id)
	if id and GetQuestTagInfo then
		local ok, first, second = pcall(GetQuestTagInfo, id)
		if ok and TagMeansDungeon(first, second) then
			quest.dungeon = true
			return
		end
	end
	if id and C_QuestLog and C_QuestLog.GetQuestTagInfo then
		local ok, info = pcall(C_QuestLog.GetQuestTagInfo, id)
		if ok and type(info) == "table" and TagMeansDungeon(info.tagID, info.tagName) then
			quest.dungeon = true
			return
		end
		if ok and TagMeansDungeon(info, nil) then
			quest.dungeon = true
			return
		end
	end
	local record
	if db and id then
		record = QCall(db, "GetQuest", id)
	end
	if type(record) == "table" then
		local sort = tonumber(record.zoneOrSort)
		if sort and sort < 0 and zoneDB and type(zoneDB.GetDungeonLocation) == "function" then
			local loc = QCall(zoneDB, "GetDungeonLocation", sort)
			if loc ~= nil and loc ~= false then
				quest.dungeon = true
				return
			end
		end
	end
	if not C_Map or not C_Map.GetMapInfo then
		return
	end
	local maps, inside = 0, 0
	local function consider(points)
		if type(points) ~= "table" then
			return
		end
		for i = 1, #points do
			local uiMap = points[i] and points[i].uiMap
			if uiMap then
				local ok, info = pcall(C_Map.GetMapInfo, uiMap)
				if ok and type(info) == "table" and info.mapType then
					maps = maps + 1
					if info.mapType == 4 then
						inside = inside + 1
					end
				end
			end
		end
	end
	for i = 1, #(quest.objectives or {}) do
		consider(quest.objectives[i].points)
	end
	if quest.turnin then
		consider(quest.turnin.points)
	end
	if maps > 0 and inside == maps then
		quest.dungeon = true
	end
end

local function BuildChain(db, questId, prevFinishers, depth, seen, inLog, playerLevel, playerMap, zoneIds)
	questId = tonumber(questId)
	if not questId or questId == 0 or depth > 5 or seen[questId] or inLog[questId] or IsCompleted(questId) then
		return nil
	end
	seen[questId] = true
	local record = QCall(db, "GetQuest", questId)
	if type(record) ~= "table" then
		return nil
	end
	local name = record.name or ("Quest " .. questId)
	local level = tonumber(record.level) or tonumber(record.questLevel) or 0
	local objectives = {}
	local data = record.ObjectiveData
	if type(data) == "table" then
		for i = 1, #data do
			local verb, title, points = ObjectiveFromData(db, data[i], playerMap, zoneIds)
			if verb then
				objectives[#objectives + 1] = {
					title = title or name,
					verb = verb,
					points = points,
				}
			end
		end
	end
	local quest = {
		id = questId,
		name = name,
		level = level,
		requiredLevel = tonumber(record.requiredLevel),
		objectives = objectives,
		turnin = TurninFor(db, record, playerMap, zoneIds, name),
		pickup = PickupFor(db, record, prevFinishers, playerMap, zoneIds, name),
		xp = ns.Planner.EstimateXP(level, playerLevel),
		xpEstimated = true,
	}
	local nextId = tonumber(record.nextQuestInChain)
	if nextId and nextId ~= 0 then
		local finishers = IdSetFrom(FinisherBuckets(record))
		quest.next = BuildChain(db, nextId, finishers, depth + 1, seen, inLog, playerLevel, playerMap, zoneIds)
	end
	MarkDungeon(quest, db)
	return quest
end

local function RowFrom(title, level, extraLevel, isHeader, isCollapsed, isComplete, questID)
	local failed = false
	if not ns.IsSecret(isComplete) and isComplete == -1 then
		failed = true
		isComplete = false
	elseif ns.IsSecret(isComplete) then
		isComplete = false
	end
	local resolved = ns.Num(level, nil) or ns.Num(extraLevel, 0)
	return {
		title = ns.Text(title, "Quest"),
		level = resolved,
		isHeader = ns.Flag(isHeader),
		isCollapsed = ns.Flag(isCollapsed),
		complete = isComplete == true or isComplete == 1,
		failed = failed,
		questID = ns.Num(questID, nil),
	}
end

local function ReadTitle(index)
	if C_QuestLog and C_QuestLog.GetInfo then
		local okInfo, info = pcall(C_QuestLog.GetInfo, index)
		if okInfo and type(info) == "table" then
			local complete = info.isComplete
			local questID = ns.Num(info.questID, nil)
			if questID and C_QuestLog.IsComplete then
				local ok, value = pcall(C_QuestLog.IsComplete, questID)
				if ok and not ns.IsSecret(value) then
					complete = value
				end
			end
			local failedValue = false
			if questID and C_QuestLog.IsFailed then
				local ok, value = pcall(C_QuestLog.IsFailed, questID)
				failedValue = ok and ns.Flag(value)
			end
			local row = RowFrom(info.title, info.level, info.difficultyLevel, info.isHeader, info.isCollapsed, complete, questID)
			if failedValue then
				row.failed = true
			end
			return row
		end
	end
	if not GetQuestLogTitle then
		return nil
	end
	local ok, title, level, _, isHeader, isCollapsed, isComplete, _, questID = pcall(GetQuestLogTitle, index)
	if not ok then
		return nil
	end
	return RowFrom(title, level, nil, isHeader, isCollapsed, isComplete, questID)
end

local function ReadObjectives(index, questID)
	local list = {}
	if questID and C_QuestLog and C_QuestLog.GetQuestObjectives then
		local ok, objectives = pcall(C_QuestLog.GetQuestObjectives, questID)
		if ok and type(objectives) == "table" then
			for i = 1, #objectives do
				local obj = objectives[i]
				local kind = obj.type
				local alt = obj.objectiveType
				if ns.IsSecret(kind) then
					kind = nil
				end
				if ns.IsSecret(alt) then
					alt = nil
				end
				local text = obj.text
				if ns.IsSecret(text) then
					text = nil
				end
				list[#list + 1] = {
					text = text,
					verb = VERB[kind] or VERB[alt] or "visit",
					done = ns.Flag(obj.finished),
				}
			end
			if #list > 0 then
				return list
			end
		end
	end
	if SelectQuestLogEntry then
		SelectQuestLogEntry(index)
	end
	local count = 0
	if GetNumQuestLeaderBoards then
		local ok, value = pcall(GetNumQuestLeaderBoards, index)
		count = ok and ns.Num(value, nil) or nil
		if not count then
			ok, value = pcall(GetNumQuestLeaderBoards)
			count = ok and ns.Num(value, 0) or 0
		end
	end
	for i = 1, count do
		local ok, text, objectiveType, finished = pcall(GetQuestLogLeaderBoard, i, index)
		if not ok or text == nil or ns.IsSecret(text) then
			ok, text, objectiveType, finished = pcall(GetQuestLogLeaderBoard, i)
		end
		if not ok or ns.IsSecret(text) then
			text = nil
		end
		if ns.IsSecret(objectiveType) then
			objectiveType = nil
		end
		list[#list + 1] = {
			text = text,
			verb = VERB[objectiveType] or "visit",
			done = ns.Flag(finished),
		}
	end
	return list
end

local function NumEntries()
	if C_QuestLog and C_QuestLog.GetNumQuestLogEntries then
		local ok, value = pcall(C_QuestLog.GetNumQuestLogEntries)
		return ok and ns.Num(value, 0) or 0
	end
	if GetNumQuestLogEntries then
		local ok, value = pcall(GetNumQuestLogEntries)
		return ok and ns.Num(value, 0) or 0
	end
	return 0
end

local function ExpandCollapsed()
	local opened = {}
	if not ExpandQuestHeader then
		return opened
	end
	for _ = 1, 6 do
		local count = NumEntries()
		local did = false
		for index = count, 1, -1 do
			local row = ReadTitle(index)
			if row and row.isHeader and row.isCollapsed then
				opened[#opened + 1] = row.title
				ExpandQuestHeader(index)
				did = true
			end
		end
		if not did then
			break
		end
	end
	return opened
end

local function RestoreCollapsed(opened)
	if not CollapseQuestHeader or not opened or #opened == 0 then
		return
	end
	for index = NumEntries(), 1, -1 do
		local row = ReadTitle(index)
		if row and row.isHeader and not row.isCollapsed then
			for j = 1, #opened do
				if opened[j] == row.title then
					CollapseQuestHeader(index)
					table.remove(opened, j)
					break
				end
			end
		end
	end
end

local function PlayerSpeed()
	local speed = 7
	local mounted = false
	if IsMounted then
		local ok, value = pcall(IsMounted)
		mounted = ok and ns.Flag(value)
	end
	if GetUnitSpeed then
		local ok, current = pcall(GetUnitSpeed, "player")
		current = ok and ns.Num(current, nil) or nil
		if current and current > 4 then
			return current
		end
	end
	if mounted then
		return 11
	end
	return speed
end

local function Coord(value)
	if value == nil or ns.IsSecret(value) or type(value) ~= "number" then
		return nil
	end
	return value
end

local function Pair(pos, posY)
	if type(pos) == "table" then
		if type(pos.GetXY) == "function" and Coord(pos.x) == nil and Coord(pos[1]) == nil then
			local ok, x, y = pcall(pos.GetXY, pos)
			if ok then
				return Coord(x), Coord(y)
			end
		end
		local x = Coord(pos.x)
		if x == nil then
			x = Coord(pos[1])
		end
		local y = Coord(pos.y)
		if y == nil then
			y = Coord(pos[2])
		end
		return x, y
	end
	return Coord(pos), Coord(posY)
end

local function PlayerPosition()
	local map
	if C_Map and C_Map.GetBestMapForUnit then
		local ok, value = pcall(C_Map.GetBestMapForUnit, "player")
		if ok and not ns.IsSecret(value) then
			map = value
		end
	end
	if map and C_Map.GetPlayerMapPosition then
		local ok, pos, posY = pcall(C_Map.GetPlayerMapPosition, map, "player")
		if ok and pos and not ns.IsSecret(pos) then
			local x, y = Pair(pos, posY)
			if x and y and x > 0 and y > 0 then
				return { x = x * 100, y = y * 100, uiMap = map }, map
			end
		end
	end
	if GetPlayerMapPosition then
		local ok, x, y = pcall(GetPlayerMapPosition, "player")
		if ok then
			x, y = Pair(x, y)
			if x and y and x > 0 and y > 0 then
				return { x = x * 100, y = y * 100, uiMap = map }, map
			end
		end
	end
	return nil, map
end

local function MakeYards()
	if not C_Map or not C_Map.GetWorldPosFromMapPos then
		return nil
	end
	return function(a, b)
		local fallback = Hypot((a.x or 0) - (b.x or 0), (a.y or 0) - (b.y or 0)) * YARDS_PER_PERCENT
		if not a.uiMap or a.uiMap ~= b.uiMap or not a.x or not b.x then
			return fallback
		end
		local posA = { x = a.x / 100, y = a.y / 100 }
		local posB = { x = b.x / 100, y = b.y / 100 }
		local okA, firstA, secondA = pcall(C_Map.GetWorldPosFromMapPos, a.uiMap, posA)
		local okB, firstB, secondB = pcall(C_Map.GetWorldPosFromMapPos, b.uiMap, posB)
		local worldA = (type(firstA) == "table" and firstA.x and firstA) or (type(secondA) == "table" and secondA.x and secondA)
		local worldB = (type(firstB) == "table" and firstB.x and firstB) or (type(secondB) == "table" and secondB.x and secondB)
		if okA and okB and worldA and worldB and not ns.IsSecret(worldA.x) and not ns.IsSecret(worldA.y) and not ns.IsSecret(worldB.x) and not ns.IsSecret(worldB.y) then
			return Hypot(worldA.x - worldB.x, worldA.y - worldB.y)
		end
		return fallback
	end
end

local function AttachQuestie(quest, db, playerLevel, playerMap, zoneIds, inLog)
	if not db or not quest.id then
		return
	end
	local record = QCall(db, "GetQuest", quest.id)
	if type(record) ~= "table" and type(db.GetQuestIDFromName) == "function" and quest.name then
		local found = QCall(db, "GetQuestIDFromName", quest.name)
		found = tonumber(found)
		if found then
			quest.id = found
			record = QCall(db, "GetQuest", found)
			inLog[found] = true
		end
	end
	if type(record) ~= "table" then
		return
	end
	if (not quest.level or quest.level < 1) and (record.level or record.questLevel) then
		quest.level = tonumber(record.level) or tonumber(record.questLevel) or quest.level
	end
	local data = record.ObjectiveData
	quest.objectives = quest.objectives or {}
	if type(data) == "table" then
		for i = 1, #quest.objectives do
			local verb, title, points = ObjectiveFromData(db, data[i], playerMap, zoneIds)
			if verb then
				quest.objectives[i].verb = quest.objectives[i].verb or verb
				if title and title ~= "" then
					quest.objectives[i].title = title
				end
				quest.objectives[i].points = points
			end
		end
		if #quest.objectives == 0 and not quest.complete then
			for i = 1, #data do
				local verb, title, points = ObjectiveFromData(db, data[i], playerMap, zoneIds)
				if verb then
					quest.objectives[#quest.objectives + 1] = {
						title = title or quest.name,
						verb = verb,
						points = points,
					}
				end
			end
		end
	end
	quest.turnin = TurninFor(db, record, playerMap, zoneIds, quest.name)
	local nextId = tonumber(record.nextQuestInChain)
	if nextId and nextId ~= 0 then
		local seen = {}
		local finishers = IdSetFrom(FinisherBuckets(record))
		quest.next = BuildChain(db, nextId, finishers, 1, seen, inLog, playerLevel, playerMap, zoneIds)
	end
end

local nodeCache

local function WorldPoint(uiMap, x, y)
	if not uiMap or not x or not y or not C_Map or not C_Map.GetWorldPosFromMapPos then
		return nil
	end
	if ns.IsSecret(x) or ns.IsSecret(y) or ns.IsSecret(uiMap) then
		return nil
	end
	local ok, first, second = pcall(C_Map.GetWorldPosFromMapPos, uiMap, { x = x / 100, y = y / 100 })
	if not ok then
		return nil
	end
	local continent, pos
	if type(first) == "number" and type(second) == "table" then
		continent, pos = first, second
	elseif type(first) == "table" then
		pos = first
		continent = 0
	end
	if not pos or ns.IsSecret(pos) then
		return nil
	end
	local wx, wy
	if pos.GetXY then
		local okPoint, a, b = pcall(pos.GetXY, pos)
		if okPoint and not ns.IsSecret(a) and not ns.IsSecret(b) then
			wx, wy = a, b
		end
	end
	if wx == nil and not ns.IsSecret(pos.x) and not ns.IsSecret(pos.y) then
		wx, wy = pos.x, pos.y
	end
	if type(wx) ~= "number" or type(wy) ~= "number" then
		return nil
	end
	return { c = continent, x = wx, y = wy }
end

local function KnownNodes(faction)
	if nodeCache then
		return nodeCache
	end
	local nodes = {}
	local factions = Enum and Enum.FlightPathFaction or {}
	local enemy = faction == "Alliance" and (factions.Horde or 1) or (factions.Alliance or 2)
	if C_TaxiMap and C_TaxiMap.GetTaxiNodesForMap then
		for _, continent in ipairs({ 1414, 1415 }) do
			local ok, list = pcall(C_TaxiMap.GetTaxiNodesForMap, continent)
			if ok and type(list) == "table" then
				for i = 1, #list do
					local info = list[i]
					if type(info) == "table" and not ns.IsSecret(info.nodeID) and not ns.IsSecret(info.faction) and not ns.Flag(info.isUndiscovered) and info.faction ~= enemy and info.position and info.nodeID then
						local px, py
						if info.position.GetXY and not ns.IsSecret(info.position) then
							local okPoint, a, b = pcall(info.position.GetXY, info.position)
							if okPoint and not ns.IsSecret(a) and not ns.IsSecret(b) then
								px, py = a, b
							end
						end
						if px == nil and not ns.IsSecret(info.position.x) then
							px, py = info.position.x, info.position.y
						end
						if type(px) == "number" and type(py) == "number" then
							local world = WorldPoint(continent, px * 100, py * 100)
							if world then
								world.name = ns.Text(info.name, nil)
								nodes[info.nodeID] = world
							end
						end
					end
				end
			end
		end
	end
	nodeCache = nodes
	return nodes
end

function ns.ForgetFlights()
	nodeCache = nil
end

function ns.TravelBetween(a, b)
	if not a or not b or not a.uiMap or not b.uiMap or not a.x or not b.x or not ns.Travel then
		return nil
	end
	local from = WorldPoint(a.uiMap, a.x, a.y)
	local to = WorldPoint(b.uiMap, b.x, b.y)
	if not from or not to then
		return nil
	end
	local faction = "Horde"
	if UnitFactionGroup then
		local ok, value = pcall(UnitFactionGroup, "player")
		if ok and not ns.IsSecret(value) and value == "Alliance" then
			faction = "Alliance"
		end
	end
	local key = faction == "Alliance" and "A" or "H"
	local seconds, info = ns.Travel.Seconds(from, to, {
		speed = PlayerSpeed(),
		nodes = KnownNodes(faction),
		times = ns.FlightTimes and ns.FlightTimes[key] or nil,
		transports = ns.Travel.TRANSPORTS[key],
	})
	if not seconds or not info or not info.flew then
		return nil
	end
	return { seconds = seconds, label = info.label }
end

local function ZoneName(reader)
	if not reader then
		return nil
	end
	local ok, value = pcall(reader)
	if not ok then
		return nil
	end
	return ns.Text(value, nil)
end

local function QuestieLoaded()
	if C_AddOns and C_AddOns.IsAddOnLoaded then
		local ok, loaded = pcall(C_AddOns.IsAddOnLoaded, "Questie")
		if ok and ns.Flag(loaded) then
			return true
		end
	end
	if IsAddOnLoaded then
		local ok, loaded = pcall(IsAddOnLoaded, "Questie")
		if ok and ns.Flag(loaded) then
			return true
		end
	end
	return type(QuestieLoader) == "table" or type(LibQuestieDB) == "table"
end

local function RewardXP(questID, index)
	if not GetQuestLogRewardXP then
		return nil
	end
	local function take(ok, value)
		if ok and not ns.IsSecret(value) and type(value) == "number" then
			return value
		end
		return nil
	end
	if questID then
		local xp = take(pcall(GetQuestLogRewardXP, questID))
		if xp ~= nil then
			return xp
		end
	end
	if SelectQuestLogEntry then
		pcall(SelectQuestLogEntry, index)
	end
	return take(pcall(GetQuestLogRewardXP))
end

local function ScanQuests()
	completedCache = nil
	zoneDB = QuestieModule("ZoneDB")
	local db = QuestieModule("QuestieDB")
	local zoneLabel = ZoneName(GetRealZoneText) or ZoneName(GetZoneText) or "this zone"
	local subzone = ZoneName(GetZoneText)
	local names = {}
	if zoneLabel and zoneLabel ~= "" then
		names[zoneLabel] = true
	end
	if subzone and subzone ~= "" then
		names[subzone] = true
	end
	local ids = {}
	local playerMod = QuestieModule("QuestiePlayer")
	if playerMod and type(playerMod.GetCurrentZoneId) == "function" then
		local ok, area = pcall(playerMod.GetCurrentZoneId, playerMod)
		area = ok and tonumber(area) or nil
		if area and area > 0 then
			ids[area] = true
			RememberZone(area)
			if parents[area] then
				ids[parents[area]] = true
			end
			local areaName = namesById[area]
			if areaName and areaName ~= false then
				names[areaName] = true
			end
			if parents[area] and namesById[parents[area]] and namesById[parents[area]] ~= false then
				names[namesById[parents[area]]] = true
			end
		end
	end

	local playerLevel = 1
	if UnitLevel then
		local ok, level = pcall(UnitLevel, "player")
		level = ok and ns.Num(level, nil) or nil
		if level and level > 0 then
			playerLevel = level
		end
	end
	local player, playerMap = PlayerPosition()
	scanPlayer = player
	scanZoneIds = ids
	local green = 8
	if GetQuestGreenRange then
		local ok, range = pcall(GetQuestGreenRange)
		range = ok and ns.Num(range, nil) or nil
		if range and range > 0 then
			green = range
		end
	end

	local previous
	if GetQuestLogSelection then
		local ok, value = pcall(GetQuestLogSelection)
		previous = ok and ns.Num(value, nil) or nil
	end
	local opened = ExpandCollapsed()
	local quests = {}
	local inLog = {}
	local header
	local count = NumEntries()
	for index = 1, count do
		local row = ReadTitle(index)
		if row and row.isHeader then
			header = row.title
		elseif row and row.title and row.title ~= "" then
			local questID = row.questID
			if not questID and GetQuestID and SelectQuestLogEntry then
				pcall(SelectQuestLogEntry, index)
				local ok, id = pcall(GetQuestID)
				questID = ok and ns.Num(id, nil) or nil
			end
			local objectives = ReadObjectives(index, questID)
			if row.complete then
				for i = 1, #objectives do
					objectives[i].done = true
				end
			end
			for i = 1, #objectives do
				objectives[i].title = CleanText(objectives[i].text) or row.title
				objectives[i].points = {}
			end
			local xp = RewardXP(questID, index)
			local known = xp ~= nil
			local level = row.level
			if not known then
				xp = ns.Planner.EstimateXP(level > 0 and level or playerLevel, playerLevel)
			end
			local quest = {
				id = questID,
				name = row.title,
				level = level,
				header = header,
				complete = row.complete,
				failed = row.failed,
				objectives = objectives,
				xp = xp or 0,
				xpEstimated = not known,
			}
			if questID then
				inLog[questID] = true
			end
			quests[#quests + 1] = quest
		end
	end
	for i = 1, #quests do
		AttachQuestie(quests[i], db, playerLevel, playerMap, ids, inLog)
		MarkDungeon(quests[i], db)
	end
	RestoreCollapsed(opened)
	if previous and previous > 0 and SelectQuestLogEntry then
		SelectQuestLogEntry(previous)
	end

	local dbSettings = ns.Settings()
	return ns.Planner.Build({
		playerLevel = playerLevel,
		greenRange = green,
		maxLevelsAbove = dbSettings.maxLevelsAbove,
		includeLowLevel = dbSettings.includeLowLevel,
		omitDungeons = dbSettings.omitDungeons,
		scope = dbSettings.scope,
		useFlights = dbSettings.useFlights,
		player = player,
		speed = PlayerSpeed(),
		zone = { ids = ids, names = names, parents = parents },
		zoneLabel = zoneLabel,
		parents = parents,
		namesById = namesById,
		quests = quests,
		yards = MakeYards(),
		travel = ns.TravelBetween,
		questie = db and true or false,
		questiePresent = QuestieLoaded(),
		tomtom = TomTom and true or false,
	})
end

ns.ScanQuests = ScanQuests
ns.PlayerPosition = PlayerPosition

function ns.InvalidateCompleted()
	completedCache = nil
end
