-- Schizzle's Warrior: SexyMap profile (v1) by Jon Shaw (Schizzle). MIT with attribution.
-- Applied by the SchizzlesWarriorSetup helper (/schizzle map). SexyMap isn't AceDB: it keeps one
-- table per character in SexyMap2DB["Name-Realm"], or the string "global" to share
-- SexyMap2DB.global. The helper writes this table to SexyMap2DB.global and points the character
-- at it, which is the same thing SexyMap's own "Global profile" toggle does.
-- Module keys: core (SexyMap_Wrath.lua / SexyMap.lua), borders (Borders*.lua),
-- buttons (Buttons*.lua), clock (Clock.lua), zonetext (ZoneText.lua), coordinates (Coordinates.lua).
local FONT = "Fira Sans Condensed Medium"
local CHARCOAL = { r = 0.06, g = 0.06, b = 0.06, a = 0.9 }
local BRONZE = { r = 0.72, g = 0.45, b = 0.2, a = 1 }
local TAN = { r = 0.78, g = 0.61, b = 0.43, a = 1 }
local GOLD = { r = 1, g = 0.82, b = 0, a = 1 }

local function copy(t) local r = {} for k, v in pairs(t) do r[k] = v end return r end

return {
	core = {
		lock = true,
		clamp = true,
		rightClickToConfig = true,
		autoZoom = 5,
		northTag = false,
		-- Square: the WHITE8X8 mask SexyMap's "Simple Square" preset uses (file ID 130871).
		shape = 130871,
	},
	borders = {
		hideBlizzard = true,
		borders = {},
		applyPreset = false,
		-- A charcoal plate 3% larger than the map, so a 2 px bronze edge frames it.
		backdrop = {
			show = true,
			scale = 1.03,
			alpha = 1,
			textureColor = copy(CHARCOAL),
			borderColor = copy(BRONZE),
			settings = {
				bgFile = "Interface\\Buttons\\WHITE8X8",
				edgeFile = "Interface\\Buttons\\WHITE8X8",
				edgeSize = 2,
				tile = false,
				insets = { left = 0, top = 0, right = 0, bottom = 0 },
			},
		},
	},
	buttons = {
		radius = 10,
		dragPositions = {},
		-- Blizzard's own minimap buttons. Addon buttons go into MinimapButtonButton instead.
		visibilitySettings = {
			GameTimeFrame = "hover",
			MinimapZoomIn = "never",
			MinimapZoomOut = "never",
			MiniMapWorldMapButton = "never",
			MiniMapTracking = "hover",
			SexyMapZoneTextButton = "always",
			TimeManagerClockButton = "always",
			MiniMapMailFrame = "always",
			MiniMapBattlefieldFrame = "always",
			LFGMinimapFrame = "always",
		},
		allowDragging = true,
		lockDragging = true,
		controlVisibility = true,
	},
	clock = {
		xOffset = 0,
		yOffset = 0,
		font = FONT,
		fontsize = 11,
		fontColor = copy(TAN),
		bgColor = copy(CHARCOAL),
		borderColor = copy(BRONZE),
		monochrome = false,
		outline = "NONE",
	},
	zonetext = {
		xOffset = 0,
		yOffset = 0,
		font = FONT,
		fontsize = 12,
		fontColor = copy(GOLD),
		bgColor = copy(CHARCOAL),
		borderColor = copy(BRONZE),
		useSecureButton = false,
		monochrome = false,
		outline = "NONE",
	},
	coordinates = {
		enabled = true,
		coordPrecision = "%.1f, %.1f",
		updateRate = 0.5,
		xOffset = 0,
		yOffset = 10,
		font = FONT,
		fontSize = 11,
		fontColor = copy(TAN),
		backgroundColor = copy(CHARCOAL),
		borderColor = copy(BRONZE),
		monochrome = false,
		outline = "NONE",
	},
}
