-- Schizzle's Questie Zones (WoW Forever) by Jon Shaw (Schizzle). MIT with attribution.
-- https://github.com/shawj317/Schizzles-World-of-Warcraft-Repo
--
-- Questie 12.5.0 through 12.6.x keeps a collapsed tracker group on
-- Questie.db.char.collapsedZones. On Forever the tracker then re-adds every native
-- watched quest during its login init and clears that group, so a reload opens it.
-- This addon copies the per-character set before that clear and writes the same keys
-- back. It does not replace the table, and it does not write Questie's profile or
-- account data. Quest collapses, sort order and the whole-tracker minimise stay with
-- Questie. No frame scripts are hooked.

local ADDON = ...
local L = SchizzlesQuestieZonesLogic

local session
local refusal
local ticker

local function say(text)
	print("|cffb87333Schizzle's Questie Zones:|r " .. text)
end

local function isLoaded(name)
	local fn = (C_AddOns and C_AddOns.IsAddOnLoaded) or _G.IsAddOnLoaded
	if type(fn) ~= "function" then
		return false
	end
	local ok, value = pcall(fn, name)
	return ok and value and true or false
end

local function addonVersion()
	local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or _G.GetAddOnMetadata
	if type(meta) ~= "function" then
		return nil
	end
	local ok, value = pcall(meta, "Questie", "Version")
	if ok and type(value) == "string" then
		return value
	end
	return nil
end

local function questieZones()
	local questie = _G.Questie
	if type(questie) ~= "table" or type(questie.db) ~= "table" or type(questie.db.char) ~= "table" then
		return nil
	end
	local zones = questie.db.char.collapsedZones
	if type(zones) ~= "table" then
		return nil
	end
	return zones
end

local function registerOnReady()
	local questie = _G.Questie
	local api = questie and questie.API
	if type(api) ~= "table" or type(api.RegisterOnReady) ~= "function" then
		return false
	end
	return true
end

local function ensureDB()
	if type(SchizzlesQuestieZonesCharDB) ~= "table" then
		SchizzlesQuestieZonesCharDB = {}
	end
	if type(SchizzlesQuestieZonesCharDB.collapsed) ~= "table" then
		SchizzlesQuestieZonesCharDB.collapsed = {}
	end
	return SchizzlesQuestieZonesCharDB
end

local function publish()
	if not session then
		return
	end
	local db = ensureDB()
	db.trusted = true
	L.WriteSet(db.collapsed, session.saved)
end

local function redraw()
	local loader = _G.QuestieLoader
	local modules = loader and loader._modules
	local tracker = modules and modules.QuestieTracker
	if type(tracker) ~= "table" or type(tracker.Update) ~= "function" or tracker.started ~= true then
		return false
	end
	local ok = pcall(tracker.Update, tracker)
	return ok
end

local function onTick()
	if not session then
		return
	end
	local live = questieZones()
	if not live then
		return
	end
	local now = GetTime()
	local inCombat = InCombatLockdown and InCombatLockdown() and true or false
	local result = L.Tick(session, live, now, inCombat)
	if result == "restored" then
		redraw()
		publish()
	elseif result == "combat" or result == "settled" or result == "mirrored" then
		publish()
	end
end

local function begin(version)
	if not (C_Timer and type(C_Timer.NewTicker) == "function") then
		refusal = "C_Timer.NewTicker is missing, so a restored collapse cannot be checked after Questie loads. Nothing was changed."
		say(refusal)
		return
	end

	local existing = type(SchizzlesQuestieZonesCharDB) == "table" and SchizzlesQuestieZonesCharDB or nil
	local chosen = L.ChooseSaved(questieZones(), existing and existing.collapsed or nil, existing and existing.trusted == true)
	session = L.NewSession(chosen)

	local api = _G.Questie.API
	local registered, err = pcall(api.RegisterOnReady, function()
		if not session then
			return
		end
		L.MarkReady(session, GetTime())
		onTick()
	end)
	if not registered then
		refusal = "Questie.API.RegisterOnReady failed (" .. tostring(err) .. "). Nothing was changed."
		say(refusal)
		session = nil
		return
	end

	publish()
	ticker = C_Timer.NewTicker(0.1, onTick)
	say("Questie " .. version .. " on this character. A collapsed tracker group stays collapsed across reload and relog.")
end

local function tryStart()
	if session or refusal then
		return
	end
	if not isLoaded("Questie") then
		return
	end
	local version = addonVersion()
	local ok, reason = L.Compatibility(version, registerOnReady(), questieZones() ~= nil)
	if not ok then
		refusal = reason
		say(reason)
		return
	end
	begin(version)
end

local function onLogout()
	if not session then
		return
	end
	if session.phase == "settled" then
		local live = questieZones()
		if live then
			session.saved = L.CollapsedSet(live)
		end
	end
	publish()
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", function(_, event, name)
	if event == "ADDON_LOADED" and (name == ADDON or name == "Questie") then
		tryStart()
	elseif event == "PLAYER_LOGOUT" then
		onLogout()
	end
end)

SLASH_SCHIZZLESQUESTIEZONES1 = "/sqz"
SlashCmdList.SCHIZZLESQUESTIEZONES = function()
	if refusal then
		say(refusal)
		return
	end
	if not isLoaded("Questie") then
		say("Questie is not loaded. Enable Questie, then /reload.")
		return
	end
	if not session then
		say("Waiting for this character's saved zones.")
		return
	end
	local count = 0
	for _ in pairs(session.saved) do
		count = count + 1
	end
	local state = session.phase == "settled" and "keeping" or "restoring"
	say(state .. " " .. count .. " collapsed tracker group" .. (count == 1 and "" or "s") .. " for this character.")
end
