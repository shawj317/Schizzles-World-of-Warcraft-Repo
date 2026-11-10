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

ns.version = Metadata("Version") or "1.3.1"

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

ns.driver = CreateFrame("Frame")
ns.driver:RegisterEvent("ADDON_LOADED")
ns.driver:RegisterEvent("PLAYER_LOGIN")
ns.driver:RegisterEvent("PLAYER_ENTERING_WORLD")
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
