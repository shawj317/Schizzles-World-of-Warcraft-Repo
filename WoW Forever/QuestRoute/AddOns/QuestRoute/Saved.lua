local _, ns = ...

-- QuestRouteDB schema 1 is the 1.0.5 table: the same keys, still at the top level.
-- A file with no schema is stamped 1. A newer schema is left as it is, and only
-- missing keys are filled. point, configPoint, width, height, and userSized are
-- not defaults, so a saved window position and size stay where the player put them.

ns.DEFAULTS = {
	schema = 1,
	includeLowLevel = false,
	omitDungeons = true,
	showOnMap = true,
	useTomTom = true,
	maxLevelsAbove = 3,
	stepsShown = 7,
	font = 1,
	fontSize = 13,
}

-- MIGRATIONS[n] rewrites a saved table from schema n-1 to n.
ns.MIGRATIONS = {}

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
	return db
end

function ns.Settings()
	if type(QuestRouteDB) ~= "table" then
		QuestRouteDB = {}
	end
	QuestRouteDB = ns.PrepareDB(QuestRouteDB)
	return ns.HealSettings(QuestRouteDB)
end
