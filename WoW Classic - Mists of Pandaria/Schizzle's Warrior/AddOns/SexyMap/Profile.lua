-- Schizzle's Warrior: SexyMap profile (v2) by Jon Shaw (Schizzle). MIT with attribution.
-- Applied by the SchizzlesWarriorSetup helper (/schizzle map). SexyMap isn't AceDB: it keeps one
-- table per character in SexyMap2DB["Name-Realm"], or the string "global" to share
-- SexyMap2DB.global. The helper writes this table to SexyMap2DB.global and points the character
-- at it, which is the same thing SexyMap's own "Global profile" toggle does.
-- v2 is Jon's own in-game setup, taken from SexyMap's saved variables (the global profile only).
-- Module keys: core (SexyMap_Wrath.lua / SexyMap.lua), borders (Borders*.lua),
-- buttons (Buttons*.lua), clock (Clock.lua), zonetext (ZoneText.lua), coordinates (Coordinates.lua),
-- movers (Movers*.lua).
local FONT = "Fira Sans Condensed Medium"
local CHARCOAL = { r = 0.06, g = 0.06, b = 0.06, a = 0.9 }
local BRONZE = { r = 0.72, g = 0.45, b = 0.2, a = 1 }
local TAN = { r = 0.78, g = 0.61, b = 0.43, a = 1 }
local GOLD = { r = 1, g = 0.82, b = 0, a = 1 }

local function copy(t) local r = {} for k, v in pairs(t) do r[k] = v end return r end

return {
	core = {
		-- Unlocked, so the map can still be dragged (SexyMap's "Lock minimap").
		lock = false,
		clamp = true,
		rightClickToConfig = true,
		autoZoom = 15,
		northTag = false,
		-- Square: the WHITE8X8 mask SexyMap's "Simple Square" preset uses (file ID 130871).
		shape = 130871,
		-- 1.5x size, tucked into the top-right corner about 4 px from each edge.
		scale = 1.5,
		point = "TOPRIGHT",
		relpoint = "TOPRIGHT",
		x = -4.376292705535889,
		y = -4.666701793670654,
	},
	borders = {
		hideBlizzard = true,
		borders = {},
		applyPreset = false,
		-- No background fill (SexyMap's background texture set to "None"), just Blizzard's
		-- tooltip border, 6 px, in bronze, 3% larger than the map. The colours are the colour
		-- picker's 8-bit values for the v1 charcoal and bronze.
		backdrop = {
			show = true,
			scale = 1.03,
			alpha = 1,
			textureColor = { r = 0.05882353335618973, g = 0.05882353335618973, b = 0.05882353335618973, a = 0.9000000059604645 },
			borderColor = { r = 0.7215686440467834, g = 0.4509804248809815, b = 0.2000000178813934, a = 1 },
			settings = {
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				edgeSize = 6,
				tile = false,
				tileSize = 0,
				insets = { left = 0, top = 0, right = 0, bottom = 0 },
			},
		},
	},
	buttons = {
		radius = 10,
		dragPositions = {},
		-- Blizzard's own minimap buttons, plus the kit's addon buttons, all shown all the time
		-- (SexyMap's default is "hover"). Only the calendar, zoom and world map buttons are hidden.
		visibilitySettings = {
			GameTimeFrame = "never",
			MinimapZoomIn = "never",
			MinimapZoomOut = "never",
			MiniMapWorldMapButton = "never",
			MiniMapTracking = "always",
			SexyMapZoneTextButton = "always",
			TimeManagerClockButton = "always",
			MiniMapMailFrame = "always",
			MiniMapBattlefieldFrame = "always",
			LFGMinimapFrame = "always",
			LibDBIcon10_Bartender4 = "always",
			LibDBIcon10_BigWigs = "always",
			LibDBIcon10_Details = "always",
			LibDBIcon10_DetailsStreamer = "always",
			LibDBIcon10_Leatrix_Plus = "always",
			LibDBIcon10_Questie = "always",
			LibDBIcon10_RareScannerMinimapIcon = "always",
			LibDBIcon10_RXPGuides = "always",
			["LibDBIcon10_TomTom-Paste"] = "always",
			LibDBIcon10_TradeSkillMaster = "always",
			LibDBIcon10_WeakAuras = "always",
		},
		allowDragging = true,
		lockDragging = true,
		controlVisibility = true,
	},
	clock = {
		xOffset = 0,
		yOffset = 0,
		font = FONT,
		fontsize = 9,
		fontColor = copy(TAN),
		bgColor = copy(CHARCOAL),
		borderColor = copy(BRONZE),
		monochrome = false,
		outline = "NONE",
	},
	zonetext = {
		xOffset = 0,
		yOffset = -18,
		font = FONT,
		fontsize = 9,
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
		updateRate = 0.1,
		xOffset = 0,
		yOffset = 9,
		font = FONT,
		fontSize = 8,
		fontColor = copy(TAN),
		backgroundColor = copy(CHARCOAL),
		borderColor = copy(BRONZE),
		monochrome = false,
		outline = "NONE",
	},
	-- The durability figure can be moved, and is locked where it is; everything else stays put.
	movers = {
		moveDurability = true,
		lockDurability = true,
		moveBuffs = false,
		lockBuffs = false,
		moveObjectives = false,
		lockObjectives = false,
		moveCaptureBar = false,
		lockCaptureBar = false,
		moveVehicle = false,
		lockVehicle = false,
		moveTopWidget = false,
		lockTopWidget = false,
		moverPositions = {},
	},
}
