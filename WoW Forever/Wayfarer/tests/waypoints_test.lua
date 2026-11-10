-- TomTom waypoints do not pile up, and a clear can be replaced.
-- Lua 5.1: lua5.1 waypoints_test.lua
local function script_dir()
	local source = debug.getinfo(1, "S").source
	if source:sub(1, 1) == "@" then
		source = source:sub(2)
	end
	return source:match("^(.*)[/\\]") or "."
end

local ns = {}
assert(loadfile(script_dir() .. "/../AddOns/Wayfarer/Waypoints.lua"))("Wayfarer", ns)

local fails = 0
local function check(cond, msg)
	if not cond then
		fails = fails + 1
		print("FAIL " .. msg)
	end
end

local function Stub()
	local live = {}
	local seq = 0
	local tom = { waypoints = {}, arrow = nil, adds = 0 }
	function tom:AddWaypoint(map, x, y, opts)
		seq = seq + 1
		self.adds = self.adds + 1
		local uid = seq
		local row = { uid = uid, from = opts.from, title = opts.title, crazy = opts.crazy, minimap = opts.minimap, map = map, x = x, y = y }
		live[uid] = row
		self.waypoints[map] = self.waypoints[map] or {}
		self.waypoints[map][uid] = row
		return uid
	end
	function tom:RemoveWaypoint(uid)
		live[uid] = nil
		for _, set in pairs(self.waypoints) do
			set[uid] = nil
		end
	end
	function tom:IsValidWaypoint(uid)
		return live[uid] ~= nil
	end
	function tom:SetCrazyArrow(uid)
		self.arrow = uid
	end
	function tom:count()
		local n = 0
		for _ in pairs(live) do
			n = n + 1
		end
		return n
	end
	function tom:clear()
		for uid in pairs(live) do
			live[uid] = nil
		end
		self.waypoints = {}
		self.arrow = nil
	end
	return tom
end

local step = { title = "Kodo Liver", x = 49.4, y = 43, uiMap = 1413 }
local other = { title = "Gryan", x = 56, y = 47, uiMap = 40 }
local tom = Stub()
tom.waypoints[1] = { [900] = { from = "HandyNotes", title = "Herb" } }
local cache = {}
for _ = 1, 5 do
	cache = ns.ReplaceWaypoints(tom, cache, { step, other }, false, 1)
end
check(tom:count() == 1, "five recalcs leave one Wayfarer arrow")
local wayfarer = 0
for _, set in pairs(tom.waypoints) do
	for _, row in pairs(set) do
		if row.from == "Wayfarer" then
			wayfarer = wayfarer + 1
		end
	end
end
check(wayfarer == 1, "only one Wayfarer waypoint remains")
local mini = 0
for _, set in pairs(tom.waypoints) do
	for _, row in pairs(set) do
		if row.from == "Wayfarer" and row.minimap then
			mini = mini + 1
		end
	end
end
check(mini == 1, "only the current step gets a TomTom minimap icon")
check(tom.arrow ~= nil and ns.WaypointValid(tom, tom.arrow), "the crazy arrow points at a live waypoint")
local key = ns.WaypointPlanKey({ step }, false, 1)
check(ns.CacheStillValid(tom, cache, key), "an unchanged step can keep its waypoint")

tom:clear()
tom.waypoints[1] = { [900] = { from = "HandyNotes", title = "Herb" } }
check(not ns.CacheStillValid(tom, cache, key), "an external clear invalidates the cache")
cache = ns.ReplaceWaypoints(tom, cache, { step }, false, 1)
check(tom:count() == 1 and tom.arrow ~= nil, "sending the step again recreates the arrow")
check(tom.waypoints[1][900] ~= nil, "the other addon's waypoint is still there")

local many = Stub()
local cache2 = {}
for _ = 1, 5 do
	cache2 = ns.ReplaceWaypoints(many, cache2, { step, other }, true, 1)
end
check(many:count() == 2, "every-step mode replaces the set instead of stacking")
local manyMini = 0
for _, set in pairs(many.waypoints) do
	for _, row in pairs(set) do
		if row.minimap then
			manyMini = manyMini + 1
		end
	end
end
check(manyMini == 1, "extra TomTom steps stay off the minimap")

if fails > 0 then
	print(fails .. " failed")
	os.exit(1)
end
print("OK")
