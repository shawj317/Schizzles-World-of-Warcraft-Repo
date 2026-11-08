-- Schizzle's Questie Zones (WoW Forever) by Jon Shaw (Schizzle). MIT with attribution.
-- https://github.com/shawj317/Schizzles-World-of-Warcraft-Repo
--
-- Pure character-zone memory. No WoW API and no Questie code. Core.lua feeds it the
-- collapsedZones table Questie already keeps per character.

SchizzlesQuestieZonesLogic = SchizzlesQuestieZonesLogic or {}
local L = SchizzlesQuestieZonesLogic

-- How long the live table must match the remembered set, out of combat, before clicks win.
-- Questie's combat queue runs the login retrack on a 0.1s ticker, including just after combat.
L.STABLE_HOLD = 0.5

-- Forever Questie builds whose tracker was read for this addon: 12.5.0, 12.5.1, 12.6.0, 12.6.4.
-- 12.5.x and 12.6.x share the same character table and the same startup clear.
function L.VersionSupported(version)
	if type(version) ~= "string" then
		return false
	end
	local major, minor = version:match("^(%d+)%.(%d+)%.%d+$")
	major, minor = tonumber(major), tonumber(minor)
	return major == 12 and (minor == 5 or minor == 6)
end

function L.Compatibility(version, hasRegisterOnReady, hasCollapsedZones)
	if not hasRegisterOnReady then
		return false, "Questie.API.RegisterOnReady is missing. This needs a Forever Questie build from 12.5.0 through 12.6.x. Nothing was changed."
	end
	if not hasCollapsedZones then
		return false, "Questie.db.char.collapsedZones is not a table. This addon only restores that per-character table. Nothing was changed."
	end
	if type(version) ~= "string" then
		return false, "Questie's version could not be read. The addons list Version field is needed (the checked Forever builds are 12.5.0 through 12.6.4). Nothing was changed."
	end
	if not L.VersionSupported(version) then
		return false, "Installed Questie " .. version .. " is outside 12.5.0 through 12.6.x. Those are the Forever builds whose zone table was checked. Nothing was changed."
	end
	return true
end

-- String keys set to true. That is Questie's collapsed state. Anything else is expanded.
function L.CollapsedSet(zones)
	local out = {}
	if type(zones) ~= "table" then
		return out
	end
	for key, value in pairs(zones) do
		if type(key) == "string" and value == true then
			out[key] = true
		end
	end
	return out
end

function L.SameSet(a, b)
	for key in pairs(a) do
		if b[key] ~= true then
			return false
		end
	end
	for key in pairs(b) do
		if a[key] ~= true then
			return false
		end
	end
	return true
end

function L.NeedsRestore(saved, live)
	for key in pairs(saved) do
		if live[key] ~= true then
			return true
		end
	end
	return false
end

-- Puts remembered collapses back. Leaves every other key alone, including expanded zones.
function L.Restore(saved, live)
	local wrote = 0
	for key in pairs(saved) do
		if live[key] ~= true then
			live[key] = true
			wrote = wrote + 1
		end
	end
	return wrote
end

function L.WriteSet(dest, set)
	local drop = {}
	for key in pairs(dest) do
		if set[key] ~= true then
			drop[#drop + 1] = key
		end
	end
	for i = 1, #drop do
		dest[drop[i]] = nil
	end
	for key in pairs(set) do
		dest[key] = true
	end
end

-- Our own saved copy wins once this character has run the addon. Before that, Questie's
-- character table is the choice from the previous logout, still intact at ADDON_LOADED.
function L.ChooseSaved(questieZones, ownCollapsed, ownTrusted)
	if ownTrusted then
		return L.CollapsedSet(ownCollapsed)
	end
	if type(questieZones) == "table" then
		return L.CollapsedSet(questieZones)
	end
	return {}
end

function L.NewSession(saved)
	return {
		saved = L.CollapsedSet(saved),
		phase = "startup",
		readyAt = nil,
		holdSince = nil,
	}
end

function L.MarkReady(session, now)
	if session.readyAt == nil then
		session.readyAt = now
	end
end

local function addLiveCollapses(saved, liveSet)
	for key in pairs(liveSet) do
		saved[key] = true
	end
end

-- result is "idle", "combat", "restored", "settled", or "mirrored".
function L.Tick(session, live, now, inCombat)
	if type(live) ~= "table" or type(now) ~= "number" then
		return "idle"
	end

	if session.phase == "settled" then
		local current = L.CollapsedSet(live)
		if not L.SameSet(session.saved, current) then
			session.saved = current
			return "mirrored"
		end
		return "idle"
	end

	if session.readyAt == nil then
		return "idle"
	end

	local liveSet = L.CollapsedSet(live)
	if inCombat then
		-- The login retrack waits out combat, so a change here is a click.
		session.holdSince = nil
		if not L.SameSet(session.saved, liveSet) then
			session.saved = liveSet
			return "combat"
		end
		return "idle"
	end

	addLiveCollapses(session.saved, liveSet)
	if L.NeedsRestore(session.saved, live) then
		L.Restore(session.saved, live)
		session.holdSince = now
		return "restored"
	end

	if session.holdSince == nil then
		session.holdSince = now
	end
	if now - session.holdSince >= L.STABLE_HOLD then
		session.phase = "settled"
		return "settled"
	end
	return "idle"
end
