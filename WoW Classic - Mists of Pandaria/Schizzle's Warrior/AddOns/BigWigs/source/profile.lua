-- Schizzle's Warrior BigWigs profile (v1) by Jon Shaw (Schizzle). MIT with attribution.
-- The sections of a BigWigs "BW2" share string, in BigWigs' own setting keys
-- (BigWigs_Options/Sharing.lua *ToExport lists, defaults in BigWigs_Plugins/Bars.lua,
-- Messages.lua, Countdown.lua and Colors.lua).
--
-- Layout, from the screen centre (UIParent units). The WeakAuras HUD keeps x -170..170,
-- y -220..120 clear; the Details! windows sit bottom right, up to about 44 below centre.
--   normal bars      left of the HUD,  x -520..-320, from y -20 growing up (8 bars max)
--   emphasized bars  right of the HUD, x  260..500,  from y -20 growing up (5 bars max)
--   countdown        centre, y 180, above the HUD
--   messages         top centre (BigWigs' default spot), new lines push up
--   big messages     centre, y 250
local FONT = "Fira Sans Condensed Medium" -- registered by WeakAuras
local TEXTURE = "Minimalist"               -- registered by BetterBlizzFrames / BetterBlizzPlates

return {
	barPositions = {
		normalPosition = { "CENTER", "CENTER", -420, -20, "UIParent" },
		expPosition = { "CENTER", "CENTER", 380, -20, "UIParent" },
	},
	barSettings = {
		fontName = FONT,
		fontSize = 11,
		fontSizeEmph = 13,
		texture = TEXTURE,
		monochrome = false,
		outline = "OUTLINE",
		growup = true,
		text = true,
		time = true,
		alignText = "LEFT",
		alignTime = "RIGHT",
		icon = true,
		iconPosition = "LEFT",
		fill = false,
		barStyle = "Default",
		emphasize = true,
		emphasizeMove = true,
		emphasizeGrowup = true,
		emphasizeRestart = true,
		emphasizeTime = 11,
		emphasizeMultiplier = 1.1,
		spacing = 2,
		visibleBarLimit = 8,
		visibleBarLimitEmph = 5,
		normalWidth = 200,
		normalHeight = 18,
		expWidth = 240,
		expHeight = 22,
		normalCopyCustomAnchorWidth = false,
		expCopyCustomAnchorWidth = false,
	},
	barColors = {
		barColor = { 0.72, 0.45, 0.2, 1 },        -- bronze
		barEmphasized = { 1, 0.47, 0, 1 },        -- ember
		barBackground = { 0.06, 0.06, 0.06, 0.7 }, -- charcoal
		barText = { 1, 1, 1, 1 },
		barTextShadow = { 0, 0, 0, 1 },
	},
	messagePositions = {
		normalPosition = { "BOTTOM", "TOP", 0, -262 },
		emphPosition = { "CENTER", "CENTER", 0, 250 },
	},
	messageSettings = {
		fontName = FONT,
		emphFontName = FONT,
		monochrome = false,
		emphMonochrome = false,
		outline = "OUTLINE",
		emphOutline = "THICKOUTLINE",
		align = "CENTER",
		fontSize = 20,
		emphFontSize = 36,
		chat = false,
		useicons = true,
		classcolor = true,
		growUpwards = true,
		displaytime = 2,
		fadetime = 1.2,
		emphUppercase = true,
	},
	messageColors = {
		-- BigWigs' meanings kept (red = danger, blue = info...); orange and yellow in the kit's ember and gold.
		red = { 1, 0.2, 0.2 },
		blue = { 0.2, 0.4, 1 },
		orange = { 1, 0.47, 0 },
		yellow = { 1, 0.82, 0 },
		green = { 0.2, 1, 0.2 },
		cyan = { 0.2, 1, 1 },
		purple = { 0.7, 0, 0.7 },
	},
	countdownPositions = {
		position = { "CENTER", "CENTER", 0, 180 },
	},
	countdownSettings = {
		textEnabled = true,
		fontName = FONT,
		outline = "THICKOUTLINE",
		fontSize = 40,
		monochrome = false,
		countdownTime = 5,
	},
	countdownColors = {
		fontColor = { r = 1, g = 0.47, b = 0 }, -- ember
	},
}
