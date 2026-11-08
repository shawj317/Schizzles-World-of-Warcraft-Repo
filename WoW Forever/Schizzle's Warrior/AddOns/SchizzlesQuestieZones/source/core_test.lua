-- Loads Core.lua against a stand-in for the Forever client. Lua 5.1.
-- Run from this folder's parent: lua5.1 source/core_test.lua

local fails = 0
local function check(ok, what)
	print((ok and "ok   " or "FAIL ") .. what)
	if not ok then
		fails = fails + 1
	end
end

dofile("SchizzlesQuestieZones/Logic.lua")
local L = SchizzlesQuestieZonesLogic

local function copyZones(collapses)
	local zones = {}
	for key, value in pairs(collapses) do
		zones[key] = value
	end
	return zones
end

-- One addon load. version nil means the metadata call returns nothing.
local function boot(version, collapses, saved)
	local state = { now = 0, inCombat = false, updates = 0, chat = {} }
	local zones = copyZones(collapses)
	local env = {
		SchizzlesQuestieZonesLogic = L,
		SchizzlesQuestieZonesCharDB = saved,
		SlashCmdList = {},
	}
	function env.GetTime()
		return state.now
	end
	function env.InCombatLockdown()
		return state.inCombat
	end
	function env.print(text)
		state.chat[#state.chat + 1] = text
	end
	env.C_Timer = {
		NewTicker = function(_, fn)
			state.ticker = fn
			return { Cancel = function() end }
		end,
	}
	env.C_AddOns = {
		IsAddOnLoaded = function(name)
			return name == "Questie" or name == "SchizzlesQuestieZones"
		end,
		GetAddOnMetadata = function(name, field)
			if name == "Questie" and field == "Version" then
				return version
			end
		end,
	}
	function env.CreateFrame()
		local widget = {}
		function widget:RegisterEvent() end
		function widget:SetScript(_, fn)
			widget.handler = fn
		end
		state.frame = widget
		return widget
	end
	env.Questie = {
		db = {
			char = { collapsedZones = zones, collapsedQuests = { [55] = true } },
			profile = { trackerSortObjectives = "byZone", collapseCompletedQuests = true, marker = "keep" },
			global = { questieLocale = "enUS" },
		},
		API = {
			RegisterOnReady = function(callback)
				state.ready = callback
			end,
		},
	}
	env.QuestieLoader = {
		_modules = {
			QuestieTracker = {
				started = true,
				Update = function()
					state.updates = state.updates + 1
				end,
			},
		},
	}
	-- Core reads Questie through _G. Point that name at this character's stand-in.
	env._G = env
	setmetatable(env, { __index = _G })
	local chunk = assert(loadfile("SchizzlesQuestieZones/Core.lua"))
	setfenv(chunk, env)
	chunk("SchizzlesQuestieZones")
	state.frame.handler(state.frame, "ADDON_LOADED", "SchizzlesQuestieZones")
	state.zones = zones
	state.env = env
	return state
end

local function said(state, needle)
	for i = 1, #state.chat do
		if state.chat[i]:find(needle, 1, true) then
			return true
		end
	end
	return false
end

local function retrack(zones, groups)
	for i = 1, #groups do
		zones[groups[i]] = nil
	end
end

local function pump(state, steps)
	for _ = 1, steps do
		state.now = state.now + 0.1
		state.ticker()
	end
end

-- Fresh character, nothing collapsed.
local fresh = boot("12.5.0", {})
retrack(fresh.zones, { "Durotar" })
fresh.now = 1
fresh.ready()
pump(fresh, 8)
check(fresh.env.Questie.db.char.collapsedZones.Durotar ~= true, "fresh state stays expanded through reload")
check(fresh.env.SchizzlesQuestieZonesCharDB.trusted == true, "fresh character still records that the addon ran")
check(fresh.env.Questie.db.profile.marker == "keep", "fresh login leaves the profile alone")

-- Collapse, reload, restore.
local collapsed = boot("12.5.0", { Durotar = true })
local zoneTable = collapsed.zones
check(collapsed.env.SchizzlesQuestieZonesCharDB.collapsed.Durotar == true, "collapse is copied before the retrack")
retrack(collapsed.zones, { "Durotar" })
check(collapsed.zones.Durotar == nil, "retrack clears the zone")
collapsed.now = 3
collapsed.ready()
check(collapsed.zones.Durotar == true and collapsed.updates == 1, "ready restores the zone and redraws")
check(zoneTable == collapsed.env.Questie.db.char.collapsedZones, "restore keeps Questie's table")
check(collapsed.env.Questie.db.char.collapsedQuests[55] == true, "quest collapse is untouched")
pump(collapsed, 8)
check(collapsed.zones.Durotar == true, "the zone stays collapsed after startup")

-- Expand, then the next reload stays expanded.
collapsed.zones.Durotar = nil
collapsed.ticker()
check(collapsed.env.SchizzlesQuestieZonesCharDB.collapsed.Durotar == nil, "an expand is written to this character")
local expanded = boot("12.6.4", { Durotar = true }, collapsed.env.SchizzlesQuestieZonesCharDB)
retrack(expanded.zones, { "Durotar" })
expanded.now = 1
expanded.ready()
pump(expanded, 8)
check(expanded.zones.Durotar ~= true, "reload after an expand stays expanded")

-- Independent zones and a new zone.
local both = boot("12.6.0", { Durotar = true, ["Elwynn Forest"] = true })
retrack(both.zones, { "Durotar", "Elwynn Forest" })
both.now = 2
both.ready()
pump(both, 8)
check(both.zones.Durotar == true and both.zones["Elwynn Forest"] == true, "each collapsed zone comes back")
both.zones.Durotar = nil
both.ticker()
check(both.env.SchizzlesQuestieZonesCharDB.collapsed.Durotar == nil, "a new quest opens only its zone")
check(both.env.SchizzlesQuestieZonesCharDB.collapsed["Elwynn Forest"] == true, "the other zone stays collapsed")
both.zones.Mulgore = nil
check(both.env.SchizzlesQuestieZonesCharDB.collapsed.Mulgore ~= true, "a new zone is not stored collapsed")
check(both.zones["Elwynn Forest"] == true, "a refresh leaves the collapsed zone collapsed")

-- Two characters.
local hero = boot("12.5.1", { Durotar = true })
local alt = boot("12.5.1", { ["Elwynn Forest"] = true })
retrack(hero.zones, { "Durotar" })
retrack(alt.zones, { "Elwynn Forest" })
hero.now, alt.now = 1, 1
hero.ready()
alt.ready()
pump(hero, 8)
pump(alt, 8)
check(hero.zones.Durotar == true and hero.zones["Elwynn Forest"] ~= true, "one character restores Durotar")
check(alt.zones["Elwynn Forest"] == true and alt.zones.Durotar ~= true, "the other character restores Elwynn Forest")
check(hero.env.SchizzlesQuestieZonesCharDB ~= alt.env.SchizzlesQuestieZonesCharDB, "characters do not share a save")

-- A wiped Questie save still restores from this character's copy.
hero.frame.handler(hero.frame, "PLAYER_LOGOUT")
local wiped = boot("12.5.0", {}, hero.env.SchizzlesQuestieZonesCharDB)
retrack(wiped.zones, { "Durotar" })
wiped.now = 4
wiped.ready()
pump(wiped, 8)
check(wiped.zones.Durotar == true, "relog restores the zone Questie saved as expanded")

-- Outside the checked versions, and with no version string, nothing is written.
local old = boot("12.4.0", { Durotar = true })
check(old.env.SchizzlesQuestieZonesCharDB == nil, "Questie 12.4.0 does not get a save")
check(old.zones.Durotar == true and old.ready == nil, "Questie 12.4.0 is not hooked")
check(said(old, "12.4.0"), "Questie 12.4.0 is named in the refusal")
local missing = boot(nil, { Durotar = true })
check(missing.env.SchizzlesQuestieZonesCharDB == nil, "a missing version does not get a save")
check(said(missing, "version could not be read"), "a missing version says what is needed")

if fails > 0 then
	print(fails .. " failed")
	os.exit(1)
end
print("all passed")
