local addonName, ns = ...

-- Load, saved settings, and the events that ask for a new route.
-- QuestRoute by Jon Shaw (Schizzle).

ns.name = addonName
ns.quietUntil = 0
ns.scheduled = false
ns.pendingCombatRefresh = false

local function Metadata(field)
	local getter = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
	if not getter then
		return nil
	end
	local ok, value = pcall(getter, addonName, field)
	if ok and type(value) == "string" and value ~= "" and not string.find(value, "[", 1, true) then
		return value
	end
	return nil
end

ns.version = Metadata("Version") or "1.3.3"

function ns:Print(message)
	print("|cffffd36aWayfarer:|r " .. tostring(message))
end

function ns.EnsureUI()
	local db = ns.Settings()
	if db.rememberWindow == false and not ns.windowForgotten and ns.ForgetWindow then
		ns.ForgetWindow(db)
		ns.windowForgotten = true
	end
	if not ns.mainFrame and ns.BuildMain then
		ns.BuildMain()
	end
end

-- Automatic refreshes wait out combat. A click on Recalculate still runs immediately.
function ns.NoteChange(event)
	if event == "TAXIMAP_OPENED" and ns.ForgetFlights then
		ns.ForgetFlights()
	end
	if event == "QUEST_TURNED_IN" and ns.InvalidateCompleted then
		ns.InvalidateCompleted()
	end
	if event == "PLAYER_REGEN_ENABLED" then
		if ns.pendingVisibility and ns.ApplyPlaceRules then
			local why = ns.pendingVisibility
			ns.pendingVisibility = nil
			ns.ApplyPlaceRules(why)
		end
		if not ns.pendingCombatRefresh then
			return
		end
		ns.pendingCombatRefresh = false
	elseif ns.InCombat() then
		ns.pendingCombatRefresh = true
		return
	end
	if ns.scanning then
		return
	end
	local frame = ns.mainFrame
	if not frame or not frame:IsShown() then
		return
	end
	if ns.scheduled then
		return
	end
	local delay = 1
	if GetTime then
		local remain = (ns.quietUntil or 0) - GetTime()
		if remain > delay then
			delay = remain
		end
	end
	ns.scheduled = true
	local waited = 0
	ns.driver:SetScript("OnUpdate", function(_, elapsed)
		waited = waited + (elapsed or 0)
		if waited < delay then
			return
		end
		ns.driver:SetScript("OnUpdate", nil)
		ns.scheduled = false
		if not ns.mainFrame or not ns.mainFrame:IsShown() then
			return
		end
		if ns.InCombat() then
			ns.pendingCombatRefresh = true
			return
		end
		if ns.Refresh then
			ns.Refresh(false)
		end
	end)
end

function ns.RestartRouteTicker()
	if ns.routeTicker and ns.routeTicker.Cancel then
		pcall(ns.routeTicker.Cancel, ns.routeTicker)
	end
	ns.routeTicker = nil
	local db = ns.Settings()
	if db.autoRecalc == false then
		return
	end
	local interval = ns.ClampInterval and ns.ClampInterval(db.autoInterval) or 30
	local function pulse()
		local current = ns.Settings()
		local hash = ns.CurrentRouteHash and ns.CurrentRouteHash() or ""
		local shown = ns.mainFrame and ns.mainFrame.IsShown and ns.mainFrame:IsShown()
		if not ns.ShouldTickRoute or not ns.ShouldTickRoute({
			enabled = current.autoRecalc ~= false,
			inCombat = ns.InCombat and ns.InCombat(),
			windowShown = shown and true or false,
			useArrow = TomTom ~= nil,
			hash = hash,
			lastHash = ns.lastRouteHash,
		}) then
			return
		end
		ns.lastRouteHash = hash
		if ns.Refresh then
			ns.Refresh(false)
		end
	end
	if C_Timer and C_Timer.NewTicker then
		ns.routeTicker = C_Timer.NewTicker(interval, pulse)
	end
end

function ns.CurrentRouteHash()
	local ids = {}
	local count = 0
	if C_QuestLog and C_QuestLog.GetNumQuestLogEntries then
		local ok, value = pcall(C_QuestLog.GetNumQuestLogEntries)
		if ok then
			count = tonumber(value) or 0
		end
	elseif GetNumQuestLogEntries then
		local ok, value = pcall(GetNumQuestLogEntries)
		if ok then
			count = tonumber(value) or 0
		end
	end
	for i = 1, count do
		if C_QuestLog and C_QuestLog.GetInfo then
			local ok, info = pcall(C_QuestLog.GetInfo, i)
			if ok and type(info) == "table" and info.questID and not info.isHeader then
				ids[#ids + 1] = info.questID
			end
		end
	end
	if #ids == 0 then
		ids[1] = count
	end
	local player, map
	if ns.PlayerPosition then
		player, map = ns.PlayerPosition()
	end
	if ns.LogHash then
		return ns.LogHash(ids, map, player and player.x, player and player.y)
	end
	return tostring(count)
end

ns.driver = CreateFrame("Frame")
ns.driver:RegisterEvent("ADDON_LOADED")
ns.driver:RegisterEvent("PLAYER_LOGIN")
ns.driver:RegisterEvent("PLAYER_ENTERING_WORLD")
ns.driver:RegisterEvent("QUEST_LOG_UPDATE")
ns.driver:RegisterEvent("QUEST_ACCEPTED")
ns.driver:RegisterEvent("QUEST_REMOVED")
ns.driver:RegisterEvent("QUEST_TURNED_IN")
ns.driver:RegisterEvent("ZONE_CHANGED_NEW_AREA")
ns.driver:RegisterEvent("PLAYER_LEVEL_UP")
	ns.driver:RegisterEvent("PLAYER_REGEN_ENABLED")
	ns.driver:RegisterEvent("TAXIMAP_OPENED")
ns.driver:SetScript("OnEvent", function(_, event, name)
	if event == "ADDON_LOADED" and name == addonName then
		ns.EnsureUI()
		if ns.RegisterSettings then
			ns.RegisterSettings()
		end
		if ns.SweepTomTom then
			ns.SweepTomTom()
		end
		if ns.RestartRouteTicker then
			ns.RestartRouteTicker()
		end
		if ns.ApplyPlaceRules then
			ns.ApplyPlaceRules("login")
		end
		return
	end
	if event == "PLAYER_LOGIN" then
		if ns.RegisterSettings then
			ns.RegisterSettings()
		end
		return
	end
	if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
		if ns.ApplyPlaceRules then
			ns.ApplyPlaceRules(ns.loginApplied and "zone" or "login")
		end
		if event == "PLAYER_ENTERING_WORLD" then
			return
		end
	end
	if event == "ADDON_LOADED" then
		if ns.EnsureMapHooks and WorldMapFrame then
			ns.EnsureMapHooks()
		end
		return
	end
	ns.NoteChange(event)
end)
