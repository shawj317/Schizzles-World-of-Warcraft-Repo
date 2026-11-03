-- Schizzle's Warrior: TomTom profile (v1) by Jon Shaw (Schizzle). MIT with attribution.
-- Applied by the SchizzlesWarriorSetup helper (/schizzle tomtom) as an AceDB profile named
-- "Schizzle's Warrior" in TomTomDB. Keys are TomTom's own profile keys (TomTom.lua defaults,
-- TomTom_CrazyArrow.lua for the arrow position); anything not listed keeps TomTom's default.
-- Waypoints are stored in TomTomWaypointsM and are never touched.
return {
	profile = {
		general = {
			confirmremoveall = true,
			announce = false,
			corpse_arrow = true,
		},
		-- Coordinates are already on the minimap (SexyMap), so TomTom's coordinate block is off.
		block = {
			enable = false,
		},
		-- Arrow at the top of the screen, well clear of the WeakAuras HUD at the centre.
		arrow = {
			enable = true,
			lock = true,
			scale = 0.9,
			arrival = 10,
			showtta = true,
			showdistance = true,
			setclosest = true,
			theme = "modern",
			position = { "TOP", nil, "TOP", 0, -24 },
		},
		minimap = { enable = true, tooltip = true },
		worldmap = { enable = true, tooltip = true, clickcreate = true, create_modifier = "A" },
	},
}
