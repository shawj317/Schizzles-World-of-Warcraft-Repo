local _, ns = ...

-- Wayfarer's own TomTom waypoints. Other addons' waypoints are left alone.
-- A route replace removes the previous Wayfarer ids, then adds the new ones.

ns.WAYPOINT_FROM = "Wayfarer"

function ns.WaypointOptions(title, crazy)
	return {
		title = title or "Wayfarer",
		persistent = false,
		minimap = crazy and true or false,
		world = true,
		crazy = crazy and true or false,
		from = ns.WAYPOINT_FROM,
		silent = true,
		cleardistance = 10,
	}
end

function ns.WaypointValid(tomtom, uid)
	if uid == nil or type(tomtom) ~= "table" or type(tomtom.IsValidWaypoint) ~= "function" then
		return false
	end
	local ok, valid = pcall(tomtom.IsValidWaypoint, tomtom, uid)
	return ok and valid and true or false
end

local function Consider(found, seen, uid, data)
	if uid == nil or seen[uid] then
		return
	end
	local from = type(data) == "table" and data.from
	if from == nil and type(uid) == "table" then
		from = uid.from
	end
	if from == ns.WAYPOINT_FROM then
		seen[uid] = true
		found[#found + 1] = uid
	end
end

function ns.CollectWayfarer(tomtom)
	local found, seen = {}, {}
	local waypoints = type(tomtom) == "table" and tomtom.waypoints
	if type(waypoints) ~= "table" then
		return found
	end
	for key, value in pairs(waypoints) do
		if type(value) ~= "table" then
			-- skip
		elseif value.from or value.x or value.m then
			Consider(found, seen, key, value)
		else
			for uid, data in pairs(value) do
				Consider(found, seen, uid, data)
			end
		end
	end
	return found
end

function ns.RemoveOurWaypoints(tomtom, cache)
	local seen = {}
	local function remove(uid)
		if uid == nil or seen[uid] then
			return
		end
		seen[uid] = true
		if type(tomtom) == "table" and type(tomtom.RemoveWaypoint) == "function" then
			pcall(tomtom.RemoveWaypoint, tomtom, uid)
		end
	end
	for i = 1, #(cache or {}) do
		local uid = cache[i]
		if type(uid) == "table" and uid.uid then
			uid = uid.uid
		end
		if ns.WaypointValid(tomtom, uid) or uid ~= nil then
			remove(uid)
		end
	end
	local tagged = ns.CollectWayfarer(tomtom)
	for i = 1, #tagged do
		remove(tagged[i])
	end
	return {}
end

local function StepTitle(step, index)
	return (index or 1) .. ". " .. ((type(step) == "table" and (step.title or step.questName)) or "Step")
end

local function AddOne(tomtom, step, index, crazy)
	if type(step) ~= "table" or not step.x or not step.y then
		return nil
	end
	local title = StepTitle(step, index)
	local uid
	if step.uiMap and type(tomtom.AddWaypoint) == "function" then
		local ok, value = pcall(tomtom.AddWaypoint, tomtom, step.uiMap, step.x / 100, step.y / 100, ns.WaypointOptions(title, crazy))
		if ok and value ~= nil then
			uid = value
		end
	end
	if uid == nil and step.areaId and type(tomtom.AddZWaypoint) == "function" then
		local ok, value = pcall(tomtom.AddZWaypoint, tomtom, 0, step.areaId, step.x, step.y, title, false, true, true, false)
		if ok and value ~= nil then
			uid = value
		end
	end
	if uid == nil then
		return nil
	end
	return uid, title
end

function ns.AimArrow(tomtom, uid, title)
	if uid == nil or type(tomtom) ~= "table" then
		return false
	end
	if type(tomtom.SetCrazyArrow) == "function" then
		pcall(tomtom.SetCrazyArrow, tomtom, uid, 10, title)
	end
	if type(tomtom.SetClosestWaypoint) == "function" then
		pcall(tomtom.SetClosestWaypoint, tomtom)
	end
	return true
end

function ns.WaypointPlanKey(steps, allSteps, focusIndex)
	steps = steps or {}
	focusIndex = tonumber(focusIndex) or 1
	if focusIndex < 1 or focusIndex > #steps then
		focusIndex = 1
	end
	local parts = {}
	local function add(step, index, crazy)
		if type(step) ~= "table" or not step.x or not step.y then
			return
		end
		parts[#parts + 1] = table.concat({
			crazy and "1" or "0",
			tostring(index),
			tostring(step.uiMap or 0),
			string.format("%.2f", step.x),
			string.format("%.2f", step.y),
		}, ":")
	end
	if allSteps then
		for i = 1, #steps do
			add(steps[i], i, i == focusIndex)
		end
	else
		add(steps[focusIndex], focusIndex, true)
	end
	return table.concat(parts, "|")
end

function ns.CacheStillValid(tomtom, cache, key)
	if type(key) ~= "string" or key == "" then
		return false
	end
	local count = 0
	for i = 1, #(cache or {}) do
		local uid = cache[i]
		if type(uid) == "table" and uid.uid then
			uid = uid.uid
		end
		if not ns.WaypointValid(tomtom, uid) then
			return false
		end
		count = count + 1
	end
	local expected = 0
	for _ in string.gmatch(key, "[^|]+") do
		expected = expected + 1
	end
	return count == expected and count > 0
end

-- allSteps: a waypoint for every step. Otherwise only the focused step.
-- Always drops Wayfarer's previous waypoints first, including ones TomTom
-- still has after our cache was cleared from outside.
function ns.ReplaceWaypoints(tomtom, cache, steps, allSteps, focusIndex)
	if type(tomtom) ~= "table" then
		return {}
	end
	ns.RemoveOurWaypoints(tomtom, cache)
	steps = steps or {}
	focusIndex = tonumber(focusIndex) or 1
	if focusIndex < 1 or focusIndex > #steps then
		focusIndex = 1
	end
	local placed = {}
	local arrowUid, arrowTitle
	if allSteps then
		for i = 1, #steps do
			local uid, title = AddOne(tomtom, steps[i], i, i == focusIndex)
			if uid then
				placed[#placed + 1] = { uid = uid, index = i, title = title }
				if i == focusIndex then
					arrowUid, arrowTitle = uid, title
				end
			end
		end
	else
		local step = steps[focusIndex]
		local uid, title = AddOne(tomtom, step, focusIndex, true)
		if uid then
			placed[1] = { uid = uid, index = focusIndex, title = title }
			arrowUid, arrowTitle = uid, title
		end
	end
	if arrowUid then
		ns.AimArrow(tomtom, arrowUid, arrowTitle)
	end
	return placed, arrowUid
end
