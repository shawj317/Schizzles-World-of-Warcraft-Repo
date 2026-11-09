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

SLASH_QUESTROUTE1 = "/questroute"
SLASH_QUESTROUTE2 = "/qr"
SlashCmdList.QUESTROUTE = function(message)
	ns.EnsureUI()
	message = Trim(message)
	if message == "config" or message == "options" or message == "settings" then
		ns.OpenConfig()
		return
	end
	if message == "recalc" or message == "recalculate" or message == "reset" then
		ns.mainFrame:Show()
		ns.Refresh(true)
		return
	end
	if message == "help" then
		ns:Print(L.HELP)
		return
	end
	if message == "debug" then
		ns.PrintDebug()
		return
	end
	if ns.mainFrame:IsShown() then
		ns.mainFrame:Hide()
	else
		ns.mainFrame:Show()
	end
end
