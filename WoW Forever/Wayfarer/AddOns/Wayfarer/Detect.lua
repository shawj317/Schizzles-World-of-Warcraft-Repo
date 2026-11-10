local addonName, ns = ...

-- Which client this is. Forever uses interface 16001, in the same numeric band as Classic,
-- and its expansion level is 0, so neither of those alone tells it apart from Classic Era.
-- Three signals are enough: the Forever project id, the TOC [Game] token, and that interface band.
-- The check follows RutaMisiones (Fastest Quest Route) by Nico, MIT.

local Client = {}
ns.Client = Client

local PROJECT_FOREVER = WOW_PROJECT_FOREVER or WOW_PROJECT_CAMELOT or 18
local PROJECT_MAINLINE = WOW_PROJECT_MAINLINE or 1
local PROJECT_CLASSIC = WOW_PROJECT_CLASSIC or 2
local FOREVER_GAME = { camelot = true, forever = true }

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

local buildVersion, buildNumber, _, interfaceVersion = "?", "0", nil, 0
if GetBuildInfo then
	buildVersion, buildNumber, _, interfaceVersion = GetBuildInfo()
end

Client.buildVersion = buildVersion
Client.buildNumber = tonumber(buildNumber)
Client.interface = tonumber(interfaceVersion) or 0
Client.gameToken = Metadata("X-Game")
Client.familyToken = Metadata("X-Family")
Client.tocFlavor = Metadata("X-Flavor")

local gameToken = Client.gameToken and string.lower(Client.gameToken) or nil
Client.signals = {
	project = WOW_PROJECT_ID ~= nil and WOW_PROJECT_ID == PROJECT_FOREVER,
	game = gameToken ~= nil and FOREVER_GAME[gameToken] == true,
	interface = Client.interface >= 16000 and Client.interface < 20000,
}
Client.isForever = Client.signals.project or Client.signals.game or Client.signals.interface
Client.isRetail = not Client.isForever and WOW_PROJECT_ID == PROJECT_MAINLINE
Client.isClassicEra = not Client.isForever and WOW_PROJECT_ID == PROJECT_CLASSIC

function Client.HasSecretRestrictions()
	return C_Secrets ~= nil and C_Secrets.HasSecretRestrictions ~= nil and C_Secrets.HasSecretRestrictions() == true
end

function Client.GetWarnings()
	local warnings = {}
	if Client.isForever and not Client.signals.project then
		warnings[#warnings + 1] = "WOW_PROJECT_ID=" .. tostring(WOW_PROJECT_ID) .. " is not the Forever id (18)"
	end
	if Client.isForever and not Client.signals.interface then
		warnings[#warnings + 1] = "Interface " .. Client.interface .. " is outside 16000-19999"
	end
	if Client.isForever and gameToken and not FOREVER_GAME[gameToken] then
		warnings[#warnings + 1] = "[Game] is " .. Client.gameToken
	end
	return warnings
end

function Client.Describe()
	local flavor = "Other"
	if Client.isForever then
		flavor = "Forever"
	elseif Client.isRetail then
		flavor = "Retail"
	elseif Client.isClassicEra then
		flavor = "ClassicEra"
	end
	return string.format(
		"%s | %s.%s Interface %d | WOW_PROJECT_ID=%s | X-Game=%s X-Family=%s X-Flavor=%s | signals %s/%s/%s",
		flavor,
		tostring(Client.buildVersion),
		tostring(Client.buildNumber),
		Client.interface,
		tostring(WOW_PROJECT_ID),
		tostring(Client.gameToken),
		tostring(Client.familyToken),
		tostring(Client.tocFlavor),
		tostring(Client.signals.project),
		tostring(Client.signals.game),
		tostring(Client.signals.interface)
	)
end
