-- Offline simulation of Schizzle's Questie Zones. Lua 5.1.
-- Run from the addon folder's parent: lua5.1 source/test.lua
-- Models the character table only. It does not load Questie.

local fails = 0
local function check(ok, what)
	print((ok and "ok   " or "FAIL ") .. what)
	if not ok then
		fails = fails + 1
	end
end

dofile("SchizzlesQuestieZones/Logic.lua")
local L = SchizzlesQuestieZonesLogic

local function setHas(set, key)
	return set[key] == true
end

local function count(set)
	local n = 0
	for _ in pairs(set) do
		n = n + 1
	end
	return n
end

-- Questie's login retrack clears the group of each native-watched quest.
local function startupRetrack(live, groups)
	for i = 1, #groups do
		if live[groups[i]] == true then
			live[groups[i]] = nil
		end
	end
end

-- A refresh reads the table and does not clear it.
local function groupsExpandedOnRefresh(live, groups)
	local expanded = {}
	for i = 1, #groups do
		local name = groups[i]
		if live[name] ~= true then
			expanded[#expanded + 1] = name
		end
	end
	return expanded
end

local function newChar(collapses, trusted)
	local live = {}
	for key in pairs(collapses) do
		live[key] = true
	end
	local own = {}
	for key in pairs(collapses) do
		own[key] = true
	end
	local quests = { [100] = true }
	local profile = {
		trackerSortObjectives = "byZone",
		collapseCompletedQuests = true,
		trackerEnabled = true,
		marker = "account",
	}
	local db = {
		char = { collapsedZones = live, collapsedQuests = quests },
		profile = profile,
		global = { questieLocale = "enUS" },
	}
	local saved = L.ChooseSaved(live, trusted and own or {}, trusted and true or false)
	local session = L.NewSession(saved)
	return session, db
end

local function run(session, db, now, inCombat)
	return L.Tick(session, db.char.collapsedZones, now, inCombat)
end

local function settle(session, db, start, inCombat)
	local now = start or 0
	local last
	for _ = 1, 20 do
		now = now + 0.1
		last = run(session, db, now, inCombat and true or false)
		if last == "settled" then
			return last, now
		end
	end
	return last, now
end

-- Version gate. Unknown builds change nothing.
check(L.VersionSupported("12.5.0"), "12.5.0 is supported")
check(L.VersionSupported("12.5.1"), "12.5.1 is supported")
check(L.VersionSupported("12.6.0"), "12.6.0 is supported")
check(L.VersionSupported("12.6.4"), "12.6.4 is supported")
check(not L.VersionSupported("12.4.0"), "12.4.0 is refused")
check(not L.VersionSupported("12.7.0"), "12.7.0 is refused")
check(not L.VersionSupported("v12.5.0"), "a v prefix is refused")
check(not L.VersionSupported(nil), "a missing version is refused")

local ok, reason = L.Compatibility(nil, true, true)
check(not ok and reason:find("version could not be read", 1, true), "missing version says what to read")
ok, reason = L.Compatibility("12.7.0", true, true)
check(not ok and reason:find("12.7.0", 1, true) and reason:find("Nothing was changed", 1, true), "12.7.0 is reported and left alone")
ok, reason = L.Compatibility("12.5.0", false, true)
check(not ok and reason:find("RegisterOnReady", 1, true), "missing ready callback is refused")
ok, reason = L.Compatibility("12.6.4", true, false)
check(not ok and reason:find("collapsedZones", 1, true), "a non-table zone store is refused")
ok = L.Compatibility("12.5.0", true, true)
check(ok == true, "12.5.0 with the ready callback and zone table is accepted")

-- Fresh character: nothing collapsed, reload leaves every group expanded.
local session, db = newChar({}, false)
local live = db.char.collapsedZones
local profile = db.profile
local quests = db.char.collapsedQuests
L.MarkReady(session, 0)
startupRetrack(live, { "Durotar", "Elwynn Forest" })
local last = settle(session, db)
check(last == "settled" and count(live) == 0 and count(session.saved) == 0, "fresh state stays expanded")
check(profile.marker == "account" and profile.collapseCompletedQuests == true, "fresh reload leaves the profile alone")

-- Collapse, then a reload restores that zone only.
session, db = newChar({ Durotar = true }, false)
live = db.char.collapsedZones
profile = db.profile
quests = db.char.collapsedQuests
local zoneTable = live
check(zoneTable.Durotar == true, "a collapse is on the character table before reload")
L.MarkReady(session, 0)
startupRetrack(live, { "Durotar" })
check(live.Durotar == nil, "the login retrack clears the collapsed zone")
check(setHas(session.saved, "Durotar"), "the remembered set still has the zone after the clear")
last = settle(session, db)
check(last == "settled" and live.Durotar == true, "reload restores the collapsed zone")
check(live == zoneTable, "restore writes into Questie's table")
check(quests[100] == true and profile.trackerSortObjectives == "byZone", "quest collapse and sort stay with Questie")
check(profile.marker == "account" and db.global.questieLocale == "enUS", "account and global settings are not written")

-- Expand, then a reload stays expanded.
session.saved = L.CollapsedSet({})
local own = {}
L.WriteSet(own, session.saved)
session, db = newChar({}, false)
-- Trusted memory from the expand wins over a stale Questie collapse.
db.char.collapsedZones.Durotar = true
session = L.NewSession(L.ChooseSaved(db.char.collapsedZones, own, true))
live = db.char.collapsedZones
L.MarkReady(session, 0)
startupRetrack(live, { "Durotar" })
last = settle(session, db)
check(last == "settled" and live.Durotar ~= true and not setHas(session.saved, "Durotar"), "an expand stays expanded across reload")

-- Two zones stay independent.
session, db = newChar({ Durotar = true }, false)
live = db.char.collapsedZones
live["Elwynn Forest"] = nil
L.MarkReady(session, 0)
startupRetrack(live, { "Durotar", "Elwynn Forest" })
last = settle(session, db)
check(live.Durotar == true and live["Elwynn Forest"] ~= true, "one collapsed zone does not collapse the other")

-- Sort-mode header is its own key.
session, db = newChar({ ["Quests (By Level)"] = true }, false)
live = db.char.collapsedZones
L.MarkReady(session, 0)
startupRetrack(live, { "Quests (By Level)" })
last = settle(session, db)
check(live["Quests (By Level)"] == true and live.Durotar ~= true, "a by-level header restores on its own key")

-- Achievements stay collapsed when the quest retrack only clears a zone.
session, db = newChar({ Durotar = true, Achievements = true }, false)
live = db.char.collapsedZones
L.MarkReady(session, 0)
startupRetrack(live, { "Durotar" })
last = settle(session, db)
check(live.Durotar == true and live.Achievements == true, "achievements stay collapsed when quests are retracked")

-- Before Questie is ready, a tick does not treat the table as settled.
session, db = newChar({ Durotar = true }, false)
check(run(session, db, 1, false) == "idle" and session.phase == "startup", "ticks wait until Questie is ready")

-- Combat at login: a click is kept, and the retrack after combat restores the rest.
session, db = newChar({ Durotar = true, ["Elwynn Forest"] = true }, false)
live = db.char.collapsedZones
L.MarkReady(session, 0)
live["Elwynn Forest"] = nil
check(run(session, db, 0.2, true) == "combat", "a combat click is taken as the player's choice")
check(not setHas(session.saved, "Elwynn Forest") and setHas(session.saved, "Durotar"), "combat keeps the other zone collapsed")
startupRetrack(live, { "Durotar", "Elwynn Forest" })
last = settle(session, db, 1, false)
check(live.Durotar == true and live["Elwynn Forest"] ~= true, "after combat the retrack restores only the zones still collapsed")

-- After the choice has settled, a new quest opens its zone and a later reload keeps it open.
session, db = newChar({ Durotar = true, ["Elwynn Forest"] = true }, false)
live = db.char.collapsedZones
L.MarkReady(session, 0)
startupRetrack(live, { "Durotar", "Elwynn Forest" })
last = settle(session, db)
check(session.phase == "settled" and live.Durotar == true and live["Elwynn Forest"] == true, "both zones restore before a new quest")
live.Durotar = nil
check(run(session, db, 5, false) == "mirrored" and not setHas(session.saved, "Durotar"), "a newly tracked quest's zone stays open")
check(setHas(session.saved, "Elwynn Forest"), "the other zone is still remembered")
local remembered = {}
L.WriteSet(remembered, session.saved)
session = L.NewSession(L.ChooseSaved({}, remembered, true))
live = { ["Elwynn Forest"] = true }
db = { char = { collapsedZones = live, collapsedQuests = { [100] = true } }, profile = profile, global = {} }
L.MarkReady(session, 10)
startupRetrack(live, { "Durotar", "Elwynn Forest" })
last = settle(session, db, 10)
check(live.Durotar ~= true and live["Elwynn Forest"] == true, "reload after a new quest restores only the zones still collapsed")

-- A refresh with no clear keeps the collapse, and a brand-new zone starts expanded.
session, db = newChar({ Durotar = true }, false)
live = db.char.collapsedZones
L.MarkReady(session, 0)
startupRetrack(live, { "Durotar" })
settle(session, db)
local expanded = groupsExpandedOnRefresh(live, { "Durotar", "Mulgore" })
check(expanded[1] == "Mulgore" and expanded[2] == nil, "refresh keeps Durotar collapsed and shows a new zone expanded")
check(run(session, db, 5, false) == "idle" and live.Durotar == true, "a refresh does not change the remembered collapse")
live.Mulgore = nil
check(not setHas(session.saved, "Mulgore"), "a new zone is not stored as collapsed")

-- Two characters do not share a set.
local sessionA, dbA = newChar({ Durotar = true }, true)
local sessionB, dbB = newChar({ ["Elwynn Forest"] = true }, true)
L.MarkReady(sessionA, 0)
L.MarkReady(sessionB, 0)
startupRetrack(dbA.char.collapsedZones, { "Durotar" })
startupRetrack(dbB.char.collapsedZones, { "Elwynn Forest" })
settle(sessionA, dbA)
settle(sessionB, dbB)
check(dbA.char.collapsedZones.Durotar == true and dbA.char.collapsedZones["Elwynn Forest"] ~= true, "character A restores only Durotar")
check(dbB.char.collapsedZones["Elwynn Forest"] == true and dbB.char.collapsedZones.Durotar ~= true, "character B restores only Elwynn Forest")

local savedA, savedB = {}, {}
L.WriteSet(savedA, sessionA.saved)
L.WriteSet(savedB, sessionB.saved)
check(setHas(savedA, "Durotar") and not setHas(savedA, "Elwynn Forest"), "character A's saved file has Durotar")
check(setHas(savedB, "Elwynn Forest") and not setHas(savedB, "Durotar"), "character B's saved file has Elwynn Forest")

-- A wipe saved by Questie on the way out still restores from this addon's copy.
local wiped = {}
local kept = { Durotar = true }
session = L.NewSession(L.ChooseSaved(wiped, kept, true))
check(setHas(session.saved, "Durotar"), "a trusted copy beats a wiped Questie save")
session = L.NewSession(L.ChooseSaved({ ["Elwynn Forest"] = true }, { Durotar = true }, false))
check(setHas(session.saved, "Elwynn Forest") and not setHas(session.saved, "Durotar"), "the first run reads Questie's character table")

-- Non-string and non-true values are not collapses.
local odd = L.CollapsedSet({ Durotar = true, [5] = true, ["Elwynn Forest"] = false, Mulgore = "yes" })
check(setHas(odd, "Durotar") and count(odd) == 1, "only string keys set to true are collapses")

if fails > 0 then
	print(fails .. " failed")
	os.exit(1)
end
print("all passed")
