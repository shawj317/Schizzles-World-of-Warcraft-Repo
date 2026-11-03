-- Schizzle's Warrior: Bartender4 profile overlay (v1) by Jon Shaw (Schizzle). MIT with attribution.
-- Applied by the SchizzlesWarriorSetup helper (/schizzle bars) on top of Bartender4's own
-- "Blizzard" preset, into a profile named "Schizzle's Warrior". Keys are Bartender4's own
-- profile keys (Bartender4.lua, ActionBars.lua, ButtonBar.lua, Bar.lua and the module files).
--
-- Positions use Bartender4's LibWindow storage: point on UIParent, x/y of the bar's top-left
-- corner, in UIParent units. Bars 1-3 are 12 buttons at scale 0.9 with padding 3, so each is
-- (36 + 3) * 12 - 3 + 8 = 473 bar units = 425.7 UI units wide and 39.6 tall.
local FONT = "Fira Sans Condensed Medium"

local function elements()
	return {
		hotkey = { font = FONT, fontSize = 12, fontFlags = "OUTLINE", fontColor = { 0.78, 0.61, 0.43 } },
		count = { font = FONT, fontSize = 13, fontFlags = "OUTLINE", fontColor = { 1, 1, 1 } },
		macro = { font = FONT, fontSize = 10, fontFlags = "OUTLINE" },
	}
end

local function bar(x, y, rows)
	return {
		enabled = true,
		padding = 3,
		rows = rows or 1,
		hidemacrotext = true,
		showgrid = false,
		elements = elements(),
		position = { point = "BOTTOM", x = x, y = y, scale = 0.9, growVertical = "DOWN", growHorizontal = "RIGHT" },
	}
end

return {
	profile = {
		outofrange = "button",
		colors = { range = { r = 0.8, g = 0.1, b = 0.1 } },
		selfcastmodifier = true,
		focuscastmodifier = true,
		snapping = true,
		buttonlock = true,
	},
	namespaces = {
		ActionBars = {
			actionbars = {
				-- Bottom stack, centred: bar 1 (1 to =) at the bottom, bar 2 (Shift binds) in the
				-- middle, bar 3 (Q E R F T G ...) on top, nearest the HUD. Top edge 124, which
				-- leaves 40+ px under the WeakAuras tray (its bottom is about 168 px up).
				[1] = bar(-213, 50),
				[2] = bar(-213, 87),
				[3] = bar(-213, 124),
				-- Bars 4 and 5 as 6x2 blocks either side of the stack, bar 6 above bar 4.
				-- Empty buttons are hidden (showgrid off), so unused bars take no space.
				[4] = bar(-436, 87, 2),
				[5] = bar(221, 87, 2),
				[6] = bar(-436, 164, 2),
			},
		},
		StanceBar = {
			enabled = true,
			padding = 3,
			hidehotkey = true,
			position = { point = "BOTTOM", x = -436, y = 206, scale = 0.9 },
		},
		ExtraActionBar = {
			enabled = true,
			hideArtwork = true,
			position = { point = "BOTTOM", x = 236, y = 176, scale = 0.9 },
		},
		MicroMenu = {
			enabled = true,
			fadeout = true,
			fadeoutalpha = 0,
			position = { point = "BOTTOMRIGHT", x = -300, y = 30, scale = 0.8 },
		},
		-- Baganator shows bag slots, so the bag bar is off.
		BagBar = { enabled = false },
		-- Warriors have no pet bar; Blizzard art off for the clean look.
		PetBar = { enabled = false },
		BlizzardArt = { enabled = false },
		-- MoP Classic XP bar (MainMenuExpBar, 1024 wide) shrunk to a thin strip under bar 1.
		XPBar = {
			enabled = true,
			position = { point = "BOTTOM", x = -213, y = 8, scale = 0.416 },
		},
		RepBar = { enabled = false },
	},
}
