-- Wayfarer still plans a route with Questie and TomTom absent.
-- Lua 5.1: lua5.1 deps_test.lua
local function script_dir()
	local source = debug.getinfo(1, "S").source
	if source:sub(1, 1) == "@" then
		source = source:sub(2)
	end
	return source:match("^(.*)[/\\]") or "."
end

local root = script_dir() .. "/../AddOns/Wayfarer/"
local ns = {}
local function load(name)
	assert(loadfile(root .. name))("Wayfarer", ns)
end

load("Secrets.lua")
load("Planner.lua")
load("Saved.lua")
load("QuestLog.lua")

QuestieLoader = nil
LibQuestieDB = nil
TomTom = nil
WayfarerDB = {}

local fails = 0
local function check(cond, msg)
	if not cond then
		fails = fails + 1
		print("FAIL " .. msg)
	end
end

local ok, plan = pcall(ns.ScanQuests)
check(ok, "scan does not throw without Questie or TomTom: " .. tostring(plan))
check(type(plan) == "table" and type(plan.steps) == "table", "a plan still comes back")
local questieNote, tomtomNote = false, false
for i = 1, #(plan and plan.notices or {}) do
	local text = plan.notices[i]
	if string.find(text, "Questie is not installed", 1, true) then
		questieNote = true
	end
	if string.find(text, "TomTom is not installed", 1, true) then
		tomtomNote = true
	end
end
check(questieNote, "missing Questie is a notice, not a crash")
check(tomtomNote, "missing TomTom is a notice, not a crash")

local aimed = ns.Planner.Build({
	playerLevel = 20,
	player = { x = 60, y = 40, uiMap = 1413 },
	zone = { ids = { [17] = true }, names = { ["The Barrens"] = true }, parents = {} },
	quests = {
		{
			name = "No pins",
			level = 20,
			header = "The Barrens",
			objectives = { { title = "Somewhere", verb = "collect", points = {} } },
		},
	},
	questie = false,
	questiePresent = false,
	tomtom = false,
})
local step = aimed.steps[1]
check(step and not step.x and not step.y, "no addon and no coordinates means no pin")

if fails > 0 then
	print(fails .. " failed")
	os.exit(1)
end
print("OK")
