local addonName, ns = ...

-- Load, saved settings, and the events that ask for a new route.
-- QuestRoute by Jon Shaw (Schizzle).

ns.name = addonName
ns.scheduled = false
ns.pendingCombatRefresh = false
ns.perf = {
	scans = 0,
	skipped = 0,
	lastMs = 0,
	lastReason = "none",
	events = 0,
}

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

ns.version = Metadata("Version") or "1.3.5"

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

local function QuestCount()
	if C_QuestLog and C_QuestLog.GetNumQuestLogEntries then
		local ok, value = pcall(C_QuestLog.GetNumQuestLogEntries)
		if ok then
			return tonumber(value) or 0
		end
	end
	if GetNumQuestLogEntries then
		local ok, value = pcall(GetNumQuestLogEntries)
		if ok then
			return tonumber(value) or 0
		end
	end
	return 0
end

local function DoneBits(questID)
	if not questID or not C_QuestLog or not C_QuestLog.GetQuestObjectives then
		return ""
	end
	local ok, objectives = pcall(C_QuestLog.GetQuestObjectives, questID)
	if not ok or type(objectives) ~= "table" then
		return ""
	end
	local bits = {}
	for i = 1, #objectives do
		local finished = objectives[i].finished
		if ns.IsSecret and ns.IsSecret(finished) then
			bits[i] = "?"
		else
			bits[i] = finished and "1" or "0"
		end
	end
	return table.concat(bits)
end

-- Quest ids, which objectives are finished, and the current map. No coordinates.
function ns.CurrentWatch()
	local ids = {}
	local count = QuestCount()
	for i = 1, count do
		local questID, header, complete
		if C_QuestLog and C_QuestLog.GetInfo then
			local ok, info = pcall(C_QuestLog.GetInfo, i)
			if ok and type(info) == "table" then
				header = info.isHeader
				questID = tonumber(info.questID)
				complete = info.isComplete
			end
		elseif GetQuestLogTitle then
			local ok, _, _, _, isHeader, _, isComplete, _, id = pcall(GetQuestLogTitle, i)
			if ok then
				header = isHeader
				questID = tonumber(id)
				complete = isComplete
			end
		end
		if questID and questID > 0 and not header then
			local bits = DoneBits(questID)
			if bits == "" then
				bits = (complete == true or complete == 1) and "1" or "0"
			end
			ids[#ids + 1] = questID .. ":" .. bits
		end
	end
	if #ids == 0 then
		ids[1] = "n:" .. count
	end
	local map
	if C_Map and C_Map.GetBestMapForUnit then
		local ok, value = pcall(C_Map.GetBestMapForUnit, "player")
		if ok and type(value) == "number" then
			map = value
		end
	end
	if ns.WatchHash then
		return ns.WatchHash(ids, map)
	end
	return tostring(count) .. "|" .. tostring(map or "")
end

function ns.CurrentRouteHash()
	return ns.CurrentWatch()
end

local function WindowShown()
	local frame = ns.mainFrame
	return frame and frame.IsShown and frame:IsShown() and true or false
end

local function ClearDriverUpdate()
	if ns.driver and ns.driver.SetScript then
		ns.driver:SetScript("OnUpdate", nil)
	end
end

-- One delayed scan. A newer request retires the previous callback.
-- The driver has no OnUpdate while this waits, unless this client has no timer.
function ns.ScheduleScan(reason)
	if ns.scheduled then
		return
	end
	ns.scanGen = (ns.scanGen or 0) + 1
	local gen = ns.scanGen
	ns.scheduled = true
	ns.scanReason = reason
	local function fire()
		if gen ~= ns.scanGen then
			return
		end
		ns.scheduled = false
		ClearDriverUpdate()
		local hash = ns.CurrentWatch()
		if not ns.ShouldScan or not ns.ShouldScan({
			scanning = ns.scanning,
			inCombat = ns.InCombat and ns.InCombat(),
			windowShown = WindowShown(),
			hash = hash,
			lastHash = ns.lastWatch,
		}) then
			if ns.InCombat and ns.InCombat() and WindowShown() and hash ~= ns.lastWatch then
				ns.pendingCombatRefresh = true
			end
			ns.perf.skipped = (ns.perf.skipped or 0) + 1
			return
		end
		if ns.Refresh then
			ns.Refresh(false, reason or "event")
		end
	end
	if C_Timer and C_Timer.After then
		ClearDriverUpdate()
		C_Timer.After(1.5, fire)
		return
	end
	local waited = 0
	ns.driver:SetScript("OnUpdate", function(_, elapsed)
		waited = waited + (elapsed or 0)
		if waited < 1.5 then
			return
		end
		ClearDriverUpdate()
		fire()
	end)
end

-- Log and zone events do not rebuild unless the quest log or zone changed.
-- Auto recalculate is a separate timer and is not required for this gate.
function ns.NoteChange(event)
	ns.perf.events = (ns.perf.events or 0) + 1
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
			ns.perf.skipped = (ns.perf.skipped or 0) + 1
			return
		end
		ns.pendingCombatRefresh = false
	elseif ns.InCombat() then
		ns.pendingCombatRefresh = true
		return
	end
	local hash = ns.CurrentWatch()
	if not ns.ShouldScan or not ns.ShouldScan({
		scanning = ns.scanning,
		inCombat = false,
		windowShown = WindowShown(),
		hash = hash,
		lastHash = ns.lastWatch,
	}) then
		ns.perf.skipped = (ns.perf.skipped or 0) + 1
		return
	end
	ns.ScheduleScan(event)
end

function ns.RestartRouteTicker()
	ns.tickerGen = (ns.tickerGen or 0) + 1
	local gen = ns.tickerGen
	local db = ns.Settings()
	local enabled = db.autoRecalc ~= false
	local interval = ns.ClampInterval and ns.ClampInterval(db.autoInterval) or 30
	local function pulse()
		if gen ~= ns.tickerGen then
			return
		end
		local current = ns.Settings()
		local hash = ns.CurrentWatch()
		if not ns.ShouldTickRoute or not ns.ShouldTickRoute({
			enabled = current.autoRecalc ~= false,
			inCombat = ns.InCombat and ns.InCombat(),
			windowShown = WindowShown(),
			hash = hash,
			lastHash = ns.lastWatch,
		}) then
			ns.perf.skipped = (ns.perf.skipped or 0) + 1
			return
		end
		if ns.Refresh then
			ns.Refresh(false, "timer")
		end
	end
	local function create()
		if not C_Timer or not C_Timer.NewTicker then
			return nil
		end
		return C_Timer.NewTicker(interval, pulse)
	end
	if ns.ReplaceTicker then
		ns.routeTicker = ns.ReplaceTicker(ns.routeTicker, enabled, create)
	elseif not enabled then
		if ns.routeTicker and ns.routeTicker.Cancel then
			pcall(ns.routeTicker.Cancel, ns.routeTicker)
		end
		ns.routeTicker = nil
	end
end

function ns.PrintPerf()
	local perf = ns.perf or {}
	local objectives, clusters, npcs, items = 0, 0, 0, 0
	if ns.CacheCounts then
		objectives, clusters, npcs, items = ns.CacheCounts()
	end
	local updating = 0
	if ns.driver and ns.driver.GetScript then
		local ok, script = pcall(ns.driver.GetScript, ns.driver, "OnUpdate")
		if ok and script then
			updating = 1
		end
	end
	ns:Print(string.format(
		"last recalc %.1f ms (%s), scans %d, skipped %d, events %d, ticker %d, pending %d, onupdate %d, objectives %d, clusters %d, npcs %d, items %d",
		tonumber(perf.lastMs) or 0,
		tostring(perf.lastReason or "none"),
		tonumber(perf.scans) or 0,
		tonumber(perf.skipped) or 0,
		tonumber(perf.events) or 0,
		ns.routeTicker and 1 or 0,
		ns.scheduled and 1 or 0,
		updating,
		tonumber(objectives) or 0,
		tonumber(clusters) or 0,
		tonumber(npcs) or 0,
		tonumber(items) or 0
	))
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
