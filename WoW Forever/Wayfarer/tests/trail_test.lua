-- Ant trail spacing and pooling. Lua 5.1: lua5.1 trail_test.lua
local function script_dir()
	local source = debug.getinfo(1, "S").source
	if source:sub(1, 1) == "@" then
		source = source:sub(2)
	end
	return source:match("^(.*)[/\\]") or "."
end

local ns = {}
assert(loadfile(script_dir() .. "/../AddOns/Wayfarer/Trail.lua"))("Wayfarer", ns)

local fails = 0
local function check(cond, msg)
	if not cond then
		fails = fails + 1
		print("FAIL " .. msg)
	end
end

local function near(a, b)
	return math.abs(a - b) < 0.02
end

local line = { { x = 0, y = 0 }, { x = 100, y = 0 } }
local still = ns.TrailSamples(line, 25, 0, 20)
check(#still == 4, "phase 0 places four dots on a 100px leg")
check(near(still[1].x, 0) and near(still[2].x, 25) and near(still[4].x, 75), "dots are 25px apart and stop before the end")

local moved = ns.TrailSamples(line, 25, 10, 20)
check(#moved == 4 and near(moved[1].x, 10) and near(moved[4].x, 85), "phase marches the dots forward")

local capped = ns.TrailSamples(line, 10, 0, 2)
check(#capped == 2, "the dot cap widens the gap instead of overflowing")
check(near(capped[1].x, 0) and near(capped[2].x, 50), "capped dots still cover the leg")

check(#ns.TrailSamples({ { x = 1, y = 1 } }, 10, 0, 8) == 0, "one point has no trail")
check(#ns.TrailSamples(nil, 10, 0, 8) == 0, "nil points have no trail")

local bend = ns.TrailSamples({ { x = 0, y = 0 }, { x = 100, y = 0 }, { x = 100, y = 100 } }, 50, 0, 20)
check(#bend == 4, "a bend is one path")
check(near(bend[3].x, 100) and near(bend[3].y, 0), "the third dot is the corner")
check(near(bend[4].x, 100) and near(bend[4].y, 50), "the path continues onto the next leg")

local pool = {}
local made = 0
local function make()
	made = made + 1
	return { id = made }
end
local a = ns.Claim(pool, make)
local b = ns.Claim(pool, make)
local c = ns.Claim(pool, make)
check(made == 3 and #pool == 3, "new claims create entries")
ns.ReleaseAll(pool)
local again = ns.Claim(pool, make)
local fourth = ns.Claim(pool, make)
check(again == a and fourth == b and made == 3, "released entries are reused")

if fails > 0 then
	print(fails .. " failed")
	os.exit(1)
end
print("OK")
