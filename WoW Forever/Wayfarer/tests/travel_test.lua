-- Flight time beats a long walk. Lua 5.1: lua5.1 travel_test.lua
local function script_dir()
	local source = debug.getinfo(1, "S").source
	if source:sub(1, 1) == "@" then
		source = source:sub(2)
	end
	return source:match("^(.*)[/\\]") or "."
end

local root = script_dir() .. "/../AddOns/Wayfarer/"
local ns = {}
assert(loadfile(root .. "Travel.lua"))("Wayfarer", ns)
assert(loadfile(root .. "FlightData.lua"))("Wayfarer", ns)

local fails = 0
local function check(cond, msg)
	if not cond then
		fails = fails + 1
		print("FAIL " .. msg)
	end
end

local Travel = ns.Travel
local from = { c = 1, x = 0, y = 0 }
local to = { c = 1, x = 10000, y = 0 }
local nodes = {
	[1] = { c = 1, x = 100, y = 0, name = "Crossroads" },
	[2] = { c = 1, x = 9900, y = 0, name = "Orgrimmar" },
}
local times = { [1] = { [2] = 90 } }
local seconds, info = Travel.Seconds(from, to, { speed = 7, nodes = nodes, times = times })
local walk = 10000 / 7
check(seconds and seconds < walk / 2, "flying beats walking the same continent")
check(info and info.flew and info.mode == "fly", "the faster trip is a flight")
check(info.label == "Fly Crossroads → Orgrimmar, ~2m", "the hop is named")

local boatSeconds, boat = Travel.Seconds(
	{ c = 1, x = 0, y = 0 },
	{ c = 2, x = 500, y = 0 },
	{
		speed = 7,
		nodes = {
			[7] = { c = 1, x = 50, y = 0, name = "Menethil Harbor" },
			[26] = { c = 2, x = 80, y = 0, name = "Auberdine" },
		},
		times = {},
		transports = Travel.TRANSPORTS.A,
	}
)
check(boatSeconds and boatSeconds < 500, "a boat crosses continents")
check(boat and boat.mode == "boat" and string.find(boat.label, "Boat", 1, true), "the crossing is labeled as a boat")
check(walk ~= nil and Travel.Seconds({ c = 1, x = 0, y = 0 }, { c = 2, x = 0, y = 0 }, { speed = 7 }) == nil, "walking cannot change continents")
check(ns.FlightTimes and ns.FlightTimes.H and ns.FlightTimes.H[23] and ns.FlightTimes.H[23][22], "measured Horde flight data is present")

if fails > 0 then
	print(fails .. " failed")
	os.exit(1)
end
print("OK")
