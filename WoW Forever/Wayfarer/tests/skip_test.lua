-- Skip a step until the quest list changes or the skips are cleared.
-- Lua 5.1: lua5.1 skip_test.lua
local function script_dir()
	local source = debug.getinfo(1, "S").source
	if source:sub(1, 1) == "@" then
		source = source:sub(2)
	end
	return source:match("^(.*)[/\\]") or "."
end

local ns = {}
assert(loadfile(script_dir() .. "/../AddOns/Wayfarer/Skip.lua"))("Wayfarer", ns)

local fails = 0
local function check(cond, msg)
	if not cond then
		fails = fails + 1
		print("FAIL " .. msg)
	end
end

local steps = {
	{ questId = 1, title = "Near", verb = "kill" },
	{ questId = 1, title = "Far", verb = "kill" },
	{ questId = 2, title = "Gryan", verb = "turn in" },
}
local skipped = {}
ns.SkipStep(skipped, steps[1])
local left = ns.WithoutSkips(steps, skipped)
check(#left == 2 and left[1].title == "Far", "skipping the first step advances the route")
check(left[2].title == "Gryan", "later steps stay in order")
ns.SkipStep(skipped, steps[1])
check(#ns.WithoutSkips(steps, skipped) == 2, "skipping the same step twice is one skip")
ns.ClearSkips(skipped)
check(#ns.WithoutSkips(steps, skipped) == 3, "clear puts every step back")

local same = ns.QuestSetKey(steps)
local changed = ns.QuestSetKey({ steps[2], steps[3] })
check(same == ns.QuestSetKey({ steps[3], steps[1], steps[2] }), "quest set ignores step order")
check(same ~= changed, "a removed quest changes the set")

if fails > 0 then
	print(fails .. " failed")
	os.exit(1)
end
print("OK")
