local _, ns = ...

-- WayfarerDB schema 1 is the old QuestRoute 1.0.5 table. Schema 2 adds route scope,
-- round-pin size, the ant trail, and flight paths. Schema 3 adds window memory,
-- login visibility, and battleground or instance hiding. Keys are not renamed.
-- A newer schema is left alone. point, configPoint, width, height, and userSized
-- are not defaults, so a saved window stays where the player put it.
-- On first load, an empty WayfarerDB is filled from QuestRouteDB if that still exists.

ns.DEFAULTS = {
	schema = 3,
	includeLowLevel = false,
	omitDungeons = true,
	showOnMap = true,
	useTomTom = true,
	maxLevelsAbove = 3,
	stepsShown = 7,
	font = 1,
	fontSize = 13,
	scope = "zone",
	useFlights = true,
	showTrail = true,
	trailAnimated = true,
	trailAlpha = 0.9,
	trailR = 1,
	trailG = 0.82,
	trailB = 0,
	pinSize = 20,
	theme = "wayfarer",
	backdropAlpha = 0.85,
	showBorder = true,
	trailCustom = false,
	rememberWindow = true,
	showOnLogin = false,
	hideInBattleground = false,
	hideInInstance = false,
	windowScale = 1,
}

-- MIGRATIONS[n] rewrites a saved table from schema n-1 to n.
-- 2 adds keys only. Missing values are filled from DEFAULTS afterwards.
ns.MIGRATIONS = {
	[2] = function() end,
	[3] = function() end,
}

local function MergeDefaults(db, defaults)
	for key, value in pairs(defaults) do
		if type(value) == "table" then
			if type(db[key]) ~= "table" then
				db[key] = {}
			end
			MergeDefaults(db[key], value)
		elseif db[key] == nil then
			db[key] = value
		end
	end
end

function ns.PrepareDB(saved)
	if type(saved) ~= "table" then
		saved = {}
	end
	local defaults = ns.DEFAULTS
	if next(saved) ~= nil then
		local schema = tonumber(saved.schema) or 1
		for version = schema + 1, defaults.schema do
			local migrate = ns.MIGRATIONS[version]
			if migrate then
				migrate(saved)
			end
			saved.schema = version
		end
		if saved.schema == nil then
			saved.schema = schema
		end
	end
	MergeDefaults(saved, defaults)
	return saved
end

-- Same clamps 1.0.5 applied whenever it read the saved table.
function ns.HealSettings(db)
	local planner = ns.Planner
	if db.includeLowLevel == nil then
		db.includeLowLevel = false
	end
	if db.omitDungeons == nil then
		db.omitDungeons = true
	end
	if db.showOnMap == nil then
		db.showOnMap = true
	end
	if db.useTomTom == nil then
		db.useTomTom = true
	end
	db.maxLevelsAbove = planner.ClampAbove(db.maxLevelsAbove)
	db.stepsShown = planner.ClampSteps(db.stepsShown)
	local font = math.floor((tonumber(db.font) or 1) + 0.5)
	if font < 1 or font > 6 then
		font = 1
	end
	db.font = font
	local fontSize = math.floor((tonumber(db.fontSize) or 13) + 0.5)
	if fontSize < 9 then
		fontSize = 9
	elseif fontSize > 22 then
		fontSize = 22
	end
	db.fontSize = fontSize
	if db.scope ~= "all" then
		db.scope = "zone"
	end
	if db.useFlights == nil then
		db.useFlights = true
	end
	if db.showTrail == nil then
		db.showTrail = true
	end
	if db.trailAnimated == nil then
		db.trailAnimated = true
	end
	db.pinSize = math.floor((tonumber(db.pinSize) or 20) + 0.5)
	if db.pinSize < 14 then
		db.pinSize = 14
	elseif db.pinSize > 32 then
		db.pinSize = 32
	end
	local function unit(n, fallback)
		n = tonumber(n)
		if n == nil then
			return fallback
		end
		if n < 0 then
			return 0
		end
		if n > 1 then
			return 1
		end
		return n
	end
	db.trailAlpha = unit(db.trailAlpha, 0.9)
	if db.trailAlpha < 0.15 then
		db.trailAlpha = 0.15
	end
	db.trailR = unit(db.trailR, 1)
	db.trailG = unit(db.trailG, 0.82)
	db.trailB = unit(db.trailB, 0)
	if db.theme ~= "blizzard" and db.theme ~= "class" then
		db.theme = "wayfarer"
	end
	db.backdropAlpha = unit(db.backdropAlpha, 0.85)
	if db.showBorder == nil then
		db.showBorder = true
	end
	if db.trailCustom == nil then
		db.trailCustom = false
	end
	if db.rememberWindow == nil then
		db.rememberWindow = true
	end
	if db.showOnLogin == nil then
		db.showOnLogin = false
	end
	if db.hideInBattleground == nil then
		db.hideInBattleground = false
	end
	if db.hideInInstance == nil then
		db.hideInInstance = false
	end
	local scale = tonumber(db.windowScale) or 1
	if scale < 0.8 then
		scale = 0.8
	elseif scale > 1.4 then
		scale = 1.4
	end
	db.windowScale = scale
	return db
end

local function CopyTable(src)
	local out = {}
	for key, value in pairs(src) do
		if type(value) == "table" then
			out[key] = CopyTable(value)
		else
			out[key] = value
		end
	end
	return out
end

function ns.Settings()
	if type(WayfarerDB) ~= "table" then
		WayfarerDB = {}
	end
	if next(WayfarerDB) == nil and type(QuestRouteDB) == "table" and next(QuestRouteDB) ~= nil then
		WayfarerDB = CopyTable(QuestRouteDB)
		WayfarerDB.migratedFrom = "QuestRoute"
	end
	WayfarerDB = ns.PrepareDB(WayfarerDB)
	return ns.HealSettings(WayfarerDB)
end
