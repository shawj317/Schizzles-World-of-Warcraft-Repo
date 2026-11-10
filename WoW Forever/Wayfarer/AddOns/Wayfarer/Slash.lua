local _, ns = ...

-- /questroute and /qr. The 1.0.5 commands still do what they did.
-- /qr reset recalculates. It does not wipe QuestRouteDB.

local L = ns.L

local function Trim(message)
	message = string.lower(message or "")
	message = string.gsub(message, "^%s+", "")
	message = string.gsub(message, "%s+$", "")
	return message
end

function ns.PrintDebug()
	local client = ns.Client
	ns:Print(ns.version .. " schema " .. tostring(ns.Settings().schema))
	if client and client.Describe then
		print("  " .. client.Describe())
		print("  HasSecretRestrictions=" .. tostring(client.HasSecretRestrictions()))
		for _, warning in ipairs(client.GetWarnings()) do
			print("  " .. warning)
		end
	end
	if Enum and Enum.AddOnRestrictionType then
		local active = {}
		for name, value in pairs(Enum.AddOnRestrictionType) do
			if ns.IsRestrictionActive(value) then
				active[#active + 1] = name
			end
		end
		table.sort(active)
		print("  Restrictions: " .. (#active > 0 and table.concat(active, ", ") or "none"))
	end
	local questie = type(QuestieLoader) == "table"
	local lib = type(LibQuestieDB) == "table"
	print("  QuestieLoader=" .. tostring(questie) .. " LibQuestieDB=" .. tostring(lib) .. " TomTom=" .. tostring(TomTom ~= nil))
	local plan = ns.mainFrame and ns.mainFrame.plan
	print(string.format(
		"  Steps=%d zone=%s combat=%s",
		plan and plan.totalSteps or 0,
		plan and plan.zoneLabel or "?",
		tostring(ns.InCombat())
	))
end

SLASH_WAYFARER1 = "/wayfarer"
SLASH_WAYFARER2 = "/wf"
SLASH_WAYFARER3 = "/qr"
SLASH_WAYFARER4 = "/questroute"
SlashCmdList.WAYFARER = function(message)
	ns.EnsureUI()
	message = Trim(message)
	local command, argument = message:match("^(%S*)%s*(.-)$")
	command = command or ""
	argument = argument or ""
	if command == "config" or command == "options" or command == "settings" then
		ns.OpenConfig()
		return
	end
	if command == "recalc" or command == "recalculate" or command == "reset" then
		ns.mainFrame:Show()
		ns.Refresh(true)
		return
	end
	if command == "scope" then
		local db = ns.Settings()
		if argument == "all" or argument == "log" then
			db.scope = "all"
		elseif argument == "zone" or argument == "current" then
			db.scope = "zone"
		elseif argument == "" then
			db.scope = db.scope == "all" and "zone" or "all"
		else
			ns:Print(L.HELP)
			return
		end
		ns:Print(string.format(L.SCOPE_SET, db.scope == "all" and L.SCOPE_ALL or L.SCOPE_ZONE))
		ns.mainFrame:Show()
		ns.Refresh(false)
		return
	end
	if command == "unskip" then
		if ns.Unskip then
			ns.Unskip()
		end
		ns:Print(L.UNSKIP)
		return
	end
	if command == "help" then
		ns:Print(L.HELP)
		return
	end
	if command == "debugsettings" then
		if ns.PrintSettingsReport then
			ns.PrintSettingsReport()
		end
		return
	end
	if command == "debug" then
		ns.PrintDebug()
		return
	end
	if command == "perf" then
		if ns.PrintPerf then
			ns.PrintPerf()
		end
		return
	end
	if command ~= "" then
		ns:Print(L.HELP)
		return
	end
	if ns.mainFrame:IsShown() then
		ns.mainFrame:Hide()
	else
		ns.mainFrame:Show()
	end
end
